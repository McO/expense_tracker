# Index

Top-level catalog of this project's bounded contexts, global decisions, and research.
For BC-scoped artifacts, see each BC's `INDEX.md`.

> Updated by: `modeling` (BC creation), `work` (global ADRs), `research` (reports tagged global / cross-BC), backfill script.
> Hand-edits are fine but the skills will append at the section markers below.

---

## Bounded contexts

<!-- bc-list:start -->
- **design-system** — tokens, components, patterns and the styleguide gate for new UI — `contexts/design-system/INDEX.md`
- **infrastructure** — globally-true tech concerns: platform, toolchain and dependency updates, persistence, app-wide conventions, builds — `contexts/infrastructure/INDEX.md`
- **cash-ledger** — recording cash transactions per currency account, balances, quick-glance cash statistics, CSV export for MoneyMoney — `contexts/cash-ledger/INDEX.md`
<!-- bc-list:end -->

## Global ADRs (scope: global)

<!-- adr-global:start -->
- **0011** — Release process: SemVer + auto build number, vX.Y.Z tags, changelog from task trailers, GitHub Release, one local script (tool/release.sh) — 2026-11-05 — `knowledge/decisions/0011-release-process-semver-task-trailer-changelog-github-release.md`
- **0010** — Releases are signed with one dedicated key (outside the repo); app ID is permanently io.github.mco.expensetracker (amends 0002) — 2026-11-05 — `knowledge/decisions/0010-release-signing-key-and-permanent-app-id.md`
- **0004** — All data in SharedPreferences as JSON lists, without schema migration — 2026-11-04 — `knowledge/decisions/0004-all-data-in-sharedpreferences-json-lists-without-schema-migration.md`
- **0003** — Plain setState, screen-owned services and imperative navigation — 2026-11-04 — `knowledge/decisions/0003-plain-setstate-screen-owned-services-imperative-navigation.md`
- **0002** — Android-only Flutter app on the stable channel, built and released manually — 2026-11-04 — `knowledge/decisions/0002-android-only-flutter-stable-manual-builds.md`
- **0001** — The app is a cash-only ledger; MoneyMoney is the system of record — 2026-11-04 — `knowledge/decisions/0001-cash-only-ledger-moneymoney-system-of-record.md`
<!-- adr-global:end -->

## Cross-BC research

Research reports relevant to more than one BC (or to the project as a whole). BC-specific
reports are listed in each BC's `INDEX.md`.

<!-- research-global:start -->
- **expense-tracker-stats-inspiration** — statistics features in cash/travel expense trackers, split into quick-glance vs. deep analysis — 2026-11-04 — `knowledge/research/expense-tracker-stats-inspiration-2026-11-04.md`
<!-- research-global:end -->

## Pointers

- Vision: `vision.md`
- Context map: `context-map.md` (if exists)
- Protocol (chronological log): `../board/protocol.md` — newest entries on top; capped at ~1,000 lines, older months roll out verbatim to `../board/protocol/YYYY-MM.md` (ADR-0039)
- All ADRs: `knowledge/decisions/`
- All research: `knowledge/research/`
