class Category {
  final String id;
  final String name;
  final String icon;
  final String color; // Hex color code
  final bool isDefault; // Whether it's a default category that can't be deleted

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Default categories that will be created on first launch
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
      id: 'other',
      name: 'Other',
      icon: '📋',
      color: 'FF9E9E9E',
      isDefault: true,
    ),
  ];
} 