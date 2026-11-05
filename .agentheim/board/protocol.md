# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

---

## 2026-11-05 09:43 -- Task verified and completed: cash-ledger-f150f - Account and currency management screens use the category list style (popup menu per item, extended add button)

**Type:** Work / Task completion
**Task:** cash-ledger-f150f - Account and currency management screens use the category list style (popup menu per item, extended add button)
**Summary:** Wallet and currency management lists use the category style (popup menu per item, extended add button); styleguide Management lists row unified
**Duration:** 6m
**Verification:** PASS (iteration 1)
**Files changed:** 5
**Tests added:** 7
**ADRs written:** none

---

## 2026-11-05 09:40 -- Task verified and completed: cash-ledger-p53v9 - Make the summary card's money colors work in dark mode

**Type:** Work / Task completion
**Task:** cash-ledger-p53v9 - Make the summary card's money colors work in dark mode
**Summary:** Summary card money colours come from scheme-aware alpha tints so they work in dark mode; styleguide Color section updated
**Duration:** 14m
**Verification:** PASS (iteration 3)
**Files changed:** 3
**Tests added:** 4
**ADRs written:** none

---

## 2026-11-05 09:39 -- Batch started: [cash-ledger-f150f]

**Type:** Work / Batch start
**Tasks:** cash-ledger-f150f - Account and currency management screens use the category list style (popup menu per item, extended add button)
**Parallel:** yes (joins in-flight cash-ledger-p53v9 iteration 3; unblocked by cash-ledger-apzzm)

---

## 2026-11-05 09:38 -- Task verified and completed: cash-ledger-apzzm - A movement's currency is always its wallet's; drop the global default currency; deleting a wallet deletes its movements after a confirm

**Type:** Work / Task completion
**Task:** cash-ledger-apzzm - A movement's currency is always its wallet's; drop the global default currency; deleting a wallet deletes its movements after a confirm
**Summary:** A movement's currency is always its wallet's (load, display, CSV, form save); the unused default-currency setting is gone; deleting a wallet deletes its movements after a confirm naming the count
**Duration:** 9m
**Verification:** PASS (iteration 2)
**Files changed:** 7
**Tests added:** 7
**ADRs written:** none

---

## 2026-11-05 09:38 -- Verification failed: cash-ledger-p53v9 - Make the summary card's money colors work in dark mode

**Type:** Work / Verification failure
**Task:** cash-ledger-p53v9
**Iteration:** 2 of 3
**Reasons:** styleguide edit dropped the forward-looking prefer-scheme-roles-or-alpha-tints rule along with the inconsistency note
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-11-05 09:36 -- Verification failed: cash-ledger-p53v9 - Make the summary card's money colors work in dark mode

**Type:** Work / Verification failure
**Task:** cash-ledger-p53v9
**Iteration:** 1 of 3
**Reasons:** styleguide section 1 Color still documents the removed shadeNN tints and blue positive balance; change not recorded
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-11-05 09:36 -- Verification failed: cash-ledger-apzzm - A movement's currency is always its wallet's; drop the global default currency; deleting a wallet deletes its movements after a confirm

**Type:** Work / Verification failure
**Task:** cash-ledger-apzzm
**Iteration:** 1 of 3
**Reasons:** edit form save untested, add-form test reads back through the overriding read path so cannot catch a wrong save, README_DELTA missing for two new domain rules
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-11-05 09:32 -- Batch started: [cash-ledger-apzzm, cash-ledger-p53v9]

**Type:** Work / Batch start
**Tasks:** cash-ledger-apzzm - A movement's currency is always its wallet's; drop the global default currency; deleting a wallet deletes its movements after a confirm, cash-ledger-p53v9 - Make the summary card's money colors work in dark mode
**Parallel:** yes (2 workers — cash-ledger-f150f blocked on cash-ledger-apzzm, follows next wave)
**Planning advisory:** whats-next (stale — background context): model the currency and category cleanup; done, these tasks are its output

---

## 2026-11-05 09:29 -- Modeling / Promoted: cash-ledger-p53v9 - Make the summary card's money colors work in dark mode

**Type:** Modeling / Promote
**BC:** cash-ledger
**From → To:** backlog → todo

---

## 2026-11-05 09:29 -- Modeling / Refined: cash-ledger-p53v9 - Make the summary card's money colors work in dark mode

**Type:** Modeling / Refine
**BC:** cash-ledger
**Status after:** todo
**Summary:** Acceptance criteria written: no shadeNN tints in total_expense_card.dart, scheme-aware/alpha colours that adapt to dark mode, semantic green/red and the net-balance distinction kept, tests and an owner eye-check.
**ADRs written:** none

---

## 2026-11-05 09:29 -- Modeling / Captured: cash-ledger-f150f - Account and currency management screens use the category list style (popup menu per item, extended add button)

**Type:** Modeling / Capture
**BC:** cash-ledger
**Filed to:** todo
**Summary:** Currency and category cleanup (cash-ledger-f150f), owner decisions 2026-11-05.

---

## 2026-11-05 09:29 -- Modeling / Captured: cash-ledger-apzzm - A movement's currency is always its wallet's; drop the global default currency; deleting a wallet deletes its movements after a confirm

**Type:** Modeling / Capture
**BC:** cash-ledger
**Filed to:** todo
**Summary:** Currency and category cleanup (cash-ledger-apzzm), owner decisions 2026-11-05.

---

## 2026-11-05 09:20 -- Work session ended

**Type:** Work / Session end
**Duration:** about 15m of work (09:09 batch start to merge, plus the owner eye-check)
**Completed:** 1 (first-try PASS: 0, re-dispatched: 1, skipped: 0)
**Bounced:** 0
**Failed:** 0
**Escalated after verification:** 0
**Lost-result re-dispatches:** 0
**Lost-result escalations:** 0
**Dispatches:** cash-ledger-bktw5: 2
**Commits:** 3 (batch start, task integration, this bookkeeping commit)
**Vision-conformance:** none — batch aligns with vision
**Batch mix:** 100% product-facing / 0% harness / 0% bookkeeping (1 task)
**Carry-over:** none — working tree clean

---

## 2026-11-05 09:19 -- Task verified and completed: cash-ledger-bktw5 - Add a Statistics screen with the four quick-glance cash statistics for the selected wallet

**Type:** Work / Task completion
**Task:** cash-ledger-bktw5 - Add a Statistics screen with the four quick-glance cash statistics for the selected wallet
**Summary:** Added a Statistics screen (home drawer entry) with the wallet balance and Correct balance, burn rate (daily average, lasts ~N days, 7-day bars) and spending mix over This month or Last 7 days; iteration 2 hardens the unit tests for mix ordering and floor/zero-balance cases.
**Duration:** 9m
**Verification:** PASS (iteration 2); human-eye criterion checked by the owner
**Files changed:** 5
**Tests added:** 14
**ADRs written:** none

---

## 2026-11-05 09:14 -- Verification failed: cash-ledger-bktw5 - Add a Statistics screen with the four quick-glance cash statistics for the selected wallet

**Type:** Work / Verification failure
**Task:** cash-ledger-bktw5 - Add a Statistics screen with the four quick-glance cash statistics for the selected wallet
**Iteration:** 1 of 3
**Reasons:** spending-mix test data already in size order so the largest-first sort is untested, lasts-N-days unit tests cannot tell floor from round and miss the balance == 0 boundary
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-11-05 09:09 -- Batch started: [cash-ledger-bktw5]

**Type:** Work / Batch start
**Tasks:** cash-ledger-bktw5 - Add a Statistics screen with the four quick-glance cash statistics for the selected wallet
**Parallel:** no (1 worker) — the only ready task
**Planning advisory:** whats-next (current): model and build the quick-glance statistics — this task

---

## 2026-11-05 09:09 -- Modeling / Captured: cash-ledger-bktw5 - Add a Statistics screen with the four quick-glance cash statistics for the selected wallet

**Type:** Modeling / Capture
**BC:** cash-ledger
**Filed to:** todo
**Summary:** Statistics screen for the selected wallet: balance with Correct balance, burn rate (this month by default, daily average plus lasts ~N days, last-7-days bars) and spending mix, period switch This month / Last 7 days. Resolves the burn-rate-period open question.

---

## 2026-11-04 23:17 -- Work session ended

**Type:** Work / Session end
**Duration:** about 2h (21:09 batch start, paused on a usage limit, to session end)
**Completed:** 2 (first-try PASS: 2, re-dispatched: 0, skipped: 0)
**Bounced:** 0
**Failed:** 0
**Escalated after verification:** 0
**Lost-result re-dispatches:** 0
**Lost-result escalations:** 0
**Dispatches:** cash-ledger-qjysm: 1, cash-ledger-vsszp: 1
**Commits:** 7 (2 batch starts, 1 promotion, 2 task integrations, 1 owner-requested label fix for cash-ledger-vsszp, this bookkeeping commit)
**Vision-conformance:** none — batch aligns with vision
**Batch mix:** 100% product-facing / 0% harness / 0% bookkeeping (2 tasks)
**Carry-over:** none — working tree clean

---

## 2026-11-04 23:16 -- Task verified and completed: cash-ledger-vsszp - Enter movements as a signed amount with a ± toggle, correct a wallet's balance from the counted cash, and flag categories that don't count in statistics

**Type:** Work / Task completion
**Task:** cash-ledger-vsszp - Enter movements as a signed amount with a ± toggle, correct a wallet's balance from the counted cash, and flag categories that don't count in statistics
**Summary:** Movements are now entered with a ± toggle beside the amount (default −) instead of a type selector, the home drawer has a Correct balance entry that records a signed Correction movement, the category form has a Count in statistics switch, and rows/detail colour by sign and mark non-counting movements.
**Duration:** 13m
**Verification:** PASS (iteration 1); human-eye criterion checked by the owner
**Files changed:** 12
**Tests added:** 7
**ADRs written:** none

---

## 2026-11-04 21:14 -- Batch started: [cash-ledger-vsszp]

**Type:** Work / Batch start
**Tasks:** cash-ledger-vsszp - Enter movements as a signed amount with a ± toggle, correct a wallet's balance from the counted cash, and flag categories that don't count in statistics
**Parallel:** no (1 worker) — only ready task, unblocked by cash-ledger-qjysm

---

## 2026-11-04 21:14 -- Modeling / Promoted: cash-ledger-vsszp - Enter movements as a signed amount with a ± toggle, correct a wallet's balance from the counted cash, and flag categories that don't count in statistics

**Type:** Modeling / Promote
**BC:** cash-ledger
**From → To:** backlog → todo

---

## 2026-11-04 21:13 -- Task verified and completed: cash-ledger-qjysm - Replace the top-up/correction kinds with signed amounts plus a per-category "count in statistics" flag

**Type:** Work / Task completion
**Task:** cash-ledger-qjysm - Replace the top-up/correction kinds with signed amounts plus a per-category "count in statistics" flag
**Summary:** A movement is now a signed amount plus a category. Top-up and Correction are seeded categories, and a per-category countsInStatistics flag keeps them out of statistics while the balance still counts them. The correction export setting is gone.
**Duration:** 5m50s
**Verification:** PASS (iteration 1)
**Files changed:** 9
**Tests added:** 10
**ADRs written:** 0007
**README delta:** README.md §Ubiquitous language anchors "Movement" and "Export name": merged — observed current text: "- **Movement** — any change to a wallet's balance. Kinds:" and "- **Export name** — the MoneyMoney category a category maps to on export" (both multi-line bullets; a first-line `expected` does not match the whole bullet, so the delta tool appended instead of replacing); the superseded entries were removed by hand and the Aggregates "Movement" line updated to the new model. ADR-0006 marked superseded_by ADR-0007.

---

## 2026-11-04 21:09 -- Batch started: [cash-ledger-qjysm]

**Type:** Work / Batch start
**Tasks:** cash-ledger-qjysm - Replace the top-up/correction kinds with signed amounts plus a per-category "count in statistics" flag
**Parallel:** no (1 worker) — only ready task; cash-ledger-vsszp waits in backlog until this is done

---

## 2026-11-04 21:03 -- Modeling / Refined: cash-ledger-vsszp - Enter movements as a signed amount with a ± toggle, correct a wallet balance from the counted cash, and flag categories that do not count in statistics

**Type:** Modeling / Refine
**BC:** cash-ledger
**Status after:** todo
**Summary:** Rewritten against the owner redesign: ± toggle (default −) replaces the Expense/Income/Top-up selector, Correct balance records a signed movement in the Correction category, category form gains a Count in statistics switch, rows colour by sign and mark non-counting categories. Now depends on cash-ledger-qjysm instead of cash-ledger-s2v1q.
**ADRs written:** none

---

## 2026-11-04 21:03 -- Modeling / Captured: cash-ledger-qjysm - Replace the top-up/correction kinds with signed amounts plus a per-category "count in statistics" flag

**Type:** Modeling / Capture
**BC:** cash-ledger
**Filed to:** todo
**Summary:** Owner redesign after eye-checking the build: a movement is a signed amount plus a category; Top-up and Correction become categories with a per-category count-in-statistics flag; supersedes the kinds from cash-ledger-s2v1q (ADR-0006).

---

## 2026-11-04 21:02 -- Work session ended

**Type:** Work / Session end
**Duration:** 26m (20:36 batch start to 21:02)
**Completed:** 1 (first-try PASS: 0, re-dispatched: 1, skipped: 0)
**Bounced:** 1 (cash-ledger-vsszp — verified PASS, then bounced on the owner's redesign after eye-checking the running build: signed amount + category instead of kinds)
**Failed:** 0
**Escalated after verification:** 0
**Lost-result re-dispatches:** 0
**Lost-result escalations:** 0
**Dispatches:** cash-ledger-s2v1q: 2, cash-ledger-vsszp: 1
**Commits:** 5 (2 batch starts, 1 task integration, 1 bounce, this bookkeeping commit)
**Vision-conformance:** none — batch aligns with vision
**Batch mix:** 100% product-facing / 0% harness / 0% bookkeeping (1 task)
**Carry-over:** none — working tree clean

---

## 2026-11-04 21:02 -- Task bounced: cash-ledger-vsszp - Let the owner record top-ups and correct a wallet's balance by entering the counted cash

**Type:** Work / Task bounced
**BC:** cash-ledger
**From → To:** doing → backlog
**Reason:** Owner redesign after eye-checking the build (2026-11-04): no Expense/Income/Top-up selector — a movement is a signed amount (± toggle, default −) plus a category; Top-up and Correction become ordinary categories; a per-category "count in statistics" flag (off for Top-up and Correction) keeps them out of statistics. The verified iteration-1 UI (salvage patch kept) no longer matches the model; refine this task against the new model task instead of merging.

---

## 2026-11-04 20:44 -- Batch started: [cash-ledger-vsszp]

**Type:** Work / Batch start
**Tasks:** cash-ledger-vsszp - Let the owner record top-ups and correct a wallet's balance by entering the counted cash
**Parallel:** no (1 worker) — the only ready task; unblocked by cash-ledger-s2v1q

---

## 2026-11-04 20:44 -- Task verified and completed: cash-ledger-s2v1q - Add top-up and correction movement kinds to the model, totals and CSV export (no UI)

**Type:** Work / Task completion
**Task:** cash-ledger-s2v1q - Add top-up and correction movement kinds to the model, totals and CSV export (no UI)
**Summary:** TransactionType now has top-up and correction (in/out) kinds that round-trip through storage, count in the wallet balance but are excluded from income/expense totals, savings rate and category breakdown, and export to CSV (top-up like income, correction signed under a configurable category defaulting to "Correction"). The broken widget test is replaced and flutter test and flutter analyze are green.
**Duration:** 8m40s
**Verification:** PASS (iteration 2)
**Files changed:** 13
**Tests added:** 9
**ADRs written:** 0006
**README delta:** README.md §Ubiquitous language anchor "Movement": merged — observed current text: "- **Movement** — any change to a wallet's balance. Kinds:" (the worker's `expected` omitted " Kinds:"); the superseded pre-change Movement entry was then removed by hand so only the new one remains

---

## 2026-11-04 20:41 -- Verification failed: cash-ledger-s2v1q - Add top-up and correction movement kinds to the model, totals and CSV export (no UI)

**Type:** Work / Verification failure
**Task:** cash-ledger-s2v1q - Add top-up and correction movement kinds to the model, totals and CSV export (no UI)
**Iteration:** 1 of 3
**Reasons:** home Net Balance still computed as income − expenses from statistics figures so it omits top-ups and corrections (LedgerTotals.balance unused), amount colour still keyed on isIncome while the sign uses increasesBalance
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-11-04 20:36 -- Batch started: [cash-ledger-s2v1q]

**Type:** Work / Batch start
**Tasks:** cash-ledger-s2v1q - Add top-up and correction movement kinds to the model, totals and CSV export (no UI)
**Parallel:** no (1 worker) — cash-ledger-vsszp depends on this task and runs in the next wave

---

## 2026-11-04 20:35 -- Modeling / Captured: cash-ledger-vsszp - Let the owner record top-ups and correct a wallet's balance by entering the counted cash

**Type:** Modeling / Capture
**BC:** cash-ledger
**Filed to:** todo
**Summary:** UI for the new movement kinds: Top-up in the add/edit forms, a Correct balance dialog that takes the counted cash and records the difference, distinct row display, and a settings field for the correction export category. Depends on cash-ledger-s2v1q and the styleguide.

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

