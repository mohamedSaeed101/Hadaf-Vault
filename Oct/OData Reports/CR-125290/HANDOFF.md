---
ticket: 125290
kind: CR
branch: cr125290
set: D:\Hadaf\worktrees\cr125290
updated: 2026-10-17
---

# CR-125290 — HANDOFF

## Where we are
| Step | State |
|---|---|
| Intake ([[facts]]), legacy dissection ([[Legacy - Income Statement family (1-5)]]) | done |
| Decisions ([[decisions]]) D1–D4, plan ([[CR-125290 - Plan]]) | done |
| P1 DB: 5 TVFs + sqlproj | done; MSBuild 0 errors (rebuilt after the DimensionName cast was dropped) |
| P2 API: 5 entities, configs, DbSets, `*Ang`, GLODataController actions (267 / 72) | done; `dotnet build` 0 errors |
| P3 Front: report-grid in 5 shells, "Print (previous design)", i18n `INCOMESTATEMENTBUDGETREPORTS` | done; `npm run testing` exit 0, prettier clean |
| P4 Layouts: `0436_GL_IncomeStatementBudgetReportsLayout.sql` (renamed from 0432 in review 1: 0430-0435 taken on other origin branches), 10 InsertLayout | done; generator in `layout-generator\` |
| P5 Parity ([[parity-125290]]) | PASS: 55 parameter sets, 3 tenants, 0 divergence |
| P6 App check ([[p6-app-check]]) | done 2026-10-16 on UNP-Ali: 20/20 PDF/XLS renders 200; legacy Net Profit = TVF; journal-type header fixed |
| Review | pass: [[review-1]] (1 block, 7 should, 15 nit) applied; [[review-2]] pass (0 open). Reviewed by Fable 5.1, applied by Opus 5.5 |
| Clean (remove-redundant) | done 2026-10-16: seed 0436 header reworded (CR narration removed), unused i18n key `INCOMESTATEMENTBUDGETREPORTS.DimensionName` removed (en/ar); DB MSBuild 0 errors, front `npm run testing` exit 0 |
| Before/after data re-run ([[before-after-125290]]) | 158/158 PASS on 3 tenants, 7/7 negatives detected |
| Demo video | `demo_125290_income-statement-budget-odata_gemini-Iapetus.mp4` (2:13, UNP-Ali, captions + Hanafi voice; legacy-print segment dropped: iframe blank in headless recording) |
| Commit | done 2026-10-17: DB `1c5c31f0b`, ERP `83c3af4f1c`, Front `c7d161dd30` — "cr125290: income statement budget and per-month reports on OData" |
| Release (2026-10-17) | Merge Desk ticket #12516 created (Beta, components Database / AnalyticsReader / Web Container) → merged origin/Master_Stable (DB sqlproj conflict resolved: kept 0436 + Master's 0411) → gates green → pushed DB `df4dfce48`, ERP `8881034b7e`, Front `963ad81f10` → Merge Desk **Solved**, ADO **Solved** + PR comment |
| Stage_Beta PRs | DB [!67383](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Database/pullrequest/67383) **Conflicts — the engineer resolves it** (agent's !67386 / cr125290_Stage_Beta abandoned and deleted 2026-10-17); API [!67384](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_ERP/pullrequest/67384) open; Web [!67385](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Front/pullrequest/67385) open |

## Open points
- **NetProfit for R1/R2 (open question 8): settled.** The legacy print on UNP-Ali (SP 22) gives the same Net Profit as the TVF (−11,310.31), so the cancelled type 1/2 rows are included.
- **Pivot column grand-total header** prints "Grand Total" in the Arabic layouts too. Changing it needs a report script, and no 24.x seed uses scripts.
- **No real data for the cost-center budget paths.** No tenant has type 1/2 budgets with a cost center, so R3 Dimension and the R1 cost-center budget were checked on synthetic #temp rows only.
- **Merge overlap.** `DataContext.GetCostCentersName` is also added by cr125288. Whichever branch merges second must drop its copy.
- **Language deviations taken on purpose (D2).** R2's total caption reads "Total Branch GOP"; R4 is no longer Ar/En swapped.
- **Set setup.** `node_modules` in the front worktree is a junction to cr125288's; `build-info.ts` was generated. Both are gitignored.

## Iteration 1 (2026-10-21): totals in grids R3/R4/R5
The tester's comment 10010794 sent the ticket back: no totals in the R3/R4/R5 grids. [[change-note-1]] holds the details. Front only: default grouping plus group sums, and `ColumnIndex.GroupSortField` in the shared report-grid. Build green, app-checked on Sabreen. Review round 3 done ([[review-3]]): the block (remote paging) is fixed with `pagingEnabled=false`, and the shoulds are applied. Committed 2026-10-21 as Front `1246f0796c` on cr125290 and **pushed** (`963ad81f10..1246f0796c`). Merge Desk: still Solved, the 3 Stage_Beta PRs are Merged, no MergeLive PR yet. Stage_Beta does not have the fix. A new Front PR cr125290 → Stage_Beta would carry exactly the 9 files and merges cleanly (merge-tree check 2026-10-21). The engineer handles the Stage_Beta route (decided 2026-10-21): the agent opens no PR. ADO moved In Development → **Solved** on 2026-10-21 (rev 27; Merge Desk was already Solved). ADO reply to the tester posted 2026-10-21 (comment 10011663: totals, the Sabreen no-data cause, the R1 "%" quirk). Open: the engineer's Stage_Beta route for the front commit. Next: push, and the engineer decides the route to Stage_Beta (the old Stage_Beta PRs are already merged). The ADO reply draft still needs the engineer's OK. Stage_Beta PRs were already merged, so pushing this needs new PRs or the Merge Desk flow (ask the engineer).

## Next step
The engineer resolves the DB Stage_Beta conflict on !67383. No client regen needed (AnalyticsReader has no API client). Then stage deploy via `release-env` when asked; production goes through Merge Desk.
