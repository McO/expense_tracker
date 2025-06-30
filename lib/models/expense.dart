import 'currency.dart';
import 'category.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final Currency currency;
  final Category category;
  final DateTime date;
  final String description;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'currency': currency.code,
      'categoryId': category.id,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json, List<Category> categories) {
    // Find the category by ID, fall back to 'other' if not found
    Category category;
    try {
      category = categories.firstWhere((cat) => cat.id == json['categoryId']);
    } catch (e) {
      // If category not found, try to find 'other' category
      try {
        category = categories.firstWhere((cat) => cat.id == 'other');
      } catch (e) {
        // If 'other' not found either, use the first available category
        category = categories.isNotEmpty ? categories.first : Category.defaultCategories.first;
      }
    }

    return Expense(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      currency: Currency.fromCode(json['currency'] ?? 'USD'),
      category: category,
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    Currency? currency,
    Category? category,
    DateTime? date,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }

  String get formattedAmount => '${currency.symbol}${amount.toStringAsFixed(2)}';
} 