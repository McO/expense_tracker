class Currency {
  final String code;
  final String symbol;
  final String name;
  final bool isCustom;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.isCustom = false,
  });

  String get displayName => '$name ($code)';

  // Predefined currencies
  static const Currency usd = Currency(code: 'USD', symbol: '\$', name: 'US Dollar');
  static const Currency eur = Currency(code: 'EUR', symbol: '€', name: 'Euro');
  static const Currency gbp = Currency(code: 'GBP', symbol: '£', name: 'British Pound');
  static const Currency jpy = Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen');
  static const Currency cad = Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar');
  static const Currency aud = Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar');
  static const Currency chf = Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc');
  static const Currency cny = Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan');
  static const Currency inr = Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee');
  static const Currency krw = Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won');
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
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
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
