---
id: ADR-0008
title: Persisted keys may be renamed by a guarded copy-then-delete migration
scope: cash-ledger
status: accepted
date: 2026-11-05
related_tasks: [cash-ledger-k6d4w]
related_adrs: [ADR-0004]
amends: [ADR-0004]
---

# ADR-0008: Persisted keys may be renamed by a guarded copy-then-delete migration

## Context

ADR-0004 keeps all data in SharedPreferences JSON lists without schema migration. With Account and Transaction as the ubiquitous language, the key `expenses` (holding transactions) was the one persisted name still disagreeing. The owner has a real install with data, so a rename must not lose anything.

## Decision

Amends ADR-0004. A persisted key may be renamed through a migration that is:

- **Guarded** by a flag key (`transactions_key_migrated_v1`), so it runs once.
- **Idempotent**: if the new key is absent and the old present, the list is copied unchanged (same JSON per entry, never transformed); if both exist, the new key wins. The old key is removed only after the copy.
- **Owned in one place**: `TransactionsStore` (lib/services/transactions_store.dart) holds the key name and the migration; every reader/writer (TransactionService, AccountService) goes through it.

Field-level schema changes still rely on `fromJson` defaults, as in ADR-0004; no general migration framework is introduced.

## Consequences

Stored key is now `transactions`; `expenses` disappears after first access post-update. Future key renames follow this pattern with their own `_vN` flag. This rule is prose-only, unenforced: no lint or test catches a future key rename that bypasses it.
