class Currency {
  final String code;
  final String symbol;
  final String name;
  final bool isCustom;

  /// Number of minor-unit digits (0-3). Built-ins use ISO 4217; custom
  /// currencies are user-chosen (default 2).
  final int decimalPlaces;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.isCustom = false,
    this.decimalPlaces = 2,
  });

  /// Rounds [amount] half away from zero to this currency's decimals,
  /// tolerant of binary-float half-way errors (12.345 -> 12.35).
  double roundAmount(double amount) {
    var factor = 1.0;
    for (var i = 0; i < decimalPlaces; i++) {
      factor *= 10;
    }
    final scaled = amount * factor;
    final nudged = scaled + (scaled.abs() * 1e-12 + 1e-12) * (scaled < 0 ? -1 : 1);
    return nudged.roundToDouble() / factor;
  }

  String get displayName => '$name ($code)';

  // Predefined currencies
  static const Currency usd = Currency(code: 'USD', symbol: '\$', name: 'US Dollar');
  static const Currency eur = Currency(code: 'EUR', symbol: '€', name: 'Euro');
  static const Currency gbp = Currency(code: 'GBP', symbol: '£', name: 'British Pound');
  static const Currency jpy = Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', decimalPlaces: 0);
  static const Currency cad = Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar');
  static const Currency aud = Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar');
  static const Currency chf = Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc');
  static const Currency cny = Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan');
  static const Currency inr = Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee');
  static const Currency krw = Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won', decimalPlaces: 0);
  static const Currency brl = Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real');
  static const Currency rub = Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble');
  static const Currency mxn = Currency(code: 'MXN', symbol: '\$', name: 'Mexican Peso');
  static const Currency sgd = Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar');
  static const Currency nzd = Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar');

  static const List<Currency> predefinedValues = [
    usd, eur, gbp, jpy, cad, aud, chf, cny, inr, krw, brl, rub, mxn, sgd, nzd,
  ];

  static Currency fromCode(String code, {List<Currency> customCurrencies = const []}) {
    // Check predefined currencies first
    try {
      return predefinedValues.firstWhere((currency) => currency.code == code);
    } catch (e) {
      // Check custom currencies
      try {
        return customCurrencies.firstWhere((currency) => currency.code == code);
      } catch (e) {
        return Currency.usd;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'symbol': symbol,
      'name': name,
      'isCustom': isCustom,
      'decimalPlaces': decimalPlaces,
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String;
    for (final c in predefinedValues) {
      if (c.code == code) {
        return Currency(
          code: code,
          symbol: json['symbol'] as String,
          name: json['name'] as String,
          isCustom: json['isCustom'] as bool? ?? false,
          decimalPlaces: c.decimalPlaces,
        );
      }
    }
    final raw = json['decimalPlaces'];
    final places = raw is int && raw >= 0 && raw <= 3 ? raw : 2;
    return Currency(
      code: code,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
      decimalPlaces: places,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
