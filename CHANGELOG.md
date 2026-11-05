# Changelog

## 1.1.0 (2026-11-05)

### Features
- tool/release.sh cuts releases: SemVer + auto build number, changelog from task trailers, signed APK, vX.Y.Z tag, GitHub Release; side-effect-free --dry-run (ADR-0011) (infrastructure-dx7t4)
- Import CSV (the app's own export) into a chosen account with a preview; exact duplicates skipped, unknown categories to Other, currency mismatch rejected (cash-ledger-hzqaa)
- Transactions stored under the transactions key, migrated once from expenses (flag-guarded copy-then-delete in TransactionsStore); ADR-0008 amends ADR-0004 (cash-ledger-k6d4w)
- A movement's currency is always its wallet's (load, display, CSV, form save); the unused default-currency setting is gone; deleting a wallet deletes its movements after a confirm naming the count (cash-ledger-apzzm)
- Added a Statistics screen (home drawer entry) with the wallet balance and Correct balance, burn rate (daily average, lasts ~N days, 7-day bars) and spending mix over This month or Last 7 days; iteration 2 hardens the unit tests for mix ordering and floor/zero-balance cases. (cash-ledger-bktw5)
- A movement is now a signed amount plus a category. Top-up and Correction are seeded categories, and a per-category countsInStatistics flag keeps them out of statistics while the balance still counts them. The correction export setting is gone. (cash-ledger-qjysm)
- TransactionType now has top-up and correction (in/out) kinds that round-trip through storage, count in the wallet balance but are excluded from income/expense totals, savings rate and category breakdown, and export to CSV (top-up like income, correction signed under a configurable category defaulting to "Correction"). The broken widget test is replaced and flutter test and flutter analyze are green. (cash-ledger-s2v1q)
- Styleguide capturing the existing look (tokens, components, patterns) plus the approved quick-glance chart style; owner signed off (design-system-001)

### Fixes
- Summary card money colours come from scheme-aware alpha tints so they work in dark mode; styleguide Color section updated (cash-ledger-p53v9)
- home button says "Add movement" instead of "Add Expense" (cash-ledger-vsszp)

### Changes
- Export saves via the system save dialog; permission_handler and all storage/media/network permissions removed (ADR-0009) (cash-ledger-m47az)
- Account and Transaction used consistently in code, on screen and in the CSV file name (transactions_<from>_<to>.csv); stored keys unchanged (cash-ledger-ydqbw)
- Wallet and currency management lists use the category style (popup menu per item, extended add button); styleguide Management lists row unified (cash-ledger-f150f)

### Chores
- Release builds signed only with a dedicated release key (tool/create-release-key.sh); app ID now io.github.mco.expensetracker (ADR-0010) (infrastructure-c5nkp)
- Dependencies upgraded to latest, Dart SDK floor raised to 3.13, unused path_provider removed; analyze clean, debug and release APKs build (infrastructure-pn83e)
- Verified the draft CSV export ADR against buildCSV, the home screen export flow and the manifest; filled in the real six-column format and corrected the draft (signed amounts, file naming, permission fallback, date-range edge, hardcoded Downloads path). No source changes. (cash-ledger-ngxsa)
- Verified the draft persistence ADR against lib/services and lib/models, corrected it (key table, per-model fromJson tolerance, two seeding patterns) and report it as ADR 0002. (infrastructure-r5v4d)
- Verified the draft architecture ADR against lib/ and corrected it (loader names vary per screen, services also nest, theme path is root to HomeScreen to SettingsScreen); final ADR returned for materialization. (infrastructure-bza94)
- Verified the draft platform/toolchain ADR against pubspec.yaml, android/ build files and lib/main.dart, and added the verified toolchain versions (AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, Java 11, Flutter-provided SDK levels, debug-key release signing). No source changes. (infrastructure-pr7em)
