---
id: cash-ledger-vsszp
title: Let the owner record top-ups and correct a wallet's balance by entering the counted cash
status: todo
type: feature
context: cash-ledger
created: 2026-11-04
completed:
depends_on: [cash-ledger-s2v1q, design-system-001]
blocks: []
tags: [movement-kinds, top-up, correction, ui, settings]
related_adrs: [ADR-0003, ADR-0005]
related_research: []
prior_art: [design-system-001]
---

## Why

`cash-ledger-s2v1q` adds top-up and correction movement kinds to the model, totals and export, but
nothing in the app lets the owner create them. Top-ups (ATM withdrawals, currency bought) need to be
recordable like any movement, and corrections exist to make the app's balance match the physical
wallet — so the natural way to enter one is to type what is actually in the wallet and let the app
work out the difference (owner decision, 2026-11-04).

## What

- **Top-up in the forms.** The add and edit movement screens (`add_expense_screen.dart`,
  `edit_expense_screen.dart`) offer Top-up alongside Expense and Income in the type selector
  (`transaction_type_selector.dart`). A top-up has title, amount, category, date and description like
  the other kinds. Existing records can be switched to Top-up via edit — this is how the owner
  reclassifies old income records by hand (no migration).
- **Correct balance.** A "Correct balance" entry in the home screen's app-bar menu (beside Export)
  for the selected wallet opens a dialog (styleguide: dialog form pattern) showing the current
  balance and asking for the **counted cash**. The dialog shows the resulting difference before
  saving; on confirm it records one correction movement (in or out) dated now, with the difference
  as its amount. Equal values record nothing and say so. Corrections are created only this way, not
  via the add form.
- **Display.** Movement rows (`recent_expenses.dart`, `expenses_list_screen.dart`) show top-ups and
  corrections distinctly from income and spending (label/icon and a neutral color, scheme-aware per
  the styleguide), with the signed amount. Editing a correction allows changing its amount, date and
  description; deleting works like any movement.
- **Settings.** The settings screen gains a text field for the correction export category (the
  SharedPreferences value added in `cash-ledger-s2v1q`, default `Correction`).
- Follow the signed-off styleguide (`.agentheim/knowledge/contexts/design-system/styleguide/README.md`).

## Acceptance criteria

- [ ] The add and edit movement forms offer Top-up as a kind, and saving produces a stored movement
      of kind top-up, covered by a widget test.
- [ ] An existing income movement can be changed to Top-up via the edit screen, covered by a widget
      test.
- [ ] "Correct balance" from the home screen's app-bar menu records a correction-in when the counted
      cash exceeds the balance, a correction-out when it is lower, and nothing (with a message) when
      equal; afterwards the wallet balance equals the counted cash. Covered by a widget or service
      test.
- [ ] The settings screen reads and saves the correction export category, covered by a widget test.
- [ ] Movement rows show top-ups and corrections with a label distinct from income and expense,
      covered by a widget test.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] Top-ups and corrections look distinct but consistent with the styleguide, in light and dark
      mode. [human-eye]

## Notes

- Depends on `cash-ledger-s2v1q` (kinds, totals, export, settings value) and the signed-off
  styleguide `design-system-001`.
- Styleguide rules that apply: dialog form pattern for small entities; scheme-aware colors (avoid
  the light-only `shadeNN` tints, see `cash-ledger-p53v9`); green = income, red = expense, so pick a
  neutral color for top-ups/corrections.
- Exchange (cash for cash) stays out of scope.
