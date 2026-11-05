import 'dart:convert';
import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/screens/account_management_screen.dart';
import 'package:expense_tracker/screens/currency_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _big(WidgetTester t) {
  t.view.physicalSize = const Size(1200, 3000);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
}

Future<void> _accounts(int n) async {
  final list = [
    for (var i = 1; i <= n; i++)
      Account(id: 'w$i', name: 'Account$i', currency: Currency.eur, isDefault: i == 1)
  ];
  SharedPreferences.setMockInitialValues({
    'accounts': list.map((a) => jsonEncode(a.toJson())).toList(),
    'selected_account_id': 'w1',
  });
}

Future<void> _openMenu(WidgetTester t, {int index = 0}) async {
  await t.tap(find.byType(PopupMenuButton<String>).at(index));
  await t.pumpAndSettle();
}

void main() {
  group('account list', () {
    testWidgets('popup menu per item, no trailing icon buttons, extended FAB', (t) async {
      _big(t);
      await _accounts(2);
      await t.pumpWidget(const MaterialApp(home: AccountManagementScreen()));
      await t.pumpAndSettle();
      expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
      expect(find.byType(IconButton), findsNothing);
      expect(find.widgetWithText(FloatingActionButton, 'Add account'), findsOneWidget);
      expect(tester(t).isExtended, isTrue);
    });

    testWidgets('Edit opens the edit dialog', (t) async {
      _big(t);
      await _accounts(2);
      await t.pumpWidget(const MaterialApp(home: AccountManagementScreen()));
      await t.pumpAndSettle();
      await _openMenu(t);
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      expect(find.text('Edit Account'), findsOneWidget);
    });

    testWidgets('FAB opens the add dialog', (t) async {
      _big(t);
      await _accounts(2);
      await t.pumpWidget(const MaterialApp(home: AccountManagementScreen()));
      await t.pumpAndSettle();
      await t.tap(find.text('Add account'));
      await t.pumpAndSettle();
      expect(find.text('Add Account'), findsOneWidget);
    });

    testWidgets('last account cannot be deleted', (t) async {
      _big(t);
      await _accounts(1);
      await t.pumpWidget(const MaterialApp(home: AccountManagementScreen()));
      await t.pumpAndSettle();
      await _openMenu(t);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('cards use elevation 2', (t) async {
      _big(t);
      await _accounts(2);
      await t.pumpWidget(const MaterialApp(home: AccountManagementScreen()));
      await t.pumpAndSettle();
      expect(t.widget<Card>(find.byType(Card).first).elevation, 2);
    });
  });

  group('currency list', () {
    Future<void> pump(WidgetTester t) async {
      _big(t);
      SharedPreferences.setMockInitialValues({
        'custom_currencies': [
          jsonEncode(const Currency(code: 'XYZ', symbol: 'Z', name: 'Zed', isCustom: true).toJson())
        ],
      });
      await t.pumpWidget(const MaterialApp(home: CurrencyManagementScreen()));
      await t.pumpAndSettle();
    }

    testWidgets('popup menu per item, no icon buttons, no app-bar add, extended FAB', (t) async {
      await pump(t);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      expect(find.widgetWithText(FloatingActionButton, 'Add currency'), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.add)), findsNothing);
      expect(t.widget<Card>(find.byType(Card).first).elevation, 2);
    });

    testWidgets('FAB opens add dialog; Delete opens confirm and removes', (t) async {
      await pump(t);
      await t.tap(find.text('Add currency'));
      await t.pumpAndSettle();
      expect(find.text('Add Custom Currency'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      await _openMenu(t);
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete Currency'), findsOneWidget);
      await t.tap(find.widgetWithText(TextButton, 'Delete'));
      await t.pumpAndSettle();
      expect(find.text('Zed'), findsNothing);
    });
  });
}

FloatingActionButton tester(WidgetTester t) => t.widget<FloatingActionButton>(find.byType(FloatingActionButton));
