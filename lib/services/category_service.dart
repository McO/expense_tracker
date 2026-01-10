import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

class CategoryService {
  static const String _categoriesKey = 'categories';
  static const String _defaultsInitializedKey = 'categories_defaults_initialized_v2';

  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if default categories have been initialized
    final defaultsInitialized = prefs.getBool(_defaultsInitializedKey) ?? false;
    if (!defaultsInitialized) {
      await _initializeDefaultCategories();
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
    final category = categories.firstWhere((c) => c.id == categoryId);
    
    // Don't allow deletion of default categories
    if (category.isDefault) {
      throw Exception('Cannot delete default categories');
    }
    
    categories.removeWhere((c) => c.id == categoryId);
    await _saveCategories(categories);
  }

  Future<Category?> getCategoryById(String id) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
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