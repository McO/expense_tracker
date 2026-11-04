import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class SettingsService {
  static const String _defaultCurrencyKey = 'default_currency';

  Future<Currency> getDefaultCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString(_defaultCurrencyKey) ?? 'USD';
    return Currency.fromCode(currencyCode);
  }
  
  Future<void> setDefaultCurrency(Currency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCurrencyKey, currency.code);
  }
} 