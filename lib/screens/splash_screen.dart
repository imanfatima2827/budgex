import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/onboarding_storage.dart';
import '../core/password_recovery_storage.dart';
import '../core/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'reset_password_screen.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(milliseconds: 800);

  String? _setupMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(_splashDuration);
    if (!mounted) return;

    final destination = await _resolveStartDestination();
    if (!mounted || destination == null) return;

    _replaceWith(destination);
  }

  Future<Widget?> _resolveStartDestination() async {
    final hasSeenOnboarding = await OnboardingStorage.hasSeenOnboarding();
    if (!mounted) return null;
    if (!hasSeenOnboarding) return const OnboardingScreen();

    if (!SupabaseConfig.isConfigured) {
      setState(() => _setupMessage = SupabaseConfig.setupMessage);
      return null;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.initialize();
    } catch (_) {
      if (!authProvider.isLoggedIn) return const LoginScreen();
    }

    if (!mounted) return null;
    if (authProvider.isLoggedIn &&
        await PasswordRecoveryStorage.consumeIfFresh()) {
      return const ResetPasswordScreen();
    }

    if (!mounted) return null;
    return authProvider.isLoggedIn ? const RootScreen() : const LoginScreen();
  }

  void _replaceWith(Widget destination) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/expense_wallet_logo_white.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _setupMessage == null
                      ? const CupertinoActivityIndicator(
                          radius: 14,
                          color: Colors.white,
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            _setupMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
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
