---
id: ADR-0006
title: Movement kinds are TransactionType values; correction direction is two internal values
scope: cash-ledger
status: accepted
date: 2026-11-04
related_tasks: [cash-ledger-s2v1q]
related_adrs: [ADR-0001, ADR-0004, ADR-0005]
---

# ADR-0006: Movement kinds are TransactionType values; correction direction is two internal values

## Context

The vision distinguishes spending, income, top-up and correction. Only spending and income count in
statistics; all four move the wallet balance. The code knew only `expense | income`. Amounts must
stay positive and storage tolerant with no migration (ADR-0004); the CSV contract is ADR-0005.

## Decision

- `TransactionType` is extended to `expense, income, topUp, correctionIn, correctionOut`. Direction
  of a correction is carried by the two values (amount stays positive); the UI will present them as
  one "Correction" kind (`name` returns "Correction" for both).
- Stored codes: `expense`, `income` (unchanged), `topup`, `correction_in`, `correction_out`.
  `fromCode` keeps its fallback to `expense` for unknown/missing codes, so legacy records load as
  before. No migration: existing income records that were really top-ups/corrections stay income.
- Derived properties on the type: `increasesBalance` (income, top-up, correction-in) and
  `countsInStatistics` (expense, income only). `Expense.signedAmount` follows `increasesBalance`
  and is the wallet balance contribution. `LedgerTotals` is the single pure place for balance and
  statistics aggregation; the home screen feeds the shown Net Balance from `LedgerTotals.balance` and
  the income/expense rows, savings rate and breakdown from `LedgerTotals.statistics`.
- CSV (extends ADR-0005, same columns/header/filtering): top-up is an unsigned row with its
  category's effective export name; a correction is a signed row (`-` for out) whose Category column
  is the correction export category, stored in SharedPreferences key `correction_export_category`
  (default `Correction`, blank falls back to default) via `SettingsService`.

## Consequences

- Alternatives rejected: a single `correction` value plus a signed amount (breaks "amounts always
  positive"); a separate direction field (extra schema, more fromJson defaults).
- Any code switching on `TransactionType` must handle all five values; existing screens still treat
  non-expense as green/"income-like" until `cash-ledger-vsszp` adds UI for the new kinds.
