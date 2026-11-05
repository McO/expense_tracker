---
id: cash-ledger-hzqaa
title: Import a CSV file the app exported into a chosen account, skipping exact duplicates
status: todo
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001]
blocks: []
tags: [import, csv, export, ui, persistence]
related_adrs: [ADR-0003, ADR-0004, ADR-0005, ADR-0007, ADR-0008]
related_research: []
prior_art: [cash-ledger-ydqbw, cash-ledger-apzzm]
---

## Why

The app's data lives only in SharedPreferences on the phone (ADR-0004). The export (ADR-0005)
gets data out but nothing brings it back, so a reinstall or a new phone loses the history. The
owner wants to re-import the app's own CSV exports (owner decision, modeling 2026-11-05). Other
sources (the old tracker app, MoneyMoney, a generic column mapper) are out of scope.

## What

- **Format:** exactly the app's own export: header `Date,Title,Category,Amount,Currency,Description`.
  Date is `yyyy-MM-dd`. Amount is signed with 2 decimals: positive means money in, negative means
  money out (ADR-0007). Fields are quoted and escaped as `TransactionService._escapeCsvField`
  writes them. A file with a different header is rejected with a clear message.
- **Entry point:** an "Import CSV" action next to the existing export (home drawer). The user picks
  the target **account** first, then the file.
- **Account and currency:** every imported row goes into the chosen account. A transaction's
  currency is always its account's (cash-ledger-apzzm). If any row's `Currency` differs from the
  account's currency, the whole file is rejected, naming the mismatch. Nothing is converted
  (vision non-goal 5).
- **Mapping each row:**
  - Amount sign → `TransactionType` (`income` if > 0, `expense` if < 0); store the absolute amount.
    Reject zero rows as invalid.
  - Category: match the `Category` column against each category's effective export name first,
    then its name, case-insensitively. Unknown → "Other". This round-trips the export, which
    writes `effectiveExportName`, so Top-up and Correction land back in their built-in categories.
  - Title and Description are taken as-is. Time of day is not in the file; use midday so date
    filters still include the row.
  - New ids; `accountId` = the chosen account.
- **Duplicates:** a row is an exact duplicate when the target account already holds a transaction
  with the same date (day), signed amount, title, and category. Duplicates are skipped. Duplicates
  inside the file itself are imported as separate rows; only rows already in the app are skipped.
- **Preview, then confirm:** before anything is written, show a summary dialog:
  - N to import
  - M duplicates skipped
  - K rows mapped to "Other"
  - E invalid rows, with line numbers
  
  Confirm writes all valid, non-duplicate rows in one save; Cancel writes nothing. If every row is
  invalid or a duplicate, say so and write nothing.
- **Parsing and mapping live in the service layer** (e.g. `TransactionService` or a small
  importer next to `buildCSV`) so they can be unit-tested without UI. All writes go through
  `TransactionsStore` (ADR-0008).

## Acceptance criteria

- [ ] Round trip: exporting an account's transactions and importing that file into an empty account
      with the same currency gives the same date, signed amount, title, category and description
      for every row. Covered by a unit test.
- [ ] Re-importing the same file into the same account imports 0 rows and reports them all as
      duplicates. Covered by a unit test.
- [ ] A file whose `Currency` differs from the chosen account's currency is rejected and writes
      nothing. Covered by a unit test.
- [ ] A wrong header is rejected, and malformed rows (bad date, non-numeric or zero amount, wrong
      column count) are reported with line numbers while valid rows can still be imported.
      Covered by unit tests.
- [ ] Unknown categories map to "Other" and are counted. Top-up and Correction export names map
      back to their built-in categories. Covered by a unit test.
- [ ] Quoted fields with commas, quotes and newlines (as the export escapes them) parse correctly.
      Covered by a unit test.
- [ ] The import flow (pick account, pick file, preview counts, confirm or cancel) works, and
      Cancel writes nothing. Covered by a widget test with the file-picking step stubbed.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] Importing a real exported file on the device lands in the chosen account and looks right.
      [human-eye]

## Notes

- Owner decisions 2026-11-05:
  - Source: only the app's own export.
  - Target: a single chosen account.
  - Duplicates: skip exact ones.
  - Categories: match by export name or name, else "Other".
- Picking a file on Android needs a new dependency (e.g. `file_picker`). Choose a maintained one,
  add it to `pubspec.yaml`, and keep the platform call behind a thin seam so tests can stub it. If
  storage permissions change, update `AGENTS.md`.
- The export filters by date with `endDate + 1 day`; the import needs no date range.
- The UI follows the signed-off styleguide (dialog pattern, management/drawer conventions).
- Not covered: importing settings, accounts or categories themselves (full backup/restore). That
  would be a separate capture if wanted.
