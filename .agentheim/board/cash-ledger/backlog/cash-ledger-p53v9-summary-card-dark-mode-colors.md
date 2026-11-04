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

Raw capture, needs refinement. Move the net-balance, income and expense cards in
`total_expense_card.dart` to scheme-aware colors (color-scheme roles or alpha tints of the semantic
colors, as the category and movement widgets already do), keeping green = income, red = expense and
the positive/negative net-balance distinction.

## Acceptance criteria

To be refined.

## Notes

Frontend task: depends on the styleguide gate (`design-system-001`, signed off).
