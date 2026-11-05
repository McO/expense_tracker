---
id: cash-ledger-bktw5
title: Add a Statistics screen with the four quick-glance cash statistics for the selected wallet
status: doing
type: feature
context: cash-ledger
created: 2026-11-05
completed:
depends_on: [design-system-001]
blocks: []
tags: [statistics, burn-rate, spending-mix, wallet-check, ui]
related_adrs: [ADR-0001, ADR-0003, ADR-0007]
related_research: [expense-tracker-stats-inspiration-2026-11-04]
prior_art: [cash-ledger-qjysm, cash-ledger-vsszp, design-system-001]
---

## Why

The vision's "What success looks like" names four quick-glance statistics about cash only — wallet
check, burn rate, spending mix, leftover foreign cash — and none of them exist as a view yet. The
groundwork is in place: `LedgerTotals` separates balance (every movement) from statistics (only
categories with `countsInStatistics`, so top-ups and corrections never count), and the styleguide's
approved chart style (section 4) fixes how they look. Owner decisions (modeling, 2026-11-05): a
dedicated Statistics screen; it follows the wallet selected on home; burn rate defaults to **this
month** and shows both the daily average and how long the cash lasts.

## What

- **Statistics screen.** A new screen reached from the home screen's drawer (beside Correct balance
  and Export). It shows statistics for the **wallet currently selected on home**, in that wallet's
  currency only (never converted, ADR-0001). Built with plain widgets / `CustomPaint`, no chart
  package (styleguide §4).
- **Period control.** A segmented control styled like the styleguide's toggle with two values:
  **This month** (default) and **Last 7 days**. It sets the period for the burn rate and spending
  mix.
- **Leftover cash / wallet check.** The wallet's current balance (`LedgerTotals.balance`, every
  movement) as the first card, with a "Correct balance" action that opens the existing dialog
  (`correct_balance_dialog.dart`) for this wallet.
- **Burn rate.** Spending in the period — money out in categories that count in statistics — as a
  headline **daily average** (spending ÷ days elapsed in the period, today included), with a caption
  **"At this pace your <balance> lasts ~N days"** (balance ÷ daily average, rounded down). Omit the
  caption when the daily average is 0 or the balance is ≤ 0. Below it, a **last-7-days bar chart**
  of daily spending (expense colour, today highlighted, no axes or gridlines, value label on the
  tallest bar) — always the last 7 days regardless of the period control.
- **Spending mix.** Horizontal bars per category for spending in the period, largest first: emoji
  tile, name, bar, amount (styleguide §4 rule 2). Only categories that count in statistics; empty
  state when there is no spending in the period.
- **Computation lives outside the widget.** Put the period filtering, daily average, "lasts N days",
  per-day series and spending-mix numbers in a pure, unit-testable helper (e.g. alongside
  `LedgerTotals`), taking the movements and a "today" date as input.
- Follow the signed-off styleguide (`.agentheim/knowledge/contexts/design-system/styleguide/README.md`),
  scheme-aware colours.

## Acceptance criteria

- [ ] The home drawer has a "Statistics" entry that opens the Statistics screen for the selected
      wallet, covered by a widget test.
- [ ] The period control defaults to This month and switches to Last 7 days, changing the burn rate
      and spending mix figures, covered by a widget test.
- [ ] The balance card shows `LedgerTotals.balance` for the selected wallet, and its "Correct
      balance" action opens the existing dialog, covered by a widget test.
- [ ] Daily average = spending in counting categories over the period ÷ days elapsed (this month:
      from the 1st to today inclusive; last 7 days: 7), excluding top-ups, corrections, income and
      other wallets, covered by unit tests with a fixed "today".
- [ ] "Lasts ~N days" = floor(balance ÷ daily average), hidden when the average is 0 or the balance
      ≤ 0, covered by unit tests.
- [ ] The last-7-days series has exactly 7 daily spending values ending today, covered by a unit
      test.
- [ ] Spending mix lists counting categories by spending in the period, largest first, and shows an
      empty state when there is none, covered by a unit test and a widget test.
- [ ] `flutter test` and `flutter analyze` pass.
- [ ] The Statistics screen follows the approved chart style and looks right in light and dark
      mode. [human-eye]

## Notes

- Owner decisions (2026-11-05): dedicated screen; selected wallet only (leftover foreign cash = the
  selected foreign wallet's balance); burn rate default period = this month; show both daily
  average and "lasts ~N days". This answers the vision's open question on the burn-rate period.
- Research: `expense-tracker-stats-inspiration-2026-11-04` (quick-glance list: daily average,
  last-N-days bars, simple category bars, period control; Trail Wallet's "left today" and
  TravelSpend's daily average are the closest prior art).
- Model: ADR-0007 — `LedgerTotals.balance` / `LedgerTotals.statistics`, `Category.countsInStatistics`,
  `Expense.signedAmount`. Reuse, don't duplicate, the balance-vs-statistics split.
- Out of scope: trips, budgets, conversion, trends (vision non-goals); the summary-card dark-mode
  colours (`cash-ledger-p53v9`).
