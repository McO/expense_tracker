---
id: ADR-0011
title: Release process: SemVer with automatic build number, vX.Y.Z tags, changelog from task trailers, GitHub Release, one local script
scope: global
status: accepted
date: 2026-11-05
related_tasks: [infrastructure-dx7t4]
related_adrs: [ADR-0002, ADR-0010]
---

# ADR-0011: Release process: SemVer with automatic build number, vX.Y.Z tags, changelog from task trailers, GitHub Release, one local script

## Context

Until now the app had no release process. `pubspec.yaml` sat at `version: 1.0.0+1`, there were no git tags and no changelog, and APKs were built ad hoc and copied around by hand. Because the build number never changed, a newer build could not be told apart from an older one (Android refuses to install over a build with an equal or higher version code), and nothing recorded what changed between versions. ADR-0002 keeps builds manual and the project has no CI/CD; ADR-0010 made release builds depend on a signing key that lives only on the owner's Mac (`android/key.properties`). A release therefore has to run locally.

## Decision

Releases are cut by one local script, `tool/release.sh <major|minor|patch|X.Y.Z> [--dry-run]`. There is no CI, so ADR-0002's manual-build stance stands and the signing key never leaves the Mac.

- **Versioning.** SemVer `X.Y.Z`, the bump chosen by the owner (`major`, `minor`, `patch`, or an explicit version that must be strictly greater than the current one). The build number (the `+N` in `version: X.Y.Z+N`) increments by exactly one on every release, so every release installs over the previous one. The arithmetic is `bumpVersion` in `tool/release_notes.dart`.
- **Tags.** Annotated tag `vX.Y.Z`, created on the `chore(release): vX.Y.Z` commit and pushed together with `main`. The previous release is found as the latest `v*` tag; with no tag the changelog covers the whole history.
- **Changelog.** `CHANGELOG.md` gets a prepended `## X.Y.Z (YYYY-MM-DD)` section generated from `git log --format=%s <prev-tag>..HEAD`. A commit counts only if its subject matches `<type>(<bc>): <summary> [<task-id>]...` (the trailer is the task-completion marker). Excluded: `model` commits, batch-start, work-session-end bookkeeping, capture, `index ADR-`, task-bounced, reconcile and `chore(release)` commits, and anything without a task-id trailer. One bullet per task id (the newest commit wins), grouped Features (`feature`), Fixes (`bug`, `fix`), Changes (`refactor`) and Chores (everything else, including `chore`, `decision`, `test`). Logic is `renderSection` / `prependSection` in `tool/release_notes.dart`, covered by `test/release_notes_test.dart`.
- **Distribution.** A GitHub Release on McO/expense_tracker, created with `gh release create vX.Y.Z`, with the changelog section as notes and `build/release/expense-tracker-X.Y.Z.apk` attached.
- **Script order, stopping at the first failure, nothing remote touched until all earlier steps passed:** preconditions (on `main`, clean tree, in sync with `origin/main`, `gh auth status` OK, `android/key.properties` present), version, `flutter analyze` and `flutter test`, changelog, signed release build, commit and annotated tag and push, `gh release create`. If a step fails before the release commit, `pubspec.yaml` and `CHANGELOG.md` are restored; if `git commit` itself fails they are unstaged and restored. If the push fails after the local commit and tag exist, the script prints how to retry the push (`git push origin main vX.Y.Z`) or abort (`git tag -d vX.Y.Z && git reset --hard HEAD~1`).
- **`--dry-run`** prints every step and the generated changelog section and writes, commits, tags, pushes and publishes nothing (it also skips analyze, test and build). For testing the refusals only, the env var `RELEASE_DRY_RUN_SKIP_CHECKS` (comma list of `branch,clean,sync,gh,key`) is honoured exclusively together with `--dry-run`; a real run always enforces every precondition.

## Consequences

- Every release has a strictly increasing build number and a recorded SemVer tag; GitHub holds the APK and notes for each version.
- The changelog is only as good as the commit subjects: the task-completion subject (conductor-written from the task) becomes the user-facing line, and a commit without a `[<task-id>]` trailer never appears in it. Hand-made commits are invisible to the changelog by design.
- The publish step is the only one that cannot be rolled back by the script; if `gh release create` fails after the push, the owner reruns that command by hand.
- Releasing by hand (tagging or publishing outside the script) is prose-only discouraged, not enforced; the script is the single place where version format, tag format and changelog source are enforced.
- Complements ADR-0002 (manual builds, no CI) and depends on ADR-0010 (release key and app ID). The first real release is run by the owner.
