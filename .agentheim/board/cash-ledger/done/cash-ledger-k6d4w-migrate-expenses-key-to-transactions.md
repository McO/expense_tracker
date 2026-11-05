---
id: cash-ledger-k6d4w
title: Store transactions under the `transactions` key, migrating the old `expenses` key once
status: done
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [cash-ledger-ydqbw]
blocks: []
tags: [persistence, migration, naming, ubiquitous-language]
related_adrs: [ADR-0004, ADR-0008]
related_research: []
prior_art: [cash-ledger-ydqbw]
---

## Why

With Account + Transaction as the language (owner decision, 2026-11-05), the one persisted name that
still disagrees is the SharedPreferences key `expenses`, which holds the transactions. The owner
chose to rename it with a one-time migration rather than keep the old key. ADR-0004 says data lives
in SharedPreferences JSON lists *without schema migration*, so this needs a decision record.

## What

- `TransactionService` reads and writes the key `transactions`.
- **One-time migration** on first access after the update: if `transactions` is absent and
  `expenses` is present, copy the list to `transactions` unchanged (same JSON per entry), then
  remove `expenses`. Guard it with a flag key (e.g. `transactions_key_migrated_v1`) so it runs once.
  If both keys exist (e.g. an interrupted earlier run), `transactions` wins and `expenses` is
  removed. A fresh install with neither key just starts empty.
- Nothing else in the stored JSON changes (`accountId`, `type: expense|income`, field names stay).
- Write an ADR amending ADR-0004: keys may be renamed through a guarded, idempotent, copy-then-delete
  migration; field-level schema changes still rely on `fromJson` defaults.
- Update the persistence key table in `AGENTS.md`.

## Acceptance criteria

- [ ] With only `expenses` stored, the first load returns the same transactions, after which
      `transactions` holds them, `expenses` is gone and the flag is set. Covered by a unit test.
- [ ] A second load does not migrate again and returns the same data. Covered by a unit test.
- [ ] With both keys present, `transactions` is kept and `expenses` removed. Covered by a unit test.
- [ ] A fresh install (no keys) works and writes only `transactions`. Covered by a unit test.
- [ ] Add, edit, delete and account deletion read and write `transactions`. Covered by the existing
      service and widget tests updated to the new key.
- [ ] An ADR amending ADR-0004 records the key-rename migration rule.
- [ ] `AGENTS.md` persistence table lists `transactions` and the flag, not `expenses`.
- [ ] `flutter test` and `flutter analyze` pass.

## Notes

- Owner decision 2026-11-05: migrate `expenses` → `transactions` (not keep the old key).
- Data loss is the main risk on the owner's real install: copy before delete, never transform the
  entries, and keep the migration idempotent.

## Verifier note (iteration 1)

**REASONS:**
- Check 6c (mechanize-or-drop, ADR-0059): ADR-0008 sets a rule for all future key renames. The task ships no enforcement for that rule and has no explicit "prose-only, unenforced" marker.
- Checks 1–5, 6b and 7 pass:
  - All four migration scenarios are asserted.
  - Copy-before-delete ordering holds and entries are copied verbatim.
  - The only `'expenses'` literal left is `TransactionsStore.legacyKey`.
  - 57 tests pass and analyze is clean.
- Check 6 is only partly verified, because the verifier saw only a summary of the ADR (the full body was in the worker's return).

**SUGGESTED_FIX:** Add an explicit "prose-only, unenforced" marker for the ADR-0008 key-rename rule to the Outcome (and to the ADR's Consequences), or ship a check. Optionally, strengthen the no-re-migration test: put `expenses` back after the first load and assert it is not copied again.

**ITERATION_HINT:** likely-fixable

## Outcome

Added `TransactionsStore` (`lib/services/transactions_store.dart`). It owns the `transactions` key and the one-time copy-then-delete migration from `expenses`, guarded by the `transactions_key_migrated_v1` flag. If both keys exist, `transactions` is kept; a fresh install writes only `transactions`. `TransactionService` and `AccountService` (account deletion) both go through it.

Tests in `test/transactions_key_migration_test.dart` cover all four cases, including that an `expenses` list reappearing after the migration is not copied in. `test/account_currency_test.dart` uses the new key, and the `AGENTS.md` key table is updated. ADR-0008 (amends ADR-0004) records the key-rename rule. That rule is prose-only, unenforced: no lint or test catches a future rename that bypasses it. `flutter test` (57 tests) and `flutter analyze` pass. Passed verification on iteration 2, after the prose-only marker was added and the no-re-migration test strengthened.
