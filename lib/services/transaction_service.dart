import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'category_service.dart';
import 'currency_service.dart';
import 'account_service.dart';
import 'transactions_store.dart';
import 'csv_import.dart';
import '../models/account.dart';

class TransactionService {
  final CategoryService _categoryService = CategoryService();
  final CurrencyService _currencyService = CurrencyService();
  final AccountService _accountService = AccountService();

  Future<List<Transaction>> getTransactions() async {
    final transactionsJson = await TransactionsStore.read();
    final categories = await _categoryService.getCategories();
    final customCurrencies = await _currencyService.getCustomCurrencies();
    
    // Get default account for backward compatibility
    final defaultAccount = await _accountService.getSelectedAccount();
    final defaultAccountId = defaultAccount?.id;

    // A transaction's currency is always its account's (display + export); the
    // stored value is only a fallback when the account can't be resolved.
    final accounts = {for (final a in await _accountService.getAccounts()) a.id: a};

    final transactions = transactionsJson.map((json) {
      final e = Transaction.fromJson(jsonDecode(json), categories, customCurrencies: customCurrencies, defaultAccountId: defaultAccountId);
      final account = accounts[e.accountId];
      return account == null ? e : e.copyWith(currency: account.currency);
    }).toList();
    
    // Sort transactions by newest date and time first
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    return transactions;
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    final index = transactions.indexWhere((e) => e.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await _saveTransactions(transactions);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final transactions = await getTransactions();
    transactions.removeWhere((transaction) => transaction.id == transactionId);
    await _saveTransactions(transactions);
  }

  Future<void> _saveTransactions(List<Transaction> transactions) async {
    final transactionsJson = transactions.map((transaction) => jsonEncode(transaction.toJson())).toList();
    await TransactionsStore.write(transactionsJson);
  }

  Future<Map<Category, double>> getTransactionsByCategory() async {
    final transactions = await getTransactions();
    final Map<Category, double> categoryTotals = {};

    for (final transaction in transactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0.0) + transaction.amount;
    }

    return categoryTotals;
  }

  Future<List<Transaction>> getTransactionsForMonth(DateTime month) async {
    final transactions = await getTransactions();
    return transactions.where((transaction) {
      return transaction.date.year == month.year && transaction.date.month == month.month;
    }).toList();
  }

  Future<List<Transaction>> getTransactionsForAccount(String accountId) async {
    final transactions = await getTransactions();
    return transactions.where((transaction) => transaction.accountId == accountId).toList();
  }

  Future<List<Transaction>> getTransactionsForAccountOrAll(String? accountId) async {
    final transactions = await getTransactions();
    if (accountId == null) {
      return transactions;
    }
    return transactions.where((transaction) => transaction.accountId == accountId).toList();
  }

  Future<String?> buildCSV({DateTime? startDate, DateTime? endDate, String? accountId}) async {
    List<Transaction> transactions = await getTransactions();

    if (accountId != null) {
      transactions = transactions.where((e) => e.accountId == accountId).toList();
    }

    if (startDate != null || endDate != null) {
      transactions = transactions.where((transaction) {
        if (startDate != null && transaction.date.isBefore(startDate)) return false;
        if (endDate != null && transaction.date.isAfter(endDate.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    }

    if (transactions.isEmpty) return null;

    final buf = StringBuffer();
    buf.writeln('Date,Title,Category,Amount,Currency,Description');
    for (final transaction in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(transaction.date);
      final title = _escapeCsvField(transaction.title);
      final category = _escapeCsvField(transaction.category.effectiveExportName);
      final amount = '${transaction.increasesBalance ? '' : '-'}${transaction.amount.toStringAsFixed(2)}';
      final currency = transaction.currency.code;
      final description = _escapeCsvField(transaction.description);
      buf.writeln('$date,$title,$category,$amount,$currency,$description');
    }
    return buf.toString();
  }

  /// Reads an exported CSV into [account] without writing anything.
  Future<ImportPreview> previewImport(String csv, Account account) async {
    return buildImportPreview(
      csv: csv,
      account: account,
      categories: await _categoryService.getCategories(),
      existing: await getTransactionsForAccount(account.id),
    );
  }

  /// Writes the valid, non-duplicate rows of [preview] in one save.
  Future<void> commitImport(ImportPreview preview) => commitImportPreview(preview);

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
