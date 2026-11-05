# Expense Tracker — Agent Guide

Personal finance Android app built with Flutter. Single developer, no CI/CD pipeline.

---

## Project Overview

- **Platform:** Android only (no iOS/web/desktop platform folders)
- **App ID:** `com.example.expense_tracker`
- **Flutter/Dart:** Dart SDK `>=3.4.3 <4.0.0`, Flutter stable
- **Theme seed:** `Color(0xFF6366F1)` (indigo), Material Design 3

---

## Directory Structure

```
lib/
├── main.dart                          # Entry point — instantiates ThemeService, builds MaterialApp
├── models/
│   ├── expense.dart                   # Core Expense model (toJson/fromJson/copyWith)
│   ├── currency.dart                  # Currency class: 15 predefined + user-defined custom
│   ├── category.dart                  # Category: hex color, emoji icon, isDefault flag
│   ├── account.dart                   # Account: name, currency, emoji, ARGB hex, isDefault
│   └── transaction_type.dart          # Enum: expense | income
├── services/
│   ├── expense_service.dart           # CRUD + CSV building (`buildCSV`); all reads/writes via SharedPreferences
│   ├── account_service.dart           # CRUD for accounts; auto-creates default if list is empty
│   ├── category_service.dart          # CRUD for categories; seeds defaults once (v2 migration flag)
│   ├── currency_service.dart          # CRUD for user-defined custom currencies
│   └── theme_service.dart             # Theme mode preference (light/dark/system)
├── screens/
│   ├── home_screen.dart               # Dashboard: account selector, totals, category breakdown, recents; also drives CSV export (account + date-range pickers, storage permission request, writes file to Downloads)
│   ├── add_expense_screen.dart        # Add transaction form
│   ├── edit_expense_screen.dart       # Edit transaction form (pre-populated)
│   ├── expenses_list_screen.dart      # Full list with search & category filter
│   ├── expense_detail_screen.dart     # Read-only detail view
│   ├── account_management_screen.dart # CRUD UI for accounts
│   ├── category_management_screen.dart# CRUD UI for categories
│   ├── add_edit_category_screen.dart  # Add/edit form for a single category
│   ├── currency_management_screen.dart# CRUD UI for custom currencies
│   └── settings_screen.dart          # Theme selection only
└── widgets/
    ├── total_expense_card.dart        # Net balance + income/expense summary row; groups totals by currency when multiple currencies are present
    ├── category_breakdown.dart        # Auto-scrolling PageView of category spending cards
    ├── recent_expenses.dart           # Dismissible list of 5 most recent transactions
    └── transaction_type_selector.dart # Two-button toggle: Expense / Income
```

Other notable files:
- `pubspec.yaml` — dependencies and flutter config
- `assets/icon/icon.png` — launcher icon (regenerated via `create_icon.dart`)
- `analysis_options.yaml` — Dart linter rules (`flutter_lints`)
- `.claude/settings.local.json` — pre-approved Claude Code tool permissions

---

## Architecture

### State Management

**Vanilla Flutter `StatefulWidget` + `setState` throughout — no external state management library.**

- Each screen owns its local state
- Services are instantiated directly inside screens: `final ExpenseService _expenseService = ExpenseService()`
- After any mutation (add/edit/delete), screens call `_loadData()` to re-fetch from SharedPreferences and then `setState()`
- Theme mode is passed from the root `_ExpenseTrackerAppState` down via callback parameters (`onThemeModeChanged`)
- No reactive streams, `ChangeNotifier`, `InheritedWidget`, Provider, Riverpod, BLoC, or GetX

### Navigation

Entirely **imperative** push/pop via `Navigator.push` / `Navigator.pop`. No named routes, no go_router. After returning from a sub-screen, the parent calls `_loadData()` to refresh.

### Data Persistence

All data is stored in **SharedPreferences as JSON strings**. No SQLite, Hive, or file-based DB.

| Key | Type | Contents |
|---|---|---|
| `expenses` | `List<String>` | JSON-encoded `Expense` objects |
| `accounts` | `List<String>` | JSON-encoded `Account` objects |
| `selected_account_id` | `String` | Currently selected account ID |
| `categories` | `List<String>` | JSON-encoded `Category` objects |
| `categories_defaults_initialized_v2` | `bool` | Migration flag to seed defaults once |
| `custom_currencies` | `List<String>` | JSON-encoded custom `Currency` objects |
| `theme_mode` | `int` | Index of `AppThemeMode` enum |

**Service pattern:** read full list → deserialize → mutate in-memory → serialize → write full list back. Every service follows this pattern.

---

## Key Models

### Expense

Fields: `id`, `title`, `amount` (double), `currency` (Currency), `category` (Category), `date`, `description`, `type` (TransactionType), `accountId`.

- `amount` is always stored as a positive number; `type` determines whether it is income or expense
- Gracefully falls back to "other" category if a stored category ID is not found in the current category list
- `toJson` / `fromJson` for SharedPreferences serialization; `copyWith` for immutable-style updates

### Currency

Plain Dart class (not an enum). 15 predefined static constants. Users can add custom currencies stored separately under `custom_currencies`.

### Category

Has a hex color string (e.g. `#FF6366F1`), an emoji icon, `isDefault` bool, and optional `exportName` for CSV export. Default categories are seeded on first launch via the `categories_defaults_initialized_v2` flag.

### Account

Has `name`, `currency` (Currency), emoji `icon`, ARGB hex `color` string, and `isDefault` bool.

### TransactionType

Enum: `expense | income`. Has a string extension for JSON serialization.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | ^2.2.2 | All local persistence |
| `intl` | ^0.20.2 | Date formatting |
| `flutter_staggered_animations` | ^1.1.1 | Staggered list animations |
| `path_provider` | ^2.1.2 | File system paths (CSV export) |
| `permission_handler` | ^12.0.0+1 | Storage permission for CSV export |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |

---

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run on connected Android device / emulator
flutter run

# Static analysis
flutter analyze

# Build APKs
flutter build apk --debug
flutter build apk --release

# Regenerate launcher icon (after changing assets/icon/icon.png)
dart run flutter_launcher_icons

# Regenerate native splash
dart run flutter_native_splash:create
```

---

## Testing

The test suite is effectively empty — `test/widget_test.dart` contains broken Flutter boilerplate that references `MyApp` (which does not exist). There are no unit tests for services, models, or screens.

When writing tests:
- The root widget is `ExpenseTrackerApp`, not `MyApp`
- Services depend on SharedPreferences; use `SharedPreferences.setMockInitialValues({})` in tests
- No test helpers or fixtures exist yet

---

## Android Permissions

Declared in `AndroidManifest.xml`:
- `INTERNET`
- `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`
- `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`
- `MANAGE_EXTERNAL_STORAGE`

These are required for the CSV export feature, which writes to the device's Downloads folder.

---

## Known Gotchas

- **No CI/CD.** Builds and releases are done manually.
- **App ID is still the default placeholder** (`com.example.expense_tracker`).
- **The README is outdated** — it documents the original simpler version. The codebase has since added accounts, income/expense types, custom categories, custom currencies, and CSV export.
- **SharedPreferences has no schema migration.** Adding or renaming fields in a model requires careful `fromJson` defaults to avoid crashes on existing installs.
- **Theme is propagated via callbacks,** not `InheritedWidget`. If you add a screen deep in the tree that needs theme control, wire the callback through all intermediate screens.
- **Category fallback:** `Expense.fromJson` falls back to the "other" category when a stored `categoryId` is not found. This is intentional — do not remove it.
- **`categories_defaults_initialized_v2` flag:** The `_v2` suffix exists because the original `_v1` flag was used for a smaller set of defaults. If you add more default categories, bump to `_v3` and seed accordingly.
