import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/auth_validators.dart';
import '../utils/error_messages.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, ProfileService? profileService})
    : _authService = authService ?? AuthService(),
      _profileService = profileService ?? ProfileService() {
    _listenToAuthChanges();
  }

  final AuthService _authService;
  final ProfileService _profileService;

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _error;
  UserProfile? _profile;
  StreamSubscription<AuthState>? _authSubscription;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authService.currentSession != null;
  User? get user => _authService.currentUser;

  String get name {
    final profileName = _profile?.fullName.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;

    final metadata = user?.userMetadata ?? <String, dynamic>{};
    final metadataName = metadata['full_name']?.toString().trim();
    if (metadataName != null && metadataName.isNotEmpty) return metadataName;

    final googleName = metadata['name']?.toString().trim();
    if (googleName != null && googleName.isNotEmpty) return googleName;

    final email = user?.email ?? _profile?.id ?? 'User';
    return email.contains('@') ? email.split('@').first : email;
  }

  String get email => user?.email ?? '';
  String get currencyCode => _profile?.currency ?? 'PKR';
  String get currencySymbol => currencyCodeToSymbol(currencyCode);
  double get monthlyBudget => _profile?.monthlyBudget ?? 0;

  Future<void> initialize() async {
    if (!isLoggedIn) return;
    await _run(() async {
      _profile = await _authService.loadProfile();
      if (_profile == null && user != null) {
        _profile = await _authService.ensureProfileForCurrentUser();
      }
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _run(() async {
      AuthValidators.validateOrThrow(AuthValidators.email, email);
      AuthValidators.validateOrThrow(AuthValidators.loginPassword, password);
      _profile = await _authService.signIn(email: email, password: password);
    });
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    var needsEmailConfirmation = false;

    await _run(() async {
      AuthValidators.validateOrThrow(AuthValidators.name, name);
      AuthValidators.validateOrThrow(AuthValidators.email, email);
      AuthValidators.validateOrThrow(AuthValidators.strongPassword, password);
      final profile = await _authService.signUp(
        fullName: name,
        email: email,
        password: password,
      );
      _profile = profile;
      needsEmailConfirmation = profile == null;
    });

    return needsEmailConfirmation;
  }

  Future<void> loginWithGoogle() async {
    await _run(() async {
      final launched = await _authService.signInWithGoogle();
      if (!launched) {
        throw const AuthException(
          'Google sign-in could not be opened. Please try again.',
        );
      }
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _run(() async {
      AuthValidators.validateOrThrow(AuthValidators.email, email);
      await _authService.sendPasswordResetEmail(email);
    });
  }

  Future<void> updatePassword(String newPassword) async {
    await _run(() async {
      AuthValidators.validateOrThrow(
        AuthValidators.strongPassword,
        newPassword,
      );
      await _authService.updatePassword(newPassword);
    });
  }

  Future<void> updateSettings({
    String? currencySymbol,
    double? monthlyBudget,
  }) async {
    await _run(() async {
      _profile = await _profileService.updateProfile(
        currency: currencySymbol == null
            ? null
            : symbolToCurrencyCode(currencySymbol),
        monthlyBudget: monthlyBudget,
      );
    });
  }

  Future<void> logout() async {
    await _run(() async {
      await _authService.signOut();
      _profile = null;
    });
  }

  void _listenToAuthChanges() {
    if (!SupabaseConfig.isConfigured) return;

    _authSubscription = _authService.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedOut || data.session == null) {
        _profile = null;
        _notifySafely();
        return;
      }

      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.userUpdated ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.initialSession) {
        try {
          _profile = await _authService.loadProfile();
        } catch (_) {
          // Keep the current profile if Supabase is briefly unavailable.
        }
        _notifySafely();
      }
    }, onError: (_, _) {});
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      await action();
    } catch (error) {
      _error = _friendlyMessage(error);
      rethrow;
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  static String currencyCodeToSymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'AED';
      case 'PKR':
      default:
        return 'Rs';
    }
  }

  static String symbolToCurrencyCode(String symbol) {
    switch (symbol) {
      case r'$':
        return 'USD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case 'AED':
        return 'AED';
      case 'Rs':
      default:
        return 'PKR';
    }
  }

  String _friendlyMessage(Object error) => friendlySupabaseMessage(error);
}
