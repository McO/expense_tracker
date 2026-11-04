---
id: ADR-0007
title: Movements are signed amounts with a per-category statistics flag
scope: cash-ledger
status: accepted
date: 2026-11-04
related_tasks: [cash-ledger-qjysm]
related_adrs: [ADR-0004, ADR-0005, ADR-0006]
supersedes: [ADR-0006]
---

# ADR-0007: Movements are signed amounts with a per-category statistics flag

## Context

ADR-0006 modelled top-up and correction as `TransactionType` kinds. After eye-checking the UI built on it, the owner redesigned the model: a movement is a signed amount plus a category; Top-up and Correction are ordinary categories; the owner decides per category whether it counts in statistics. The vision's rule stays: top-ups and corrections move the balance but are never spending or income.

## Decision

- `TransactionType` is `expense | income` again. It is direction only, set from the sign the owner enters; amount stays stored positive (ADR-0004, no record migration).
- Interim codes `topup`, `correction_in`, `correction_out` still load: as income, income, expense; `topup` records get the Top-up category and `correction_*` the Correction category unless they carry another existing category id.
- `Category.countsInStatistics` (bool, default true, missing in JSON means true). `Expense.countsInStatistics` delegates to its category. `LedgerTotals.statistics` filters on it; `LedgerTotals.balance` sums every movement by sign.
- Built-in categories `Category.topUp` (id `topup`) and `Category.correction` (id `correction`), flag false, are kept in `Category.ledgerCategories`, separate from `defaultCategories`. `CategoryService` ensures them with an idempotent insert-if-missing-by-id step guarded by its own flag `categories_ledger_ensured_v1`. The `categories_defaults_initialized_v2` flag is NOT bumped: that would overwrite user categories wholesale (ADR-0004).
- `Expense.correction(difference: ...)` builds a correction movement from a signed difference.
- Export (ADR-0005): every row is signed by direction; the Category column is the category's effective export name. The `correction_export_category` setting and its SettingsService methods are removed; the Correction category's own export name replaces it.

## Consequences

- The UI (cash-ledger-vsszp) can offer a +/- toggle and a flag editor without any further model change.
- A user who deletes or renames the seeded categories is not overridden: the ensure step runs once.
- ADR-0006 is superseded.
