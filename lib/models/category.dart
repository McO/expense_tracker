import 'transaction_type.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final String color; // Hex color code
  final bool isDefault; // Whether it's a default category that can't be deleted
  final String? exportName; // Optional name used for CSV exports
  final TransactionType type; // Type of transaction this category is for

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.exportName,
    this.type = TransactionType.expense, // Default to expense for backward compatibility
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'exportName': exportName,
      'type': type.code,
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
      type: TransactionTypeExtension.fromCode(json['type'] ?? 'expense'),
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    String? exportName,
    TransactionType? type,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      exportName: exportName ?? this.exportName,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Get the name to use for exports
  String get effectiveExportName => exportName?.trim().isNotEmpty == true ? exportName! : name;

  // Helper getters
  bool get isExpenseCategory => type == TransactionType.expense;
  bool get isIncomeCategory => type == TransactionType.income;

  // Default expense categories
  static List<Category> get defaultExpenseCategories => [
    const Category(
      id: 'food',
      name: 'Food',
      icon: '🍽️',
      color: 'FF4CAF50',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'transportation',
      name: 'Transportation',
      icon: '🚗',
      color: 'FF2196F3',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛒',
      color: 'FFE91E63',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: '🎬',
      color: 'FF9C27B0',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'bills',
      name: 'Bills',
      icon: '💡',
      color: 'FFFF9800',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'health',
      name: 'Health',
      icon: '💊',
      color: 'FFF44336',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'education',
      name: 'Education',
      icon: '📚',
      color: 'FF3F51B5',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'travel',
      name: 'Travel',
      icon: '✈️',
      color: 'FF00BCD4',
      isDefault: true,
      type: TransactionType.expense,
    ),
    const Category(
      id: 'other_expense',
      name: 'Other',
      icon: '📋',
      color: 'FF9E9E9E',
      isDefault: true,
      type: TransactionType.expense,
    ),
  ];

  // Default income categories
  static List<Category> get defaultIncomeCategories => [
    const Category(
      id: 'salary',
      name: 'Salary',
      icon: '💼',
      color: 'FF4CAF50',
      isDefault: true,
      type: TransactionType.income,
    ),
    const Category(
      id: 'freelance',
      name: 'Freelance',
      icon: '💻',
      color: 'FF2196F3',
      isDefault: true,
      type: TransactionType.income,
    ),
    const Category(
      id: 'business',
      name: 'Business',
      icon: '🏪',
      color: 'FFFF9800',
      isDefault: true,
      type: TransactionType.income,
    ),
    const Category(
      id: 'investment',
      name: 'Investment',
      icon: '📈',
      color: 'FF9C27B0',
      isDefault: true,
      type: TransactionType.income,
    ),
    const Category(
      id: 'bonus',
      name: 'Bonus',
      icon: '🎁',
      color: 'FFE91E63',
      isDefault: true,
      type: TransactionType.income,
    ),
    const Category(
      id: 'rental',
      name: 'Rental',
      icon: '🏠',
      color: 'FF795548',
      isDefault: true,
      type: TransactionType.income,
    ),
    const Category(
      id: 'refund',
      name: 'Refund',
      icon: '↩️',
      color: 'FF607D8B',
      isDefault: true,
      type: TransactionType.income,
    ),
    const Category(
      id: 'other_income',
      name: 'Other',
      icon: '💰',
      color: 'FF9E9E9E',
      isDefault: true,
      type: TransactionType.income,
    ),
  ];

  // Combined default categories
  static List<Category> get defaultCategories => [
    ...defaultExpenseCategories,
    ...defaultIncomeCategories,
  ];

  // Backward compatibility getter
  static List<Category> get defaultExpenseCategories_old => defaultExpenseCategories;
} 