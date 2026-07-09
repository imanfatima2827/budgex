import 'category.dart';

class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.paymentMethod,
    this.categoryId,
    this.category,
    this.note = '',
    this.isActive = true,
    this.autoPost = true,
    this.lastGeneratedDate,
  });

  final String id;
  final String userId;
  final String? categoryId;
  final ExpenseCategory? category;
  final String title;
  final double amount;
  final String paymentMethod;
  final String frequency;
  final DateTime nextDueDate;
  final String note;
  final bool isActive;
  final bool autoPost;
  final DateTime? lastGeneratedDate;

  factory RecurringExpense.fromMap(Map<String, dynamic> map) {
    final rawCategory = map['categories'];
    return RecurringExpense(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString(),
      category: rawCategory is Map
          ? ExpenseCategory.fromMap(Map<String, dynamic>.from(rawCategory))
          : null,
      title: map['title']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      paymentMethod: map['payment_method']?.toString() ?? 'Cash',
      frequency: map['frequency']?.toString() ?? 'monthly',
      nextDueDate: _parseDate(map['next_due_date']),
      note: map['note']?.toString() ?? '',
      isActive: map['is_active'] != false,
      autoPost: map['auto_post'] != false,
      lastGeneratedDate: map['last_generated_date'] == null
          ? null
          : _parseDate(map['last_generated_date']),
    );
  }

  RecurringExpense copyWith({
    String? id,
    String? userId,
    String? categoryId,
    ExpenseCategory? category,
    String? title,
    double? amount,
    String? paymentMethod,
    String? frequency,
    DateTime? nextDueDate,
    String? note,
    bool? isActive,
    bool? autoPost,
    DateTime? lastGeneratedDate,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      autoPost: autoPost ?? this.autoPost,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
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
}
