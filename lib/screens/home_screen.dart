import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/transaction.dart';
import '../models/currency.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../services/transaction_service.dart';
import '../services/csv_file_picker.dart';
import '../services/csv_file_saver.dart';
import '../services/app_version_lookup.dart';
import '../services/ledger_totals.dart';
import '../services/theme_service.dart';
import '../services/account_service.dart';
import '../widgets/balance_summary_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/recent_transactions.dart';
import 'statistics_screen.dart';
import '../widgets/correct_balance_dialog.dart';
import 'add_transaction_screen.dart';
import 'transactions_list_screen.dart';
import 'settings_screen.dart';
import 'account_management_screen.dart';
import 'currency_management_screen.dart';
import 'category_management_screen.dart';

/// File name of a CSV export: `transactions_<from>_<to>.csv` (ADR-0005).
String csvExportFileName(DateTimeRange range) {
  String ymd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  return 'transactions_${ymd(range.start)}_${ymd(range.end)}.csv';
}

class HomeScreen extends StatefulWidget {
  final Function(AppThemeMode)? onThemeModeChanged;
  final AppThemeMode currentThemeMode;

  /// File-picking step of CSV import; replaced in tests.
  final CsvFilePicker csvFilePicker;

  /// Save-dialog step of CSV export; replaced in tests.
  final CsvFileSaver csvFileSaver;

  /// Installed-version lookup for the drawer footer; replaced in tests.
  final AppVersionLookup appVersionLookup;

  const HomeScreen({
    super.key,
    this.csvFilePicker = pickCsvFileText,
    this.csvFileSaver = saveCsvFile,
    this.appVersionLookup = lookupAppVersion,
    this.onThemeModeChanged,
    this.currentThemeMode = AppThemeMode.system,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  List<Transaction> _recentTransactions = [];
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
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
    _loadVersion();
  }

  String? _versionLabel;

  Future<void> _loadVersion() async {
    try {
      final version = await widget.appVersionLookup();
      if (!mounted || version == null) return;
      setState(() => _versionLabel = version.label);
    } catch (_) {
      // Lookup failed: show no version line.
    }
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
    final transactions = await _transactionService.getTransactions();

    List<Transaction> filteredTransactions = transactions;
    if (_selectedAccount != null) {
      filteredTransactions = filteredTransactions
          .where((e) => e.accountId == _selectedAccount!.id)
          .toList();
    }
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    final stats = LedgerTotals.statistics(filteredTransactions);
    final totalIncome = stats.totalIncome;
    final totalExpenses = stats.totalExpenses;
    final categoryTotals = stats.categoryTotals;
    final categoryIncomeTotal = stats.categoryIncomeTotal;
    final categoryExpenseTotal = stats.categoryExpenseTotal;
    final currencyTotals = stats.currencyTotals;

    setState(() {
      _allTransactions = transactions;
      _filteredTransactions = filteredTransactions;
      _recentTransactions = filteredTransactions.take(5).toList();
      _balance = LedgerTotals.balance(filteredTransactions);
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _categoryTotals = categoryTotals;
      _categoryIncomeTotal = categoryIncomeTotal;
      _categoryExpenseTotal = categoryExpenseTotal;
      _currencyTotals = currencyTotals;
    });
  }

  void _applyFilter() {
    List<Transaction> filteredTransactions = _allTransactions;

    // Filter by selected account
    if (_selectedAccount != null) {
      filteredTransactions = filteredTransactions.where((transaction) => transaction.accountId == _selectedAccount!.id).toList();
    }

    // Ensure transactions are sorted by newest date and time first (in case filtering changed the order)
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals for filtered data
    final stats = LedgerTotals.statistics(filteredTransactions);
    final totalIncome = stats.totalIncome;
    final totalExpenses = stats.totalExpenses;
    final categoryTotals = stats.categoryTotals;
    final categoryIncomeTotal = stats.categoryIncomeTotal;
    final categoryExpenseTotal = stats.categoryExpenseTotal;
    final currencyTotals = stats.currencyTotals;

    setState(() {
      _filteredTransactions = filteredTransactions;
      _recentTransactions = filteredTransactions.take(5).toList();
      _balance = LedgerTotals.balance(filteredTransactions);
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _categoryTotals = categoryTotals;
      _categoryIncomeTotal = categoryIncomeTotal;
      _categoryExpenseTotal = categoryExpenseTotal;
      _currencyTotals = currencyTotals;
      });
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      await _transactionService.deleteTransaction(transaction.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${transaction.title}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Account?> _selectAccount() {
    return showDialog<Account>(
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
  }

  Future<void> _importFromCSV() async {
    final Account? account = await _selectAccount();
    if (!mounted || account == null) return;

    final String? csv;
    try {
      csv = await widget.csvFilePicker();
    } catch (e) {
      if (mounted) _snack('Could not read the file: $e', Colors.red);
      return;
    }
    if (!mounted || csv == null) return;

    final preview = await _transactionService.previewImport(csv, account);
    if (!mounted) return;

    if (preview.fileError != null) {
      await _showImportMessage('Cannot import', preview.fileError!);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import preview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Into account: ${account.name}'),
              const SizedBox(height: 8),
              Text('${preview.toImport.length} to import',
                  key: const Key('import-count')),
              Text('${preview.duplicates} duplicates skipped',
                  key: const Key('import-duplicates')),
              Text('${preview.mappedToOther} rows mapped to "Other"',
                  key: const Key('import-other')),
              Text('${preview.invalid.length} invalid rows',
                  key: const Key('import-invalid')),
              for (final e in preview.invalid) Text('  $e'),
              if (preview.hasNothingToImport) ...[
                const SizedBox(height: 8),
                const Text('Nothing to import: every row is invalid or a duplicate.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (!preview.hasNothingToImport)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _transactionService.commitImport(preview);
    await _loadData();
    if (mounted) {
      _snack('Imported ${preview.toImport.length} transactions', Colors.green);
    }
  }

  Future<void> _showImportMessage(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  Future<void> _exportToCSV() async {
    final Account? selectedAccount = await _selectAccount();

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
    final csvContent = await _transactionService.buildCSV(
      startDate: dateRange.start,
      endDate: dateRange.end,
      accountId: selectedAccount.id,
    );

    if (!mounted) return;

    if (csvContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions found for the selected range')),
      );
      return;
    }

    final fileName = csvExportFileName(dateRange);

    try {
      final saved = await widget.csvFileSaver(fileName, csvContent);
      if (!saved) return; // cancelled: nothing written, no message
      if (mounted) _snack('Saved $fileName', Colors.green);
    } catch (e) {
      if (mounted) _snack('Export failed: $e', Colors.red);
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
                Icons.account_balance,
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
                  _buildBalanceSummaryCard(),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
    );
  }

  Widget _buildBalanceSummaryCard() {
    return BalanceSummaryCard(
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
      allTransactions: _filteredTransactions,
    );
  }

  Widget _buildRecentTransactions() {
    return RecentTransactions(
      transactions: _recentTransactions,
      onDelete: _deleteTransaction,
      onViewAll: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionsListScreen()),
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
      child: Column(
        children: [
          Expanded(child: _buildDrawerItems()),
          if (_versionLabel != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _versionLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    return ListView(
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
                        Icons.account_balance,
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
            title: const Text('All Transactions'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsListScreen()),
              );
              await _loadData();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance),
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
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics'),
            onTap: () async {
              Navigator.pop(context);
              final account = _selectedAccount;
              if (account == null) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StatisticsScreen(account: account)),
              );
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
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import CSV'),
            onTap: () async {
              Navigator.pop(context);
              await _importFromCSV();
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
    );
  }
}

