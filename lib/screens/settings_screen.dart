import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../utils/date_helpers.dart';
import '../widgets/account_profile_card.dart';
import '../widgets/app_card.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_page_header.dart';
import '../widgets/app_scaled_text.dart';
import 'category_budgets_screen.dart';
import 'csv_export_preview_screen.dart';
import 'csv_import_screen.dart';
import 'income_screen.dart';
import 'login_screen.dart';
import 'recurring_expenses_screen.dart';
import 'savings_goals_screen.dart';
import 'security_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editBudget(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(
      text: auth.monthlyBudget.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(prefixText: '${auth.currencySymbol} '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(
                controller.text.trim().replaceAll(',', ''),
              );
              if (parsed == null || parsed < 0) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && context.mounted) {
      try {
        await context.read<AuthProvider>().updateSettings(monthlyBudget: value);
      } catch (error) {
        if (!context.mounted) return;
        final message = context.read<AuthProvider>().error ?? error.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _editCurrency(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final options = <String>[r'$', 'Rs', '€', '£', 'AED'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => _SelectionSheet<String>(
        title: 'Select Currency',
        selected: auth.currencySymbol,
        options: options,
        labelBuilder: (symbol) => symbol,
        iconBuilder: (_) => Icons.attach_money_rounded,
      ),
    );
    if (selected != null && context.mounted) {
      try {
        await context.read<AuthProvider>().updateSettings(
          currencySymbol: selected,
        );
      } catch (error) {
        if (!context.mounted) return;
        final message = context.read<AuthProvider>().error ?? error.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _editTheme(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (sheetContext) => _SelectionSheet<ThemeMode>(
        title: 'Select Theme',
        selected: themeProvider.themeMode,
        options: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
        labelBuilder: (mode) {
          switch (mode) {
            case ThemeMode.light:
              return 'Light';
            case ThemeMode.dark:
              return 'Dark';
            case ThemeMode.system:
              return 'System default';
          }
        },
        iconBuilder: _themeIcon,
      ),
    );

    if (selected != null && context.mounted) {
      await context.read<ThemeProvider>().changeTheme(selected);
    }
  }

  static IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final now = DateTime.now();
    final start = startOfMonth(now);
    final end = endOfMonth(now);

    return ColoredBox(
      color: AppTheme.scaffoldColor(context),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(
                padding: EdgeInsets.zero,
                title: 'Settings',
                subtitle:
                    'Manage your account, exports, theme, and finance tools.',
              ),
              const SizedBox(height: 18),
              AccountProfileCard(
                name: auth.name,
                email: auth.email,
              ),
              const SizedBox(height: 22),
              const _GroupTitle('General'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.attach_money_rounded,
                      title: 'Currency',
                      value: auth.currencySymbol,
                      onTap: () => _editCurrency(context),
                    ),
                    const _DividerInset(),
                    _SettingTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Monthly Budget',
                      value: formatCurrency(
                        auth.monthlyBudget,
                        symbol: auth.currencySymbol,
                      ),
                      onTap: () => _editBudget(context),
                    ),
                    const _DividerInset(),
                    _SettingTile(
                      icon: _themeIcon(themeProvider.themeMode),
                      title: 'Theme',
                      value: themeProvider.label,
                      onTap: () => _editTheme(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _GroupTitle('Data & Export'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.file_download_outlined,
                      title: 'Export to CSV',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CsvExportPreviewScreen(
                            startDate: start,
                            endDate: end,
                          ),
                        ),
                      ),
                    ),
                    const _DividerInset(),
                    _SettingTile(
                      icon: Icons.upload_file_rounded,
                      title: 'Import CSV',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CsvImportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _GroupTitle('Finance Assistant'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.add_card_rounded,
                      title: 'Income Tracking',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IncomeScreen()),
                      ),
                    ),
                    const _DividerInset(),
                    _SettingTile(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Category Budgets',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoryBudgetsScreen(),
                        ),
                      ),
                    ),
                    const _DividerInset(),
                    _SettingTile(
                      icon: Icons.repeat_rounded,
                      title: 'Recurring Expenses',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecurringExpensesScreen(),
                        ),
                      ),
                    ),
                    const _DividerInset(),
                    _SettingTile(
                      icon: Icons.savings_outlined,
                      title: 'Savings Goals',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavingsGoalsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _GroupTitle('Privacy'),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: _SettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'PIN & Biometric Lock',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecuritySettingsScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final expenseProvider = context.read<ExpenseProvider>();
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldLogout != true) return;

                    try {
                      await authProvider.logout();
                      if (!context.mounted) return;
                      expenseProvider.clear();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      final message = authProvider.error ?? error.toString();
                      messenger.showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: BorderSide(
                      color: AppTheme.danger.withValues(alpha: 0.28),
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

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    required this.iconBuilder,
  });

  final String title;
  final T selected;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final IconData Function(T option) iconBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.titleColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ...options.map((option) {
              final isSelected = selected == option;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Icon(iconBuilder(option), color: AppTheme.primary),
                title: Text(
                  labelBuilder(option),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, option),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.titleColor(context),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DividerInset extends StatelessWidget {
  const _DividerInset();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 66),
      child: Divider(
        height: 1,
        color: AppTheme.borderColor(context).withValues(alpha: 0.72),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: AppIconBubble(
        icon: icon,
        size: 40,
        iconSize: 20,
        borderRadius: 15,
      ),
      title: AppScaledText(
        title,
        minFontSize: 10,
        style: TextStyle(
          color: AppTheme.titleColor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: AppScaledText(
                value!,
                minFontSize: 9,
                style: TextStyle(
                  color: AppTheme.bodyColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.bodyColor(context),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
