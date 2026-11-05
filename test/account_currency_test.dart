import 'dart:convert';
import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/screens/account_management_screen.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/screens/edit_transaction_screen.dart';
import 'package:expense_tracker/screens/transactions_list_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _mv(String id, String acc, {String? currency}) => {
      'id': id,
      'title': 'Mv$id',
      'amount': 5.0,
      if (currency != null) 'currency': currency,
      'categoryId': 'other',
      'date': DateTime(2026, 11, 4).toIso8601String(),
      'description': '',
      'type': 'expense',
      'accountId': acc,
    };

Future<void> _seed(List<Map<String, dynamic>> txs) async {
  final eur = Account(id: 'w1', name: 'Euro', currency: Currency.eur, isDefault: true);
  final gbp = Account(id: 'w2', name: 'Pound', currency: Currency.gbp);
  SharedPreferences.setMockInitialValues({
    'accounts': [eur, gbp].map((a) => jsonEncode(a.toJson())).toList(),
    'selected_account_id': 'w1',
    'transactions': txs.map(jsonEncode).toList(),
  });
}

void _big(WidgetTester t) {
  t.view.physicalSize = const Size(1200, 3000);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
}

void main() {
  test('stored currency differing from account is shown/exported as account currency', () async {
    await _seed([_mv('1', 'w1', currency: 'USD')]);
    final svc = TransactionService();
    expect((await svc.getTransactions()).single.currency.code, 'EUR');
    final csv = await svc.buildCSV(accountId: 'w1');
    expect(csv, contains(',5.00,EUR,').or(contains(',-5.00,EUR,')));
  });

  test('transaction without currency loads with account currency', () async {
    await _seed([_mv('1', 'w2')]);
    expect((await TransactionService().getTransactions()).single.currency.code, 'GBP');
  });

  test('deleting an account deletes exactly its transactions', () async {
    await _seed([_mv('1', 'w1'), _mv('2', 'w2'), _mv('3', 'w2')]);
    await AccountService().deleteAccount('w2');
    final left = await TransactionService().getTransactions();
    expect(left.map((e) => e.id), ['1']);
  });

  testWidgets('list row shows account currency symbol', (tester) async {
    _big(tester);
    await _seed([_mv('1', 'w1', currency: 'USD')]);
    await tester.pumpWidget(const MaterialApp(home: TransactionsListScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('€5.00'), findsWidgets);
    expect(find.textContaining('\$5.00'), findsNothing);
  });

  testWidgets('add form saves transaction with account currency, no picker', (tester) async {
    _big(tester);
    await _seed([]);
    await tester.pumpWidget(const MaterialApp(home: AddTransactionScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<Currency>), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'X');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '3');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add transaction'));
    await tester.pumpAndSettle();
    final raw = (await SharedPreferences.getInstance()).getStringList('transactions')!;
    expect(jsonDecode(raw.single)['currency'], 'EUR');
  });

  testWidgets('edit form stores account currency for a USD transaction in a EUR account', (tester) async {
    _big(tester);
    await _seed([_mv('1', 'w1', currency: 'USD')]);
    final mv = (await TransactionService().getTransactions()).single;
    await tester.pumpWidget(MaterialApp(home: EditTransactionScreen(transaction: mv)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update transaction'));
    await tester.pumpAndSettle();
    final raw = (await SharedPreferences.getInstance()).getStringList('transactions')!;
    expect(jsonDecode(raw.single)['currency'], 'EUR');
  });

  testWidgets('account delete confirm names N; cancel changes nothing; confirm deletes', (tester) async {
    _big(tester);
    await _seed([_mv('1', 'w1'), _mv('2', 'w2'), _mv('3', 'w2')]);
    await tester.pumpWidget(const MaterialApp(home: AccountManagementScreen()));
    await tester.pumpAndSettle();
    Future<void> pickDelete() async {
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    }
    await pickDelete();
    expect(find.textContaining('This also deletes 2 transactions'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await TransactionService().getTransactions()).length, 3);

    await pickDelete();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect((await TransactionService().getTransactions()).map((e) => e.id), ['1']);
    expect((await AccountService().getAccounts()).length, 1);
  });
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
