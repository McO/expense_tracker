---
id: cash-ledger-yc1h3
title: Amount input follows the phone's number format and the currency's decimals, tolerating the other separator, symbols and spaces
status: doing
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [cash-ledger-ajxaq, design-system-001]
blocks: [cash-ledger-my7ez]
tags: [amount, input, locale, decimals]
related_adrs: [ADR-0007]
related_research: []
prior_art: [cash-ledger-qjysm]
---

## Why

The amount fields are not tolerant of different number formats.
- **Add and Edit transaction** use `double.tryParse`, so `12,50` is rejected as invalid. So are `€12`, ` 12.5 ` and similar.
- **Correct balance** swaps `,` for `.`, but nothing else.
- Depending on the phone's language, Android's number keypad offers either `.` or `,`.

The owner wants the form to follow the phone's number format instead of guessing.

## What

One shared, pure amount parser and formatter, used by all three amount inputs: Add transaction, Edit transaction, and Correct balance.

- **Locale:** use the phone's locale for the decimal separator, for example `,` for de_DE and `.` for en_US. The app sets no `supportedLocales`, so `Localizations.localeOf` would always be en_US. Read the device locale (e.g. `PlatformDispatcher.instance.locale`) behind a small injectable seam, so tests can force de_DE or en_US. Follow the CsvFilePicker / AppVersionLookup seam pattern.
- **Parsing is tolerant:**
  - Accept the locale's decimal separator, and also the other one (`.` ↔ `,`) as the decimal point, since some keypads only offer one.
  - Ignore surrounding whitespace and a typed or pasted currency symbol or code: the account currency's symbol, `€`, `$`, `EUR` and the like.
  - Thousands separators are **not** supported. A number with more than one separator, or with letters left after stripping, is invalid.
- **Decimals:** at most the account currency's `decimalPlaces` (cash-ledger-ajxaq). For 0-decimal currencies, no decimal separator is allowed. Typing beyond the limit is prevented, or shown as a validation error; prevention is preferred.
- **Normalize on leave:** when the field loses focus, rewrite valid input in the phone's format with exactly the currency's decimals. For example, de_DE EUR `12,5` → `12,50` and en_US `12.5` → `12.50`, and JPY `1500` stays `1500`.
- **Edit and Correct balance open values in the same locale format,** for example `12,50` instead of `12.5`.
- **Saved value:** rounded to the currency's decimals (the ajxaq helper), positive for transactions. Correct balance still allows a minus for counted cash below zero only if it allows it today; keep its current sign behaviour.
- **Hint and placeholder:** these follow the locale and decimals, for example `0,00`, or `0` for JPY.

## Acceptance criteria

- [ ] **Parser unit tests, de_DE + EUR:** `12,50` → 12.5 · `12.50` → 12.5 · ` €12,5 ` → 12.5 · `EUR 7` → 7 · `1.234,56` → invalid · `12,345` → invalid (3 decimals for a 2-decimal currency) · `abc` → invalid.
- [ ] **Parser unit tests, en_US + EUR:** `12.50` and `12,50` → 12.5.
- [ ] **Parser unit tests, JPY:** `1500` → 1500, and `1500,5` / `1500.5` are invalid.
- [ ] **Parser unit tests, a 3-decimal currency:** `1,250` → 1.25.
- [ ] **Formatter unit tests:** de_DE EUR 12.5 → `12,50`, en_US EUR 12.5 → `12.50`, JPY 1500 → `1500`.
- [ ] **Widget test:** with locale de_DE, entering `12,50` in Add transaction saves 12.5. The same input previously failed validation.
- [ ] **Widget test:** leaving the field with `12,5` (de_DE, EUR) shows `12,50`.
- [ ] **Widget test:** Edit transaction opens an existing 12.5 EUR amount as `12,50` under de_DE.
- [ ] **Widget test:** Correct balance accepts `95,30` under de_DE and records the right correction difference.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] On the emulator (and the owner's German-locale phone), typing amounts with the phone's keypad feels natural, for both a EUR and a 0-decimal account. [human-eye]

## Notes

- Owner decisions on 2026-11-05:
  - Follow the phone's format instead of guessing what `1.234` means.
  - Accept currency symbols and spaces.
  - No thousands separators.
  - Normalize the text when the field loses focus.
  - Decimals per currency.
- On-screen display of amounts elsewhere in the app is cash-ledger-my7ez. Reuse this task's formatter there; don't build a second one.
- CSV export and import stay locale-independent (dot decimal) and are out of scope.
