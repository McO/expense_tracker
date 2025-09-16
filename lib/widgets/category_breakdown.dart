import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/currency.dart';
import '../models/expense.dart';

class CategoryBreakdown extends StatefulWidget {
  final Map<Category, double> categoryTotals;
  final Map<Category, double> categoryIncomeTotal;
  final Map<Category, double> categoryExpenseTotal;
  final double totalIncome;
  final double totalExpenses;
  final List<Expense> allExpenses;
  final Currency? selectedCurrencyFilter;

  const CategoryBreakdown({
    super.key,
    required this.categoryTotals,
    required this.categoryIncomeTotal,
    required this.categoryExpenseTotal,
    required this.totalIncome,
    required this.totalExpenses,
    required this.allExpenses,
    required this.selectedCurrencyFilter,
  });

  @override
  State<CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<CategoryBreakdown> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.categoryTotals.length <= 1) return;
    
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.categoryTotals.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  Color _getCategoryColor(Category category) {
    try {
      return Color(int.parse(category.color, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatCategoryAmount(Category category, double amount, bool isIncome) {
    String formattedAmount;
    
    if (widget.selectedCurrencyFilter != null) {
      formattedAmount = '${widget.selectedCurrencyFilter!.symbol}${amount.toStringAsFixed(2)}';
    } else {
      final categoryExpenses = widget.allExpenses.where((e) => e.category.id == category.id);
      final categoryCurrencies = categoryExpenses.map((e) => e.currency).toSet();
      
      if (categoryCurrencies.length == 1) {
        final currency = categoryCurrencies.first;
        formattedAmount = '${currency.symbol}${amount.toStringAsFixed(2)}';
      } else {
        formattedAmount = 'Mixed currencies';
      }
    }
    
    if (formattedAmount != 'Mixed currencies') {
      formattedAmount = '${isIncome ? '+' : '-'}$formattedAmount';
    }
    
    return formattedAmount;
  }

  String _formatCategoryTotal(Category category, double amount) {
    if (widget.selectedCurrencyFilter != null) {
      return '${widget.selectedCurrencyFilter!.symbol}${amount.toStringAsFixed(2)}';
    } else {
      final categoryExpenses = widget.allExpenses.where((e) => e.category.id == category.id);
      final categoryCurrencies = categoryExpenses.map((e) => e.currency).toSet();
      
      if (categoryCurrencies.length == 1) {
        final currency = categoryCurrencies.first;
        return '${currency.symbol}${amount.toStringAsFixed(2)}';
      } else {
        return 'Mixed currencies';
      }
    }
  }

  double _calculateSlideHeight() {
    double baseHeight = 50.0;
    baseHeight += 16.0;
    baseHeight += 4.0;
    
    double maxContentHeight = 0.0;
    
    for (final category in widget.categoryTotals.keys) {
      final incomeAmount = widget.categoryIncomeTotal[category] ?? 0.0;
      final expenseAmount = widget.categoryExpenseTotal[category] ?? 0.0;
      
      double contentHeight = 0.0;
      
      if (incomeAmount > 0) {
        contentHeight += 36.0;
        contentHeight += 2.0;
      }
      
      if (expenseAmount > 0) {
        contentHeight += 36.0;
        contentHeight += 2.0;
      }
      
      if (contentHeight > 0) {
        contentHeight -= 2.0;
      }
      
      if (contentHeight > maxContentHeight) {
        maxContentHeight = contentHeight;
      }
    }
    
    if (maxContentHeight == 0.0) {
      maxContentHeight = 16.0;
    }
    
    return baseHeight + maxContentHeight;
  }

  Widget _buildAmountRow(String label, double amount, Category category, bool isIncome, double percentage) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isIncome ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIncome ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: isIncome ? Colors.green : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isIncome ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isIncome ? Colors.green : Colors.red,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySlide(Category category) {
    final color = _getCategoryColor(category);
    final incomeAmount = widget.categoryIncomeTotal[category] ?? 0.0;
    final expenseAmount = widget.categoryExpenseTotal[category] ?? 0.0;
    final totalAmount = widget.categoryTotals[category] ?? 0.0;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.4), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatCategoryTotal(category, totalAmount),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              if (incomeAmount > 0 || expenseAmount > 0) ...[
                if (incomeAmount > 0) ...[
                  _buildAmountRow(
                    'Income',
                    incomeAmount,
                    category,
                    true,
                    widget.totalIncome > 0 ? (incomeAmount / widget.totalIncome) * 100 : 0.0,
                  ),
                  const SizedBox(height: 4),
                ],
                if (expenseAmount > 0) ...[
                  _buildAmountRow(
                    'Expenses',
                    expenseAmount,
                    category,
                    false,
                    widget.totalExpenses > 0 ? (expenseAmount / widget.totalExpenses) * 100 : 0.0,
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoryList = widget.categoryTotals.keys.toList();

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
            if (widget.selectedCurrencyFilter != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.selectedCurrencyFilter!.code,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: _calculateSlideHeight(),
          child: GestureDetector(
            onTapDown: (_) => _stopAutoScroll(),
            onPanStart: (_) => _stopAutoScroll(),
            onTapUp: (_) => Future.delayed(
              const Duration(seconds: 3),
              () => _startAutoScroll(),
            ),
            onPanEnd: (_) => Future.delayed(
              const Duration(seconds: 3),
              () => _startAutoScroll(),
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                final category = categoryList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildCategorySlide(category),
                );
              },
            ),
          ),
        ),
        
        if (categoryList.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentPage + 1} of ${categoryList.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                ...List.generate(categoryList.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == index ? 12 : 8,
                    height: _currentPage == index ? 12 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
