import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _expensesKey = 'expenses';

  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_expensesKey) ?? [];

    return expensesJson.map((json) => Expense.fromJson(jsonDecode(json))).toList();
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

  Future<Map<ExpenseCategory, double>> getExpensesByCategory() async {
    final expenses = await getExpenses();
    final Map<ExpenseCategory, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final expenses = await getExpenses();
    return expenses.where((expense) {
      return expense.date.year == month.year && expense.date.month == month.month;
    }).toList();
  }

  /// Exports expenses to CSV format according to the specified German format
  Future<String?> exportToCSV() async {
    try {
      // Request multiple permissions for different Android versions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      // Check if any permission is granted
      bool hasPermission = statuses.values.any((status) => status.isGranted);

      if (!hasPermission) {
        print('No storage permissions granted: $statuses');
        return null;
      }

      final expenses = await getExpenses();
      if (expenses.isEmpty) {
        return null;
      }

      // Sort expenses by date (newest first)
      expenses.sort((a, b) => b.date.compareTo(a.date));

      // Create CSV content
      final StringBuffer csvContent = StringBuffer();

      // Add header
      csvContent.writeln('Datum;Wertstellung;Kategorie;Name;Verwendungszweck;Konto;Bank;Betrag;Währung');

      // Add data rows
      final dateFormat = DateFormat('dd.MM.yyyy');
      final numberFormat = NumberFormat('#,##0.00', 'de_DE');

      for (final expense in expenses) {
        final date = dateFormat.format(expense.date);
        final category = _mapCategoryToGerman(expense.category);
        final name = expense.title;
        final description = expense.description;
        final amount = numberFormat.format(expense.amount);
        final currency = expense.currency.code;

        // Format: Datum;Wertstellung;Kategorie;Name;Verwendungszweck;Konto;Bank;Betrag;Währung
        csvContent.writeln('$date;$date;$category;$name;$description;;;-$amount;$currency');
      }

      // Try multiple locations for saving the file
      List<String> possiblePaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (String path in possiblePaths) {
        try {
          final downloadsDir = Directory(path);
          if (await downloadsDir.exists()) {
            final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
            final fileName = 'expenses_$timestamp.csv';
            final file = File('${downloadsDir.path}/$fileName');

            // Write CSV content to file
            await file.writeAsString(csvContent.toString());
            print('CSV saved successfully to: ${file.path}');
            return file.path;
          }
        } catch (e) {
          print('Failed to save to $path: $e');
          continue;
        }
      }

      // Fallback to app documents directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'expenses_$timestamp.csv';
        final file = File('${appDir.path}/$fileName');

        // Write CSV content to file
        await file.writeAsString(csvContent.toString());
        print('CSV saved to app directory: ${file.path}');
        return file.path;
      } catch (e) {
        print('Failed to save to app directory: $e');
        return null;
      }
    } catch (e) {
      print('Error exporting CSV: $e');
      return null;
    }
  }

  /// Maps expense categories to German names
  String _mapCategoryToGerman(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Lebensmittel';
      case ExpenseCategory.transportation:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Einkaufen';
      case ExpenseCategory.entertainment:
        return 'Unterhaltung';
      case ExpenseCategory.bills:
        return 'Rechnungen';
      case ExpenseCategory.health:
        return 'Gesundheit';
      case ExpenseCategory.education:
        return 'Bildung';
      case ExpenseCategory.travel:
        return 'Reisen';
      case ExpenseCategory.other:
        return 'Sonstiges';
    }
  }
}
