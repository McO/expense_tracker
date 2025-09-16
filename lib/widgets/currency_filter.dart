import 'package:flutter/material.dart';
import '../models/currency.dart';

class CurrencyFilter extends StatelessWidget {
  final Set<Currency> availableCurrencies;
  final Currency? selectedCurrency;
  final Function(Currency?) onCurrencyChanged;

  const CurrencyFilter({
    super.key,
    required this.availableCurrencies,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (availableCurrencies.isEmpty) {
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
              value: selectedCurrency,
              isDense: true,
              hint: Text(
                'All',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onChanged: onCurrencyChanged,
              items: [
                DropdownMenuItem<Currency?>(
                  value: null,
                  child: Text(
                    'All',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                ...availableCurrencies.map<DropdownMenuItem<Currency?>>((Currency currency) {
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
}
