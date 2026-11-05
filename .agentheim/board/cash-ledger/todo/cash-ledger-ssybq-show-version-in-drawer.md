---
id: cash-ledger-ssybq
title: Show the app version and build number at the bottom of the home drawer
status: todo
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001]
blocks: []
tags: [ui, drawer, version, release]
related_adrs: [ADR-0011]
related_research: []
prior_art: [infrastructure-dx7t4]
---

## Why

Now that releases are versioned (ADR-0011, `tool/release.sh`) and installed by hand from GitHub,
the owner wants to see in the app which version is installed on the phone. The owner asked for
this on 2026-11-05.

## What

- At the bottom of the home drawer (`_buildDrawer()` in `lib/screens/home_screen.dart`), show the
  installed version as `Version X.Y.Z (N)`, for example `Version 1.1.0 (2)`. Use the drawer's
  muted/secondary text style from the styleguide, and keep it unobtrusive.
- Read the values at runtime from the installed package (`versionName`/`versionCode`), not from a
  hard-coded string, so every release shows its own version without a code change. Use a
  maintained package such as `package_info_plus`. Put the lookup behind a thin injectable seam, so
  widget tests can supply a fixed version.
- If the lookup fails, show nothing rather than an error.
- Update `AGENTS.md`'s dependency table if a package is added.

## Acceptance criteria

- [ ] With the seam returning `1.2.3` / `7`, opening the drawer shows `Version 1.2.3 (7)`. Covered
      by a widget test.
- [ ] If the version lookup fails or returns nothing, the drawer still opens and shows no version
      line. Covered by a widget test.
- [ ] No version string is hard-coded in `lib/`.
- [ ] `flutter test`, `flutter analyze` and `flutter build apk --debug` pass. `AGENTS.md` lists
      any new dependency.
- [ ] On the emulator, the drawer shows the real installed version and it looks in place. [human-eye]

## Notes

- Owner request 2026-11-05: "show version on the sidebar".
- Frontend task, so it depends on the styleguide (design-system-001, done).
