---
id: ADR-0010
title: Releases are signed with one dedicated key and the app ID is permanently io.github.mco.expensetracker
scope: global
status: accepted
date: 2026-11-05
amends: [ADR-0002]
related_tasks: [infrastructure-c5nkp]
related_adrs: [ADR-0002]
---

# ADR-0010: Releases are signed with one dedicated key and the app ID is permanently io.github.mco.expensetracker

## Context

Release builds were signed with whichever Mac's debug key built them. On 2026-11-05 this forced a
full uninstall/reinstall on the owner's phone: the installed app came from another Mac,
`adb install -r` failed with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, and the data had to be exported
and re-imported. The app ID was also the placeholder `com.example.expense_tracker` (ADR-0002),
which Google Play rejects; changing it is only cheap before the first proper release.

This ADR amends ADR-0002 and replaces two of its points: the placeholder app ID
`com.example.expense_tracker`, and release builds signed with the debug keystore.

## Decision

- Releases are signed only with one dedicated release key (RSA 4096, alias `release`, validity
  about 27 years). The keystore lives outside the repo, by default at
  `~/.android-keys/expense-tracker-release.jks`, and the owner backs up the file and its password.
- The owner creates the key once with `tool/create-release-key.sh`, which prompts for the
  certificate name and the password (asked twice, minimum 6 characters), passes the password to
  keytool through the environment rather than the command line, escapes the name for the
  certificate DN, refuses to overwrite an existing keystore, and writes `android/key.properties`
  (gitignored, mode 600).
- `android/app/build.gradle.kts` reads `android/key.properties` for the `release` signing config.
  A release build without that file fails with a message naming `tool/create-release-key.sh`; it
  never falls back to the debug key. Debug builds are unaffected.
- The app ID and namespace are `io.github.mco.expensetracker` (reverse of `mco.github.io`,
  controlled through the owner's GitHub account) and never change again. This replaces ADR-0002's
  placeholder ID.
- Changing the ID or the key forces a reinstall. The recovery path is export, uninstall/reinstall,
  import. The ID change itself makes this a different app from `com.example.expense_tracker`.
- The "never change the ID again" rule is prose-only; the signing rule is enforced by the build.

## Consequences

- Any Mac can build an updatable release, provided it has the keystore and `key.properties`.
- Losing the keystore or its password means installed copies can never be updated; backup is the
  owner's responsibility.
- The first install of the new ID needs a one-time export, uninstall of the old app, install, and
  import.
- Builds stay manual (ADR-0002's build-and-release approach otherwise stands); there is no CI to
  hold the key.
