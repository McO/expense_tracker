/// Movement kinds of the cash ledger. Amounts are always stored positive
/// (ADR-0004); the kind decides the direction and whether the movement
/// counts in statistics (see ADR-0006).
enum TransactionType {
  expense,
  income,
  topUp,
  correctionIn,
  correctionOut,
}

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.topUp:
        return 'Top-up';
      case TransactionType.correctionIn:
      case TransactionType.correctionOut:
        return 'Correction';
    }
  }

  String get code {
    switch (this) {
      case TransactionType.expense:
        return 'expense';
      case TransactionType.income:
        return 'income';
      case TransactionType.topUp:
        return 'topup';
      case TransactionType.correctionIn:
        return 'correction_in';
      case TransactionType.correctionOut:
        return 'correction_out';
    }
  }

  /// True when the movement adds to the wallet balance.
  bool get increasesBalance =>
      this == TransactionType.income ||
      this == TransactionType.topUp ||
      this == TransactionType.correctionIn;

  /// True for spending and income only; top-ups and corrections move the
  /// balance but are excluded from statistics.
  bool get countsInStatistics =>
      this == TransactionType.expense || this == TransactionType.income;

  bool get isCorrection =>
      this == TransactionType.correctionIn ||
      this == TransactionType.correctionOut;

  static TransactionType fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'topup':
        return TransactionType.topUp;
      case 'correction_in':
        return TransactionType.correctionIn;
      case 'correction_out':
        return TransactionType.correctionOut;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }
}
