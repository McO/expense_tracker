---
id: cash-ledger-hzqaa
title: Import a CSV file the app exported into a chosen account, skipping exact duplicates
status: done
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

## Verifier note (iteration 1)

**REASONS:**
- Check 5: README_DELTA appends the Import command's rules to `## Ubiquitous language`, which holds short term definitions only. This README keeps commands and their rules under `## Key commands`, which would still list Export without Import. Only the section is wrong; the body matches the diff.
- Minor: FILES_CHANGED says 9, but FILE_LIST and the diff show 8.
- Everything else passes: every criterion is covered, 71 tests pass, analyze is clean, and the single write goes through TransactionsStore.

**SUGGESTED_FIX:**
- Record the import command under "Key commands" (an append carrying the behaviour text).
- Optionally add a short "Import" term in "Ubiquitous language", written like the existing Export bullet.
- Report FILES_CHANGED: 8.
- No code or test changes are needed.

**ITERATION_HINT:** likely-fixable

## Outcome

"Import CSV" now sits in the home drawer next to Export. The flow is: choose the target account, choose a file, see a preview, then Import or Cancel. The file is chosen through the injectable `CsvFilePicker` seam, which by default uses `file_picker` ^13.3.2. The preview shows how many rows will be imported, how many duplicates are skipped, how many rows are mapped to "Other", and which rows are invalid, by line number.

- A currency mismatch or a wrong header shows a message and writes nothing.
- If every row is invalid or a duplicate, only Cancel is offered.

Key files:
- `lib/services/csv_import.dart`: pure functions `parseCsvRecords` (quoting, BOM, CRLF, line numbers), `buildImportPreview` and `matchCategory` (export name first, then name, case-insensitive), plus `commitImportPreview`, which does a single write through `TransactionsStore` (ADR-0008).
- `lib/services/transaction_service.dart`: adds `previewImport` and `commitImport`.
- `lib/services/csv_file_picker.dart`: the picker seam.
- `lib/screens/home_screen.dart`: the drawer action and the flow. The account picker is now shared with Export (`_selectAccount`).

Tests: `test/csv_import_test.dart` (service) and `test/csv_import_flow_test.dart` (widget flow with a stubbed picker), 14 new tests; 71 pass in total. `flutter analyze` is clean, and `flutter build apk --debug` builds. No Android permission changes were needed. The cash-ledger README now records Import under Key commands and Ubiquitous language. Verification passed on iteration 2; iteration 1 had put the README delta in the wrong section. Still open: the owner's own check of importing a real export on the device.
