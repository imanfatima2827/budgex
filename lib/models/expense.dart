import 'category.dart';

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.userId = '',
    this.categoryId,
    this.note = '',
    this.receiptUrl,
    this.recurringExpenseId,
  });

  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String paymentMethod;
  final String note;
  final String? receiptUrl;
  final String? recurringExpenseId;

  factory Expense.fromMap(Map<String, dynamic> map) {
    final rawCategory = map['categories'];
    final category = rawCategory is Map
        ? ExpenseCategory.fromMap(Map<String, dynamic>.from(rawCategory))
        : ExpenseCategory.fallback();

    return Expense(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString(),
      title: map['title']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      category: category,
      date: _parseDate(map['expense_date']),
      paymentMethod: map['payment_method']?.toString().trim().isNotEmpty == true
          ? map['payment_method'].toString()
          : 'Cash',
      note: map['note']?.toString() ?? '',
      receiptUrl: map['receipt_url']?.toString(),
      recurringExpenseId: map['recurring_expense_id']?.toString(),
    );
  }

  Map<String, dynamic> toInsertMap({required String currentUserId}) {
    return {
      'user_id': currentUserId,
      'category_id': category.id,
      'title': title.trim(),
      'amount': amount,
      'expense_date': _dateOnly(date),
      'note': note.trim().isEmpty ? null : note.trim(),
      'payment_method': paymentMethod,
      'receipt_url': receiptUrl,
      'recurring_expense_id': recurringExpenseId,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'category_id': category.id,
      'title': title.trim(),
      'amount': amount,
      'expense_date': _dateOnly(date),
      'note': note.trim().isEmpty ? null : note.trim(),
      'payment_method': paymentMethod,
      'receipt_url': receiptUrl,
    };
  }

  Expense copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? paymentMethod,
    String? note,
    String? receiptUrl,
    bool clearReceiptUrl = false,
    String? recurringExpenseId,
  }) {
    final nextCategory = category ?? this.category;
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? nextCategory.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: nextCategory,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      receiptUrl: clearReceiptUrl ? null : receiptUrl ?? this.receiptUrl,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
