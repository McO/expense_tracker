import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class SettingsService {
  static const String _defaultCurrencyKey = 'default_currency';
  static const String _correctionExportCategoryKey = 'correction_export_category';
  static const String defaultCorrectionExportCategory = 'Correction';

  /// Category name written to the CSV Category column for corrections.
  Future<String> getCorrectionExportCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_correctionExportCategoryKey);
    return (value == null || value.trim().isEmpty)
        ? defaultCorrectionExportCategory
        : value;
  }

  Future<void> setCorrectionExportCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_correctionExportCategoryKey, name.trim());
  }
  
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