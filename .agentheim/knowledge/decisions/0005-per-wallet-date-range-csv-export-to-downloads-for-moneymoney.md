---
id: ADR-0005
title: Per-wallet date-range CSV export to Downloads, shaped for MoneyMoney import
scope: cash-ledger
status: accepted
date: 2026-11-04
related_tasks: [cash-ledger-ngxsa]
related_adrs: [ADR-0001, ADR-0004]
---

# ADR-0005: Per-wallet date-range CSV export to Downloads, shaped for MoneyMoney import

## Context

MoneyMoney is the system of record (ADR-0001) and imports CSV manually into one cash account per
currency. Volume is low. Export is a founding requirement: the previous app's lack of it is why this
app exists. This ADR records the export as it exists in code today, so that the coming top-up and
correction movement kinds can be weighed against a known contract.

## Decision

The owner exports one wallet (account) over a date range as a CSV file, and imports it manually
into the matching MoneyMoney cash account.

**Flow (`_exportToCSV` in `lib/screens/home_screen.dart`, reached from the Export menu entry):**
1. A dialog lists all accounts; the owner picks one (cancel aborts).
2. `showDateRangePicker` (first date 2020-01-01, last date today, default the last 30 days).
3. `ExpenseService.buildCSV(startDate, endDate, accountId)` builds the content. If no movements
   match, it returns `null`; the screen shows a snackbar ("No expenses found for the selected
   range") and writes no file.
4. Storage permission is requested via `permission_handler`: `Permission.manageExternalStorage`
   first; if not granted, falls back to `Permission.storage`; if neither is granted, a red snackbar
   is shown and nothing is written.
5. The file is written with `File.writeAsString` to the hardcoded path
   `/storage/emulated/0/Download` (or `/storage/emulated/0/Downloads` if the first directory does
   not exist). The name is `expenses_<yyyyMMdd>_<yyyyMMdd>.csv` (range start and end). The wallet is
   not part of the file name, and a file with the same name is silently overwritten. Success and
   failure are reported by snackbar.

**CSV format (`ExpenseService.buildCSV`):**
- Separator `,`; line endings `\n`; UTF-8 via `writeAsString` defaults; one header row, one row per
  movement, in stored order (not re-sorted).
- Header: `Date,Title,Category,Amount,Currency,Description`
- `Date`: `yyyy-MM-dd` (local date, no time of day).
- `Title`, `Description`: written as-is, quoted with `"` (embedded `"` doubled) only if the value
  contains `,`, `"` or `\n`.
- `Category`: the category's `effectiveExportName` — `exportName` when set and non-blank after
  trimming, otherwise the category `name` — so categories map to MoneyMoney's category names. It is
  passed through the same quoting rule.
- `Amount`: always two decimals with `.` as the decimal separator and no thousands separator. Sign
  is derived from `type`: expenses are written with a leading `-` (e.g. `-12.50`), income is written
  unsigned (e.g. `12.50`). The stored `amount` is always positive (see `Expense`).
- `Currency`: the currency code (e.g. `EUR`).
- Not exported: account name or id, movement id, transaction type as a separate column.

**Filtering:** by `accountId` (when given), then by date: a movement is kept if its timestamp is not
before the picked start (midnight) and not after the picked end plus one day. Because the end bound
is `endDate + 1 day` from a midnight value, movements on the end day are included, and a movement
timestamped exactly at midnight of the following day is included too.

**No export tracking:** nothing records which movements were exported. Overlapping ranges produce
duplicates, which are cleaned up in MoneyMoney (vision non-goal 7).

## Consequences

### Positive
- Data can always leave the app; the format is plain, flat and inspectable.
- Each export is independent and stateless; no extra persisted keys (ADR-0004 unaffected).
- Categories can be aliased per category via `exportName` to match MoneyMoney's names.

### Negative
- Broad storage permissions are declared for one file write: `WRITE_EXTERNAL_STORAGE`,
  `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES/VIDEO/AUDIO` and `MANAGE_EXTERNAL_STORAGE`, plus
  `INTERNET`. The Downloads path is hardcoded rather than resolved via an API.
- Overlapping date ranges produce duplicates in MoneyMoney (accepted; cleaned up there).
- Top-ups and corrections are currently logged as income and therefore export as plain positive
  rows; MoneyMoney sees them as income, not as transfers. How they should export is an open
  question.
- The file name does not identify the wallet, and same-range exports overwrite each other.
- The inclusive end bound can pull in a movement at exactly midnight of the day after the range.
- No column identifies the wallet or movement, so rows cannot be matched back to the app's records.

### Neutral
- The CSV shape is coupled to MoneyMoney's importer, which this app does not control; the
  header and column order were not verified against MoneyMoney's import dialog by this ADR.

## Alternatives considered

- **Share sheet instead of Downloads** — avoids storage permissions entirely; not the current
  behaviour, worth a later task.
- **Export tracking (last-exported marker)** — rejected for now; duplicates are cheap to remove.
