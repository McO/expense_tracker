# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

---

## 2026-11-04 20:34 -- Modeling / Captured: cash-ledger-s2v1q - Add top-up and correction movement kinds to the model, totals and CSV export (no UI)

**Type:** Modeling / Capture
**BC:** cash-ledger
**Filed to:** todo
**Summary:** Adds top-up and correction movement kinds underneath the UI: model, tolerant persistence, balance vs. statistics totals, CSV export rules (top-up like income, correction with its own configurable category), and a green flutter test.

---

## 2026-11-04 20:29 -- Work session ended

**Type:** Work / Session end
**Completed:** 0 — vacuum guard exit (no ready tasks; 5 open vision questions surfaced, all open 0 days; cash-ledger-p53v9 waits in backlog for refinement)

---

## 2026-11-04 20:17 -- Work session ended

**Type:** Work / Session end
**Duration:** 11m (20:06 batch start to 20:17)
**Completed:** 5 (first-try PASS: 0, re-dispatched: 1, skipped: 4)
**Bounced:** 0
**Failed:** 0
**Escalated after verification:** 0
**Lost-result re-dispatches:** 0
**Lost-result escalations:** 0
**Dispatches:** infrastructure-pr7em: 1, infrastructure-bza94: 1, infrastructure-r5v4d: 1, cash-ledger-ngxsa: 1, design-system-001: 2
**Commits:** 9 (2 batch starts, 5 task integrations, 1 carry-over reconcile, this bookkeeping commit)
**Vision-conformance:** none — batch aligns with vision
**Batch mix:** 100% product-facing / 0% harness / 0% bookkeeping (5 tasks)
**Carry-over:** .agentheim/.dashboard/: committed (ignored via .gitignore — dashboard runtime files, not project bookkeeping)

---

## 2026-11-04 20:16 -- Task verified and completed: design-system-001 - Capture the existing look as a styleguide and sign it off before new UI work

**Type:** Work / Task completion
**Task:** design-system-001 - Capture the existing look as a styleguide and sign it off before new UI work
**Summary:** Styleguide capturing the existing look (tokens, components, patterns) plus the approved quick-glance chart style; owner signed off
**Duration:** 5m50s
**Verification:** PASS (iteration 2)
**Files changed:** 1
**Tests added:** 0
**ADRs written:** none

---

## 2026-11-04 20:13 -- Verification failed: design-system-001 - Capture the existing look as a styleguide and sign it off before new UI work

**Type:** Work / Verification failure
**Task:** design-system-001 - Capture the existing look as a styleguide and sign it off before new UI work
**Iteration:** 1 of 3
**Reasons:** management-lists row misdescribes account and currency screens and omits the AlertDialog form pattern, elevation-2 usage list incomplete, category alpha range wrong
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-11-04 20:11 -- Task completed (verification skipped): cash-ledger-ngxsa - Record the existing CSV export as an ADR (per-wallet date range to Downloads, for MoneyMoney)

**Type:** Work / Task completion
**Task:** cash-ledger-ngxsa - Record the existing CSV export as an ADR (per-wallet date range to Downloads, for MoneyMoney)
**Summary:** Verified the draft CSV export ADR against buildCSV, the home screen export flow and the manifest; filled in the real six-column format and corrected the draft (signed amounts, file naming, permission fallback, date-range edge, hardcoded Downloads path). No source changes.
**Duration:** 3m41s
**Verification:** SKIPPED — decision-only task
**Files changed:** 0

---

## 2026-11-04 20:10 -- Batch started: [cash-ledger-ngxsa, design-system-001]

**Type:** Work / Batch start
**Tasks:** cash-ledger-ngxsa - Record the existing CSV export as an ADR (per-wallet date range to Downloads, for MoneyMoney), design-system-001 - Capture the existing look as a styleguide and sign it off before new UI work
**Parallel:** yes (2 workers) — the whole remaining ready set, second wave after the three infrastructure ADR backfills

---

## 2026-11-04 20:09 -- Task completed (verification skipped): infrastructure-r5v4d - Record the existing persistence as an ADR (SharedPreferences JSON lists, no schema migration)

**Type:** Work / Task completion
**Task:** infrastructure-r5v4d - Record the existing persistence as an ADR (SharedPreferences JSON lists, no schema migration)
**Summary:** Verified the draft persistence ADR against lib/services and lib/models, corrected it (key table, per-model fromJson tolerance, two seeding patterns) and report it as ADR 0002.
**Duration:** 2m09s
**Verification:** SKIPPED — decision-only task
**Files changed:** 0

---

## 2026-11-04 20:09 -- Task completed (verification skipped): infrastructure-bza94 - Record the existing app architecture as an ADR (setState, screen-owned services, imperative navigation)

**Type:** Work / Task completion
**Task:** infrastructure-bza94 - Record the existing app architecture as an ADR (setState, screen-owned services, imperative navigation)
**Summary:** Verified the draft architecture ADR against lib/ and corrected it (loader names vary per screen, services also nest, theme path is root to HomeScreen to SettingsScreen); final ADR returned for materialization.
**Duration:** 2m02s
**Verification:** SKIPPED — decision-only task
**Files changed:** 0

---

## 2026-11-04 20:08 -- Task completed (verification skipped): infrastructure-pr7em - Record the existing platform and toolchain as an ADR (Android-only Flutter, manual builds)

**Type:** Work / Task completion
**Task:** infrastructure-pr7em - Record the existing platform and toolchain as an ADR (Android-only Flutter, manual builds)
**Summary:** Verified the draft platform/toolchain ADR against pubspec.yaml, android/ build files and lib/main.dart, and added the verified toolchain versions (AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, Java 11, Flutter-provided SDK levels, debug-key release signing). No source changes.
**Duration:** 1m53s
**Verification:** SKIPPED — decision-only task
**Files changed:** 0

---

## 2026-11-04 20:06 -- Batch started: [infrastructure-pr7em, infrastructure-bza94, infrastructure-r5v4d]

**Type:** Work / Batch start
**Tasks:** infrastructure-pr7em - Record the existing platform and toolchain as an ADR (Android-only Flutter, manual builds), infrastructure-bza94 - Record the existing app architecture as an ADR (setState, screen-owned services, imperative navigation), infrastructure-r5v4d - Record the existing persistence as an ADR (SharedPreferences JSON lists, no schema migration)
**Parallel:** yes (3 workers, MAX_PARALLEL 3) — cash-ledger-ngxsa and design-system-001 held to the next wave by the cap; grouped the three infrastructure ADR backfills first since they are one BC and code-free

---

## 2026-11-04 20:00 -- Brainstorm: cash ledger feeding MoneyMoney

**Type:** Brainstorm
**Outcome:** vision created
**BCs identified:** cash-ledger (core), infrastructure, design-system
**Summary:** The app is the owner's cash-only ledger, one wallet per currency mirroring a MoneyMoney cash account, handed over by manual CSV export; MoneyMoney stays the system of record. New domain distinction: movements are spending, income, top-up, correction (exchange as nice-to-have), and only spending and income count in the four quick-glance statistics. Trips, budgets, conversion and deep analysis are explicit non-goals.
**ADRs written:** 0001
**Foundation tasks emitted:** infrastructure-pr7em, infrastructure-bza94, infrastructure-r5v4d, cash-ledger-ngxsa (architecture-backfill decisions), design-system-001 (styleguide gate); walking skeleton skipped — app already exists

---

## 2026-11-04 19:56 -- Research: statistics features in cash and travel expense trackers

**Type:** Research
**Requested by:** brainstorm
**Report:** knowledge/research/expense-tracker-stats-inspiration-2026-11-04.md
**Review:** PASS (iteration 3)
**Summary:**
- Baseline across apps: category pie, period totals, filters, CSV export; travel apps add daily budget / left-today, daily or 30-day averages, last-N-days bar charts and widgets.
- Most apps convert to one home currency; Cashew shows original and converted side by side.
- Quick-glance (balance per currency, daily average, recent-days bar, simple category mix) vs. deep analysis (trends, budget history, tag/location reports) that MoneyMoney already covers.

---

