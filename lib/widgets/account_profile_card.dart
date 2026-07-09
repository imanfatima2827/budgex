import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'app_card.dart';
import 'app_scaled_text.dart';

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({
    super.key,
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(name);
    final displayEmail = email.trim().isEmpty
        ? 'Signed in account'
        : email.trim();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ProfileAvatar(name: displayName),
          const SizedBox(width: 14),
          Expanded(
            child: _ProfileDetails(
              name: displayName,
              email: displayEmail,
            ),
          ),
        ],
      ),
    );
  }

  static String _displayName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'User' : trimmed;
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.name, this.size = 64});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.teal],
        ),
      ),
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static String _initials(String value) {
    final initials = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return initials.isEmpty ? 'U' : initials;
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppScaledText(
          name,
          minFontSize: 11,
          style: TextStyle(
            color: AppTheme.titleColor(context),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        AppScaledText(
          email,
          minFontSize: 10,
          style: TextStyle(
            color: AppTheme.bodyColor(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
