import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/security_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/primary_button.dart';

class SecurityLockScreen extends StatefulWidget {
  const SecurityLockScreen({super.key});

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _obscurePin = true;
  bool _isBiometricUnlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final security = context.read<SecurityProvider>();
      if (security.biometricEnabled) {
        _unlockWithBiometrics(showError: false);
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _unlock() {
    final ok = context.read<SecurityProvider>().unlockWithPin(
      _pinController.text,
    );
    if (!ok) {
      setState(() => _error = 'Incorrect PIN. Try again.');
    }
  }

  Future<void> _unlockWithBiometrics({bool showError = true}) async {
    if (_isBiometricUnlocking) return;
    setState(() => _isBiometricUnlocking = true);

    final security = context.read<SecurityProvider>();
    final ok = await security.unlockWithBiometrics();

    if (!mounted) return;
    setState(() => _isBiometricUnlocking = false);

    if (!ok && showError) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            security.biometricError ?? 'Biometric unlock was not completed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 86,
                      width: 86,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.primary,
                        size: 42,
                      ),
                    ),
                    SizedBox(height: 22),
                    Text(
                      'App Locked',
                      style: TextStyle(
                        color: AppTheme.titleColor(context),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter your PIN or use biometrics to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.bodyColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: _pinController,
                      obscureText: _obscurePin,
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 8,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'PIN',
                        errorText: _error,
                        suffixIcon: IconButton(
                          tooltip: _obscurePin ? 'Show PIN' : 'Hide PIN',
                          icon: Icon(
                            _obscurePin
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _unlock(),
                    ),
                    SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Unlock',
                      icon: Icons.lock_open_rounded,
                      onPressed: _unlock,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
