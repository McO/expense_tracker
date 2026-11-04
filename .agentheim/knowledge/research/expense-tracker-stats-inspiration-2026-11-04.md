---
topic: Statistics / insight features in mobile expense trackers, with emphasis on cash and multi-currency travel spending
date: 2026-11-04
requested_by: brainstorm
related_tasks: []
---

# Research: Expense tracker statistics and insights (cash / multi-currency travel)

## Question
Which on-phone stats and insights do comparable expense trackers offer? Which are distinctive and liked? What is specific to multi-currency or travel use? Which fit a "quick glance" use and which are deep analysis that MoneyMoney already covers?

## Summary
- Baseline across the apps: category pie or breakdown, period totals, budget vs. spent, per-account or per-currency views, and search or filters by date, category and tag. Sources are mostly store listings and vendor pages [1][2][3][4][5][6].
- The distinctive travel feature is a daily budget with a daily average, shown per trip or per leg. Trail Wallet and TravelSpend are built around it. Trail Wallet adds "how much left today", a five-day bar chart, and spreading an item over several days. TravelSpend adds a home-screen widget, and a reviewer says large items like flights can be kept out of the daily figures [1][2][7].
- Multi-currency handling is typically: enter in local or home currency and convert to a home currency. Rate sources are often opaque. Some apps allow a manual rate (Toshl, Tricount). Trail Wallet's rate is updated manually in-app. One TravelSpend source mentions conversion issues (low reliability) [1][2][3][13][15].
- Several of the relevant apps (Trail Wallet, TravelSpend, Toshl, Wallet) convert to a single home currency. This app's per-currency-account model differs. Stats that stay per currency avoid rate issues entirely. Cashew is the one found that shows original and converted amounts side by side [3][10].
- Evidence of user preference is thin. Most "liked" claims come from single blog reviews or store text, and no user-forum threads were retrieved. Treat the "liked" column as indicative only.

## Findings

### 1. Baseline (common across apps)
- Category pie or breakdown charts: Trail Wallet [1], TravelSpend [2]. (Wallet and Toshl pie-chart claims dropped: no source I can cite.)
- Budgets over a period with progress and alerts: Cashew (daily, weekly, monthly or custom ranges, per-category limits) [3]. Wallet (one-time or recurring budgets only; period types not confirmed) [6]. Toshl (any period, filterable by category, tag or account, optional rollover; per the GB App Store listing, vendor marketing) [5].
- Period views of daily, weekly and monthly data: Money Manager by Realbyte, per the Google Play description quoted in search results [11]. Calendar view was not confirmed.
- Filters and search by date range, category, amount or tag: Cashew [3], TravelSpend (last 30 days, this month, this year, custom, with totals) [2], Trail Wallet (tag filter) [1].
- Month-over-month comparison and filtering by category, tag or location: Toshl (store listing) [5]. This is marketing text.
- CSV export of a date range or a whole trip: Trail Wallet [1]. This is the export pattern the owner already uses.

### 2. Distinctive features and reception
- **Daily budget with "left today":** Trail Wallet. Tap the daily budget to see what remains. Spending is tracked daily, per trip or per month. A bar chart shows the last five days [1]. A reviewer describes the daily summary as making it easier to stick to the budget (single-source claim via search summary; page itself returned 403) [12].
- **Spread an expense over several days / exclude large one-offs from daily figures:** Trail Wallet [12] and TravelSpend. A TravelSpend reviewer notes flights can be kept out of daily totals [2]. Source quality: store page plus one reviewer.
- **Daily average as the headline number:** a TravelSpend user review (via search results) calls the daily average "the best measure of how we're doing budget-wise" and says the dashboard can show trip total plus daily average on opening [7]. Single-source. The store page lists "30-Day Average" and "Last 30 Days" cards and a widget, but flags them as Premium and for trips of 60+ days [2].
- **Home-screen widget with daily average:** TravelSpend v2.9.3 [2]. This is a quick-glance pattern.
- **Trip recap sharing:** TravelSpend v2.6.x [2].
- **Customizable home screen and widgets, original plus converted amount per transaction:** Cashew [3]. Cashew is free and has a 4.8 Google Play rating over about 23K reviews, per search results. Aggregator counts conflict [10].
- **Past budget history:** Cashew [3].
- **Tag, location, and account-filtered planning graphs:** Toshl [5].
- **Debt tracking:** Wallet's store listing says "manage debt" [6]. Low relevance to cash tracking. (Debt-to-income removed, see Unverified claims.)
- **Complaints (relevant as anti-patterns):**
  - TravelSpend: UI navigation friction after an update and high subscription cost for infrequent travelers, per an AI-generated aggregator summary (low reliability) [13].
  - Wallet: earlier claim of rate/base-currency complaints removed (not supported by sources checked).
  - Premium paywalls on stats: TravelSpend reportedly gates the full statistics and live rates [7].
  - TravelSpend reviewer: no per-category budgets [2].

### 3. Multi-currency and travel specifics
- **Trip as a container with its own budget and dates:** Trail Wallet (multiple trips with separate budgets and durations, per-trip history) [1][12] and TravelSpend (each trip has its own budget; a reviewer says separate budgets per country or leg are possible) [2][7].
- **Enter in either currency, convert to home currency:** Trail Wallet allows entry in local or home currency, covering 218 countries [1]. TravelSpend converts automatically to home currency [2]. Showing the total in both currencies is ⚠️ UNVERIFIED (only from a review that 404'd on fetch [7]).
- **Rate handling:**
  - Trail Wallet: manual in-app update, needs internet [1].
  - TravelSpend: last-fetched rate used offline, per reviewer. The store page does not say where rates come from [2][7].
  - Toshl: built-in rates update on each sync using that day's figures; users can enter their own rate and add custom currencies (with a self-supplied rate) [15]. The store listing only says "always fresh exchange rates" [5].
  - Wallet: multi-currency support is listed on BudgetBakers' site, with no rate details [16]. A 2021 article (via search) said rates came from currencylayer.com [6]; not re-verified.
  - Tricount: daily market rates with a manual per-expense override, per search summaries [9].
  - Splitwise: sources conflict on whether auto-conversion is a Pro feature. Not resolved [9].
  - One source notes that converted figures can differ from what the traveller actually paid (card or exchange), and suggests recording which rate was used [9]. This matters for cash, where the true rate is the one at the exchange counter.
- **Two currencies shown side by side:** Cashew's original-plus-converted display per transaction [3] (README). Travel Cutter [14] (agency write-up).
- **Group splitting (Splitwise, Tricount):** settlement balances in a group currency [9]. This is not a statistics feature and is largely irrelevant to a solo ledger. It is included only for the currency angle.
- **Trail Wallet status:** its own page says it is no longer available (archival only, copyright 2022, no shutdown date) [1]. It stays a useful design reference, but users cannot get it now.
- **Per-country views:** found only as the "budget per country or leg" idea in one TravelSpend review [7]. No dedicated per-country report was verified in any app.

### 4. Quick-glance vs. deep analysis (explicit split)
This split is my reading of the sources, not a claim any source makes. The recommendation is left to the reader.

**Quick glance (at the till, on a trip, small screen):**
| Feature | Where seen |
|---|---|
| Balance per currency or account | Cashew (switch account/currency on home) [3]. Already present in this app |
| Daily budget with "left today" | Trail Wallet [1] |
| Daily average, 30-day average, trip total | TravelSpend [2][7] |
| Last-N-days bar chart (e.g. 5 days) | Trail Wallet [1] |
| Home-screen widget with daily average or balance | TravelSpend [2], Cashew [3] |
| Original plus converted amount shown together | Cashew [3] |
| Simple category pie for the current period | Trail Wallet [1], TravelSpend [2] |
| Period control. Observed: Trail Wallet views per day, per trip and per month [1]. TravelSpend only has a search filter (last 30 days, this month, this year, custom range) [2]. A four-way today/week/month/trip switch is the author's synthesis, not an observed feature | Trail Wallet [1], TravelSpend [2] |
| Trip or leg container with date range | Trail Wallet [1], TravelSpend [2] |

**Deep analysis (MoneyMoney already covers it, per the brief):**
| Feature | Where seen |
|---|---|
| Month-over-month comparison, trend graphs | Toshl [5] |
| Filtering reports by tag, location or account | Toshl [5] |
| Per-category budgets with rollover | Toshl [5], Cashew [3] |
| Budget history over past periods | Cashew [3] |
| Debt and goal tracking | Wallet (debt) [6], Cashew (goals) [3] |
| Cash-flow analysis | Wallet [16] |
| Bank sync and categorisation rules | Wallet, Toshl (paid tiers) [5][6] |
| Group settlement | Splitwise, Tricount [9] |

**Items that straddle the line:** category pie across a custom date range, search with totals (TravelSpend [2]), and per-category average spend. They are cheap to show but are also what MoneyMoney does after import.

## Sources
1. [Trail Wallet (Voyage Travel Apps)](https://voyagetravelapps.com/trail-wallet/) — vendor page. Feature list, and states the app is discontinued. Copyright 2022.
2. [TravelSpend: Travel Budget App, App Store (CA)](https://apps.apple.com/ca/app/id1434284824?l=en-ca) — store listing with version notes. Vendor marketing plus user reviews. Date not captured.
3. [Cashew on GitHub (jameskokoska/Cashew)](https://github.com/jameskokoska/Cashew) — project README, primary source. Features: budgets, multi-currency, goals, widgets.
4. [Spendee reviews on Capterra](https://www.capterra.com/p/238829/Spendee/reviews/) — only nine reviews. Spendee evidence in this report is thin, so details on it should be treated as unverified. Search summary only; one cash wallet on the free tier and 160+ currencies, with daily rate updates.
5. [Toshl Finance App Store listing](https://apps.apple.com/gb/app/id921590251) — vendor marketing. Month-over-month comparisons, tag/location filters, almost 200 currencies with "always fresh" rates.
6. [Wallet: Budget & Money Manager App Store listing](https://apps.apple.com/us/app/-/id1032467659) — vendor listing: one-time or recurring budgets, "manage debt". Currencylayer detail comes from a 2021 Dhaka Tribune article seen only in search: https://www.dhakatribune.com/business/315521/this-is-your-one-step-solution-to-tracking
7. [Adam and Linds, TravelSpend review](https://adamandlinds.com/travelspend-review-budget-tracking-full-time-travel/) — blogger review quoted via search summary. The page itself returned 404 when fetched. Date unknown.
8. [Trail Wallet 2.1 release notes](https://voyagetravelapps.com/trail-wallet-2-dot-1-released/) — listed in search results only, not read.
9. [Tricount multi-currency page](https://tricount.com/expense-tracker-features/multi-currency-support) and [Splitwise App Store listing](https://apps.apple.com/app/id349866256) — vendor pages for the currency angle. Splitwise Pro behaviour and Tricount rate overrides come from search summaries of blog reviews (for example nomadesim.com, editorialge.com). I did not read those pages myself, and the Splitwise support page could not be fetched.
10. [Cashew on SourceForge, AlternativeTo and other aggregators](https://alternativeto.net/software/cashew--expense-budget-tracker/about) — rating numbers. Aggregator counts conflict.
11. [Money Manager Expense & Budget (Realbyte), AppFollow listing](https://apps.appfollow.io/android/money-manager-expense-budget/com.realbyteapps.moneymanagerfree?country=ua) — Play description. Daily, weekly and monthly review. Its 4.6 rating over about 449K reviews was stated in search results.
12. [Too Many Adapters, Trail Wallet review](https://toomanyadapters.com/review-trail-wallet-app-ios/) — blog review. Fetch returned 403, so only the search summary was used.
13. [marlvel.ai summary for TravelSpend](https://marlvel.ai/apps/com-travel-spend-app) — AI-generated aggregator. Low reliability.
14. [Travel Cutter, Space-O Technologies](https://spaceotechnologies.com/?p=99065) — two-currency comparison display. Product write-up by the agency that built it.

15. [Toshl blog: Travel with Toshl Finance, expenses in different currencies](https://toshl.com/blog/travel-with-toshl-finance-keep-on-top-of-your-expenses-in-different-currencies/amp/) — vendor blog: custom exchange rates, custom currencies, rates update on sync.
16. [BudgetBakers, Wallet personal solutions](https://budgetbakers.com/en/solutions/personal/) — vendor page: "Cash Flow Analysis", "Multi-Currency Support". No debt, budget period or rate detail.

## Unverified claims
- Wallet debt-to-income ratio: dropped. Not found on the listing, BudgetBakers page or Getfinny review.
- Wallet user complaints (base currency, rate update not working): dropped. Not found in the sources checked.
- Wallet weekly/monthly/custom budget periods: dropped. Only one-time/recurring confirmed.
- Wallet and Toshl "pie chart by account": dropped. No citable source.
- TravelSpend shows totals in both entered and home currency: ⚠️ UNVERIFIED. The only source [7] 404'd.
- Toshl "daily" rate updates: the Toshl blog says rates update on each sync using that day's figures [15]; an older "daily" claim from a search summary is not independently confirmed.
- TravelSpend per-person daily metrics: dropped. The store page does not mention them.

## Open questions
- I found no user forum threads (Reddit, XDA, etc.). The searches returned blogs and store listings. "Noticeably liked" claims therefore rest on single reviews. A targeted forum search is needed to confirm what users actually value.
- Spendee, Money Manager (Realbyte), Wallet, 1Money and Tricount statistics screens were not verified from primary sources. Their entries rest on listings and search summaries. 1Money was not covered at all.
- Exchange-rate handling of TravelSpend and Wallet is described inconsistently. TravelSpend reviews disagree between "uses last-fetched rate" and "issues with conversion". Rate sources are undocumented.
- No app found a clean answer for per-country views. No source showed a per-country report as a built-in feature.
- Whether stats gated behind premium (TravelSpend) are the ones users miss most is unknown.
