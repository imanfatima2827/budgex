import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_floating_add_button.dart';
import '../widgets/app_scaled_text.dart';
import '../widgets/primary_button.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('This will remove "${goal.title}" from your goals.'),
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

  Future<void> _deleteGoal(BuildContext context, SavingsGoal goal) async {
    try {
      await context.read<ExpenseProvider>().deleteSavingsGoal(goal.id);
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
      appBar: AppBar(title: Text('Savings Goals')),
      floatingActionButton: AppFloatingAddButton(
        tooltip: 'Add Savings Goal',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSavingsGoalScreen()),
        ),
      ),
      body: SafeArea(
        child: provider.savingsGoals.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: AppEmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No goals yet',
                    message:
                        'Create a savings target like emergency fund, travel, laptop, or business investment.',
                    actionLabel: 'Add Savings Goal',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSavingsGoalScreen(),
                      ),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                itemCount: provider.savingsGoals.length,
                separatorBuilder: (_, _) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final goal = provider.savingsGoals[index];
                  return AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSavingsGoalScreen(goal: goal),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppScaledText(
                                goal.title,
                                minFontSize: 10,
                                style: TextStyle(
                                  color: AppTheme.titleColor(context),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(goal.progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _DeleteCardButton(
                                  tooltip: 'Delete Goal',
                                  onTap: () async {
                                    final confirmed = await _confirmDelete(
                                      context,
                                      goal,
                                    );
                                    if (confirmed && context.mounted) {
                                      await _deleteGoal(context, goal);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 8,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${formatCurrency(goal.savedAmount, symbol: currency)} '
                          'saved of '
                          '${formatCurrency(goal.targetAmount, symbol: currency)}',
                          style: TextStyle(
                            color: AppTheme.bodyColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (goal.targetDate != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Target: ${formatDate(goal.targetDate!)}',
                            style: TextStyle(
                              color: AppTheme.bodyColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
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

class AddSavingsGoalScreen extends StatefulWidget {
  const AddSavingsGoalScreen({super.key, this.goal});

  final SavingsGoal? goal;

  @override
  State<AddSavingsGoalScreen> createState() => _AddSavingsGoalScreenState();
}

class _AddSavingsGoalScreenState extends State<AddSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late final TextEditingController _noteController;
  DateTime? _targetDate;
  bool _isSaving = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _targetController = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toStringAsFixed(0),
    );
    _savedController = TextEditingController(
      text: goal == null ? '0' : goal.savedAmount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: goal?.note ?? '');
    _targetDate = goal?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    final target =
        double.tryParse(_targetController.text.trim().replaceAll(',', '')) ?? 0;
    final saved =
        double.tryParse(_savedController.text.trim().replaceAll(',', '')) ?? 0;
    final provider = context.read<ExpenseProvider>();
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await provider.updateSavingsGoal(
          widget.goal!.copyWith(
            title: _titleController.text.trim(),
            targetAmount: target,
            savedAmount: saved,
            targetDate: _targetDate,
            clearTargetDate: _targetDate == null,
            note: _noteController.text.trim(),
            isCompleted: saved >= target,
          ),
        );
      } else {
        await provider.addSavingsGoal(
          title: _titleController.text.trim(),
          targetAmount: target,
          savedAmount: saved,
          targetDate: _targetDate,
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Goal' : 'Add Goal'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () async {
                await context.read<ExpenseProvider>().deleteSavingsGoal(
                  widget.goal!.id,
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
                          labelText: 'Goal title',
                          hintText: 'Emergency Fund',
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Title must be at least 2 characters'
                            : null,
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Target amount',
                          hintText: '50,000',
                        ),
                        validator: (value) =>
                            (double.tryParse(
                                      (value ?? '').replaceAll(',', '').trim(),
                                    ) ??
                                    0) <=
                                0
                            ? 'Target must be greater than 0'
                            : null,
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        controller: _savedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Already saved',
                          hintText: '0',
                        ),
                      ),
                      SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.flag_outlined,
                          color: AppTheme.primary,
                        ),
                        title: Text('Target date'),
                        subtitle: Text(
                          _targetDate == null
                              ? 'No date selected'
                              : formatDate(_targetDate!),
                          style: TextStyle(
                            color: AppTheme.titleColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _targetDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 1),
                              ),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _targetDate = picked);
                            }
                          },
                          child: Text('Pick'),
                        ),
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
                  label: 'Save Goal',
                  icon: Icons.savings_outlined,
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
