---
id: 0001
title: The app is a cash-only ledger; MoneyMoney is the system of record
scope: global
status: accepted
date: 2026-11-04
supersedes: []
superseded_by: []
related_tasks: []
related_research: [expense-tracker-stats-inspiration-2026-11-04]
---

# ADR 0001: The app is a cash-only ledger; MoneyMoney is the system of record

## Context
The owner's finances live in MoneyMoney (a Mac banking app), which fetches every bank and card
transaction automatically. Cash is the one blind spot: everyday euro cash at home and foreign cash
on trips. The app was built because a previous cash tracker would not export transactions. Today
each app account mirrors one MoneyMoney cash account per currency, and records are handed over by
a manual date-range CSV export. The owner wants better statistics, which raises the question of
how much analysis this app should do itself.

## Decision
The app records **cash only** and treats **MoneyMoney as the system of record**. It owns capture,
per-currency wallet balances, export, and quick-glance cash statistics (wallet check, burn rate,
spending mix, leftover foreign cash). It does not own trips, budgets, currency conversion, trends,
or any figure that would need card or bank data to be correct.

## Consequences
### Positive
- Scope stays small: every feature request can be tested against "is this about the cash in my
  pocket, and does MoneyMoney not already do it?"
- Statistics stay honest: they never pretend to describe spending the app cannot see.
- Export stays a first-class concern: the data must always be able to leave the app.

### Negative
- No trip cost, budgets or cross-currency totals in the app, even though travel apps commonly
  offer them; those questions have to be answered in MoneyMoney.
- The app depends on MoneyMoney's import behaviour (CSV shape, category names), which it does not
  control.

### Neutral
- Each wallet stays in its own currency; no exchange-rate data is needed.

## Alternatives considered
- **A full multi-currency finance app (trips, budgets, home-currency totals)** — rejected: most
  spending is by card and never enters this app, so its totals would be wrong, and MoneyMoney
  already covers this.
- **Replacing the app with MoneyMoney's own manual entry** — not chosen: capture has to happen on
  the phone, at the till or on a trip.

## References
- `.agentheim/knowledge/vision.md`
- `.agentheim/knowledge/research/expense-tracker-stats-inspiration-2026-11-04.md`
