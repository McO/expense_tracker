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
│   ├── transactions_store.dart        # Owns the `transactions` key: raw read/write plus the one-time `expenses` → `transactions` migration
│   ├── transaction_service.dart       # CRUD + CSV building (`buildCSV`; export file is `transactions_<from>_<to>.csv`); reads/writes through `TransactionsStore`; loaded transactions take their account's currency
│   ├── csv_import.dart                # Pure CSV import: parse own export, map rows, detect duplicates; `commitImportPreview` writes via TransactionsStore
│   ├── csv_file_saver.dart            # `CsvFileSaver` seam + default file_picker-backed system save dialog (export)
│   ├── app_version_lookup.dart        # `AppVersionLookup` seam + default package_info_plus-backed installed-version lookup (drawer footer)
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
| `categories_ledger_ensured_v1` | `bool` | Flag: the built-in Top-up and Correction categories have been added (non-destructively, also on existing installs) |
| `custom_currencies` | `List<String>` | JSON-encoded custom `Currency` objects |
| `theme_mode` | `int` | Index of `AppThemeMode` enum |

**Service pattern:** read full list → deserialize → mutate in-memory → serialize → write full list back. Every service follows this pattern.

---

## Key Models

### Transaction

Fields: `id`, `title`, `amount` (double), `currency` (Currency), `category` (Category), `date`, `description`, `type` (TransactionType), `accountId`.

A transaction is a **signed amount plus a category** (ADR-0007):
- **Direction:** the UI's sign toggle (`−` = money out, `+` = money in). It is stored as a positive `amount` plus `type` (`expense` = out, `income` = in). Use `signedAmount` and `increasesBalance` rather than re-deriving the sign.
- **Kind:** the category decides it. Spending and income use ordinary categories. Top-ups and corrections use the built-in Top-up and Correction categories, which move the balance but stay out of statistics (`Category.countsInStatistics`).
- **Correction:** `Transaction.correction(difference: …)` builds one from the signed difference between counted cash and the recorded balance.
- **Currency:** a transaction's currency is always its account's. `TransactionService` applies it on load, and CSV import rejects a currency mismatch. Never let a transaction carry a currency different from its account's.
- **Category fallback:** loading falls back to the "other" category if a stored category ID is not found in the current category list.
- **Serialization:** `toJson` / `fromJson` for SharedPreferences; `copyWith` for immutable-style updates.

### Currency

Plain Dart class (not an enum). 15 predefined static constants. Users can add custom currencies stored separately under `custom_currencies`.

### Category

Has a hex color string (e.g. `#FF6366F1`), an emoji icon, `isDefault` bool, optional `exportName` for CSV export (`effectiveExportName` falls back to the name), and `countsInStatistics` (default `true`).
- **Defaults:** seeded on first launch via the `categories_defaults_initialized_v2` flag.
- **Ledger categories:** `Category.topUp` (🏧) and `Category.correction` (⚖️) are built in, with `countsInStatistics: false`. They count in the account balance but never in spending, income or the statistics. `CategoryService` adds them once via `categories_ledger_ensured_v1`, without touching existing categories.

### Account

Has `name`, `currency` (Currency), emoji `icon`, ARGB hex `color` string, and `isDefault` bool.

### TransactionType

Enum: `expense | income`. It is the **direction only** (money out / money in), not the kind of transaction; the category decides the kind. Has a string extension for JSON serialization (`code`, `fromCode`). Interim codes from an earlier model still load: `topup` and `correction_in` load as income, `correction_out` as expense. Unknown codes load as expense.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | ^2.2.2 | All local persistence |
| `intl` | ^0.20.2 | Date formatting |
| `flutter_staggered_animations` | ^1.1.1 | Staggered list animations |
| `file_picker` | ^13.3.2 | Pick a CSV file for import; save the CSV export via the system dialog |
| `package_info_plus` | ^10.2.2 | Read the installed version and build number for the drawer footer |
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

# Tests
flutter test

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

`flutter test` runs about 90 unit and widget tests in `test/`, covering:
- models and transaction kinds;
- storage-key migration;
- balance and statistics math;
- CSV export and import (pure logic and the UI flow);
- screens and styling;
- the drawer version footer;
- the release-notes logic.

Keep `flutter test` and `flutter analyze` green; `tool/release.sh` refuses to release otherwise.

When writing tests:
- The root widget is `ExpenseTrackerApp`.
- Services depend on SharedPreferences; call `SharedPreferences.setMockInitialValues({...})` with the state you need.
- Platform dialogs and plugins sit behind injectable seams passed into `HomeScreen(...)`: `CsvFilePicker`, `CsvFileSaver` and `AppVersionLookup`. Pass a fake in widget tests instead of touching the platform. Follow the same pattern for any new platform dependency.
- Pure logic lives in plain-Dart services (`cash_statistics.dart`, `ledger_totals.dart`, `csv_import.dart`, `tool/release_notes.dart`); test it without widgets.

---

## Android Permissions

The app declares **no** permissions in `AndroidManifest.xml`. CSV export saves through Android's system save dialog and import uses the system file picker (both via `file_picker`), so no storage, media or network permission is needed (ADR-0009). Flutter's debug/profile manifests add `INTERNET` themselves for hot reload.

---

## Known Gotchas

- **`pubspec.lock` is committed** so every checkout, test run and release build uses the same tested dependency versions; refresh it deliberately with `flutter pub upgrade`.
- **No CI/CD.** Releases are cut locally by `tool/release.sh` (see Releasing); never tag, push or publish a release by hand.
- **Release builds need `android/key.properties`.** Run `tool/create-release-key.sh` once; it creates the release keystore at `~/.android-keys/expense-tracker-release.jks` (outside the repo) and writes the gitignored `android/key.properties`. `flutter build apk --release` fails without it and never falls back to the debug key. Back up the keystore and its password. Changing the key or app ID forces a reinstall (export, reinstall, import).
- **The README is user-facing** (what the app is, install, build, release). Keep it in step when a user-visible feature lands; this file stays the detailed code guide.
- **SharedPreferences has no schema migration.** Adding or renaming fields in a model requires careful `fromJson` defaults to avoid crashes on existing installs.
- **Theme is propagated via callbacks,** not `InheritedWidget`. If you add a screen deep in the tree that needs theme control, wire the callback through all intermediate screens.
- **Category fallback:** `Transaction.fromJson` falls back to the "other" category when a stored `categoryId` is not found. This is intentional — do not remove it.
- **`categories_defaults_initialized_v2` flag:** The `_v2` suffix exists because the original `_v1` flag was used for a smaller set of defaults. If you add more default categories, bump to `_v3` and seed accordingly. The built-in Top-up and Correction categories are separate (`categories_ledger_ensured_v1`); a new built-in category of that kind needs its own flag bump and a non-destructive add.

---

## Planning & Decisions

Planning lives in `.agentheim/` (the Agentheim workflow), not in issues:
- `knowledge/vision.md`: purpose, success criteria, non-goals, ubiquitous language (Account, Transaction, Top-up, Correction, …), and open questions. Read it before proposing features. Its non-goals (no trips, budgets, currency conversion, sync or deep analysis) are deliberate.
- `knowledge/decisions/`: the ADRs. Check the relevant ones before changing persistence, export, signing or release behaviour. Notable ones:
  - ADR-0004 / 0008: storage and key migration;
  - ADR-0007: signed amount plus category;
  - ADR-0009: export via the system save dialog;
  - ADR-0010: signing key and app ID;
  - ADR-0011: the release process.
- `board/<context>/{backlog,todo,doing,done}/`: task files, one per change.

Commit subjects for task work use `<type>(<context>): <summary> [<task-id>]`. `tool/release.sh` builds `CHANGELOG.md` from exactly these subjects, so a change committed without that shape is left out of the release notes.
