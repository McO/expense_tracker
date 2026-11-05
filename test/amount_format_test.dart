import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/services/amount_format.dart';

const de = Locale('de', 'DE');
const us = Locale('en', 'US');
const dinar = Currency(code: 'KWD', symbol: 'KD', name: 'Dinar', isCustom: true, decimalPlaces: 3);

void main() {
  group('parseAmount de_DE EUR', () {
    double? p(String s) => parseAmount(s, Currency.eur, de);
    test('accepts both separators, symbols, codes, spaces', () {
      expect(p('12,50'), 12.5);
      expect(p('12.50'), 12.5);
      expect(p(' €12,5 '), 12.5);
      expect(p('EUR 7'), 7);
    });
    test('rejects thousands, too many decimals, letters', () {
      expect(p('1.234,56'), isNull);
      expect(p('12,345'), isNull);
      expect(p('abc'), isNull);
      expect(p(''), isNull);
    });
    test('negative only when allowed', () {
      expect(p('-5,5'), isNull);
      expect(parseAmount('-5,5', Currency.eur, de, allowNegative: true), -5.5);
    });
  });
  test('en_US EUR accepts . and ,', () {
    expect(parseAmount('12.50', Currency.eur, us), 12.5);
    expect(parseAmount('12,50', Currency.eur, us), 12.5);
  });
  test('JPY has no decimals', () {
    expect(parseAmount('1500', Currency.jpy, de), 1500);
    expect(parseAmount('1500,5', Currency.jpy, de), isNull);
    expect(parseAmount('1500.5', Currency.jpy, de), isNull);
  });
  test('3-decimal currency', () {
    expect(parseAmount('1,250', dinar, de), 1.25);
  });
  test('formatAmount', () {
    expect(formatAmount(12.5, Currency.eur, de), '12,50');
    expect(formatAmount(12.5, Currency.eur, us), '12.50');
    expect(formatAmount(1500, Currency.jpy, de), '1500');
    expect(formatAmount(1234.5, Currency.eur, us), '1234.50');
    expect(formatAmountWithSymbol(12.5, Currency.eur, de), '€12,50');
  });
  test('amountHint', () {
    expect(amountHint(Currency.eur, de), '0,00');
    expect(amountHint(Currency.jpy, de), '0');
  });
  group('display formatting', () {
    test('grouping and symbol', () {
      expect(formatAmountWithSymbol(1234.5, Currency.eur, de), '€1.234,50');
      expect(formatAmountWithSymbol(1234.5, Currency.eur, us), '€1,234.50');
      expect(formatAmountWithSymbol(1500, Currency.jpy, de), '¥1.500');
      expect(formatAmountWithSymbol(1500, Currency.jpy, us), '¥1,500');
      expect(formatAmountWithSymbol(1234567.891, dinar, de), 'KD1.234.567,891');
    });
    test('negative keeps the minus before the symbol', () {
      expect(formatAmountWithSymbol(-2, Currency.eur, de), '-€2,00');
      expect(formatAmountWithSymbol(-1234.5, Currency.eur, us), '-€1,234.50');
    });
    test('no minus on a value that rounds to zero', () {
      expect(formatAmountWithSymbol(-0.004, Currency.eur, de), '€0,00');
      expect(formatAmountWithSymbol(-0.4, Currency.jpy, us), '¥0');
    });
    test('input formatting stays ungrouped', () {
      expect(formatAmount(1234.5, Currency.eur, de), '1234,50');
    });
    test('percent follows the decimal separator', () {
      expect(formatPercent(12.5, de), '12,5%');
      expect(formatPercent(12.5, us), '12.5%');
    });
  });
}
