---
id: infrastructure-pn83e
title: Upgrade all dependencies to their latest versions and raise the Dart SDK lower bound to the installed toolchain
status: done
type: chore
context: infrastructure
created: 2026-11-05
completed:
depends_on: [cash-ledger-m47az]
blocks: []
tags: [dependencies, flutter, dart, upkeep, toolchain]
related_adrs: [ADR-0002]
related_research: []
prior_art: []
---

## Why

The vision says "the codebase stays on current Flutter and dependency versions" — the one success
criterion with no work behind it, and "version updates" was among the owner's first goals.
`flutter pub outdated` on Flutter 3.47.2 / Dart 3.13.2 (2026-11-05) shows the app behind:
`cupertino_icons` 1.0.8 → 2.0.0 (major), `shared_preferences` 2.5.3 → 2.5.6, `path_provider`
2.1.5 → 2.1.6, `flutter_native_splash` 2.4.6 → 2.4.8, plus many transitive updates; the
`environment.sdk` constraint is still `>=3.4.3 <4.0.0`. Owner decision (modeling, 2026-11-05):
move everything to latest, majors included, and raise the SDK lower bound.

## What

- Run `flutter pub upgrade --major-versions`, so every direct and dev dependency moves to its
  latest release: `shared_preferences`, `intl`, `flutter_staggered_animations`, `path_provider`,
  `cupertino_icons`, `file_picker`, `flutter_launcher_icons`, `flutter_native_splash` and
  `flutter_lints`. `permission_handler` was already removed by cash-ledger-m47az.
- Raise `environment.sdk`'s lower bound to the installed Dart, i.e. `^3.13.0` or `>=3.13.0 <4.0.0`.
- Fix every analyzer error, deprecation warning and new lint the upgrade brings up (for example
  from a newer `flutter_lints`), and any test or behaviour fallout. Behaviour must not change.
- Check the Android build config (Gradle / AGP / Kotlin versions in `android/`) still builds with
  the upgraded plugins. Bump them only if a plugin requires it, and note any bump in the Outcome.
- Remove `path_provider` if nothing in `lib/` uses it any more after cash-ledger-m47az.
- Update `AGENTS.md`'s dependency table and its "Flutter/Dart" line to the new versions and
  constraint.

## Acceptance criteria

- [ ] `flutter pub outdated` lists no direct or dev dependency with a newer "Latest" version than
      the one resolved, except where a newer version is incompatible with the installed Flutter.
      Name any such exception in the Outcome.
- [ ] `pubspec.yaml` `environment.sdk` lower bound is ≥ 3.13.0.
- [ ] `flutter analyze` reports no issues, including no deprecation infos.
- [ ] `flutter test` passes, and `flutter build apk --debug` and `flutter build apk --release`
      succeed.
- [ ] `AGENTS.md` dependency versions and the SDK line match `pubspec.yaml`.
- [ ] The app starts on the emulator and the existing data (accounts, transactions) still loads
      and displays as before the upgrade. [human-eye]

## Notes

- Owner decision 2026-11-05: latest everything, majors included; raise the SDK lower bound.
- Depends on cash-ledger-m47az, which removes `permission_handler` and the storage permissions
  before this upgrade.
- ADR-0002 (Android-only Flutter, manual builds) is unchanged. This keeps it current; it does not
  change the toolchain choice.
- `pubspec.lock` is not tracked in this repo, so only `pubspec.yaml` records the new version
  constraints.

## Outcome

Dependencies are upgraded. `flutter pub outdated` (Flutter 3.47.2) reports every direct and dev dependency up to date.

- SDK constraint: `>=3.4.3 <4.0.0` → `>=3.13.0 <4.0.0`.
- `cupertino_icons`: ^1.0.6 → ^2.0.0.
- `path_provider` removed. Nothing used it once export moved to the save dialog (ADR-0009).
- Already at their latest, constraints unchanged: `shared_preferences` (resolves 2.5.6), `intl` (0.20.3), `flutter_staggered_animations`, `file_picker`, `flutter_launcher_icons`, `flutter_native_splash`, `flutter_lints`.
- Still outdated, transitive only and held back by upstream packages: `cross_file`, `material_color_utilities`, `objective_c`, `cli_util`, `test_api`.
- Lint fallout fixed:
  - `(_, __)` → `(_, _)` in `currency_management_screen.dart`.
  - A null-aware map element in `account_currency_test.dart`.
- No Gradle, AGP or Kotlin changes. The build warns that a future Flutter will expect a move to Built-in Kotlin; nothing was done about it.
- `AGENTS.md` (SDK line, dependency table) updated.

`flutter analyze` is clean and `flutter test` passes (74). `flutter build apk --debug` and `--release` both succeed. Verification passed on iteration 1; this run resumed an earlier worker that the owner had stopped. Still pending: the owner's check that the app starts on the emulator and existing data loads.
