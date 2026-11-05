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
      final c = Currency.fromJson(decoded);
      return Currency(
        code: c.code,
        symbol: c.symbol,
        name: c.name,
        isCustom: true,
        decimalPlaces: c.decimalPlaces,
      );
    }).toList();
  }

  Future<void> addCustomCurrency(String code, String symbol, String name,
      {int decimalPlaces = 2}) async {
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
      decimalPlaces: decimalPlaces,
    );
    
    customCurrencies.add(newCurrency);
    await _saveCustomCurrencies(customCurrencies);
  }

  /// Edits symbol, name and decimal places of a custom currency. The code is
  /// fixed (transactions reference it). Accounts holding the currency are
  /// updated so they stay consistent; transactions are not touched.
  Future<void> updateCustomCurrency(String code,
      {required String symbol,
      required String name,
      required int decimalPlaces}) async {
    final customCurrencies = await getCustomCurrencies();
    final index = customCurrencies.indexWhere((c) => c.code == code);
    if (index < 0) throw Exception('Currency not found');
    final updated = Currency(
      code: code,
      symbol: symbol,
      name: name,
      isCustom: true,
      decimalPlaces: decimalPlaces,
    );
    customCurrencies[index] = updated;
    await _saveCustomCurrencies(customCurrencies);

    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getStringList('accounts');
    if (accounts != null) {
      final rewritten = accounts.map((raw) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final cur = json['currency'];
        if (cur is Map<String, dynamic> && cur['code'] == code) {
          json['currency'] = updated.toJson();
        }
        return jsonEncode(json);
      }).toList();
      await prefs.setStringList('accounts', rewritten);
    }
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
