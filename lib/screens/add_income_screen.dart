import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/income.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key, this.income});

  final Income? income;

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  String _source = 'Salary';
  bool _isSaving = false;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    _titleController = TextEditingController(text: income?.title ?? '');
    _amountController = TextEditingController(text: income == null ? '' : income.amount.toStringAsFixed(0));
    _noteController = TextEditingController(text: income?.note ?? '');
    _selectedDate = income?.date ?? DateTime.now();
    _source = income?.source ?? 'Salary';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    setState(() => _isSaving = true);
    final provider = context.read<ExpenseProvider>();
    try {
      if (_isEditing) {
        await provider.updateIncome(widget.income!.copyWith(
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          source: _source,
          note: _noteController.text.trim(),
        ));
      } else {
        await provider.addIncome(
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          source: _source,
          note: _noteController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = context.watch<ExpenseProvider>().incomeSources;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(title: Text(_isEditing ? 'Edit Income' : 'Add Income')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Income title',
                          hintText: 'Salary, freelance payment...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Title must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Amount', hintText: '1,368'),
                        validator: (value) {
                          final amount = double.tryParse((value ?? '').replaceAll(',', '').trim()) ?? 0;
                          return amount <= 0 ? 'Amount must be greater than 0' : null;
                        },
                      ),
                      SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: sources.contains(_source) ? _source : sources.first,
                        decoration: const InputDecoration(labelText: 'Source'),
                        isExpanded: true,
                        items: sources
                            .map(
                              (source) => DropdownMenuItem(
                                value: source,
                                child: Text(source),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _source = value);
                        },
                      ),
                      SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
                        title: Text('Income date'),
                        subtitle: Text(
                          formatDate(_selectedDate),
                          style: TextStyle(
                            color: AppTheme.titleColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: TextButton(onPressed: _pickDate, child: Text('Change')),
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Note', hintText: 'Optional details'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                PrimaryButton(
                  label: _isEditing ? 'Update Income' : 'Add Income',
                  icon: Icons.add_card_rounded,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
