import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/expense.dart';
import '../models/currency.dart';
import '../models/category.dart';
import '../services/expense_service.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../widgets/total_expense_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/recent_expenses.dart';
import '../widgets/currency_filter.dart';
import 'add_expense_screen.dart';
import 'expenses_list_screen.dart';
import 'expense_detail_screen.dart';
import 'settings_screen.dart';
import 'category_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(AppThemeMode)? onThemeModeChanged;
  final AppThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    this.onThemeModeChanged,
    this.currentThemeMode = AppThemeMode.system,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final SettingsService _settingsService = SettingsService();
  List<Expense> _recentExpenses = [];
  List<Expense> _allExpenses = [];
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  Map<Category, double> _categoryTotals = {};
  Map<Category, double> _categoryIncomeTotal = {};
  Map<Category, double> _categoryExpenseTotal = {};
  Map<Currency, double> _currencyTotals = {};
  Set<Currency> _availableCurrencies = {};
  Currency? _selectedCurrencyFilter;
  Currency _defaultCurrency = Currency.usd;
  
  @override
  void initState() {
    super.initState();
    _loadDefaultCurrency();
    _loadData();
  }
  
  Future<void> _loadDefaultCurrency() async {
    try {
      final currency = await _settingsService.getDefaultCurrency();
      setState(() {
        _defaultCurrency = currency;
      });
    } catch (e) {
      // Keep the fallback USD if there's an error
    }
  }

  Future<void> _loadData() async {
    // Refresh default currency in case it was changed in settings
    await _loadDefaultCurrency();
    
    final expenses = await _expenseService.getExpenses();

    // Get available currencies
    final Set<Currency> availableCurrencies = {};
    for (final expense in expenses) {
      availableCurrencies.add(expense.currency);
    }

    setState(() {
      _allExpenses = expenses;
      _availableCurrencies = availableCurrencies;
    });

    _applyFilter();
  }

  void _applyFilter() {
    List<Expense> filteredExpenses;

    if (_selectedCurrencyFilter == null) {
      // Show all expenses
      filteredExpenses = _allExpenses;
    } else {
      // Filter by selected currency
      filteredExpenses = _allExpenses.where((expense) => expense.currency == _selectedCurrencyFilter).toList();
    }

    // Ensure expenses are sorted by newest date and time first (in case filtering changed the order)
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals for filtered data
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    final Map<Category, double> categoryTotals = {};
    final Map<Category, double> categoryIncomeTotal = {};
    final Map<Category, double> categoryExpenseTotal = {};
    final Map<Currency, double> currencyTotals = {};

    for (final expense in filteredExpenses) {
      if (expense.isIncome) {
        totalIncome += expense.amount;
        categoryIncomeTotal[expense.category] = (categoryIncomeTotal[expense.category] ?? 0) + expense.amount;
      } else {
        totalExpenses += expense.amount;
        categoryExpenseTotal[expense.category] = (categoryExpenseTotal[expense.category] ?? 0) + expense.amount;
      }
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      currencyTotals[expense.currency] = (currencyTotals[expense.currency] ?? 0) + expense.amount;
    }

    setState(() {
      _recentExpenses = filteredExpenses.take(5).toList();
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _categoryTotals = categoryTotals;
      _categoryIncomeTotal = categoryIncomeTotal;
      _categoryExpenseTotal = categoryExpenseTotal;
      _currencyTotals = currencyTotals;
    });
  }

  Color _getCategoryColor(Category category) {
    try {
      return Color(int.parse(category.color, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      await _expenseService.deleteExpense(expense.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${expense.title}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Exporting to CSV...'),
              ],
            ),
          );
        },
      );

      final filePath = await _expenseService.exportToCSV();

      // Hide loading indicator
      Navigator.of(context).pop();

      if (filePath != null) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final isInDownloads = filePath.contains('/Download/');
            return AlertDialog(
              title: const Text('Export Successful'),
              content: Text(isInDownloads
                  ? 'CSV file saved to Downloads folder:\n${filePath.split('/Download/').last}'
                  : 'CSV file saved to:\n$filePath'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Export Failed'),
              content: const Text('Failed to export expenses to CSV. This might be due to:\n\n'
                  '• Storage permissions not granted\n'
                  '• Insufficient storage space\n'
                  '• File system restrictions\n\n'
                  'Please check your device settings and try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Export Error'),
            content: Text('An error occurred while exporting: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildCurrencyFilter() {
    return CurrencyFilter(
      availableCurrencies: _availableCurrencies,
      selectedCurrency: _selectedCurrencyFilter,
      onCurrencyChanged: (Currency? newValue) {
        setState(() {
          _selectedCurrencyFilter = newValue;
        });
        _applyFilter();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Expense Tracker',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  _buildCurrencyFilter(),
                  const SizedBox(height: 16),
                  _buildTotalExpenseCard(),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(),
                  const SizedBox(height: 16),
                  _buildRecentExpenses(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildTotalExpenseCard() {
    return TotalExpenseCard(
      totalIncome: _totalIncome,
      totalExpenses: _totalExpenses,
      currencyTotals: _currencyTotals,
      defaultCurrency: _defaultCurrency,
    );
  }

  Widget _buildCategoryBreakdown() {
    return CategoryBreakdown(
      categoryTotals: _categoryTotals,
      categoryIncomeTotal: _categoryIncomeTotal,
      categoryExpenseTotal: _categoryExpenseTotal,
      totalIncome: _totalIncome,
      totalExpenses: _totalExpenses,
      allExpenses: _allExpenses,
      selectedCurrencyFilter: _selectedCurrencyFilter,
    );
  }

  Widget _buildRecentExpenses() {
    return RecentExpenses(
      expenses: _recentExpenses,
      onDelete: _deleteExpense,
      onViewAll: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpensesListScreen()),
        );
        _loadData();
      },
      onRefresh: _loadData,
    );
  }

  IconData _getThemeIcon() {
    final currentMode = widget.currentThemeMode;
    switch (currentMode) {
      case AppThemeMode.light:
        return Icons.brightness_5;
      case AppThemeMode.dark:
        return Icons.brightness_6;
      case AppThemeMode.system:
        return Icons.brightness_7;
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Tracker',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your finances',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('All Expenses'),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpensesListScreen()),
              );
              _loadData();
            },
          ),
                     ListTile(
             leading: const Icon(Icons.file_download),
             title: const Text('Export to CSV'),
             onTap: () async {
               Navigator.pop(context); // Close drawer
               await _exportToCSV();
             },
           ),
           ListTile(
             leading: const Icon(Icons.category),
             title: const Text('Manage Categories'),
             onTap: () async {
               Navigator.pop(context); // Close drawer
               await Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
               );
               _loadData(); // Refresh data in case categories were modified
             },
           ),
           const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onThemeModeChanged: widget.onThemeModeChanged,
                    currentThemeMode: widget.currentThemeMode,
                  ),
                ),
              );
              _loadData();
            },
          ),
          ListTile(
            leading: Icon(_getThemeIcon()),
            title: const Text('Toggle Theme'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              final currentMode = widget.currentThemeMode;
              AppThemeMode nextMode;

              switch (currentMode) {
                case AppThemeMode.light:
                  nextMode = AppThemeMode.dark;
                  break;
                case AppThemeMode.dark:
                  nextMode = AppThemeMode.system;
                  break;
                case AppThemeMode.system:
                  nextMode = AppThemeMode.light;
                  break;
              }

              widget.onThemeModeChanged?.call(nextMode);
            },
          ),
        ],
      ),
    );
  }
}

