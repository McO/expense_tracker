---
id: infrastructure-bza94
title: Record the existing app architecture as an ADR (setState, screen-owned services, imperative navigation)
status: todo
type: decision
context: infrastructure
created: 2026-11-04
depends_on: []
blocks: []
tags: [adr-backfill, architecture, state-management, navigation]
related_adrs: []
related_research: []
prior_art: []
---

## Why

New work (statistics screens, currency/category cleanup) will be tempted to introduce a state
management library or routing package. Recording the current conventions makes that a deliberate
decision, not drift.

## What

Commit an ADR documenting the current conventions: vanilla `StatefulWidget` + `setState`;
services instantiated directly in screens; screens re-fetch via `_loadData()` after mutations
and after returning from sub-screens; imperative `Navigator.push`/`pop`, no named routes; theme
mode propagated via callbacks from the root widget.

## Acceptance criteria

- ADR committed with `scope: global`; justification matches the draft below (or the
  owner-amended version).
- No code change.

## Notes

Draft ADR (number provisional, finalized at integration):

```markdown
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
architecture.

## Decision
State lives in each screen's `StatefulWidget` and changes via `setState`. Services are created
inside screens (`final ExpenseService _expenseService = ExpenseService()`). After any mutation,
and after returning from a pushed screen, the screen calls `_loadData()` to re-read storage.
Navigation is imperative (`Navigator.push`/`pop`), no named routes or router package. Theme mode
is passed down from `_ExpenseTrackerAppState` via `onThemeModeChanged` callbacks. No Provider,
Riverpod, BLoC, GetX, `ChangeNotifier` or `InheritedWidget`.

## Consequences
### Positive
- No framework to learn or upgrade; every screen is self-contained and easy to read.
### Negative
- Screens re-read all data on every refresh; fine at current volume, wasteful if it grows.
- Cross-screen state (theme) must be threaded through every intermediate screen.
- Services are hard to substitute in tests (no injection).
### Neutral
- Introducing a state-management library later is a new ADR that supersedes this one.

## Alternatives considered
- **Provider / Riverpod / BLoC** — not adopted; overhead not justified at this size.
- **go_router / named routes** — not adopted; no deep links or web routing needed.
```
