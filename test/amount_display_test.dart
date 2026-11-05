
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/widgets/balance_summary_card.dart';
import 'package:expense_tracker/widgets/recent_transactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Locale _de() => const Locale('de', 'DE');

Transaction _t(double a, Currency c, TransactionType t) => Transaction(
      id: '$a',
      title: 'Lunch',
      amount: a,
      currency: c,
      category: Category.defaultCategories.first,
      date: DateTime(2026, 11, 4),
      type: t,
      accountId: 'a1',
    );

void main() {
  testWidgets('balance summary card groups and uses the German separators',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BalanceSummaryCard(
          balance: 1234.5,
          totalIncome: 2000,
          totalExpenses: 765.5,
          currencyTotals: const {},
          defaultCurrency: Currency.eur,
          localeLookup: _de,
        ),
      ),
    ));
    expect(find.text('+€1.234,50'), findsOneWidget);
    expect(find.text('+€2.000,00'), findsOneWidget);
    expect(find.text('-€765,50'), findsOneWidget);
  });

  testWidgets('a JPY account shows whole numbers', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            BalanceSummaryCard(
              balance: 1500,
              totalIncome: 1500,
              totalExpenses: 0,
              currencyTotals: const {},
              defaultCurrency: Currency.jpy,
              localeLookup: _de,
            ),
            RecentTransactions(
              transactions: [_t(1500, Currency.jpy, TransactionType.expense)],
              onDelete: (_) {},
              onViewAll: () {},
              onRefresh: () {},
              localeLookup: _de,
            ),
          ]),
        ),
      ),
    ));
    expect(find.text('+¥1.500'), findsWidgets);
    expect(find.text('-¥1.500'), findsOneWidget);
    expect(find.textContaining(',00'), findsNothing);
  });

  test('Transaction formatted amounts follow the locale', () {
    final t = _t(1234.5, Currency.eur, TransactionType.expense);
    expect(t.formattedAmount(_de()), '€1.234,50');
    expect(t.formattedAmountWithSign(const Locale('en', 'US')), '-€1,234.50');
  });
}
