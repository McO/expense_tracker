import 'package:flutter/material.dart';
import '../models/currency.dart';

class TotalExpenseCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final Map<Currency, double> currencyTotals;
  final Currency defaultCurrency;

  const TotalExpenseCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currencyTotals,
    required this.defaultCurrency,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate net balance
    final netBalance = totalIncome - totalExpenses;
    
    // Determine currency to display
    Currency displayCurrency = defaultCurrency;
    if (currencyTotals.isNotEmpty) {
      // Find the currency with the highest total amount (most used)
      final sortedCurrencies = currencyTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      displayCurrency = sortedCurrencies.first.key;
    }
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  'Financial Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Net Balance
            Row(
              children: [
                Icon(
                  netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: netBalance >= 0 ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Net Balance: ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${netBalance >= 0 ? '+' : ''}${displayCurrency.symbol}${netBalance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: netBalance >= 0 ? Colors.green : Colors.red,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Income and Expenses Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Income',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${displayCurrency.symbol}${totalIncome.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '-${displayCurrency.symbol}${totalExpenses.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              ),
              
              const SizedBox(height: 8),
              if (currencyTotals.length > 1)
                Text(
                  'Combined from ${currencyTotals.length} currencies',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                )
              else if (totalIncome > 0)
                Text(
                  'Savings Rate: ${((totalIncome - totalExpenses) / totalIncome * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                )
          ],
        ),
      ),
    );
  }
}
