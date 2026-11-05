import 'dart:convert';
import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/screens/account_management_screen.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/edit_expense_screen.dart';
import 'package:expense_tracker/screens/expenses_list_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
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

Future<void> _seed(List<Map<String, dynamic>> mvs) async {
  final eur = Account(id: 'w1', name: 'Euro', currency: Currency.eur, isDefault: true);
  final gbp = Account(id: 'w2', name: 'Pound', currency: Currency.gbp);
  SharedPreferences.setMockInitialValues({
    'accounts': [eur, gbp].map((a) => jsonEncode(a.toJson())).toList(),
    'selected_account_id': 'w1',
    'expenses': mvs.map(jsonEncode).toList(),
  });
}

void _big(WidgetTester t) {
  t.view.physicalSize = const Size(1200, 3000);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
}

void main() {
  test('stored currency differing from wallet is shown/exported as wallet currency', () async {
    await _seed([_mv('1', 'w1', currency: 'USD')]);
    final svc = ExpenseService();
    expect((await svc.getExpenses()).single.currency.code, 'EUR');
    final csv = await svc.buildCSV(accountId: 'w1');
    expect(csv, contains(',5.00,EUR,').or(contains(',-5.00,EUR,')));
  });

  test('movement without currency loads with wallet currency', () async {
    await _seed([_mv('1', 'w2')]);
    expect((await ExpenseService().getExpenses()).single.currency.code, 'GBP');
  });

  test('deleting a wallet deletes exactly its movements', () async {
    await _seed([_mv('1', 'w1'), _mv('2', 'w2'), _mv('3', 'w2')]);
    await AccountService().deleteAccount('w2');
    final left = await ExpenseService().getExpenses();
    expect(left.map((e) => e.id), ['1']);
  });

  testWidgets('list row shows wallet currency symbol', (tester) async {
    _big(tester);
    await _seed([_mv('1', 'w1', currency: 'USD')]);
    await tester.pumpWidget(const MaterialApp(home: ExpensesListScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('€5.00'), findsWidgets);
    expect(find.textContaining('\$5.00'), findsNothing);
  });

  testWidgets('add form saves movement with wallet currency, no picker', (tester) async {
    _big(tester);
    await _seed([]);
    await tester.pumpWidget(const MaterialApp(home: AddExpenseScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<Currency>), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'X');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '3');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add movement'));
    await tester.pumpAndSettle();
    final raw = (await SharedPreferences.getInstance()).getStringList('expenses')!;
    expect(jsonDecode(raw.single)['currency'], 'EUR');
  });

  testWidgets('edit form stores wallet currency for a USD movement in a EUR wallet', (tester) async {
    _big(tester);
    await _seed([_mv('1', 'w1', currency: 'USD')]);
    final mv = (await ExpenseService().getExpenses()).single;
    await tester.pumpWidget(MaterialApp(home: EditExpenseScreen(expense: mv)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update movement'));
    await tester.pumpAndSettle();
    final raw = (await SharedPreferences.getInstance()).getStringList('expenses')!;
    expect(jsonDecode(raw.single)['currency'], 'EUR');
  });

  testWidgets('wallet delete confirm names N; cancel changes nothing; confirm deletes', (tester) async {
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
    expect(find.textContaining('This also deletes 2 movements'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await ExpenseService().getExpenses()).length, 3);

    await pickDelete();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect((await ExpenseService().getExpenses()).map((e) => e.id), ['1']);
    expect((await AccountService().getAccounts()).length, 1);
  });
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
