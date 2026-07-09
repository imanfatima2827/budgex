import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/security_provider.dart';
import '../services/pdf_export_service.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_action_icon_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_scaled_text.dart';
import '../widgets/line_chart.dart';
import '../widgets/section_title.dart';
import 'category_breakdown_screen.dart';
import 'csv_export_preview_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _periodIndex = 2;
  DateTime _anchorDate = DateTime.now();
  bool _isSharingPdf = false;

  static const _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  DateTimeRange get _range {
    final anchor = _anchorDate;
    switch (_periodIndex) {
      case 0:
        final start = DateTime(anchor.year, anchor.month, anchor.day);
        return DateTimeRange(
          start: start,
          end: DateTime(anchor.year, anchor.month, anchor.day, 23, 59, 59),
        );
      case 1:
        final start = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
        ).subtract(Duration(days: anchor.weekday - 1));
        final end = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return DateTimeRange(start: start, end: end);
      case 3:
        return DateTimeRange(
          start: DateTime(anchor.year, 1, 1),
          end: DateTime(anchor.year, 12, 31, 23, 59, 59),
        );
      case 2:
      default:
        return DateTimeRange(
          start: startOfMonth(anchor),
          end: endOfMonth(anchor),
        );
    }
  }

  String get _rangeLabel {
    final range = _range;
    if (_periodIndex == 0) return formatDate(range.start);
    if (_periodIndex == 2) return formatMonth(range.start);
    if (_periodIndex == 3) return '${range.start.year}';
    return '${formatShortDate(range.start)} - ${formatShortDate(range.end)}';
  }

  void _movePeriod(int offset) {
    setState(() {
      switch (_periodIndex) {
        case 0:
          _anchorDate = _anchorDate.add(Duration(days: offset));
          break;
        case 1:
          _anchorDate = _anchorDate.add(Duration(days: offset * 7));
          break;
        case 3:
          _anchorDate = DateTime(
            _anchorDate.year + offset,
            _anchorDate.month,
            _anchorDate.day,
          );
          break;
        case 2:
        default:
          _anchorDate = DateTime(
            _anchorDate.year,
            _anchorDate.month + offset,
            1,
          );
      }
    });
  }

  Future<void> _sharePdf(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final auth = context.read<AuthProvider>();
    final security = context.read<SecurityProvider>();
    final range = _range;
    final expenses = provider.expenses
        .where(
          (expense) =>
              !expense.date.isBefore(range.start) &&
              !expense.date.isAfter(range.end),
        )
        .toList();
    setState(() => _isSharingPdf = true);
    security.suspendLock();
    try {
      final file = await PdfExportService.createExpenseReport(
        expenses: expenses,
        categoryTotals: provider.categoryTotalsForDateRange(
          range.start,
          range.end,
        ),
        startDate: range.start,
        endDate: range.end,
        currencySymbol: auth.currencySymbol,
        income: provider.incomeForDateRange(range.start, range.end),
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Budgex PDF report'),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      security.resumeLock();
      if (mounted) setState(() => _isSharingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final range = _range;
    final filteredExpenses = provider.expenses
        .where(
          (expense) =>
              !expense.date.isBefore(range.start) &&
              !expense.date.isAfter(range.end),
        )
        .toList();
    final total = filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final income = provider.incomeForDateRange(range.start, range.end);
    final savings = income - total;
    final dailyTotals = provider.dailyTotalsForDateRange(
      range.start,
      range.end,
    );
    final categoryTotals = provider.categoryTotalsForDateRange(
      range.start,
      range.end,
    );
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      color: AppTheme.scaffoldColor(context),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                padding: EdgeInsets.zero,
                title: 'Reports',
                subtitle:
                    'Understand trends and export clear spending summaries.',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppActionIconButton(
                      icon: Icons.picture_as_pdf_outlined,
                      tooltip: 'Share PDF',
                      onTap: _isSharingPdf ? null : () => _sharePdf(context),
                    ),
                    const SizedBox(width: 10),
                    AppActionIconButton(
                      icon: Icons.file_download_outlined,
                      tooltip: 'Export CSV',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CsvExportPreviewScreen(
                            startDate: range.start,
                            endDate: range.end,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              _PeriodSelector(
                periods: _periods,
                selectedIndex: _periodIndex,
                onChanged: (index) => setState(() => _periodIndex = index),
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _movePeriod(-1),
                    icon: Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _rangeLabel,
                        style: TextStyle(
                          color: AppTheme.titleColor(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _movePeriod(1),
                    icon: Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Income',
                      value: formatCurrency(
                        income,
                        symbol: auth.currencySymbol,
                      ),
                      icon: Icons.add_card_rounded,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Expenses',
                      value: formatCurrency(total, symbol: auth.currencySymbol),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const AppIconBubble(
                      icon: Icons.savings_outlined,
                      size: 52,
                      iconSize: 27,
                      borderRadius: 18,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Savings',
                            style: TextStyle(
                              color: AppTheme.bodyColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatCurrency(
                                savings,
                                symbol: auth.currencySymbol,
                              ),
                              style: TextStyle(
                                color: savings < 0
                                    ? AppTheme.danger
                                    : AppTheme.titleColor(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.softSurfaceColor(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '${filteredExpenses.length} records',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              const SectionTitle(title: 'Daily Spending'),
              AppCard(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: DailyLineChart(dailyTotals: dailyTotals),
              ),
              SizedBox(height: 24),
              SectionTitle(
                title: 'Top Categories',
                actionText: 'View Chart',
                onActionTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryBreakdownScreen(month: range.start),
                  ),
                ),
              ),
              AppCard(
                child: sortedCategories.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'No category data',
                        message:
                            'Add expenses in this period to see your top spending categories.',
                        compact: true,
                      )
                    : Column(
                        children: sortedCategories.map((entry) {
                          final percentage = total <= 0
                              ? 0
                              : entry.value / total;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: entry.key.color
                                          .withValues(alpha: 0.18),
                                      child: Icon(
                                        entry.key.icon,
                                        color: entry.key.color,
                                        size: 17,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: AppScaledText(
                                        entry.key.name,
                                        minFontSize: 10,
                                        style: TextStyle(
                                          color: AppTheme.titleColor(context),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${formatCurrency(entry.value, symbol: auth.currencySymbol)} '
                                      '(${(percentage * 100).toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        color: AppTheme.bodyColor(context),
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
                                    value: percentage.toDouble(),
                                    minHeight: 7,
                                    backgroundColor: entry.key.color.withValues(
                                      alpha: 0.12,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      entry.key.color,
                                    ),
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

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> periods;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(6),
      borderRadius: 18,
      child: Row(
        children: List.generate(periods.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    periods[index],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppTheme.titleColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                AppScaledText(
                  value,
                  minFontSize: 10,
                  style: TextStyle(
                    color: AppTheme.titleColor(context),
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
