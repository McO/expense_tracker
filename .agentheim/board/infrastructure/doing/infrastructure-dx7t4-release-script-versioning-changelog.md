---
id: infrastructure-dx7t4
title: One local release script that bumps the SemVer version and build number, writes the changelog from done tasks, tags, and publishes a GitHub Release with the signed APK
status: doing
type: feature
context: infrastructure
created: 2026-11-05
completed:
depends_on: [infrastructure-c5nkp]
blocks: []
tags: [release, versioning, changelog, github, toolchain]
related_adrs: [ADR-0002]
related_research: []
prior_art: [infrastructure-pn83e]
---

## Why

The app has never had a release: `pubspec.yaml` is still at `version: 1.0.0+1`, there are no git
tags and no changelog. APKs have been built ad hoc and copied around by hand. Because the build
number never changes, a newer build cannot be told apart from an older one, and nothing records
what changed between versions.

Owner decisions (modeling, 2026-11-05):
- the release lands as a GitHub Release with the signed APK attached;
- one local script runs the release (keeping ADR-0002's manual builds; the signing key never
  leaves the Mac);
- SemVer, with the owner choosing the bump and the build number incrementing automatically;
- the changelog is generated from the Agentheim tasks completed since the last release.

## What

- **`tool/release.sh <major|minor|patch|X.Y.Z>`.** One command that runs these steps in order and
  stops at the first failure, changing nothing remote unless every earlier step passed:
  1. **Preconditions.** On `main`, working tree clean, in sync with `origin/main`. `gh auth
     status` OK. `android/key.properties` present (infrastructure-c5nkp).
  2. **Version.** Compute the new `X.Y.Z` from the current `pubspec.yaml` version and the argument.
     Set the build number to the current build number + 1, so every release installs over the
     previous one. Write `version: X.Y.Z+N` to `pubspec.yaml`.
  3. **Checks.** `flutter analyze` and `flutter test` must pass.
  4. **Changelog.** Prepend a `## X.Y.Z (YYYY-MM-DD)` section to `CHANGELOG.md`, creating the file
     if missing. List one bullet per Agentheim task completed since the previous `v*` tag
     (`git log <prev-tag>..HEAD`, task-completion commits identified by their `[<task-id>]`
     trailer and conventional `<type>(<bc>):` subject). Group them by type (Features, Fixes,
     Changes/Refactors, Chores). Leave out batch-start, bookkeeping, capture and modeling commits.
     The first release, with no previous tag, covers the whole history.
  5. **Build.** `flutter build apk --release`, signed with the release key. Copy the APK to
     `build/release/expense-tracker-X.Y.Z.apk`.
  6. **Commit and tag.** Commit `pubspec.yaml` and `CHANGELOG.md` as
     `chore(release): vX.Y.Z`, create an annotated tag `vX.Y.Z`, then push the commit and the tag.
  7. **Publish.** `gh release create vX.Y.Z` on McO/expense_tracker, with the new changelog
     section as notes and the APK attached.
- **Testability.**
  - Put the version arithmetic and changelog generation in a small script or Dart tool that can
    be tested without git remotes or a build (e.g. `tool/release_notes.dart`), with unit tests.
  - Give the script a `--dry-run` flag that prints every step and the generated changelog section
    without writing, committing, pushing or publishing.
- **Docs.**
  - **AGENTS.md:** add a "Releasing" section covering the command, the preconditions and what it
    produces, and replace the "No CI/CD … releases are done manually" gotcha with a pointer to it.
  - **ADR:** record the release process (SemVer + auto build number, the tag format `vX.Y.Z`, the
    changelog from task trailers, GitHub Release as the distribution channel, local script, no
    CI). It complements ADR-0002.

## Acceptance criteria

- [ ] Version arithmetic is covered by unit tests:
      - `1.0.0+1` with `patch` → `1.0.1+2`;
      - with `minor` → `1.1.0+2`;
      - with `major` → `2.0.0+2`;
      - with explicit `1.4.0` → `1.4.0+2`;
      - a lower or equal explicit version is rejected.
- [ ] Changelog generation is covered by unit tests over a fixture commit list. They check:
      - task commits are grouped by type, one bullet each, with the summary and task id;
      - bookkeeping, batch-start, capture and modeling commits are excluded;
      - the first release with no previous tag includes everything.
- [ ] `tool/release.sh patch --dry-run` on a clean main prints the planned version, the changelog
      section, and the build, tag, push and release steps, and leaves `git status` clean with no
      new tag. The Outcome shows the actual dry-run output.
- [ ] The script refuses to run on a dirty tree, off `main`, out of sync with origin, without `gh`
      auth, or without `android/key.properties`, each with a clear message. Covered by a test or by
      a demonstrated dry run.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] AGENTS.md has a "Releasing" section, and the ADR exists and matches the script.
- [ ] The owner runs the first real release (`tool/release.sh minor`, giving v1.1.0). It appears on
      GitHub with the APK attached, and that APK installs on the phone. [human-eye]

## Notes

- Owner decisions 2026-11-05: GitHub Release, one local script, SemVer with automatic build
  number, changelog from done tasks.
- Depends on infrastructure-c5nkp, which provides the release signing key and the new app ID.
- A worker must not run a real release (push, tag or publish) while working this task. Only the
  dry run and the unit tests are in scope. The first real release is the owner's
  `[human-eye]` step.
- `gh` 2.101.0 is installed; the remote is `https://github.com/McO/expense_tracker.git`.
- Convention check: the release script itself enforces the process (version format, tag, the
  changelog source), so there is no separate lint. Running releases through the script rather than
  by hand is prose-only, unenforced.
