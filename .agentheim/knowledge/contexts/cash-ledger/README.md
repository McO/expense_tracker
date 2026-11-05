# Cash ledger

## Purpose
Recording cash transactions per currency account, keeping each account's balance true to the physical
cash, showing quick-glance cash statistics, and exporting transactions as CSV for MoneyMoney.

## Classification
core

This is the whole reason the app exists (ADR-0001): MoneyMoney sees everything except cash.

## Actors
- **Owner** (sole user) — records transactions on the phone, checks balances and statistics, exports
  date ranges.
- **MoneyMoney** (external, downstream) — imports the CSV into one cash account per currency.

## Ubiquitous language
- **Account** — the cash held in one currency; mirrors exactly one MoneyMoney cash account.
  *`Account` in code (`lib/models/account.dart`). Earlier docs, ADRs and tasks say *wallet*.*
- **Transaction** — any change to an account's balance: a signed amount (positive = money in, negative = money out) plus a category. There are no transaction kinds; Top-up (cash entering from the owner's own money) and Correction (aligning the balance with the physical wallet) are ordinary built-in categories with `countsInStatistics: false`. Whether a transaction counts as spending/income is decided by its category's flag, so the owner chooses. *Exchange (nice-to-have)* — cash swapped for cash; leaves one account and enters another at the rate actually received.
  *Current code (ADR-0007, supersedes ADR-0006): `TransactionType` = `expense | income` (direction, amount stays positive; stored codes `topup`, `correction_in`, `correction_out` from the interim build still load as income/income/expense in the Top-up/Correction category). `Expense.signedAmount`, `Expense.correction(difference: ...)` builds a correction from a signed difference. `LedgerTotals` computes balance (every transaction by sign) and statistics (only categories with `countsInStatistics`).
- **Balance** — sum of all transactions in an account; should equal the physical cash.
- **Category** — what a transaction was for. Carries a `countsInStatistics` flag (default true); the seeded Top-up (`Category.topUpId`) and Correction (`Category.correctionId`) categories have it false. They are ensured non-destructively by `CategoryService` under their own flag (`categories_ledger_ensured_v1`).
- **Export name** — the MoneyMoney category a category maps to on export (`Category.exportName`); the CSV Category column always uses it, corrections included (the former correction export category setting is removed).
- **Currency** — an account's currency; predefined or user-defined custom.
- **Export** — a CSV of one account's transactions over a chosen date range, saved to a location the owner picks in Android's system save dialog (ADR-0009); the app holds no storage permissions.
- **Account check / Burn rate / Spending mix / Leftover foreign cash** — the four quick-glance
  statistics (see vision).
- **Import** — reading one of the app's own CSV exports back into a chosen account.
- **Decimal places** — the number of minor-unit digits (0-3) of a currency. Built-ins use ISO 4217 (JPY, KRW = 0, others 2); custom currencies choose it (default 2) and can edit it later. `Currency.roundAmount` rounds an amount to it.

## Aggregates
- **Account** — has exactly one currency; its balance is the sum of its transactions. Deleting an account deletes its transactions, after a confirm that names how many.
- **Transaction** — amount is stored positive and its direction (in/out, from the entered sign) decides the balance effect; its category decides whether it counts in statistics; belongs to exactly one account (an exchange touches two). Its currency is always its account's; a stored currency is only a fallback when the account can't be resolved.
- **Category** — default categories are seeded once; a transaction whose category no longer exists
  falls back to "other" (intentional, keep it).

## Key events
- Transaction recorded / edited / deleted
- Export produced

## Key commands
- Record transaction, edit transaction, delete transaction
- Manage accounts, categories, currencies
- Export account transactions for a date range
- Correct balance — enter the counted cash for an account; records one Correction-category transaction signed by the difference (nothing when equal)
- Enter transaction with a ± toggle beside the amount (default −); Top-up is just the Top-up category with +
- **Statistics** — read-only screen (home drawer) for the selected account: balance with Correct balance, burn rate (daily average = counting spending / days elapsed, "lasts ~N days" = floor(balance / average), hidden when average is 0 or balance <= 0; last-7-days bars) and spending mix, over This month (default) or Last 7 days. Computed by the pure `CashStatistics`.
- Import CSV — read one of the app's own exports (header `Date,Title,Category,Amount,Currency,Description`) into a chosen account; a currency different from the account's rejects the whole file; exact duplicates (same day, signed amount, title, category already in the account) are skipped; unknown categories map to Other; invalid rows are reported with line numbers; a preview is confirmed before one save through TransactionsStore

## Frontend rule — styleguide gate
This BC has a UI. **Every frontend task in this BC must `depends_on: [design-system-001]`**
and may not be promoted until the owner has signed off on the styleguide.

## Test command
- `flutter test` (static check: `flutter analyze`). SharedPreferences is mocked with `SharedPreferences.setMockInitialValues({})`.

## Relationships with other contexts
- **Customer of:** infrastructure (persistence, platform, build).
- **Conformist to:** MoneyMoney's CSV import format.
- **Customer of:** design-system (UI tokens and components).

## Open questions
- ~~How top-ups and corrections should appear in the CSV so MoneyMoney treats a top-up as a
  transfer (open since 2026-11-04).~~ — resolved 2026-11-04 by cash-ledger-s2v1q (ADR-0006): top-ups export like income, corrections signed under their own configurable category; old records are not migrated.
- ~~How existing income records that are really top-ups or corrections migrate, given no schema
  migration (open since 2026-11-04).~~ — resolved 2026-11-04 by cash-ledger-s2v1q (ADR-0006): top-ups export like income, corrections signed under their own configurable category; old records are not migrated.
- ~~Default burn-rate period (open since 2026-11-04).~~ — resolved 2026-11-05: this month (see cash-ledger-bktw5).
