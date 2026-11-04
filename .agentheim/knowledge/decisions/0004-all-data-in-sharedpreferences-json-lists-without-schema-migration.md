---
id: 0004
title: All data in SharedPreferences as JSON lists, without schema migration
scope: global
status: accepted
date: 2026-11-04
related_tasks: [infrastructure-r5v4d]
---

# ADR 0004: All data in SharedPreferences as JSON lists, without schema migration

## Context
The app holds low-volume, single-device, single-user data. This ADR records the existing persistence choice (verified against `lib/services/` and `lib/models/`) before the vision's new movement kinds (top-up, correction, exchange) change what is stored on an install that already has real records.

## Decision
All data lives in SharedPreferences. No SQLite, Hive or file-based store. Keys and types actually in use:

| Key | Type | Service | Contents |
|---|---|---|---|
| `expenses` | `List<String>` | `expense_service.dart` | JSON-encoded `Expense` |
| `accounts` | `List<String>` | `account_service.dart` | JSON-encoded `Account` |
| `selected_account_id` | `String` | `account_service.dart` | currently selected account id |
| `categories` | `List<String>` | `category_service.dart` | JSON-encoded `Category` |
| `categories_defaults_initialized_v2` | `bool` | `category_service.dart` | one-off seeding flag |
| `custom_currencies` | `List<String>` | `currency_service.dart` | JSON-encoded custom `Currency` |
| `default_currency` | `String` | `settings_service.dart` | currency code, defaults to `USD` |
| `theme_mode` | `int` | `theme_service.dart` | index of `AppThemeMode`, defaults to system |

Every list-backed service follows: read the full list, deserialize, mutate in memory, serialize, write the full list back. An `Expense` stores its category by `categoryId` and its currency by code; both are resolved against the current category and custom-currency lists on read.

There is no schema version and no migration framework. Compatibility rests on tolerant `fromJson`:
- `Expense.fromJson` defaults `currency` to `USD`, `description` to `''`, `type` to `expense`, and `accountId` to the currently selected account id (or `''`). An unknown `categoryId` falls back to the `other` category, then to the first available category, then to the first built-in default. This fallback is intentional and must stay.
- `Account.fromJson` defaults `icon`, `color` and `isDefault`, but `id`, `name` and `currency` are required.
- `Category.fromJson` defaults `isDefault` to `false` and `exportName` to null, but `id`, `name`, `icon` and `color` are required.
- A new or renamed field therefore needs a safe default in `fromJson`; a required field added without one crashes existing installs on read.

Two seeding patterns exist:
- Categories: `categories_defaults_initialized_v2` guards a one-off seed of the default categories. The `_v2` suffix exists because `_v1` seeded a smaller set. Adding default categories means bumping to `_v3` and seeding accordingly.
- Accounts: no flag; `getAccounts` creates a default "Main Account" whenever the stored list is empty.

## Consequences
### Positive
- Zero setup, no native database dependency, trivial to reason about.
### Negative
- Any model change risks crashing existing installs if `fromJson` is not defensive; required fields on `Account` and `Category` have no fallback.
- Changing the meaning of existing records (e.g. reclassifying existing income records as top-ups, the vision's open question) needs an explicit one-off migration step guarded by its own flag, since there is no migration framework.
- Seeding by flag means a bump re-seeds via a full overwrite of `categories` (`_saveCategories(defaults)`), which discards user-made categories unless the migration merges explicitly.
- Whole-list rewrites scale poorly and are not atomic across keys; acceptable at current volume.
### Neutral
- Moving to SQLite/Drift later would be a superseding ADR.

## Alternatives considered
- **SQLite / Drift** — more robust migrations; not needed at this volume.
- **Hive / Isar** — typed storage; adds a dependency for little gain today.

## Note on ADR numbering

Minted provisionally as ADR-0002 in its worker worktree. A sibling task's ADR already claimed that number (or the guess overshot the true count) by the time this task's conductor finalized numbering at squash-merge integration (`lib/adr-allocation.mjs`'s `finalizeAdrNumbering`, ADR-0058) — this ADR was renumbered to **ADR-0004**, the true next-free number on `main` at that moment. No content besides this identity changed.
