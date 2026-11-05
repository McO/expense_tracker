---
id: infrastructure-c5nip
title: Sign release builds with a dedicated release key and change the app ID to io.github.mco.expensetracker
status: todo
type: chore
context: infrastructure
created: 2026-11-05
completed:
depends_on: []
blocks: [infrastructure-dxit4]
tags: [release, signing, android, app-id, toolchain]
related_adrs: [ADR-0002]
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
- Builds stay manual on the Mac (ADR-0002); there is no CI. infrastructure-dxit4 adds the release
  script on top of this.
- Convention check: the signing/app-ID rule is enforced by the build itself (a release build fails
  without the release key). The "never change the ID again" part is prose-only, unenforced.
