import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/auth_provider.dart';
import 'expense_list_card.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AuthProvider>().currencySymbol;

    return ExpenseListCard(
      expense: expense,
      currency: currency,
      onTap: onTap,
      onDelete: onDelete,
      showPaymentMethod: false,
      showDeleteAction: onDelete != null,
      showCardDecoration: false,
      showAccentBar: true,
      borderRadius: 22,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
