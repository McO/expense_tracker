import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> start(WidgetTester tester, String? csv) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(csvFilePicker: () async => csv)));
    await tester.pumpAndSettle();
    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Main Account')));
    await tester.pumpAndSettle();
  }

  const csv = 'Date,Title,Category,Amount,Currency,Description\n'
      '2026-11-03,Tea,Food,-2.00,USD,\n'
      '2026-11-04,Pay,Mystery,5.00,USD,\n'
      'bad,row\n';

  testWidgets('preview shows counts; Import writes', (tester) async {
    await start(tester, csv);
    expect(find.text('2 to import'), findsOneWidget);
    expect(find.text('0 duplicates skipped'), findsOneWidget);
    expect(find.text('1 rows mapped to "Other"'), findsOneWidget);
    expect(find.text('1 invalid rows'), findsOneWidget);
    expect(find.textContaining('Line 4'), findsOneWidget);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect((await TransactionService().getTransactions()).length, 2);
  });

  testWidgets('Cancel writes nothing', (tester) async {
    await start(tester, csv);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await TransactionService().getTransactions(), isEmpty);
  });

  testWidgets('currency mismatch shows a message and writes nothing', (tester) async {
    await start(tester,
        'Date,Title,Category,Amount,Currency,Description\n2026-11-03,T,Food,-1.00,EUR,\n');
    expect(find.textContaining('Currency mismatch'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await TransactionService().getTransactions(), isEmpty);
  });

  testWidgets('cancelled file picker does nothing', (tester) async {
    await start(tester, null);
    expect(find.text('Import preview'), findsNothing);
    expect(await AccountService().getAccounts(), isNotEmpty);
  });
}
