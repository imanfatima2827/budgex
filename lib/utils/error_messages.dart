import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_validators.dart';

const _networkSetupMessage =
    'Cannot reach Supabase. Check your internet connection, DNS/VPN settings, '
    'and that SUPABASE_URL is the exact Project URL.';
const _rateLimitMessage =
    'A confirmation email was already requested. Please wait a minute, '
    'check your inbox/spam, then try again.';
const _googleSecretMessage =
    'Google login is missing the OAuth client secret in Supabase. Add the '
    'Google client ID and client secret in Supabase Auth, then try again.';
const _googleConfigMessage =
    'Google login is not fully configured in Supabase. Enable Google provider, '
    'add the Google client ID and client secret, then add the app redirect URL.';
const _weakPasswordMessage =
    'Password is too weak. Use 8+ characters with uppercase, lowercase, number, '
    'and special character.';

String friendlySupabaseMessage(Object error) {
  if (error is AuthValidationException) return error.message;

  final rawMessage = _rawErrorMessage(error);
  final message = rawMessage.toLowerCase();
  final commonMessage = _friendlyCommonMessage(message);
  if (commonMessage != null) return commonMessage;

  if (error is AuthException) return _friendlyAuthMessage(error.message);
  if (error is PostgrestException) {
    return _friendlyDatabaseMessage(error.message);
  }

  if (rawMessage.isEmpty) return 'Something went wrong. Please try again.';
  return rawMessage;
}

String _rawErrorMessage(Object error) {
  if (error is AuthException) return error.message.trim();
  if (error is PostgrestException) return error.message.trim();
  return error.toString().replaceFirst('Exception: ', '').trim();
}

String? _friendlyCommonMessage(String message) {
  if (message.contains('failed host lookup') ||
      message.contains('socketexception') ||
      message.contains('clientexception') ||
      message.contains('nodename nor servname provided') ||
      message.contains('no route to host') ||
      message.contains('no address associated with hostname')) {
    return _networkSetupMessage;
  }

  if (message.contains('network is unreachable') ||
      message.contains('connection refused') ||
      message.contains('connection timed out') ||
      message.contains('connection timeout') ||
      message.contains('connection closed') ||
      message.contains('connection reset') ||
      message.contains('software caused connection abort') ||
      message.contains('handshakeexception') ||
      message.contains('xmlhttprequest error')) {
    return 'Network connection failed. Please check your internet connection and try again.';
  }

  if (message.contains('invalid api key') || message.contains('jwt')) {
    return 'Supabase anon key is invalid. Please check SUPABASE_ANON_KEY.';
  }

  if (message.contains('security purposes') &&
      message.contains('request this after')) {
    return _rateLimitMessage;
  }

  if (message.contains('missing oauth secret')) {
    return _googleSecretMessage;
  }

  if (message.contains('provider is not enabled') ||
      message.contains('unsupported provider') ||
      message.contains('google')) {
    return _googleConfigMessage;
  }

  return null;
}

String _friendlyAuthMessage(String rawMessage) {
  final message = rawMessage.toLowerCase();
  final commonMessage = _friendlyCommonMessage(message);
  if (commonMessage != null) return commonMessage;

  if (message.contains('invalid login credentials') ||
      message.contains('invalid credentials')) {
    return 'Incorrect email or password. Please check your details and try again.';
  }
  if (message.contains('email not confirmed')) {
    return 'Please confirm your email before signing in. Check your inbox or spam folder.';
  }
  if (message.contains('user already registered') ||
      message.contains('already registered')) {
    return 'An account already exists with this email. Please sign in instead.';
  }
  if (message.contains('signup is disabled')) {
    return 'Signup is disabled in Supabase Auth settings.';
  }
  if (message.contains('password should be') ||
      message.contains('weak password')) {
    return _weakPasswordMessage;
  }
  if (message.contains('invalid email')) {
    return 'Enter a valid email address.';
  }
  if (message.contains('email rate limit') ||
      message.contains('rate limit') ||
      message.contains('too many')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (message.contains('otp expired') ||
      message.contains('token expired') ||
      message.contains('session expired')) {
    return 'This link has expired. Request a new password reset email and try again.';
  }
  if (message.contains('missing oauth secret')) {
    return _googleSecretMessage;
  }

  if (message.contains('provider is not enabled') ||
      message.contains('unsupported provider')) {
    return _googleConfigMessage;
  }

  return rawMessage.trim().isEmpty
      ? 'Authentication failed. Please try again.'
      : rawMessage;
}

String cleanErrorMessage(Object error) {
  final rawMessage = _rawErrorMessage(error);
  return rawMessage.isEmpty
      ? 'Something went wrong. Please try again.'
      : rawMessage;
}

String _friendlyDatabaseMessage(String rawMessage) {
  final message = rawMessage.toLowerCase();
  final commonMessage = _friendlyCommonMessage(message);
  if (commonMessage != null) return commonMessage;

  if (message.contains('violates row-level security') ||
      message.contains('rls')) {
    return 'Database permission error. Check Supabase RLS policies for this table.';
  }
  if (message.contains('duplicate key')) {
    return 'This record already exists.';
  }
  if (message.contains('foreign key')) {
    return 'Selected data is invalid or no longer exists. Refresh and try again.';
  }

  return rawMessage.trim().isEmpty
      ? 'Database request failed. Please try again.'
      : rawMessage;
}
