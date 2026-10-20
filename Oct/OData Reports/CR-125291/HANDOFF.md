---
ticket: 125291
kind: CR
branch: cr125291
set: D:\Hadaf\worktrees\cr125291
updated: 2026-10-15
---

# CR-125291 — HANDOFF

## Where we are
| Step | State |
|---|---|
| Merge Desk ticket 12513 (Beta, Acknowledge; components Database, AnalyticsReader, Web Container) | done |
| Set `worktrees\cr125291` (db, erp, front), offset 600, front `npm install` | done |
| Intake ([[facts]]), legacy dissection (3 notes) | done |
| Decisions ([[decisions]]) D1–D7, plan ([[CR-125291 - Plan]]) | **AGREED at the plan gate 2026-10-17** (all recommended options) |
| P1 DB TVFs / P2 backend / P3 front / P4 layouts (seed 0437) | done, builds green, uncommitted |
| P5 parity ([[parity-125291]]) | PASS, 75 sets, 0 divergence |
| Q2 decimals (tenant ApproximateNo) | done |
| P6 app check ([[p6-app-check]]) | done 2026-10-17 on ELGHONEIM: all 5 match legacy (en+ar); branch-caption defect fixed |
| Commit + ship | committed 2026-10-18; merged origin/Master_Stable (sqlproj conflict: kept 0411 + 0437), gates green; **pushed** db 0046d7491, erp e83932dd3b, front 5db5f2ba61; Merge Desk **Solved**; ADO **Solved** + PR comment |
| Stage_Beta PRs | DB [!67418](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Database/pullrequest/67418), API [!67419](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_ERP/pullrequest/67419), Web [!67420](https://dev.azure.com/hadafsolutions/AccFlex_ERP/_git/AccFlex_Cloud_Front/pullrequest/67420) — **all merged** (conflicts resolved by someone else before a replacement was needed). Master_Stable PRs: Merge Desk opens them after stage. |

## Next step
Review done ([[review-1]], [[review-2]]: pass) → committed → optional `remove-redundant` → push when told → `release-ticket` (push, Merge Desk Solved → Stage_Beta + Master_Stable PRs).
Merge overlaps to resolve later: DataContext.cs / GLODataController.cs with cr125290; one-date-form with fx123513.
- 2026-10-17 P2 backend done (build 0 errors), uncommitted.
- 2026-10-17 P3 front done (npm run testing exit 0, prettier clean), uncommitted.
- 2026-10-17 P1 DB TVFs done (MSBuild 0 errors), uncommitted. P4 + P5 started.
- 2026-10-17 P5 parity PASS (75 sets, 5 tenants, 0 divergence).
- 2026-10-17 P4 layouts done (seed 0437, 10 InsertLayout, MSBuild 0 errors). Phase loop stopped at P6 (Q1).
- 2026-10-17 Q2 done (layouts follow tenant ApproximateNo; builds green). Q1: engineer chose ELGHONEIM_Primary for P6 before/after. Assembling the targeted deploy script was refused by the auto-mode permission check; waiting for the engineer to allow it or run the deploy.
- 2026-10-17 P6 done: before/after on ELGHONEIM, all 5 MATCH; fix in FinancialStatementReportOptions.BranchFilter. Local run torn down (config.json and wwwroot restored). TVFs + layouts 566–575 stay on ELGHONEIM.
- 2026-10-18 Review: round 1 (Fable reviewer + backend/sql/AP) block 0 / should 6 / nit 13; implementer (Opus) applied rows 1,2,7,8,13,15,17, disagreed on the rest with reasons; round 2 pass (0 open). Gates green: sqlproj, AnalyticsReader, npm run testing + prettier, parity 15/15 on ELGHONEIM + Nakhil_Primary. Note: the TVFs deployed on ELGHONEIM are the pre-review versions (Compare lacks DescriptionArabic) — redeploy before any further app check there. Uncommitted.
- 2026-10-18 Committed one commit per repo ([cr125291] feat: mvc to odata in financial statements reports; no Co-Authored-By): db e561dbf82, erp c7e9c35fff, front 6299f68a86. Working trees clean. Not pushed.
- 2026-10-18 Shipped: merge Master_Stable, gates green, push, Merge Desk Solved, ADO Solved. Stage_Beta PRs !67418 (DB) and !67419 (API) have conflicts (sibling CRs on Stage_Beta touch the sqlproj / DataContext / GLODataController) — resolve via a cr125291_Stage_Beta branch only when the engineer asks. Next: explainer video → attach to WI 125291.
- 2026-10-18 Explainer video recorded on ELGHONEIM (86 s, Gemini Iapetus voice + Arabic captions): vault demo_125291_financial-statements-odata_gemini-Iapetus.mp4; attached to WI 125291. Local run stopped; config.json/wwwroot restored. ELGHONEIM has the reviewed TVF versions.
- 2026-10-18 Stage_Beta: all 3 PRs merged (Merge Desk stagePrsMerged=true); no cr125291_Stage_Beta branch pushed. Verified: cr125291 got no foreign commits (Conflicts tab not used on it); Stage_Beta holds the 5 TVFs + 0437, 5 DbSets, 5 routes, no conflict markers; Stage_Beta sqlproj MSBuild and AnalyticsReader build 0 errors. Waiting on: stage deployment (Ready for test) → Master_Stable PRs by Merge Desk.
