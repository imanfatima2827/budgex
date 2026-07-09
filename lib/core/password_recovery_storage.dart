import 'package:shared_preferences/shared_preferences.dart';

class PasswordRecoveryStorage {
  const PasswordRecoveryStorage._();

  static const _pendingSentAtKey = 'pending_password_recovery_sent_at';
  static const _validFor = Duration(hours: 2);

  static Future<void> markPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _pendingSentAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> consumeIfFresh() async {
    final prefs = await SharedPreferences.getInstance();
    final sentAt = prefs.getInt(_pendingSentAtKey);
    await prefs.remove(_pendingSentAtKey);

    if (sentAt == null) return false;

    final sentTime = DateTime.fromMillisecondsSinceEpoch(sentAt);
    return DateTime.now().difference(sentTime) <= _validFor;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSentAtKey);
  }
}
