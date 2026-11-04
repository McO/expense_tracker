# Design system

## Purpose
The app's visual language: color and type tokens, reusable components (cards, list rows, pickers,
charts), interaction patterns, and the review process that gates new UI. Captures the existing look
first (Material Design 3, indigo seed `Color(0xFF6366F1)`, light/dark/system themes) so new screens,
starting with the statistics, extend it instead of drifting.

## Classification
supporting

## Actors
- **Owner** — reviews and signs off on the styleguide; that sign-off opens the gate for frontend
  tasks in every BC.

## Ubiquitous language
- **Token** — a named design value (color, spacing, radius, type style).
- **Component** — a reusable widget with a defined look and behaviour (e.g. summary card, category
  card, movement row).
- **Pattern** — a recurring arrangement of components (e.g. dashboard section, form, picker).
- **Styleguide gate** — no frontend task may be promoted until `design-system-001` (styleguide) is
  done and signed off.

## Aggregates
None.

## Key events
- Styleguide signed off

## Key commands
- Propose / revise a token, component or pattern

## Relationships with other contexts
- **Supplier to:** cash-ledger (every UI task depends on the styleguide).

## Open questions
- Which chart style fits the quick-glance statistics (open since 2026-11-04).
