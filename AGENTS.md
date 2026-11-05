# Expense Tracker — Agent Guide

Personal finance Android app built with Flutter. Single developer, no CI/CD pipeline.

---

## Project Overview

- **Platform:** Android only (no iOS/web/desktop platform folders)
- **App ID:** `io.github.mco.expensetracker` (never changes again, ADR-0010)
- **Flutter/Dart:** Dart SDK `>=3.13.0 <4.0.0`, Flutter stable
- **Theme seed:** `Color(0xFF6366F1)` (indigo), Material Design 3

---

## Directory Structure

```
lib/
├── main.dart                          # Entry point — instantiates ThemeService, builds MaterialApp
├── models/
│   ├── transaction.dart               # Core Transaction model (toJson/fromJson/copyWith)
│   ├── currency.dart                  # Currency class: 15 predefined + user-defined custom
│   ├── category.dart                  # Category: hex color, emoji icon, isDefault flag
│   ├── account.dart                   # Account: name, currency, emoji, ARGB hex, isDefault
│   └── transaction_type.dart          # Enum: expense | income
├── services/
│   ├── transaction_service.dart       # CRUD + CSV building (`buildCSV`; export file is `transactions_<from>_<to>.csv`); all reads/writes via SharedPreferences
│   ├── csv_import.dart                # Pure CSV import: parse own export, map rows, detect duplicates; `commitImportPreview` writes via TransactionsStore
│   ├── csv_file_saver.dart            # `CsvFileSaver` seam + default file_picker-backed system save dialog (export)
│   ├── csv_file_picker.dart           # `CsvFilePicker` seam + default file_picker-backed picker
│   ├── cash_statistics.dart           # Pure quick-glance statistics for one account
│   ├── ledger_totals.dart             # Pure aggregation: account balance and income/expense totals
│   ├── account_service.dart           # CRUD for accounts; auto-creates default if list is empty
│   ├── category_service.dart          # CRUD for categories; seeds defaults once (v2 migration flag)
│   ├── currency_service.dart          # CRUD for user-defined custom currencies
│   └── theme_service.dart             # Theme mode preference (light/dark/system)
├── screens/
│   ├── home_screen.dart               # Dashboard: account selector, totals, category breakdown, recents; also drives CSV export (account + date-range pickers, then saves through the system save dialog via the `CsvFileSaver` seam)
│   ├── add_transaction_screen.dart    # Add transaction form
│   ├── edit_transaction_screen.dart   # Edit transaction form (pre-populated)
│   ├── transactions_list_screen.dart  # Full list with search & category filter
│   ├── transaction_detail_screen.dart # Read-only detail view
│   ├── account_management_screen.dart # CRUD UI for accounts
│   ├── category_management_screen.dart# CRUD UI for categories
│   ├── add_edit_category_screen.dart  # Add/edit form for a single category
│   ├── currency_management_screen.dart# CRUD UI for custom currencies
│   ├── statistics_screen.dart         # Quick-glance cash statistics for one account
│   └── settings_screen.dart          # Theme selection only
└── widgets/
    ├── balance_summary_card.dart      # Net balance + income/expense summary row; groups totals by currency when multiple currencies are present
    ├── category_breakdown.dart        # Auto-scrolling PageView of category spending cards
    ├── recent_transactions.dart       # Dismissible list of 5 most recent transactions
    ├── transaction_style.dart         # Direction colour, non-counting marker and chip for a transaction row
    ├── sign_toggle.dart               # Sign toggle for the amount (− = money out, + = money in)
    └── correct_balance_dialog.dart    # Correct balance dialog; records one correction transaction
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
- Services are instantiated directly inside screens: `final TransactionService _transactionService = TransactionService()`
- After any mutation (add/edit/delete), screens call `_loadData()` to re-fetch from SharedPreferences and then `setState()`
- Theme mode is passed from the root `_ExpenseTrackerAppState` down via callback parameters (`onThemeModeChanged`)
- No reactive streams, `ChangeNotifier`, `InheritedWidget`, Provider, Riverpod, BLoC, or GetX

### Navigation

Entirely **imperative** push/pop via `Navigator.push` / `Navigator.pop`. No named routes, no go_router. After returning from a sub-screen, the parent calls `_loadData()` to refresh.

### Data Persistence

All data is stored in **SharedPreferences as JSON strings**. No SQLite, Hive, or file-based DB.

| Key | Type | Contents |
|---|---|---|
| `transactions` | `List<String>` | JSON-encoded `Transaction` objects (renamed from `expenses`; migrated once by `TransactionsStore`) |
| `transactions_key_migrated_v1` | `bool` | Flag: the `expenses` → `transactions` key migration has run |
| `accounts` | `List<String>` | JSON-encoded `Account` objects |
| `selected_account_id` | `String` | Currently selected account ID |
| `categories` | `List<String>` | JSON-encoded `Category` objects |
| `categories_defaults_initialized_v2` | `bool` | Migration flag to seed defaults once |
| `custom_currencies` | `List<String>` | JSON-encoded custom `Currency` objects |
| `theme_mode` | `int` | Index of `AppThemeMode` enum |

**Service pattern:** read full list → deserialize → mutate in-memory → serialize → write full list back. Every service follows this pattern.

---

## Key Models

### Transaction

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
| `file_picker` | ^13.3.2 | Pick a CSV file for import; save the CSV export via the system dialog |
| `cupertino_icons` | ^2.0.0 | iOS-style icons |

---

## Releasing

One local command cuts a release (ADR-0011, complements ADR-0002; the signing key never leaves the Mac):

```bash
tool/release.sh <major|minor|patch|X.Y.Z> [--dry-run]
```

Preconditions (each refused with a clear message): on `main`, clean working tree, in sync with `origin/main`, `gh auth status` OK, `android/key.properties` present (`tool/create-release-key.sh`, see ADR-0010).

Steps, stopping at the first failure: compute the new SemVer (`X.Y.Z`, an explicit one must be higher) and build number (+1 every release) and write `version: X.Y.Z+N` to `pubspec.yaml`; `flutter analyze` and `flutter test`; prepend `## X.Y.Z (date)` to `CHANGELOG.md`, built from task-completion commits (`<type>(<bc>): ... [<task-id>]`) since the previous `v*` tag, grouped Features / Fixes / Changes / Chores (batch-start, bookkeeping, capture, modeling and release commits left out); `flutter build apk --release`, copied to `build/release/expense-tracker-X.Y.Z.apk`; commit `chore(release): vX.Y.Z`, annotated tag `vX.Y.Z`, push; `gh release create` on McO/expense_tracker with the changelog section as notes and the APK attached.

`--dry-run` prints every step and the changelog section and changes nothing. Version and changelog logic lives in `tool/release_notes.dart` (tests: `test/release_notes_test.dart`).

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

The app declares **no** permissions in `AndroidManifest.xml`. CSV export saves through Android's system save dialog and import uses the system file picker (both via `file_picker`), so no storage, media or network permission is needed (ADR-0009). Flutter's debug/profile manifests add `INTERNET` themselves for hot reload.

---

## Known Gotchas

- **No CI/CD.** Releases are cut locally by `tool/release.sh` (see Releasing); never tag, push or publish a release by hand.
- **Release builds need `android/key.properties`.** Run `tool/create-release-key.sh` once; it creates the release keystore at `~/.android-keys/expense-tracker-release.jks` (outside the repo) and writes the gitignored `android/key.properties`. `flutter build apk --release` fails without it and never falls back to the debug key. Back up the keystore and its password. Changing the key or app ID forces a reinstall (export, reinstall, import).
- **The README is outdated** — it documents the original simpler version. The codebase has since added accounts, income/expense types, custom categories, custom currencies, and CSV export.
- **SharedPreferences has no schema migration.** Adding or renaming fields in a model requires careful `fromJson` defaults to avoid crashes on existing installs.
- **Theme is propagated via callbacks,** not `InheritedWidget`. If you add a screen deep in the tree that needs theme control, wire the callback through all intermediate screens.
- **Category fallback:** `Transaction.fromJson` falls back to the "other" category when a stored `categoryId` is not found. This is intentional — do not remove it.
- **`categories_defaults_initialized_v2` flag:** The `_v2` suffix exists because the original `_v1` flag was used for a smaller set of defaults. If you add more default categories, bump to `_v3` and seed accordingly.
