---
type: handoff
cr: 125299
updated: 2026-10-14
status: legacy dissected, plan written, waiting on plan approval + Merge Desk restart
---

# HANDOFF — CR-125299: 4 HR reports (Medical Insurance, Employee Save, Employee Statistics, Risk Analysis) → OData

> [!important] Resume here
> No branch, no set, no code yet. Merge Desk MCP still says "not set up": the PAT is in `.env.local`, Claude Code must be restarted. Then: plan approval → P0.

| Step | State |
|---|---|
| 0 Preflight / Merge Desk | done: #12498, components Database / AnalyticsReader / Web Container |
| 1 Intake | done: [[CR-125299 - Source]] |
| Size | **L** |
| Legacy dissection | done: [[CR-125299 - Legacy Analysis]] |
| Decisions | D1–D5: [[decisions]]; open: [[open-questions]] (Q1 Medical tenant, Q2 Medical ModuleId) |
| Plan | written: [[CR-125299 - Plan]] — **STOP for the engineer's approval** |
| Parity tenant | UNP-Ali on db-all (`CR-125292\parity\run.sh` pattern); data present for Save / Statistics / Risk, none for Medical |

## Progress (2026-10-14, after plan approval)
- Plan **approved** by the engineer.
- P0: set `C:\Hadaf_Work\worktrees\cr125299` (db, erp, front) cut locally off `origin/Master_Stable`, offset 400 (decision D4b). Merge Desk ticket still to create after restart. Front needs `npm install` (package.json differs from main checkout) before its gate.
- Q2 answered: Medical ModuleId 521.
- P1a/b/c + parity running (TVFs written in the db worktree, created on UNP-Ali, results → [[parity-results]]).

## Progress (2026-10-15)
- Merge Desk ticket **#12498** created (Beta, Acknowledge, owner Mohamed Saeed); branches `cr125299` in Database / API / WebContainer. Deploy components set on the engineer's request: **Database, AnalyticsReader, Web Container**. Set tracks `origin/cr125299` (same commits as the local cut).
- P1a Save + Medical: done, parity pass (Medical 0 = 0 only, Q1). P1b Statistics: done, parity pass (88/88 master, 617/617 detail, 5 ranges). Files untracked in db worktree, not in `.sqlproj` yet.
- P1c Risk: first run interrupted by the session restart (left nothing); relaunched.
- DB build: VS 2022 Community **amd64** MSBuild (`...\Current\Bin\amd64\MSBuild.exe`); the x86 `Bin\MSBuild.exe` fails with MSB4062 (4tecture task, incorrect format). 4 TVFs registered, in model.xml, 0 warnings on them. Committed db `aa2675266` (local).
- P3a backend (Save `odata/EmployeeSave` keys employeeids; Medical `odata/EmployeesMedicalInsurance` keys employeeids, cardReceive; Statistics `odata/EmployeeStatistics` keys employeeids, fromDate, toDate + detail `odata/EmployeeVacationStatistics` keys employeeids, toDate; ModuleIds 767 / 521 / 459; isArabic = `_userSession.IsDefaultRequestCulture`): build 0 errors, committed erp `9b194b9ace` (local).
- P4a front (3 shells) and P5a layouts (`0415_PR_HrReportsLayout.sql`, 3 reports) running. Front gate needs node_modules: `npm install` in the set needs the engineer's OK (package.json differs from main checkout).

## Progress (2026-10-15, later)
Local commits (not pushed):
- db `aa2675266` Save/Medical/Statistics TVFs · `e39e50190` Risk TVF + `PR_CalendarDateDifference` (parity 44 runs, 0 mismatches vs a verbatim C# oracle `parity\risk-oracle\`) · `e1bb418c0` layouts `0428_PR_HrReportsLayout.sql` (6 of 8; seeded on UNP-Ali)
- erp `9b194b9ace` Save/Medical/Statistics endpoints · `ace4de9f85` Risk endpoint (`odata/RiskAnalysis`, keys employeeids, riskDate; ModuleId 343)
- front `27377e4458` Save/Medical/Statistics screens on report-grid (Statistics: report-grid-multi-request; old Payroll-API grid + its components removed; insurance-report route ModuleId 521; `HRODATAREPORTS` i18n block)
Running: Risk TVF Q3 fix (D6) + re-parity; Risk front (P4b); Risk layout (P5b, appends to 0428); `npm install` in the set's Front (engineer OK'd).
Next: Front build gate (`front-verify-build`), AnalyticsReader full build, in-app check P6 (ar + en) on UNP-Ali with AnalyticsReader on +400, Medical parity on a tenant with data (Q1), then propose `/review-code 125299`.

## State (2026-10-15, implementation complete)
All phases P1–P5 done and committed locally, nothing pushed, trees clean:
- db: `aa2675266` `e39e50190` `e1bb418c0` `86e79e7ea` `dd9df5834` (D6 per-employee salary)
- erp: `9b194b9ace` `ace4de9f85`
- front: `27377e4458` `e9f6dccaab`
Gates: DB dacpac ✅ (amd64 MSBuild), AnalyticsReader `dotnet build` ✅ 0 errors (wwwroot bundles restored), Front `npm run testing` ✅ EXIT 0, 0 TS/NG errors (log `%TEMP%\front-build-cr125299-20261015103336.log`). Layouts: 8 rows seeded on UNP-Ali.
Parity: Save ✅, Statistics ✅, Risk ✅ (legacy 44/44 and D6-fixed 44/44), Medical 0 = 0 only (Q1 open).
Open: Q1 (Medical tenant), Q4 (Risk Vacations tie emulation — recommend simplify, decide in review).
Next: `/review-code 125299` (engineer's trigger); P6 in-app check (ar + en) — port 4200 is held by another node process (pid 34636, another set's ng serve), needs the engineer's OK to stop it (one-hot-set rule).

## In-app check (2026-10-15)
Done on UNP-Ali, ar + en: [[in-app-check]]. All four screens work without the iframe; numbers match parity in the app; Arabic and English prints render from the seeded 0428 layouts. Finding F1 = pre-existing shared report-grid `customizeText` bug (dates/decimals in the grid only; prints fine) → separate work item. Processes stopped, config restored, trees clean.
Next: `/review-code 125299` (engineer chose "in-app check, then review").

## Review (2026-10-15)
- Round 1: [[review-1]] — 0 block, 5 should, 13 nit (reviewer + backend + sql + AP; Fable 5.1 reviewers, Opus 5.5 implementer). Applied: DB `bb558984c` (D8 plain half-to-even Vacations, Salary DECIMAL(19,4), D9 empty-ids headers), ERP `9b19622f57` (`HrReportEmployeeIds`: empty → NULL, unparsable → empty list), Front `1b3ea4f3a0` (label back to COMMON._Date_, dead service restored). Gates green (dacpac, AnalyticsReader 0 errors, npm run testing EXIT 0). Risk parity after D8: only the 10 expected ties differ by 0.01.
- Medical real-data parity: ERP_MainDB-Ali (2 active delivered rows) PASS via `parity\parity_Medical_inline.sql` (no DDL). Undelivered card still unexercised (no tenant has one) — Q1 remainder, engineer-optional.
- Round 2: [[review-2]] — **pass**, 0 block, 0 should; row 5 done in-app (Save + Medical prints). Excel/PDF export left for QA.
- remove-redundant done (2026-10-15): ERP `e66fd52da8` (unused `using` in EmployeeSaveRptAng.cs), Front `7be351fb0e` (EmployeeStatistics.model.ts + barrel export, orphaned by the CR's deletion of the old data service). DB: nothing to remove. Gates after cleanup: AnalyticsReader 0 errors, `npm run testing` EXIT 0. Noticed, not touched (pre-existing dead code on Master_Stable): employee-save-report-form `subs`/`ngOnInit`/`getAllEmployeeIds`/`showLoading`/`handleError`; insurance-report-form `showLoading`/`hideLoading`/`handleError`; old i18n keys `STATISTICS._VacationRequests_`, `_TotalVacationBalance_`, `EMPLOYEE._PurchaseCount_`, `_BounsCount_` (kept: may be resolved dynamically).
- Local commits ahead of origin/cr125299: db 6, erp 4, front 4. Nothing pushed.
- Video: captions-only explainer `video\demo_125299_hr-odata-reports_captions.mp4` (voice dropped on the engineer's word), attached to ADO 125299.

## Shipped (2026-10-15, engineer: "ship it")
- Pushed `origin/cr125299`: db `bb558984c`, erp `e66fd52da8`, front `7be351fb0e` (0 behind Master_Stable, no merge needed).
- Merge Desk #12498 → **Solved**; ADO 125299 → **Solved** (rev 15, comment with PR links).
- Stage_Beta PRs (Merge Desk, MergeLocal): Database [!67251](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Database/pullrequest/67251) **conflicts** (edit/edit in `AccFlex_Cloud_Database_State.sqlproj` only); API [!67252](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_ERP/pullrequest/67252) open; WebContainer [!67253](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Front/pullrequest/67253) open. Master_Stable PRs (MergeLive) not opened yet by Merge Desk.
- No API client regen: AnalyticsReader has no NSwag client.
- Waiting on: the engineer's call on the DB stage conflict (fix branch `cr125299_Stage_Beta` off origin/Stage_Beta, only on request); stage deploy only on request; set removal on request (`remove-cr.ps1 -Id 125299`). Side session "Fix report-grid customizeText overriding formats" (F1) waits on the engineer's work item id.

## How to continue
```
Continue CR 125299 (MVC → OData, 4 HR reports) with mvc-to-odata-report-migration.
Read C:\Hadaf_Valut\Oct\OData Reports\CR-125299\HANDOFF.md and the Plan.
If the plan is approved: P0 (Merge Desk ticket + new-cr.ps1), then P1a/b/c in parallel.
```

## Session log
- 2026-10-14 — Legacy dissection of all 4 reports, decisions D1–D5, UNP-Ali data check, plan written.
