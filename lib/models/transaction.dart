import 'dart:ui' show Locale;
import '../services/amount_format.dart';
import 'currency.dart';
import 'category.dart';
import 'transaction_type.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final Currency currency;
  final Category category;
  final DateTime date;
  final String description;
  final TransactionType type;
  final String accountId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.description = '',
    this.type = TransactionType.expense, // Default to expense for backward compatibility
    required this.accountId,
  });

  // Helper getters
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTopUp => category.id == Category.topUpId;
  bool get isCorrection => category.id == Category.correctionId;

  /// Decided by the transaction's category flag (ADR-0007).
  bool get countsInStatistics => category.countsInStatistics;

  /// True when this transaction adds to the account balance.
  bool get increasesBalance => type.increasesBalance;

  // Signed amount for the account balance (positive when the transaction adds cash)
  double get signedAmount => increasesBalance ? amount : -amount;

  // Formatted amount with sign
  String formattedAmountWithSign([Locale? locale]) {
    final sign = increasesBalance ? '+' : '-';
    return '$sign${formatAmountWithSymbol(amount, currency, locale ?? deviceLocale())}';
  }

  /// Builds a correction transaction from the signed difference between the
  /// counted cash and the recorded balance (positive = cash was missing from
  /// the books, i.e. money in).
  factory Transaction.correction({
    required String id,
    required double difference,
    required Currency currency,
    required DateTime date,
    required String accountId,
    Category category = Category.correction,
    String title = 'Correction',
  }) {
    return Transaction(
      id: id,
      title: title,
      amount: difference.abs(),
      currency: currency,
      category: category,
      date: date,
      type: difference >= 0 ? TransactionType.income : TransactionType.expense,
      accountId: accountId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'currency': currency.code,
      'categoryId': category.id,
      'date': date.toIso8601String(),
      'description': description,
      'type': type.code,
      'accountId': accountId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json, List<Category> categories, {List<Currency> customCurrencies = const [], String? defaultAccountId}) {
    // Interim s2v1q codes carry their category when none is stored (ADR-0007)
    final rawType = (json['type'] ?? 'expense').toString().toLowerCase();
    final interimId = rawType == 'topup'
        ? Category.topUpId
        : (rawType == 'correction_in' || rawType == 'correction_out')
            ? Category.correctionId
            : null;
    final wantedId = categories.any((cat) => cat.id == json['categoryId'])
        ? json['categoryId']
        : (interimId ?? json['categoryId']);

    // Find the category by ID, fall back to 'other' if not found
    Category category;
    try {
      category = categories.firstWhere((cat) => cat.id == wantedId);
    } catch (e) {
      final builtIn = Category.ledgerCategories.where((cat) => cat.id == wantedId);
      if (builtIn.isNotEmpty) {
        category = builtIn.first;
      } else {
        // If category not found, try to find 'other' category
        try {
          category = categories.firstWhere((cat) => cat.id == 'other');
        } catch (e) {
          // If 'other' not found either, use the first available category
          category = categories.isNotEmpty ? categories.first : Category.defaultCategories.first;
        }
      }
    }

    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      currency: Currency.fromCode(json['currency'] ?? 'USD', customCurrencies: customCurrencies),
      category: category,
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
      type: TransactionTypeExtension.fromCode(json['type'] ?? 'expense'), // Default to expense for backward compatibility
      accountId: json['accountId'] ?? defaultAccountId ?? '', // Use provided accountId or default
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    Currency? currency,
    Category? category,
    DateTime? date,
    String? description,
    TransactionType? type,
    String? accountId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
    );
  }

  String formattedAmount([Locale? locale]) =>
      formatAmountWithSymbol(amount, currency, locale ?? deviceLocale());
} 