---
type: handoff
cr: 125716
updated: 2026-10-22
status: plan written; waiting on the business check round 1 and the plan gate
---

# HANDOFF — CR-125716: Violation Policies (سياسات المخالفات, Property Manager)

**Pushed:** no. Nothing is committed (engineer standing rule: no commit until told).

| Step (onboard-ticket spine) | State |
|---|---|
| 0 Preflight + Merge Desk ticket | **done.** The agent created ADO CR **125716** at the engineer's explicit request from the source note [[Violation Policies]]. Fields were copied from CR 125563; it is assigned to Mohamed Saeed, state In Development. Merge Desk ticket #12595: Beta, Acknowledge, repos API / WebContainer / Database, contract change on, components Database / Property Manager / Web Container. `cr125716` is on origin in all 3 repos; there is none in AccFlex_ERP. |
| 1 Intake | done: [[facts]] |
| 1b Size | **L**: 3 repos, new table + FK on `Pm_ContractClause` + module row, new API contract + screen + menu root, ~22 files |
| 2 Set | done: `D:\Hadaf\worktrees\cr125716\` (db, erp, front), port offset **1200**. The front `node_modules` isn't linked: run `npm install` (with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1`) before phase 8. |
| 3–4 Grill + spec | done by the agent: [[spec]] (A1–A12). The engineer answered Q1–Q8 one by one on 2026-10-22 ([[decisions]]). Q3 changed: the «سياسة المخالفة» picker on the contract-clause form is in scope. Q8: the tenant notice is deferred, and fines carry no VAT. There is no KG in the workspace; the grilling ran on the source note, the sibling CR notes and the code. |
| 5 Business check | round 1 **pass** (0 block, 3 should, 5 nit) → [[business-check-1]]; folded into [[spec]] / [[plan]] / [[open-questions]] (lookup tables, CHECKs, pre-deploy null script, base currency). One nit rejected (`CountryEnum.SaudiArabia` = 193 exists). |
| 5b Business check 2 | **pass** (0 block, 2 should, 4 nit) → [[business-check-2]]. Row 1: the engineer allows any clause to carry a policy (D4). Row 2: the A9 wording is fixed. The nits are folded in ([[deferred]] rewritten, plan DB bullet). Tell Abd Alrhman Hamaj (owner of CR 125483's clause screen) when the PR opens. |
| 5c Spec change | side session: the policy's names are `ViolationPolicyName` / `ViolationPolicyNameSecondLanguage` (D5); spec, plan and decisions are aligned |
| 6 Plan | **gate passed** 2026-10-22: "Yes to the plan with the decisions in decisions.md. Run the phases." |
| 7 Implement | **phases 1–8b done**, uncommitted (no-commit rule); details in [[plan]] § Progress. Gates:<br>- DB: MSBuild exits 0 and sql-reviewer is clean (FK renamed `FK_Pm_ContractClause_Pm_ViolationPolicy`).<br>- PM API: build 0 errors; swagger lists the 6 operations.<br>- Tests: 434 / 434 (50 new).<br>- Client: regenerated into the set's `node_modules` only (1.0.153 package.json kept; backup in scratchpad).<br>- Front: `npm run testing` exits 0 with 0 errors.<br>Changed files: DB 8, ERP 39, Front 16. **Phase 9 blocked on Q9** (OK to publish the cut-down schema to Sabreen). |

## Tenant schema

- **2026-10-22 ~15:50, db-all / Sabreen_Primary:** the cut-down CR 125716 schema was applied (engineer's Q9 yes) from scratchpad `cr125716-sabreen.sql`, guarded and in one transaction: 3 tables, FK, pre-script logic, 0467 seed, module 954. Verified: 5 types, 2 modes, FK present, module 954, 0 clauses with a policy. COPY_ONLY backup first: `Sabreen_Primary_cr125716_20261022.bak` in db-all's default backup folder. A full publish would have dropped 45 columns from other branches, so it was not used.

- **Phase 9 local run (2026-10-22 ~16:00):**
  - PM API: Debug build from scratchpad `pm-bin-9`, `http://localhost:2619`, Development, Authority localbeta, DebugTenantConnection → db-all/Sabreen_Primary (Application Name `cr125716-pm-local`).
  - Front: `npm run dev` on :4200. config.json was edited locally (propertymanagerapi → localhost:2619, miscapi / dashboard → localbeta); `git restore` it at teardown.
  - The engineer signed in. **Phase 9 done: A1–A12 pass**, see [[test-results]].
  - Teardown: API and dev server stopped, config.json restored, no config-like file dirty in any repo.
  - Test data left on Sabreen: NOISE-01 and DAMAGE-01; clause 3 back to null.

## Ticket facts

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125716
- First PR → `Stage_Beta`, second → `Master_Stable`. **Never merge `Stage_Beta` into `cr125716`.**
- Module **938** (engineer, D6; 954 is "Work Teams" on Sabreen), menu `7` التأجير › `7_1` المخالفات › `7_1_1` (Q4). Sabreen has the 938 row (added 2026-10-22 during review).
- The cloud has no lease contract and no violation log: occurrence counting is deferred (Q1).

## Next step

**Review done 2026-10-22, pass:**
- Round 1 ([[review-1]]): 0 block, 5 should, 12 nit / info. Rows 1, 2, 3, 6, 9, 10, 13, 14 were applied and gates re-run green (API build, 434 / 434 tests, sqlproj, `npm run testing`).
- Round 2 ([[review-2]]): 0 / 0 / 0, all rows verified, module 938 consistent.
- Reviewed by Fable 5.1, applied by Opus 5.5.
- Bent rules D7 (unpaginated GetAll) and D8 (`Id` PK) go in the PR description.

**Clean-up done 2026-10-22 (remove-redundant):**
- 3 finders (DB / ERP / Front) over `git diff HEAD` plus untracked files: the CR's lines are near-clean.
- The engineer approved item 1 only: the reworded apply-mode comment in `violation-policies-data.service.ts`. Gate `npm run testing` exits 0; prettier clean.
- Kept by decision:
  - the SubSink for the one-shot call, `onDeletePopupHide` and the `isRTL` default (match siblings)
  - `AmountForOccurrence` (the BR-3 seam)
  - the duplicated clause lookup and test setup
  - the pre-script ELSE branch (runs once per tenant)
- Noticed, not touched: the export boilerplate across grids, the inline name-by-language idiom, `WebMenuGroup.cs` indentation.

**Demo video 2026-10-22:** [[demo_125716_violation-policies_Iapetus.mp4]] (1:54, Hanafi / Gemini Iapetus, 12 segments; work files in the session scratchpad `demo-125716\`). Approved by the engineer (v2, 2:13, line 3 explains both apply modes). Attached to ADO 125716 on 2026-10-25 as `demo_125716_violation-policies.mp4`. Teardown done: local API and dev server stopped, config.json restored, clause 3 unlinked on Sabreen (NOISE-01 / DAMAGE-01 remain as test data).

**Committed 2026-10-22** (engineer's say-so, no Co-Authored-By line, not pushed):
- DB `e735a1132` (8 files)
- ERP `181fdcdd27` (37 files)
- Front `60be81b0f2` (16 files). The pretty-quick hook also re-indented the two pre-existing en-US lines (101, 146).

**SHIPPED 2026-10-22 (release-ticket):**
- **Rebased onto origin/Master_Stable** (engineer: rebase, not merge). The conflicts were adjacent additions, so both sides were kept: `0002` (938 next to 949), `Module.cs` (938 next to 950), `WebMenuGroup.cs` (Prices "6" then Leasing "7"), `PropertyManagerContext.cs`, both resx files.
- Master_Stable's PriceList / SalePrice test contexts needed the `ViolationPolicies` DbSet: ERP commit `a15038c934`.
- Gates: API build 0 errors, 614 / 614 tests, sqlproj build, `npm run testing` exit 0.
- **Front clients are now source** (`src/api-clients/<module>`, the `*.api.client` packages are retired). Ran `sync-api-client` (PropertyManager): 0 orphans, parity ok, 17 files committed by path in Front `bd60f608aa`. No Client SDK pipeline and no pin bump.
- Pushed tips: DB `76cc739bf`, ERP `a15038c934`, Front `bd60f608aa`.
- Merge Desk #12595 → **Solved**; ADO 125716 → **Solved**, with the PR-links comment.
- Stage_Beta PRs:
  - API !68210: open
  - DB !68212: **Conflicts**
  - Web !68211: **Conflicts**

  The engineer resolves these; a `cr125716_Stage_Beta` branch is cut only on request.
- **After release (D9):** the pre-deploy script `20261022144037_NullContractClauseFinePolicyId.sql` was removed (engineer: no customer data). DB sqlproj builds; a follow-up DB commit was pushed to `cr125716`, so the open DB PRs pick it up.
- **Stage_Beta conflicts fixed 2026-10-25** (engineer: "fix conflict"):
  - DB !68212 had already completed into Stage_Beta (it includes the D9 removal).
  - Cut `cr125716_Stage_Beta` off origin/Stage_Beta in ERP and Front (worktrees under `worktrees\cr125716\_stage\`), merged `cr125716` in and resolved there. `cr125716` itself is unchanged.
  - ERP: Stage_Beta's cr125720 owns root `7` Rental with `7_1` / `7_1_1` Rental Reports, so on the stage branch Violations sits under Rental as **`7_2` / `7_2_1`** and our `Leasing` root is dropped. cr125716 was then aligned (engineer, ERP `9424488d89`, pushed): Leasing `7` › Violations `7_2` › `7_2_1`, so Master matches Stage_Beta. Only the duplicate root `7` (Leasing vs cr125720's Rental, both «التأجير») is left for whichever lands on Master second. ContractTemplateTestContext got the DbSet. A second Stage_Beta update (cr125638 resx) was merged in too.
  - Gates: PM tests 796 / 796 on the first merge. After the second update, the PM API doesn't compile because of Stage_Beta itself: cr125638 (`709235f32c`, PR 68207) declares `BookingAndContracting` / `RealEstateMarketing` twice in `WebMenuGroup.cs` (CS0102). Not ours; not fixed. Front `npm run testing`: only the 2 TS2554 payroll `getEmployeeList` errors already on Stage_Beta.
  - New PRs: ERP **!68281**, Web **!68282** (both mergeable, linked to 125716, no auto-complete). Old !68210 / !68211 abandoned with a pointer comment.
- The old steps below are superseded:
- sync with origin/Master_Stable (expect a one-line conflict in `0002_Acc_Module_Data.sql`)
- regenerate the PM client through the Client SDK pipeline and bump the front pin
- push, then move Merge Desk #12595 and ADO 125716 to Solved
- PR description cites D7 / D8 and tells Abd Alrhman Hamaj about the clause picker The release must regenerate the client in the repo TSClient and bump the front pin, and re-check that module 954 / seed 0467 / menu "7" are still free on Stage_Beta. After that, `phase-loop` runs the plan.
