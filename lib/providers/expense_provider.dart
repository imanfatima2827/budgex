import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/expense_filter.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/savings_goal.dart';
import '../models/spending_insight.dart';
import '../services/category_service.dart';
import '../services/csv_export_service.dart';
import '../services/expense_service.dart';
import '../services/finance_service.dart';
import '../utils/date_helpers.dart';
import '../utils/error_messages.dart';

part 'expense_provider_analytics.dart';
part 'expense_provider_csv.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({
    ExpenseService? expenseService,
    CategoryService? categoryService,
    FinanceService? financeService,
  })  : _expenseService = expenseService ?? ExpenseService(),
        _categoryService = categoryService ?? CategoryService(),
        _financeService = financeService ?? FinanceService();

  static const List<String> _paymentMethods = [
    'Cash',
    'Card',
    'Bank Transfer',
    'Wallet',
  ];
  static const List<String> _incomeSources = [
    'Salary',
    'Business',
    'Freelance',
    'Gift',
    'Investment',
    'Other',
  ];
  static const List<String> _recurringFrequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  final ExpenseService _expenseService;
  final CategoryService _categoryService;
  final FinanceService _financeService;

  bool _isLoading = false;
  String? _error;
  final List<ExpenseCategory> _categories = [];
  final List<Expense> _expenses = [];
  final List<CategoryBudget> _categoryBudgets = [];
  final List<Income> _incomes = [];
  final List<RecurringExpense> _recurringExpenses = [];
  final List<SavingsGoal> _savingsGoals = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get paymentMethods => _paymentMethods;
  List<String> get incomeSources => _incomeSources;
  List<String> get recurringFrequencies => _recurringFrequencies;

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);
  List<CategoryBudget> get categoryBudgets => List.unmodifiable(_categoryBudgets);

  List<Income> get incomes {
    final copy = List<Income>.from(_incomes);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  List<RecurringExpense> get recurringExpenses {
    final copy = List<RecurringExpense>.from(_recurringExpenses);
    copy.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return copy;
  }

  List<SavingsGoal> get savingsGoals {
    final copy = List<SavingsGoal>.from(_savingsGoals);
    copy.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final aDate = a.targetDate;
      final bDate = b.targetDate;
      if (aDate == null && bDate == null) return a.title.compareTo(b.title);
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return copy;
  }

  List<Expense> get expenses {
    final copy = List<Expense>.from(_expenses);
    copy.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
    });
    return copy;
  }

  Future<void> initialize() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      clear();
      return;
    }
    await _run(() async {
      final loadedCategories = await _categoryService.fetchCategories();
      _categories
        ..clear()
        ..addAll(loadedCategories);

      final loadedRecurring = await _financeService.fetchRecurringExpenses();
      _recurringExpenses
        ..clear()
        ..addAll(loadedRecurring.map(_recurringWithKnownCategory));

      final autoCreated = await _financeService.createDueRecurringExpenses(
        recurringExpenses: _recurringExpenses,
        categories: _categories,
      );

      final loadedExpenses = await _expenseService.fetchExpenses();
      final loadedBudgets = await _financeService.fetchCategoryBudgets();
      final loadedIncomes = await _financeService.fetchIncomes();
      final refreshedRecurring = await _financeService.fetchRecurringExpenses();
      final loadedGoals = await _financeService.fetchSavingsGoals();

      _expenses
        ..clear()
        ..addAll(loadedExpenses.map(_withKnownCategory));
      for (final created in autoCreated.map(_withKnownCategory)) {
        if (_expenses.every((expense) => expense.id != created.id)) {
          _expenses.add(created);
        }
      }
      _categoryBudgets
        ..clear()
        ..addAll(loadedBudgets.map(_budgetWithKnownCategory));
      _incomes
        ..clear()
        ..addAll(loadedIncomes);
      _recurringExpenses
        ..clear()
        ..addAll(refreshedRecurring.map(_recurringWithKnownCategory));
      _savingsGoals
        ..clear()
        ..addAll(loadedGoals);
    });
  }

  Future<void> refresh() => initialize();

  void clear() {
    _isLoading = false;
    _categories.clear();
    _expenses.clear();
    _categoryBudgets.clear();
    _incomes.clear();
    _recurringExpenses.clear();
    _savingsGoals.clear();
    _error = null;
    notifyListeners();
  }

  ExpenseCategory categoryById(String id) {
    return _categories.firstWhere(
      (category) => category.id == id,
      orElse: () => _otherCategory,
    );
  }

  Future<ExpenseCategory> addCategory(String name) async {
    late ExpenseCategory created;
    await _run(() async {
      created = await _categoryService.addCategory(name);
      _categories.add(created);
    });
    return created;
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    required String paymentMethod,
    String note = '',
    String? receiptUrl,
  }) async {
    await _run(() async {
      final created = await _expenseService.addExpense(
        title: title,
        amount: amount,
        category: category,
        date: date,
        paymentMethod: paymentMethod,
        note: note,
        receiptUrl: receiptUrl,
      );
      _expenses.add(_withKnownCategory(created));
    });
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    await _run(() async {
      final updated = await _expenseService.updateExpense(updatedExpense);
      _upsertExpense(_withKnownCategory(updated));
    });
  }

  Future<void> deleteExpense(String id) async {
    await _run(() async {
      await _expenseService.deleteExpense(id);
      _expenses.removeWhere((expense) => expense.id == id);
    });
  }

  Future<String> uploadReceiptImage({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _financeService.uploadReceiptImage(
      bytes: bytes,
      fileName: fileName,
    );
  }

  Future<void> setCategoryBudget({
    required ExpenseCategory category,
    required double monthlyLimit,
  }) async {
    await _run(() async {
      final saved = await _financeService.upsertCategoryBudget(
        category: category,
        monthlyLimit: monthlyLimit,
      );
      final normalized = _budgetWithKnownCategory(saved);
      _upsertCategoryBudget(normalized);
    });
  }

  Future<void> deleteCategoryBudget(String id) async {
    await _run(() async {
      await _financeService.deleteCategoryBudget(id);
      _categoryBudgets.removeWhere((budget) => budget.id == id);
    });
  }

  Future<void> addIncome({
    required String title,
    required double amount,
    required DateTime date,
    required String source,
    String note = '',
  }) async {
    await _run(() async {
      final created = await _financeService.addIncome(
        title: title,
        amount: amount,
        date: date,
        source: source,
        note: note,
      );
      _incomes.add(created);
    });
  }

  Future<void> updateIncome(Income income) async {
    await _run(() async {
      final updated = await _financeService.updateIncome(income);
      _upsertIncome(updated);
    });
  }

  Future<void> deleteIncome(String id) async {
    await _run(() async {
      await _financeService.deleteIncome(id);
      _incomes.removeWhere((income) => income.id == id);
    });
  }

  Future<void> addRecurringExpense({
    required String title,
    required double amount,
    required ExpenseCategory category,
    required String paymentMethod,
    required String frequency,
    required DateTime nextDueDate,
    String note = '',
    bool autoPost = true,
  }) async {
    await _run(() async {
      final created = await _financeService.addRecurringExpense(
        title: title,
        amount: amount,
        category: category,
        paymentMethod: paymentMethod,
        frequency: frequency,
        nextDueDate: nextDueDate,
        note: note,
        autoPost: autoPost,
      );
      _recurringExpenses.add(_recurringWithKnownCategory(created));
    });
  }

  Future<void> updateRecurringExpense(RecurringExpense recurring) async {
    await _run(() async {
      final updated = await _financeService.updateRecurringExpense(recurring);
      _upsertRecurring(_recurringWithKnownCategory(updated));
    });
  }

  Future<void> setRecurringExpenseActive(
    RecurringExpense recurring,
    bool isActive,
  ) async {
    final index = _recurringExpenses.indexWhere(
      (item) => item.id == recurring.id,
    );
    final previous = index == -1 ? null : _recurringExpenses[index];
    final optimistic = _recurringWithKnownCategory(
      recurring.copyWith(isActive: isActive),
    );

    _upsertRecurring(optimistic);
    _error = null;
    notifyListeners();

    try {
      final updated = await _financeService.updateRecurringExpense(optimistic);
      _upsertRecurring(_recurringWithKnownCategory(updated));
    } catch (error) {
      if (previous == null) {
        _recurringExpenses.removeWhere((item) => item.id == recurring.id);
      } else {
        _upsertRecurring(previous);
      }
      _error = friendlySupabaseMessage(error);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteRecurringExpense(String id) async {
    await _run(() async {
      await _financeService.deleteRecurringExpense(id);
      _recurringExpenses.removeWhere((recurring) => recurring.id == id);
    });
  }

  Future<void> addSavingsGoal({
    required String title,
    required double targetAmount,
    double savedAmount = 0,
    DateTime? targetDate,
    String note = '',
  }) async {
    await _run(() async {
      final created = await _financeService.addSavingsGoal(
        title: title,
        targetAmount: targetAmount,
        savedAmount: savedAmount,
        targetDate: targetDate,
        note: note,
      );
      _savingsGoals.add(created);
    });
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _run(() async {
      final updated = await _financeService.updateSavingsGoal(goal);
      _upsertSavingsGoal(updated);
    });
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _run(() async {
      await _financeService.deleteSavingsGoal(id);
      _savingsGoals.removeWhere((goal) => goal.id == id);
    });
  }

  Expense _withKnownCategory(Expense expense) {
    final matched = _categories.where(
      (category) => category.id == expense.category.id,
    );
    if (matched.isEmpty) return expense;
    return expense.copyWith(
      category: matched.first,
      categoryId: matched.first.id,
    );
  }

  CategoryBudget _budgetWithKnownCategory(CategoryBudget budget) {
    final matched = _categories.where(
      (category) => category.id == budget.categoryId,
    );
    if (matched.isEmpty) return budget;
    return budget.copyWith(category: matched.first);
  }

  void _upsertExpense(Expense expense) {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      _expenses.add(expense);
    } else {
      _expenses[index] = expense;
    }
  }

  void _upsertCategoryBudget(CategoryBudget budget) {
    final index = _categoryBudgets.indexWhere(
      (item) => item.categoryId == budget.categoryId,
    );
    if (index == -1) {
      _categoryBudgets.add(budget);
    } else {
      _categoryBudgets[index] = budget;
    }
  }

  void _upsertIncome(Income income) {
    final index = _incomes.indexWhere((item) => item.id == income.id);
    if (index == -1) {
      _incomes.add(income);
    } else {
      _incomes[index] = income;
    }
  }

  void _upsertSavingsGoal(SavingsGoal goal) {
    final index = _savingsGoals.indexWhere((item) => item.id == goal.id);
    if (index == -1) {
      _savingsGoals.add(goal);
    } else {
      _savingsGoals[index] = goal;
    }
  }

  void _upsertRecurring(RecurringExpense recurring) {
    final index = _recurringExpenses.indexWhere(
      (item) => item.id == recurring.id,
    );
    if (index == -1) {
      _recurringExpenses.add(recurring);
    } else {
      _recurringExpenses[index] = recurring;
    }
  }

  RecurringExpense _recurringWithKnownCategory(RecurringExpense recurring) {
    final matched = _categories.where(
      (category) => category.id == recurring.categoryId,
    );
    if (matched.isEmpty) return recurring;
    return recurring.copyWith(
      category: matched.first,
      categoryId: matched.first.id,
    );
  }

  ExpenseCategory get _otherCategory {
    return _categories.firstWhere(
      (category) => category.name.toLowerCase() == 'other',
      orElse: ExpenseCategory.fallback,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _error = friendlySupabaseMessage(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
