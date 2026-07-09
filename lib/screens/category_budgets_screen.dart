import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_icon_bubble.dart';

class CategoryBudgetsScreen extends StatelessWidget {
  const CategoryBudgetsScreen({super.key});

  Future<void> _editBudget(BuildContext context, String categoryId) async {
    final provider = context.read<ExpenseProvider>();
    final category = provider.categoryById(categoryId);
    final existing = provider.categoryBudgetLimit(categoryId);
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _CategoryBudgetDialog(
        categoryName: category.name,
        existingLimit: existing,
      ),
    );
    if (value == null || !context.mounted) return;
    try {
      if (value <= 0) {
        final matches = provider.categoryBudgets.where(
          (budget) => budget.categoryId == categoryId,
        );
        if (matches.isNotEmpty) {
          await provider.deleteCategoryBudget(matches.first.id);
        }
      } else {
        await provider.setCategoryBudget(
          category: category,
          monthlyLimit: value,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = context.watch<AuthProvider>().currencySymbol;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(title: const Text('Category Budgets')),
      body: SafeArea(
        child: provider.categories.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: AppEmptyState(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'No categories yet',
                    message:
                        'Create categories while adding expenses, then set budget limits here.',
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                itemCount: provider.categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = provider.categories[index];
                  final limit = provider.categoryBudgetLimit(category.id);
                  final spent = provider.categorySpendingForMonth(
                    category.id,
                    now,
                  );
                  final progress = limit <= 0
                      ? 0.0
                      : (spent / limit).clamp(0.0, 1.0).toDouble();
                  final overBudget = limit > 0 && spent > limit;

                  return AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => _editBudget(context, category.id),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AppIconBubble(
                              icon: category.icon,
                              color: category.color,
                              size: 44,
                              iconSize: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      color: AppTheme.titleColor(context),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    limit <= 0
                                        ? 'No budget set'
                                        : '${formatCurrency(spent, symbol: currency)} / '
                                            '${formatCurrency(limit, symbol: currency)}',
                                    style: TextStyle(
                                      color: overBudget
                                          ? AppTheme.danger
                                          : AppTheme.bodyColor(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (limit <= 0
                                            ? AppTheme.primary
                                            : category.color)
                                        .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                limit <= 0 ? 'Set' : 'Edit',
                                style: TextStyle(
                                  color: limit <= 0
                                      ? AppTheme.primary
                                      : category.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (limit > 0) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: category.color.withValues(
                                alpha: 0.12,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                overBudget ? AppTheme.danger : category.color,
                              ),
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

class _CategoryBudgetDialog extends StatefulWidget {
  const _CategoryBudgetDialog({
    required this.categoryName,
    required this.existingLimit,
  });

  final String categoryName;
  final double existingLimit;

  @override
  State<_CategoryBudgetDialog> createState() => _CategoryBudgetDialogState();
}

class _CategoryBudgetDialogState extends State<_CategoryBudgetDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingLimit <= 0
          ? ''
          : widget.existingLimit.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_controller.text.trim().replaceAll(',', ''));

    if (parsed == null || parsed < 0) {
      setState(() => _errorText = 'Enter a valid monthly limit');
      return;
    }

    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.categoryName} Budget'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: 'Monthly limit',
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.existingLimit > 0)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('Remove'),
          ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
