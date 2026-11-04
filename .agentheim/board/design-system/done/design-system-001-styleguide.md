---
id: design-system-001
title: Capture the existing look as a styleguide and sign it off before new UI work
status: done
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

## Verifier note (iteration 1)

**REASONS:**
- Criterion "A styleguide document exists covering tokens, components and patterns as they exist today" is not met: the "Management lists" row (styleguide/README.md line 66) claims all three management screens use a "Card list, `PopupMenuButton` per item, `FloatingActionButton.extended` to add, confirm dialogs for delete". Only `lib/screens/category_management_screen.dart` does (PopupMenuButton at :260, FloatingActionButton.extended at :160). `lib/screens/account_management_screen.dart` uses two trailing `IconButton`s per item (:308, :312) and a plain `FloatingActionButton` (:322). `lib/screens/currency_management_screen.dart` uses a trailing `IconButton` (:341), an app-bar `IconButton` (:282) and no FAB. It also omits that accounts and currencies are added/edited in `AlertDialog` forms (account :59-62, currency :112-115), a separate form pattern the "Forms" row (line 64) misses.
- Smaller accuracy issues: (a) Elevation list (lines 48-52) says elevation 2 is used only for the summary cards in total_expense_card.dart, but `lib/screens/category_management_screen.dart:202` also uses elevation 2. (b) Line 24 says category color is "used as 0.1 to 0.3 alpha tints and borders"; `lib/widgets/category_breakdown.dart` uses 0.03, 0.08, 0.15, 0.3 and 0.4 (:188, :196-197, :213, :215).
- Everything else spot-checked matched the code; scope is clean; sign-off is correctly marked pending and is not a reason for this FAIL.

**SUGGESTED_FIX:** Rewrite the "Management lists" row to describe each screen as it really is (category: PopupMenuButton + FAB.extended; account: IconButtons + plain FAB; currency: IconButtons + app-bar add button, no FAB), note the inconsistency the way the shade-color one is noted, and add the AlertDialog-form pattern used for accounts and currencies. Correct the elevation-2 list and the category alpha range.

**ITERATION_HINT:** likely-fixable

## Outcome

Created the styleguide at `.agentheim/knowledge/contexts/design-system/styleguide/README.md`: tokens (Material 3, seed 0xFF6366F1, light/dark/system, theme overrides, typography, spacing, radii, elevation including category-management cards at 2, semantic money colors, category alpha values as used), components with implementing files, patterns (including the AlertDialog-form pattern for accounts and currencies), and a proposed cash-only chart style for quick-glance statistics. Management-list controls are documented per screen (category: PopupMenuButton + FAB.extended; account: two IconButtons + plain FAB; currency: IconButtons + app-bar add, no FAB) and flagged as an inconsistency, alongside the light-only shade colors in total_expense_card.dart. No lib/ changes, so no behaviour change.

*(At worker hand-off, owner sign-off was still pending; it was given afterwards — see below.)*

**Owner sign-off: given 2026-11-04, as is.** Decisions recorded in the styleguide's section 5: unify management lists on the category style (PopupMenuButton + FloatingActionButton.extended); fix the light-only shade colors in `total_expense_card.dart` (captured as `cash-ledger-p53v9`); chart style in section 4 approved. Verification PASS on iteration 2 (iteration 1 FAIL: management-list, elevation and alpha inaccuracies, fixed).
