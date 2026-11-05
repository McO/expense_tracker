---
id: cash-ledger-ydqbw
title: Use Account and Transaction consistently in code and on screen (no Wallet, Movement or Expense-for-record)
status: done
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

## Verifier note (iteration 1)

**REASONS:**
- The blanket "expense" → "transaction" replace also hit places where "expense" means the outgoing direction:
  - `test/transaction_kinds_test.dart:35`: "TransactionType has only transaction and income".
  - `test/transaction_kinds_test.dart:46`: "…income/income/transaction…".
  - `test/balance_summary_card_colors_test.dart:64`: "income stays green, transaction stays red".
  - `lib/services/ledger_totals.dart:6` doc comment: "income/transaction/category".
  - `lib/services/category_service.dart:30`: "works for both transaction and income".
- Minor: `test/account_currency_test.dart:56` says "a account" (should be "an account").
- Minor: the `AGENTS.md` tree still lists `transaction_type_selector.dart`, which doesn't exist. It also misses `statistics_screen.dart`, `cash_statistics.dart`, `ledger_totals.dart`, `sign_toggle.dart` and `correct_balance_dialog.dart`.
- Everything else passes: the greps, the unchanged stored keys/JSON, the CSV test, the styleguide edit, and 54 tests plus a clean analyze. The icon swap is accepted.

**SUGGESTED_FIX:** Change the five direction-sense spots back to "expense" and fix "a account". Bring the `AGENTS.md` directory tree up to date with `lib/`.

**ITERATION_HINT:** likely-fixable

## Verifier note (iteration 2)

**REASONS:**
- `lib/models/category.dart:114` still reads "both transactions and income"; it was "both expenses and income" (the direction sense, missed in the iteration-1 list).
- The `AGENTS.md` tree still leaves out `lib/widgets/transaction_style.dart` (renamed from `movement_style.dart` by this task).
- Everything else passes: the iteration-1 fixes, the greps, 54 tests and a clean analyze.

**SUGGESTED_FIX:** Change `category.dart:114` back to "both expenses and income". Add `transaction_style.dart` under `widgets/` in the `AGENTS.md` tree.

**ITERATION_HINT:** likely-fixable

## Outcome

Pure rename; behaviour is unchanged. `Expense` → `Transaction` (`lib/models/transaction.dart`), plus `TransactionService`, the Add/Edit transaction screens, `TransactionDetailScreen`, `TransactionsListScreen`, `RecentTransactions`, `BalanceSummaryCard` (was `TotalExpenseCard`) and `transaction_style.dart`. Methods became `getTransactions`, `saveTransaction` and so on, and the tests were renamed (`account_currency_test`, `transaction_kinds_test`, `transaction_ui_test`, `balance_summary_card_colors_test`). Every wallet/movement identifier and every on-screen wallet/movement string now says account/transaction. The `account_balance_wallet*` icons became `account_balance*`.

Kept on purpose:
- "expense" where it means the outgoing direction: `TransactionType.expense`, `isExpense`, `totalExpenses`, `categoryExpenseTotal`, and the summary card's "Income"/"Expenses";
- the type label "Expense";
- the app title "Expense Tracker" and `ExpenseTrackerApp`;
- the stored key `expenses`, which moves in cash-ledger-k6d4w.

The CSV file name is now `transactions_<from>_<to>.csv` (`csvExportFileName`), covered by `test/transaction_naming_test.dart`, which also checks the screen wording. `AGENTS.md` and the styleguide source use the new names, and the `AGENTS.md` tree matches `lib/`. `flutter test` passes 54 tests and `flutter analyze` is clean. Passed verification on iteration 3: iterations 1 and 2 fixed places where the blanket rename had turned the outgoing-direction sense of "expense" into "transaction".
