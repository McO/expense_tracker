---
id: cash-ledger-p53v9
title: Make the summary card's money colors work in dark mode
status: done
type: bug
context: cash-ledger
created: 2026-11-04
depends_on: [design-system-001]
blocks: []
tags: [ui, dark-mode, styleguide, summary-card]
related_adrs: []
related_research: []
prior_art: [design-system-001]
---

## Why

The styleguide (design-system-001, section 1 "Color") found that `lib/widgets/total_expense_card.dart`
uses light-only `Colors.<x>.shadeNN` tints (green/red/blue/orange `shade50` fills, `shade700` text),
which give poor contrast in dark mode. The owner decided at styleguide sign-off (2026-11-04) to fix
it.

## What

Move the net-balance, income and expense cards in
`total_expense_card.dart` to scheme-aware colors (color-scheme roles or alpha tints of the semantic
colors, as the category and movement widgets already do), keeping green = income, red = expense and
the positive/negative net-balance distinction.

## Acceptance criteria

- [ ] `lib/widgets/total_expense_card.dart` uses no `Colors.<x>.shadeNN` tints; its fills and text
      colours derive from the theme's colour scheme or from alpha tints of the semantic colours, so
      they adapt to dark mode. Covered by a widget test that pumps the card under a dark theme and
      asserts no shade constant is used (e.g. the card's container colours differ between light and
      dark themes).
- [ ] Income stays green, expense stays red, and the net-balance card still distinguishes positive
      from negative, covered by a widget test.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] The summary card reads well in both light and dark mode. [human-eye]

## Notes

Frontend task: depends on the styleguide gate (`design-system-001`, signed off).

## Verifier note (iteration 1)

**REASONS:**
- The code is correct: 38 tests pass, the new tests fail on the old code, `flutter analyze` is clean, and no `shadeNN` is left. But section 1 "Color" of the design-system styleguide README (lines 19-25) still describes the old money colours: hard-coded `green`/`red`/`blue`/`orange` `shade50`/`shade700`. Line 25 still calls the `total_expense_card.dart` shades a "known inconsistency". After this merge, none of that is true.
- The positive net balance moves from blue to `colorScheme.primary`, and every fill is now a 16% alpha blend over `surface` with text mixed 30% toward `onSurface`. Nothing records this. The styleguide is the frontend gate, so a future worker reading it would bring back the old tints.
- Everything else passes. The colours follow the styleguide's own rules ("prefer scheme roles or alpha tints", "tint plus tone").

**SUGGESTED_FIX:** Keep the code and tests. Update section 1 "Color" of `.agentheim/knowledge/contexts/design-system/styleguide/README.md`, lines 19-25 (the styleguide-source carve-out allows editing it in the worktree). Describe the summary card's money colours as alpha tints of the semantic colours over `colorScheme.surface`, with text mixed toward `onSurface`: income green, expense red, net-balance positive `colorScheme.primary`, negative orange. Remove the "known inconsistency" note.

**ITERATION_HINT:** likely-fixable

## Verifier note (iteration 2)

**REASONS:**
- Code, tests (38 pass), analyze and the new section 1 wording are all fine.
- Defect: the deleted "Known inconsistency" bullet also carried the styleguide's forward-looking rule, "New components should prefer scheme roles or alpha tints (`color.withValues(alpha: ...)`)". That rule is now stated nowhere else, so nothing stops a future worker from reintroducing `Colors.x.shadeNN`.

**SUGGESTED_FIX:** Keep everything. Add one bullet back to section 1 "Color": "New components should prefer scheme roles or alpha tints (`color.withValues(alpha: ...)`) over fixed `Colors.x.shadeNN` tints, as the summary card, category and movement widgets do." Leave out the "known inconsistency" wording.

**ITERATION_HINT:** likely-fixable

## Outcome

`lib/widgets/total_expense_card.dart` no longer uses any `Colors.<x>.shadeNN` tint. A private `_Tone` helper derives each card's fill (the semantic colour at 16% alpha, blended over `colorScheme.surface`) and its foreground (the semantic colour mixed 30% toward `onSurface`). Income is `Colors.green` and expense is `Colors.red`. The positive net balance uses `colorScheme.primary`, replacing blue, and the negative net balance uses `Colors.orange`. Four widget tests in `test/total_expense_card_colors_test.dart` cover the light/dark difference, the absence of shade constants, green and red in both modes, and positive versus negative. Section 1 "Color" of the styleguide now describes these colours and drops the shadeNN "known inconsistency" note. It keeps the rule that new components prefer scheme roles or alpha tints over fixed shade tints. `flutter test` and `flutter analyze` pass. The [human-eye] check in light and dark mode is still pending with the owner.
