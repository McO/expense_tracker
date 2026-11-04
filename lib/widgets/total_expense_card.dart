import 'package:flutter/material.dart';
import '../models/currency.dart';

class TotalExpenseCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  /// Wallet balance counting every movement kind (top-ups and corrections
  /// included). Defaults to income - expenses when not given.
  final double? balance;
  final Map<Currency, double> currencyTotals;
  final Currency defaultCurrency;

  const TotalExpenseCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    this.balance,
    required this.currencyTotals,
    required this.defaultCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate net balance
    final netBalance = balance ?? (totalIncome - totalExpenses);
    
    // Determine currency to display
    Currency displayCurrency = defaultCurrency;
    if (currencyTotals.isNotEmpty) {
      // Find the currency with the highest total amount (most used)
      final sortedCurrencies = currencyTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      displayCurrency = sortedCurrencies.first.key;
    }
    
    return Column(
      children: [
        // Net Balance Card - Larger
        Card(
          color: netBalance >= 0 ? Colors.blue.shade50 : Colors.orange.shade50,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: netBalance >= 0 ? Colors.blue.shade700 : Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Net Balance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: netBalance >= 0 ? Colors.blue.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${netBalance >= 0 ? '+' : ''}${displayCurrency.symbol}${netBalance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: netBalance >= 0 ? Colors.blue.shade700 : Colors.orange.shade700,
                      ),
                ),
                if (totalIncome > 0 && currencyTotals.length <= 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Savings Rate: ${((totalIncome - totalExpenses) / totalIncome * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (netBalance >= 0 ? Colors.blue.shade700 : Colors.orange.shade700).withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if (currencyTotals.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Combined from ${currencyTotals.length} currencies',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (netBalance >= 0 ? Colors.blue.shade700 : Colors.orange.shade700).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Income and Expenses Row - Smaller, side by side
        Row(
          children: [
            // Income Card
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.green.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Income',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+${displayCurrency.symbol}${totalIncome.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Expenses Card
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '-${displayCurrency.symbol}${totalExpenses.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
