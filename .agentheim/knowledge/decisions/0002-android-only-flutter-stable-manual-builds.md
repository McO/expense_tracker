---
id: 0002
title: Android-only Flutter app on the stable channel, built and released manually
scope: global
status: accepted
date: 2026-11-04
supersedes: []
superseded_by: []
related_tasks: [infrastructure-pr7em]
related_adrs: [ADR-0001]
---

# ADR 0002: Android-only Flutter app on the stable channel, built and released manually

## Context
Single developer and single user, on an Android phone. The app predates this decision record;
this documents the existing choice, verified against the repo on 2026-11-04.

## Decision
- **Platform:** Android is the only platform (only an `android/` folder; no iOS/web/desktop).
  App id and namespace are the placeholder `com.example.expense_tracker`.
- **Framework:** Flutter stable, Dart SDK constraint `>=3.4.3 <4.0.0` (`pubspec.yaml`).
- **Android build:** Android Gradle Plugin 9.1.0 and Kotlin Gradle plugin 2.4.0 (declared in
  `android/settings.gradle.kts`, Kotlin DSL), Gradle wrapper 9.3.1, Java/JVM target 11.
  `compileSdk`, `minSdk`, `targetSdk`, `ndkVersion`, `versionCode` and `versionName` are not
  pinned; they come from the Flutter Gradle plugin's defaults (`flutter.*`), so a Flutter
  upgrade moves them. App version is `1.0.0+1`.
- **UI:** Material Design 3 (`useMaterial3: true`) with indigo seed `Color(0xFF6366F1)`
  (`lib/main.dart`).
- **Build and release:** `flutter build apk --debug|--release`, installed by hand. The release
  build is signed with the debug keystore (no release signing config). `flutter analyze` is the
  static gate. No CI/CD.

## Consequences
### Positive
- Minimal surface: one platform, one toolchain, no pipeline to maintain.
### Negative
- Toolchain bumps (Flutter, AGP, Gradle, Kotlin) are manual and occasionally breaking; the
  build files already sit on a very recent AGP 9 / Gradle 9 / Kotlin 2.4 combination.
- No automated gate: regressions are only caught by `flutter analyze`, tests (currently almost
  none) and manual use.
- App id is still the placeholder `com.example.expense_tracker`, and release APKs use debug
  signing, so they are not suitable for store publication as-is.
### Neutral
- Adding iOS later would be a new decision, not a config change (non-goal per vision).

## Alternatives considered
- **Native Android (Kotlin)** - not chosen; Flutter was the original choice and works.
- **CI pipeline** - not worth it for a single-user app today.
