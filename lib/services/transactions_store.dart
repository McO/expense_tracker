import 'package:shared_preferences/shared_preferences.dart';

/// Single owner of the persisted transactions list: the key name and the
/// one-time `expenses` -> `transactions` key migration (ADR-0004 amendment).
class TransactionsStore {
  static const String key = 'transactions';
  static const String legacyKey = 'expenses';
  static const String migratedFlag = 'transactions_key_migrated_v1';

  /// Runs the guarded, idempotent copy-then-delete migration once.
  /// Entries are copied verbatim, never transformed.
  static Future<void> migrateIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(migratedFlag) == true) return;
    final legacy = prefs.getStringList(legacyKey);
    if (legacy != null) {
      if (!prefs.containsKey(key)) {
        await prefs.setStringList(key, List<String>.from(legacy));
      }
      // transactions wins when both exist; legacy removed only after the copy.
      await prefs.remove(legacyKey);
    }
    await prefs.setBool(migratedFlag, true);
  }

  static Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    await migrateIfNeeded(prefs);
    return prefs.getStringList(key) ?? [];
  }

  static Future<void> write(List<String> json) async {
    final prefs = await SharedPreferences.getInstance();
    await migrateIfNeeded(prefs);
    await prefs.setStringList(key, json);
  }
}
