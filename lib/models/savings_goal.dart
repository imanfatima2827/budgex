class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.targetDate,
    this.note = '',
    this.isCompleted = false,
  });

  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate;
  final String note;
  final bool isCompleted;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  double get remaining => (targetAmount - savedAmount).clamp(0.0, double.infinity);

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      targetAmount: _toDouble(map['target_amount']),
      savedAmount: _toDouble(map['saved_amount']),
      targetDate: map['target_date'] == null ? null : DateTime.tryParse(map['target_date'].toString()),
      note: map['note']?.toString() ?? '',
      isCompleted: map['is_completed'] == true,
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? note,
    bool? isCompleted,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: clearTargetDate ? null : targetDate ?? this.targetDate,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
