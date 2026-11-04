---
id: cash-ledger-qjysm
title: Replace the top-up/correction kinds with signed amounts plus a per-category "count in statistics" flag
status: done
type: feature
context: cash-ledger
created: 2026-11-04
completed:
depends_on: []
blocks: [cash-ledger-vsszp]
tags: [movement-kinds, top-up, correction, category, statistics, export, persistence]
related_adrs: [ADR-0004, ADR-0005, ADR-0006, ADR-0007]
related_research: []
prior_art: [cash-ledger-s2v1q]
---

## Why

`cash-ledger-s2v1q` (ADR-0006) added top-up and correction as their own `TransactionType` kinds. After
eye-checking the UI built on it, the owner redesigned the model (2026-11-04): a movement is simply a
**signed amount plus a category**. Positive is money in, negative is money out; there is no
Expense/Income/Top-up selector. Top-up and Correction are ordinary categories. What keeps them out of
the statistics is a **per-category "count in statistics" flag**, so the owner decides which
categories count. The vision's rule still holds: top-ups and corrections move the balance but never
count as spending or income.

## What

- **Direction from the sign.** The model's notion of direction stays the stored `type`
  (`expense` = out, `income` = in) with a positive `amount` (ADR-0004, no migration of existing
  records); it is now set purely from the sign the owner enters, not from a separate kind choice.
  Remove `topUp`, `correctionIn` and `correctionOut` from `TransactionType`.
- **Interim codes stay readable.** Records saved with the codes `topup`, `correction_in` or
  `correction_out` (possible on test installs of the s2v1q build) load as `income`, `income` and
  `expense` respectively; `topup` records get the Top-up category, `correction_*` records the
  Correction category, unless they already carry another category id.
- **Category flag.** `Category` gains `countsInStatistics` (bool, default `true`, persisted;
  `fromJson` defaults missing values to `true`, ADR-0004). Editing it is UI work in
  `cash-ledger-vsszp`.
- **Seed Top-up and Correction categories, non-destructively.** Add built-in "Top-up" and
  "Correction" categories with `countsInStatistics: false` (sensible icons/colours; export names
  default to their names). Existing installs must get them **without** losing or overwriting any
  user category: do not bump the `categories_defaults_initialized_v2` flag with a wholesale
  `_saveCategories(defaults)` (ADR-0004 warns that overwrites user categories). Use a separate,
  idempotent "ensure these categories exist" step guarded by its own flag, inserting only missing
  ones by id.
- **Statistics.** `LedgerTotals.statistics` (income/expense totals, savings rate, category and
  currency maps) counts only movements whose category has `countsInStatistics == true`.
  `LedgerTotals.balance` counts every movement by sign. The home screen keeps using both as today.
- **Export (ADR-0005).** Every row is signed by direction as today; the Category column is the
  category's effective export name for every movement, corrections included. Remove the
  correction export category setting (`SettingsService.getCorrectionExportCategory` /
  `setCorrectionExportCategory`, key `correction_export_category`); its job is now the Correction
  category's own export name.
- **Supersede ADR-0006** with a new ADR (scope `cash-ledger`) recording this model, and mark 0006
  `superseded_by` it.
- Keep `flutter test` and `flutter analyze` green; update or remove the s2v1q tests that assert the
  removed kinds.

## Acceptance criteria

- [ ] `TransactionType` has only `expense` and `income`; every stored movement round-trips through
      `toJson`/`fromJson`, covered by a unit test.
- [ ] Records with codes `topup`, `correction_in`, `correction_out` load as income/income/expense in
      the Top-up/Correction categories (when they had no other category), covered by a unit test.
- [ ] Legacy records (`income`, `expense`, missing `type`) load exactly as before, covered by a unit
      test.
- [ ] `Category.countsInStatistics` persists, and a stored category without the field loads as
      `true`, covered by a unit test.
- [ ] Top-up and Correction categories exist with `countsInStatistics: false` after first launch on
      a fresh install **and** on an install with existing user categories, which all survive
      unchanged; running the step twice adds nothing. Covered by unit tests.
- [ ] Statistics exclude movements in categories with `countsInStatistics == false`; balance counts
      them, covered by a unit test.
- [ ] CSV writes a correction as a signed row whose Category is the Correction category's effective
      export name, covered by a unit test; the `correction_export_category` setting is gone.
- [ ] A new ADR (scope `cash-ledger`) records the model and ADR-0006 is marked superseded.
- [ ] `flutter test` and `flutter analyze` pass.

## Notes

- Owner decisions (2026-11-04, after eye-checking the s2v1q/vsszp build): signed amount via a ±
  toggle (UI, `cash-ledger-vsszp`); Top-up and Correction are categories; a per-category flag decides
  what counts in statistics; corrections are a category too.
- Prior art: `cash-ledger-s2v1q` (done) — reuse `LedgerTotals`, `Expense.signedAmount`, and the
  balance-vs-statistics split; replace its kind-based exclusion with the category flag.
- The bounced UI work is salvaged at `.agentheim/salvage/cash-ledger-vsszp-bounced.patch` (for
  reference only; it targets the old kinds).

## Outcome

Implemented the signed-amount model (ADR-0007, supersedes ADR-0006). `TransactionType` is back to `expense | income`; interim codes `topup`/`correction_in`/`correction_out` load as income/income/expense with the Top-up/Correction category. `Category.countsInStatistics` (default true) persists; `LedgerTotals.statistics` filters on it while `balance` counts everything. Top-up and Correction categories (`Category.topUp`/`Category.correction`, ids `Category.topUpId`/`correctionId`, `Category.ledgerCategories`) are ensured non-destructively by `CategoryService` under flag `categories_ledger_ensured_v1`. `Expense.correction(difference:)` builds a correction from a signed difference for vsszp. CSV Category uses the category's export name; the `correction_export_category` setting is removed. No UI change; the type selector stays Expense/Income. `flutter test` and `flutter analyze` are green.

Conductor action: set ADR-0006's frontmatter to `status: superseded` and `superseded_by: [ADR-0007]` (I cannot edit under `.agentheim/`).

Key files: lib/models/category.dart, lib/models/expense.dart, lib/models/transaction_type.dart, lib/services/category_service.dart, lib/services/expense_service.dart, lib/services/ledger_totals.dart, lib/services/settings_service.dart, test/movement_kinds_test.dart, test/balance_display_test.dart.
