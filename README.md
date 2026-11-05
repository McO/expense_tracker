# Expense Tracker

A personal Android app for tracking **cash**: the euros in your pocket at home and the foreign
currency you carry abroad.

The app was built to work alongside [MoneyMoney](https://moneymoney.app), a banking app for the
Mac. MoneyMoney fetches every bank and card transaction automatically but cannot see cash. In
Expense Tracker, each account mirrors one MoneyMoney cash account. You record cash transactions
on the phone, then hand them over with a CSV export. The CSV is plain, so any finance tool that
imports CSV can use it.

Your data stays on the phone. There is no account, no sync and no network access. The app requests
no Android permissions at all.

## Features

- **Accounts per currency.** Keep euros, dollars, lira and so on in separate accounts, each with its
  own balance, emoji and colour. Add custom currencies beyond the 15 built-in ones.
- **Quick entry.** A transaction is a signed amount plus a category. Use **−** for money out and
  **+** for money in.
- **Honest statistics.** Top-ups (ATM withdrawals, currency bought) and balance corrections move
  the balance, but they never count as spending or income.
- **Correct balance.** Enter what is physically in your wallet. The app records the difference as
  one correction.
- **Quick-glance statistics** for each account, over this month or the last 7 days:
  - **Balance:** does the app's balance match your wallet?
  - **Burn rate:** a daily average, plus "lasts ~N days".
  - **Spending mix:** what your cash goes on.
- **Categories** with emoji, colour and an optional export name, which maps them to your finance
  tool's categories.
- **CSV export.** Export one account over a date range. The file is saved through Android's own save
  dialog.
- **CSV import.** Import the app's own export back into an account. You get a preview first, and
  exact duplicates are skipped. This is also how you move your data to a new phone.
- Light and dark theme, Material Design 3.

## Install

Download the APK from the latest
[GitHub Release](https://github.com/McO/expense_tracker/releases/latest) and install it. Android
asks you to allow installs from your browser or file manager the first time.

Each release is signed with the same key, so new versions install over the old one and keep your
data.

## Build from source

You need the [Flutter](https://docs.flutter.dev/get-started/install) SDK (stable channel) and the
Android SDK.

```bash
flutter pub get
flutter run                 # run on a connected device or emulator
flutter test                # unit and widget tests
flutter analyze             # static analysis
flutter build apk --debug   # debug APK, signed with the debug key
```

Release builds (`flutter build apk --release`) need a release signing key. Run
`tool/create-release-key.sh` once to create one. Without the key, the build stops with a message
explaining what to do; it never falls back to the debug key.

Releases are cut with `tool/release.sh <major|minor|patch>` (add `--dry-run` to preview). The
script:
1. bumps the version;
2. runs the tests;
3. writes the changelog;
4. builds the signed APK;
5. tags the version and publishes the GitHub Release.

See [CHANGELOG.md](CHANGELOG.md) for the history.

## Project layout

- `lib/` contains the app: `models/`, `services/` (storage, statistics, CSV), `screens/` and
  `widgets/`. State is plain `StatefulWidget` + `setState`, and data is stored as JSON in
  `SharedPreferences`.
- `test/` contains unit and widget tests.
- `tool/` contains the release and signing-key scripts.
- `.agentheim/` holds the planning record: the vision, the task boards, and the architecture
  decision records (ADRs) under `knowledge/decisions/`.
- [AGENTS.md](AGENTS.md) is the detailed guide to the codebase. It is written for AI coding agents
  and is just as useful for humans.

## License

[MIT](LICENSE) © 2025-2026 Marco Rasp
