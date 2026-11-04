---
id: cash-ledger-ngxsa
title: Record the existing CSV export as an ADR (per-wallet date range to Downloads, for MoneyMoney)
status: todo
type: decision
context: cash-ledger
created: 2026-11-04
depends_on: []
blocks: []
tags: [adr-backfill, export, csv, moneymoney, permissions]
related_adrs: [ADR-0001]
related_research: []
prior_art: []
---

## Why

Export is a founding requirement (the previous app's lack of it is why this app exists, ADR-0001).
The coming top-up/correction movement kinds will change what the CSV must contain, so the current
export contract should be on record first.

## What

Commit a BC-local ADR documenting the current export: one wallet (account) and a date range chosen
in the home screen; CSV built by `ExpenseService.buildCSV`; categories written by their
`exportName` when set; file written to the device's Downloads folder after a storage-permission
request (`permission_handler`); imported manually into the matching MoneyMoney cash account; no
tracking of what was already exported (duplicates are cleaned up in MoneyMoney, vision non-goal 7).

## Acceptance criteria

- ADR committed with `scope: cash-ledger`; justification matches the draft below (or the
  owner-amended version).
- The column list in the ADR matches `buildCSV` at commit time.
- No code change.

## Notes

Draft ADR (number provisional, finalized at integration):

```markdown
---
id: 0005
title: Per-wallet date-range CSV export to Downloads, shaped for MoneyMoney import
scope: cash-ledger
status: accepted
date: 2026-11-04
related_tasks: [cash-ledger-ngxsa]
---

# ADR 0005: Per-wallet date-range CSV export to Downloads, shaped for MoneyMoney import

## Context
MoneyMoney is the system of record (ADR-0001) and imports CSV manually into one cash account per
currency. Volume is low. This records the existing export.

## Decision
Export one wallet's movements over an owner-chosen date range as CSV (`ExpenseService.buildCSV`;
columns: <fill in from code>), writing each category's `exportName` (falling back to its name) so
it maps to MoneyMoney's categories. The file is written to Downloads after requesting storage
permission. Nothing records which movements were exported.

## Consequences
### Positive
- Data can always leave the app; the format is plain and inspectable.
### Negative
- Broad storage permissions (`MANAGE_EXTERNAL_STORAGE` et al.) are declared for one file write.
- Overlapping date ranges produce duplicates in MoneyMoney (accepted; cleaned up there).
- Top-ups currently export as income; MoneyMoney then sees them as income, not transfers.
### Neutral
- The CSV shape is coupled to MoneyMoney's importer, which this app does not control.

## Alternatives considered
- **Share sheet instead of Downloads** — avoids storage permissions; not the current behaviour,
  worth a later task.
- **Export tracking (last-exported marker)** — rejected for now; duplicates are cheap to remove.
```
