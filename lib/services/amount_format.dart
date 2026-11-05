import 'dart:ui';

import 'package:intl/intl.dart';

import '../models/currency.dart';

/// Reads the phone's locale; a seam so tests can force de_DE or en_US.
typedef LocaleLookup = Locale Function();

/// Default lookup: the device locale (the app sets no supportedLocales, so
/// `Localizations.localeOf` would always be en_US).
Locale deviceLocale() => PlatformDispatcher.instance.locale;

/// The decimal separator of [locale] (`,` for de_DE, `.` for en_US).
String decimalSeparator(Locale locale) {
  final candidates = [
    locale.toLanguageTag().replaceAll('-', '_'),
    locale.languageCode,
  ];
  for (final name in candidates) {
    try {
      return NumberFormat.decimalPattern(name).symbols.DECIMAL_SEP;
    } catch (_) {}
  }
  return '.';
}

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
/// currency's decimals, no symbol, no grouping (e.g. `12,50`, `1500`).
String formatAmount(double amount, Currency currency, Locale locale) {
  final fixed = currency.roundAmount(amount).toStringAsFixed(currency.decimalPlaces);
  return fixed.replaceFirst('.', decimalSeparator(locale));
}

/// Like [formatAmount] but prefixed with the currency symbol (`€12,50`).
String formatAmountWithSymbol(double amount, Currency currency, Locale locale) {
  final body = formatAmount(amount.abs(), currency, locale);
  return '${amount < 0 ? '-' : ''}${currency.symbol}$body';
}

/// Placeholder for an empty field: `0,00` (de_DE EUR), `0` (JPY).
String amountHint(Currency currency, Locale locale) =>
    formatAmount(0, currency, locale);
