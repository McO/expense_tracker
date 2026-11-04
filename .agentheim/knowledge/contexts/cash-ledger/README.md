# Cash ledger

## Purpose
Recording cash movements per currency wallet, keeping each wallet's balance true to the physical
cash, showing quick-glance cash statistics, and exporting movements as CSV for MoneyMoney.

## Classification
core

This is the whole reason the app exists (ADR-0001): MoneyMoney sees everything except cash.

## Actors
- **Owner** (sole user) — records movements on the phone, checks balances and statistics, exports
  date ranges.
- **MoneyMoney** (external, downstream) — imports the CSV into one cash account per currency.

## Ubiquitous language
- **Wallet** — the cash held in one currency; mirrors exactly one MoneyMoney cash account.
  *Named `Account` in the current code (`lib/models/account.dart`).*
- **Movement** — any change to a wallet's balance. Kinds:
  - **Spending** — cash paid out for something. Counts in statistics.
  - **Income** — cash received from someone else. Counts in statistics.
  - **Top-up** — cash entering a wallet from the owner's own money (ATM withdrawal, currency bought
    by card). Moves the balance; not income.
  - **Correction** — adjusts the balance to match the physical wallet, either direction. Moves the
    balance; not spending or income.
  - **Exchange** *(nice-to-have)* — cash swapped for cash; leaves one wallet and enters another at
    the rate actually received.
  *Current code: `Expense` with `TransactionType` `expense | income` only; top-ups and corrections
  are recorded as income today.*
- **Balance** — sum of all movements in a wallet; should equal the physical cash.
- **Category** — what a spending or income movement was for.
- **Export name** — the MoneyMoney category a category maps to on export
  (`Category.exportName`).
- **Currency** — a wallet's currency; predefined or user-defined custom.
- **Export** — a CSV of one wallet's movements over a chosen date range.
- **Wallet check / Burn rate / Spending mix / Leftover foreign cash** — the four quick-glance
  statistics (see vision).

## Aggregates
- **Wallet** — has exactly one currency; its balance is the sum of its movements.
- **Movement** — amount is always positive, its kind decides direction; belongs to exactly one
  wallet (an exchange touches two).
- **Category** — default categories are seeded once; a movement whose category no longer exists
  falls back to "other" (intentional, keep it).

## Key events
- Movement recorded / edited / deleted
- Export produced

## Key commands
- Record movement, edit movement, delete movement
- Manage wallets, categories, currencies
- Export wallet movements for a date range

## Frontend rule — styleguide gate
This BC has a UI. **Every frontend task in this BC must `depends_on: [design-system-001]`**
and may not be promoted until the owner has signed off on the styleguide.

## Relationships with other contexts
- **Customer of:** infrastructure (persistence, platform, build).
- **Conformist to:** MoneyMoney's CSV import format.
- **Customer of:** design-system (UI tokens and components).

## Open questions
- How top-ups and corrections should appear in the CSV so MoneyMoney treats a top-up as a
  transfer (open since 2026-11-04).
- How existing income records that are really top-ups or corrections migrate, given no schema
  migration (open since 2026-11-04).
- Default burn-rate period (open since 2026-11-04).
