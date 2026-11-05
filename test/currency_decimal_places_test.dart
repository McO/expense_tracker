import 'dart:convert';

import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/screens/currency_management_screen.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('decimal places model', () {
    test('built-ins follow ISO 4217', () {
      expect(Currency.jpy.decimalPlaces, 0);
      expect(Currency.krw.decimalPlaces, 0);
      expect(Currency.eur.decimalPlaces, 2);
      for (final c in Currency.predefinedValues) {
        final expected = (c.code == 'JPY' || c.code == 'KRW') ? 0 : 2;
        expect(c.decimalPlaces, expected, reason: c.code);
      }
    });

    test('custom JSON without decimalPlaces loads with 2; 0 round-trips', () {
      final old = Currency.fromJson(
          {'code': 'XYZ', 'symbol': 'Z', 'name': 'Zed', 'isCustom': true});
      expect(old.decimalPlaces, 2);
      final zero = Currency.fromJson(const Currency(
              code: 'LEK', symbol: 'L', name: 'Lek', isCustom: true, decimalPlaces: 0)
          .toJson());
      expect(zero.decimalPlaces, 0);
    });

    test('built-in resolved by code uses ISO value', () {
      expect(Currency.fromCode('JPY').decimalPlaces, 0);
      final fromStored = Currency.fromJson(
          {'code': 'JPY', 'symbol': '¥', 'name': 'Yen', 'decimalPlaces': 2});
      expect(fromStored.decimalPlaces, 0);
    });

    test('rounding', () {
      expect(Currency.jpy.roundAmount(1500.4), 1500);
      expect(Currency.eur.roundAmount(12.345), 12.35);
      expect(
          const Currency(code: 'KWD', symbol: 'K', name: 'K', decimalPlaces: 3)
              .roundAmount(1.2346),
          1.235);
      expect(Currency.eur.roundAmount(-12.345), -12.35);
      expect(Currency.eur.roundAmount(1.005), 1.01);
    });
  });

  group('currency screen', () {
    Future<void> pump(WidgetTester t, {List<String> currencies = const []}) async {
      t.view.physicalSize = const Size(1200, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({'custom_currencies': currencies});
      await t.pumpWidget(const MaterialApp(home: CurrencyManagementScreen()));
      await t.pumpAndSettle();
    }

    testWidgets('add with 0 decimal places stores and lists it', (t) async {
      await pump(t);
      await t.tap(find.text('Add currency'));
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, 'Currency Code'), 'XQZ');
      await t.enterText(find.widgetWithText(TextField, 'Symbol'), 'Q');
      await t.enterText(find.widgetWithText(TextField, 'Currency Name'), 'Quetz');
      await t.tap(find.byKey(const Key('decimal-places-0')));
      await t.pumpAndSettle();
      await t.tap(find.text('Add'));
      await t.pumpAndSettle();
      final stored = await CurrencyService().getCustomCurrencies();
      expect(stored.single.code, 'XQZ');
      expect(stored.single.decimalPlaces, 0);
      expect(find.text('Quetz'), findsOneWidget);
    });

    testWidgets('edit persists, keeps code, leaves transactions intact', (t) async {
      final cur = const Currency(code: 'XYZ', symbol: 'Z', name: 'Zed', isCustom: true);
      await pump(t, currencies: [jsonEncode(cur.toJson())]);
      final account = Account(
          id: 'a1', name: 'A', currency: cur, icon: 'x', color: 'FF000000', isDefault: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('accounts', [jsonEncode(account.toJson())]);
      await prefs.setStringList('transactions', ['{"marker":1}']);

      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      expect(find.text('Edit Custom Currency'), findsOneWidget);
      await t.enterText(find.widgetWithText(TextField, 'Currency Name'), 'Zedder');
      await t.enterText(find.widgetWithText(TextField, 'Symbol'), 'ZZ');
      await t.tap(find.byKey(const Key('decimal-places-3')));
      await t.pumpAndSettle();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();

      final stored = await CurrencyService().getCustomCurrencies();
      expect(stored.single.code, 'XYZ');
      expect(stored.single.name, 'Zedder');
      expect(stored.single.symbol, 'ZZ');
      expect(stored.single.decimalPlaces, 3);
      expect(find.text('Zedder'), findsOneWidget);
      expect((await AccountService().getAccounts()).single.currency.decimalPlaces, 3);
      expect(prefs.getStringList('transactions'), ['{"marker":1}']);
    });
  });
}
