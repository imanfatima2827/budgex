import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _controller = TextEditingController();
  bool _isImporting = false;

  static const _sample = 'Date,Title,Category,Amount,Payment Method,Note\n'
      '2026-06-01,Lunch,Food,850,Cash,Office lunch\n'
      '2026-06-02,Bus,Transport,120,Cash,Daily commute';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    if (_controller.text.trim().isEmpty || _isImporting) return;
    final provider = context.read<ExpenseProvider>();
    setState(() => _isImporting = true);
    try {
      await provider.importExpensesFromCsv(_controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV imported successfully')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(title: Text('Import CSV')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSV format',
                      style: TextStyle(
                        color: AppTheme.titleColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    SelectableText(
                      _sample,
                      style: TextStyle(
                        color: AppTheme.bodyColor(context),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _controller.text = _sample),
                      icon: Icon(Icons.content_paste_rounded),
                      label: Text('Use Sample'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _controller,
                  minLines: 12,
                  maxLines: 18,
                  decoration: InputDecoration(
                    labelText: 'Paste CSV here',
                    alignLabelWithHint: true,
                    hintText: _sample,
                  ),
                ),
              ),
              SizedBox(height: 20),
              PrimaryButton(
                label: _isImporting ? 'Importing...' : 'Import Expenses',
                icon: Icons.upload_file_rounded,
                onPressed: _isImporting ? null : _import,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
