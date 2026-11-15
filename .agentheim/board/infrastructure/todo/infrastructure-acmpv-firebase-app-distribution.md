---
id: infrastructure-acmpv
title: tool/release.sh also uploads each signed APK to Firebase App Distribution, so the owner installs and updates through App Tester
status: todo
type: feature
context: infrastructure
created: 2026-11-15
completed:
depends_on: []
blocks: []
tags: [release, distribution, firebase]
related_adrs: [ADR-0009, ADR-0010, ADR-0011]
related_research: []
prior_art: [infrastructure-dx7t4, infrastructure-c5nkp]
---

## Why

Installing a release today goes like this: open the GitHub Release on the phone, download the APK, allow the install, install. There is no notice when a new version is out.

The owner is the app's only user and wants an easier route. Each release should appear in Google's **Firebase App Tester** app on the phone and install with one tap, with a notification for new versions. The owner chose Firebase App Distribution on 2026-11-15. GitHub Releases stay as they are.

## What

Extend `tool/release.sh` (ADR-0011) with one more step, run after the GitHub Release is published: upload `build/release/expense-tracker-X.Y.Z.apk` to Firebase App Distribution using the Firebase CLI. The CLI is already installed on the owner's Mac.

```
firebase appdistribution:distribute <apk> --app <FIREBASE_APP_ID> --groups <group> --release-notes-file <changelog section>
```

- **Configuration:** a gitignored local file, e.g. `tool/release.local.env` with `FIREBASE_APP_ID=…` and `FIREBASE_TESTER_GROUP=…`.
  - Use a tester **group**, set up in the Firebase console, not an email address. The repo is public, so the owner's email must never appear in it.
  - Commit an example file, `tool/release.local.env.example`, that holds placeholders only.
- **Distribution is opt-in by configuration.**
  - **Config present:** a new precondition checks that the `firebase` CLI is installed and logged in (e.g. `firebase login:list` shows an account). If not, the release is refused with a clear message, the same way as the existing preconditions.
  - **Config absent:** the release runs exactly as today and prints one line, "Firebase distribution not configured; skipped".
  - The `RELEASE_DRY_RUN_SKIP_CHECKS` seam gets a `firebase` name, honoured only with `--dry-run`, like the others.
- **Release notes:** the upload uses the same changelog section as the GitHub Release.
- **Failure handling:** if the upload fails, the GitHub Release has already been published. Do not roll anything back. Print a clear message and the exact retry command, the same pattern as the existing push-failure hint, and exit non-zero.
- **`--dry-run`:** prints the exact `firebase appdistribution:distribute …` command it would run, or the "not configured" line, and uploads nothing.
- **No Firebase code goes into the app:**
  - no SDK, no `google-services.json`, no Gradle plugin, no new permission;
  - ADR-0009's "no permissions" stays true, as does the vision's "data stays on the phone";
  - Firebase's in-app update SDK is explicitly out of scope, because it needs `INTERNET`.
- **Docs:**
  - `AGENTS.md` (Releasing section) and `README.md` (Install section) describe the Firebase route.
  - The README gets the owner's one-time setup checklist, see Notes below. Keep it generic: no project IDs and no emails.
- **ADR:** draft one amending ADR-0011 (an extra distribution step, configured locally). It should record why the in-app SDK was rejected, with ADR-0009 as the reason.

## Acceptance criteria

- [ ] With no `tool/release.local.env`: `tool/release.sh patch --dry-run` (with `RELEASE_DRY_RUN_SKIP_CHECKS` as needed) runs as before and prints "Firebase distribution not configured; skipped". Covered by a scripted or `test/` check.
- [ ] With a config holding dummy values: `--dry-run` prints the exact `firebase appdistribution:distribute build/release/expense-tracker-X.Y.Z.apk --app <id> --groups <group> --release-notes-file <file>` command and uploads nothing.
- [ ] With the config present and the firebase precondition not skipped: a missing or logged-out `firebase` CLI is refused with a clear message before anything changes. Testable with a fake `firebase` on `PATH` that exits non-zero.
- [ ] `tool/release.local.env` is gitignored (`git check-ignore` reports it); `tool/release.local.env.example` is tracked and holds placeholders only.
- [ ] No Firebase dependency, plugin, `google-services.json` or permission is added to the app. `git diff` touches nothing under `android/app/src/main/`, `pubspec.yaml` or `pubspec.lock`.
- [ ] Any testable logic (e.g. building the distribute command) is covered by tests; if it lives in `tool/release_notes.dart`, `test/release_notes_test.dart` covers it. `flutter test` and `flutter analyze` pass.
- [ ] `AGENTS.md` and `README.md` describe the Firebase step and the owner's one-time setup, with no project IDs and no emails.
- [ ] After the owner's one-time setup, a real `tool/release.sh patch` puts the new version into App Tester on the owner's phone, and it installs over the GitHub-installed app with data kept. [human-eye]

## Notes

- **Owner's one-time setup** (manual; the worker must not attempt it):
  1. Create a Firebase project at console.firebase.google.com.
  2. Add an Android app with package `io.github.mco.expensetracker`. You can skip the `google-services.json` download, since it isn't needed.
  3. Open App Distribution and create a tester group (e.g. `owner`) with your own email.
  4. Run `firebase login` on the Mac.
  5. Copy `tool/release.local.env.example` to `tool/release.local.env` and fill in the app ID (from Project settings) and the group alias.
  6. Install **Firebase App Tester** on the phone (it comes with the first invite email) and accept the invite.
- **Same key, so updates install in place:** App Distribution serves exactly the APK `release.sh` built, signed with the release key (ADR-0010).
- **Safety for workers:**
  - Never run a real release or a real `firebase appdistribution:distribute`.
  - Never touch `~/.android-keys` or `~/.android`, or a real `android/key.properties`.
  - Use only dry runs and fake `firebase`/`gh` binaries on `PATH`.
- **Out of scope:** the Play Store, Firebase in-app update prompts, and distributing to anyone besides the owner.
