import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'category_service.dart';
import 'currency_service.dart';
import 'account_service.dart';
import 'settings_service.dart';

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

  Future<String?> buildCSV({DateTime? startDate, DateTime? endDate, String? accountId}) async {
    List<Expense> expenses = await getExpenses();

    if (accountId != null) {
      expenses = expenses.where((e) => e.accountId == accountId).toList();
    }

    if (startDate != null || endDate != null) {
      expenses = expenses.where((expense) {
        if (startDate != null && expense.date.isBefore(startDate)) return false;
        if (endDate != null && expense.date.isAfter(endDate.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    }

    if (expenses.isEmpty) return null;

    final correctionCategory = await SettingsService().getCorrectionExportCategory();
    final buf = StringBuffer();
    buf.writeln('Date,Title,Category,Amount,Currency,Description');
    for (final expense in expenses) {
      final date = DateFormat('yyyy-MM-dd').format(expense.date);
      final title = _escapeCsvField(expense.title);
      final category = _escapeCsvField(expense.isCorrection
          ? correctionCategory
          : expense.category.effectiveExportName);
      final amount = '${expense.increasesBalance ? '' : '-'}${expense.amount.toStringAsFixed(2)}';
      final currency = expense.currency.code;
      final description = _escapeCsvField(expense.description);
      buf.writeln('$date,$title,$category,$amount,$currency,$description');
    }
    return buf.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
