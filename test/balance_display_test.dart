import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/widgets/total_expense_card.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/ledger_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _e(double a, TransactionType t, [Category? c]) => Expense(
      id: '$a$t',
      title: 't',
      amount: a,
      currency: Currency.usd,
      category: c ?? Category.defaultCategories.first,
      date: DateTime(2026, 11, 4),
      type: t,
      accountId: 'a1',
    );

void main() {
  testWidgets('Net Balance shows top-ups and corrections, rows stay statistics',
      (tester) async {
    final all = [
      _e(100, TransactionType.income),
      _e(30, TransactionType.expense),
      _e(50, TransactionType.income, Category.topUp),
      _e(7, TransactionType.income, Category.correction),
      _e(3, TransactionType.expense, Category.correction),
    ];
    final stats = LedgerTotals.statistics(all);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TotalExpenseCard(
          balance: LedgerTotals.balance(all),
          totalIncome: stats.totalIncome,
          totalExpenses: stats.totalExpenses,
          currencyTotals: stats.currencyTotals,
          defaultCurrency: Currency.usd,
        ),
      ),
    ));
    expect(find.text('+\$124.00'), findsNWidgets(1)); // 100+50+7-30-3
    expect(find.text('+\$100.00'), findsOneWidget);
    expect(find.text('-\$30.00'), findsOneWidget);
  });
}
