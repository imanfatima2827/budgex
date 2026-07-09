import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/income.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_floating_add_button.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_scaled_text.dart';
import 'add_income_screen.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, Income income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete income?'),
        content: Text('This will remove “${income.title}” from your records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _deleteIncome(BuildContext context, Income income) async {
    try {
      await context.read<ExpenseProvider>().deleteIncome(income.id);
    } catch (error) {
      if (!context.mounted) return;
      final provider = context.read<ExpenseProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<AuthProvider>().currencySymbol;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(title: const Text('Income Tracking')),
      floatingActionButton: AppFloatingAddButton(
        tooltip: 'Add Income',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
        ),
      ),
      body: SafeArea(
        child: provider.incomes.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: AppEmptyState(
                    icon: Icons.add_card_rounded,
                    title: 'No income added',
                    message:
                        'Add salary, business, freelance or other income to see savings and savings rate.',
                    actionLabel: 'Add Income',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddIncomeScreen(),
                      ),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                itemCount: provider.incomes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final income = provider.incomes[index];
                  return Dismissible(
                    key: ValueKey(income.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context, income),
                    onDismissed: (_) => _deleteIncome(context, income),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddIncomeScreen(income: income),
                        ),
                      ),
                      child: Row(
                        children: [
                          const AppIconBubble(
                            icon: Icons.add_card_rounded,
                            color: AppTheme.success,
                            size: 46,
                            iconSize: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppScaledText(
                                  income.title,
                                  minFontSize: 10,
                                  style: TextStyle(
                                    color: AppTheme.titleColor(context),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${income.source} • ${formatDate(income.date)}',
                                  style: TextStyle(
                                    color: AppTheme.bodyColor(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${formatCurrency(income.amount, symbol: currency)}',
                                style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final confirmed = await _confirmDelete(
                                    context,
                                    income,
                                  );
                                  if (confirmed && context.mounted) {
                                    await _deleteIncome(context, income);
                                  }
                                },
                                borderRadius: BorderRadius.circular(13),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.danger.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppTheme.danger,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
