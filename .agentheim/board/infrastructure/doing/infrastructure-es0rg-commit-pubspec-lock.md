---
id: infrastructure-es0rg
title: Commit pubspec.lock so every checkout and release builds the tested dependency versions
status: doing
type: chore
context: infrastructure
created: 2026-11-05
completed:
depends_on: []
blocks: []
tags: [dependencies, reproducible-build, release]
related_adrs: [ADR-0002, ADR-0011]
related_research: []
prior_art: [infrastructure-pn83e, infrastructure-dx7t4]
---

## Why

`.gitignore` contains `*.lock`, and that pattern also ignores `pubspec.lock`. As a result:
- The owner's checkout keeps a stale local lock file. For example, it pins `shared_preferences` to 2.5.3 and `shared_preferences_android` to 2.4.10.
- Worktrees, workers and verifiers start without a lock file, so they resolve the latest versions (2.5.6 and 2.5.4).

So tests and verification run against different packages than the ones `tool/release.sh` builds the release APK from. The upgrade in infrastructure-pn83e ("latest everything") never reached the owner's tree either. Dart recommends committing `pubspec.lock` for applications.

## What

- Change `.gitignore` so that `pubspec.lock` is tracked. Either remove the blanket `*.lock`, or keep ignoring other lock files and un-ignore `pubspec.lock` explicitly. Prefer the narrowest change. Check what else `*.lock` was meant to cover before removing it.
- Run `flutter pub upgrade` to resolve the newest versions allowed by the current `pubspec.yaml` constraints. Do not change any constraint in `pubspec.yaml`.
- Track the resulting `pubspec.lock`.
- In `AGENTS.md`, add one short line saying that `pubspec.lock` is committed and why.

## Acceptance criteria

- [ ] `git check-ignore pubspec.lock` reports nothing; the file is tracked in the diff.
- [ ] The committed `pubspec.lock` has `shared_preferences` ≥ 2.5.6 and `shared_preferences_android` ≥ 2.5.4, the latest versions resolvable today.
- [ ] `pubspec.yaml` constraints are unchanged.
- [ ] `flutter analyze`, `flutter test` and `flutter build apk --debug` pass with the committed lock file.
- [ ] `RELEASE_DRY_RUN_SKIP_CHECKS=branch,clean,sync,gh,key tool/release.sh patch --dry-run` passes.
- [ ] `AGENTS.md` notes that `pubspec.lock` is committed.

## Notes

- Owner approved on 2026-11-05 after `flutter pub get` showed the stale versions.
- The owner's local untracked `pubspec.lock` in the main checkout will conflict with the tracked one when this merges. The conductor removes it before the squash-merge.
- Packages held back by the Flutter SDK, such as `material_color_utilities`, `cross_file` and `objective_c`, stay behind until a Flutter update. That is expected, not a defect.
