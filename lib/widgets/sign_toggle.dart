import 'package:flutter/material.dart';
import '../models/transaction_type.dart';
import 'transaction_style.dart';

/// ± toggle beside the amount field: tapping flips the direction of the
/// transaction (− = money out, + = money in).
class SignToggle extends StatelessWidget {
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  const SignToggle({super.key, required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = directionColor(type);
    return Tooltip(
      message: type.increasesBalance ? 'Money in (tap to flip)' : 'Money out (tap to flip)',
      child: SizedBox(
        height: 56,
        width: 56,
        child: OutlinedButton(
          key: const Key('sign-toggle'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: color,
            side: BorderSide(color: color),
          ),
          onPressed: () => onChanged(type.increasesBalance
              ? TransactionType.expense
              : TransactionType.income),
          child: Text(
            type.increasesBalance ? '+' : '−',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
