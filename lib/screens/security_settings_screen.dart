import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/security_provider.dart';
import '../utils/app_theme.dart';
import '../utils/error_messages.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  Future<void> _setPin(BuildContext context) async {
    final controller = TextEditingController();
    bool obscurePin = true;
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            scrollable: true,
            title: Text('Set App PIN'),
            content: TextField(
              controller: controller,
              autofocus: true,
              obscureText: obscurePin,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.number,
              maxLength: 8,
              scrollPadding: const EdgeInsets.only(bottom: 120),
              decoration: InputDecoration(
                hintText: 'Minimum 4 digits',
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: obscurePin ? 'Show PIN' : 'Hide PIN',
                  icon: Icon(
                    obscurePin
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () =>
                      setDialogState(() => obscurePin = !obscurePin),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text),
                child: Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (pin == null || !context.mounted) return;
    try {
      await context.read<SecurityProvider>().setPin(pin);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN lock enabled')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(cleanErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      appBar: AppBar(title: Text('Security')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Lock',
                    style: TextStyle(
                      color: AppTheme.titleColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Protect your finance data with a local PIN. Biometrics '
                    'can be enabled when the device supports it.',
                    style: TextStyle(
                      color: AppTheme.bodyColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 18),
                  PrimaryButton(
                    label: security.pinEnabled ? 'Change PIN' : 'Set PIN',
                    icon: Icons.pin_outlined,
                    onPressed: () => _setPin(context),
                  ),
                  if (security.pinEnabled) ...[
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.read<SecurityProvider>().removePin(),
                        icon: Icon(Icons.lock_open_rounded),
                        label: Text('Remove PIN Lock'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile.adaptive(
                value: security.biometricEnabled,
                title: Text(
                  'Biometric Unlock',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.titleColor(context),
                  ),
                ),
                subtitle: Text(
                  'Use fingerprint or face unlock when available.',
                ),
                secondary: Icon(
                  Icons.fingerprint_rounded,
                  color: AppTheme.primary,
                ),
                onChanged: (value) async {
                  try {
                    await context.read<SecurityProvider>().setBiometricEnabled(
                      value,
                    );
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(cleanErrorMessage(error))),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
