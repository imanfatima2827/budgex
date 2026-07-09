class AuthValidationException implements Exception {
  const AuthValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
  static final RegExp _whitespaceRegex = RegExp(r'\s');

  static String normalizeEmail(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Full name is required';
    if (trimmed.length < 2) return 'Full name is too short';
    if (trimmed.length > 60) return 'Full name is too long';
    return null;
  }

  static String? email(String? value) {
    final trimmed = normalizeEmail(value);
    if (trimmed.isEmpty) return 'Email address is required';
    if (_whitespaceRegex.hasMatch(trimmed)) {
      return 'Email address cannot contain spaces';
    }
    if (trimmed.length > 254) return 'Email address is too long';
    if (trimmed.contains('..')) return 'Enter a valid email address';
    if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? loginPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (password.length > 72) return 'Password must be 72 characters or less';
    return null;
  }

  static String? strongPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.trim() != password) {
      return 'Password cannot start or end with spaces';
    }
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (password.length > 72) return 'Password must be 72 characters or less';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Add at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Add at least one special character';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static void validateOrThrow(
    String? Function(String?) validator,
    String? value,
  ) {
    final message = validator(value);
    if (message != null) throw AuthValidationException(message);
  }
}
