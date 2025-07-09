import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/transaction_type.dart';

class CategoryService {
  static const String _categoriesKey = 'categories';
  static const String _defaultsInitializedKey = 'categories_defaults_initialized';
  static const String _incomeDefaultsInitializedKey = 'income_categories_defaults_initialized';

  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if default categories have been initialized
    final defaultsInitialized = prefs.getBool(_defaultsInitializedKey) ?? false;
    if (!defaultsInitialized) {
      await _initializeDefaultCategories();
    }
    
    // Check if income categories have been initialized (for existing users)
    final incomeDefaultsInitialized = prefs.getBool(_incomeDefaultsInitializedKey) ?? false;
    if (!incomeDefaultsInitialized) {
      await _initializeIncomeCategories();
    }
    
    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
    return categoriesJson.map((json) => Category.fromJson(jsonDecode(json))).toList();
  }

  Future<List<Category>> getCategoriesByType(TransactionType type) async {
    final allCategories = await getCategories();
    return allCategories.where((category) => category.type == type).toList();
  }

  Future<List<Category>> getExpenseCategories() async {
    return getCategoriesByType(TransactionType.expense);
  }

  Future<List<Category>> getIncomeCategories() async {
    return getCategoriesByType(TransactionType.income);
  }

  Future<void> _initializeDefaultCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save default categories (both expense and income)
    final defaultCategories = Category.defaultCategories;
    await _saveCategories(defaultCategories);
    
    // Mark defaults as initialized
    await prefs.setBool(_defaultsInitializedKey, true);
    await prefs.setBool(_incomeDefaultsInitializedKey, true);
  }

  Future<void> _initializeIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing categories directly from SharedPreferences to avoid infinite loop
    final categoriesJson = prefs.getStringList(_categoriesKey) ?? [];
    final existingCategories = categoriesJson.map((json) => Category.fromJson(jsonDecode(json))).toList();
    
    // Check if income categories already exist
    final hasIncomeCategories = existingCategories.any((cat) => cat.type == TransactionType.income);
    
    if (!hasIncomeCategories) {
      // Add income categories to existing categories
      final incomeCategories = Category.defaultIncomeCategories;
      final allCategories = [...existingCategories, ...incomeCategories];
      await _saveCategories(allCategories);
    }
    
    // Mark income defaults as initialized
    await prefs.setBool(_incomeDefaultsInitializedKey, true);
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

  Future<bool> categoryExists(String name, {String? excludeId, TransactionType? type}) async {
    final categories = await getCategories();
    return categories.any((c) => 
        c.name.toLowerCase() == name.toLowerCase() && 
        c.id != excludeId &&
        (type == null || c.type == type));
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