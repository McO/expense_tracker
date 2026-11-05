import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/screens/add_edit_category_screen.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/screens/edit_transaction_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/category_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:expense_tracker/services/ledger_totals.dart';
import 'package:expense_tracker/widgets/correct_balance_dialog.dart';
import 'package:expense_tracker/widgets/recent_transactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Transaction _e(String id, double amount, TransactionType t, String accountId,
        {Category? category}) =>
    Transaction(
      id: id,
      title: 'Row$id',
      amount: amount,
      currency: Currency.usd,
      category: category ?? Category.defaultCategories.first,
      date: DateTime(2026, 11, 4),
      type: t,
      accountId: accountId,
    );

void _bigSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('add form has no type selector; ± toggle defaults to - and flips',
      (tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: AddTransactionScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Type'), findsNothing);
    expect(find.text('Transaction details'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('sign-toggle')), matching: find.text('−')),
        findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Lunch');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '12');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add transaction'));
    await tester.pumpAndSettle();
    var stored = await TransactionService().getTransactions();
    expect(stored.single.type, TransactionType.expense);
    expect(stored.single.signedAmount, -12);

    await tester.pumpWidget(const MaterialApp(home: AddTransactionScreen(), key: Key('second')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-toggle')));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Salary');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '30');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add transaction'));
    await tester.pumpAndSettle();
    stored = await TransactionService().getTransactions();
    expect(stored.firstWhere((e) => e.title == 'Salary').signedAmount, 30);
  });

  testWidgets('edit form shows the sign and flipping it changes direction',
      (tester) async {
    _bigSurface(tester);
    final account = (await AccountService().getAccounts()).first;
    final income = _e('1', 20, TransactionType.income, account.id);
    await TransactionService().saveTransaction(income);
    await tester.pumpWidget(MaterialApp(home: EditTransactionScreen(transaction: income)));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('sign-toggle')), matching: find.text('+')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('sign-toggle')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final stored = await TransactionService().getTransactions();
    expect(stored.single.type, TransactionType.expense);
    expect(stored.single.signedAmount, -20);
  });

  Future<void> runCorrection(
      WidgetTester tester, Account account, double balance, String counted) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                correctBalance(context, account: account, balance: balance),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), counted);
    await tester.pump();
  }

  for (final c in [('150', 50.0, 'Difference: +\$50.00'), ('70', -30.0, 'Difference: -\$30.00')]) {
    testWidgets('correct balance counted ${c.$1} records a signed correction',
        (tester) async {
      final account = (await AccountService().getAccounts()).first;
      await TransactionService()
          .saveTransaction(_e('1', 100, TransactionType.income, account.id));
      await runCorrection(tester, account, 100, c.$1);
      expect(find.text(c.$3), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final stored = await TransactionService().getTransactions();
      expect(stored.length, 2);
      final corr = stored.where((e) => e.category.id == Category.correctionId).single;
      expect(corr.signedAmount, c.$2);
      expect(LedgerTotals.balance(stored), double.parse(c.$1));
    });
  }

  testWidgets('correct balance with equal cash records nothing', (tester) async {
    final account = (await AccountService().getAccounts()).first;
    await TransactionService()
        .saveTransaction(_e('1', 100, TransactionType.income, account.id));
    await runCorrection(tester, account, 100, '100');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await TransactionService().getTransactions()).length, 1);
    expect(find.textContaining('nothing to correct'), findsOneWidget);
  });

  testWidgets('category form reads and saves Count in statistics', (tester) async {
    _bigSurface(tester);
    final cat = (await CategoryService().getCategories()).firstWhere((c) => c.id == Category.topUpId);
    expect(cat.countsInStatistics, isFalse);
    await tester.pumpWidget(MaterialApp(home: AddEditCategoryScreen(category: cat)));
    await tester.pumpAndSettle();
    final sw = find.byKey(const Key('counts-in-statistics-switch'));
    await tester.ensureVisible(sw);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    await tester.tap(sw);
    await tester.pump();
    final save = find.textContaining(RegExp(r'^(Save|Update)', caseSensitive: false));
    await tester.tap(save.first);
    await tester.pumpAndSettle();
    final after = (await CategoryService().getCategories()).firstWhere((c) => c.id == Category.topUpId);
    expect(after.countsInStatistics, isTrue);
  });

  testWidgets('rows colour by sign and mark non-counting transactions', (tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecentTransactions(
            transactions: [
              _e('1', 5, TransactionType.income, 'a'),
              _e('2', 6, TransactionType.income, 'a', category: Category.topUp),
              _e('3', 8, TransactionType.expense, 'a'),
            ],
            onDelete: (_) async {},
            onViewAll: () {},
            onRefresh: () {},
          ),
        ),
      ),
    ));
    Color colorOf(String t) => tester.widget<Text>(find.text(t)).style!.color!;
    expect(colorOf('+\$5.00'), Colors.green);
    expect(colorOf('-\$8.00'), Colors.red);
    expect(find.byKey(const Key('not-counted-marker')), findsOneWidget);
  });
}
