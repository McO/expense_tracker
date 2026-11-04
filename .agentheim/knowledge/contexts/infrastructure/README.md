# Infrastructure

## Purpose
Owns **globally-true** technical concerns: platform and toolchain (Flutter, Dart, Android build,
Gradle/AGP/Kotlin), dependency and version updates, base persistence, app-wide architecture
conventions, build and release. BC-local technical concerns (e.g. how the cash ledger writes its
CSV file) stay inside the originating BC.

## Classification
generic

## Actors
- **Owner** (sole developer) — builds and releases manually; no CI/CD.

## Ubiquitous language
- **Toolchain** — Flutter stable, Dart SDK, Android Gradle Plugin, Gradle, Kotlin.
- **Dependency update** — bumping a package in `pubspec.yaml` or a build-tool version, with
  `flutter analyze` and a build still passing.
- **Preferences store** — SharedPreferences, where all app data lives as JSON strings.
- **Release build** — `flutter build apk --release`, installed by hand.

## Aggregates
None — no domain aggregates live here.

## Key events
- Toolchain bumped
- Dependency updated

## Key commands
- Update Flutter / dependencies / Android build tooling
- Build debug or release APK

## Relationships with other contexts
- **Supplier to:** cash-ledger, design-system.

## Open questions
- None yet.
