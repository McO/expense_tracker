import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';

import '../models/currency.dart';

/// Reads the phone's locale; a seam so tests can force de_DE or en_US.
typedef LocaleLookup = Locale Function();

/// Default lookup: the device locale (the app sets no supportedLocales, so
/// `Localizations.localeOf` would always be en_US).
Locale deviceLocale() => PlatformDispatcher.instance.locale;

NumberSymbols? _symbols(Locale locale) {
  final candidates = [
    locale.toLanguageTag().replaceAll('-', '_'),
    locale.languageCode,
  ];
  for (final name in candidates) {
    try {
      return NumberFormat.decimalPattern(name).symbols;
    } catch (_) {}
  }
  return null;
}

/// The decimal separator of [locale] (`,` for de_DE, `.` for en_US).
String decimalSeparator(Locale locale) => _symbols(locale)?.DECIMAL_SEP ?? '.';

/// The grouping separator of [locale] (`.` for de_DE, `,` for en_US).
String groupSeparator(Locale locale) => _symbols(locale)?.GROUP_SEP ?? ',';

/// Parses user-typed [text] into an amount, or null when invalid.
///
/// Tolerant: surrounding spaces and a currency symbol or code are ignored,
/// and either `.` or `,` is accepted as the decimal point. Thousands
/// separators are not supported. At most [currency].decimalPlaces decimals.
/// [locale] is accepted for API symmetry with [formatAmount]; both
/// separators are accepted regardless of it.
double? parseAmount(
  String text,
  Currency currency,
  Locale locale, {
  bool allowNegative = false,
}) {
  var s = text;
  final tokens = <String>{
    currency.symbol,
    currency.code,
    for (final c in Currency.predefinedValues) ...[c.symbol, c.code],
  }.where((t) => t.isNotEmpty).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final t in tokens) {
    s = s.replaceAll(RegExp(RegExp.escape(t), caseSensitive: false), '');
  }
  s = s.replaceAll(RegExp(r'[\s  ]'), '');
  final match = RegExp(r'^(-?)(\d*)(?:[.,](\d*))?$').firstMatch(s);
  if (match == null) return null;
  final negative = match.group(1) == '-';
  final whole = match.group(2)!;
  final frac = match.group(3);
  if (whole.isEmpty && (frac == null || frac.isEmpty)) return null;
  if (negative && !allowNegative) return null;
  if (frac != null && currency.decimalPlaces == 0) return null;
  if (frac != null && frac.length > currency.decimalPlaces) return null;
  final value = double.parse('${whole.isEmpty ? '0' : whole}.${frac == null || frac.isEmpty ? '0' : frac}');
  return currency.roundAmount(negative ? -value : value);
}

/// Formats [amount] in [locale]'s decimal separator with exactly the
/// currency's decimals, no symbol (e.g. `12,50`, `1500`). Without [grouping]
/// (input fields) there are no thousands separators; with it (display) the
/// locale's grouping is applied (`1.234,50`).
String formatAmount(double amount, Currency currency, Locale locale,
    {bool grouping = false}) {
  final fixed = currency.roundAmount(amount).toStringAsFixed(currency.decimalPlaces);
  final negative = fixed.startsWith('-');
  final unsigned = negative ? fixed.substring(1) : fixed;
  final dot = unsigned.indexOf('.');
  var whole = dot < 0 ? unsigned : unsigned.substring(0, dot);
  final frac = dot < 0 ? '' : unsigned.substring(dot + 1);
  if (grouping) {
    final sep = groupSeparator(locale);
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(sep);
      buf.write(whole[i]);
    }
    whole = buf.toString();
  }
  return '${negative ? '-' : ''}$whole${frac.isEmpty ? '' : decimalSeparator(locale) + frac}';
}

/// Display form: the currency symbol before the locale-grouped number
/// (`€1.234,50`, `-€2,00`). A value that rounds to zero shows no minus.
String formatAmountWithSymbol(double amount, Currency currency, Locale locale) {
  final rounded = currency.roundAmount(amount);
  final body = formatAmount(rounded.abs(), currency, locale, grouping: true);
  return '${rounded < 0 ? '-' : ''}${currency.symbol}$body';
}

/// A percentage with one decimal in [locale]'s decimal separator (`12,5%`).
String formatPercent(double value, Locale locale) =>
    '${value.toStringAsFixed(1).replaceFirst('.', decimalSeparator(locale))}%';

/// Placeholder for an empty field: `0,00` (de_DE EUR), `0` (JPY).
String amountHint(Currency currency, Locale locale) =>
    formatAmount(0, currency, locale);
