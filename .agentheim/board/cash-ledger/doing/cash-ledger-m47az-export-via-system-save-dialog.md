---
id: cash-ledger-m47az
title: Export saves the CSV through Android's save dialog, so the app needs no storage permissions
status: doing
type: refactor
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001]
blocks: [infrastructure-pn83e]
tags: [export, csv, permissions, android, cleanup]
related_adrs: [ADR-0002, ADR-0005]
related_research: []
prior_art: [cash-ledger-hzqaa]
---

## Why

Export asks for Android's "All files access" (`MANAGE_EXTERNAL_STORAGE`, with a fallback to
`Permission.storage`). It then writes to a hard-coded `/storage/emulated/0/Download` path
(`lib/screens/home_screen.dart`). This is the broadest storage permission Android has, and it is
fragile across devices.

The manifest also declares permissions the app never uses: `INTERNET`, `READ_MEDIA_IMAGES`,
`READ_MEDIA_VIDEO` and `READ_MEDIA_AUDIO`. Import already uses the system file picker
(`file_picker`, cash-ledger-hzqaa), which needs no permissions at all.

The owner decided (modeling, 2026-11-05) that export should save through the system dialog, and
that `permission_handler` and every storage/media/network permission should go. This also removes
one major-version bump from the dependency upgrade (infrastructure-pn83e).

## What

- **Export flow.**
  - Keep the account and date-range pickers exactly as today.
  - After choosing, open Android's system save dialog, pre-filled with the existing file name
    `transactions_<from>_<to>.csv`. Use `file_picker`'s save support (already a dependency) or
    another maintained SAF-based way.
  - The user picks the folder, e.g. Downloads or Drive.
  - Write the same CSV content `buildCSV` produces today; its columns and format are unchanged
    (ADR-0005).
  - If the user cancels the dialog, nothing is written and no error is shown.
  - Keep the existing success and failure messages, adjusted to say the file was saved rather
    than naming a hard-coded path.
- **Seam.** Put the save call behind a thin injectable seam, like `CsvFilePicker` for import, so a
  widget test can stub it.
- **Remove `permission_handler`.** Remove the dependency and all its uses.
- **Manifest.** Remove `INTERNET`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`,
  `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO` and `MANAGE_EXTERNAL_STORAGE` from
  `android/app/src/main/AndroidManifest.xml`, unless a remaining dependency demonstrably needs one;
  if so, document why.
  - Note that removing `INTERNET` also removes it from the release build. Flutter debug and
    profile builds get it from their own manifests, so hot reload is unaffected.
- **ADR.** Write an ADR amending ADR-0005: export goes to a location the user picks in the system
  save dialog, not a fixed Downloads path, and the app holds no storage permissions.
- **Docs.** Update `AGENTS.md`: the permissions section, the dependency table and the `home_screen`
  description.

## Acceptance criteria

- [ ] Export calls the save seam with `transactions_<from>_<to>.csv` and exactly the `buildCSV`
      content for the chosen account and range; a cancelled dialog writes nothing and shows no
      error. Covered by a widget test with the seam stubbed.
- [ ] `permission_handler` is gone: no reference in `pubspec.yaml`, `lib/` or `test/`.
- [ ] `AndroidManifest.xml` declares none of the seven removed permissions, unless one is kept with
      a written reason.
- [ ] An ADR amending ADR-0005 records the save-dialog export and the no-permissions stance.
- [ ] `AGENTS.md` permissions, dependencies and the export description match the code.
- [ ] `flutter test`, `flutter analyze` and `flutter build apk --debug` pass.
- [ ] On a device, exporting opens the save dialog, the file lands where chosen, and importing that
      file back works. [human-eye]

## Notes

- Owner decision 2026-11-05: save via the system dialog; drop `permission_handler` and the
  storage, media and network permissions.
- Runs before infrastructure-pn83e, the dependency upgrade, so that task no longer has to bump
  `permission_handler` 12→13.
- The export's MoneyMoney shape (ADR-0005) is untouched; only where the file goes changes.
