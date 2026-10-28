---
type: handoff
cr: 125486
updated: 2026-10-19
status: SHIPPED to Merge Desk Solved; Stage_Beta PRs have conflicts; module id 934→944 + menu sub-group fix pushed 2026-10-19
---

# HANDOFF — CR-125486: Import projects from Excel (Property Manager)

**Committed locally 2026-10-18, NOT pushed** (engineer: no push yet). 8 commits, split per phase, no Claude co-author:
- DB: `cca69e0ea` import log table + module 934; `17de89c97` drop Pm_Project.ProofOfIncomeAndExpenses
- ERP: `d78428399a` projects (field removed + uniqueness); `3517e521e0` import feature; `b7ee5c1b7b` tests
- Front: `f51498a25b` projects form; `211371da1d` import screen; `baeb3168b0` amenity Serves (client drift)

## Where we are (2026-10-18)

| Step (onboard-ticket spine) | State |
|---|---|
| 0 Preflight + Merge Desk ticket | done. The ADO CR **125486** was created by the agent at the engineer's request (the normal rule is that the agent never creates work items; the engineer asked explicitly). State is In Development. Merge Desk ticket #12533 is Beta, Acknowledge, owner Mohamed Saeed, repos API / WebContainer / Database, contract change **on** |
| 1 Intake | done: [[facts]] (source: [[importProjects]]) |
| 1b Size | **L**: 3 repos, a new table, a new API contract and a new screen, about 25 files |
| 2 Set | done: `D:\Hadaf\worktrees\cr125486\` (db, erp, front), port offset **700**. Front `npm install` was run in the set (package.json differs from the main checkout) |
| 3–4 Grill + spec | done: [[spec]]. Requirement is now [[importProjects v3]]. Every question was answered one by one on 2026-10-18 and recorded in [[decisions]], which overrides v3 on Q3 (activity by id), Q10 (cost center code = parent + next sequence) and Q11 (**drop** the «اثبات الإيراد» columns) |
| 5 Business check | round 1 done: [[business-check-1]]. Verdict: confirm with PO (no KG on this machine; checked against the code). Rows 1–3 → Q8, row 4 → Q9, rows 5–7 adopted, rows 8–9 = Q5 / Q3. Round 2 after the answers |
| 6 Plan | written: [[plan]]. **v2** rewritten after the answers (13 phases, waves A–H). **GATE: waiting for the engineer's yes** |
| 7 Implement | phases 1–11 **done** (uncommitted). e2e on Sabreen: [[test-results]].
| 9 Clean | **done** 2026-10-18: remove-redundant group A applied (engineer approved A only): GL `CreateForAutoGeneration` isLastNode param removed (always ParentCostCenter), unused using in tests, (AC-7)/(AC-10) comment tags, default rowAlternationEnabled, unused CSS class. Kept `r.Errors ?? []` (Errors is optional in the generated DTO). Gates: 41/41 tests; PM/GL/Logistics API 0 errors; `npm run testing` exit 0, 0 errors; prettier clean |
| 8 Review | **pass** after 2 rounds: [[review-1]] (31 merged rows: reviewer + backend + sql + front anti-patterns), [[review-2]] (re-check: 14 done verified, 17 disagree accepted). Fable 5.1 reviewed, Opus 5.5 applied. Two `block` rows are routed away from the code: **S1 = Q13** (engineer) and **A1 = client pin** (release gate) | Plan v2 approved 2026-10-18. **No commits** (engineer preference): changes stay uncommitted in the set. See the Phase log below |

## Ticket facts

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125486
  - Change Request, area `3- Customer Issues`, Program Property Manager
  - Customer نواصى العقارية (copied from sibling PM CRs 125402 / 125483)
  - Due date 2026-11-01
- Branch `cr125486` exists on origin in all 3 repos (made by Merge Desk). First PR goes to `Stage_Beta`, second to `Master_Stable`. **Never merge `Stage_Beta` into `cr125486`.**

## Key code facts (from the scouts)

- **Backend:** `PropertyManager.sln`
  - Create handler `PropertyManager.Application\Projects\Commands\CreateProjectCommand\CreateProjectCommand.cs`
  - Domain rules `Project.ValidateProject` (`Project.cs:266`)
  - Serial `GetNextCodeService.GetNextProjectCode` reads the DB, so the import must save per row
- **DB:** the only unique constraint is `Pm_Project.ProjectSerial`. Name and number are not unique today.
- **Cost center:** nothing auto-creates one today. The pattern to copy is `Logistics...CreateMachineCommand.cs:147-180` (`CostCenter.CreateForAutoGeneration`).
- **Menu and permissions:** `Module.cs`, `0002_Acc_Module_Data.sql`, `WebMenuItem.cs`, `routes.ts`. The module id is **944** (934 until 2026-10-19, then 937 briefly; see the phase log). Menu: root "5" «إعدادات العقارات» › sub-group "5_2" «أدوات المشاريع والعقارات» › item "5_2_1" «استيراد المشاريع» (`WebMenuGroup.cs`).
- **Front:** parses Excel with `xlsx` (journal-import handler). The import screen to copy is `logistics\modules\material-import`.

## Next step

0. **Done 2026-10-19:** the module-id fix (934 → 944) and the menu sub-group are committed and pushed: DB `7e3cda84d`, ERP `9025204d8b`, Front `4530356bf9`. The Stage_Beta PRs !67592 / !67593 / !67594 carry them and still show Conflicts. The client SDK needs no regeneration because the id is not in the API contract.
1. The **Stage_Beta PRs all show Conflicts**: API !67592, Front !67593, DB !67594. On the engineer's word, cut `cr125486_Stage_Beta` off `origin/Stage_Beta` per repo, merge `cr125486` into it, resolve, re-run the gates, push, open the stage PR from it and abandon the conflicting one. **Never merge Stage_Beta into cr125486.**
2. After Stage Beta is deployed: re-check AC-10 and AC-11 (the parent cost center list and the selected cost center on the Projects screen). The local remote-GL 400 hid them.
3. Cleanup: `remove-cr.ps1 -Id 125486` when the engineer decides.

## Phase log

- 2026-10-18: wave A started: phase 1 (DB) and phase 2 (remove «اثبات الإيراد» from the back end), in parallel.
- Phase 2 **done (project side)**: 8 files. PropertyManager.API + Application.Test build 0 errors. The full .sln fails only on the WiX installer project (tool not installed here). Property side → CR-125487 (split). Q12 resolved.
- Phase 1 **done**: new `Pm_ProjectImportLog` (+ sqlproj), `Pm_Project.ProofOfIncomeAndExpenses` + DF dropped, module row 934 in `0002_Acc_Module_Data.sql` (CRLF + BOM kept). MSBuild 0 errors. Bent rule: `DATETIME` instead of `db-rules.md`'s `datetime2(3)`, to match the sibling Pm_ tables.
- Phase 3 **done**: Module 934, `ProjectImportLog` entity + errors, 4 uniqueness errors + resx, `ProjectUniquenessService` used by Create/Update (Update excludes self), registered in `Program.cs`, GL `CreateForAutoGeneration` overload (returns `ParentCostCenter` when non-leaf). PM.API and GL.API csproj build 0 errors.
- Phases 4+5 **done**: EF config + DbSet; `ProjectImport\**` (validator, verify/import commands, log query with paging); 15 resx keys via `ProjectImportErrors`; new `PropertyManagerTransaction` (PM context transaction, GL context joined via SetDbConnection + UseTransaction) registered as `IApplicationTransaction`; the parent cost center check uses the GL rule (`HasTransactions` or non-void JournalActions). Build 0 errors (nullable warnings only).
- Phase 7 **done**: `ProjectImportController` (`POST Verify`, `POST`, `GET Log`), menu group "5" «أدوات المشاريع والعقارات» with item "5_1" (CR 125487 can use "5_2"), `WebMenuGroup.cs` edited. Build 0 errors. Swagger on :2119 lists the 3 operations, saved to `scratchpad\pm-swagger.json`.
- Phase 6 **done**: 28 tests (23 validator + 5 uniqueness), all pass. Moq contexts per test-doubles-and-baselines.md. No packages added, no defects.
- Phase 8 **done**: client regenerated from the saved swagger (custom tsgen in the scratchpad) and built. Only the `dist` of `node_modules/property-manager.api.client` was replaced (still labelled 1.0.108). Backup in `scratchpad/backup`. Front git status clean, CE client folder untouched.
- Phase 9 **done**: the «اثبات الإيراد» radio, its form control and renderRadio removed from the Projects form (3 files). i18n keys kept (Properties still uses them). A scoped tsc over modules/projects gives 0 errors. Duplicate errors show via ServerErrorInterceptor toasts, no code needed. Noted, outside scope: the interceptor returns EMPTY, so a loading overlay may stay up after a 400.
- Phase 10 **done**: `modules/project-import/**` (module, shell, review/template-columns/log components, columns/data/excel services), route `project-import` {ModuleId 934}, 142 i18n keys in ar-EG and en-US. Build: 3 errors, none in phase-10 files. 2 are amenity drift (Q15). 1 was `property-main-form.component.ts:106` reading `ProjectInfoDto.ProofOfIncomeAndExpensesId`, fallout of this CR removing it from ProjectInfoDto; that line was removed (the property keeps its own default). Gate re-run: `npm run testing` gives only the 2 amenity drift errors (Q15) and 0 from this CR's code.
- **Phase 11 (end to end) blocked**: it needs the engineer to name a tenant DB for the targeted publish (new table, column drop, module 934). Phases 12 (review) and 13 (cleanup) are next after that.
- Phase 11 e2e setup (2026-10-18), tenant **Sabreen_Primary on db-all** (the engineer's choice):
  - The `-Script` preview showed a full publish would drop about 40 columns from other branches' work, so `cr125486-sabreen.sql` (in this folder) was applied instead. It holds only `Pm_ProjectImportLog` + module 934, and **does not drop** `Pm_Project.ProofOfIncomeAndExpenses` on the shared tenant. Exit 0, verified, 0 projects on the tenant.
  - PropertyManager API from the set runs on https://localhost:2118 (`scratchpad
un-pm-api.ps1`: Debug, DebugTenantConnection env var, Authority = localbeta).
  - Front `config.json` (LOCAL ONLY, restore after): propertymanagerapi → localhost:2118, localstable → localbeta.
  - `launch.json` entry `front-cr125486`. The dev server failed to build on the Q15 amenity drift. Q15 is **fixed**: amenity-main-grid uses `AmenityServes = { Project: 1, Property: 2 }` from `AmenityType.cs`, and the scoped tsc gives 0 errors. The front builds and serves on localhost:4200.
- Phase 11 **done** 2026-10-18 on db-all / Sabreen_Primary, with the engineer signed in. See [[test-results]]:
  - AC-1, 2, 5, 6, 7, 8, 12, 13, 14 and BR-2/3/4/5/10 pass.
  - AC-3 passes with a wording gap (Q17).
  - AC-4: the sales-org half can't be exercised on Sabreen (user 24 is linked to both orgs); the unit test covers it.
  - AC-10 and AC-11 UI are not verifiable locally: the Stage Beta GL `ActiveCostCenter` returns 400 for Sabreen. Re-check on Stage Beta.
  - New questions: Q16 (المركز text vs lookup), Q17 (AC-3 message).
  - Test reference data added on Sabreen via [[cr125486-sabreen-testdata.sql]]. Projects NRJ, NRJ-A, NRJ-B, ZZZ, NOCC, cost centers 51/52 and 2 log rows now exist on Sabreen.
- Teardown done: API, front and file server stopped; nothing listening on 2118/2119/4200/8765; front `config.json` restored. All 3 repos show only this CR's changes (uncommitted). `launch.json` keeps the `front-cr125486` entry; gitignored launchSettings copied into the set's PM API.
- Review: round 1 merged (2 block routed away, 11 should, 18 nit) → implementer applied 16 rows, uncommitted. Gates: API build 0 errors, 41/41 tests, dacpac OK, `npm run testing` exit 0. Round 2: **pass**.
- 2026-10-18: Q13 → `Pm_Project.sql` reverted (the column stays). Q16 → Center TypeKey List + `_CenterNote_` ar/en, v3 field 16 = «قائمة». Q17 → resx text fixed. Gates: 41/41 tests, API 0 errors, `npm run testing` exit 0 with 0 errors, dacpac built.
- remove-redundant: group A applied (6 items), groups B/C/D declined. Gates green.
- **Q13 re-opened by the follow-up note** [[followup-drop-proof-column]]: real tenant upgrades use AccessControl `DatabaseOperations.UpgradeDatabase` with `BlockOnPossibleDataLoss = false`; `DB.Deployer` (true) has no consumer. So the column drop would not block tenant upgrades. Waiting for the engineer: restore the drop in this CR, or keep it for the follow-up.
- 2026-10-18: Q13 reversed by the engineer: the `Pm_Project.ProofOfIncomeAndExpenses` drop is back in `Pm_Project.sql` (the follow-up note shows tenant upgrades use BlockOnPossibleDataLoss=false). Review-1 row S1 is closed by that decision. No follow-up CR needed.
- 2026-10-18: committed per phase (8 commits, list at the top). All 3 trees are clean. Not pushed.
- 2026-10-18: explainer video recorded on Sabreen (PM + GL APIs local): `demo_125486_import-projects_Iapetus.mp4` (1:51, Hanafi voice + Arabic captions). The take imported ALF, ALF-A, ALF-B, QDS + 2 cost centers under «5» on Sabreen. Teardown done, all 3 trees clean.
- 2026-10-18: activity is now matched **by name** (Q3 final). ProjectImportRowDto.ProjectActivityId → ProjectActivity; the validator matches Pm_ProjectActivities Name/NameSecondLanguage (normalised): blank → null, unknown → error, duplicate name → ambiguous. Tests 44/44, API 0 errors, client regenerated locally, `npm run testing` exit 0 with 0 errors, prettier clean. **Uncommitted** (4 ERP + 4 Front files). The video's segment 2 still says «النشاط بيتكتب بالـ ID»: re-voice that line and its caption (Gemini quota resets tomorrow).
- 2026-10-18: activity-by-name committed (ERP f674c87332, Front ec9db1abef; not pushed). Video re-recorded on the new code: line 2 trimmed to drop the 'by ID' sentence (no Gemini quota), caption 2 = activity by name; the take imported BRJ, BRJ-A, BRJ-B, HDQ on Sabreen (activity سكني matched by name). Teardown done.
- 2026-10-18 **SHIPPED**:
  - Synced with origin/Master_Stable (merge, no conflicts). Gates green: 44/44 tests, PM/GL/Logistics APIs 0 errors, dacpac OK, front `npm run testing` exit 0.
  - Pushed: DB `00b42b7e2`, ERP `34177d9167`, Front `ca3b63f064`.
  - Client SDK: run 185677 published an EMPTY 1.0.123 (the TSClient was missing the `@angular/compiler` devDependency). Fixed in ERP `34177d9167`; run 185679 published **1.0.124**, verified, and the front pin is bumped.
  - Merge Desk #12533 → Solved, components Database / Property Manager / Web Container. ADO → Solved, with a comment carrying the PR links. The video is attached to the work item.
  - Stage_Beta PRs: API !67592, Front !67593, DB !67594, **all Conflicts**.
- 2026-10-18: the engineer will resolve the Stage_Beta PR conflicts (API !67592, Front !67593, DB !67594) personally. The agent does not cut `_Stage_Beta` branches. The set is kept for now.
- 2026-10-19 **module id clash fixed: 934 → 937 (uncommitted)**:
  - Problem: `origin/Stage_Beta` already uses 934 for `PropertyManagerInstallmentPlans` «خطط التقسيط» (from `origin/cr125402`, Abd Alrhman Hamaj). Both features would have shared one permission row, and the `0002` MERGE would flip the module row between them on every deploy.
  - Scan: `Module.cs`, the `0002` rows and the front `routes.ts` ModuleId on every remote branch (ERP 639, DB 317, Front 457). Used: 931–936 and 940–943. **936 is also `PropertyManagerFurnishing` on `origin/cr125491`, so CR-125488's 936 clashes too**; 938 is free for it. 937, 938 and 939 were the only free ids. The engineer chose **937**. Full table: side-session note `module-id-scan-2026-10-19.md`.
  - Changed (BOM and CRLF kept, one line each): ERP `SharedKernel.Logic\Modules\Module.cs`, DB `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql`, Front `projects\property-manager\src\app\routes.ts`. The controller (`Module.PropertyManagerProjectImport.ModuleId`) and WebMenuItem "5_1" pick the id up through `Module`. No test references the id.
  - Gates: PropertyManager.API.csproj 0 errors; sqlproj (VS 2022 Community MSBuild) dacpac built, no errors; front `npm run testing` exit 0 with 0 errors (baseline: exit 0, 0 errors).
  - Sabreen_Primary still has module row 934 = Project Import from `cr125486-sabreen.sql`. The next full reference-data deploy rewrites it; any permission rows granted on 934 there stay on 934.
  - **Stage_Beta group "5" collision:** on `origin/Stage_Beta`, PropertyManager `WebMenuGroup.cs:38` group "5" is «إعدادات العقارات» / "Property Settings". This CR's group "5" «أدوات المشاريع والعقارات» would clash with it, the same collision CR-125487's Stage_Beta PRs already have. Resolve it with the Stage_Beta PR conflicts (Next step 1).
- 2026-10-19 **engineer: module id after 943 → 944; menu as a sub-group** (uncommitted):
  - 944 is free on every remote ERP branch (scan of `new Module(944–959` over all `origin/*` after a full fetch: no hits). Stage_Beta uses 934 and 940–943.
  - Menu, engineer's choice: root group "5" «إعدادات العقارات» / "Property Settings" (same line as Stage_Beta, `fas fa-cogs`) with child sub-group "5_2" «أدوات المشاريع والعقارات» (not root, no icon, like Stage_Beta's "5_1" «البيانات الأساسية للعقارات»), item "5_2_1" «استيراد المشاريع». Matches the spec path إعدادات العقارات › أدوات المشاريع والعقارات › استيراد المشاريع. On the Stage_Beta merge the conflict resolves by keeping both sub-groups in "5"'s `childMenuGroups`.
  - Siblings: CR-125487 (shipped) still has root "5" «أدوات المشاريع والعقارات» with item "5_2" and module 935; CR-125488 uses item "5_3" and module 936 (936 clashes with `cr125491`). Not changed here.
  - Gates: PropertyManager.API.csproj 0 errors; dacpac built. Front: only the routes.ts ModuleId literal changed; `npm run testing` not re-run.
- 2026-10-19: label «مركز التكلفة الأب» → «مركز التكلفة الرئيسي» (engineer): ar i18n (4 keys: _ParentCostCenter_, _ParentCostCenterMissing_, _LogNewCostCenters_, _CreateCostCenterNote_) + 3 resx messages (+ Designer comments). English stays "Parent cost center". Tests 44/44, PM API 0 errors, JSON + prettier OK. Committed + pushed: ERP `61cb7e004f`, Front `633dc68fd7` (the open Stage_Beta PRs pick it up).
- 2026-10-21 **Iteration 1 (QA retest, ADO comment 10010529 by Sabreen), uncommitted.** See [[change-note-1]].
  - Merge Desk #12533 is InRelease and its Stage_Beta PRs are merged. ADO is back at In Development. There is no Bug id, so this is an iterate on `cr125486`.
  - BR-2: project type, status, view and activity now also match their code (`Serial` > 0). Governorate, city and center have no code column and stay name-only, which answers the TBI open question.
  - The «بالغة» → «باللغة» typo is fixed in `Resource.resx` `ProjectNameSecondLanguageRequired` (+ the Designer comment), `ProjectImportColumn` and `property-manager.json` `PROJECTIMPORT._ProjectNameSecondLanguage_`.
  - ⟦E…⟧ comes from Stage_Beta's cr125183 `ErrorMarker`. `ProjectImportRowValidation.ToDto()` strips it with the sibling's regex.
  - Gates: PM Application tests 48/48 (44 + 4 new); the JSON parses and passes prettier.
  - **Next:** `/review-code 125486` (one round). Then commit and push `cr125486`. The Stage_Beta PRs are already merged, so the fix needs a new path to Stage_Beta (the engineer decides: a new PR or a `cr125486_Stage_Beta` branch). The Master_Stable PRs pick it up on push.
- 2026-10-21 Review round 3 ([[review-3]]): **pass**, 0 block / 0 should / 3 nit (Fable reviewer + backend-reviewer). The nits are left as they are. Next: the engineer says commit, then push and decide the Stage_Beta path.
- 2026-10-21 Iteration 1 committed and pushed (fast-forward): ERP `891a7c076a`, Front `d91587cfd8`; no DB change. Merge Desk lists only the 3 Stage_Beta PRs (!67592/!67593/!67594), all **Merged**, and no Master_Stable (MergeLive) PR yet. So the push lands in no open PR. Open: the path to Stage_Beta (a new PR, or a `cr125486_Stage_Beta` branch: the engineer decides), then a Stage Beta deploy (PM API + Web Container) so Sabreen can retest. ADO stays In Development until then.
- 2026-10-21 Stage_Beta PRs opened by the agent at the engineer's request (cr125486 → Stage_Beta, one commit each, merge-tree clean, linked to 125486): ERP !67925, Front !67926. No autocomplete set. Next: merge them, deploy Stage Beta (PM API + Web Container) via release-env when asked, then ADO back to Solved and reply to Sabreen's comment.
