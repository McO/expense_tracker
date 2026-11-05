import '../models/category.dart';
import '../models/currency.dart';
import '../models/transaction.dart';

/// Pure aggregation over transactions: account balance counts every kind, while
/// income/expense/category figures count only categories flagged countsInStatistics (ADR-0007).
class LedgerTotals {
  final double totalIncome;
  final double totalExpenses;
  final Map<Category, double> categoryTotals;
  final Map<Category, double> categoryIncomeTotal;
  final Map<Category, double> categoryExpenseTotal;
  final Map<Currency, double> currencyTotals;

  const LedgerTotals({
    required this.totalIncome,
    required this.totalExpenses,
    required this.categoryTotals,
    required this.categoryIncomeTotal,
    required this.categoryExpenseTotal,
    required this.currencyTotals,
  });

  /// Savings rate in percent of income; 0 when there is no income.
  double get savingsRate =>
      totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0.0;

  static LedgerTotals statistics(Iterable<Transaction> transactions) {
    double income = 0.0;
    double spending = 0.0;
    final categoryTotals = <Category, double>{};
    final categoryIncome = <Category, double>{};
    final categoryExpense = <Category, double>{};
    final currencyTotals = <Currency, double>{};
    for (final e in transactions) {
      if (!e.countsInStatistics) continue;
      if (e.isIncome) {
        income += e.amount;
        categoryIncome[e.category] = (categoryIncome[e.category] ?? 0) + e.amount;
      } else {
        spending += e.amount;
        categoryExpense[e.category] = (categoryExpense[e.category] ?? 0) + e.amount;
      }
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
      currencyTotals[e.currency] = (currencyTotals[e.currency] ?? 0) + e.amount;
    }
    return LedgerTotals(
      totalIncome: income,
      totalExpenses: spending,
      categoryTotals: categoryTotals,
      categoryIncomeTotal: categoryIncome,
      categoryExpenseTotal: categoryExpense,
      currencyTotals: currencyTotals,
    );
  }

  /// Account balance = sum of every transaction by sign.
  static double balance(Iterable<Transaction> transactions) =>
      transactions.fold(0.0, (sum, e) => sum + e.signedAmount);
}
