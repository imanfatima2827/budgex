import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_filter.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_search_field.dart';
import '../widgets/expense_list_card.dart';
import '../widgets/filter_circle_button.dart';
import 'add_expense_screen.dart';
import 'search_filter_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  final _searchController = TextEditingController();
  ExpenseFilter _filter = const ExpenseFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilter() async {
    final result = await Navigator.push<ExpenseFilter>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchFilterScreen(initialFilter: _filter),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _filter = result;
      _searchController.text = result.searchText;
    });
  }

  void _openAddExpense() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final currency = context.watch<AuthProvider>().currencySymbol;
    final activeFilter = _filter.copyWith(searchText: _searchController.text);
    final expenses = expenseProvider.filteredExpenses(activeFilter);
    final total = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    return ColoredBox(
      color: AppTheme.scaffoldColor(context),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppPageHeader(
              title: 'Expenses',
              subtitle: 'Review, search, edit and delete your spending records.',
              trailing: FilterCircleButton(
                hasActiveFilters: _filter.hasActiveFilters,
                onTap: _openFilter,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Search by title, category, or note...',
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ExpenseSummaryCard(
                records: expenses.length,
                total: total,
                currency: currency,
                hasFilters: activeFilter.hasActiveFilters,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: expenses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                      child: Center(
                        child: AppEmptyState(
                          icon: activeFilter.hasActiveFilters
                              ? Icons.manage_search_rounded
                              : Icons.receipt_long_outlined,
                          title: activeFilter.hasActiveFilters ? 'No matching expenses' : 'No expenses yet',
                          message: activeFilter.hasActiveFilters
                              ? 'Try adjusting the search text or filter options.'
                              : 'Add your first expense to start tracking where your money goes.',
                          actionLabel: activeFilter.hasActiveFilters ? null : 'Add Expense',
                          onAction: activeFilter.hasActiveFilters ? null : _openAddExpense,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                      itemCount: expenses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];

                        return ExpenseListCard(
                          expense: expense,
                          currency: currency,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddExpenseScreen(expense: expense),
                            ),
                          ),
                          onDelete: () => expenseProvider.deleteExpense(expense.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.records,
    required this.total,
    required this.currency,
    required this.hasFilters,
  });

  final int records;
  final double total;
  final String currency;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor(context).withValues(alpha: 0.78),
        ),
        boxShadow: [AppTheme.themedSoftShadow(context, alpha: 0.04, blur: 14)],
      ),
      child: Row(
        children: [
          const AppIconBubble(
            icon: Icons.receipt_long_rounded,
            size: 38,
            iconSize: 19,
            borderRadius: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFilters ? 'Filtered spending' : 'Total spending',
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$records ${records == 1 ? 'record' : 'records'}',
                  style: TextStyle(
                    color: AppTheme.titleColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '-${formatCurrency(total, symbol: currency)}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
