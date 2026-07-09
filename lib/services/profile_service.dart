import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileService {
  ProfileService({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final row = await _supabase
        .from('profiles')
        .select('id, full_name, currency, monthly_budget')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  Future<UserProfile> createCurrentProfile({
    required String fullName,
    String currency = 'PKR',
    double monthlyBudget = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    final session = _supabase.auth.currentSession;

    if (user == null || session == null) {
      throw const AuthException(
        'Please confirm your email and sign in before creating your profile.',
      );
    }

    return createProfile(
      userId: user.id,
      fullName: fullName,
      currency: currency,
      monthlyBudget: monthlyBudget,
    );
  }

  Future<UserProfile> createProfile({
    required String userId,
    required String fullName,
    String currency = 'PKR',
    double monthlyBudget = 0,
  }) async {
    final row = await _supabase
        .from('profiles')
        .upsert({
          'id': userId,
          'full_name': fullName.trim(),
          'currency': currency,
          'monthly_budget': monthlyBudget,
        }, onConflict: 'id')
        .select('id, full_name, currency, monthly_budget')
        .single();

    return UserProfile.fromMap(row);
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? currency,
    double? monthlyBudget,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('No logged-in user found.');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName.trim();
    if (currency != null) updates['currency'] = currency;
    if (monthlyBudget != null) updates['monthly_budget'] = monthlyBudget;

    if (updates.isEmpty) {
      final profile = await fetchCurrentProfile();
      if (profile == null) {
        return createCurrentProfile(fullName: user.email ?? 'User');
      }
      return profile;
    }

    final row = await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select('id, full_name, currency, monthly_budget')
        .single();

    return UserProfile.fromMap(row);
  }
}
