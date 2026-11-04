---
id: cash-ledger-vsszp
title: Enter movements as a signed amount with a ± toggle, correct a wallet's balance from the counted cash, and flag categories that don't count in statistics
status: backlog
type: feature
context: cash-ledger
created: 2026-11-04
completed:
depends_on: [cash-ledger-qjysm, design-system-001]
blocks: []
tags: [movement-kinds, top-up, correction, category, ui]
related_adrs: [ADR-0003, ADR-0005]
related_research: []
prior_art: [design-system-001, cash-ledger-s2v1q]
---

## Why

The owner redesigned the model after eye-checking the first UI build (2026-11-04): a movement is a
signed amount plus a category, with no Expense/Income/Top-up selector. Top-up and Correction are
ordinary categories, and a per-category "count in statistics" flag keeps them out of the
statistics. `cash-ledger-qjysm` delivers the model; this task is the UI for it.

## What

- **Signed amount entry.** In the add and edit movement forms (`add_expense_screen.dart`,
  `edit_expense_screen.dart`) the Expense/Income type selector (`transaction_type_selector.dart`) is
  replaced by a **± toggle beside the amount field**. A new movement defaults to **−** (money out);
  tapping the toggle flips it. The amount field itself only takes the positive number. Editing an
  existing movement shows its current sign. Form texts no longer say "Expense" where the movement may
  be income (e.g. "Movement details", a neutral title placeholder).
- **Top-up is a category.** Recording a top-up = choosing the Top-up category with **+**. No special
  path.
- **Correct balance.** An entry in the home screen's drawer directly above Export (that drawer is
  where Export lives) opens a dialog (styleguide dialog-form pattern) for the selected wallet: it
  shows the current balance, takes the **counted cash**, shows the signed difference live, and on
  confirm records one movement dated now in the **Correction** category, signed by the difference.
  Equal values record nothing and say so.
- **Category flag.** Category management / the add-edit category screen
  (`add_edit_category_screen.dart`) gains a "Count in statistics" switch for the
  `countsInStatistics` flag. Management-list controls follow the category style (styleguide
  decision 2026-11-04).
- **Display.** Movement rows (`recent_expenses.dart`, `expenses_list_screen.dart`) and the detail
  screen colour the signed amount by sign (+ green, − red, per the styleguide); movements in a
  category that doesn't count in statistics (e.g. Top-up, Correction) are visibly marked so they read
  as "not income/spending" (e.g. a neutral, scheme-aware colour or a small label).
- **Settings.** Nothing new; make sure no correction-export-category field remains (the setting is
  removed by `cash-ledger-qjysm`).
- Follow the signed-off styleguide (`.agentheim/knowledge/contexts/design-system/styleguide/README.md`).

## Acceptance criteria

- [ ] The add form has no Expense/Income/Top-up selector; a ± toggle beside the amount defaults to −,
      and saving stores a movement whose direction matches the toggle, covered by a widget test.
- [ ] The edit form shows an existing movement's sign on the toggle and saving after flipping it
      changes the stored direction, covered by a widget test.
- [ ] "Correct balance" in the home drawer records one movement in the Correction category, + when
      the counted cash exceeds the balance and − when lower, and nothing (with a message) when equal;
      afterwards the wallet balance equals the counted cash. Covered by a widget or service test.
- [ ] The category form reads and saves the "Count in statistics" switch, covered by a widget test.
- [ ] Movement rows show + amounts and − amounts in their sign colours, and mark movements in
      non-counting categories distinctly, covered by a widget test.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] The signed-amount form, the ± toggle and the marking of non-counting movements look
      consistent with the styleguide in light and dark mode. [human-eye]

## Notes

- Depends on `cash-ledger-qjysm` (model: direction from sign, Top-up/Correction categories,
  `countsInStatistics`, statistics by flag, export by category name) and the signed-off styleguide
  `design-system-001`.
- Refined 2026-11-04 after the owner's redesign. The earlier, verified UI for the old kinds is
  salvaged at `.agentheim/salvage/cash-ledger-vsszp-bounced.patch` — reusable pieces: the Correct
  balance dialog (`correct_balance_dialog.dart`), `movement_style.dart`, the drawer entry, widget
  test scaffolding. Its type-selector and settings-field parts are obsolete.
- Owner observations from the eye-check, fold in here: the form said "Expense Details" / "Enter
  expense title" for a top-up, and the `$` currency box had a light background in dark mode.

## Worker note

Owner redesign after eye-checking the build (2026-11-04): no Expense/Income/Top-up selector — a movement is a signed amount (± toggle, default −) plus a category; Top-up and Correction become ordinary categories; a per-category "count in statistics" flag (off for Top-up and Correction) keeps them out of statistics. The verified iteration-1 UI (salvage patch kept) no longer matches the model; refine this task against the new model task instead of merging.
