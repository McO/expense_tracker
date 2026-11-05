# Expense Tracker Styleguide

Status: **signed off by the owner on 2026-11-04** (design-system-001). The styleguide gate is open: frontend tasks that `depends_on: [design-system-001]` may now be promoted. Owner decisions are recorded in section 5.

This documents the look as it exists in `lib/` today, plus one proposal (section 4). Values were read from the code, not invented. Where the code is inconsistent, that is noted so new screens can choose deliberately.

## 1. Tokens

### Theme (`lib/main.dart`, `_buildTheme`)
- Material 3 (`useMaterial3: true`), `ColorScheme.fromSeed(seedColor: Color(0xFF6366F1))` (indigo).
- Light, dark and system modes. Both themes are built by the same function with a different `Brightness`. The mode is a user setting (`ThemeService`, `settings_screen.dart`) and is passed down by callback.
- `AppBarTheme`: centered title, elevation 0.
- `CardThemeData`: elevation 4, shape rounded 16.
- `FloatingActionButtonThemeData`: elevation 6.
- No custom `TextTheme`, no custom font. Everything uses Material 3 defaults.

### Color
- Brand and surfaces come from the seed `ColorScheme` (e.g. account selector uses `secondaryContainer` / `onSecondaryContainer`; the active page dot uses `primaryColor`).
- Semantic money colors on the summary card (`total_expense_card.dart`) are scheme-aware: each card fill is the semantic colour as an alpha tint (0.16) blended over `colorScheme.surface`, and its text/icon colour is the semantic colour mixed 30% toward `colorScheme.onSurface`, so both adapt to light and dark mode:
  - Income: green (`Colors.green`)
  - Expense: red (`Colors.red`)
  - Net balance: positive `colorScheme.primary`, negative orange (`Colors.orange`)
  - Inactive/empty hints: `Colors.grey[300..600]`
- Category color: each `Category` carries its own hex color (`category.toColor()`); used as alpha tints and borders; `category_breakdown.dart` uses 0.03 and 0.08 (gradient), 0.15 (fill), 0.3 and 0.4 (borders), and `recent_expenses.dart` uses 0.1 (fill) and 0.3 (border).
- New components should prefer scheme roles or alpha tints (`color.withValues(alpha: ...)`) over fixed `Colors.x.shadeNN` tints, as the summary card, category and movement widgets do.

### Typography
Theme text styles used, with bold added by hand:
- `headlineMedium` bold: net balance figure
- `titleLarge` bold: section headings ("Recent Transactions") and card amounts
- `titleMedium` (bold or w600): card titles, account selector, list amounts
- `bodyMedium` / `bodySmall`: labels and secondary text (`bodySmall` also for small percentages, overridden to 11 in places)
- Raw `fontSize` overrides exist (10 to 28, mostly 16, 18, 12, 24). Prefer theme styles in new code.
- Emoji are used as icons for categories and accounts (`fontSize` 18 in a 40 px tile).

### Spacing
Multiples of 4, with 16 dominant.
- Page/card padding: `EdgeInsets.all(16)` (most common); dense cards `symmetric(horizontal: 16, vertical: 8)`; empty states `all(24)`.
- Gaps: `SizedBox` 16 (between sections), 8 (within a card), 12 (between sibling cards), 4 (tight).

### Radii
- 16: cards (theme default)
- 20: category carousel card
- 12: tiles, selectors, swipe-delete background, type buttons
- 8: inner amount rows
- 10: category icon tile

### Elevation
- 4: theme default card
- 2: summary cards in `total_expense_card.dart` and the cards in `category_management_screen.dart`
- 6: carousel card and FAB
- 0: app bar

## 2. Components

| Component | Widget file | Notes |
|---|---|---|
| Net balance / income / expense summary | `lib/widgets/total_expense_card.dart` (`TotalExpenseCard`) | One larger tinted card (net balance, trend icon, savings rate or "Combined from N currencies") above two half-width cards (income green, expenses red). Icon + label row, then bold amount. |
| Category card carousel | `lib/widgets/category_breakdown.dart` (`CategoryBreakdown`) | `PageView`, auto-advances every 4 s, one card per category: radius 20, 2 px category-tinted border, light gradient of the category color, income/expense rows each with `LinearProgressIndicator` and percentage. Page counter ("1 of N") plus dot indicators (12 px active, 8 px inactive). Shows "Mixed currencies" when a category spans currencies. |
| Movement row and swipe-to-delete | `lib/widgets/recent_expenses.dart` (`RecentExpenses`) | `Card` + `ListTile`: 40 px category emoji tile (radius 10, tinted), bold title, "Category • date" subtitle, signed amount colored green/red. `Dismissible` end-to-start with red background (icon + "Delete"), confirmed by an `AlertDialog` (Cancel / red Delete). Header row with "View All" `TextButton`. Empty state: grey receipt icon, title, hint. |
| Transaction type toggle | `lib/widgets/transaction_type_selector.dart` (`TransactionTypeSelector`) | Card with two equal buttons (Expense red, Income green). Selected: 2 px border in the color, 0.1 alpha fill; unselected: grey. Radius 12, padding 16. |
| Account selector | `lib/screens/home_screen.dart` (`_buildAccountSelector`) | `DropdownButton` hiding the underline inside a `secondaryContainer` rounded-12 container. |
| Date picker and range picker | `lib/screens/add_expense_screen.dart`, `lib/screens/edit_expense_screen.dart` (`showDatePicker`); `lib/screens/home_screen.dart` (`showDateRangePicker`, CSV export) | Stock Material pickers, no custom styling. |
| Forms (full screen) | `lib/screens/add_expense_screen.dart`, `edit_expense_screen.dart`, `add_edit_category_screen.dart` | `TextFormField` with `OutlineInputBorder`, 16 px vertical gaps, `DropdownButton` for category and currency, save action with validation. |
| Forms (dialog) | `lib/screens/account_management_screen.dart`, `lib/screens/currency_management_screen.dart` | Accounts and currencies are added/edited in an `AlertDialog` (via `showDialog`, stateful builder) holding `TextField`s with `OutlineInputBorder` (accounts also `DropdownButtonFormField`s), with dialog actions. Categories use a full screen instead. |
| List with search/filter | `lib/screens/expenses_list_screen.dart` | Full movement list reusing the row style. |
| Management lists | `lib/screens/category_management_screen.dart`, `account_management_screen.dart`, `currency_management_screen.dart` | Card lists (elevation 2) with delete confirmed by `AlertDialog`. One unified pattern on all three screens: a trailing per-item `PopupMenuButton` (Edit, and Delete in the destructive colour where deletion is allowed) and a `FloatingActionButton.extended` to add ("Add category" / "Add wallet" / "Add currency"); no trailing icon buttons and no app-bar add button. Custom currencies have no edit dialog, so their menu holds Delete only. New management screens follow this pattern. |

## 3. Patterns

- **Card-first layout.** Content lives in rounded `Card`s on the scaffold surface; sections separated by 16 px.
- **Tint plus tone.** Meaning is shown as a pale tint fill, a matching border or text tone, and an icon (trending up/down, arrow up/down). Green means income, red means expense.
- **Signed amounts.** Always currency symbol plus two decimals, with `+` / `-` signs on summaries and signed amounts on rows.
- **Dialog forms.** Small entities (accounts, currencies) are edited in an `AlertDialog` form; larger ones (expenses, categories) get a full screen.
- **Feedback.** Errors and confirmations use `ScaffoldMessenger` `SnackBar`; destructive actions use an `AlertDialog` with a red confirm.
- **Navigation.** Imperative `Navigator.push`/`pop`; the parent reloads data on return.
- **Empty states.** Centered muted icon, title, one-line hint, inside a card.
- **Multi-currency.** Summaries group or label when several currencies are present; never silently sum across currencies in a way that hides it (see "Combined from N currencies", "Mixed currencies").

## 4. Chart style for quick-glance statistics (approved 2026-11-04, not yet implemented)

Scope per the vision: cash only, no budgets, trips, conversion or deep analysis. Top-ups and corrections never count as spending or income. From the research quick-glance list, use only: balance per currency/account (already present), daily average, last-N-days bar chart, simple category pie/bars for the current period, and a period control.

Proposed rules:
1. **Reuse the card.** Each statistic sits in a standard `Card` (radius 16, theme elevation, padding 16) with a `titleMedium` bold heading, like the existing sections.
2. **Prefer bars over pies.** Category mix as horizontal bars (generalizing the `LinearProgressIndicator` rows already in the carousel), one row per category: emoji tile, name, bar, amount. A donut is acceptable only for at most about 5 slices plus "other".
3. **Last-N-days bar chart.** N = 5 to 7 vertical bars, expense color only, day initials beneath, today highlighted with the scheme primary and other days at reduced alpha. No axes or gridlines; value label above the tallest/selected bar.
4. **Color.** Category charts use `category.toColor()`. Single-series charts use the expense red (or scheme primary for neutral figures such as daily average). Use scheme-aware colors so dark mode works.
5. **Numbers first.** Each chart is paired with one headline figure (`headlineMedium` bold, e.g. daily average) and one caption (`bodySmall`). Per-currency figures are shown side by side, never converted.
6. **Period control.** A single segmented control (for example 7 days / month) above the charts, styled like the transaction type toggle (radius 12, 2 px border when selected).
7. **Implementation note.** Build charts with plain `Container`/`CustomPaint` widgets, matching today's no-extra-dependency stance. Adding a chart package would need its own decision (ADR).
8. **Empty state.** Use the existing empty-state pattern when there is no data for the period.

## 5. Owner decisions (2026-11-04)
- **Management lists — unify on the category style.** New and cleaned-up management screens use a per-item `PopupMenuButton` and a `FloatingActionButton.extended` to add, as `category_management_screen.dart` does. Account and currency screens now follow it (cash-ledger-f150f).
- **Light-only shade colors — fix.** `total_expense_card.dart` should move to scheme-aware colors; captured as a backlog task in cash-ledger.
- **Chart style — approved.** Section 4 is the rule for the quick-glance cash statistics; it is no longer just a proposal. A chart package still needs its own ADR.
- **Sign-off:** given, as is.
