import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/security_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaled_text.dart';
import '../widgets/primary_button.dart';

class CsvExportPreviewScreen extends StatelessWidget {
  const CsvExportPreviewScreen({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  Future<void> _shareCsv(BuildContext context, String csv) async {
    final security = context.read<SecurityProvider>();
    security.suspendLock();
    try {
      final directory = await getTemporaryDirectory();
      final fileName =
          'expenses_${startDate.year}_${startDate.month.toString().padLeft(2, '0')}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Budgex CSV export'),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      security.resumeLock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final csv = expenseProvider.createCsv(
      startDate: startDate,
      endDate: endDate,
    );
    final total = expenseProvider.totalForDateRange(startDate, endDate);
    final records = csv.trim().isEmpty ? 0 : csv.split('\n').length - 1;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(
        title: Text('Export to CSV'),
        leading: _BackButton(onTap: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            children: [
              SizedBox(height: 6),
              Container(
                height: 96,
                width: 82,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    'CSV',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Export Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${formatDate(startDate)} – ${formatDate(endDate)}',
                style: TextStyle(
                  color: AppTheme.bodyColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Total Records',
                      value: '$records',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Total Amount',
                      value: formatCurrency(total, symbol: auth.currencySymbol),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              PrimaryButton(
                label: 'Share CSV File',
                icon: Icons.ios_share_rounded,
                onPressed: () => _shareCsv(context, csv),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV copied to clipboard'),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.copy_rounded),
                  label: Text('Copy CSV'),
                ),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.72,
                      minChildSize: 0.4,
                      maxChildSize: 0.92,
                      builder: (context, scrollController) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: SelectableText(csv),
                        ),
                      ),
                    ),
                  ),
                  icon: Icon(Icons.visibility_outlined),
                  label: Text('Preview Data'),
                ),
              ),
              SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    csv,
                    maxLines: 10,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppTheme.titleColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppScaledText(
            label,
            minFontSize: 9,
            style: TextStyle(
              color: AppTheme.bodyColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          AppScaledText(
            value,
            minFontSize: 10,
            style: TextStyle(
              color: AppTheme.titleColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
