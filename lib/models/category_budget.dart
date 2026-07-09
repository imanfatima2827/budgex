import 'category.dart';

class CategoryBudget {
  const CategoryBudget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.monthlyLimit,
    this.category,
  });

  final String id;
  final String userId;
  final String categoryId;
  final double monthlyLimit;
  final ExpenseCategory? category;

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    final rawCategory = map['categories'];
    return CategoryBudget(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      monthlyLimit: _toDouble(map['monthly_limit']),
      category: rawCategory is Map
          ? ExpenseCategory.fromMap(Map<String, dynamic>.from(rawCategory))
          : null,
    );
  }

  CategoryBudget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? monthlyLimit,
    ExpenseCategory? category,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      category: category ?? this.category,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
