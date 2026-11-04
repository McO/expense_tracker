---
id: 0003
title: Plain setState, screen-owned services and imperative navigation
scope: global
status: accepted
date: 2026-11-04
related_tasks: [infrastructure-bza94]
---

# ADR 0003: Plain setState, screen-owned services and imperative navigation

## Context
Small single-user app with roughly ten screens and low data volume. This records the existing
architecture (verified against `lib/`), so that adding a state-management or routing library
becomes a deliberate decision rather than drift.

## Decision
State lives in each screen's `StatefulWidget` and changes via `setState`. Services are created
directly as fields inside screens (`final ExpenseService _expenseService = ExpenseService()`);
`ExpenseService` additionally instantiates `CategoryService`, `CurrencyService` and
`AccountService` itself. After any mutation, and after returning from a pushed screen, the
screen re-reads storage through its own loader and then calls `setState`. The loader is named
per screen (`_loadData()` in `HomeScreen`, `_loadAccounts()`, `_loadCategories()`,
`_loadExpenses()` elsewhere); there is no shared base class or mixin.
Navigation is imperative (`Navigator.push` / `Navigator.pop`); there are no named routes and no
router package. Theme mode is owned by `_ExpenseTrackerAppState` in `main.dart` and passed down
via `currentThemeMode` / `onThemeModeChanged` constructor parameters: root -> `HomeScreen` ->
`SettingsScreen`. No Provider, Riverpod, BLoC, GetX, `ChangeNotifier`, `InheritedWidget`,
streams or `FutureBuilder`-style reactive plumbing is used.

## Consequences
### Positive
- No framework to learn or upgrade; every screen is self-contained and easy to read.
### Negative
- Screens re-read all data on every refresh; fine at current volume, wasteful if it grows.
- Cross-screen state (theme) must be threaded through every intermediate screen.
- Services are hard to substitute in tests (no injection).
- Loader naming is inconsistent across screens, so new screens must pick a name by convention only.
### Neutral
- Introducing a state-management library later is a new ADR that supersedes this one.

## Alternatives considered
- **Provider / Riverpod / BLoC** — not adopted; overhead not justified at this size.
- **go_router / named routes** — not adopted; no deep links or web routing needed.

## Note on ADR numbering

Minted provisionally as ADR-0002 in its worker worktree. A sibling task's ADR already claimed that number (or the guess overshot the true count) by the time this task's conductor finalized numbering at squash-merge integration (`lib/adr-allocation.mjs`'s `finalizeAdrNumbering`, ADR-0058) — this ADR was renumbered to **ADR-0003**, the true next-free number on `main` at that moment. No content besides this identity changed.
