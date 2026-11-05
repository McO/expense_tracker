# Vision: Expense Tracker (cash ledger)

## Purpose
A personal Android app that records the one part of my money that MoneyMoney (my Mac banking
app, the system of record for all my finances) cannot see: the **cash in my pockets**, everyday
euros at home and foreign currency abroad. Each account mirrors one MoneyMoney cash account, and
the app hands its records over by manual CSV export. On the phone, it answers quick-glance
questions about cash that would otherwise mean counting notes or opening the Mac.

It exists because the cash tracker I used before would not export my transactions, so my data was
locked in. Getting my records out is a founding requirement, not a feature.

## Users
One user: me, the developer and only user. I record cash spending at the till or shortly after,
in whatever currency I am holding, and periodically export a date range into MoneyMoney's cash
accounts on my Mac.

## The problem
- MoneyMoney fetches every bank and card transaction automatically, but cash is invisible to it.
  Without this app my cash spending, especially foreign cash on trips, never reaches my books.
- Generic tracker apps either lock data in (my previous app) or try to be the whole finance
  system, duplicating what MoneyMoney already does better.
- Cash in several currencies needs separate balances: euros and dollars can't share one pot.

## What success looks like
- Every cash transaction I make can be recorded quickly on the phone, in the currency of the account
  it came from.
- A date-range CSV export lands cleanly in the matching MoneyMoney cash account, with categories
  mapped to MoneyMoney's.
- At a glance, the app answers four questions about cash only:
  1. **Account check:** does the app's balance match what is physically in the wallet?
  2. **Burn rate:** how fast am I going through cash (e.g. euros this month)?
  3. **Spending mix:** what do I spend cash on?
  4. **Leftover foreign cash:** how much do I have left before going home?
- **Top-ups** (ATM withdrawals, currency bought) and **corrections** move the balance but never
  count as spending or income, so the statistics stay honest.
- Currency and category management is clean and predictable.
- The codebase stays on current Flutter and dependency versions.

## Non-goals
1. **Not a full finance app.** MoneyMoney is the system of record. This app records cash only;
   card and bank spending never appears here.
2. **No trips.** No trip totals, trip budgets or trip cost in euros. Most of a trip is paid by
   card, so any trip figure here would be wrong. Trip cost belongs in MoneyMoney.
3. **No deep analysis.** No month-over-month trends, budget history or reports; MoneyMoney does
   that.
4. **No budgets.**
5. **No currency conversion.** Each account stays in its own currency; amounts are never converted
   between currencies or into a home currency.
6. **No bank connection or sync.** Data stays on the phone; the handover is a manual CSV export.
7. **No duplicate-export protection.** Volume is low and duplicates are easy to delete in
   MoneyMoney; tracking what was already exported is deliberately out of scope.
8. **Single user, Android only.** No sharing, no group expense splitting, no iOS.

## Ubiquitous language (seed)
- **Account:** the cash I hold in one currency (e.g. EUR account, USD account). Mirrors exactly one
  MoneyMoney cash account. (Earlier docs, ADRs and tasks call it a *wallet*; same thing.)
- **Transaction:** any change to an account's balance (earlier docs say *movement*). Four kinds:
  - **Spending:** cash paid out for something. Counts in statistics.
  - **Income:** cash received from someone else. Counts in statistics.
  - **Top-up:** cash entering an account from my own money (ATM withdrawal, currency bought with a
    card). Moves the balance; not income. In MoneyMoney terms, a transfer into the cash account.
  - **Correction:** an adjustment so the app's balance matches the physical wallet, in either
    direction. Moves the balance; not spending or income.
  - **Exchange** *(nice-to-have)*: cash swapped for cash in another currency; one transaction that
    leaves one account and enters another, at the rate actually received.
  *The current code knows only `expense` and `income`; top-ups and corrections are logged as
  income today.*
- **Balance:** the sum of all transactions in an account. Should match the physical cash.
- **Category:** what a spending or income transaction was for. Has an **export name**, the
  MoneyMoney category it maps to.
- **Export:** a manual CSV of one account's transactions over a chosen date range, imported into the
  matching MoneyMoney cash account.
- **Account check / burn rate / spending mix / leftover foreign cash:** the four quick-glance
  statistics above.

## Open questions
- ~~How should top-ups and corrections appear in the CSV export, so MoneyMoney treats a top-up as a transfer and not as income? (open since 2026-11-04)~~ — resolved 2026-11-04 by cash-ledger-s2v1q (ADR-0006): top-ups export like income, corrections signed under their own configurable category; old records are not migrated.
- ~~How do existing records, where top-ups and corrections were logged as income, move to the new transaction kinds on an install with real data and no schema migration? (open since 2026-11-04)~~ — resolved 2026-11-04 by cash-ledger-s2v1q (ADR-0006): top-ups export like income, corrections signed under their own configurable category; old records are not migrated.
- ~~What period does the burn rate cover by default (this month, last 30 days, since the last top-up)? (open since 2026-11-04)~~ — resolved 2026-11-05: this month (daily average plus "lasts ~N days"), with a Last 7 days switch; see cash-ledger-bktw5.
- Exchange (cash for cash): when, and how is the received rate recorded? (open since 2026-11-04)
- Overlap with OpenSpec: the repo also carries `openspec/` for spec-driven changes; which one is the source of truth for planning? (open since 2026-11-04)
