import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';

class CategoryService {
  CategoryService({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<List<ExpenseCategory>> fetchCategories() async {
    final rows = await _supabase
        .from('categories')
        .select('id, user_id, name, icon_name, color_hex, is_default')
        .order('is_default', ascending: false)
        .order('name');

    return (rows as List)
        .map(
          (row) =>
              ExpenseCategory.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<ExpenseCategory> addCategory(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('No logged-in user found.');

    final row = await _supabase
        .from('categories')
        .insert({
          'user_id': user.id,
          'name': name.trim(),
          'icon_name': 'category',
          'color_hex': '#006FFD',
          'is_default': false,
        })
        .select('id, user_id, name, icon_name, color_hex, is_default')
        .single();

    return ExpenseCategory.fromMap(row);
  }
}
