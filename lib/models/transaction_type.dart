/// Direction of a movement. Amounts are always stored positive (ADR-0004);
/// the owner's sign decides the direction: income = money in, expense = money
/// out. Whether a movement counts in statistics is decided by its category
/// (`Category.countsInStatistics`), not by the type (see ADR-0007).
enum TransactionType {
  expense,
  income,
}

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
    }
  }

  String get code {
    switch (this) {
      case TransactionType.expense:
        return 'expense';
      case TransactionType.income:
        return 'income';
    }
  }

  /// True when the movement adds to the wallet balance.
  bool get increasesBalance => this == TransactionType.income;

  /// Interim s2v1q codes (`topup`, `correction_in`, `correction_out`) stay
  /// readable: they load as income, income and expense. Unknown codes fall
  /// back to expense.
  static TransactionType fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'income':
      case 'topup':
      case 'correction_in':
        return TransactionType.income;
      case 'expense':
      case 'correction_out':
      default:
        return TransactionType.expense;
    }
  }
}
