import 'package:flutter/material.dart';
import '../widgets/transaction_style.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/transaction_type.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import 'transaction_detail_screen.dart';
import 'edit_transaction_screen.dart';

class TransactionsListScreen extends StatefulWidget {
  final Category? initialCategoryFilter;
  
  const TransactionsListScreen({super.key, this.initialCategoryFilter});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  List<Category> _availableCategories = [];
  Category? _selectedCategory;
  TransactionType? _selectedTransactionType;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Don't set _selectedCategory here - wait for categories to load
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _transactionService.getTransactions();
      final categories = await _categoryService.getCategories();
      
      setState(() {
        _allTransactions = transactions; // Already sorted by service
        _filteredTransactions = _allTransactions;
        _availableCategories = categories;
        
        // Ensure the initial category filter exists in the loaded categories
        if (widget.initialCategoryFilter != null) {
          final matchingCategory = categories.firstWhere(
            (cat) => cat.id == widget.initialCategoryFilter!.id,
            orElse: () => widget.initialCategoryFilter!,
          );
          _selectedCategory = matchingCategory;
        }
        
        _isLoading = false;
      });
      
      // Apply initial category filter if provided
      if (widget.initialCategoryFilter != null) {
        _filterTransactions();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTransactions() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        final matchesSearch = transaction.title
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            transaction.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == null || 
            transaction.category.id == _selectedCategory!.id;
        final matchesTransactionType = _selectedTransactionType == null ||
            transaction.type == _selectedTransactionType;
        
        return matchesSearch && matchesCategory && matchesTransactionType;
      }).toList();
      
      // Ensure filtered transactions maintain sort order by newest date and time first
      _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterTransactions();
  }

  void _onCategoryFilterChanged(Category? category) {
    _selectedCategory = category;
    _filterTransactions();
  }

  void _onTransactionTypeFilterChanged(TransactionType? type) {
    _selectedTransactionType = type;
    _filterTransactions();
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${transaction.title}"?'),
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

    if (confirm == true) {
      try {
        await _transactionService.deleteTransaction(transaction.id);
        await _loadTransactions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction deleted successfully'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(180),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Transaction Type Filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TransactionType?>(
                        initialValue: _selectedTransactionType,
                        decoration: InputDecoration(
                          labelText: 'Transaction Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: [
                          const DropdownMenuItem<TransactionType?>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          DropdownMenuItem<TransactionType?>(
                            value: TransactionType.income,
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                const Text('Income'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<TransactionType?>(
                            value: TransactionType.expense,
                            child: Row(
                              children: [
                                Icon(Icons.trending_down, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                const Text('Expenses'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: _onTransactionTypeFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<Category?>(
                        initialValue: _selectedCategory != null && _availableCategories.any((cat) => cat.id == _selectedCategory!.id)
                            ? _availableCategories.firstWhere((cat) => cat.id == _selectedCategory!.id)
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: [
                          const DropdownMenuItem<Category?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._availableCategories.map((category) => DropdownMenuItem<Category?>(
                            value: category,
                            child: Row(
                              children: [
                                Text(category.icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(category.name)),
                              ],
                            ),
                          )),
                        ],
                        onChanged: _onCategoryFilterChanged,
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTransactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        // Safety check to prevent index out of bounds
                        if (index >= _filteredTransactions.length) {
                          return const SizedBox.shrink();
                        }
                        
                        final transaction = _filteredTransactions[index];
                        
                        // Wrap in try-catch to prevent animation rendering issues
                        try {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildTransactionCard(transaction),
                              ),
                            ),
                          );
                        } catch (e) {
                          // Fallback to simple card without animation
                          return _buildTransactionCard(transaction);
                        }
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty || _selectedCategory != null || _selectedTransactionType != null
                ? Icons.search_off
                : Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null || _selectedTransactionType != null
                ? 'No transactions found'
                : 'No transactions yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null || _selectedTransactionType != null
                ? 'Try adjusting your search or filters'
                : 'Start adding transactions to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: transaction.type == TransactionType.expense ? Colors.red : Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              transaction.type == TransactionType.expense ? Icons.delete : Icons.check_circle,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              transaction.type == TransactionType.expense ? 'Delete' : 'Added',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Transaction'),
            content: Text('Are you sure you want to delete "${transaction.title}"?'),
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
        try {
          await _transactionService.deleteTransaction(transaction.id);
          await _loadTransactions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${transaction.title}" deleted'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: Colors.white,
                  onPressed: () {
                    // Add undo functionality if needed in the future
                  },
                ),
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
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: transaction.category.toColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: transaction.category.toColor().withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                transaction.category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transaction.category.name} • ${DateFormat('MMM d, yyyy • h:mm a').format(transaction.date)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!transaction.countsInStatistics) ...[
                const SizedBox(height: 4),
                const NotCountedMarker(),
              ],
              if (transaction.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmountWithSign,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: transactionColor(transaction),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editTransaction(transaction);
                  } else if (value == 'delete') {
                    _deleteTransaction(transaction);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(transaction: transaction),
              ),
            );
          },
        ),
      ),
    );
  }
} 