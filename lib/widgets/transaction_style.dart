import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';

/// + green, − red (styleguide). Scheme-aware shades so both modes read well.
Color directionColor(TransactionType type) =>
    type.increasesBalance ? Colors.green : Colors.red;

/// Colour of a transaction's signed amount.
Color transactionColor(Transaction e) => directionColor(e.type);

/// Small label for transactions that do not count as income/spending.
const String notCountedLabel = 'Not counted';

/// Neutral, scheme-aware colour used to mark non-counting transactions.
Color notCountedColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

/// Chip-like marker, shown only for transactions outside the statistics.
class NotCountedMarker extends StatelessWidget {
  const NotCountedMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final color = notCountedColor(context);
    return Container(
      key: const Key('not-counted-marker'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(notCountedLabel,
          style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
