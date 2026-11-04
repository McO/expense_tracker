---
id: cash-ledger-s2v1q
title: Add top-up and correction movement kinds to the model, totals and CSV export (no UI)
status: done
type: feature
context: cash-ledger
created: 2026-11-04
completed:
depends_on: []
blocks: [cash-ledger-vsszp]
tags: [movement-kinds, top-up, correction, export, persistence, statistics]
related_adrs: [ADR-0001, ADR-0004, ADR-0005, ADR-0006]
related_research: []
prior_art: [cash-ledger-ngxsa]
---

## Why

The vision distinguishes four movement kinds: spending, income, top-up and correction. Only
spending and income count in statistics; top-ups (ATM withdrawals, currency bought with a card) and
corrections (bringing the app's balance in line with the physical wallet) move the balance but are
not income or spending. Today the code knows only `expense | income`, and the owner logs top-ups and
corrections as income, which inflates income totals and the category breakdown. This task adds the
kinds underneath the UI so the data, totals and export are right before any screen changes
(`cash-ledger-vsszp` builds the UI on top).

## What

- **Movement kinds.** Extend `TransactionType` (`lib/models/transaction_type.dart`) with a top-up kind
  and a correction kind. Amounts stay positive (ADR-0004); a correction's direction (into or out of
  the wallet) must be representable. Recommended shape, unless the code argues otherwise: two
  internal values for the correction (in / out), presented to the UI later as one "Correction"
  kind. Record the chosen representation as an ADR in the ADRS block (scope `cash-ledger`).
- **Persistence (ADR-0004).** `toJson`/`fromJson` round-trip every kind. Existing stored records
  keep reading exactly as before (`expense`/`income`); a missing `type` still defaults as today.
  **No migration:** existing income records that were really top-ups or corrections stay income
  (owner decision, 2026-11-04).
- **Balance vs. statistics.**
  - The wallet balance counts every movement: spending and correction-out subtract; income,
    top-up and correction-in add.
  - Income and expense totals (`total_expense_card.dart` figures and whatever service feeds them),
    the savings rate, and the category breakdown (`category_breakdown.dart`'s data) count **only**
    spending and income; top-ups and corrections are excluded.
- **CSV export (`ExpenseService.buildCSV`, ADR-0005).**
  - Top-up: exported exactly like income today — a positive (unsigned) row with its category's
    effective export name (owner decision: categorize in MoneyMoney by hand).
  - Correction: exported as a signed row (`-` for out, unsigned for in, two decimals, as amounts are
    today) whose `Category` column is a configurable **correction export category**, persisted in
    SharedPreferences (new key, default `"Correction"`) via a settings service getter/setter. The
    settings UI for it is part of `cash-ledger-vsszp`.
  - Column set, header, filtering and file naming stay as ADR-0005 describes.
- **Tests.** Replace the broken boilerplate `test/widget_test.dart` (it references a nonexistent
  `MyApp`) so `flutter test` runs green, and add unit tests (SharedPreferences mocked via
  `SharedPreferences.setMockInitialValues`) covering the criteria below. Record `flutter test` as the
  BC's test command via README_DELTA.

## Acceptance criteria

- [ ] `TransactionType` has top-up and correction (with direction) kinds; every kind round-trips
      through `toJson`/`fromJson`, covered by a unit test.
- [ ] A stored record written before this change (`"type":"income"`, `"type":"expense"`, or no
      `type`) loads with the same kind as before, covered by a unit test.
- [ ] Wallet balance = income + top-ups + corrections-in − spending − corrections-out, covered by a
      unit test.
- [ ] Income/expense totals, savings rate and category breakdown data exclude top-ups and
      corrections, covered by a unit test.
- [ ] `buildCSV` writes a top-up as an unsigned row with its category's export name, and a
      correction as a signed row whose Category column is the configured correction export
      category (default `Correction`), covered by a unit test.
- [ ] The correction export category is persisted under its own SharedPreferences key with a
      getter/setter and default `Correction`, covered by a unit test.
- [ ] `flutter test` passes (broken `test/widget_test.dart` replaced) and `flutter analyze` reports
      no issues.
- [ ] An ADR (scope `cash-ledger`) records how the movement kinds and correction direction are
      represented.
- [ ] No screen behaviour changes beyond totals now excluding top-ups/corrections (no new UI).

## Notes

- Owner decisions (modeling, 2026-11-04): top-ups export like income today; corrections export with
  their own configurable category; corrections are entered as a counted balance (UI task); old
  records are left alone (no migration).
- Exchange (cash for cash) is a nice-to-have and out of scope here.
- Vision open questions 1 (top-up/correction export) and 2 (existing income records) are answered
  by these decisions; strike them in `vision.md` at integration.
- Prior art: `cash-ledger-ngxsa` (ADR-0005, the export contract). Persistence rules: ADR-0004
  (tolerant `fromJson`, no schema migration).

## Verifier note (iteration 1)

**REASONS:**
- Criterion 3 ("Wallet balance = income + top-ups + corrections-in − spending − corrections-out") is covered only for `LedgerTotals.balance` (lib/services/ledger_totals.dart:58-59, test 'wallet balance counts every kind'), which no production code calls. The wallet balance the app actually shows is the home screen's "Net Balance", computed by `TotalExpenseCard` as `totalIncome - totalExpenses` (lib/widgets/total_expense_card.dart:21). After this diff home_screen.dart (~89-95, ~122-128) feeds it `LedgerTotals.statistics(...)` figures, which exclude top-ups and corrections — so the shown balance now omits them, contradicting "The wallet balance counts every movement" and ADR-0006's claim that LedgerTotals is what the home screen uses.
- Same root cause, criterion 9: the Net Balance card is a balance, not an income/expense total; once cash-ledger-vsszp lets users record top-ups/corrections, the balance figure would silently drop them.
- Secondary (fix together if cheap): amount colour is still chosen from `isIncome` (lib/widgets/recent_expenses.dart:168, lib/screens/expenses_list_screen.dart:506, lib/screens/expense_detail_screen.dart:29,33) while `formattedAmountWithSign` uses `increasesBalance` — a top-up/correction-in would show "+$50.00" in red with a trending-down icon.
- Passing context: `flutter test` 8/8 green, `flutter analyze` clean; legacy loading unchanged and tested; CSV signs/category and the `correction_export_category` setting correct and tested; no new UI; no `.agentheim/` paths.

**SUGGESTED_FIX:** Feed the home screen's Net Balance from `LedgerTotals.balance(filteredExpenses)` (e.g. pass a `balance` parameter into `TotalExpenseCard` instead of deriving it from income − expenses); keep savings rate and the income/expense rows on statistics. Add a test that fails if the shown balance excludes top-ups or corrections (e.g. a widget test of `TotalExpenseCard`/home with a top-up record). Optionally switch colour/icon checks from `isIncome` to `increasesBalance`.

**ITERATION_HINT:** likely-fixable

## Outcome

Added top-up and correction (in/out) movement kinds underneath the UI. `TransactionType` (lib/models/transaction_type.dart) now has five values with codes `topup`, `correction_in`, `correction_out`, plus `increasesBalance`/`countsInStatistics`/`isCorrection`; `Expense.signedAmount` is the balance contribution. New pure `LedgerTotals` (lib/services/ledger_totals.dart) gives balance (all kinds) and statistics (spending and income only: totals, savings rate, category and currency maps); `home_screen.dart` now uses it: Net Balance (TotalExpenseCard `balance`) counts all kinds while income/expense rows, savings rate and breakdown exclude top-ups/corrections; amount colours/icons follow `increasesBalance`. `ExpenseService.buildCSV` exports top-ups like income and corrections signed under `SettingsService.getCorrectionExportCategory()` (key `correction_export_category`, default `Correction`; setter `setCorrectionExportCategory`). Legacy records load unchanged; no migration. Broken `test/widget_test.dart` replaced; new `test/movement_kinds_test.dart` covers round-trip, legacy loading, balance, statistics, CSV and the setting. `flutter test` and `flutter analyze` are green. ADR-0006 reported. Vision open questions 1 and 2 are answered by this task and should be struck at integration. No new UI; cash-ledger-vsszp can use `LedgerTotals.balance`, `SettingsService` getter/setter and the type's properties.
