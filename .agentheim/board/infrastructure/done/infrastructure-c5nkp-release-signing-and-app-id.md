---
id: infrastructure-c5nkp
title: Sign release builds with a dedicated release key and change the app ID to io.github.mco.expensetracker
status: done
type: chore
context: infrastructure
created: 2026-11-05
completed:
depends_on: []
blocks: [infrastructure-dx7t4]
tags: [release, signing, android, app-id, toolchain]
related_adrs: [ADR-0002, ADR-0010]
related_research: []
prior_art: [infrastructure-pn83e]
---

## Why

Release builds are signed with whichever Mac's debug key happens to build them. On 2026-11-05 this
forced a full uninstall/reinstall on the owner's phone: the installed app came from another Mac,
`adb install -r` failed with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, and the data had to be exported
and re-imported. The app ID is also still the placeholder `com.example.expense_tracker`. Google
Play rejects `com.example.*`, and the ID can only be changed cheaply before the first proper
release.

Owner decisions (modeling, 2026-11-05):
- one dedicated release key;
- a script the owner runs once to create it, so the owner chooses the password;
- the new app ID `io.github.mco.expensetracker`.

## What

- **Key-creation script.** Add `tool/create-release-key.sh`. It interactively prompts for the
  store/key password (and the owner's name for the certificate DN) and runs `keytool -genkeypair`
  (RSA 4096, validity ≥ 25 years, alias `release`). The keystore goes **outside the repo**, by
  default `~/.android-keys/expense-tracker-release.jks`. The script then writes
  `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`), which is
  already gitignored. It refuses to overwrite an existing keystore, and at the end prints a
  reminder to back up the keystore file and its password, e.g. in a password manager.
- **Gradle signing.** In `android/app/build.gradle(.kts)`, add a `release` signingConfig that
  reads `android/key.properties`, and use it for the `release` build type.
  - If `key.properties` is missing, a **release** build must fail with a clear message naming
    `tool/create-release-key.sh`. It must never silently fall back to the debug key.
  - Debug builds are unaffected.
- **App ID.** Set `applicationId` to `io.github.mco.expensetracker` and `namespace` to match.
  Move `MainActivity.kt` to `kotlin/io/github/mco/expensetracker/` and update its `package` line.
  Fix any other occurrence of the old ID (e.g. AndroidManifest, splash/launcher-icon config).
- **ADR.** Write one recording:
  - releases are signed only with the dedicated release key, which lives outside the repo and is
    backed up by the owner;
  - the app ID is `io.github.mco.expensetracker` (reverse of `mco.github.io`, controlled via the
    owner's GitHub account) and never changes again;
  - changing the ID or the key forces a reinstall, with export → reinstall → import as the
    recovery path.
- **AGENTS.md.** Update the "App ID" line, remove the "App ID is still the default placeholder"
  gotcha, and document the key script and that release builds need `android/key.properties`.

## Acceptance criteria

- [ ] `grep -rn "com.example.expense_tracker\|com/example/expense_tracker" android lib pubspec.yaml`
      finds nothing. `applicationId` and `namespace` are `io.github.mco.expensetracker`, and
      `MainActivity.kt` lives under `io/github/mco/expensetracker/`.
- [ ] Running `tool/create-release-key.sh` non-interactively, by piping the password and name on
      stdin into a temp `HOME`, creates the keystore and `android/key.properties`. A second run
      refuses to overwrite. Demonstrated in the Outcome with the commands run; temp files are
      cleaned up, and no real key is committed.
- [ ] With a throwaway `key.properties` and keystore (created in a temp location and removed
      afterwards), `flutter build apk --release` succeeds. `apksigner verify --print-certs`
      shows the release certificate, not `CN=Android Debug`.
- [ ] With no `android/key.properties`, `flutter build apk --release` fails with a message naming
      `tool/create-release-key.sh`.
- [ ] `flutter build apk --debug`, `flutter test` and `flutter analyze` pass.
- [ ] `git status` shows no keystore or `key.properties` tracked (`*.jks` and
      `**/android/key.properties` stay gitignored).
- [ ] The ADR and the AGENTS.md updates exist and match the code.

## Notes

- Owner decisions 2026-11-05: dedicated release key, created by a script the owner runs once;
  app ID `io.github.mco.expensetracker`.
- After this merges, the owner must:
  1. run `tool/create-release-key.sh` once;
  2. back up the keystore and password;
  3. on the phone: export every account, uninstall the old `com.example.expense_tracker` app,
     install the first release, and import again. The new ID makes this a different app.
- Builds stay manual on the Mac (ADR-0002); there is no CI. infrastructure-dx7t4 adds the release
  script on top of this.
- Convention check: the signing/app-ID rule is enforced by the build itself (a release build fails
  without the release key). The "never change the ID again" part is prose-only, unenforced.

## Verifier note (iteration 1)

**REASONS:**
- Check 6b: ADR-0002's Decision still names the placeholder app ID `com.example.expense_tracker` and debug-key release signing. ADR-0010 overrides both but lists ADR-0002 only in `related_adrs`, with no `amends:`/`supersedes:`. Project convention: ADR-0007 `supersedes: [ADR-0006]`; ADR-0008/0009 `amends: [...]`.
- Everything else passes:
  - no old ID left;
  - the APK package is `io.github.mco.expensetracker`;
  - a release build without `key.properties` fails with no debug fallback;
  - the key script creates the keystore with dir 700 / files 600 and refuses to overwrite;
  - the signed build shows the release certificate;
  - analyze, 74 tests and the debug build pass;
  - nothing secret is tracked, and `AGENTS.md` matches.
- Optional hardening:
  - the password is passed as a keytool argument, so it is visible in `ps`; `-storepass:env` would avoid that;
  - the password is not confirmed by asking twice;
  - `-dname "CN=${OWNER_NAME}"` breaks if the name contains a comma;
  - an existing `key.properties` keeps its old permissions.

**SUGGESTED_FIX:** Add `amends: [ADR-0002]` to ADR-0010, plus a sentence saying it replaces ADR-0002's placeholder-ID and debug-signing points. Optionally apply the hardening.

**ITERATION_HINT:** likely-fixable

## Outcome

Release builds now sign only with a dedicated release key, and the app ID is `io.github.mco.expensetracker`. ADR-0010 records this and amends ADR-0002, replacing its placeholder ID and its debug-key signing.

- **`android/app/build.gradle.kts`.** The app ID and namespace are changed. The `release` signing config reads `android/key.properties`. Any release build without that file fails with a message naming `tool/create-release-key.sh`; there is no debug-key fallback.
- **`MainActivity.kt`.** Moved to `io/github/mco/expensetracker/`.
- **`tool/create-release-key.sh`** (new). It:
  - asks for the certificate name, and asks for the password twice (at least 6 characters);
  - passes the password to keytool through `-storepass:env` / `-keypass:env`, never on the command line, and unsets it afterwards;
  - escapes the name for the certificate DN, so "Doe, Jane" works;
  - creates an RSA 4096 key with alias `release`, in `~/.android-keys/expense-tracker-release.jks`;
  - refuses to overwrite an existing keystore;
  - writes `android/key.properties` with mode 600.
- **`AGENTS.md`.** The app ID line is updated, and the release-key gotcha replaces the placeholder-ID gotcha.

Checks, run with throwaway keys only (since deleted):
- The signed release APK carries the release certificate, not Android Debug.
- A release build without `key.properties` fails with the expected message.
- `flutter analyze` is clean, `flutter test` passes 74, and the debug build works.
- No keystore or `key.properties` is tracked in git.

Verification passed on iteration 2. Iteration 1 was missing the ADR-0002 amendment, and the script was hardened at the same time.

Owner follow-up:
1. Run `tool/create-release-key.sh` once.
2. Back up the keystore and its password.
3. On the phone: export, uninstall the old `com.example.expense_tracker` app, install the first release, and import.
