import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/expense.dart';
import '../models/currency.dart';
import '../services/expense_service.dart';
import 'add_expense_screen.dart';
import 'expenses_list_screen.dart';
import 'expense_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    this.onThemeToggle,
    this.isDarkMode = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _recentExpenses = [];
  List<Expense> _allExpenses = [];
  double _totalExpenses = 0.0;
  Map<ExpenseCategory, double> _categoryTotals = {};
  Map<Currency, double> _currencyTotals = {};
  Set<Currency> _availableCurrencies = {};
  Currency? _selectedCurrencyFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
    final Map<ExpenseCategory, double> categoryTotals = {};
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

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (result == true) {
      _loadData();
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
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpensesListScreen()),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                          onThemeToggle: widget.onThemeToggle,
                          isDarkMode: widget.isDarkMode,
                        )),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
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
    if (_currencyTotals.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Expenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$0.00',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'This month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Expenses',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _currencyTotals.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 200,
                          child: Card(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          entry.key.symbol,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key.code,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${entry.key.symbol}${entry.value.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    String _formatCategoryAmount(ExpenseCategory category, double amount) {
      if (_selectedCurrencyFilter != null) {
        // When filtered by currency, show the amount in that currency
        return '${_selectedCurrencyFilter!.symbol}${amount.toStringAsFixed(2)}';
      } else {
        // When showing all currencies, check if category has mixed currencies
        final categoryExpenses = _allExpenses.where((e) => e.category == category);
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
                      Text(
                        entry.key.icon,
                        style: const TextStyle(fontSize: 24),
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
                                  entry.key.displayName,
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
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          expense.category.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(
                        expense.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${expense.category.displayName} • ${DateFormat('MMM d, yyyy').format(expense.date)}',
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
                  );
                }).toList(),
              ),
      ],
    );
  }
}
