import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('CSV export file is named transactions_<from>_<to>.csv', () {
    final r = DateTimeRange(start: DateTime(2026, 1, 5), end: DateTime(2026, 11, 20));
    expect(csvExportFileName(r), 'transactions_20260105_20261120.csv');
  });

  testWidgets('home and drawer use the Transaction language',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final acc = (await AccountService().getAccounts()).first;
    await TransactionService().saveTransaction(Transaction(
        id: 't1',
        title: 'Coffee',
        amount: 3,
        currency: Currency.usd,
        category: Category.defaultCategories.first,
        date: DateTime.now(),
        accountId: acc.id));
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('All Transactions'), findsOneWidget);
  });
}
