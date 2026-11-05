---
id: ADR-0009
title: Export saves through the system save dialog; the app holds no storage permissions
scope: cash-ledger
status: accepted
date: 2026-11-05
related_tasks: [cash-ledger-m47az]
related_adrs: [ADR-0005]
amends: [ADR-0005]
---

# ADR-0009: Export saves through the system save dialog; the app holds no storage permissions

## Context

ADR-0005 recorded export as a write to the hard-coded `/storage/emulated/0/Download` path,
guarded by `permission_handler` requests for `MANAGE_EXTERNAL_STORAGE` (falling back to
`Permission.storage`). That is the broadest storage permission Android has, and it is fragile
across devices. The manifest also declared permissions nothing used: `INTERNET` and
`READ_MEDIA_IMAGES/VIDEO/AUDIO`. Import (cash-ledger-hzqaa) already uses the system file picker
through `file_picker`, which needs no permissions. The owner decided on 2026-11-05 that export
should use the system dialog too and that every storage, media and network permission should go.

## Decision

- After the owner picks the account and date range, export opens Android's system save dialog
  (`FilePicker.saveFile` with the CSV bytes and mime type `text/csv`), pre-filled with the file
  name `transactions_<from>_<to>.csv`. The owner chooses the folder (Downloads, Drive, ...).
- The save step sits behind the injectable `CsvFileSaver` seam (`lib/services/csv_file_saver.dart`,
  default `saveCsvFile`), mirroring `CsvFilePicker` for import, so widget tests can stub it.
  It returns true when saved and false when the user cancels; a cancel writes nothing and shows
  no message. Success and failure are still reported by snackbar ("Saved <file name>",
  "Export failed: ...").
- `permission_handler` is removed. `AndroidManifest.xml` declares no permissions:
  `INTERNET`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `READ_MEDIA_*` and
  `MANAGE_EXTERNAL_STORAGE` are all dropped. Flutter's debug and profile manifests add
  `INTERNET` themselves, so hot reload is unaffected; the release build no longer has it.
- The CSV content and format from ADR-0005 (`buildCSV`, header, columns, filtering) are unchanged.
  Only steps 4 and 5 of ADR-0005's flow (permission request, write to Downloads) are replaced.

## Consequences

### Positive
- No permission prompts and no "All files access"; works across Android versions and devices.
- The owner chooses where the file goes; the save dialog handles name collisions itself.
- One fewer dependency, and one major-version bump fewer in the dependency upgrade.

### Negative
- The owner must confirm a dialog on every export instead of a silent write to Downloads.
- The app can no longer reach the network in release builds (it never did).

### Neutral
- ADR-0005's remaining decisions (format, filtering, no export tracking) stand.
- The exact on-device behaviour of the save dialog is verified by the owner, not by tests.
