import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

class CategoryService {
  static const String _categoriesKey = 'categories';
  static const String _defaultsInitializedKey = 'categories_defaults_initialized_v2';
  static const String _ledgerCategoriesKey = 'categories_ledger_ensured_v1';

  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if default categories have been initialized
    final defaultsInitialized = prefs.getBool(_defaultsInitializedKey) ?? false;
    if (!defaultsInitialized) {
      await _initializeDefaultCategories();
    }
    
    if (!(prefs.getBool(_ledgerCategoriesKey) ?? false)) {
      await _ensureLedgerCategories();
    }

    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
    return categoriesJson.map((json) => Category.fromJson(jsonDecode(json))).toList();
  }

  Future<void> _initializeDefaultCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save default categories (universal - works for both expense and income)
    final defaultCategories = Category.defaultCategories;
    await _saveCategories(defaultCategories);
    
    // Mark defaults as initialized
    await prefs.setBool(_defaultsInitializedKey, true);
  }

  /// Idempotent: inserts the built-in Top-up/Correction categories only if
  /// missing by id; never touches existing categories (ADR-0004, ADR-0007).
  Future<void> _ensureLedgerCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(_categoriesKey) ?? [];
    final existing = json.map((j) => Category.fromJson(jsonDecode(j))).toList();
    for (final c in Category.ledgerCategories) {
      if (!existing.any((e) => e.id == c.id)) existing.add(c);
    }
    await _saveCategories(existing);
    await prefs.setBool(_ledgerCategoriesKey, true);
  }

  Future<void> _saveCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = categories.map((category) => jsonEncode(category.toJson())).toList();
    await prefs.setStringList(_categoriesKey, categoriesJson);
  }

  Future<void> saveCategory(Category category) async {
    final categories = await getCategories();
    
    // Check if category already exists
    final existingIndex = categories.indexWhere((c) => c.id == category.id);
    if (existingIndex != -1) {
      categories[existingIndex] = category;
    } else {
      categories.add(category);
    }
    
    await _saveCategories(categories);
  }

  Future<void> updateCategory(Category category) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    
    if (index != -1) {
      categories[index] = category;
      await _saveCategories(categories);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final categories = await getCategories();
    final idx = categories.indexWhere((c) => c.id == categoryId);
    if (idx < 0) return;
    if (categories[idx].isDefault) {
      throw Exception('Cannot delete default categories');
    }
    categories.removeAt(idx);
    await _saveCategories(categories);
  }

  Future<Category?> getCategoryById(String id) async {
    final categories = await getCategories();
    final idx = categories.indexWhere((c) => c.id == id);
    return idx >= 0 ? categories[idx] : null;
  }

  Future<bool> categoryExists(String name, {String? excludeId}) async {
    final categories = await getCategories();
    return categories.any((c) => 
        c.name.toLowerCase() == name.toLowerCase() && 
        c.id != excludeId);
  }

  String generateCategoryId(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  // Get available icons for category selection
  static List<String> get availableIcons => [
    '🍽️', '🚗', '🛒', '🎬', '💡', '💊', '📚', '✈️', '📋',
    '☕', '🏠', '⛽', '🎯', '🎮', '💻', '📱', '👕', '💄',
    '🎵', '🏃', '💰', '🎁', '🐕', '🌱', '⚡', '🔧', '🎨',
    '🍕', '🍜', '🍔', '🥤', '🚌', '🚖', '🚲', '⚓', '🏖️',
    '🏥', '💳', '📊', '📝', '📞', '💼', '🎪', '🎢', '🎡',
    '⚽', '🏀', '🎾', '🏈', '⚾', '🏐', '🏓', '🏸', '🏑',
    '🛍️', '👜', '👠', '⌚', '👓', '💎', '🎫', '🎭', '🎪',
    // Income specific icons
    '💼', '💻', '🏪', '📈', '🎁', '🏠', '↩️', '💰',
  ];

  // Get available colors for category selection
  static List<String> get availableColors => [
    'FF4CAF50', // Green
    'FF2196F3', // Blue
    'FFE91E63', // Pink
    'FF9C27B0', // Purple
    'FFFF9800', // Orange
    'FFF44336', // Red
    'FF3F51B5', // Indigo
    'FF00BCD4', // Cyan
    'FF9E9E9E', // Grey
    'FFCDDC39', // Lime
    'FFFF5722', // Deep Orange
    'FF795548', // Brown
    'FF607D8B', // Blue Grey
    'FFFFC107', // Amber
    'FF8BC34A', // Light Green
    'FF673AB7', // Deep Purple
    'FF009688', // Teal
    'FFFF1744', // Red Accent
  ];
} 