import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  static const _pinKey = 'security_pin';
  static const _biometricKey = 'biometric_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoaded = false;
  bool _isUnlocked = false;
  bool _isLockSuspended = false;
  String? _pin;
  bool _biometricEnabled = false;
  String? _biometricError;

  bool get isLoaded => _isLoaded;
  bool get pinEnabled => _pin != null && _pin!.isNotEmpty;
  bool get biometricEnabled => _biometricEnabled;
  String? get biometricError => _biometricError;
  bool get lockEnabled => pinEnabled || biometricEnabled;
  bool get isUnlocked => !lockEnabled || _isUnlocked;
  bool get lockSuspended => _isLockSuspended;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    _biometricEnabled = prefs.getBool(_biometricKey) ?? false;
    if (!pinEnabled && _biometricEnabled) {
      _biometricEnabled = false;
      await prefs.setBool(_biometricKey, false);
    }
    _isLockSuspended = false;
    _isUnlocked = !lockEnabled;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final normalized = pin.trim();
    if (normalized.length < 4) {
      throw Exception('PIN must be at least 4 digits.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, normalized);
    _pin = normalized;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    _pin = null;
    _biometricEnabled = false;
    await prefs.setBool(_biometricKey, false);
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      if (!pinEnabled) {
        throw Exception('Set a PIN before enabling biometrics.');
      }
      final biometrics = await _availableBiometrics();
      if (biometrics.isEmpty) {
        throw Exception(
          _biometricError ??
              'Add a fingerprint or face unlock in your device settings first.',
        );
      }
      final verified = await _authenticateWithBiometrics(
        'Confirm your fingerprint or face unlock to enable Budgex biometrics.',
      );
      if (!verified) {
        throw Exception(
          _biometricError ?? 'Biometric verification was cancelled.',
        );
      }
    }
    _biometricEnabled = enabled;
    await prefs.setBool(_biometricKey, enabled);
    notifyListeners();
  }

  Future<bool> canUseBiometrics() async {
    try {
      final biometrics = await _availableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool unlockWithPin(String pin) {
    if (_pin == null || pin.trim() != _pin) return false;
    _isUnlocked = true;
    notifyListeners();
    return true;
  }

  void suspendLock() {
    _isLockSuspended = true;
  }

  void resumeLock() {
    _isLockSuspended = false;
  }

  Future<bool> unlockWithBiometrics() async {
    if (!_biometricEnabled) return false;
    final biometrics = await _availableBiometrics();
    if (biometrics.isEmpty) {
      _biometricError =
          'No fingerprint or face unlock is enrolled on this device.';
      notifyListeners();
      return false;
    }

    final ok = await _authenticateWithBiometrics(
      'Unlock Budgex with your fingerprint or face unlock.',
    );
    if (ok) {
      _isUnlocked = true;
    }
    notifyListeners();
    return ok;
  }

  void lock() {
    if (!lockEnabled || _isLockSuspended) return;
    _isUnlocked = false;
    notifyListeners();
  }

  Future<List<BiometricType>> _availableBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) {
        _biometricError =
            'Biometric authentication is not available on this device.';
        return const [];
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        _biometricError =
            'Add a fingerprint or face unlock in your device settings first.';
      }
      return biometrics;
    } on PlatformException catch (error) {
      _biometricError = _biometricExceptionMessage(error);
      return const [];
    } catch (_) {
      _biometricError = 'Biometric unlock failed. Try again.';
      return const [];
    }
  }

  Future<bool> _authenticateWithBiometrics(String reason) async {
    _biometricError = null;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok) {
        _biometricError = 'Biometric verification was cancelled.';
      }
      return ok;
    } on PlatformException catch (error) {
      _biometricError = _biometricExceptionMessage(error);
      return false;
    } catch (_) {
      _biometricError = 'Biometric unlock failed. Try again.';
      return false;
    }
  }

  String _biometricExceptionMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('permanent')) {
      return 'Biometric unlock is locked. Unlock your phone with your device PIN first.';
    }
    if (code.contains('lock')) {
      return 'Biometric unlock is temporarily locked. Use your PIN, then try again later.';
    }
    if (code.contains('notenrolled') || code.contains('not_enrolled')) {
      return 'Add a fingerprint or face unlock in your device settings first.';
    }
    if (code.contains('passcodenotset') || code.contains('passcode_not_set')) {
      return 'Set a screen lock on this device first.';
    }
    if (code.contains('notavailable') || code.contains('not_available')) {
      return 'Biometric authentication is not available on this device.';
    }

    final message = error.message?.trim();
    if (message == null || message.isEmpty) {
      return 'Biometric unlock failed. Try again.';
    }
    return message;
  }
}
