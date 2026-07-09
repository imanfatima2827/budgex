import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/expense.dart';

class ExpenseService {
  ExpenseService({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  static const _expenseSelect =
      'id, user_id, category_id, title, amount, expense_date, note, payment_method, receipt_url, recurring_expense_id, '
      'categories(id, user_id, name, icon_name, color_hex, is_default)';

  Future<List<Expense>> fetchExpenses() async {
    final rows = await _supabase
        .from('expenses')
        .select(_expenseSelect)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List).map((row) {
      return Expense.fromMap(Map<String, dynamic>.from(row as Map));
    }).toList();
  }

  Future<Expense> addExpense({
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
    required String paymentMethod,
    String note = '',
    String? receiptUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('No logged-in user found.');

    final expense = Expense(
      id: '',
      userId: user.id,
      categoryId: category.id,
      title: title,
      amount: amount,
      category: category,
      date: date,
      paymentMethod: paymentMethod,
      note: note,
      receiptUrl: receiptUrl,
    );

    final row = await _supabase
        .from('expenses')
        .insert(expense.toInsertMap(currentUserId: user.id))
        .select(_expenseSelect)
        .single();

    return Expense.fromMap(row);
  }

  Future<Expense> updateExpense(Expense expense) async {
    final row = await _supabase
        .from('expenses')
        .update(expense.toUpdateMap())
        .eq('id', expense.id)
        .select(_expenseSelect)
        .single();

    return Expense.fromMap(row);
  }

  Future<void> deleteExpense(String id) async {
    await _supabase.from('expenses').delete().eq('id', id);
  }
}
