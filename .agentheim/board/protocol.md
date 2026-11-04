# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

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

