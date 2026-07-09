import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/profile.dart';
import '../utils/auth_validators.dart';
import 'profile_service.dart';

class AuthService {
  AuthService({SupabaseClient? client, ProfileService? profileService})
    : _client = client,
      _profileService = profileService ?? ProfileService(client: client);

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;
  final ProfileService _profileService;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  Future<UserProfile?> loadProfile() => _profileService.fetchCurrentProfile();

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    _ensureSupabaseConfigured();
    AuthValidators.validateOrThrow(AuthValidators.email, email);
    AuthValidators.validateOrThrow(AuthValidators.loginPassword, password);

    final response = await _supabase.auth.signInWithPassword(
      email: AuthValidators.normalizeEmail(email),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Login failed. Please try again.');
    }

    return ensureProfileForCurrentUser();
  }

  Future<bool> signInWithGoogle() async {
    _ensureSupabaseConfigured();

    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.authRedirectUrl,
      scopes: 'email profile',
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<UserProfile?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _ensureSupabaseConfigured();
    AuthValidators.validateOrThrow(AuthValidators.name, fullName);
    AuthValidators.validateOrThrow(AuthValidators.email, email);
    AuthValidators.validateOrThrow(AuthValidators.strongPassword, password);

    final trimmedEmail = AuthValidators.normalizeEmail(email);
    final trimmedName = fullName.trim();
    final displayName = trimmedName.isEmpty
        ? trimmedEmail.split('@').first
        : trimmedName;

    final response = await _supabase.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: {'full_name': displayName},
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException(
        'Signup failed. Please check Supabase email confirmation settings.',
      );
    }

    // If email confirmation is ON, Supabase creates the auth user but does not
    // create a client session. Any profile insert from Flutter will fail RLS.
    // The SQL trigger creates the profile row from auth.users instead.
    if (response.session == null) {
      return null;
    }

    await _applyReturnedSession(response.session!);
    return ensureProfileForCurrentUser(defaultName: displayName);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _ensureSupabaseConfigured();
    AuthValidators.validateOrThrow(AuthValidators.email, email);

    await _supabase.auth.resetPasswordForEmail(
      AuthValidators.normalizeEmail(email),
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    _ensureSupabaseConfigured();
    AuthValidators.validateOrThrow(AuthValidators.strongPassword, newPassword);

    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const AuthException(
        'Password recovery session expired. Open the reset link again and try once more.',
      );
    }

    final response = await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    if (response.user == null) {
      throw const AuthException('Password update failed. Please try again.');
    }
  }

  Future<UserProfile> ensureProfileForCurrentUser({String? defaultName}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('No logged-in user found.');

    final profile = await _profileService.fetchCurrentProfile();
    if (profile != null) return profile;

    return _profileService.createCurrentProfile(
      fullName: defaultName ?? _displayNameForUser(user),
    );
  }

  Future<void> _applyReturnedSession(Session session) async {
    if (_supabase.auth.currentSession != null) return;

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return;

    await _supabase.auth.setSession(refreshToken);
  }

  Future<void> signOut() => _supabase.auth.signOut();

  void _ensureSupabaseConfigured() {
    if (!SupabaseConfig.isConfigured) {
      throw AuthException(SupabaseConfig.setupMessage);
    }
  }

  String _displayNameForUser(User user) {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final fullName = metadata['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final name = metadata['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'User';
  }
}
