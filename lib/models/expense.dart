class Expense {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String description;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}

enum ExpenseCategory {
  food('Food', '🍽️'),
  transportation('Transportation', '🚗'),
  shopping('Shopping', '🛒'),
  entertainment('Entertainment', '🎬'),
  bills('Bills', '💡'),
  health('Health', '💊'),
  education('Education', '📚'),
  travel('Travel', '✈️'),
  other('Other', '📋');

  const ExpenseCategory(this.displayName, this.icon);

  final String displayName;
  final String icon;
} 