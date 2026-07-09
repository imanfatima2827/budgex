import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/savings_goal.dart';

class FinanceService {
  FinanceService({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  static const categorySelect =
      'id, user_id, name, icon_name, color_hex, is_default';
  static const budgetSelect =
      'id, user_id, category_id, monthly_limit, categories($categorySelect)';
  static const recurringSelect = 'id, user_id, category_id, title, amount, '
      'payment_method, frequency, next_due_date, note, is_active, '
      'auto_post, last_generated_date, categories($categorySelect)';

  Future<List<CategoryBudget>> fetchCategoryBudgets() async {
    final rows = await _supabase
        .from('category_budgets')
        .select(budgetSelect)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) =>
              CategoryBudget.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<CategoryBudget> upsertCategoryBudget({
    required ExpenseCategory category,
    required double monthlyLimit,
  }) async {
    final user = _requireUser();
    final row = await _supabase
        .from('category_budgets')
        .upsert({
          'user_id': user.id,
          'category_id': category.id,
          'monthly_limit': monthlyLimit,
        }, onConflict: 'user_id,category_id')
        .select(budgetSelect)
        .single();

    return CategoryBudget.fromMap(row);
  }

  Future<void> deleteCategoryBudget(String id) async {
    await _supabase.from('category_budgets').delete().eq('id', id);
  }

  Future<List<Income>> fetchIncomes() async {
    final rows = await _supabase
        .from('incomes')
        .select('id, user_id, title, amount, income_date, source, note')
        .order('income_date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Income.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Income> addIncome({
    required String title,
    required double amount,
    required DateTime date,
    required String source,
    String note = '',
  }) async {
    final user = _requireUser();
    final income = Income(
      id: '',
      userId: user.id,
      title: title,
      amount: amount,
      date: date,
      source: source,
      note: note,
    );

    final row = await _supabase
        .from('incomes')
        .insert(income.toInsertMap(currentUserId: user.id))
        .select('id, user_id, title, amount, income_date, source, note')
        .single();

    return Income.fromMap(row);
  }

  Future<Income> updateIncome(Income income) async {
    final row = await _supabase
        .from('incomes')
        .update(income.toUpdateMap())
        .eq('id', income.id)
        .select('id, user_id, title, amount, income_date, source, note')
        .single();

    return Income.fromMap(row);
  }

  Future<void> deleteIncome(String id) async {
    await _supabase.from('incomes').delete().eq('id', id);
  }

  Future<List<RecurringExpense>> fetchRecurringExpenses() async {
    final rows = await _supabase
        .from('recurring_expenses')
        .select(recurringSelect)
        .order('next_due_date', ascending: true);

    return (rows as List)
        .map(
          (row) =>
              RecurringExpense.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<RecurringExpense> addRecurringExpense({
    required String title,
    required double amount,
    required ExpenseCategory category,
    required String paymentMethod,
    required String frequency,
    required DateTime nextDueDate,
    String note = '',
    bool autoPost = true,
  }) async {
    final user = _requireUser();
    final row = await _supabase
        .from('recurring_expenses')
        .insert({
          'user_id': user.id,
          'category_id': category.id,
          'title': title.trim(),
          'amount': amount,
          'payment_method': paymentMethod,
          'frequency': frequency,
          'next_due_date': _dateOnly(nextDueDate),
          'note': note.trim().isEmpty ? null : note.trim(),
          'auto_post': autoPost,
          'is_active': true,
        })
        .select(recurringSelect)
        .single();

    return RecurringExpense.fromMap(row);
  }

  Future<RecurringExpense> updateRecurringExpense(
    RecurringExpense recurring,
  ) async {
    final row = await _supabase
        .from('recurring_expenses')
        .update({
          'category_id': recurring.categoryId,
          'title': recurring.title.trim(),
          'amount': recurring.amount,
          'payment_method': recurring.paymentMethod,
          'frequency': recurring.frequency,
          'next_due_date': _dateOnly(recurring.nextDueDate),
          'note': recurring.note.trim().isEmpty ? null : recurring.note.trim(),
          'auto_post': recurring.autoPost,
          'is_active': recurring.isActive,
          'last_generated_date': recurring.lastGeneratedDate == null
              ? null
              : _dateOnly(recurring.lastGeneratedDate!),
        })
        .eq('id', recurring.id)
        .select(recurringSelect)
        .single();

    return RecurringExpense.fromMap(row);
  }

  Future<void> deleteRecurringExpense(String id) async {
    await _supabase.from('recurring_expenses').delete().eq('id', id);
  }

  Future<List<Expense>> createDueRecurringExpenses({
    required List<RecurringExpense> recurringExpenses,
    required List<ExpenseCategory> categories,
  }) async {
    final user = _requireUser();
    final today = DateTime.now();
    final created = <Expense>[];

    for (final recurring in recurringExpenses) {
      if (!recurring.isActive || !recurring.autoPost) continue;
      var dueDate = _dateOnlyDate(recurring.nextDueDate);
      final todayOnly = _dateOnlyDate(today);
      var safety = 0;

      while (!dueDate.isAfter(todayOnly) && safety < 24) {
        safety++;
        final duplicate = await _supabase
            .from('expenses')
            .select('id')
            .eq('user_id', user.id)
            .eq('recurring_expense_id', recurring.id)
            .eq('expense_date', _dateOnly(dueDate))
            .maybeSingle();

        if (duplicate == null) {
          final category = categories.firstWhere(
            (item) => item.id == recurring.categoryId,
            orElse: ExpenseCategory.fallback,
          );
          final expense = Expense(
            id: '',
            userId: user.id,
            categoryId: category.id,
            title: recurring.title,
            amount: recurring.amount,
            category: category,
            date: dueDate,
            paymentMethod: recurring.paymentMethod,
            note: recurring.note,
            recurringExpenseId: recurring.id,
          );
          final row = await _supabase
              .from('expenses')
              .insert(expense.toInsertMap(currentUserId: user.id))
              .select(
                'id, user_id, category_id, title, amount, expense_date, note, '
                'payment_method, receipt_url, recurring_expense_id, '
                'categories($categorySelect)',
              )
              .single();
          created.add(Expense.fromMap(row));
        }

        dueDate = nextDueDate(dueDate, recurring.frequency);
      }

      await _supabase
          .from('recurring_expenses')
          .update({
            'next_due_date': _dateOnly(dueDate),
            'last_generated_date': _dateOnly(todayOnly),
          })
          .eq('id', recurring.id);
    }

    return created;
  }

  Future<List<SavingsGoal>> fetchSavingsGoals() async {
    final rows = await _supabase
        .from('savings_goals')
        .select(
          'id, user_id, title, target_amount, saved_amount, target_date, note, is_completed',
        )
        .order('is_completed', ascending: true)
        .order('target_date', ascending: true);

    return (rows as List)
        .map(
          (row) => SavingsGoal.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<SavingsGoal> addSavingsGoal({
    required String title,
    required double targetAmount,
    double savedAmount = 0,
    DateTime? targetDate,
    String note = '',
  }) async {
    final user = _requireUser();
    final row = await _supabase
        .from('savings_goals')
        .insert({
          'user_id': user.id,
          'title': title.trim(),
          'target_amount': targetAmount,
          'saved_amount': savedAmount,
          'target_date': targetDate == null ? null : _dateOnly(targetDate),
          'note': note.trim().isEmpty ? null : note.trim(),
          'is_completed': savedAmount >= targetAmount,
        })
        .select(
          'id, user_id, title, target_amount, saved_amount, target_date, note, is_completed',
        )
        .single();

    return SavingsGoal.fromMap(row);
  }

  Future<SavingsGoal> updateSavingsGoal(SavingsGoal goal) async {
    final row = await _supabase
        .from('savings_goals')
        .update({
          'title': goal.title.trim(),
          'target_amount': goal.targetAmount,
          'saved_amount': goal.savedAmount,
          'target_date': goal.targetDate == null
              ? null
              : _dateOnly(goal.targetDate!),
          'note': goal.note.trim().isEmpty ? null : goal.note.trim(),
          'is_completed':
              goal.isCompleted || goal.savedAmount >= goal.targetAmount,
        })
        .eq('id', goal.id)
        .select(
          'id, user_id, title, target_amount, saved_amount, target_date, note, is_completed',
        )
        .single();

    return SavingsGoal.fromMap(row);
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _supabase.from('savings_goals').delete().eq('id', id);
  }

  Future<String> uploadReceiptImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _requireUser();
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await _supabase.storage
        .from('receipts')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
    return _supabase.storage.from('receipts').getPublicUrl(path);
  }

  static DateTime nextDueDate(DateTime from, String frequency) {
    switch (frequency) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      case 'monthly':
      default:
        final nextMonth = DateTime(from.year, from.month + 1, 1);
        final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final day = from.day > maxDay ? maxDay : from.day;
        return DateTime(nextMonth.year, nextMonth.month, day);
    }
  }

  User _requireUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('No logged-in user found.');
    return user;
  }

  static DateTime _dateOnlyDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
