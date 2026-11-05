import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';

/// Difference between counted cash and the current balance, rounded to cents.
double balanceDifference(double balance, double counted) =>
    ((counted - balance) * 100).round() / 100;

/// Opens the Correct balance dialog; on confirm records one transaction in the
/// Correction category signed by the difference (or nothing, with a message,
/// when counted equals the balance). Returns true when one was recorded.
Future<bool> correctBalance(
  BuildContext context, {
  required Account account,
  required double balance,
  TransactionService? transactionService,
}) async {
  final counted = await showDialog<double>(
    context: context,
    builder: (_) => CorrectBalanceDialog(account: account, balance: balance),
  );
  if (counted == null || !context.mounted) return false;
  final difference = balanceDifference(balance, counted);
  final messenger = ScaffoldMessenger.of(context);
  if (difference == 0) {
    messenger.showSnackBar(const SnackBar(
        content: Text('Counted cash equals the balance - nothing to correct')));
    return false;
  }
  final categories = await CategoryService().getCategories();
  final category = categories.firstWhere((c) => c.id == Category.correctionId,
      orElse: () => Category.correction);
  final now = DateTime.now();
  await (transactionService ?? TransactionService()).saveTransaction(Transaction.correction(
    id: now.millisecondsSinceEpoch.toString(),
    difference: difference,
    currency: account.currency,
    date: now,
    accountId: account.id,
    category: category,
  ));
  messenger.showSnackBar(const SnackBar(content: Text('Balance corrected')));
  return true;
}

class CorrectBalanceDialog extends StatefulWidget {
  final Account account;
  final double balance;

  const CorrectBalanceDialog({
    super.key,
    required this.account,
    required this.balance,
  });

  @override
  State<CorrectBalanceDialog> createState() => _CorrectBalanceDialogState();
}

class _CorrectBalanceDialogState extends State<CorrectBalanceDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _counted => double.tryParse(_controller.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final symbol = widget.account.currency.symbol;
    final counted = _counted;
    final diff = counted == null ? null : balanceDifference(widget.balance, counted);
    var diffText = '';
    if (diff != null) {
      diffText = diff == 0
          ? 'No difference'
          : 'Difference: ${diff > 0 ? '+' : '-'}$symbol${diff.abs().toStringAsFixed(2)}';
    }
    return AlertDialog(
      title: const Text('Correct balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current balance: $symbol${widget.balance.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: 'Counted cash',
              prefixText: symbol,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(diffText, key: const Key('correct-balance-difference')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: counted == null ? null : () => Navigator.pop(context, counted),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
