import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class CurrencyService {
  static const String _customCurrenciesKey = 'custom_currencies';

  Future<List<Currency>> getCustomCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final customCurrenciesJson = prefs.getStringList(_customCurrenciesKey) ?? [];
    
    return customCurrenciesJson.map((json) {
      final Map<String, dynamic> decoded = jsonDecode(json);
      return Currency(
        code: decoded['code'] as String,
        symbol: decoded['symbol'] as String,
        name: decoded['name'] as String,
        isCustom: true,
      );
    }).toList();
  }

  Future<void> addCustomCurrency(String code, String symbol, String name) async {
    final customCurrencies = await getCustomCurrencies();
    
    // Check if currency code already exists in custom or predefined
    if (customCurrencies.any((c) => c.code == code.toUpperCase())) {
      throw Exception('Currency code already exists');
    }
    
    if (Currency.predefinedValues.any((c) => c.code == code.toUpperCase())) {
      throw Exception('Currency code already exists in predefined currencies');
    }
    
    final newCurrency = Currency(
      code: code.toUpperCase(),
      symbol: symbol,
      name: name,
      isCustom: true,
    );
    
    customCurrencies.add(newCurrency);
    await _saveCustomCurrencies(customCurrencies);
  }

  Future<void> removeCustomCurrency(String code) async {
    final customCurrencies = await getCustomCurrencies();
    customCurrencies.removeWhere((c) => c.code == code);
    await _saveCustomCurrencies(customCurrencies);
  }

  Future<void> _saveCustomCurrencies(List<Currency> currencies) async {
    final prefs = await SharedPreferences.getInstance();
    final currenciesJson = currencies.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_customCurrenciesKey, currenciesJson);
  }

  Future<List<Currency>> getAllAvailableCurrencies() async {
    final customCurrencies = await getCustomCurrencies();
    
    // Combine predefined and custom currencies
    final List<Currency> allCurrencies = [
      ...Currency.predefinedValues,
      ...customCurrencies,
    ];
    
    return allCurrencies;
  }
}
