import 'package:flutter/services.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const _assetPath = '.env';
  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _definedRedirectScheme = String.fromEnvironment(
    'APP_REDIRECT_SCHEME',
  );

  static String _rawUrl = _definedUrl;
  static String anonKey = _definedAnonKey;

  /// Used by Supabase OAuth and password recovery email links.
  /// Add this exact URL in Supabase Dashboard > Auth > URL Configuration > Redirect URLs.
  static String appRedirectScheme = _definedRedirectScheme.isEmpty
      ? 'budgex'
      : _definedRedirectScheme;

  static String get authRedirectUrl => '$appRedirectScheme://login-callback/';

  static String url = _normalizeUrl(_rawUrl);

  static Future<void> load() async {
    final values = await _loadDotEnv();

    _rawUrl = _valueFrom(values, 'SUPABASE_URL', fallback: _definedUrl);
    anonKey = _valueFrom(
      values,
      'SUPABASE_ANON_KEY',
      fallback: _definedAnonKey,
    );
    appRedirectScheme = _valueFrom(
      values,
      'APP_REDIRECT_SCHEME',
      fallback: _definedRedirectScheme.isEmpty
          ? 'budgex'
          : _definedRedirectScheme,
    );
    url = _normalizeUrl(_rawUrl);
  }

  static bool get isConfigured {
    return url.isNotEmpty &&
        anonKey.isNotEmpty &&
        !_containsPlaceholder(url) &&
        !_containsPlaceholder(anonKey) &&
        _isHttpsUrl(url);
  }

  static String get setupMessage {
    if (url.isEmpty || anonKey.isEmpty) {
      return 'Add SUPABASE_URL and SUPABASE_ANON_KEY to .env before running the app.';
    }
    if (_containsPlaceholder(url) || _containsPlaceholder(anonKey)) {
      return 'Replace the placeholder Supabase URL and anon key with your real Supabase project values.';
    }
    if (!_isHttpsUrl(url)) {
      return 'SUPABASE_URL is invalid. Use the Project URL from Supabase, for example https://your-project.supabase.co';
    }
    return 'Supabase configuration is invalid. Check SUPABASE_URL and SUPABASE_ANON_KEY.';
  }

  static Future<Map<String, String>> _loadDotEnv() async {
    try {
      final content = await rootBundle.loadString(_assetPath);
      return _parseDotEnv(content);
    } catch (_) {
      return const {};
    }
  }

  static Map<String, String> _parseDotEnv(String content) {
    final values = <String, String>{};
    for (final rawLine in content.split('\n')) {
      var line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line.startsWith('export ')) line = line.substring(7).trim();

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();
      values[key] = _unquote(value);
    }
    return values;
  }

  static String _valueFrom(
    Map<String, String> values,
    String key, {
    required String fallback,
  }) {
    final value = values[key]?.trim();
    if (value == null || value.isEmpty) return fallback.trim();
    return value;
  }

  static String _unquote(String value) {
    if (value.length < 2) return value;
    final startsWithSingleQuote = value.startsWith("'");
    final startsWithDoubleQuote = value.startsWith('"');
    if ((startsWithSingleQuote && value.endsWith("'")) ||
        (startsWithDoubleQuote && value.endsWith('"'))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool _containsPlaceholder(String value) {
    final lower = value.toLowerCase();
    return lower.contains('replace-this') ||
        lower.contains('your-project') ||
        lower.contains('your-anon-key');
  }
}
