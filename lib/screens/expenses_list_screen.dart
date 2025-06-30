import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import 'expense_detail_screen.dart';
import 'edit_expense_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final CategoryService _categoryService = CategoryService();
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  List<Category> _availableCategories = [];
  Category? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await _expenseService.getExpenses();
      final categories = await _categoryService.getCategories();
      
      // Get unique categories used in expenses
      final usedCategories = expenses.map((e) => e.category).toSet().toList();
      
      setState(() {
        _allExpenses = expenses..sort((a, b) => b.date.compareTo(a.date));
        _filteredExpenses = _allExpenses;
        _availableCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expenses: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _allExpenses.where((expense) {
        final matchesSearch = expense.title
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            expense.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == null || 
            expense.category.id == _selectedCategory!.id;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterExpenses();
  }

  void _onCategoryFilterChanged(Category? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterExpenses();
  }

  Color _getCategoryColor(Category category) {
    try {
      return Color(int.parse(category.color, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expense),
      ),
    );

    if (result == true) {
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final bool? confirm = await showDialog<bool>(
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

    if (confirm == true) {
      try {
        await _expenseService.deleteExpense(expense.id);
        await _loadExpenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Expenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                // Category filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: _selectedCategory == null,
                          onSelected: (_) => _onCategoryFilterChanged(null),
                          label: const Text('All'),
                        ),
                      ),
                      ..._availableCategories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _selectedCategory?.id == category.id,
                            onSelected: (_) => _onCategoryFilterChanged(category),
                            backgroundColor: _getCategoryColor(category).withOpacity(0.1),
                            selectedColor: _getCategoryColor(category).withOpacity(0.2),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category.icon),
                                const SizedBox(width: 4),
                                Text(category.name),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredExpenses.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadExpenses,
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = _filteredExpenses[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildExpenseCard(expense),
                            ),
                          ),
                        );
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
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? Icons.search_off
                : Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? 'No expenses found'
                : 'No expenses yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? 'Try adjusting your search or filters'
                : 'Start adding expenses to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
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
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
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
        try {
          await _expenseService.deleteExpense(expense.id);
          await _loadExpenses();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${expense.title}" deleted'),
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
                content: Text('Error deleting expense: ${e.toString()}'),
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
              color: _getCategoryColor(expense.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCategoryColor(expense.category).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                expense.category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            expense.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${expense.category.name} • ${DateFormat('MMM d, yyyy').format(expense.date)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (expense.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  expense.description,
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
                expense.formattedAmount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editExpense(expense);
                  } else if (value == 'delete') {
                    _deleteExpense(expense);
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
                builder: (context) => ExpenseDetailScreen(expense: expense),
              ),
            );
          },
        ),
      ),
    );
  }
} 