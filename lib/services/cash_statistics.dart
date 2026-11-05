import '../models/category.dart';
import '../models/expense.dart';
import 'ledger_totals.dart';

/// Period the burn rate and spending mix are computed over.
enum StatsPeriod { thisMonth, last7Days }

/// Pure quick-glance cash statistics for one wallet (cash-ledger-bktw5).
/// Spending = money out in categories that count in statistics (ADR-0007);
/// the balance counts every movement. Nothing is converted across currencies.
class CashStatistics {
  final double balance;
  final double spending;
  final int daysElapsed;
  final double dailyAverage;

  /// floor(balance / dailyAverage); null when the average is 0 or balance <= 0.
  final int? lastsDays;

  /// Exactly 7 daily spending values, oldest first, last one is today.
  final List<double> last7Days;

  /// Counting categories by spending in the period, largest first.
  final List<MapEntry<Category, double>> spendingMix;

  const CashStatistics({
    required this.balance,
    required this.spending,
    required this.daysElapsed,
    required this.dailyAverage,
    required this.lastsDays,
    required this.last7Days,
    required this.spendingMix,
  });

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static CashStatistics compute({
    required Iterable<Expense> expenses,
    required String accountId,
    required DateTime today,
    required StatsPeriod period,
  }) {
    final t = _day(today);
    final wallet = expenses.where((e) => e.accountId == accountId).toList();
    final balance = LedgerTotals.balance(wallet);
    final counted =
        wallet.where((e) => e.isExpense && e.countsInStatistics).toList();

    final start = period == StatsPeriod.thisMonth
        ? DateTime(t.year, t.month, 1)
        : DateTime(t.year, t.month, t.day - 6);
    final days = period == StatsPeriod.thisMonth ? t.day : 7;

    bool inRange(DateTime from, Expense e) {
      final d = _day(e.date);
      return !d.isBefore(from) && !d.isAfter(t);
    }

    final inPeriod = counted.where((e) => inRange(start, e)).toList();
    final spending = inPeriod.fold(0.0, (s, e) => s + e.amount);
    final avg = spending / days;

    final series = List<double>.filled(7, 0.0);
    for (var i = 0; i < 7; i++) {
      final day = DateTime(t.year, t.month, t.day - (6 - i));
      for (final e in counted) {
        if (_day(e.date) == day) series[i] += e.amount;
      }
    }

    final mix = <Category, double>{};
    for (final e in inPeriod) {
      mix[e.category] = (mix[e.category] ?? 0) + e.amount;
    }
    final mixList = mix.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CashStatistics(
      balance: balance,
      spending: spending,
      daysElapsed: days,
      dailyAverage: avg,
      lastsDays: (avg > 0 && balance > 0) ? (balance / avg).floor() : null,
      last7Days: series,
      spendingMix: mixList,
    );
  }
}
