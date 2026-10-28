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

## Iteration 1 (2026-10-21): PO Check comment 10010651
- **Source:** Sabreen, 2026-10-20. All four reports match the old print, but she raised two things:
  - The period balance has no totals.
  - The account lookup on the budget-period screen is ignored.
- **Merge Desk:** #12511 is Solved, and the stage PRs are merged. That puts this on the Iterate path: same branch, no status move.
- **Plan:** [[change-note-1]], decisions D4–D6, all engineer-approved.
- **Changes, Front only and uncommitted:**
  - report-grid `totalSummaryOptions`, copied byte-identical from cr125395 `85f9fe329e`.
  - The period-balance total row: Debit, Credit, DebitLocal, CreditLocal.
  - The account lookup is removed from the shared budget form. The by-month shell was cleaned up as well, approved in Q1.
- **Build gate:** `npm run testing` OOMs on this machine (Windows errno 1455). Another session's dev server holds memory, so esbuild crashes while building source maps. The gate was rerun as `ng build --source-map=false` with a 6 GB heap: **EXIT 0**, no TS or NG errors, bundle built in 146 s.
- **Browser check, 2026-10-21: PASS.**
  - **Setup:** the dist build was served on localhost:4200 against Beta, company Sabreen. Beta identity allows only the origin `http://localhost:4200`.
  - **Data loading:** the grid loads every row in a single OData request (`$count=true`, no `$top`), so the total covers all rows, not one page.
  - **Branch:** the PO's "branch 1101" is branch **Id 7**, «البلاستيك محاسبي».
  - **Branch 7, Oct-2025 (subPeriodId=1):** the total row shows DebitLocal **7,329,380.05**, CreditLocal 0, on 4 rows. This equals the old print.
  - **All branches:** 209 rows, Debit/DebitLocal 15,021,441.51, Credit/CreditLocal 4,003,333.58. This equals the sum of the OData response.
  - **Budget-period screen:** no account lookup. Preview returns 5118 with 20,305.93 / 25,000 / -4,694.07 / -18.78%, which equals the PO's check.
  - **Clean-up:** config.json restored, server stopped, launch entry removed.
- **Review round 3, 2026-10-21: PASS.** Result in [[review-3]]: 0 block, 0 should, 3 nits (one of them pre-existing). The engineer had both optional nits applied: the orphan `BrancheList$` field is removed, and the total row uses `#,##0.00`. After that, the rebuild with `--source-map=false` gave EXIT 0 with 0 errors. Prettier is clean, and the diff is now 10 files, 34+/78-. 
- **remove-redundant:** nothing to remove. Noticed but not touched: the pre-existing unused `isUpdateChileCostCentertList` and `isUpdateJournalTypeList`.
- **Committed and pushed 2026-10-21:** Front `89b515b024` "[cr125288] fix: PO check - period balance totals, drop ignored account lookup", with no co-author line.
  - The pretty-quick hook ran, and the report-grid hunks are still identical to cr125395.
  - `origin/cr125288` Front is now `89b515b024`. DB and API are unchanged (`99e8381fa` / `16c17e8555`).
- **The push does NOT reach Beta.**
  - All three Stage_Beta PRs (!67281, !67282, !67283) are already **Merged**, and Merge Desk shows `stagePrsMerged: true`.
  - No Master_Stable (MergeLive) PRs are open yet. When Merge Desk opens them from cr125288, they will carry this commit.
- **Getting it to Beta for the PO retest needs a new Front PR into Stage_Beta.**
  - A dry-run merge of cr125288 into origin/Stage_Beta conflicts in `report-grid.component.ts` imports: Stage_Beta adds the `DetailTabOptions` import block next to the line both sides changed. The resolution is to keep Stage_Beta's block.
  - Per the rule, that is done on a `cr125288_Stage_Beta` branch cut from Stage_Beta, with cr125288 merged into it and the PR opened from it, **only when the engineer asks**.
  - **Engineer's decision, 2026-10-21:** leave it. The engineer handles Beta personally, and Merge Desk's Master_Stable PR will carry `89b515b024`. The agent opens no Stage_Beta PR or branch.
- **2026-10-21 10:09:** the engineer's account (Merge Desk) re-solved the ticket. Merge Desk opened **new Stage_Beta PRs**:
  - DB [!67988](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Database/pullrequest/67988): Open.
  - API [!67989](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_ERP/pullrequest/67989): Open.
  - Front [!67990](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Front/pullrequest/67990): **Conflicts**. This is the predicted `report-grid.component.ts` import conflict; the resolution is to keep Stage_Beta's `DetailTabOptions` block.
- **ADO:** that run left the state at In Development. The agent moved it to **Solved** at the engineer's request (rev 33; column Resolved, lane BETA).
- **Front !67990 conflict:** the engineer resolves it personally (decision 2026-10-21). The agent does not touch it.
- **Iteration 1 closed.** The work now waits on the engineer's Beta deploy and the PO retest, then on Merge Desk's MergeLive PRs.
- **Next:** then `/review-code 125288` (one round), then push. The push updates the open PRs, with no Merge Desk move.

## Next step
1. ~~P6 app check~~ done. ~~Grid PDF fix + R1 branch-filter truncation~~ done and verified on unp-ali (see [[p6-app-check]] "Fixes applied after P6"); ELGHONEIM_Primary still has the first 0430 version.
2. ~~Commit~~ done (not pushed).
3. ~~Review~~ pass (2 rounds). Pushed. Next, when the engineer asks: release-ticket. There is no Merge Desk ticket for 125288 yet, so create one (Change Request, Beta) before the Solved move, which opens the Stage_Beta and Master_Stable PRs. Never merge Stage_Beta into cr125288.
4. Release: there is no Merge Desk ticket yet. Create it, or let Merge Desk create it, before the Solved move.

## 2026-10-25 iterate 2 — period balance totals (Muhammed Tariq, ADO comment 10021303)
- [[change-note-2]]: total row on DebitLocal/CreditLocal only; Grouping on AccountNo (AutoExpand) + groupSummaryOptions on the same two columns, like the old print's per-account «الاجمالى» and report footer.
- Front gate: `npm run testing` EXIT 0, Prettier clean. Not checked in the running app.
- Pushed Front cr125288 89b515b024..d7eea2dffd. Review skipped on the engineer's explicit "fix and ship".
- Merge Desk's Front PR !67990 was already merged, so opened Front PR !68387 cr125288 → Stage_Beta (1 commit, 2 files, merges clean) on the engineer's ask. ADO → Solved; reply to Muhammed.
- Next: PR !68387 merges + Web Container Stage Beta deploy; QA retest.
