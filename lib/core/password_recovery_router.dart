import 'package:flutter/material.dart';

import '../screens/reset_password_screen.dart';
import 'app_navigator.dart';
import 'password_recovery_storage.dart';

class PasswordRecoveryRouter {
  PasswordRecoveryRouter();

  bool _isOpeningResetScreen = false;

  Future<void> openResetPasswordScreen() async {
    if (_isOpeningResetScreen) return;
    _isOpeningResetScreen = true;
    await PasswordRecoveryStorage.consumeIfFresh();
    _pushWhenNavigatorIsReady();
  }

  void _pushWhenNavigatorIsReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _pushWhenNavigatorIsReady();
        return;
      }

      await navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        (_) => false,
      );
      _isOpeningResetScreen = false;
    });
  }
}
