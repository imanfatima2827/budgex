class ExpenseFilter {
  const ExpenseFilter({
    this.searchText = '',
    this.categoryId,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  final String searchText;
  final String? categoryId;
  final String? paymentMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;

  bool get hasActiveFilters {
    return searchText.trim().isNotEmpty ||
        categoryId != null ||
        paymentMethod != null ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null;
  }

  ExpenseFilter copyWith({
    String? searchText,
    String? categoryId,
    bool clearCategory = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
  }) {
    return ExpenseFilter(
      searchText: searchText ?? this.searchText,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      paymentMethod: clearPaymentMethod
          ? null
          : paymentMethod ?? this.paymentMethod,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      minAmount: clearMinAmount ? null : minAmount ?? this.minAmount,
      maxAmount: clearMaxAmount ? null : maxAmount ?? this.maxAmount,
    );
  }
}
