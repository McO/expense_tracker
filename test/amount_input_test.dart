import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/screens/edit_transaction_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:expense_tracker/widgets/correct_balance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Locale _de() => const Locale('de', 'DE');

Future<Account> _eurAccount() async {
  final a = Account(id: 'eur1', name: 'Euro', currency: Currency.eur, isDefault: true);
  await AccountService().saveAccount(a);
  await AccountService().setSelectedAccount(a.id);
  return a;
}

void _bigSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('add: de_DE 12,50 saves 12.5', (tester) async {
    _bigSurface(tester);
    await _eurAccount();
    await tester.pumpWidget(MaterialApp(home: AddTransactionScreen(localeLookup: _de)));
    await tester.pumpAndSettle();
    expect(find.text('0,00'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Lunch');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '12,50');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add transaction'));
    await tester.pumpAndSettle();
    final stored = await TransactionService().getTransactions();
    expect(stored.single.amount, 12.5);
  });

  testWidgets('add: leaving the field normalizes 12,5 to 12,50', (tester) async {
    _bigSurface(tester);
    await _eurAccount();
    await tester.pumpWidget(MaterialApp(home: AddTransactionScreen(localeLookup: _de)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '12,5');
    await tester.tap(find.widgetWithText(TextFormField, 'Title'));
    await tester.pumpAndSettle();
    expect(find.text('12,50'), findsOneWidget);
  });

  testWidgets('edit: opens 12.5 EUR as 12,50 under de_DE', (tester) async {
    _bigSurface(tester);
    final a = await _eurAccount();
    final t = Transaction(
      id: '1',
      title: 'X',
      amount: 12.5,
      currency: Currency.eur,
      category: Category.defaultCategories.first,
      date: DateTime(2026, 11, 4),
      type: TransactionType.expense,
      accountId: a.id,
    );
    await tester.pumpWidget(
        MaterialApp(home: EditTransactionScreen(transaction: t, localeLookup: _de)));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '12,50'), findsOneWidget);
  });

  testWidgets('correct balance accepts 95,30 under de_DE', (tester) async {
    final account = await _eurAccount();
    await TransactionService().saveTransaction(Transaction(
      id: '1',
      title: 'Start',
      amount: 100,
      currency: Currency.eur,
      category: Category.defaultCategories.first,
      date: DateTime(2026, 11, 4),
      type: TransactionType.income,
      accountId: account.id,
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => correctBalance(context,
                account: account, balance: 100, localeLookup: _de),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '95,30');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final stored = await TransactionService().getTransactions();
    final corr = stored.where((e) => e.category.id == Category.correctionId).single;
    expect(corr.signedAmount, -4.7);
  });
}
