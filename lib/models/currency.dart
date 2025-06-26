enum Currency {
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro'),
  gbp('GBP', '£', 'British Pound'),
  jpy('JPY', '¥', 'Japanese Yen'),
  cad('CAD', 'C\$', 'Canadian Dollar'),
  aud('AUD', 'A\$', 'Australian Dollar'),
  chf('CHF', 'CHF', 'Swiss Franc'),
  cny('CNY', '¥', 'Chinese Yuan'),
  inr('INR', '₹', 'Indian Rupee'),
  krw('KRW', '₩', 'South Korean Won'),
  brl('BRL', 'R\$', 'Brazilian Real'),
  rub('RUB', '₽', 'Russian Ruble'),
  mxn('MXN', '\$', 'Mexican Peso'),
  sgd('SGD', 'S\$', 'Singapore Dollar'),
  nzd('NZD', 'NZ\$', 'New Zealand Dollar');

  const Currency(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;

  String get displayName => '$name ($code)';
  
  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => Currency.usd,
    );
  }
} 