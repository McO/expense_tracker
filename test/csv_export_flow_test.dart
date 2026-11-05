import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> export(WidgetTester tester, Future<bool> Function(String, String) saver) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final acc = (await AccountService().getAccounts()).first;
    await TransactionService().saveTransaction(Transaction(
      id: 't1',
      title: 'Tea',
      amount: 2,
      currency: Currency.usd,
      category: Category.defaultCategories.first,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.expense,
      accountId: acc.id,
    ));
    await tester.pumpWidget(MaterialApp(home: HomeScreen(csvFileSaver: saver)));
    await tester.pumpAndSettle();
    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(acc.name)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('Export hands file name and buildCSV content to the save seam', (tester) async {
    String? name;
    String? content;
    await export(tester, (n, c) async {
      name = n;
      content = c;
      return true;
    });
    final acc = (await AccountService().getAccounts()).first;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    expect(name, csvExportFileName(DateTimeRange(start: start, end: now)));
    expect(name, matches(RegExp(r'^transactions_\d{8}_\d{8}\.csv$')));
    expect(
        content,
        await TransactionService()
            .buildCSV(startDate: start, endDate: now, accountId: acc.id));
    expect(find.textContaining('Saved'), findsOneWidget);
  });

  testWidgets('cancelled save dialog shows no message', (tester) async {
    var calls = 0;
    await export(tester, (n, c) async {
      calls++;
      return false;
    });
    expect(calls, 1);
    expect(find.textContaining('Saved'), findsNothing);
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('save failure is reported', (tester) async {
    await export(tester, (n, c) async => throw Exception('boom'));
    expect(find.textContaining('Export failed'), findsOneWidget);
  });
}
