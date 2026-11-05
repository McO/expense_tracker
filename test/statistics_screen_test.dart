import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/statistics_screen.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:expense_tracker/services/theme_service.dart';
import 'package:expense_tracker/widgets/correct_balance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final today = DateTime(2026, 11, 10, 12);

Transaction _e(String id, double amt, DateTime d, String acc,
        {TransactionType type = TransactionType.expense, Category? cat}) =>
    Transaction(
        id: id,
        title: id,
        amount: amt,
        currency: Currency.usd,
        category: cat ?? Category.defaultCategories.first,
        date: d,
        type: type,
        accountId: acc);

void _big(WidgetTester t) {
  t.view.physicalSize = const Size(1200, 3000);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> seed(String acc) async {
    final s = TransactionService();
    await s.saveTransaction(_e('top', 1000, DateTime(2026, 11, 1), acc,
        type: TransactionType.income, cat: Category.topUp));
    await s.saveTransaction(_e('early', 100, DateTime(2026, 11, 1), acc));
    await s.saveTransaction(_e('recent', 50, DateTime(2026, 11, 9), acc,
        cat: Category.defaultCategories[1]));
    await s.saveTransaction(_e('elsewhere', 777, DateTime(2026, 11, 9), 'other-account'));
  }

  testWidgets('drawer Statistics entry opens the screen for the selected account',
      (tester) async {
    _big(tester);
    final acc = (await AccountService().getAccounts()).first;
    await seed(acc.id);
    await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
            onThemeModeChanged: (_) {}, currentThemeMode: AppThemeMode.system)));
    await tester.pumpAndSettle();
    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.text('Statistics - ${acc.name}'), findsOneWidget);
    expect(find.byKey(const Key('stats-balance')), findsOneWidget);
  });

  testWidgets('period control defaults to this month and switches to last 7 days',
      (tester) async {
    _big(tester);
    final acc = (await AccountService().getAccounts()).first;
    await seed(acc.id);
    await tester.pumpWidget(
        MaterialApp(home: StatisticsScreen(account: acc, today: today)));
    await tester.pumpAndSettle();
    final sym = acc.currency.symbol;
    // this month: 150 over 10 days
    expect(find.text('$sym${15.0.toStringAsFixed(2)} / day'), findsOneWidget);
    expect(find.text('Spent $sym${150.0.toStringAsFixed(2)} over 10 days'),
        findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('period-last7Days')));
    await tester.pumpAndSettle();
    // last 7 days: only the 50 on the 9th, over 7 days
    expect(find.text('$sym${(50 / 7).toStringAsFixed(2)} / day'), findsOneWidget);
    expect(find.text('Spent $sym${50.0.toStringAsFixed(2)} over 7 days'),
        findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(1));
    expect(find.byKey(const Key('stats-bars')), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('bar-$i')), findsOneWidget);
    }
  });

  testWidgets('balance card shows the account balance; Correct balance opens dialog',
      (tester) async {
    _big(tester);
    final acc = (await AccountService().getAccounts()).first;
    await seed(acc.id);
    await tester.pumpWidget(
        MaterialApp(home: StatisticsScreen(account: acc, today: today)));
    await tester.pumpAndSettle();
    final sym = acc.currency.symbol;
    expect(tester.widget<Text>(find.byKey(const Key('stats-balance'))).data,
        '$sym${850.0.toStringAsFixed(2)}');
    // lasts: 850 / 15 = 56.67 -> 56
    expect(find.textContaining('lasts ~56 days'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stats-correct-balance')));
    await tester.pumpAndSettle();
    expect(find.byType(CorrectBalanceDialog), findsOneWidget);
  });

  testWidgets('empty state when there is no spending; caption hidden', (tester) async {
    _big(tester);
    final acc = (await AccountService().getAccounts()).first;
    await tester.pumpWidget(
        MaterialApp(home: StatisticsScreen(account: acc, today: today)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stats-mix-empty')), findsOneWidget);
    expect(find.byKey(const Key('stats-lasts')), findsNothing);
  });
}
