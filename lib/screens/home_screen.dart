import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/expense.dart';
import '../models/currency.dart';
import '../models/category.dart';
import '../services/expense_service.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
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
  double _totalExpenses = 0.0;
  Map<Category, double> _categoryTotals = {};
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

    // Calculate totals for filtered data
    double total = 0.0;
    final Map<Category, double> categoryTotals = {};
    final Map<Currency, double> currencyTotals = {};

    for (final expense in filteredExpenses) {
      total += expense.amount;
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      currencyTotals[expense.currency] = (currencyTotals[expense.currency] ?? 0) + expense.amount;
    }

    setState(() {
      _recentExpenses = filteredExpenses.take(5).toList();
      _totalExpenses = total;
      _categoryTotals = categoryTotals;
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
    if (_availableCurrencies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<Currency?>(
              value: _selectedCurrencyFilter,
              isDense: true,
              hint: Text(
                'All',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onChanged: (Currency? newValue) {
                setState(() {
                  _selectedCurrencyFilter = newValue;
                });
                _applyFilter();
              },
              items: [
                DropdownMenuItem<Currency?>(
                  value: null,
                  child: Text(
                    'All',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                ..._availableCurrencies.map<DropdownMenuItem<Currency?>>((Currency currency) {
                  return DropdownMenuItem<Currency?>(
                    value: currency,
                    child: Text(
                      currency.code,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
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
                  const SizedBox(height: 24),
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
    // Calculate total amount across all currencies
    final totalAmount = _currencyTotals.values.fold<double>(0.0, (sum, amount) => sum + amount);
    
    // Determine currency to display
    Currency displayCurrency = _defaultCurrency; // use user's default currency
    if (_currencyTotals.isNotEmpty) {
      // Find the currency with the highest total amount (most used)
      final sortedCurrencies = _currencyTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      displayCurrency = sortedCurrencies.first.key;
    }
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Expenses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${displayCurrency.symbol}${totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            if (_currencyTotals.length > 1)
              Text(
                'Combined from ${_currencyTotals.length} currencies',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
              )
            else
              Text(
                'This month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

        String _formatCategoryAmount(Category category, double amount) {
      if (_selectedCurrencyFilter != null) {
        // When filtered by currency, show the amount in that currency
        return '${_selectedCurrencyFilter!.symbol}${amount.toStringAsFixed(2)}';
      } else {
        // When showing all currencies, check if category has mixed currencies
        final categoryExpenses = _allExpenses.where((e) => e.category.id == category.id);
        final categoryCurrencies = categoryExpenses.map((e) => e.currency).toSet();
        
        if (categoryCurrencies.length == 1) {
          // Single currency for this category
          final currency = categoryCurrencies.first;
          return '${currency.symbol}${amount.toStringAsFixed(2)}';
        } else {
          // Mixed currencies
          return 'Mixed currencies';
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_selectedCurrencyFilter != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedCurrencyFilter!.code,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _categoryTotals.entries.map((entry) {
                final percentage = _totalExpenses > 0 ? (entry.value / _totalExpenses) * 100 : 0.0;

                                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getCategoryColor(entry.key).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            entry.key.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key.name,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  _formatCategoryAmount(entry.key, entry.value),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getCategoryColor(entry.key),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpenses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Expenses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_recentExpenses.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExpensesListScreen()),
                  );
                  _loadData();
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _recentExpenses.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first expense',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Column(
                children: _recentExpenses.map((expense) {
                  return Dismissible(
                    key: Key(expense.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Expense'),
                          content: Text('Are you sure you want to delete "${expense.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      await _deleteExpense(expense);
                    },
                                          child: Card(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(expense.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getCategoryColor(expense.category).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                expense.category.icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          title: Text(
                            expense.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${expense.category.name} • ${DateFormat('MMM d, yyyy').format(expense.date)}',
                          ),
                        trailing: Text(
                          expense.formattedAmount,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpenseDetailScreen(expense: expense),
                            ),
                          );

                          if (result == true) {
                            _loadData();
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
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
