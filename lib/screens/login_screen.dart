import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/password_recovery_storage.dart';
import '../core/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/auth_validators.dart';
import '../widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'root_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;
  bool _obscure = true;
  bool _showValidationErrors = false;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _isNavigating = false;

  static const String _logoPath = 'assets/images/expense_wallet_logo_blue.png';
  static const String _googleIconPath = 'assets/images/google_icon.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForOAuthLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateHomeIfAuthenticated();
    });
  }

  void _listenForOAuthLogin() {
    if (!SupabaseConfig.isConfigured) return;

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (!mounted || _isNavigating) return;

      if (data.session == null ||
          data.event == AuthChangeEvent.passwordRecovery) {
        return;
      }

      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.userUpdated) {
        await _completeAuthenticatedNavigation();
      }
    }, onError: (_, _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || state != AppLifecycleState.resumed) return;
    _navigateHomeIfAuthenticated();
  }

  Future<void> _navigateHomeIfAuthenticated() async {
    if (!mounted || _isNavigating) return;
    if (!context.read<AuthProvider>().isLoggedIn) return;
    await _completeAuthenticatedNavigation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isSubmitting) return;

    setState(() => _showValidationErrors = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await context.read<AuthProvider>().login(
        email: AuthValidators.normalizeEmail(_emailController.text),
        password: _passwordController.text,
      );
      if (!mounted) return;
      await _completeAuthenticatedNavigation();
    } catch (error) {
      if (!mounted) return;
      final message = context.read<AuthProvider>().error ?? error.toString();
      _showErrorSnackBar(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isGoogleSubmitting || _isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSubmitting = true);
    try {
      await context.read<AuthProvider>().loginWithGoogle();
      await _navigateHomeIfAuthenticated();
    } catch (error) {
      if (!mounted) return;
      final message = context.read<AuthProvider>().error ?? error.toString();
      _showErrorSnackBar(message);
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
  }

  Future<void> _completeAuthenticatedNavigation() async {
    if (_isNavigating) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      _showErrorSnackBar('Sign-in was not completed.');
      return;
    }

    _isNavigating = true;
    unawaited(PasswordRecoveryStorage.clear());

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RootScreen()),
      (_) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    AppTheme.isDark(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: AppTheme.bodyColor(context)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: AppTheme.softSurfaceColor(context),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.bodyColor(context)),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.danger.withValues(alpha: 0.65)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.danger, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = AppTheme.titleColor(context);
    final bodyColor = AppTheme.bodyColor(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              children: [
                SizedBox(height: 10),
                Image.asset(
                  _logoPath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 12),
                Text(
                  'Sign In to Budgex',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    fontFamily: 'BebasNeue',
                  ),
                ),
                SizedBox(height: 30),
                _FieldLabel('Email Address', color: titleColor),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _inputDecoration(
                    hint: 'Enter your email address...',
                    icon: Icons.email_outlined,
                  ),
                  validator: AuthValidators.email,
                ),
                SizedBox(height: 18),
                _FieldLabel('Password', color: titleColor),
                SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _inputDecoration(
                    hint: 'Enter your password...',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: AuthValidators.loginPassword,
                  onFieldSubmitted: (_) => _login(),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  initialEmail: _emailController.text,
                                ),
                              ),
                            );
                          },
                    child: Text('Forgot Password?'),
                  ),
                ),
                SizedBox(height: 8),
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: _isSubmitting,
                  onPressed: _login,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppTheme.borderColor(context)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: TextStyle(color: bodyColor, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppTheme.borderColor(context)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isGoogleSubmitting ? null : _loginWithGoogle,
                    icon: _isGoogleSubmitting
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.asset(_googleIconPath, width: 18, height: 18),
                    label: Text(
                      'Login with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: titleColor,
                      side: BorderSide(color: AppTheme.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New here? ',
                      style: TextStyle(fontSize: 15, color: bodyColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Create an account',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}
