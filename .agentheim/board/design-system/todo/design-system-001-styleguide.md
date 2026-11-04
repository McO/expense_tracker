---
id: design-system-001
title: Capture the existing look as a styleguide and sign it off before new UI work
status: todo
type: feature
context: design-system
created: 2026-11-04
depends_on: []
blocks: []
tags: [styleguide, design-system, gate, foundation]
related_adrs: []
related_research: [expense-tracker-stats-inspiration-2026-11-04]
prior_art: []
---

## Why

New UI is coming (quick-glance cash statistics, cleaned-up currency and category management).
Without a written styleguide, each screen reinvents cards, spacing and chart styling. The app
already has a consistent look; this captures it so new screens extend it.

No walking-skeleton dependency: the app already runs (mature project, foundation pass adapted).

## What

- Document the existing tokens: Material 3, seed `Color(0xFF6366F1)`, light/dark/system themes,
  typography, spacing and radii actually used.
- Document the existing components and patterns: total/summary card (`total_expense_card.dart`),
  category card carousel (`category_breakdown.dart`), movement rows and swipe-to-delete
  (`recent_expenses.dart`), transaction-type toggle, account/date-range pickers, forms.
- Propose the chart style for quick-glance statistics (e.g. simple category bar/pie, recent-days
  bar), informed by the research report's quick-glance list.
- Keep it in-repo and short; no new design tooling.

## Acceptance criteria

- A styleguide document exists covering tokens, components and patterns as they exist today,
  plus a proposed chart style for statistics.
- Every listed component points to the widget file that implements it.
- **Owner has reviewed and signed off on the styleguide before any frontend feature task is
  promoted.** This is a gate, not just a deliverable.
- No behaviour change to existing screens.

## Notes

Gate rule: every frontend task in any BC must `depends_on: [design-system-001]`
(recorded in `cash-ledger` README).
