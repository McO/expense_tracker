import '../services/amount_format.dart';
import 'package:flutter/material.dart';
import '../widgets/transaction_style.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../screens/transactions_list_screen.dart';
import '../screens/transaction_detail_screen.dart';

class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onDelete;
  final Function() onViewAll;
  final Function() onRefresh;
  final LocaleLookup localeLookup;

  const RecentTransactions({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onViewAll,
    required this.onRefresh,
    this.localeLookup = deviceLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (transactions.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TransactionsListScreen(localeLookup: localeLookup)),
                  );
                  onRefresh();
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        transactions.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first transaction',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Column(
                children: transactions.map((transaction) {
                  return Dismissible(
                    key: Key(transaction.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
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
                            size: 28,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Transaction'),
                          content: Text('Are you sure you want to delete "${transaction.title}"?'),
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
                      await onDelete(transaction);
                    },
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: transaction.category.toColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: transaction.category.toColor().withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              transaction.category.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        title: Text(
                          transaction.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${transaction.category.name} • ${DateFormat('MMM d, yyyy • h:mm a').format(transaction.date)}',
                            ),
                            if (!transaction.countsInStatistics) ...[
                              const SizedBox(height: 4),
                              const NotCountedMarker(),
                            ],
                          ],
                        ),
                        trailing: Text(
                          transaction.formattedAmountWithSign(localeLookup()),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: transactionColor(transaction),
                              ),
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailScreen(transaction: transaction, localeLookup: localeLookup),
                            ),
                          );

                          if (result == true) {
                            onRefresh();
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
