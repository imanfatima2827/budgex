import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/security_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_floating_add_button.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';
import 'expenses_list_screen.dart';
import 'reports_screen.dart';
import 'security_lock_screen.dart';
import 'settings_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _wasBackgrounded = false;

  late final List<Widget> _pages = [
    DashboardScreen(onSeeAllTap: () => setState(() => _currentIndex = 1)),
    const ExpensesListScreen(),
    const SizedBox.shrink(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeHomeData());
  }

  Future<void> _primeHomeData() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    try {
      await authProvider.initialize();
    } catch (_) {
      // Keep Home visible. Profile details can be retried later.
    }

    if (!mounted) return;

    try {
      await expenseProvider.initialize();
    } catch (_) {
      // Keep Home visible. Dashboard data can be refreshed manually.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      if (!_wasBackgrounded) return;
      _wasBackgrounded = false;
      context.read<SecurityProvider>().lock();
      return;
    }

    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
    }
  }

  void _handleNavTap(int index) {
    if (index == 2) {
      _openAddExpense();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _openAddExpense([ExpenseCategory? category]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(preselectedCategory: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    if (security.isLoaded && !security.isUnlocked) {
      return const SecurityLockScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavTap,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AppFloatingAddButton(
        tooltip: 'Add Expense',
        onPressed: () => _openAddExpense(),
      ),
    );
  }
}
