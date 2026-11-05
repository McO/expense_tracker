---
id: cash-ledger-apzzm
title: A movement's currency is always its wallet's; drop the global default currency; deleting a wallet deletes its movements after a confirm
status: done
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001]
blocks: [cash-ledger-f150f]
tags: [currency, wallet, cleanup, persistence, export]
related_adrs: [ADR-0001, ADR-0004, ADR-0005, ADR-0007]
related_research: []
prior_art: [cash-ledger-qjysm, cash-ledger-vsszp]
---

## Why

The vision asks for currency and category management that is "clean and predictable", and a wallet
is "the cash held in one currency". Today the code contradicts that: every movement carries its own
currency, chosen in the add/edit form (defaulting to the wallet's, else `Currency.usd`), so a
movement can disagree with its wallet. A global "default currency" setting exists
(`SettingsService.getDefaultCurrency` / `setDefaultCurrency`, key `default_currency`, USD fallback)
but nothing reads it. And deleting a wallet leaves its movements behind with a dangling
`accountId`. Owner decisions (modeling, 2026-11-05): a movement's currency is always its wallet's;
drop the default-currency setting; deleting a wallet with movements deletes them too, after a
confirm that says how many.

## What

- **Wallet owns the currency.** A movement's currency is its wallet's currency. Remove the
  currency picker from the add and edit movement forms (`add_expense_screen.dart`,
  `edit_expense_screen.dart`); saving sets the currency from the wallet. Wherever a movement's
  currency is shown or exported (rows, detail, statistics, CSV `Currency` column, ADR-0005), it is
  the wallet's currency.
- **Existing data (ADR-0004, no migration framework).** Stored movements keep loading; a stored
  `currency` that differs from the wallet's is not migrated on disk, but display and export use the
  wallet's currency. A movement with no `currency` field loads with its wallet's currency instead of
  the hard-coded `'USD'` fallback (fall back to USD only when the wallet can't be resolved).
- **Drop the global default currency.** Remove `getDefaultCurrency` / `setDefaultCurrency` and the
  `default_currency` key from `SettingsService`, and any UI for it. A currency is chosen only when
  creating a wallet (account form unchanged otherwise).
- **Deleting a wallet deletes its movements.** In account management, deleting a wallet that has
  movements first shows a confirm dialog naming the count ("This also deletes N movements"); on
  confirm, the wallet and all its movements are removed; on cancel nothing changes. A wallet without
  movements keeps today's simple confirm. The "cannot delete the last wallet" rule and the
  default/selected-wallet reassignment in `AccountService.deleteAccount` stay as they are.
- **Category deletion is unchanged** (owner decision): movements of a deleted custom category keep
  falling back to "Other".

## Acceptance criteria

- [ ] The add and edit movement forms have no currency picker; a saved movement's currency equals
      its wallet's currency, covered by a widget test.
- [ ] Rows, detail and the CSV `Currency` column show the wallet's currency even for a stored
      movement whose own `currency` differs, covered by a unit test (CSV) and a widget test (row).
- [ ] A stored movement without a `currency` field loads with its wallet's currency, covered by a
      unit test.
- [ ] `SettingsService` no longer has a default-currency getter/setter or the `default_currency` key,
      and nothing references them.
- [ ] Deleting a wallet with N > 0 movements shows a confirm naming N; confirming removes the wallet
      and exactly its N movements (other wallets' movements untouched); cancelling changes nothing.
      Covered by a service test and a widget test.
- [ ] `flutter test` and `flutter analyze` pass.

## Notes

- Owner decisions 2026-11-05: wallet owns the currency; drop the default setting; delete wallet ⇒
  delete its movements after confirm; category deletion keeps the silent "Other" fallback.
- Follows the signed-off styleguide (dialog pattern for the confirm, red destructive action).
- `cash-ledger-f150f` (list-style unification) touches the same account screen and runs after this.

## Verifier note (iteration 1)

**REASONS:**
- Criterion 1: the edit form has no test. `test/wallet_currency_test.dart` only drives `AddExpenseScreen`, so the edit form's `currency: _selectedAccount!.currency` (`edit_expense_screen.dart:184`) is uncovered.
- Criterion 1: the add-form test reads back through `ExpenseService().getExpenses()`, which this diff changed to override every currency with the wallet's. The test would pass even if the form saved USD. It must check the raw stored JSON `currency` in SharedPreferences (`prefs.getStringList('expenses')`).
- The "no picker existed" claim holds (HEAD~1 had no `DropdownButton<Currency>`). Hardening is fine, but the test must still catch a wrong save.
- Check 5: `README_DELTA` is empty, but the diff adds two domain rules the README's `## Aggregates` doesn't record. The wallet's currency overrides a movement's stored currency for display and export (the stored value is only a fallback). Deleting a wallet deletes its movements. Report `README_DELTA` ops for the Wallet/Movement bullets.
- Everything else holds: CSV and row tests, missing-field test, settings removal, wallet-delete service and widget tests. `flutter test` (40) and `flutter analyze` are clean.

**SUGGESTED_FIX:** Add an edit-form widget test, and fix the add-form test, so both assert that the raw stored `currency` in SharedPreferences equals the wallet's code. For edit, use a movement stored as USD in a EUR wallet. Also report `README_DELTA` ops for the wallet-owns-currency override and the wallet-delete-deletes-movements rule.

**ITERATION_HINT:** likely-fixable

## Outcome

`ExpenseService.getExpenses` now sets every movement's currency to its wallet's. The stored value is used only when the wallet can't be resolved, and a missing `currency` field is handled the same way. CSV export and the movement rows therefore use the wallet's currency. The add and edit forms save the wallet's currency; neither form had a currency picker before (only a read-only symbol). Tests check the raw stored JSON `currency` for both forms; for edit, a USD movement in a EUR wallet is stored as EUR. `settings_service.dart` held only the unreferenced default-currency setting, so it was deleted. `AccountService.deleteAccount` also removes the wallet's movements, and the account screen's confirm says "This also deletes N movement(s)." Tests are in `test/wallet_currency_test.dart` (41 passing); `flutter analyze` is clean. The cash-ledger README's Wallet and Movement aggregate bullets record both rules. ADR-0004's key table still lists `default_currency` as a historical key; the key is no longer written.
