# Infrastructure

## Purpose
Owns **globally-true** technical concerns: platform and toolchain (Flutter, Dart, Android build,
Gradle/AGP/Kotlin), dependency and version updates, base persistence, app-wide architecture
conventions, build and release. BC-local technical concerns (e.g. how the cash ledger writes its
CSV file) stay inside the originating BC.

## Classification
generic

## Actors
- **Owner** (sole developer) — builds manually and cuts each release with the local `tool/release.sh`; no CI/CD.

## Ubiquitous language
- **Toolchain** — Flutter stable, Dart SDK, Android Gradle Plugin, Gradle, Kotlin.
- **Dependency update** — bumping a package in `pubspec.yaml` or a build-tool version, with
  `flutter analyze` and a build still passing.
- **Preferences store** — SharedPreferences, where all app data lives as JSON strings.
- **Release build** — `flutter build apk --release`, signed with the release key (ADR-0010); produced by `tool/release.sh` and attached to the GitHub Release as `expense-tracker-X.Y.Z.apk`.
- **Release** — one versioned drop of the app: SemVer `X.Y.Z` plus a build number, an annotated git tag `vX.Y.Z`, and a GitHub Release (McO/expense_tracker) with the signed APK attached. Cut by `tool/release.sh` (ADR-0011). When Firebase distribution is configured, the same signed APK is also uploaded to Firebase App Distribution as a last step (ADR-0012).
- **Changelog** — `CHANGELOG.md`, one `## X.Y.Z (date)` section per release, generated from the task-completion commits (`<type>(<bc>): ... [<task-id>]`) since the previous `v*` tag and grouped Features / Fixes / Changes / Chores.
- **Build number** — the `+N` in `version: X.Y.Z+N` in `pubspec.yaml`; goes up by one with every release so each release installs over the previous one.
- **Tester group** — the Firebase App Distribution group (identified by its alias, never an email) that receives each release in the Firebase App Tester app (ADR-0012).
- **Local release config** — the gitignored `tool/release.local.env` (template `tool/release.local.env.example`) holding `FIREBASE_APP_ID` and `FIREBASE_TESTER_GROUP`; its presence switches the Firebase distribution step on (ADR-0012).

## Aggregates
None — no domain aggregates live here.

## Key events
- Toolchain bumped
- Dependency updated
- Release published
- Release distributed to App Tester

## Key commands
- Update Flutter / dependencies / Android build tooling
- Build debug or release APK
- Cut a release — `tool/release.sh <major|minor|patch|X.Y.Z> [--dry-run]`

## Relationships with other contexts
- **Supplier to:** cash-ledger, design-system.

## Open questions
- None yet.
