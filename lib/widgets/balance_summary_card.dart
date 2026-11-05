import '../services/amount_format.dart';
import 'package:flutter/material.dart';
import '../models/currency.dart';

class BalanceSummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  /// Account balance counting every transaction kind (top-ups and corrections
  /// included). Defaults to income - expenses when not given.
  final double? balance;
  final Map<Currency, double> currencyTotals;
  final Currency defaultCurrency;
  final LocaleLookup localeLookup;

  const BalanceSummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    this.balance,
    required this.currencyTotals,
    required this.defaultCurrency,
    this.localeLookup = deviceLocale,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate net balance
    final locale = localeLookup();
    final netBalance = balance ?? (totalIncome - totalExpenses);
    
    // Determine currency to display
    Currency displayCurrency = defaultCurrency;
    if (currencyTotals.isNotEmpty) {
      // Find the currency with the highest total amount (most used)
      final sortedCurrencies = currencyTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      displayCurrency = sortedCurrencies.first.key;
    }
    
    final scheme = Theme.of(context).colorScheme;
    final income = _Tone(Colors.green, scheme);
    final expense = _Tone(Colors.red, scheme);
    final net = netBalance >= 0
        ? _Tone(scheme.primary, scheme)
        : _Tone(Colors.orange, scheme);

    return Column(
      children: [
        // Net Balance Card - Larger
        Card(
          color: net.fill,
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
                      color: net.fg,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Net Balance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: net.fg,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${netBalance >= 0 ? '+' : ''}${formatAmountWithSymbol(netBalance, displayCurrency, locale)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: net.fg,
                      ),
                ),
                if (totalIncome > 0 && currencyTotals.length <= 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Savings Rate: ${formatPercent((totalIncome - totalExpenses) / totalIncome * 100, locale)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: net.fg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if (currencyTotals.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Combined from ${currencyTotals.length} currencies',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: net.fg.withValues(alpha: 0.7),
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
                color: income.fill,
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
                            color: income.fg,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Income',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: income.fg,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+${formatAmountWithSymbol(totalIncome, displayCurrency, locale)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: income.fg,
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
                color: expense.fill,
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
                            color: expense.fg,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: expense.fg,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '-${formatAmountWithSymbol(totalExpenses, displayCurrency, locale)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: expense.fg,
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

/// Scheme-aware fill + foreground pair derived from a semantic colour, so the
/// card reads well in light and dark mode (no fixed Colors.x.shadeNN tints).
class _Tone {
  final Color fill;
  final Color fg;

  _Tone(Color base, ColorScheme scheme)
      : fill = Color.alphaBlend(base.withValues(alpha: 0.16), scheme.surface),
        fg = Color.lerp(base, scheme.onSurface, 0.3)!;
}
