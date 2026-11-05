---
id: cash-ledger-ydqbw
title: Use Account and Transaction consistently in code and on screen (no Wallet, Movement or Expense-for-record)
status: doing
type: refactor
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001]
blocks: [cash-ledger-k6d4w]
tags: [naming, ubiquitous-language, cleanup, ui-copy]
related_adrs: [ADR-0003, ADR-0004, ADR-0007]
related_research: []
prior_art: [cash-ledger-apzzm, cash-ledger-f150f, cash-ledger-qjysm]
---

## Why

The owner decided (modeling, 2026-11-05) that the ubiquitous language is **Account** and
**Transaction** — not Wallet, not Movement. The vision and the cash-ledger README now say so. The app
and the code still mix four words for the same things: screens say "Add movement", "Recent
Transactions", "All Expenses", "Delete Expense", "Add wallet"; the code has `Expense`,
`ExpenseService`, `movement_style.dart`, `RecentExpenses`, `TotalExpenseCard`, tests named
`movement_*` / `wallet_*`. A record is a *transaction*; "expense" stays only as the outgoing
direction (`TransactionType.expense`, the summary card's "Expenses" total).

## What

- **Code names.** Rename the record type and everything named after it to Transaction, including
  file names:
  - `Expense` → `Transaction` (`lib/models/expense.dart` → `transaction.dart`). If `Transaction`
    clashes with an imported Flutter/Dart name, resolve it with an import prefix or `hide`, not by
    picking another word.
  - `ExpenseService` → `TransactionService`, `AddExpenseScreen` → `AddTransactionScreen`,
    `EditExpenseScreen` → `EditTransactionScreen`, `ExpenseDetailScreen` →
    `TransactionDetailScreen`, `ExpensesListScreen` → `TransactionsListScreen`,
    `RecentExpenses` → `RecentTransactions`, `movement_style.dart` → `transaction_style.dart`,
    and their files. `TotalExpenseCard` → a name for what it shows (e.g. `BalanceSummaryCard`).
  - Local variables, parameters, methods (`getExpenses` → `getTransactions`, `addExpense`, …) and
    comments follow. Any remaining `wallet` / `movement` identifiers or comments become
    `account` / `transaction`.
  - `Account`, `AccountService`, `TransactionType` (`expense | income`) keep their names.
  - Test files and test names follow (e.g. `wallet_currency_test.dart` →
    `account_currency_test.dart`, `movement_*_test.dart` → `transaction_*_test.dart`).
- **On-screen copy.** Every user-visible string says account / transaction: "Add transaction",
  "Edit transaction", "Transaction details", "Transaction added/updated successfully!", "Recent
  Transactions", "All Transactions", "Delete Transaction", "No transactions yet", "Add account",
  "This also deletes N transaction(s).", the category flag help text, error messages. The
  "Transaction Type" filter and detail field keep that label with Income / Expense values (owner
  decision). The summary card keeps "Income" / "Expenses" (directions, not records). The app title
  stays "Expense Tracker".
- **CSV file name** becomes `transactions_<from>_<to>.csv` (owner decision); CSV columns and content
  are unchanged (ADR-0005).
- **Out of scope:** persisted keys and JSON fields (`expenses`, `accounts`, `accountId`, type
  values) stay exactly as they are here — the `expenses` → `transactions` key move is
  `cash-ledger-k6d4w`. Behaviour is unchanged.
- Update `AGENTS.md` (directory tree, model names) to the new names.

## Acceptance criteria

- [ ] `grep -rniE "wallet|movement" lib test` finds nothing.
- [ ] No class, file, method or variable in `lib/` or `test/` names a record "expense": `grep -rnE
      "\bExpense\b|ExpenseService|getExpenses|AddExpense|EditExpense|RecentExpenses|expense_service|expense\.dart"
      lib test` finds nothing. `TransactionType.expense` and the stored `'expenses'` key may remain.
- [ ] No user-visible string says "movement", "wallet", or uses "expense(s)" for a record; the
      remaining "Expense"/"Expenses" strings are only the direction (type value, summary total) and
      the app title. Covered by widget tests that find "Add transaction", "Recent Transactions",
      "All Transactions" and "Add account".
- [ ] Export writes `transactions_<from>_<to>.csv`, covered by a test.
- [ ] Existing stored data still loads unchanged (same keys and JSON), covered by the existing
      tests.
- [ ] `AGENTS.md` names match the code.
- [ ] `flutter test` and `flutter analyze` pass.

## Notes

- Owner decisions 2026-11-05: language is Account + Transaction; "Transaction Type" label kept;
  app title kept; CSV name becomes `transactions_…`; stored key migrated in a separate task.
- Vision, cash-ledger README and styleguide were already switched to Account / Transaction in the
  modeling commit. ADRs, research and done tasks keep their historical wording.
- The styleguide source names files (e.g. `lib/widgets/recent_expenses.dart`); update those paths
  to the renamed files (styleguide-source carve-out).
- Pure rename; prefer `git mv`-equivalent file moves (the conductor stages deletions + additions).
