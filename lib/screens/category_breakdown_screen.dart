import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/month_option.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaled_text.dart';
import '../widgets/donut_chart.dart';

class CategoryBreakdownScreen extends StatefulWidget {
  const CategoryBreakdownScreen({super.key, required this.month});

  final DateTime month;

  @override
  State<CategoryBreakdownScreen> createState() =>
      _CategoryBreakdownScreenState();
}

class _CategoryBreakdownScreenState extends State<CategoryBreakdownScreen> {
  late final List<MonthOption> _months;
  late MonthOption _selectedMonth;

  @override
  void initState() {
    super.initState();
    _months = lastMonths(count: 8);
    _selectedMonth = _months.firstWhere(
      (month) => isSameMonth(month.start, widget.month),
      orElse: () => _months.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final total = expenses.totalForMonth(_selectedMonth.start);
    final categoryTotals = expenses.categoryTotals(_selectedMonth.start);
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final contentWidth = MediaQuery.sizeOf(context).width - 40;
    final monthDropdownWidth = contentWidth < 236 ? contentWidth : 236.0;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(
        title: Text('Category Breakdown'),
        leading: _BackButton(onTap: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: monthDropdownWidth,
                  child: DropdownButtonFormField<MonthOption>(
                    initialValue: _selectedMonth,
                    isExpanded: true,
                    dropdownColor: AppTheme.dropdownColor(context),
                    menuMaxHeight: 260,
                    borderRadius: BorderRadius.circular(20),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.primary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Month',
                      prefixIcon: Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    style: TextStyle(
                      color: AppTheme.titleColor(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    items: _months
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: AppScaledText(
                                month.label,
                                minFontSize: 10,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (month) {
                      if (month != null) {
                        setState(() => _selectedMonth = month);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Center(
                  child: DonutChart(
                    data: categoryTotals,
                    size: 220,
                    centerText:
                        '${formatCurrency(total, symbol: auth.currencySymbol)}\nTotal',
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Category Details',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10),
              AppCard(
                child: sorted.isEmpty
                    ? SizedBox(
                        height: 96,
                        child: Center(
                          child: Text(
                            'No expenses found',
                            style: TextStyle(
                              color: AppTheme.bodyColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: sorted.map((entry) {
                          final percentage = total <= 0
                              ? 0
                              : (entry.value / total) * 100;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              children: [
                                Container(
                                  height: 38,
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: entry.key.color.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    entry.key.icon,
                                    color: entry.key.color,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppScaledText(
                                        entry.key.name,
                                        minFontSize: 10,
                                        style: TextStyle(
                                          color: AppTheme.titleColor(context),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        '${percentage.toStringAsFixed(0)}% of total',
                                        style: TextStyle(
                                          color: AppTheme.bodyColor(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatCurrency(
                                    entry.value,
                                    symbol: auth.currencySymbol,
                                  ),
                                  style: TextStyle(
                                    color: AppTheme.titleColor(context),
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
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.titleColor(context),
            size: 20,
          ),
        ),
      ),
    );
  }
}
