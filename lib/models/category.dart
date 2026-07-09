import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.userId,
    this.iconName = 'category',
    this.colorHex = '#607D8B',
    this.isDefault = false,
  });

  final String id;
  final String? userId;
  final String name;
  final IconData icon;
  final Color color;
  final String iconName;
  final String colorHex;
  final bool isDefault;

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    final iconName = map['icon_name']?.toString() ?? 'category';
    final colorHex = map['color_hex']?.toString() ?? '#607D8B';

    return ExpenseCategory(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      name: map['name']?.toString() ?? 'Other',
      icon: iconFromName(iconName),
      color: colorFromHex(colorHex),
      iconName: iconName,
      colorHex: colorHex,
      isDefault: map['is_default'] == true,
    );
  }

  Map<String, dynamic> toInsertMap({required String currentUserId}) {
    return {
      'user_id': currentUserId,
      'name': name,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_default': false,
    };
  }

  static ExpenseCategory fallback() {
    return const ExpenseCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.category,
      color: Color(0xFF607D8B),
      iconName: 'category',
      colorHex: '#607D8B',
      isDefault: true,
    );
  }

  static IconData iconFromName(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'directions_car':
        return Icons.directions_car;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'bolt':
        return Icons.bolt;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'medical_services':
        return Icons.medical_services;
      case 'movie':
        return Icons.movie;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'category':
      default:
        return Icons.category;
    }
  }

  static Color colorFromHex(String value) {
    final normalized = value.replaceAll('#', '').trim();
    if (normalized.length != 6 && normalized.length != 8) {
      return const Color(0xFF607D8B);
    }

    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return const Color(0xFF607D8B);

    if (normalized.length == 6) {
      return Color(0xFF000000 | parsed);
    }
    return Color(parsed);
  }
}
