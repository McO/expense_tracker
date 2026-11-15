---
id: ADR-0012
title: Firebase App Distribution as an optional, locally configured release step
scope: infrastructure
status: accepted
date: 2026-11-15
related_tasks: [infrastructure-acmpv]
related_adrs: [ADR-0009, ADR-0010, ADR-0011]
amends: [ADR-0011]
---

# ADR-0012: Firebase App Distribution as an optional, locally configured release step

## Context

Installing a release meant opening the GitHub Release on the phone and downloading the APK, with no notice of new versions. The owner (the only user) chose Firebase App Distribution and its App Tester app for one-tap installs and notifications. ADR-0011 defines the release script; ADR-0009 says the app declares no permissions; ADR-0010 fixes the signing key.

## Decision

Amends ADR-0011: `tool/release.sh` gets a final step 8/8 after the GitHub Release: `firebase appdistribution:distribute build/release/expense-tracker-X.Y.Z.apk --app <id> --groups <group> --release-notes-file <changelog section>`.

- Opt-in by configuration: gitignored `tool/release.local.env` with `FIREBASE_APP_ID` and `FIREBASE_TESTER_GROUP` (template `tool/release.local.env.example`, placeholders only; public repo, so no emails or real IDs are committed). A tester group, not an email, is used. Without config the script prints "Firebase distribution not configured; skipped" and behaves as before.
- With config, a precondition requires the `firebase` CLI installed and logged in (`firebase login:list`); otherwise the release is refused before anything changes. `RELEASE_DRY_RUN_SKIP_CHECKS` gains `firebase` (dry-run only).
- If the upload fails after the GitHub Release is published, nothing is rolled back: the script prints the exact retry command and exits non-zero.
- The served APK is the one built and signed by the release script, so updates install in place (ADR-0010).
- Rejected: Firebase's in-app update SDK. It needs the `INTERNET` permission and Firebase code in the app, which breaks ADR-0009's "no permissions" and the vision's "data stays on the phone".
- The app gets no SDK, `google-services.json`, Gradle plugin or permission.

## Consequences

- The upload cannot be rolled back once the GitHub Release is published; a failed upload leaves the release in place and the owner retries by hand with the printed command (the changelog notes file is kept for that).
- Once the local config exists, `firebase` installed and logged in becomes a release precondition, refused before anything changes.
- Without the config the release behaves exactly as before.
- The app stays free of Firebase code and of permissions (ADR-0009); in-place updates keep working through the same signing key (ADR-0010).
