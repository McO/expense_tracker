---
id: infrastructure-tf3qk
title: Migrate the Android app module from the Kotlin Gradle Plugin to Flutter's Built-in Kotlin
status: doing
type: chore
context: infrastructure
created: 2026-11-05
completed:
depends_on: []
blocks: []
tags: [android, gradle, kotlin, toolchain, upkeep]
related_adrs: [ADR-0002, ADR-0010, ADR-0011]
related_research: []
prior_art: [infrastructure-pn83e, infrastructure-c5nkp]
---

## Why

Every build on Flutter 3.47.2 warns that the app applies the Kotlin Gradle Plugin (KGP), and that
future Flutter versions will fail to build such apps. The warning points to the migration guide:
https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers

This was seen during the dependency upgrade (infrastructure-pn83e) and the first release (v1.1.0)
and deliberately left alone. The vision asks that the codebase stay on current Flutter versions,
so the fix should land before a Flutter upgrade turns the warning into a broken build. The owner
asked to capture it on 2026-11-05.

## What

- Follow the official guide for app developers to move `android/` off KGP onto Built-in Kotlin.
  Today the app module applies `id("kotlin-android")`
  (`android/app/build.gradle.kts`), `android/settings.gradle(.kts)` declares
  `org.jetbrains.kotlin.android` 2.4.0, and the `kotlin { compilerOptions { jvmTarget … } }` block
  needs whatever replacement the guide prescribes. Read the guide (and the Flutter tool's own
  migration notes for 3.47) rather than guessing.
- Keep everything else unchanged:
  - `applicationId` and `namespace` stay `io.github.mco.expensetracker` (ADR-0010);
  - release signing from `android/key.properties`, and the guard that fails release builds without
    it, stay intact (ADR-0010);
  - `tool/release.sh` keeps working (ADR-0011);
  - `MainActivity.kt` stays as it is.
- **Out of scope:** the plugin-side warning for `shared_preferences_android`. That is upstream; at
  most, bump it if a newer version that supports Built-in Kotlin already exists, and otherwise
  note it in the Outcome.

## Acceptance criteria

- [ ] `flutter build apk --debug` no longer prints the "Your Android app project … applies the
      Kotlin Gradle Plugin" warning. The Outcome quotes the build output.
- [ ] With a throwaway `android/key.properties` and keystore in a temp location (deleted
      afterwards), `flutter build apk --release` succeeds and is signed with the release key, not
      Android Debug. Without `key.properties`, the release build still fails with the message
      naming `tool/create-release-key.sh`.
- [ ] The built APK's package is still `io.github.mco.expensetracker` (`aapt2 dump badging`).
- [ ] `flutter analyze` and `flutter test` pass, and `tool/release.sh patch --dry-run` still runs
      cleanly through its steps (using `RELEASE_DRY_RUN_SKIP_CHECKS` only where needed in a
      worktree).
- [ ] Any remaining plugin-side KGP warning (e.g. `shared_preferences_android`) is named in the
      Outcome, with whether a fixed version exists.
- [ ] The app on the emulator starts and shows existing data as before. [human-eye]

## Notes

- Owner asked to capture this on 2026-11-05. It is not urgent: the builds succeed today.
- Never use the owner's real `~/.android-keys` or `android/key.properties` in a worktree; use only
  throwaway keys.
- Manual builds, no CI (ADR-0002).
