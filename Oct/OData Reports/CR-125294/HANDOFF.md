---
type: handoff
cr: 125294
updated: 2026-10-14
status: implemented, reviewed (pass), pushed to origin/cr125294; number check pass on UNP-Ali (advance only); in-app check pending
---

# HANDOFF — CR-125294: Advance & purchase payroll reports → OData

Full history of what was done: [[CR-125294 - Work Log]].

> [!important] Resume here
> **Pushed**: `origin/cr125294` = db `a2a2ac3aa`, erp `277ebf7d56`, front `1ef801747b` (checked 2026-10-14). The worktree set `D:\Hadaf\worktrees\cr125294` exists only on the original machine; on `C:\Hadaf_Work` there is no set. Cut one from `origin/cr125294` before any further code change.

## Where we are (2026-10-14)

| Step (onboard-ticket spine) | State |
|---|---|
| 0 Preflight + Merge Desk ticket | **done**: Merge Desk #12458, Beta, Acknowledge, owner Mohamed Saeed, repos Database / API / WebContainer, contract change off, components empty (Merge Desk detects) |
| 1 Intake | done: [[CR-125294 - Source]] |
| 1b Size | **L** (3 reports × DB + AnalyticsReader + Front) |
| 2 Set | done: `worktrees\cr125294` (db, erp, front), port offset 100 |
| 3 Grill / decisions | done: [[decisions]] D1–D7, no open questions ([[open-questions]]) |
| Legacy dissection | done: [[CR-125294 - Legacy Analysis]] |
| 7 Implement | **done**, uncommitted; design: [[CR-125294 - OData Reports]] |
| Print layouts (D5) | **done**: `0413_PR_AdvanceAndPurchaseReportsLayout.sql`, 6 `InsertLayout` calls (3 reports × ar + en), registered in the `.sqlproj` |
| Gates | DB build ✅, AnalyticsReader build ✅ (re-run on the new base 2026-10-14, 0 errors), Angular build ✅ for payroll (see Gate notes) |
| Number check (acceptance gate) | **pass (partial)** 2026-10-14 on **UNP-Ali / db-all**: [[parity-results]]. Advance + repayments match (9 = 9, 132,436.23). Unpaid and Purchase have no data there, so they are untested |
| In-app check (ar + en) | **partial** 2026-10-14 on UNP-Ali: [[in-app-check]]. Override proven; Advance grid + detail OK (Arabic). F1 (repayments tab title) **fixed** in front `8c1accad0e`, not pushed. Print, English, export, purchase still open |
| 8 Review | **pass** (2026-10-14): [[review-1]] (0 block, 1 should, 6 nit — rows 1–2 applied, 3–7 kept as sibling style) → [[review-2]] pass. Reviewers ran on Opus 5.5 (Fable 5.1 out of credits); code written by Sonnet 5.5 |
| 9 Clean | remove-redundant **done** (2026-10-14): 0 items — every added comment is a why-comment (deliberate legacy deviations), no debug leftovers, no unused imports, nothing orphaned (`EmployeeFromToFormComponent`, `AccflexReportShellComponent` still used by other shells). Gates green as recorded above. Nothing committed |
| 10 Ship | not started — needs the number check and the engineer's word to commit |

## Repo tips

| Repo | Local HEAD | Dirty |
|---|---|---|
| AccFlex_Cloud_Database | `a2a2ac3aa` (1 ahead of origin) | 0 |
| AccFlex_Cloud_ERP | `277ebf7d56` (1 ahead of origin) | 0 |
| AccFlex_Cloud_Front | `1ef801747b` (1 ahead of origin; pretty-quick reformatted 6 files in the commit) | 0 |

ERP was fast-forwarded 39 commits (2026-10-14): Merge Desk cut `origin/cr125294` from a newer `Master_Stable` than the set. None of those commits touch the CR's files; the uncommitted changes carried over untouched.

## Ticket facts

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125294 — Change Request, In Development (column acknowledged), assigned Mohamed Saeed, program PayRoll, parent 68514.
- Merge Desk: https://support-system.accflex.com/ ticket #12458 (tfs 125294).
- Branch `cr125294` → first PR `Stage_Beta`, second PR `Master_Stable` (Merge Desk opens both on the Solved move). Never merge `Stage_*` into it.

## What was built

| Report | Route (unchanged) | TVF(s) | OData endpoint / ReportName | ModuleId |
|---|---|---|---|---|
| رصيد سلف الموظفين — Unpaid Advance Payments | `accounting-reports/unpaid-advanced-payments` | `PR_UnpaidAdvancePaymentsReport` | `UnpaidAdvancePayments` | 549 |
| تقرير السلف — Employees Advance | `accounting-reports/advance-report` | `PR_EmployeesAdvanceReport`, `PR_EmployeesAdvanceRepaymentReport` | `EmployeesAdvance` (+`EmployeesAdvanceRepayment`) | 551 |
| المشتريات — Employee Purchase | `accounting-reports/employee-purchase` | `PR_EmployeePurchaseReport`, `PR_EmployeePurchaseRepaymentReport` | `EmployeePurchase` (+`EmployeePurchaseRepayment`) | 547 |

### Files (all under `D:\Hadaf\worktrees\cr125294`)

**AccFlex_Cloud_Database**
- `dbo\Functions\PR_UnpaidAdvancePaymentsReport.sql` (new)
- `dbo\Functions\PR_EmployeesAdvanceReport.sql`, `PR_EmployeesAdvanceRepaymentReport.sql` (new)
- `dbo\Functions\PR_EmployeePurchaseReport.sql`, `PR_EmployeePurchaseRepaymentReport.sql` (new)
- `Scripts\ReferenceDataScripts\0413_PR_AdvanceAndPurchaseReportsLayout.sql` (new; ApplicationId 4)
- `AccFlex_Cloud_Database_State.sqlproj` — 5 `<Build Include>` + 1 `<None Include>`

**AccFlex_Cloud_ERP / AnalyticsReader.Api**
- `ODataViews\Payroll\UnpaidAdvancePaymentsRpt\UnpaidAdvancePayments.cs`
- `ODataViews\Payroll\EmployeesAdvanceRpt\EmployeesAdvance.cs` (header + repayment entities)
- `ODataViews\Payroll\EmployeePurchaseRpt\EmployeePurchase.cs` (header + repayment entities)
- `ODataViewsConfigurations\Payroll\AdvanceAndPurchaseRptConfigs\AdvanceAndPurchaseRptConfigs.cs` (5 `ToFunction` configs)
- `Models\DataContext.cs` — 5 DbSets
- `ODataControllers\Payroll\PayrollOdataController.cs` — 5 actions, ModuleIds 547/549/551, `_userSession.SecurityLevel`
- `AngularReports\Payroll\AdvanceAndPurchaseReports\*RptAng.cs` — 3 print reports (header carries its repayment list)

**AccFlex_Cloud_Front / accflex-erp**
- `projects\payroll\...\accounting-reports\containers\unpaid-advanced-payments-shell\*` — `report-grid`
- `...\advance-report-shell\*`, `...\employee-deduction-shell\*` — `report-grid-multi-request`, detail filtered by `AdvanceId` / `PurchaseId` on expand
- `accounting-reports.module.ts` — `data: { ModuleId }` 547 / 549 / 551 on the three routes
- `src\assets\i18n\{en-US,ar-EG}\payroll.json` — `ADVANCEPURCHASEREPORTS` block

## Gate notes

- DB: VS 2022 **Community** MSBuild → dacpac OK.
- AnalyticsReader: `dotnet build -p:LibraryRestore=false -p:BundleMinifyEnabled=false` with `BaseOutputPath` in the scratchpad. Without those flags libman fails (no node_modules in a fresh worktree) and the bundler rewrites 5 `wwwroot` bundles; restore them with `git checkout -- …/wwwroot` after any build.
- Front: `npm run testing` with the main checkout's `node_modules` junctioned in temporarily (removed after). 4 errors, all in logistics `SalesQuotation`, from the main checkout's `logistics.api.client 1.0.3898-local.1` vs `1.0.3893` pinned on Master_Stable. Payroll compiles clean. Run `node scripts/write-build-info.cjs` first (git-ignored output). Front and DB were not rebuilt after the branch move (their tips did not change).

## What's next

1. ~~Number check~~ done on UNP-Ali (partial, see [[parity-results]]). Old note: (blocked on `ACCFLEX_DB_USER` / `ACCFLEX_DB_PASSWORD`): publish the 5 functions to **UnitedPlastic** on `support-db2` with `scripts\publish-db.ps1` (`-Script` preview first, targeted objects only), set real employee ids and dates in `parity-125294.sql`, run it. Pass = every diff result set empty. Record in `parity-results.md` here.
2. In-app check: AnalyticsReader on port +100 + front; the three screens in Arabic and English — grid, detail expand, group by employee, Excel/PDF export, print with the seeded layouts.
3. ~~`/review-code 125294`~~ done, pass.
4. remove-redundant, gates, commit (on the engineer's word), then ship via `release-ticket`.

**Number check blocker detail (2026-10-14):** the engineer chose UnitedPlastic on `web-test` (D6 revised) and added credentials to `.env.local`. `support-db2` is unreachable from this machine. The `accflex-env-pin` plugin denies every command targeting `web-test` ("web-test is retired") even after `/env unretire web-test`; the stored pin still lists it retired. Needs the engineer to fix the pin (`/env` should show web-test / UnitedPlastic, retired: none), or run `publish-db.ps1 … -Script` and `parity-125294.sql` themselves.

## How to continue

```
Resume cr125294: read D:\Hadaf\Hadaf Vault\Oct\OData Reports\CR-125294\HANDOFF.md, run /where-are-we 125294, then the number check (step 1 above).
Mode: worktree set D:\Hadaf\worktrees\cr125294. Branch cr125294 (tracks origin/cr125294).
Next: in-app check against UNP-Ali (5 TVFs already created there).
```

## Session log

- 2026-10-13 — Legacy dissection, decisions D1–D4, worktree set, DB + backend + front implemented, gates run, vault notes written.
- 2026-10-14 — Committed on the engineer's word: one commit per repo (db a2a2ac3aa, erp 277ebf7d56, front 1ef801747b), not pushed.
- 2026-10-14 — Review rounds 1–2 pass; SubSink + typed handlers applied in the three shells (uncommitted); number check blocked by env-pin on web-test.
- 2026-10-14 — D5–D7 answered; layout seed 0413 added; Merge Desk ticket #12458 created (branches cut); ERP fast-forwarded 39 commits to `origin/cr125294`, rebuilt clean; HANDOFF brought up to date.
- 2026-10-14 — (machine C:\Hadaf_Work) Confirmed the branch is pushed. Created the 5 TVFs on UNP-Ali / db-all and ran parity: pass for Advance; Unpaid and Purchase have no data there.
- 2026-10-14 — (C:\Hadaf_Work) Set `C:\Hadaf_Work\worktrees\cr125294` cut (erp + front, offset 200; ERP needed `core.longpaths=true`; NuGet restore with `--ignore-failed-sources`, internal feed 401). 0413 layouts seeded on UNP-Ali (6 rows). AnalyticsReader Debug on https://localhost:7485 → UNP-Ali via DebugTenantConnection, Authority localbeta; `\` lists all 5 entity sets, anonymous call 401. Front: main `node_modules` junctioned, local `config.json` analyticsreaderapi → 7485 (must be restored). Screens waiting on: port 4200 (cr103744 ng serve, engineer's) and ACCFLEX_APP_USER / ACCFLEX_APP_PASSWORD in .env.local.
- 2026-10-14 — In-app check on UNP-Ali (Arabic): front on 4200 with per-package node_modules links (logistics client pinned 1.0.3893). Advance grid/detail OK, F1 found, print not verified. API (7485) and front (4200) left running.
- 2026-10-14 — F1 fixed: advance + purchase shells pass the raw key via customTransalatePropertyList; verified in the app; build gate exit 0. Front commit `8c1accad0e` (local; origin/cr125294 is 1 behind).
- 2026-10-14 — In-app check (headless Chrome, .env.local user): print ar+en pass (7 pages, seeded layouts), PDF/XLSX export ar+en pass (XLSX total 132,436.23), English pass. Open: unpaid + purchase need a tenant with data.
- 2026-10-14 — F1 pushed: front origin/cr125294 = `8c1accad0e`. Tagged test data added to UNP-Ali (`testdata-125294-UNP-Ali.sql`, delete block inside). Parity with data: pass on all 3 reports. In-app: Unpaid + Purchase pass (grid, print, XLSX; ar + en). Unpaid PDF export 404 = F2, a pre-existing shared report-grid bug, not this CR.
- 2026-10-14 — F2 fixed on cr125294 (engineer's request): shared report-grid PDF URL; front `f58eff4e44`, local, 1 ahead of origin. Unpaid PDF export now passes ar + en; build exit 0.
- 2026-10-14 — Test data added to UNP-Ali (2 paid advances, 2 purchases): parity re-run passes on all 3 reports (2=2, 11=11 / 139,436.23, 2=2 / 4,900), see [[parity-results]]. Before/after video recorded: [[CR-125294-before-after.mp4]] (legacy on Stage Stable vs cr125294 local). Print verified in Arabic. Legacy bug noted: no employee / Select all → employeesIds=null → SQL conversion error.
- 2026-10-14 — Developer explanation written: [[explain-odata-reports]] (call chain, invariants, per-layer changes, KG terms, open points; flags the shared report-grid PDF-URL change for the PR).
- 2026-10-14 — Narrated before/after video (Egyptian-Arabic voice, Gemini Iapetus; ar + en captions): [[demo_125294_before-after_hanafi.mp4]] (2:35), script [[demo_125294_narration.txt]].
- 2026-10-14 — Narrated video updated (2:53, 13 segments): the after-print now shown for all three reports (Unpaid, Advance, Purchase).
- 2026-10-14 — **Shipped (release-ticket).** Merged origin/Master_Stable into the set (ERP 4c832b4a9d, Front 8f3c448bb4; front logistics client pin 1.0.3900); gates green (AnalyticsReader build 0 errors, front npm run testing exit 0); manual secret scan of the front ticket commits clean (front repo has no core.hooksPath). Pushed. Merge Desk #12458 → **Solved**, components Database + AnalyticsReader + Web Container. ADO 125294 → **Solved** with PR comment; demo video attached. Stage_Beta PRs: DB !67196 (open), API !67197 (**conflicts**), WebContainer !67198 (**conflicts**). Conflicts are in files outside the ticket (Logistics resx/client/sln, Payroll EmployeeErrors.cs, front package.json), from Master_Stable vs Stage_Beta drift; ERP Logistics.sln conflicted even before the sync. Waiting on: engineer's call on a cr125294_Stage_Beta resolution branch.
- 2026-10-14 — **Release finished.** Layout scripts split per report, each ar-EG + en-US: `0413_PR_UnpaidAdvancePaymentsReportLayout.sql`, `0414_PR_EmployeesAdvanceReportLayout.sql`, `0415_PR_EmployeePurchaseReportLayout.sql` (DB `f7e7418cc`; local DB build blocked by a broken 4tecture task install on this machine, so the PR validation build is the gate). Stage conflicts resolved on `cr125294_Stage_Beta` (Stage_Beta + the CR commits cherry-picked, builds green). **Stage_Beta PRs now:** DB !67196, API !67199, WebContainer !67200 (all merge clean, linked to 125294); Merge Desk's !67197 / !67198 abandoned. Merge Desk #12458 Solved (components Database, AnalyticsReader, Web Container); ADO 125294 Solved, demo video attached. Worktree set removed with remove-cr.ps1 (remote branches kept). **Waiting on:** reviewers / Merge Desk to merge the stage PRs and deploy Stage Beta; Merge Desk's Master_Stable PRs. Note: the 0414/0415 numbers are also used by cr125292 (0414_PR_SalaryReportsLayout) and cr125309 (0415_PR_LatenessPolicyPrintLayout); different file names, so no clash.
