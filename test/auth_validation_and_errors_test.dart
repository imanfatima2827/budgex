import 'package:budgex/utils/auth_validators.dart';
import 'package:budgex/utils/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthValidators', () {
    test('normalizes email addresses', () {
      expect(
        AuthValidators.normalizeEmail('  AwanIman28@GMAIL.COM  '),
        'awaniman28@gmail.com',
      );
    });

    test('accepts a strong signup password', () {
      expect(AuthValidators.strongPassword('Alice123@'), isNull);
    });

    test('rejects invalid email and weak password values', () {
      expect(AuthValidators.email('awan iman@gmail.com'), isNotNull);
      expect(AuthValidators.strongPassword('alice123'), isNotNull);
    });

    test('throws readable validation errors', () {
      expect(
        () => AuthValidators.validateOrThrow(
          AuthValidators.email,
          'not-an-email',
        ),
        throwsA(isA<AuthValidationException>()),
      );
    });
  });

  group('friendlySupabaseMessage', () {
    test('maps Supabase socket host lookup failures to friendly copy', () {
      final message = friendlySupabaseMessage(
        const AuthException(
          "ClientException with SocketException: Failed host lookup: "
          "'qdsavpymhyoyvivltnae.supabase.co' "
          "(OS Error: No address associated with hostname, errno = 7)",
        ),
      );

      expect(message, contains('Cannot reach Supabase'));
      expect(message, isNot(contains('SocketException')));
    });
  });
}
