---
id: cash-ledger-p53v9
title: Make the summary card's money colors work in dark mode
status: backlog
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
