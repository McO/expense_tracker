import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:expense_tracker/services/transactions_store.dart';

String tx(String id, {String type = 'expense'}) =>
    '{"id":"$id","title":"t$id","amount":5.0,"currency":"EUR","categoryId":"other","date":"2026-01-01T10:00:00.000","description":"","type":"$type","accountId":"a1"}';

void main() {
  test('migrates expenses to transactions verbatim, once', () async {
    final raw = [tx('1'), tx('2', type: 'income')];
    SharedPreferences.setMockInitialValues({'expenses': raw});
    final prefs = await SharedPreferences.getInstance();
    final first = await TransactionService().getTransactions();
    expect(first.length, 2);
    expect(prefs.getStringList('transactions'), raw);
    expect(prefs.containsKey('expenses'), isFalse);
    expect(prefs.getBool(TransactionsStore.migratedFlag), isTrue);
    final second = await TransactionService().getTransactions();
    expect(second.map((t) => t.id).toSet(), first.map((t) => t.id).toSet());
    expect(prefs.getStringList('transactions'), raw);

    // A stray `expenses` list reappearing later must not be migrated again.
    await prefs.setStringList('expenses', [tx('stray')]);
    final third = await TransactionService().getTransactions();
    expect(third.map((t) => t.id).toSet(), first.map((t) => t.id).toSet());
    expect(prefs.getStringList('transactions'), raw);
  });

  test('both keys: transactions wins, expenses removed', () async {
    SharedPreferences.setMockInitialValues({
      'expenses': [tx('old')],
      'transactions': [tx('new')],
    });
    final prefs = await SharedPreferences.getInstance();
    final list = await TransactionService().getTransactions();
    expect(list.map((t) => t.id), ['new']);
    expect(prefs.containsKey('expenses'), isFalse);
    expect(prefs.getStringList('transactions'), [tx('new')]);
  });

  test('fresh install writes only transactions', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(await TransactionService().getTransactions(), isEmpty);
    expect(prefs.containsKey('expenses'), isFalse);
    await TransactionsStore.write([tx('9')]);
    expect(prefs.getStringList('transactions'), [tx('9')]);
    expect(prefs.containsKey('expenses'), isFalse);
  });
}
