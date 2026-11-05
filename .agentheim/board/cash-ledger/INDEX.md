# Cash Ledger — Index (task board)

Catalog of this bounded context's tasks by status.

> Updated by: `modeling` (tasks), the lifecycle verbs (promote / claim / complete / capture / dismiss / bounce / reroute).
> Hand-edits are fine but the verbs will append at the section markers below.

---

## Tasks by status

<!-- task-counts:start -->
- **Backlog:** 1
- **Todo:** 0
- **Doing:** 0
- **Done:** 5
<!-- task-counts:end -->

### Todo
<!-- todo-list:start -->
<!-- todo-list:end -->

### Doing
<!-- doing-list:start -->
<!-- doing-list:end -->

### Done (most recent first; older entries kept for prior-art search)
<!-- done-list:start -->
- **cash-ledger-bktw5** — Add a Statistics screen with the four quick-glance cash statistics for the selected wallet (feature) — `done/cash-ledger-bktw5-quick-glance-statistics-screen.md`
- **cash-ledger-vsszp** — Enter movements as a signed amount with a ± toggle, correct a wallet's balance from the counted cash, and flag categories that don't count in statistics (feature) — `done/cash-ledger-vsszp-movement-kinds-ui.md`
- **cash-ledger-qjysm** — Replace the top-up/correction kinds with signed amounts plus a per-category "count in statistics" flag (feature) — `done/cash-ledger-qjysm-signed-amount-and-category-flag.md`
- **cash-ledger-s2v1q** — Add top-up and correction movement kinds to the model, totals and CSV export (no UI) (feature) — `done/cash-ledger-s2v1q-movement-kinds-model-totals-export.md`
- **cash-ledger-ngxsa** — Record the existing CSV export as an ADR (per-wallet date range to Downloads, for MoneyMoney) (decision) — `done/cash-ledger-ngxsa-record-csv-export.md`
<!-- done-list:end -->

Current-month entries stay live in full — the nominal ~30-entry figure
(`lib/index-rotation.mjs`'s `DEFAULT_CAP_ENTRIES`) is a steady-state target, not a hard cap, so a
busy month can legitimately hold well past 30 live entries (ADR-0039); rotation never splits a
month. Once a whole month closes and rotation rolls it out, this header is rewritten in place to
name the archive location (ADR-0047) and the block above holds only the still-live entries.
Rolled-out months land verbatim, newest-on-top, in `done-archive/YYYY-MM.md` — the same
cap-and-roll convention ADR-0039 established for `protocol.md` (agentic-workflow-r2c7m), applied
here to the INDEX done-list (agentic-workflow-c8j3w). Rotation never touches the actual
`done/<task-id>-<slug>.md` files or the `**Done:** N` lifetime count above, so `depends_on`/
`blocks` resolution and the dashboard search corpus (ADR-0023) are unaffected; `modeling`'s
prior-art matcher additionally checks `done-archive/` when present.

### Backlog
<!-- backlog-list:start -->
- **cash-ledger-p53v9** — Make the summary card's money colors work in dark mode (bug) — `backlog/cash-ledger-p53v9-summary-card-dark-mode-colors.md`
<!-- backlog-list:end -->

## Pointers

- Done-list archive (entries rolled out beyond the live cap, if any): `done-archive/YYYY-MM.md` (ADR-0039 convention, agentic-workflow-c8j3w)
- Knowledge half (ADRs / research / concepts / BC README) for this BC: `../../knowledge/contexts/<bc-name>/INDEX.md`
