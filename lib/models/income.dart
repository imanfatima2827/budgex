class Income {
  const Income({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.date,
    this.source = 'Salary',
    this.note = '',
  });

  final String id;
  final String userId;
  final String title;
  final double amount;
  final DateTime date;
  final String source;
  final String note;

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      date: _parseDate(map['income_date']),
      source: map['source']?.toString().trim().isNotEmpty == true
          ? map['source'].toString()
          : 'Salary',
      note: map['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toInsertMap({required String currentUserId}) {
    return {
      'user_id': currentUserId,
      'title': title.trim(),
      'amount': amount,
      'income_date': _dateOnly(date),
      'source': source.trim().isEmpty ? 'Salary' : source.trim(),
      'note': note.trim().isEmpty ? null : note.trim(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title.trim(),
      'amount': amount,
      'income_date': _dateOnly(date),
      'source': source.trim().isEmpty ? 'Salary' : source.trim(),
      'note': note.trim().isEmpty ? null : note.trim(),
    };
  }

  Income copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    DateTime? date,
    String? source,
    String? note,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      source: source ?? this.source,
      note: note ?? this.note,
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
