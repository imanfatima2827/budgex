import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import 'app_icon_bubble.dart';
import 'app_scaled_text.dart';
import 'finance_info_chip.dart';

class ExpenseListCard extends StatelessWidget {
  const ExpenseListCard({
    super.key,
    required this.expense,
    required this.currency,
    this.onTap,
    this.onDelete,
    this.showPaymentMethod = true,
    this.showDeleteAction = true,
    this.showCardDecoration = true,
    this.showAccentBar = true,
    this.borderRadius = 24,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  final Expense expense;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showPaymentMethod;
  final bool showDeleteAction;
  final bool showCardDecoration;
  final bool showAccentBar;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;

  bool get _canDelete => onDelete != null;

  @override
  Widget build(BuildContext context) {
    final card = _ExpenseCardBody(
      expense: expense,
      currency: currency,
      onTap: onTap,
      onDelete: _canDelete && showDeleteAction
          ? () => _deleteWithConfirmation(context)
          : null,
      showPaymentMethod: showPaymentMethod,
      showCardDecoration: showCardDecoration,
      showAccentBar: showAccentBar,
      borderRadius: borderRadius,
      contentPadding: contentPadding,
    );

    if (!_canDelete) return card;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(borderRadius: borderRadius),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: card,
    );
  }

  Future<void> _deleteWithConfirmation(BuildContext context) async {
    final confirmed = await _confirmDelete(context);
    if (confirmed) onDelete?.call();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('This will remove “${expense.title}” from your records.'),
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
}

class _ExpenseCardBody extends StatelessWidget {
  const _ExpenseCardBody({
    required this.expense,
    required this.currency,
    required this.showPaymentMethod,
    required this.showCardDecoration,
    required this.showAccentBar,
    required this.borderRadius,
    required this.contentPadding,
    this.onTap,
    this.onDelete,
  });

  final Expense expense;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showPaymentMethod;
  final bool showCardDecoration;
  final bool showAccentBar;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Stack(
          children: [
            if (showAccentBar)
              PositionedDirectional(
                start: 0,
                top: 16,
                bottom: 16,
                child: _AccentBar(color: expense.category.color),
              ),
            Padding(
              padding: EdgeInsetsDirectional.only(start: showAccentBar ? 5 : 0),
              child: Padding(
                padding: contentPadding,
                child: _ExpenseCardContent(
                  expense: expense,
                  currency: currency,
                  onDelete: onDelete,
                  showPaymentMethod: showPaymentMethod,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!showCardDecoration) return child;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: radius,
        border: Border.all(
          color: AppTheme.borderColor(context).withValues(alpha: 0.78),
        ),
        boxShadow: [AppTheme.themedSoftShadow(context, alpha: 0.045, blur: 16)],
      ),
      child: child,
    );
  }
}

class _ExpenseCardContent extends StatelessWidget {
  const _ExpenseCardContent({
    required this.expense,
    required this.currency,
    required this.showPaymentMethod,
    this.onDelete,
  });

  final Expense expense;
  final String currency;
  final VoidCallback? onDelete;
  final bool showPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final hasReceipt =
        expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty;
    final paymentMethod = expense.paymentMethod.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppIconBubble(
          icon: expense.category.icon,
          color: expense.category.color,
          size: 46,
          iconSize: 22,
          borderRadius: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppScaledText(
                expense.title,
                minFontSize: 10,
                style: TextStyle(
                  color: AppTheme.titleColor(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${expense.category.name} • ${formatDate(expense.date)}${hasReceipt ? ' • Receipt' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.bodyColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showPaymentMethod && paymentMethod.isNotEmpty) ...[
                const SizedBox(height: 8),
                FinanceInfoChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: paymentMethod,
                  maxWidth: 132,
                  minHeight: 27,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        _TrailingAmount(
          amount: '-${formatCurrency(expense.amount, symbol: currency)}',
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _TrailingAmount extends StatelessWidget {
  const _TrailingAmount({required this.amount, this.onDelete});

  final String amount;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 84),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppScaledText(
            amount,
            maxLines: 1,
            minFontSize: 10,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppTheme.titleColor(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(height: 10),
            _RoundActionButton(
              icon: Icons.delete_outline_rounded,
              color: AppTheme.danger,
              tooltip: 'Delete expense',
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _AccentBar extends StatelessWidget {
  const _AccentBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.borderRadius});

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.danger,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}
