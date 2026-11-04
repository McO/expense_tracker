import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/expense.dart';
import '../models/currency.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../services/expense_service.dart';
import '../services/ledger_totals.dart';
import '../services/theme_service.dart';
import '../services/account_service.dart';
import '../widgets/total_expense_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/recent_expenses.dart';
import '../widgets/correct_balance_dialog.dart';
import 'add_expense_screen.dart';
import 'expenses_list_screen.dart';
import 'settings_screen.dart';
import 'account_management_screen.dart';
import 'currency_management_screen.dart';
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
  final AccountService _accountService = AccountService();
  List<Expense> _recentExpenses = [];
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  double _balance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  Map<Category, double> _categoryTotals = {};
  Map<Category, double> _categoryIncomeTotal = {};
  Map<Category, double> _categoryExpenseTotal = {};
  Map<Currency, double> _currencyTotals = {};
  final Currency _defaultCurrency = Currency.usd;
  Account? _selectedAccount;
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadAccounts();
    await _loadData();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountService.getAccounts();
      final selectedAccount = await _accountService.getSelectedAccount();
      setState(() {
        _accounts = accounts;
        _selectedAccount = selectedAccount;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadData() async {
    final expenses = await _expenseService.getExpenses();

    List<Expense> filteredExpenses = expenses;
    if (_selectedAccount != null) {
      filteredExpenses = filteredExpenses
          .where((e) => e.accountId == _selectedAccount!.id)
          .toList();
    }
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    final stats = LedgerTotals.statistics(filteredExpenses);
    final totalIncome = stats.totalIncome;
    final totalExpenses = stats.totalExpenses;
    final categoryTotals = stats.categoryTotals;
    final categoryIncomeTotal = stats.categoryIncomeTotal;
    final categoryExpenseTotal = stats.categoryExpenseTotal;
    final currencyTotals = stats.currencyTotals;

    setState(() {
      _allExpenses = expenses;
      _filteredExpenses = filteredExpenses;
      _recentExpenses = filteredExpenses.take(5).toList();
      _balance = LedgerTotals.balance(filteredExpenses);
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _categoryTotals = categoryTotals;
      _categoryIncomeTotal = categoryIncomeTotal;
      _categoryExpenseTotal = categoryExpenseTotal;
      _currencyTotals = currencyTotals;
    });
  }

  void _applyFilter() {
    List<Expense> filteredExpenses = _allExpenses;

    // Filter by selected account
    if (_selectedAccount != null) {
      filteredExpenses = filteredExpenses.where((expense) => expense.accountId == _selectedAccount!.id).toList();
    }

    // Ensure expenses are sorted by newest date and time first (in case filtering changed the order)
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals for filtered data
    final stats = LedgerTotals.statistics(filteredExpenses);
    final totalIncome = stats.totalIncome;
    final totalExpenses = stats.totalExpenses;
    final categoryTotals = stats.categoryTotals;
    final categoryIncomeTotal = stats.categoryIncomeTotal;
    final categoryExpenseTotal = stats.categoryExpenseTotal;
    final currencyTotals = stats.currencyTotals;

    setState(() {
      _filteredExpenses = filteredExpenses;
      _recentExpenses = filteredExpenses.take(5).toList();
      _balance = LedgerTotals.balance(filteredExpenses);
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _categoryTotals = categoryTotals;
      _categoryIncomeTotal = categoryIncomeTotal;
      _categoryExpenseTotal = categoryExpenseTotal;
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
    final Account? selectedAccount = await showDialog<Account>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _accounts.map((account) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse(account.color, radix: 16)),
                  child: Text(account.icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(account.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${account.currency.displayName} (${account.currency.symbol})'),
                onTap: () => Navigator.pop(context, account),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedAccount == null) return;

    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (!mounted || dateRange == null) return;

    // Build CSV content
    final csvContent = await _expenseService.buildCSV(
      startDate: dateRange.start,
      endDate: dateRange.end,
      accountId: selectedAccount.id,
    );

    if (!mounted) return;

    if (csvContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses found for the selected range')),
      );
      return;
    }

    // Request storage permission
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    if (!status.isGranted) {
      var fallback = await Permission.storage.status;
      if (!fallback.isGranted) fallback = await Permission.storage.request();
      if (!fallback.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to export'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final from = '${dateRange.start.year}${dateRange.start.month.toString().padLeft(2, '0')}${dateRange.start.day.toString().padLeft(2, '0')}';
    final to = '${dateRange.end.year}${dateRange.end.month.toString().padLeft(2, '0')}${dateRange.end.day.toString().padLeft(2, '0')}';
    final fileName = 'expenses_${from}_$to.csv';

    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final dir = await downloadsDir.exists() ? downloadsDir : Directory('/storage/emulated/0/Downloads');
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads/$fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAccountSelector() {
    if (_accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
              child: DropdownButton<Account>(
                value: _selectedAccount,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                onChanged: (Account? newValue) async {
                setState(() {
                    _selectedAccount = newValue;
                });
                  if (newValue != null) {
                    await _accountService.setSelectedAccount(newValue.id);
                  }
                _applyFilter();
              },
                items: _accounts.map<DropdownMenuItem<Account>>((Account account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Row(
                      children: [
                        Text(
                          account.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                  child: Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          account.currency.code,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ),
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                  _buildAccountSelector(),
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
        label: const Text('Add movement'),
      ),
    );
  }

  Widget _buildTotalExpenseCard() {
    return TotalExpenseCard(
      balance: _balance,
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
      allExpenses: _filteredExpenses,
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
                  await _loadData();
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
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
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
                            color: Colors.black.withValues(alpha: 0.1),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpensesListScreen()),
              );
              await _loadData();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Accounts'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountManagementScreen()),
              );
              await _initData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currencies'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
              );
              await _loadData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Correct balance'),
            onTap: () async {
              Navigator.pop(context);
              final account = _selectedAccount;
              if (account == null) return;
              await correctBalance(context, account: account, balance: _balance);
              await _loadData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export'),
            onTap: () async {
              Navigator.pop(context);
              await _exportToCSV();
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

