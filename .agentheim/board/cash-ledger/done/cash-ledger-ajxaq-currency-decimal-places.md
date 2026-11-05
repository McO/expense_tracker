---
id: cash-ledger-ajxaq
title: Each currency has its own number of decimal places (ISO for built-ins, editable for custom currencies)
status: done
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001]
blocks: [cash-ledger-yc1h3, cash-ledger-my7ez]
tags: [currency, amount, decimals]
related_adrs: [ADR-0004]
related_research: []
prior_art: [cash-ledger-apzzm]
---

## Why

Not every currency has 2 decimal places:
- Japanese yen and Korean won have none.
- Kuwaiti, Bahraini and Omani dinars have 3.
- Some currencies are effectively whole-number in cash, such as the owner's LEK (Albanian lek).

Today `Currency` has no notion of decimals, so everything is entered and shown with 2. The owner wants the amount input and display to follow each currency's real decimals. This task is their foundation.

## What

- `Currency` gains `decimalPlaces` (int, 0–3).
- **Built-in currencies** use their ISO 4217 minor units: JPY and KRW are 0, and the other 13 built-ins are 2.
- **Custom currencies:**
  - The add-currency dialog gets a "Decimal places" choice of 0, 1, 2 or 3, defaulting to 2.
  - An existing custom currency can be edited to change its decimal places, along with its symbol and name. The code stays fixed, because transactions reference it. (Today the screen only has add and delete.)
- **Storage:** stored custom currencies without the field load with 2 (ADR-0004: no schema migration, tolerant `fromJson`). Built-ins resolved by code always use their ISO value. `toJson` writes the field.
- **Shared rounding helper:** add one place where an amount is rounded to its currency's decimals. The later tasks use it when saving amounts; this task only adds it and tests it.

## Acceptance criteria

- [ ] `Currency.jpy.decimalPlaces == 0`, `Currency.krw.decimalPlaces == 0`, and `Currency.eur.decimalPlaces == 2`. All 15 built-ins match ISO 4217. Unit-tested.
- [ ] A custom currency JSON without `decimalPlaces` loads with 2, and one with `decimalPlaces: 0` round-trips. Unit-tested.
- [ ] Adding a custom currency with decimal places 0 stores it, and the currency list shows it. Widget-tested.
- [ ] Editing an existing custom currency's decimal places (and symbol/name) persists, keeps its code, and leaves existing transactions intact. Widget-tested.
- [ ] Rounding an amount to its currency's decimals is unit-tested: 1500.4 JPY → 1500, 12.345 EUR → 12.35, 1.2346 at 3 decimals → 1.235.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] The currency dialogs' new decimal-places control fits the styleguide. [human-eye]

## Notes

- The owner chose decimals per currency over a fixed 2 on 2026-11-05.
- Follow-up tasks:
  - cash-ledger-yc1h3: amount input follows the phone's locale and the currency's decimals.
  - cash-ledger-my7ez: on-screen amounts follow the phone's locale and the currency's decimals.
- Out of scope:
  - Displaying amounts with the new decimals (my7ez).
  - CSV export and import (they stay locale-independent and unchanged).
  - Cash rounding (CHF 0.05).

## Outcome

`Currency` now has `decimalPlaces` (0-3).
- **Built-ins:** JPY and KRW have 0, the other 13 built-ins have 2. A built-in always uses its ISO value, even if stored JSON says otherwise.
- **Stored data (ADR-0004):** custom JSON without the field loads with 2, and invalid values also fall back to 2. `toJson` writes the field.

`Currency.roundAmount` rounds half away from zero, with a tiny relative epsilon:
- the criterion's cases: 12.345 EUR → 12.35, 1500.4 JPY → 1500, 1.2346 at 3 decimals → 1.235;
- the verifier's probe: 2.675 → 2.68, 0.005 → 0.01, and negatives mirror correctly.

The Currencies screen:
- **Add:** the dialog has a Decimal places chip choice (0-3, default 2).
- **Edit:** a new menu entry changes symbol, name and decimals; the code is locked.
- **Effect of an edit:** `CurrencyService.updateCustomCurrency` also rewrites the embedded currency copy on the accounts that use it. Transactions store only the code, so they stay consistent.
- **Crash fix:** the dialog no longer disposes its controllers mid-animation, which had crashed it.

Checks:
- 6 new tests in `test/currency_decimal_places_test.dart`; all 98 tests pass and analyze is clean.
- `AGENTS.md` is updated.
- Verification passed on iteration 1.

Notes for the follow-up tasks:
- my7ez should avoid showing `-0`; the verifier saw -0.004 round to -0.0.
- The edit test checks that stored transactions are untouched using a synthetic entry, not a real transaction reload.

Pending: the owner's eye-check of the decimal-places control.
