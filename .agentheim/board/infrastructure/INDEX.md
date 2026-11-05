# Infrastructure — Index (task board)

Catalog of this bounded context's tasks by status.

> Updated by: `modeling` (tasks), the lifecycle verbs (promote / claim / complete / capture / dismiss / bounce / reroute).
> Hand-edits are fine but the verbs will append at the section markers below.

---

## Tasks by status

<!-- task-counts:start -->
- **Backlog:** 0
- **Todo:** 2
- **Doing:** 0
- **Done:** 4
<!-- task-counts:end -->

### Todo
<!-- todo-list:start -->
- **infrastructure-dx7t4** — One local release script that bumps the SemVer version and build number, writes the changelog from done tasks, tags, and publishes a GitHub Release with the signed APK (feature) — `todo/infrastructure-dx7t4-release-script-versioning-changelog.md`
- **infrastructure-c5nkp** — Sign release builds with a dedicated release key and change the app ID to io.github.mco.expensetracker (chore) — `todo/infrastructure-c5nkp-release-signing-and-app-id.md`
<!-- todo-list:end -->

### Doing
<!-- doing-list:start -->
<!-- doing-list:end -->

### Done (most recent first; older entries kept for prior-art search)
<!-- done-list:start -->
- **infrastructure-pn83e** — Upgrade all dependencies to their latest versions and raise the Dart SDK lower bound to the installed toolchain (chore) — `done/infrastructure-pn83e-upgrade-flutter-dependencies.md`
- **infrastructure-r5v4d** — Record the existing persistence as an ADR (SharedPreferences JSON lists, no schema migration) (decision) — `done/infrastructure-r5v4d-record-persistence.md`
- **infrastructure-bza94** — Record the existing app architecture as an ADR (setState, screen-owned services, imperative navigation) (decision) — `done/infrastructure-bza94-record-app-architecture.md`
- **infrastructure-pr7em** — Record the existing platform and toolchain as an ADR (Android-only Flutter, manual builds) (decision) — `done/infrastructure-pr7em-record-platform-and-toolchain.md`
<!-- done-list:end -->

### Backlog
<!-- backlog-list:start -->
<!-- backlog-list:end -->

## Pointers

- Done-list archive (entries rolled out beyond the live cap, if any): `done-archive/YYYY-MM.md` (ADR-0039 convention, agentic-workflow-c8j3w)
- Knowledge half (ADRs / research / concepts / BC README) for this BC: `../../knowledge/contexts/infrastructure/INDEX.md`
