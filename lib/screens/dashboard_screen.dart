import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/spending_insight.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_scaled_text.dart';
import '../widgets/donut_chart.dart';
import '../widgets/expense_tile.dart';
import '../widgets/section_title.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'category_budgets_screen.dart';
import 'savings_goals_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onSeeAllTap});

  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ExpenseProvider>();

    final now = DateTime.now();
    final expenseTotal = provider.totalForMonth(now);
    final incomeTotal = provider.incomeForMonth(now);
    final savings = provider.savingsForMonth(now);
    final savingsRate = provider.savingsRate(now);
    final comparison = provider.comparisonPercentage(now);
    final budget = auth.monthlyBudget;
    final budgetProgress = budget <= 0
        ? 0.0
        : (expenseTotal / budget).clamp(0.0, 1.0).toDouble();
    final remainingBudget = (budget - expenseTotal).clamp(0.0, double.infinity);
    final categoryTotals = provider.categoryTotals(now);
    final recent = provider.recentExpenses(limit: 3);
    final insights = provider.insightsForMonth(now, monthlyBudget: budget);
    final displayName = auth.name.trim().isEmpty
        ? 'USER'
        : auth.name.trim().toUpperCase();

    return Container(
      color: AppTheme.scaffoldColor(context),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                  padding: EdgeInsets.zero,
                  title: 'HI! $displayName',
                  subtitle:
                      'Track smarter today, spend with confidence tomorrow.',
                  trailing: IconButton.filledTonal(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddIncomeScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_card_rounded),
                    tooltip: 'Add income',
                  ),
                ),
                const SizedBox(height: 20),
                _HeroFinanceCard(
                  income: incomeTotal,
                  expense: expenseTotal,
                  savings: savings,
                  savingsRate: savingsRate,
                  budgetProgress: budgetProgress,
                  remainingBudget: remainingBudget,
                  month: now,
                  currency: auth.currencySymbol,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        icon: comparison <= 0
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        title: 'Month change',
                        value:
                            '${comparison >= 0 ? '+' : ''}${comparison.toStringAsFixed(1)}%',
                        positive: comparison <= 0,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.speed_rounded,
                        title: 'Daily Average',
                        value: formatCurrency(
                          provider.averageDailySpend(now),
                          symbol: auth.currencySymbol,
                        ),
                        positive: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'Top Category',
                        value: _topCategoryName(categoryTotals),
                        positive: true,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'Transactions',
                        value: '${provider.expensesForMonth(now).length}',
                        positive: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SectionTitle(
                  title: 'Budget Alerts & Insights',
                  actionText: 'Goals',
                  onActionTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavingsGoalsScreen(),
                    ),
                  ),
                ),
                if (insights.isEmpty)
                  AppCard(
                    child: Text(
                      'Add income and expenses to unlock smart spending insights.',
                      style: TextStyle(
                        color: AppTheme.bodyColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Column(
                    children: insights
                        .map((insight) => _InsightCard(insight: insight))
                        .toList(),
                  ),
                SizedBox(height: 24),
                SectionTitle(
                  title: 'Category Budgets',
                  actionText: 'Manage',
                  onActionTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryBudgetsScreen(),
                    ),
                  ),
                ),
                _CategoryBudgetPreview(currency: auth.currencySymbol),
                SizedBox(height: 24),
                SectionTitle(title: 'Category Breakdown'),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: categoryTotals.isEmpty
                      ? _EmptyInline(
                          title: 'No expenses yet',
                          message:
                              'Start tracking your spending by adding your first expense.',
                          buttonText: 'Add Expense',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            DonutChart(data: categoryTotals, size: 138),
                            SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                children: categoryTotals.entries.map((entry) {
                                  final percentage = expenseTotal <= 0
                                      ? 0
                                      : (entry.value / expenseTotal) * 100;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 10,
                                          width: 10,
                                          decoration: BoxDecoration(
                                            color: entry.key.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: AppScaledText(
                                            entry.key.name,
                                            minFontSize: 8,
                                            style: TextStyle(
                                              color: AppTheme.titleColor(
                                                context,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: AppTheme.titleColor(context),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: 24),
                SectionTitle(
                  title: 'Recent Expenses',
                  actionText: 'See All',
                  onActionTap: onSeeAllTap,
                ),
                if (recent.isEmpty)
                  AppCard(
                    child: _EmptyInline(
                      title: 'No recent expenses',
                      message: 'Add your first transaction to see it here.',
                      buttonText: 'Add Expense',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddExpenseScreen(),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: recent.map((expense) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: ExpenseTile(
                              expense: expense,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddExpenseScreen(expense: expense),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _topCategoryName(Map<ExpenseCategory, double> categoryTotals) {
    if (categoryTotals.isEmpty) return 'None';
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key.name;
  }
}

class _HeroFinanceCard extends StatelessWidget {
  const _HeroFinanceCard({
    required this.income,
    required this.expense,
    required this.savings,
    required this.savingsRate,
    required this.budgetProgress,
    required this.remainingBudget,
    required this.month,
    required this.currency,
  });

  final double income;
  final double expense;
  final double savings;
  final double savingsRate;
  final double budgetProgress;
  final double remainingBudget;
  final DateTime month;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatMonth(month),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Income',
                  value: formatCurrency(income, symbol: currency),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Expenses',
                  value: formatCurrency(expense, symbol: currency),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Savings',
                  value: formatCurrency(savings, symbol: currency),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Savings Rate',
                  value: '${savingsRate.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly budget usage',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(budgetProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: budgetProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Remaining: ${formatCurrency(remainingBudget, symbol: currency)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetPreview extends StatelessWidget {
  const _CategoryBudgetPreview({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final now = DateTime.now();
    final budgets = provider.categoryBudgets.take(4).toList();
    if (budgets.isEmpty) {
      return AppCard(
        child: _EmptyInline(
          title: 'No category budgets set',
          message: 'Set limits for Food, Transport, Shopping and Bills.',
          buttonText: 'Set Budgets',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryBudgetsScreen()),
          ),
        ),
      );
    }
    return AppCard(
      child: Column(
        children: budgets.map((budget) {
          final category =
              budget.category ?? provider.categoryById(budget.categoryId);
          final spent = provider.categorySpendingForMonth(
            budget.categoryId,
            now,
          );
          final progress = budget.monthlyLimit <= 0
              ? 0.0
              : (spent / budget.monthlyLimit).clamp(0.0, 1.0).toDouble();
          final overBudget = spent > budget.monthlyLimit;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: AppTheme.titleColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${formatCurrency(spent, symbol: currency)} / '
                      '${formatCurrency(budget.monthlyLimit, symbol: currency)}',
                      style: TextStyle(
                        color: overBudget
                            ? AppTheme.danger
                            : AppTheme.bodyColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: category.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overBudget ? AppTheme.danger : category.color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final SpendingInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = insight.isWarning
        ? AppTheme.warning
        : (insight.isPositive ? AppTheme.success : AppTheme.primary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(insight.icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: TextStyle(
                      color: AppTheme.titleColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    insight.message,
                    style: TextStyle(
                      color: AppTheme.bodyColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.positive,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppTheme.success : AppTheme.danger;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppScaledText(
                  title,
                  minFontSize: 8,
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                AppScaledText(
                  value,
                  minFontSize: 10,
                  style: TextStyle(
                    color: AppTheme.titleColor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onTap,
  });

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wallet_outlined, color: AppTheme.primary, size: 34),
        SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.titleColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.bodyColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton(onPressed: onTap, child: Text(buttonText)),
      ],
    );
  }
}
