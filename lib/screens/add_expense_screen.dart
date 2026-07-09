import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/primary_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense, this.preselectedCategory});

  final Expense? expense;
  final ExpenseCategory? preselectedCategory;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  ExpenseCategory? _selectedCategory;
  String _paymentMethod = 'Cash';
  String? _receiptUrl;
  Uint8List? _receiptBytes;
  String? _receiptFileName;
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: expense?.note ?? '');
    _selectedDate = expense?.date ?? DateTime.now();
    _selectedCategory = expense?.category ?? widget.preselectedCategory;
    _paymentMethod = expense?.paymentMethod ?? 'Cash';
    _receiptUrl = expense?.receiptUrl;
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

  Future<void> _pickReceipt() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _receiptBytes = bytes;
      _receiptFileName = file.name.isEmpty ? 'receipt.jpg' : file.name;
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final categoryName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (categoryName == null || categoryName.isEmpty || !mounted) return;
    try {
      final created = await context.read<ExpenseProvider>().addCategory(
        categoryName,
      );
      if (mounted) setState(() => _selectedCategory = created);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select or add a category')));
      return;
    }
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    final provider = context.read<ExpenseProvider>();
    setState(() => _isSaving = true);

    try {
      var receiptUrl = _receiptUrl;
      if (_receiptBytes != null) {
        receiptUrl = await provider.uploadReceiptImage(
          bytes: _receiptBytes!,
          fileName: _receiptFileName ?? 'receipt.jpg',
        );
      }

      if (_isEditing) {
        await provider.updateExpense(
          widget.expense!.copyWith(
            title: _titleController.text.trim(),
            amount: amount,
            category: _selectedCategory,
            categoryId: _selectedCategory!.id,
            date: _selectedDate,
            paymentMethod: _paymentMethod,
            note: _noteController.text.trim(),
            receiptUrl: receiptUrl,
            clearReceiptUrl: receiptUrl == null,
          ),
        );
      } else {
        await provider.addExpense(
          title: _titleController.text.trim(),
          amount: amount,
          category: _selectedCategory!,
          date: _selectedDate,
          paymentMethod: _paymentMethod,
          note: _noteController.text.trim(),
          receiptUrl: receiptUrl,
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
    final provider = context.watch<ExpenseProvider>();
    final paymentMethods = provider.paymentMethods;
    final dropdownOptions = paymentMethods.isEmpty
        ? <String>[_paymentMethod]
        : paymentMethods;
    final dropdownValue = dropdownOptions.contains(_paymentMethod)
        ? _paymentMethod
        : dropdownOptions.first;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Add Expense')),
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
                          labelText: 'Expense title',
                          hintText: 'Family expense',
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Title must be at least 2 characters'
                            : null,
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        cursorColor: AppTheme.primary,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          hintText: '1,368',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            (value ?? '').trim().replaceAll(',', ''),
                          );
                          if (amount == null || amount <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14),
                      AppDropdownField<String>(
                        label: 'Payment Method',
                        value: dropdownValue,
                        items: dropdownOptions,
                        labelBuilder: (method) => method,
                        prefixIcon: Icons.account_balance_wallet_outlined,
                        menuMaxHeight: 220,
                        onChanged: (value) =>
                            setState(() => _paymentMethod = value),
                      ),
                      SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.primary,
                        ),
                        title: Text('Expense date'),
                        subtitle: Text(
                          formatDate(_selectedDate),
                          style: TextStyle(
                            color: AppTheme.titleColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: _pickDate,
                          child: Text('Change'),
                        ),
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'Optional details',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Category',
                  style: TextStyle(
                    color: AppTheme.titleColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...provider.categories.map(_categoryChip),
                    _addCategoryChip(),
                  ],
                ),
                SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const AppIconBubble(
                        icon: Icons.receipt_long_outlined,
                        size: 44,
                        iconSize: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receipt image',
                              style: TextStyle(
                                color: AppTheme.titleColor(context),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              _receiptBytes != null
                                  ? _receiptFileName ?? 'Receipt selected'
                                  : (_receiptUrl == null || _receiptUrl!.isEmpty
                                        ? 'Attach proof of purchase'
                                        : 'Receipt already attached'),
                              style: TextStyle(
                                color: AppTheme.bodyColor(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickReceipt,
                        icon: Icon(Icons.upload_file_rounded),
                        label: Text('Upload'),
                      ),
                    ],
                  ),
                ),
                if (_receiptBytes != null) ...[
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _receiptBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                SizedBox(height: 24),
                PrimaryButton(
                  label: _isEditing ? 'Update Expense' : 'Add Expense',
                  icon: Icons.check_rounded,
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

  Widget _categoryChip(ExpenseCategory category) {
    final selected = _selectedCategory?.id == category.id;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.14)
              : AppTheme.softSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? category.color.withValues(alpha: 0.34)
                : AppTheme.borderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16, color: category.color),
            SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                color: selected ? category.color : AppTheme.titleColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addCategoryChip() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _showAddCategoryDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.softSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
            SizedBox(width: 6),
            Text(
              'Add',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
