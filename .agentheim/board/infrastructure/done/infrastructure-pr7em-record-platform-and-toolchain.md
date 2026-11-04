---
id: infrastructure-pr7em
title: Record the existing platform and toolchain as an ADR (Android-only Flutter, manual builds)
status: done
type: decision
context: infrastructure
created: 2026-11-04
depends_on: []
blocks: []
tags: [adr-backfill, platform, toolchain, build]
related_adrs: [ADR-0001, ADR-0002]
related_research: []
prior_art: []
---

## Why

The app already exists; its platform and toolchain choices were made implicitly. Recording them
lets future tasks (version updates especially) cite a decision instead of re-deciding it.

## What

Commit an ADR documenting what is true today: Android only, Flutter stable, Dart SDK
`>=3.4.3 <4.0.0`, AGP 9 DSL with current Gradle/Kotlin, Material Design 3, manual
debug/release builds, no CI/CD, placeholder app id `com.example.expense_tracker`.

## Acceptance criteria

- ADR committed with `scope: global`; justification matches the draft below (or the
  owner-amended version).
- Facts in the ADR match the repo at commit time (`pubspec.yaml`, `android/` build files).
- No code change.

## Notes

Draft ADR (number provisional, finalized at integration):

```markdown
---
id: 0002
title: Android-only Flutter app on the stable channel, built and released manually
scope: global
status: accepted
date: 2026-11-04
related_tasks: [infrastructure-pr7em]
---

# ADR 0002: Android-only Flutter app on the stable channel, built and released manually

## Context
Single developer and single user, on an Android phone. The app predates this decision record;
this documents the existing choice.

## Decision
Flutter stable, Dart SDK `>=3.4.3 <4.0.0`, Android as the only platform (no iOS/web/desktop
folders). Material Design 3 with indigo seed `0xFF6366F1`. Builds via `flutter build apk`,
installed by hand; `flutter analyze` is the static gate. No CI/CD.

## Consequences
### Positive
- Minimal surface: one platform, one toolchain, no pipeline to maintain.
### Negative
- Toolchain bumps (Flutter, AGP, Gradle, Kotlin) are manual and occasionally breaking.
- No automated gate: regressions are only caught by `flutter analyze`, tests (currently almost
  none) and manual use.
- App id is still the placeholder `com.example.expense_tracker`.
### Neutral
- Adding iOS later would be a new decision, not a config change (non-goal per vision).

## Alternatives considered
- **Native Android (Kotlin)** — not chosen; Flutter was the original choice and works.
- **CI pipeline** — not worth it for a single-user app today.
```

Verify current Gradle/AGP/Kotlin versions from `android/` before committing (recent commit
`e0783e2` migrated to the AGP 9 DSL).

## Outcome

Verified the draft ADR against the repo and returned the final ADR (provisional 0002, `scope: global`) in the ADRS block. Corrections and additions to the draft: AGP 9.1.0, Kotlin plugin 2.4.0, Gradle wrapper 9.3.1, Java 11 target, compileSdk/minSdk/targetSdk/versionCode taken from Flutter plugin defaults (not pinned), release builds signed with the debug keystore, version 1.0.0+1. Dart constraint, app id, and theme seed (`0xFF6366F1`, M3) were confirmed unchanged. No code or test changes.

ADR recorded as **0002** (`knowledge/decisions/0002-android-only-flutter-stable-manual-builds.md`).
