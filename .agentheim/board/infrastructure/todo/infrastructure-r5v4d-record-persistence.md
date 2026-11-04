---
id: infrastructure-r5v4d
title: Record the existing persistence as an ADR (SharedPreferences JSON lists, no schema migration)
status: todo
type: decision
context: infrastructure
created: 2026-11-04
depends_on: []
blocks: []
tags: [adr-backfill, persistence, shared-preferences, migration]
related_adrs: []
related_research: []
prior_art: []
---

## Why

The vision's new movement kinds (top-up, correction, exchange) will change stored data on an
install with real records. The persistence rules, especially "no schema migration, so `fromJson`
must default safely", need to be on record before that work starts.

## What

Commit an ADR documenting: all data in SharedPreferences as JSON strings under fixed keys;
every service follows read-full-list → deserialize → mutate → serialize → write-full-list; no
SQLite/Hive/files; no schema versioning, so new or renamed fields need safe `fromJson` defaults;
the one-off seeding flag pattern (`categories_defaults_initialized_v2`).

## Acceptance criteria

- ADR committed with `scope: global`; justification matches the draft below (or the
  owner-amended version).
- Key table in the ADR matches the keys actually used in `lib/services/` at commit time.
- No code change.

## Notes

Draft ADR (number provisional, finalized at integration):

```markdown
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
Low-volume, single-device, single-user data. This records the existing persistence choice.

## Decision
All data lives in SharedPreferences: `expenses`, `accounts`, `categories`, `custom_currencies`
as `List<String>` of JSON objects; `selected_account_id`, `default_currency` as strings;
`theme_mode` as an int; `categories_defaults_initialized_v2` as a bool seeding flag. Every service
reads the full list, deserializes, mutates in memory, serializes and writes the full list back.
There is no schema version: model changes must keep `fromJson` tolerant (defaults for missing
fields, fallback to the "other" category for unknown category ids). New default seeds bump the
flag suffix (`_v3`).

## Consequences
### Positive
- Zero setup, no native database dependency, trivial to reason about.
### Negative
- Any model change risks crashing existing installs if `fromJson` is not defensive.
- Changing the meaning of existing records (e.g. reclassifying income as top-ups) needs an
  explicit one-off migration step guarded by a flag, since there is no migration framework.
- Whole-list rewrites scale poorly; acceptable at current volume.
### Neutral
- Moving to SQLite/Drift later would be a superseding ADR.

## Alternatives considered
- **SQLite / Drift** — more robust migrations; not needed at this volume.
- **Hive / Isar** — typed storage; adds a dependency for little gain today.
```
