---
type: handoff
cr: 125288
updated: 2026-10-15
status: SHIPPED 2026-10-15 - Merge Desk #12511 Solved, ADO Solved; Stage_Beta PRs !67281 / !67282 / !67283 all mergeable (conflicts resolved in the PRs by the engineer), auto-complete on
---

# HANDOFF — CR-125288: Period Balance + Estimated Budget reports to OData

## Where we are (2026-10-15)

| Step | State |
|---|---|
| Intake | ADO 125288: Change Request, General Accounting, In Development, assigned to Mohamed Saeed. **No Merge Desk ticket yet.** `cr125288` was cut locally by `new-cr.ps1` and is not pushed. |
| Size | **L** |
| Legacy dissection | done: [[Legacy - Period Balance]], [[Legacy - Estimated Budget (A-B-C)]] |
| Set | `D:\Hadaf\worktrees\cr125288` (db, erp, front), offset **300**. Front `node_modules` installed (P3). |
| Plan / decisions | [[CR-125288 - Plan]], [[decisions]] (D1 full grid, D2 exact port, D3 previous-design print) |
| P1 TVFs | **done**, uncommitted. 4 inline TVFs plus sqlproj `<Build Include>`. VS 2022 Community MSBuild: 0 errors, all 4 in model.xml. Day report uses a digits tally; month report keeps the recursive CTE. |
| P2 backend | **done**, uncommitted. 4 entities, 2 config files, 4 DbSets, 4 `*ReportAng`, `AdvancedReportOptions` helper, `GetCostCentersName` in DataContext, 4 `GLODataController` actions (361/362). `dotnet build` 0 errors. |
| P3 front | **done**, uncommitted. 4 shells with a full report-grid (`BUDGETBALANCEREPORTS` keys en/ar); forms' Print relabelled "Print (previous design)". `npm run testing` EXIT 0 after `npm install`. |
| P4 layouts | **done**, uncommitted. `0430_GL_PeriodBalanceAndEstimatedBudgetReportsLayout.sql`: 8 InsertLayout calls, registered `<None>`, sqlproj build green. Not yet rendered. |
| P5 parity | **PASS** on 2026-10-15: 50 comparisons on 6 tenants, 0 divergence, 4 negative controls detected. See [[parity-125288]]. |
| Commit | **done 2026-10-15** (engineer: "commit, don't push"). One commit per repo, no co-author line: DB `99e8381fa`, Cloud_ERP `16c17e8555`, Front `05940137c8` + review fix `546b0f5165`. **Pushed 2026-10-15** (engineer: "push, no PRs, no Merge Desk move"): `origin/cr125288` = DB `99e8381fa`, Cloud_ERP `16c17e8555`, Front `546b0f5165`. |
| Review | **pass** 2026-10-15. Round 1 ([[review-1]]): Fable reviewer + backend/sql reviewers + front anti-patterns found 0 block, 4 should, 11 nit. The 4 should rows were in the Front shells (branch source, Clear defaults, from>to on grid preview) and were applied by the Opus implementer in Front `546b0f5165` (not pushed). Round 2 ([[review-2]]): all 4 rows verified, 0 block. Rule bends are recorded in [[decisions]]. |
| Merge Desk | **#12511** created 2026-10-15 (Beta; components Database, AnalyticsReader, Web Container; repos Database/API/WebContainer); the existing origin/cr125288 heads were kept. Moved Acknowledge → **Solved**, which opened the Stage_Beta (MergeLocal) PRs: DB [!67281](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Database/pullrequest/67281) **conflicts** in `AccFlex_Cloud_Database_State.sqlproj`; API [!67282](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_ERP/pullrequest/67282) **conflicts** in `ODataControllers/GLODataController.cs`; Front [!67283](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Front/pullrequest/67283) open, clean. **Conflicts resolved by the engineer in the PRs (2026-10-15)**: ADO mergeStatus succeeded on all 3, and cr125288 / Stage_Beta are unchanged. Verified from the PR merge refs: DB merge `cbf5235d4` keeps Stage_Beta's 10 seed lines plus 0430; API merge `74260df991` has 20 routes (Stage_Beta's 16 plus our 4), both enums and all usings, with no markers. The agent's local `cr125288_Stage_Beta` attempt was aborted and removed, never pushed. The Master_Stable (MergeLive) PRs are not listed yet. **Never merge Stage_Beta into cr125288.** |
| ADO state | **Solved** 2026-10-15 (engineer: "move it to solved"): rev 9, board column Resolved, lane BETA. Merge Desk has not been touched: there is no ticket for 125288, so no PRs are open yet. |
| Demo video | **done 2026-10-15**: `demo_125288_period-balance-budget-odata_captions.mp4` in this folder, captions only with no sound, 94 s, 11 segments recorded on unp-ali via localhost (Playwright profile already signed in). The by-month and by-day screens show 'no data' because unp-ali has no budgets. Steps and plan are in the session scratchpad `demo-125288`. **Attached to ADO 125288** (rev 8, AttachedFile, REST via the az token). |
| P6 app check | **done 2026-10-15 on unp-ali** (engineer's choice). Targeted deploy: 4 TVFs plus 0430, layout ids 2800–2807; the same deploy went to ELGHONEIM_Primary for smoke checks. The 4 screens and the grid preview work (R1 209 rows and R2 1,336 rows, equal to SQL). All 16 PDF/XLS renders return 200. R1 grand totals equal SQL. The grid PDF-export 404 (`report-grid.component.ts:871` double slash) and the R1 branch-filter truncation were fixed afterwards and re-verified. See [[p6-app-check]]. Servers stopped; config.json restored. |

### Open points for the engineer (from P3/P4)
- Clear resets the form, but the cost-center lookup and branch tree keep showing their old selection. Other GA shells behave the same way.
- Grid preview has no from > to date check. The legacy forms check it only on the old Print button.
- DeviationPercent uses grid format `#0.##'%'`; the print uses `{0:N2}%`.
- The layouts have no tax numbers in the header, because the backend does not supply them.
- Arabic name cells are `MiddleLeft` with RightToLeft, as in 0402/0414. Confirm this in the P6 preview.
- Data gaps that parity could not prove:
  - The R4 PeriodBalance is 0 everywhere.
  - No NULL-branch rows exist.

## Ticket facts
- A CR, so the first PR goes to `Stage_Beta` and the second to `Master_Stable`. **Never merge `Stage_Beta` into `cr125288`.**
- AccFlex_ERP is read-only (the legacy MVC source).
- Precedents:
  - fx123513, Balance Sheet: print-only.
  - CR-125292, salary reports: full grid. This CR follows CR-125292.

## Parity tenants (db-all, counted 2026-10-15)

| Report | Tenant(s) | Data |
|---|---|---|
| R3 by month | **Rusasnew** | 816 monthly budget rows |
| R3 by month | dbriyadh_Primary | 12 monthly budget rows |
| R2 period | **ELGHONEIM_Primary** | 2 weekly budget rows (`IsFixedWeekly`) |
| R2 period | ACCFLEX-ERP | 1 weekly budget row |
| R4 by day | **ERP_MainDB-Ali** | the only `IsFixedDaily` row on the server |
| R1 period balance | ELGHONEIM_Primary | 61k `Acc_AccountBalance` rows |
| R1 period balance | ABN-NN_Primary | 25k `Acc_AccountBalance` rows |
| R1 period balance | dbriyadh_Primary | 6k `Acc_AccountBalance` rows |

## Next step
1. ~~P6 app check~~ done. ~~Grid PDF fix + R1 branch-filter truncation~~ done and verified on unp-ali (see [[p6-app-check]] "Fixes applied after P6"); ELGHONEIM_Primary still has the first 0430 version.
2. ~~Commit~~ done (not pushed).
3. ~~Review~~ pass (2 rounds). Pushed. Next, when the engineer asks: release-ticket. There is no Merge Desk ticket for 125288 yet, so create one (Change Request, Beta) before the Solved move, which opens the Stage_Beta and Master_Stable PRs. Never merge Stage_Beta into cr125288.
4. Release: there is no Merge Desk ticket yet. Create it, or let Merge Desk create it, before the Solved move.
