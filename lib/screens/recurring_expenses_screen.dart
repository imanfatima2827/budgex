import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/recurring_expense.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_floating_add_button.dart';
import '../widgets/app_scaled_text.dart';
import '../widgets/primary_button.dart';

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  Future<void> _changeActiveState(
    BuildContext context,
    RecurringExpense item,
    bool value,
  ) async {
    final provider = context.read<ExpenseProvider>();
    try {
      await provider.setRecurringExpenseActive(item, value);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? error.toString())),
      );
    }
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    RecurringExpense item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete recurring expense?'),
        content: Text('This will remove "${item.title}" from recurring bills.'),
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

  Future<void> _deleteRecurring(
    BuildContext context,
    RecurringExpense item,
  ) async {
    try {
      await context.read<ExpenseProvider>().deleteRecurringExpense(item.id);
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
      appBar: AppBar(title: const Text('Recurring Expenses')),
      floatingActionButton: AppFloatingAddButton(
        tooltip: 'Add Recurring Expense',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddRecurringExpenseScreen()),
        ),
      ),
      body: SafeArea(
        child: provider.recurringExpenses.isEmpty
            ? _EmptyRecurring(
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddRecurringExpenseScreen(),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                itemCount: provider.recurringExpenses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = provider.recurringExpenses[index];
                  final category =
                      item.category ??
                      provider.categoryById(item.categoryId ?? '');
                  return _RecurringExpenseCard(
                    item: item,
                    category: category,
                    currency: currency,
                    onActiveChanged: (value) =>
                        _changeActiveState(context, item, value),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddRecurringExpenseScreen(recurring: item),
                      ),
                    ),
                    onDelete: () async {
                      final confirmed = await _confirmDelete(context, item);
                      if (confirmed && context.mounted) {
                        await _deleteRecurring(context, item);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _RecurringExpenseCard extends StatelessWidget {
  const _RecurringExpenseCard({
    required this.item,
    required this.category,
    required this.currency,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringExpense item;
  final ExpenseCategory category;
  final String currency;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final paymentMethod = item.paymentMethod.trim();
    final frequencyLabel = item.frequency.trim().toUpperCase();
    final statusText = item.isActive ? 'Active' : 'Paused';

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIconBubble(
            icon: category.icon,
            color: category.color,
            size: 46,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppScaledText(
                  item.title,
                  minFontSize: 10,
                  style: TextStyle(
                    color: AppTheme.titleColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Repeat: $frequencyLabel',
                  maxLines: 1,
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Next: ${formatDate(item.nextDueDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.bodyColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paymentMethod.isEmpty
                      ? statusText
                      : '$paymentMethod - $statusText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.isActive
                        ? AppTheme.bodyColor(context)
                        : AppTheme.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 118),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppScaledText(
                  '-${formatCurrency(item.amount, symbol: currency)}',
                  maxLines: 1,
                  minFontSize: 10,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 32,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch(
                          value: item.isActive,
                          activeThumbColor: AppTheme.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: onActiveChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _DeleteCardButton(
                      tooltip: 'Delete Recurring',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteCardButton extends StatelessWidget {
  const _DeleteCardButton({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppTheme.danger,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _EmptyRecurring extends StatelessWidget {
  const _EmptyRecurring({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AppEmptyState(
          icon: Icons.repeat_rounded,
          title: 'No recurring expenses yet',
          message:
              'Add rent, internet, subscriptions, loan payments, or other repeated bills.',
          actionLabel: 'Add Recurring Expense',
          onAction: onAdd,
        ),
      ),
    );
  }
}

class AddRecurringExpenseScreen extends StatefulWidget {
  const AddRecurringExpenseScreen({super.key, this.recurring});

  final RecurringExpense? recurring;

  @override
  State<AddRecurringExpenseScreen> createState() =>
      _AddRecurringExpenseScreenState();
}

class _AddRecurringExpenseScreenState extends State<AddRecurringExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  ExpenseCategory? _category;
  String _paymentMethod = 'Cash';
  String _frequency = 'monthly';
  DateTime _nextDueDate = DateTime.now();
  bool _autoPost = true;
  bool _isSaving = false;

  bool get _isEditing => widget.recurring != null;

  @override
  void initState() {
    super.initState();
    final item = widget.recurring;
    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController = TextEditingController(
      text: item == null ? '' : item.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: item?.note ?? '');
    _paymentMethod = item?.paymentMethod ?? 'Cash';
    _frequency = item?.frequency ?? 'monthly';
    _nextDueDate = item?.nextDueDate ?? DateTime.now();
    _autoPost = item?.autoPost ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    final provider = context.read<ExpenseProvider>();
    final category =
        _category ??
        widget.recurring?.category ??
        (provider.categories.isNotEmpty ? provider.categories.first : null);
    if (category == null) return;
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await provider.updateRecurringExpense(
          widget.recurring!.copyWith(
            title: _titleController.text.trim(),
            amount: amount,
            categoryId: category.id,
            category: category,
            paymentMethod: _paymentMethod,
            frequency: _frequency,
            nextDueDate: _nextDueDate,
            note: _noteController.text.trim(),
            autoPost: _autoPost,
          ),
        );
      } else {
        await provider.addRecurringExpense(
          title: _titleController.text.trim(),
          amount: amount,
          category: category,
          paymentMethod: _paymentMethod,
          frequency: _frequency,
          nextDueDate: _nextDueDate,
          note: _noteController.text.trim(),
          autoPost: _autoPost,
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
    final categories = provider.categories;
    final selectedCategory =
        _category ??
        widget.recurring?.category ??
        (categories.isNotEmpty ? categories.first : null);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Recurring' : 'Add Recurring'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () async {
                await context.read<ExpenseProvider>().deleteRecurringExpense(
                  widget.recurring!.id,
                );
                if (context.mounted) Navigator.pop(context);
              },
              icon: Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Internet Bill',
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Title must be at least 2 characters'
                            : null,
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '1,368',
                        ),
                        validator: (value) =>
                            (double.tryParse(
                                      (value ?? '').replaceAll(',', '').trim(),
                                    ) ??
                                    0) <=
                                0
                            ? 'Amount must be greater than 0'
                            : null,
                      ),
                      SizedBox(height: 14),
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: 'Category'),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _category = value),
                      ),
                      SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                        ),
                        isExpanded: true,
                        items: provider.paymentMethods
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _paymentMethod = value);
                          }
                        },
                      ),
                      SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _frequency,
                        decoration: InputDecoration(labelText: 'Repeat'),
                        isExpanded: true,
                        items: provider.recurringFrequencies
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _frequency = value);
                          }
                        },
                      ),
                      SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.event_repeat_rounded,
                          color: AppTheme.primary,
                        ),
                        title: Text('Next due date'),
                        subtitle: Text(
                          formatDate(_nextDueDate),
                          style: TextStyle(
                            color: AppTheme.titleColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _nextDueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _nextDueDate = picked);
                            }
                          },
                          child: Text('Change'),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _autoPost,
                        title: Text('Auto-add when due'),
                        subtitle: Text(
                          'The app creates the expense automatically on launch after the due date.',
                        ),
                        onChanged: (value) => setState(() => _autoPost = value),
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: 'Note'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                PrimaryButton(
                  label: 'Save Recurring Expense',
                  icon: Icons.repeat_rounded,
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
