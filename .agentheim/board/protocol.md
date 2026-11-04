# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

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

