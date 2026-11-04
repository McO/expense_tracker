import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final String color; // Hex color code
  final bool isDefault; // Whether it's a default category that can't be deleted
  final String? exportName; // Optional name used for CSV exports

  /// Whether movements in this category count as spending/income in
  /// statistics. Top-up and Correction are not counted (ADR-0007).
  final bool countsInStatistics;

  static const String topUpId = 'topup';
  static const String correctionId = 'correction';

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.exportName,
    this.countsInStatistics = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'exportName': exportName,
      'countsInStatistics': countsInStatistics,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      isDefault: json['isDefault'] ?? false,
      exportName: json['exportName'],
      countsInStatistics: json['countsInStatistics'] ?? true,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    String? exportName,
    bool? countsInStatistics,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      exportName: exportName ?? this.exportName,
      countsInStatistics: countsInStatistics ?? this.countsInStatistics,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Color toColor() {
    try {
      return Color(int.parse(color, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // Get the name to use for exports
  String get effectiveExportName => exportName?.trim().isNotEmpty == true ? exportName! : name;

  /// Built-in categories for cash that does not count as spending or income.
  /// Seeded non-destructively by `CategoryService` (separate from the
  /// defaults list so existing installs gain them without losing anything).
  static const Category topUp = Category(
    id: topUpId,
    name: 'Top-up',
    icon: '🏧',
    color: 'FF009688',
    isDefault: true,
    countsInStatistics: false,
  );

  static const Category correction = Category(
    id: correctionId,
    name: 'Correction',
    icon: '⚖️',
    color: 'FF607D8B',
    isDefault: true,
    countsInStatistics: false,
  );

  static List<Category> get ledgerCategories => [topUp, correction];

  // Default categories (universal - can be used for both expenses and income)
  static List<Category> get defaultCategories => [
    const Category(
      id: 'food',
      name: 'Food',
      icon: '🍽️',
      color: 'FF4CAF50',
      isDefault: true,
    ),
    const Category(
      id: 'transportation',
      name: 'Transportation',
      icon: '🚗',
      color: 'FF2196F3',
      isDefault: true,
    ),
    const Category(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛒',
      color: 'FFE91E63',
      isDefault: true,
    ),
    const Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: '🎬',
      color: 'FF9C27B0',
      isDefault: true,
    ),
    const Category(
      id: 'bills',
      name: 'Bills',
      icon: '💡',
      color: 'FFFF9800',
      isDefault: true,
    ),
    const Category(
      id: 'health',
      name: 'Health',
      icon: '💊',
      color: 'FFF44336',
      isDefault: true,
    ),
    const Category(
      id: 'education',
      name: 'Education',
      icon: '📚',
      color: 'FF3F51B5',
      isDefault: true,
    ),
    const Category(
      id: 'travel',
      name: 'Travel',
      icon: '✈️',
      color: 'FF00BCD4',
      isDefault: true,
    ),
    const Category(
      id: 'salary',
      name: 'Salary',
      icon: '💼',
      color: 'FF4CAF50',
      isDefault: true,
    ),
    const Category(
      id: 'freelance',
      name: 'Freelance',
      icon: '💻',
      color: 'FF2196F3',
      isDefault: true,
    ),
    const Category(
      id: 'business',
      name: 'Business',
      icon: '🏪',
      color: 'FFFF9800',
      isDefault: true,
    ),
    const Category(
      id: 'investment',
      name: 'Investment',
      icon: '📈',
      color: 'FF9C27B0',
      isDefault: true,
    ),
    const Category(
      id: 'bonus',
      name: 'Bonus',
      icon: '🎁',
      color: 'FFE91E63',
      isDefault: true,
    ),
    const Category(
      id: 'rental',
      name: 'Rental',
      icon: '🏠',
      color: 'FF795548',
      isDefault: true,
    ),
    const Category(
      id: 'refund',
      name: 'Refund',
      icon: '↩️',
      color: 'FF607D8B',
      isDefault: true,
    ),
    const Category(
      id: 'other',
      name: 'Other',
      icon: '📋',
      color: 'FF9E9E9E',
      isDefault: true,
    ),
  ];
} 