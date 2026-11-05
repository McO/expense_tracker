---
id: cash-ledger-my7ez
title: Every amount on screen follows the phone's number format and the currency's decimals
status: todo
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [cash-ledger-ajxaq, cash-ledger-yc1h3, design-system-001]
blocks: []
tags: [amount, display, locale, decimals]
related_adrs: []
related_research: []
prior_art: []
---

## Why

The app shows every amount with a dot and 2 decimals, for example `€12.50` and `¥1500.00`, regardless of the phone's settings or the currency. Once input follows the phone's format and the currency's decimals (cash-ledger-yc1h3), the display should match. The owner chose "everywhere" on 2026-11-05.

## What

- Route every on-screen amount through the shared amount formatter from cash-ledger-yc1h3: phone locale, the currency's `decimalPlaces` from cash-ledger-ajxaq, and the currency symbol.
- **Grouping separators in display:** use the locale's grouping, for example de_DE `€1.234,50` and en_US `€1,234.50`. The input deliberately accepts no grouping (yc1h3). Grouping is display-only, which is normal and unambiguous here.
- **Where amounts appear** (today's `toStringAsFixed(2)` call sites and `formattedAmount` / `formattedAmountWithSign` in `lib/models/transaction.dart`):
  - balance summary card;
  - recent transactions and the transactions list;
  - transaction detail;
  - category breakdown;
  - statistics (balance, burn rate, mix);
  - the Correct balance dialog's "Current balance";
  - the import preview.
- **Symbol position:** keep today's symbol placement (`€12,50`, `-€2,00`) unless the styleguide says otherwise. Do not adopt locale-specific trailing symbols (`12,50 €`); that is a separate decision.
- **Percentages** in statistics and the breakdown may follow the locale's decimal separator too.
- **CSV export stays locale-independent** (dot decimal), because it is a machine format for MoneyMoney. Leave `buildCSV` and `csv_import.dart` untouched.

## Acceptance criteria

- [ ] **Formatter unit tests:** de_DE EUR 1234.5 → `€1.234,50` · en_US EUR 1234.5 → `€1,234.50` · JPY 1500 → `¥1.500` (de_DE) / `¥1,500` (en_US) · negative values keep today's `-` prefix placement.
- [ ] **Widget tests (de_DE):**
  - The balance summary card shows `€1.234,50` for a 1234.5 EUR balance.
  - A JPY account's balance and recent transactions show no decimals.
- [ ] No `toStringAsFixed(2)` remains for on-screen money in `lib/screens/`, `lib/widgets/` or `lib/models/transaction.dart`. A grep shows only CSV code, `lib/services/csv_import.dart` and `transaction_service.dart`'s `buildCSV`.
- [ ] A CSV export produced after this change is byte-identical in its amount format to one produced before it (dot decimal). Covered by the existing export tests, which still pass unchanged.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] On the emulator under a German locale, balances, lists, statistics and dialogs read naturally, and a JPY account shows whole numbers. [human-eye]

## Notes

- This depends on yc1h3 so it reuses its formatter and locale seam, rather than building a second one.
- Out of scope: locale-specific symbol placement (`12,50 €`) and app-wide translations (the UI language stays English).
