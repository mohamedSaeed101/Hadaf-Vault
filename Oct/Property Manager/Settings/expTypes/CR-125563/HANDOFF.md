---
type: handoff
cr: 125563
updated: 2026-10-19
status: step 9 done (uncommitted); waiting for the engineer to commit, then release-ticket
---

# HANDOFF — CR-125563: Project Expense Types (أنواع تكاليف المشاريع, Property Manager)

**Pushed:** no. Nothing is committed (engineer standing rule: no commit until told).

| Step (onboard-ticket spine) | State |
|---|---|
| 0 Preflight + Merge Desk ticket | **done.** The agent created ADO CR **125563** at the engineer's explicit request (normally it never creates work items). Fields copied from CR 125488. An ADO rule assigned it to Hassan Eldarwany; reassigned to Mohamed Saeed, state In Development. Merge Desk ticket #12553: Beta, Acknowledge, repos API / WebContainer / Database, contract change on, components Database / Property Manager / Web Container. `cr125563` on origin in all 3 repos |
| 1 Intake | done: [[facts]] (source [[expTypes]]) |
| 1b Size | **L**: 3 repos, 2 new tables, new API contract + screen, ~25 files |
| 2 Set | done: `D:\Hadaf\worktrees\cr125563\` (db, erp, front), port offset **1000**. Front `node_modules` not linked: `npm install` (with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1`) before phase 8 |
| 3–4 Grill + spec | done by the agent: [[spec]] (A1–A11). Q1–Q12 answered: [[decisions]] |
| 5 Business check | round 1: [[business-check-1]], violations (0 block, 7 should, 3 nit). Rows 1, 5, 8, 9, 10 folded into [[spec]]; rows 2, 3, 4, 6, 7 are Q8, Q4, Q9, Q10, Q11. Round 2 after the answers. The KG `Accflex_KG` isn't cloned in this workspace; the check ran on vault notes + GL code |
| 6 Plan | **gate passed** 2026-10-19, all recommended answers + Q12 (module 948, menu 5_1_5) — [[decisions]] |
| 7 Implement | phase-loop running, uncommitted |

## Ticket facts

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125563
- First PR → `Stage_Beta`, second → `Master_Stable`. **Never merge `Stage_Beta` into `cr125563`.**
- Module **948**, menu item **5_1_5**.

## Next step

phase-loop runs [[plan]]: wave A (1, 2), 3, 4, wave D (5, 6), 7, 8, 9, then propose `/review-code 125563`.
- 2026-10-19 phase 2 done (uncommitted): Module 948 in Module.cs, ProjectExpenseTypeAggregate (Create/Update/Validate, 15-entry error enum), 15 resx keys ar+en+Designer; PropertyManager.API.csproj builds 0 errors
- 2026-10-19 phase 3 done (uncommitted): EF configs for Pm_ProjectExpenseType + link ProjectProjectExpenseType (ValueObject in ProjectAggregate, no nav on Project), DbSets in context + interface; API builds
- 2026-10-19 phase 1 done (uncommitted): Pm_ProjectExpenseType (UQ_ Code / AssetAccountId constraints = the spec's unique indexes), Pm_ProjectProjectExpenseType, sqlproj entries, module row 948 in 0002_Acc_Module_Data.sql (file is LF); sqlproj builds 0 errors. sqlproj carries 1286 harmless duplicate Build Include lines from d7afadb27a (not ours)
- 2026-10-19 phase 4 done (uncommitted): ProjectExpenseTypes\ commands (Create→Result<int>, Update, Delete), queries (GetAll, GetById, GetActive, GetAccounts), static ProjectExpenseTypeAccountValidator, ProjectExpenseTypeDtoLoader (one grouped GL query); API builds
- 2026-10-19 phase 6 done (uncommitted): ProjectExpenseTypeController (7 actions, module 948), menu groups 5 / 5_1 + item 5_1_5; API ran on :2419 (1419+1000), swagger lists the 7 operations
- 2026-10-19 phase 7 done: PM client regenerated from the Release API build into the set's node_modules (old 1.0.108 backed up at scratchpad\pm-client-1.0.108-backup); repo TSClient index.ts untouched, new source saved at scratchpad\pm-client-index-125563.ts. **Release note:** the regen also carries earlier drift (postPaymentTerm→createPaymentTerm, updatePaymentTerm(id, cmd), getAmenityTypes) — check the PM front callers when release-ticket regenerates
- 2026-10-19 phase 5 done (uncommitted): 56 NUnit tests in PropertyManager.Application.Test\ProjectExpenseTypes\ (mocked PM + GL contexts, no EF InMemory) — 56/56 pass; the project had 0 tests before on Master_Stable. EF save behaviour is left to phase 9
- 2026-10-19 phase 8 done (uncommitted): module project-expense-types (grid, popup form, data service), route project-expense-types (ModuleId 948), i18n ar-EG/en-US; first gate run: 2 TS2367 in amenity-main-grid (pre-existing, CR-125487 Q15) → applied CR-125487's identical Amenity fix (phase 8b) so the branches merge cleanly; gate re-running
- 2026-10-19 front gate green after restart: npm run testing exit 0 (98 s), 0 errors; prettier clean on our files; amenity-main-grid warns but Master_Stable's copy already did (pre-existing), content identical to cr125487 (CRLF only)
- 2026-10-19 phase 9 blocked: engineer approved the guarded script for db-all/Sabreen_Primary (scratchpad cr125563-sabreen.sql: 2 guarded CREATE TABLE + guarded Acc_Module 948 insert, one transaction). Apply failed before connecting: db-all doesn't resolve, OpenVPN adapters disconnected. Nothing was applied. Resume: connect VPN, re-run the sqlcmd apply, then start the PM API on :2419 against Sabreen
- 2026-10-19 phase 9 setup: guarded script applied to db-all/Sabreen_Primary (2 tables + Acc_Module 948). Test asset accounts added (new rows, type 7 under parent 10): 1501/1103901 A clean CC-linked, 1502/1103902 B CC-linked BeginningDebit 100, 1503/1103903 C not CC-linked, 1504/1103904 D clean CC-linked. Finding: Sabreen had **no** CC-linked asset accounts and no journal lines on project cost centres → under Q8 the asset lookup is empty on a tenant like this. PM API Debug on https://localhost:2418 (Authority localbeta, DebugTenantConnection Sabreen, App Name cr125563-pm-local). ng serve OOM'd (machine memory) → serving the npm-run-testing dist on :4200 via scratchpad spa_serve.py with the local config.json; waiting for the engineer's sign-in
- 2026-10-19 phase 9 done: E2E on db-all/Sabreen_Primary — A1–A6, A8–A11 pass, A7 partial (no journal lines on project cost centres in Sabreen; unit tests cover the sum), UI checked ([[test-results]]). Review notes: Q8 leaves the asset lookup empty on tenants with no CC-linked asset accounts; grid clips columns at ~800 px; popup title truncates. Teardown complete (API + static server stopped, config.json restored, UserPermissions patch removed). Left on Sabreen: the 2 tables, Acc_Module 948, test accounts 1501–1504, type row 1 (EMW, inactive). All code uncommitted. **Next: /review-code 125563**
- 2026-10-19 review done: round 1 [[review-1]] pass (0 block, 6 should, 12 nit + release gate row 19: client pin); implementer applied 2, 5, 6, 7, 10 (StringLength; disagreed on Required/Range — accepted), 11, 14–18; round 2 [[review-2]] **pass**, 0 open. 57/57 tests, API build, npm run testing, prettier green. Reviewed by Fable 5.1, applied by Opus 5.5. Uncommitted. **Next: continue → remove-redundant (step 9), then release-ticket** (publish PM client + bump pin = row 19)
- 2026-10-19 step 9 done (uncommitted): remove-redundant applied 3 approved removals (duplicate [visible] on the edit/trash dxi-buttons, unused Poco IsActive default); kept handler permission checks (feature-without-search §6), service SubSink (review row 5), aggregate IsFailure guards. Gates green: PropertyManager.API build 0 errors, 57/57 tests, npm run testing exit 0, prettier clean on the touched template; no local config in the change set. Noticed, not touched: amenity data service unsubscribed subs + narrating comment. **Next: commit (engineer's say-so), then release-ticket** (push, Merge Desk Solved, ADO Solved, publish PM client + bump front pin = review row 19, PR note about the carried Amenity fix)
- 2026-10-19 video dry take found a bug: GetAll threw on NULL NameEn → fixed (string? NameEn on the aggregate), 57/57, verified on Sabreen ([[test-results]]). Uncommitted.
- 2026-10-19 video take found a 2nd bug: edit popup lost Code/NameAr/accounts (DevExtreme validation reset after patch) → fixed (reset before patch). Front rebuild + re-take running. Uncommitted.
- 2026-10-20 resume: front rebuilt with the edit-popup fix (npm run testing exit 0), dist config re-pointed to localhost:2418. Video re-take blocked: VPN down (db-all doesn't resolve); API and static server need restarting. Voice clips + steps.py + reset.sql ready in scratchpad demo-125563. Uncommitted.
