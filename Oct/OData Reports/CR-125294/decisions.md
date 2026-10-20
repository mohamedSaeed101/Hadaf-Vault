---
type: decisions
cr: 125294
updated: 2026-10-13
---

# CR-125294 — Decisions

| # | Question | Decision (engineer, 2026-10-13) | Effect |
|---|---|---|---|
| D1 | Legacy Advance/Purchase SQL skips the date range (and Advance skips IsAdvance/Confirmed) when no employee is selected — replicate or fix? | **Fix** | New TVFs always apply the date range; Advance always filters `IsAdvance = 1 AND Confirmed = 1`. Parity holds whenever employees are picked; with no employee picked the new reports return fewer rows on purpose |
| D2 | Screen shape: interactive grid (ticket) vs print-only (migration skill default) | **Interactive grid** | Unpaid = `report-grid`; Advance and Purchase = `report-grid-multi-request` with the repayment schedule as detail (two TVFs each) |
| D3 | Security-level filter (legacy has none; sibling uses a client-sent one) | **Yes, server-side** | `EmployeeSecurityLevel <= _userSession.SecurityLevel` in all five TVFs. Managers above the user's level are hidden |
| D4 | Worktree set (Merge Desk had not created the branch) | **Create locally** with `scripts\new-cr.ps1` off `Master_Stable` | Set `worktrees\cr125294` (db, erp, front), port offset 100. Nothing pushed |

## Implementation choices (agent, within the decisions)

- Day boundaries are normalised **inside** the TVFs (from = 00:00:00, to = 23:59:59) so the legacy `< @to` / `BETWEEN` semantics hold whatever the backend sends.
- Front sends dates as `yyyy-MM-dd` strings, so a timezone can't move a day.
- The repayment TVFs join their header TVF with the same parameters, so the detail can never cover a different set of advances or purchases than the header.
- Unpaid keeps legacy `EmployeeName` only (legacy shows `PR_Employee.EmployeeName` in both languages); currency column follows UI language (`ArabicLetter` / `EnglishLetter`).
- The three existing shells were rewritten in place (same routes, same menu entries). The legacy MVC endpoints still exist server-side for comparison, but the web screens no longer call them. The migration skill suggested keeping the iframe route until parity is signed off; the ticket says "without the iframe".
- Routes now carry `data: { ModuleId }` 547 / 549 / 551. These only add access for users with view permission; previously non-admins were blocked.

## Open questions answered (engineer, 2026-10-14)

| # | Question | Decision |
|---|---|---|
| D5 (Q1) | Custom print layouts or grid print | **Build layouts**: Arabic (RTL) + English (LTR) `.repx` per report, seeded with `dbo.InsertLayout` in a new ReferenceDataScripts file |
| D6 (Q2) | Parity tenant | **UnitedPlastic** on `support-db2` |
| D7 (Q3) | Merge Desk ticket | **Create now** so `origin/cr125294` exists |
