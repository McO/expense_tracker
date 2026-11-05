import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/cash_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

final today = DateTime(2026, 11, 10, 15);
final food = Category.defaultCategories.first;
final other = Category.defaultCategories[1];

Transaction e(double amt, DateTime date,
        {TransactionType type = TransactionType.expense,
        Category? cat,
        String acc = 'a'}) =>
    Transaction(
        id: '${amt}_${date.toIso8601String()}_$acc',
        title: 't',
        amount: amt,
        currency: Currency.usd,
        category: cat ?? food,
        date: date,
        type: type,
        accountId: acc);

CashStatistics stats(List<Transaction> xs, StatsPeriod p) => CashStatistics.compute(
    transactions: xs, accountId: 'a', today: today, period: p);

void main() {
  final data = [
    e(100, DateTime(2026, 11, 1)),
    e(50, DateTime(2026, 11, 10)),
    e(30, DateTime(2026, 11, 5), cat: other),
    e(999, DateTime(2026, 11, 6), cat: Category.topUp, type: TransactionType.income),
    e(40, DateTime(2026, 11, 6), cat: Category.correction),
    e(70, DateTime(2026, 11, 7), type: TransactionType.income),
    e(500, DateTime(2026, 11, 8), acc: 'b'),
    e(25, DateTime(2026, 10, 31)),
  ];

  test('this month: average over days 1..today inclusive, counting spending only', () {
    final s = stats(data, StatsPeriod.thisMonth);
    expect(s.spending, 180);
    expect(s.daysElapsed, 10);
    expect(s.dailyAverage, 18);
  });

  test('last 7 days: window is today-6..today (11-04..11-10), divided by 7', () {
    final s = stats(data, StatsPeriod.last7Days);
    expect(s.spending, 80);
    expect(s.dailyAverage, closeTo(80 / 7, 1e-9));
  });

  test('balance counts every transaction of the account only', () {
    final s = stats(data, StatsPeriod.thisMonth);
    expect(s.balance, -100 - 50 - 30 + 999 - 40 + 70 - 25);
  });

  test('lasts N days is floor(balance / average)', () {
    final xs = [e(100, DateTime(2026, 11, 1)), e(1000, DateTime(2026, 10, 1), type: TransactionType.income, cat: Category.topUp)];
    final s = stats(xs, StatsPeriod.thisMonth); // avg 10, balance 900+...
    expect(s.balance, 900);
    expect(s.lastsDays, 90);
    final s2 = stats([e(30, DateTime(2026, 11, 1)), e(100, DateTime(2026, 11, 1), type: TransactionType.income, cat: Category.topUp)], StatsPeriod.thisMonth);
    expect(s2.lastsDays, 23); // 70 / 3 = 23.33
  });

  test('lasts N days hidden when average is 0 or balance <= 0', () {
    expect(stats([e(100, DateTime(2026, 11, 1), type: TransactionType.income, cat: Category.topUp)], StatsPeriod.thisMonth).lastsDays, isNull);
    expect(stats([e(100, DateTime(2026, 11, 1))], StatsPeriod.thisMonth).lastsDays, isNull);
    expect(stats([], StatsPeriod.thisMonth).lastsDays, isNull);
  });

  test('last-7-days series has 7 values ending today, regardless of period', () {
    final s = stats(data, StatsPeriod.thisMonth);
    expect(s.last7Days.length, 7);
    expect(s.last7Days, [0.0, 30.0, 0.0, 0.0, 0.0, 0.0, 50.0]); // 11-04 .. 11-10
    expect(stats(data, StatsPeriod.last7Days).last7Days, s.last7Days);
  });

  test('spending mix: counting categories, largest first, empty when none', () {
    final s = stats(data, StatsPeriod.thisMonth);
    expect(s.spendingMix.map((m) => m.key.id), [food.id, other.id]);
    expect(s.spendingMix.map((m) => m.value), [150, 30]);
    expect(stats([], StatsPeriod.thisMonth).spendingMix, isEmpty);
    expect(stats(data, StatsPeriod.last7Days).spendingMix.map((m) => m.value), [50, 30]);
  });

  test('spending mix is sorted by size, not by insertion order (both periods)', () {
    final xs = [
      e(30, DateTime(2026, 11, 9), cat: other), // smaller category first (newest first)
      e(80, DateTime(2026, 11, 8), cat: food),
    ];
    for (final p in StatsPeriod.values) {
      final s = stats(xs, p);
      expect(s.spendingMix.map((m) => m.key.id), [food.id, other.id], reason: '$p');
      expect(s.spendingMix.map((m) => m.value), [80, 30], reason: '$p');
    }
  });

  test('lasts N days floors: 850 / 15 per day is 56, not 57', () {
    final xs = [
      e(850 + 150, DateTime(2026, 10, 1), type: TransactionType.income, cat: Category.topUp),
      e(150, DateTime(2026, 11, 1)), // 150 over 10 days = 15/day, balance 850
    ];
    final s = stats(xs, StatsPeriod.thisMonth);
    expect(s.balance, 850);
    expect(s.dailyAverage, 15);
    expect(s.lastsDays, 56);
  });

  test('lasts N days hidden when balance is exactly 0 with a positive average', () {
    final xs = [
      e(100, DateTime(2026, 10, 1), type: TransactionType.income, cat: Category.topUp),
      e(100, DateTime(2026, 11, 1)),
    ];
    final s = stats(xs, StatsPeriod.thisMonth);
    expect(s.balance, 0);
    expect(s.dailyAverage, greaterThan(0));
    expect(s.lastsDays, isNull);
  });
}
