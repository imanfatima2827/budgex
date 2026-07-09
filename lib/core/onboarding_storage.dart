import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  const OnboardingStorage._();

  static const String hasSeenOnboardingKey = 'has_seen_onboarding_v1';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasSeenOnboardingKey) ?? false;
  }

  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenOnboardingKey, true);
  }
}
