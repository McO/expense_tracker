import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction_type.dart';
import '../services/category_service.dart';
import 'add_edit_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditCategoryScreen(),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete default categories'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?\n\nExpenses using this category will be moved to "Other".'),
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
        await _categoryService.deleteCategory(category.id);
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${category.name}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting category: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryCard(category);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final color = _getColorFromHex(category.color);
    
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Center(
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (category.exportName?.isNotEmpty == true) ...[
              Text(
                'Export as: ${category.exportName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    category.isDefault ? 'Default' : 'Custom',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editCategory(category);
                break;
              case 'delete':
                _deleteCategory(category);
                break;
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
            if (!category.isDefault)
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
        onTap: () => _editCategory(category),
      ),
    );
  }
} 