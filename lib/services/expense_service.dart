import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/currency.dart';
import 'category_service.dart';
import 'currency_service.dart';
import 'account_service.dart';

class ExpenseService {
  static const String _expensesKey = 'expenses';
  final CategoryService _categoryService = CategoryService();
  final CurrencyService _currencyService = CurrencyService();
  final AccountService _accountService = AccountService();

  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_expensesKey) ?? [];
    final categories = await _categoryService.getCategories();
    final customCurrencies = await _currencyService.getCustomCurrencies();
    
    // Get default account for backward compatibility
    final defaultAccount = await _accountService.getSelectedAccount();
    final defaultAccountId = defaultAccount?.id;

    final expenses = expensesJson.map((json) => Expense.fromJson(jsonDecode(json), categories, customCurrencies: customCurrencies, defaultAccountId: defaultAccountId)).toList();
    
    // Sort expenses by newest date and time first
    expenses.sort((a, b) => b.date.compareTo(a.date));
    
    return expenses;
  }

  Future<void> saveExpense(Expense expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    await _saveExpenses(expenses);
  }

  Future<void> updateExpense(Expense expense) async {
    final expenses = await getExpenses();
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      expenses[index] = expense;
      await _saveExpenses(expenses);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final expenses = await getExpenses();
    expenses.removeWhere((expense) => expense.id == expenseId);
    await _saveExpenses(expenses);
  }

  Future<void> _saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = expenses.map((expense) => jsonEncode(expense.toJson())).toList();
    await prefs.setStringList(_expensesKey, expensesJson);
  }

  Future<double> getTotalExpenses() async {
    final expenses = await getExpenses();
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<Map<Category, double>> getExpensesByCategory() async {
    final expenses = await getExpenses();
    final Map<Category, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    return categoryTotals;
  }

  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final expenses = await getExpenses();
    return expenses.where((expense) {
      return expense.date.year == month.year && expense.date.month == month.month;
    }).toList();
  }

  Future<List<Expense>> getExpensesForAccount(String accountId) async {
    final expenses = await getExpenses();
    return expenses.where((expense) => expense.accountId == accountId).toList();
  }

  Future<List<Expense>> getExpensesForAccountOrAll(String? accountId) async {
    final expenses = await getExpenses();
    if (accountId == null) {
      return expenses;
    }
    return expenses.where((expense) => expense.accountId == accountId).toList();
  }

  Future<String?> exportToCSV({DateTime? startDate, DateTime? endDate, String? accountId, String? storagePath}) async {
    try {
      List<Expense> expenses = await getExpenses();
      
      if (expenses.isEmpty) {
        return null;
      }

      // Filter expenses by account if provided
      if (accountId != null) {
        expenses = expenses.where((expense) => expense.accountId == accountId).toList();
        
        if (expenses.isEmpty) {
          return null;
        }
      }

      // Filter expenses by date range if provided
      if (startDate != null || endDate != null) {
        expenses = expenses.where((expense) {
          if (startDate != null && expense.date.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && expense.date.isAfter(endDate.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        }).toList();

        if (expenses.isEmpty) {
          return null;
        }
      }

      // Request permission for external storage
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // Try storage permission instead
          status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) {
              return null;
            }
          }
        }
      }

      // Create CSV content
      final StringBuffer csvContent = StringBuffer();
      csvContent.writeln('Date,Title,Category,Amount,Currency,Description');

      for (final expense in expenses) {
        final date = DateFormat('yyyy-MM-dd').format(expense.date);
        final title = _escapeCsvField(expense.title);
        final category = _escapeCsvField(expense.category.effectiveExportName);
        final amount = expense.amount.toStringAsFixed(2);
        final currency = expense.currency.code;
        final description = _escapeCsvField(expense.description);
        
        csvContent.writeln('$date,$title,$category,$amount,$currency,$description');
      }

      // Get directory based on storage type
      Directory? directory;
      String? directoryPath = storagePath ?? await getExportDirectory();

      if (directoryPath == null) {
        return null;
      }
      
      directory = Directory(directoryPath);
      
      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create file with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'expenses_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      // Write CSV content to file
      await file.writeAsString(csvContent.toString());

      return file.path;
    } catch (e) {
      return null;
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<String?> getExportDirectory() async {
    try {
      // Try to get Downloads directory first
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final altDownloadsDir = Directory('/storage/emulated/0/Downloads');
      
      if (await downloadsDir.exists()) {
        return downloadsDir.path;
      } else if (await altDownloadsDir.exists()) {
        return altDownloadsDir.path;
      }

      // Try to get external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir.path;
      }

      // Fall back to app documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      return docsDir.path;
    } catch (e) {
      return null;
    }
  }
}
