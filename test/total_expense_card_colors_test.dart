import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/widgets/total_expense_card.dart';

Widget _host(Brightness b, {double income = 100, double expenses = 40}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), brightness: b),
      useMaterial3: true,
    ),
    home: Scaffold(
      body: TotalExpenseCard(
        totalIncome: income,
        totalExpenses: expenses,
        currencyTotals: const {},
        defaultCurrency: Currency.usd,
      ),
    ),
  );
}

Future<List<Color?>> _cardColors(WidgetTester t, Brightness b,
    {double income = 100, double expenses = 40}) async {
  await t.pumpWidget(_host(b, income: income, expenses: expenses));
  await t.pumpAndSettle();
  return t.widgetList<Card>(find.byType(Card)).map((c) => c.color).toList();
}

Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('card fills differ between light and dark themes',
      (t) async {
    final light = await _cardColors(t, Brightness.light);
    final dark = await _cardColors(t, Brightness.dark);
    expect(light.length, 3);
    for (var i = 0; i < 3; i++) {
      expect(light[i], isNotNull);
      expect(dark[i], isNot(equals(light[i])));
    }
  });

  testWidgets('no Colors shade constants are used', (t) async {
    for (final b in Brightness.values) {
      final fills = await _cardColors(t, b);
      final texts = [
        _textColor(t, 'Income'),
        _textColor(t, 'Expenses'),
        _textColor(t, 'Net Balance'),
      ];
      for (final c in [...fills, ...texts]) {
        for (final m in [Colors.green, Colors.red, Colors.blue, Colors.orange]) {
          for (final s in [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]) {
            expect(c, isNot(equals(m[s])));
          }
        }
      }
    }
  });

  testWidgets('income stays green, expense stays red', (t) async {
    for (final b in Brightness.values) {
      await t.pumpWidget(_host(b));
      await t.pumpAndSettle();
      final inc = _textColor(t, 'Income')!;
      final exp = _textColor(t, 'Expenses')!;
      expect(inc.g, greaterThan(inc.r));
      expect(inc.g, greaterThan(inc.b));
      expect(exp.r, greaterThan(exp.g));
      expect(exp.r, greaterThan(exp.b));
    }
  });

  testWidgets('positive and negative net balance are distinguished',
      (t) async {
    for (final b in Brightness.values) {
      final pos = await _cardColors(t, b, income: 100, expenses: 10);
      final posText = _textColor(t, 'Net Balance');
      final neg = await _cardColors(t, b, income: 10, expenses: 100);
      final negText = _textColor(t, 'Net Balance');
      expect(pos[0], isNot(equals(neg[0])));
      expect(posText, isNot(equals(negText)));
    }
  });
}
