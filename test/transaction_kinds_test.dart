import 'dart:convert';

import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/category_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:expense_tracker/services/ledger_totals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _cats = [...Category.defaultCategories, ...Category.ledgerCategories];
final _food = _cats.first;
final _other = _cats[1];
final _topUp = Category.topUp;
final _correction = Category.correction;

Transaction _e(String id, double amount, TransactionType type,
        {Category? category}) =>
    Transaction(
      id: id,
      title: 'T$id',
      amount: amount,
      currency: Currency.usd,
      category: category ?? _food,
      date: DateTime(2026, 11, 4),
      type: type,
      accountId: 'a1',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('TransactionType has only expense and income; round-trips', () {
    expect(TransactionType.values, [TransactionType.expense, TransactionType.income]);
    for (final t in TransactionType.values) {
      final json = jsonDecode(jsonEncode(_e('1', 5, t, category: _topUp).toJson()));
      final back = Transaction.fromJson(json, _cats);
      expect(back.type, t);
      expect(back.amount, 5);
      expect(back.category, _topUp);
    }
  });

  test('interim codes load as income/income/expense with their categories', () {
    Map<String, dynamic> rec(String code, String cat) =>
        _e('1', 5, TransactionType.expense).toJson()
          ..['type'] = code
          ..['categoryId'] = cat;
    final top = Transaction.fromJson(rec('topup', 'food'), _cats);
    expect(top.type, TransactionType.income);
    expect(top.category, _food); // already carried another category id
    final topNoCat = Transaction.fromJson(rec('topup', 'gone'), _cats);
    expect(topNoCat.category, _topUp);
    final cin = Transaction.fromJson(rec('correction_in', 'gone'), _cats);
    expect(cin.type, TransactionType.income);
    expect(cin.category, _correction);
    final cout = Transaction.fromJson(rec('correction_out', 'gone'), _cats);
    expect(cout.type, TransactionType.expense);
    expect(cout.category, _correction);
  });

  test('legacy records load as before', () {
    Map<String, dynamic> base() => _e('1', 5, TransactionType.expense).toJson();
    expect(Transaction.fromJson(base()..['type'] = 'income', _cats).type,
        TransactionType.income);
    expect(Transaction.fromJson(base()..['type'] = 'expense', _cats).type,
        TransactionType.expense);
    expect(Transaction.fromJson(base()..remove('type'), _cats).type,
        TransactionType.expense);
  });

  test('Category.countsInStatistics persists; missing loads true', () {
    expect(_food.countsInStatistics, isTrue);
    final c = _food.copyWith(countsInStatistics: false);
    expect(Category.fromJson(jsonDecode(jsonEncode(c.toJson()))).countsInStatistics,
        isFalse);
    final legacy = _food.toJson()..remove('countsInStatistics');
    expect(Category.fromJson(legacy).countsInStatistics, isTrue);
  });

  test('fresh install gets Top-up and Correction, not counted in statistics',
      () async {
    final cats = await CategoryService().getCategories();
    final t = cats.firstWhere((c) => c.id == Category.topUpId);
    final c = cats.firstWhere((c) => c.id == Category.correctionId);
    expect(t.countsInStatistics, isFalse);
    expect(c.countsInStatistics, isFalse);
    expect(t.effectiveExportName, 'Top-up');
    expect(c.effectiveExportName, 'Correction');
    expect(cats.length, Category.defaultCategories.length + 2);
  });

  test('existing install keeps user categories; step is idempotent', () async {
    final mine = const Category(id: 'mine', name: 'Mine', icon: 'x', color: 'FF000000');
    final edited = _food.copyWith(name: 'Groceries');
    SharedPreferences.setMockInitialValues({
      'categories_defaults_initialized_v2': true,
      'categories': [
        jsonEncode(edited.toJson()),
        jsonEncode(mine.toJson()),
      ],
    });
    final svc = CategoryService();
    final first = await svc.getCategories();
    expect(first.map((c) => c.id), ['food', 'mine', Category.topUpId, Category.correctionId]);
    expect(first.first.name, 'Groceries');
    final second = await svc.getCategories();
    expect(second.length, 4);
    // a user deleting/renaming later is not undone by re-seeding
    await svc.updateCategory(second.last.copyWith(name: 'Cash diff'));
    expect((await svc.getCategories()).last.name, 'Cash diff');
  });

  final all = [
    _e('1', 100, TransactionType.income),
    _e('2', 50, TransactionType.income, category: _topUp),
    _e('3', 7, TransactionType.income, category: _correction),
    _e('4', 30, TransactionType.expense, category: _other),
    _e('5', 3, TransactionType.expense, category: _correction),
  ];

  test('account balance counts every transaction by sign', () {
    expect(LedgerTotals.balance(all), 100 + 50 + 7 - 30 - 3);
  });

  test('statistics exclude categories not counted in statistics', () {
    final s = LedgerTotals.statistics(all);
    expect(s.totalIncome, 100);
    expect(s.totalExpenses, 30);
    expect(s.categoryIncomeTotal, {_food: 100});
    expect(s.categoryExpenseTotal, {_other: 30});
    expect(s.categoryTotals, {_food: 100, _other: 30});
    expect(s.currencyTotals, {Currency.usd: 130});
    expect(s.savingsRate, closeTo(70, 1e-9));
  });

  test('an ordinary category can opt out of statistics', () {
    final quiet = _food.copyWith(countsInStatistics: false);
    final s = LedgerTotals.statistics([_e('1', 9, TransactionType.expense, category: quiet)]);
    expect(s.totalExpenses, 0);
  });

  test('Correction.fromSignedDifference builds a signed correction transaction', () {
    final up = Transaction.correction(
        id: 'c1', difference: 7.5, currency: Currency.usd, date: DateTime(2026, 11, 4), accountId: 'a1');
    expect(up.type, TransactionType.income);
    expect(up.amount, 7.5);
    expect(up.category, _correction);
    final down = Transaction.correction(
        id: 'c2', difference: -3, currency: Currency.usd, date: DateTime(2026, 11, 4), accountId: 'a1');
    expect(down.type, TransactionType.expense);
    expect(down.amount, 3);
    expect(down.signedAmount, -3);
  });

  test('buildCSV: signed rows, Category column is the category export name',
      () async {
    final svc = TransactionService();
    await svc.saveTransaction(_e('1', 50, TransactionType.income, category: _topUp));
    await svc.saveTransaction(_e('2', 3, TransactionType.expense, category: _correction));
    await svc.saveTransaction(_e('3', 4, TransactionType.expense,
        category: _correction.copyWith(exportName: 'Cash diff')));
    final lines = (await svc.buildCSV())!.trim().split('\n');
    final byTitle = {for (final l in lines.skip(1)) l.split(',')[1]: l.split(',')};
    expect(byTitle['T1']![2], 'Top-up');
    expect(byTitle['T1']![3], '50.00');
    expect(byTitle['T2']![2], 'Correction');
    expect(byTitle['T2']![3], '-3.00');
    expect(byTitle['T3']![2], 'Correction'); // stored category list decides, not the instance
  });
}
