class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.currency,
    required this.monthlyBudget,
  });

  final String id;
  final String fullName;
  final String currency;
  final double monthlyBudget;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'PKR',
      monthlyBudget: _toDouble(map['monthly_budget']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'currency': currency,
      'monthly_budget': monthlyBudget,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? currency,
    double? monthlyBudget,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
