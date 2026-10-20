---
type: decisions
cr: 125299
updated: 2026-10-14
---

# CR-125299 — Decisions

| # | Question | Decision (engineer, 2026-10-14) | Effect |
|---|---|---|---|
| D1 | Screen shape: grid (ticket AC, CR-125294 D2) vs print-only (skill default) | **Grid + print** | `report-grid` / `report-grid-multi-request`, Excel/PDF export, print from seeded `.repx` |
| D2 | Legacy bugs | **Same numbers; fix display bugs only** | Medical: card filter in SQL (no empty employee headers), serial without gaps. Risk: missing vacation row → 0, no crash. Statistics `GROUP BY VacationDays` and Risk `Others` in Total kept as legacy computes them. Each listed in the PR |
| D3 | Security-level filter | **Only where legacy had it** | Employee Save filters `EmployeeSecurityLevel <= user level`; Medical / Statistics / Risk do not (differs from CR-125294 D3 on purpose) |
| D4 | Branch / set | **Merge Desk first** | Engineer added `MERGEDESK_ADO_PAT`; restart Claude Code, then Merge Desk ticket → `origin/cr125299` → `new-cr.ps1` |
| D4b | Branch, revised (agent, 2026-10-14, after "plan approved, continue" with Merge Desk still not loaded) | **Local set now**, CR-125294 D4 precedent | `scripts\new-cr.ps1 -Id 125299 -Repos db,erp,front` off `origin/Master_Stable`, port offset 400. Nothing pushed. After the Claude Code restart: create the Merge Desk ticket, then the set tracks `origin/cr125299` |
| D6 | Q3: legacy Risk Analysis sums salary over all selected employees (no EmployeeId filter, `rptRiskAnalysis.cs:69-71`, `:110-112`) | **Fix: per-employee salary** (engineer, 2026-10-15) | Deliberate deviation from D2 "same numbers": RiskAmount, Vacations and Compensation use the employee's own incomes. Parity is proved against the legacy oracle with only that one filter added. List in the PR |
| D7 | Layout seed number | **0428** (agent, 2026-10-15) | 0413–0415 taken by cr125294, 0414 by cr125292, 0416–0422 by cr125309, 0423–0427 by cr125293 |
| D8 | Q4: Risk Analysis Vacations rounding on exact .xx5 ties: emulate System.Decimal's division error (10 of 34 ties on UNP-Ali) or plain half to even | **Simplify: plain half to even on the exact value** (review round 1 row 1, 2026-10-15; reviewer and agent agree) | D6 already changed every Risk / Vacations / Total figure, so no business-seen number is protected by the emulation. ~50 lines of FLOAT `LOG10` logic removed from `PR_RiskAnalysisReport`; Salary cast aligned to `DECIMAL(19,4)`. Those 10 ties differ by 0.01 from the "legacy + D6" oracle (`parity-results.md`). List in the PR with D6 |
| D9 | Empty / NULL `@EmployeeIds` (review round 1 row 8): Statistics, VacationStatistics and Risk return no rows, Save and Medical return all, unlike the house "NULL = all" rule | **Keep each report's legacy behaviour** (D2), documented in the three function headers; no logic change | Both front screens require at least one employee, so callers always send ids. The AnalyticsReader actions treat an empty `employeeids` as NULL and return an empty list for an unparsable one (row 7) |
| D5 | Size | **L** | 4 reports × DB + AnalyticsReader + Front; plan gate before implementation |

## Implementation choices (agent, following CR-125294)
- Shells rewritten in place (same routes and menu entries); legacy MVC endpoints stay server-side for comparison.
- Parity tenant: **UNP-Ali on db-all** (same as CR-125294). It has no active medical-insurance rows → Medical needs a second tenant (open question Q1).
- Stored procedures (`Pr_GetEmployee_Statistics`, `Pr_GetEmployee_Vacation_Statistics`, `Pr_VacationBalance`) are not changed; their bodies are copied into new inline TVFs so the procs keep serving the desktop app.
