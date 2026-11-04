import 'dart:convert';

import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/ledger_totals.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _cats = Category.defaultCategories;
final _food = _cats.first;
final _other = _cats[1];

Expense _e(String id, double amount, TransactionType type,
        {Category? category, DateTime? date}) =>
    Expense(
      id: id,
      title: 'T$id',
      amount: amount,
      currency: Currency.usd,
      category: category ?? _food,
      date: date ?? DateTime(2026, 11, 4),
      type: type,
      accountId: 'a1',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every kind round-trips through toJson/fromJson', () {
    for (final t in TransactionType.values) {
      final json = jsonDecode(jsonEncode(_e('1', 5, t).toJson()));
      final back = Expense.fromJson(json, _cats);
      expect(back.type, t);
      expect(back.amount, 5);
    }
  });

  test('legacy records keep their kind', () {
    Map<String, dynamic> base() => _e('1', 5, TransactionType.expense).toJson();
    expect(Expense.fromJson(base()..['type'] = 'income', _cats).type,
        TransactionType.income);
    expect(Expense.fromJson(base()..['type'] = 'expense', _cats).type,
        TransactionType.expense);
    expect(Expense.fromJson(base()..remove('type'), _cats).type,
        TransactionType.expense);
  });

  final all = [
    _e('1', 100, TransactionType.income),
    _e('2', 50, TransactionType.topUp),
    _e('3', 7, TransactionType.correctionIn),
    _e('4', 30, TransactionType.expense, category: _other),
    _e('5', 3, TransactionType.correctionOut),
  ];

  test('wallet balance counts every kind', () {
    expect(LedgerTotals.balance(all), 100 + 50 + 7 - 30 - 3);
  });

  test('statistics exclude top-ups and corrections', () {
    final s = LedgerTotals.statistics(all);
    expect(s.totalIncome, 100);
    expect(s.totalExpenses, 30);
    expect(s.categoryIncomeTotal, {_food: 100});
    expect(s.categoryExpenseTotal, {_other: 30});
    expect(s.categoryTotals, {_food: 100, _other: 30});
    expect(s.currencyTotals, {Currency.usd: 130});
    expect(s.savingsRate, closeTo(70, 1e-9));
  });

  test('buildCSV: top-up unsigned with category export name, correction signed',
      () async {
    final svc = ExpenseService();
    await svc.saveExpense(_e('1', 50, TransactionType.topUp));
    await svc.saveExpense(_e('2', 7.5, TransactionType.correctionIn));
    await svc.saveExpense(_e('3', 3, TransactionType.correctionOut));
    final lines = (await svc.buildCSV())!.trim().split('\n');
    final byTitle = {for (final l in lines.skip(1)) l.split(',')[1]: l.split(',')};
    final cat = _food.effectiveExportName;
    expect(byTitle['T1']![2], cat);
    expect(byTitle['T1']![3], '50.00');
    expect(byTitle['T2']![2], 'Correction');
    expect(byTitle['T2']![3], '7.50');
    expect(byTitle['T3']![2], 'Correction');
    expect(byTitle['T3']![3], '-3.00');
  });

  test('buildCSV uses the configured correction category', () async {
    await SettingsService().setCorrectionExportCategory('Cash diff');
    final svc = ExpenseService();
    await svc.saveExpense(_e('1', 3, TransactionType.correctionOut));
    expect((await svc.buildCSV())!, contains(',Cash diff,-3.00,'));
  });

  test('correction export category persists with default', () async {
    final s = SettingsService();
    expect(await s.getCorrectionExportCategory(), 'Correction');
    await s.setCorrectionExportCategory('Adjust');
    expect(await s.getCorrectionExportCategory(), 'Adjust');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('correction_export_category'), 'Adjust');
  });
}
