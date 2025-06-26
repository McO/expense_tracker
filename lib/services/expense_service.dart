import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _expensesKey = 'expenses';
  
  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getStringList(_expensesKey) ?? [];
    
    return expensesJson
        .map((json) => Expense.fromJson(jsonDecode(json)))
        .toList();
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
    final expensesJson = expenses
        .map((expense) => jsonEncode(expense.toJson()))
        .toList();
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
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    return categoryTotals;
  }

  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final expenses = await getExpenses();
    return expenses.where((expense) {
      return expense.date.year == month.year && 
             expense.date.month == month.month;
    }).toList();
  }
} 