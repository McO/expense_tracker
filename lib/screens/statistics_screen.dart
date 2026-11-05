import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../services/cash_statistics.dart';
import '../services/expense_service.dart';
import '../widgets/correct_balance_dialog.dart';

/// Quick-glance cash statistics for one wallet (styleguide section 4).
class StatisticsScreen extends StatefulWidget {
  final Account account;

  /// Injectable for tests; defaults to now.
  final DateTime? today;

  const StatisticsScreen({super.key, required this.account, this.today});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ExpenseService _expenseService = ExpenseService();
  StatsPeriod _period = StatsPeriod.thisMonth;
  CashStatistics? _stats;

  DateTime get _today => widget.today ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expenses = await _expenseService.getExpenses();
    if (!mounted) return;
    setState(() {
      _stats = CashStatistics.compute(
        expenses: expenses,
        accountId: widget.account.id,
        today: _today,
        period: _period,
      );
    });
  }

  String _money(double v) =>
      '${widget.account.currency.symbol}${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: Text('Statistics - ${widget.account.name}')),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _balanceCard(stats),
                const SizedBox(height: 16),
                _PeriodControl(
                  period: _period,
                  onChanged: (p) {
                    _period = p;
                    _load();
                  },
                ),
                const SizedBox(height: 16),
                _burnRateCard(stats),
                const SizedBox(height: 16),
                _mixCard(stats),
              ],
            ),
    );
  }

  Widget _card(String title, List<Widget> children) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _balanceCard(CashStatistics stats) {
    final theme = Theme.of(context);
    return _card('Leftover cash', [
      Text(_money(stats.balance),
          key: const Key('stats-balance'),
          style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: stats.balance < 0 ? Colors.red : theme.colorScheme.primary)),
      const SizedBox(height: 4),
      Text('In your ${widget.account.currency.code} wallet',
          style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('stats-correct-balance'),
        icon: const Icon(Icons.tune),
        label: const Text('Correct balance'),
        onPressed: () async {
          await correctBalance(context,
              account: widget.account, balance: stats.balance);
          await _load();
        },
      ),
    ]);
  }

  Widget _burnRateCard(CashStatistics stats) {
    final theme = Theme.of(context);
    final lasts = stats.lastsDays;
    return _card('Burn rate', [
      Text('${_money(stats.dailyAverage)} / day',
          key: const Key('stats-daily-average'),
          style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
      const SizedBox(height: 4),
      Text(
          'Spent ${_money(stats.spending)} over ${stats.daysElapsed} '
          '${stats.daysElapsed == 1 ? 'day' : 'days'}',
          style: theme.textTheme.bodySmall),
      if (lasts != null) ...[
        const SizedBox(height: 4),
        Text('At this pace your ${_money(stats.balance)} lasts ~$lasts days',
            key: const Key('stats-lasts'), style: theme.textTheme.bodySmall),
      ],
      const SizedBox(height: 16),
      SizedBox(
        height: 140,
        child: _DailyBars(
          key: const Key('stats-bars'),
          values: stats.last7Days,
          today: _today,
          label: _money,
        ),
      ),
    ]);
  }

  Widget _mixCard(CashStatistics stats) {
    final theme = Theme.of(context);
    final mix = stats.spendingMix;
    final max = mix.isEmpty ? 0.0 : mix.first.value;
    return _card('Spending mix', [
      if (mix.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text('No spending in this period',
                key: const Key('stats-mix-empty'),
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        )
      else
        for (final entry in mix) _mixRow(entry.key, entry.value, max),
    ]);
  }

  Widget _mixRow(Category category, double amount, double max) {
    final color = category.toColor();
    return Padding(
      key: Key('mix-${category.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(category.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: max > 0 ? amount / max : 0,
                    minHeight: 8,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(_money(amount),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Segmented control styled like the transaction type toggle (radius 12,
/// 2 px border when selected).
class _PeriodControl extends StatelessWidget {
  final StatsPeriod period;
  final ValueChanged<StatsPeriod> onChanged;

  const _PeriodControl({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _segment(context, 'This month', StatsPeriod.thisMonth),
        const SizedBox(width: 8),
        _segment(context, 'Last 7 days', StatsPeriod.last7Days),
      ],
    );
  }

  Widget _segment(BuildContext context, String label, StatsPeriod value) {
    final scheme = Theme.of(context).colorScheme;
    final selected = period == value;
    return Expanded(
      child: InkWell(
        key: Key('period-${value.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? scheme.primary : scheme.onSurface)),
        ),
      ),
    );
  }
}

/// Seven vertical bars, today highlighted, no axes or gridlines, a value
/// label above the tallest bar and day initials beneath.
class _DailyBars extends StatelessWidget {
  final List<double> values; // oldest first, last = today
  final DateTime today;
  final String Function(double) label;

  const _DailyBars(
      {super.key,
      required this.values,
      required this.today,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = values.fold(0.0, (m, v) => v > m ? v : m);
    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final tallest = max > 0 ? values.lastIndexOf(max) : -1;
    return LayoutBuilder(builder: (context, c) {
      const labelH = 18.0, initialH = 18.0;
      final barArea = c.maxHeight - labelH - initialH;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: labelH,
                    child: i == tallest
                        ? FittedBox(
                            child: Text(label(values[i]),
                                style: const TextStyle(fontSize: 11)))
                        : null,
                  ),
                  Container(
                    key: Key('bar-$i'),
                    width: 20,
                    height: max > 0
                        ? (barArea * values[i] / max).clamp(2.0, barArea)
                        : 2.0,
                    decoration: BoxDecoration(
                      color: i == values.length - 1
                          ? scheme.primary
                          : Colors.red.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(
                    height: initialH,
                    child: Center(
                      child: Text(
                          initials[DateTime(today.year, today.month,
                                      today.day - (values.length - 1 - i))
                                  .weekday -
                              1],
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
