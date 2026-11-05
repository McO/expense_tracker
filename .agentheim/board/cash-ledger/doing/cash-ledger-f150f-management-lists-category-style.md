---
id: cash-ledger-f150f
title: Account and currency management screens use the category list style (popup menu per item, extended add button)
status: doing
type: refactor
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001, cash-ledger-apzzm]
blocks: []
tags: [ui, styleguide, cleanup, management-lists]
related_adrs: [ADR-0003]
related_research: []
prior_art: [design-system-001]
---

## Why

At the styleguide sign-off (design-system-001, section 5, 2026-11-04) the owner decided that
management screens unify on the category style. Today they differ: categories use a per-item
`PopupMenuButton` and a `FloatingActionButton.extended`; accounts use two trailing `IconButton`s and
a plain `FloatingActionButton`; currencies use a trailing `IconButton` and an add button in the app
bar, with no FAB.

## What

- `account_management_screen.dart` and `currency_management_screen.dart` adopt the category style
  (`category_management_screen.dart`): each item has a trailing `PopupMenuButton` with Edit and
  Delete (Delete in the destructive colour), and adding uses a `FloatingActionButton.extended`
  ("Add wallet" / "Add currency"). Remove the app-bar add button on the currency screen.
- Cards follow the category list's card styling (elevation 2, per the styleguide).
- Behaviour is unchanged: the same add/edit dialogs, the same delete confirmations (including the
  wallet-deletion confirm added by `cash-ledger-apzzm`), the same rules (last wallet can't be deleted,
  built-in currencies can't be deleted).
- Update the styleguide's "Management lists" row (`.agentheim/knowledge/contexts/design-system/styleguide/README.md`,
  the styleguide-source carve-out a worker may edit) to describe the one unified pattern instead of
  the inconsistency.

## Acceptance criteria

- [ ] Account and currency lists show a per-item popup menu with Edit and Delete, and no trailing
      icon buttons, covered by widget tests.
- [ ] Both screens add via a `FloatingActionButton.extended`; the currency screen has no app-bar add
      button, covered by widget tests.
- [ ] Edit and Delete from the popup menu open the same dialogs and confirmations as before, and the
      existing rules still hold, covered by widget tests.
- [ ] The styleguide's "Management lists" row describes the unified pattern (no inconsistency
      note left).
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] The three management screens look consistent with each other and the styleguide, in light and
      dark mode. [human-eye]

## Notes

- Depends on `cash-ledger-apzzm`, which changes wallet deletion on the same screen.
- Styleguide section 5 records the owner's decision; section 2's "Management lists" row describes
  today's inconsistency.
