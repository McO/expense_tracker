import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/services/app_version_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openDrawer(WidgetTester tester, AppVersionLookup lookup) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(appVersionLookup: lookup)));
    await tester.pumpAndSettle();
    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('drawer shows the version from the seam', (tester) async {
    await openDrawer(tester, () async => const AppVersion('1.2.3', '7'));
    expect(find.text('Version 1.2.3 (7)'), findsOneWidget);
  });

  testWidgets('drawer shows no version line when lookup returns nothing', (tester) async {
    await openDrawer(tester, () async => null);
    expect(find.text('All Transactions'), findsOneWidget);
    expect(find.textContaining('Version'), findsNothing);
  });

  testWidgets('drawer shows no version line when lookup throws', (tester) async {
    await openDrawer(tester, () async => throw Exception('boom'));
    expect(find.text('All Transactions'), findsOneWidget);
    expect(find.textContaining('Version'), findsNothing);
  });
}
