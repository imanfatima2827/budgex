import 'dart:async';

import 'package:budgex/core/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_navigator.dart';
import 'core/password_recovery_router.dart';

import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/security_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.load();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  final themeProvider = ThemeProvider();
  final securityProvider = SecurityProvider();
  await Future.wait([themeProvider.load(), securityProvider.load()]);

  runApp(
    BudgexApp(themeProvider: themeProvider, securityProvider: securityProvider),
  );
}

class BudgexApp extends StatefulWidget {
  const BudgexApp({
    super.key,
    required this.themeProvider,
    required this.securityProvider,
  });

  final ThemeProvider themeProvider;
  final SecurityProvider securityProvider;

  @override
  State<BudgexApp> createState() => _BudgexAppState();
}

class _BudgexAppState extends State<BudgexApp> {
  StreamSubscription<AuthState>? _authSubscription;
  final PasswordRecoveryRouter _passwordRecoveryRouter =
      PasswordRecoveryRouter();

  @override
  void initState() {
    super.initState();
    _listenForPasswordRecovery();
  }

  void _listenForPasswordRecovery() {
    if (!SupabaseConfig.isConfigured) return;

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event != AuthChangeEvent.passwordRecovery) return;
      _passwordRecoveryRouter.openResetPasswordScreen();
    }, onError: (_, _) {});
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider.value(value: widget.securityProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Budgex',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
