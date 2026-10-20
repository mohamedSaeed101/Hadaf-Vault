---
type: handoff
cr: 125487
updated: 2026-10-19
status: SHIPPED to Merge Desk Solved 2026-10-19; Stage_Beta PRs have conflicts (waiting for the engineer); module 935→945 + menu sub-group fix pushed 2026-10-19
---

# HANDOFF — CR-125487: Import properties (units) from Excel (Property Manager)

**Pushed:** yes, 2026-10-19, `cr125487` in 3 repos after merging `origin/Master_Stable` (no conflicts; gates re-run green: API 0 errors, tests 20/20, DB EXIT 0, front `npm run testing` EXIT 0 on the real 1.0.126 pin).
- DB `301f28bfc`
- ERP `58c02616b6`: includes the `@angular/compiler` fix for the PM TS client
- Front `e330f6bc7a`: pin `property-manager.api.client` 1.0.126

**Release:**
- Client SDK pipeline 684: run 185685 published an **empty 1.0.125** (the npm build failed on `@angular/compiler` but publish ran anyway). After the fix, run 185687 published **1.0.126**, verified to contain `PropertyImportClient`.
- Merge Desk #12534: components Database / Property Manager / Web Container; **Solved**.
- ADO 125487: **Solved**, with a PR-links comment; the video is attached.
- Stage_Beta PRs, all three **Conflicts**:
  - API !67597: Logistics resources (from the Master_Stable merge), the PM TSClient `index.ts`, `WebMenuGroup` / `WebMenuItem`, `PropertiesErrors`, PM resx
  - WebContainer !67598: `package.json`, `amenity-main-grid`, `routes.ts`, i18n
  - Database !67599: `0002_Acc_Module_Data.sql`
- Stage_Beta already has module 934 Installment Plans and menu group "5" (`5_1_1`); this CR's new root group "5" collides with it there. Module 935 is free.

## Where we are (2026-10-18)

| Step (onboard-ticket spine) | State |
|---|---|
| 0 Preflight + Merge Desk ticket | **done.** The agent created ADO CR **125487** at the engineer's request (the normal rule is that the agent never creates work items; the engineer asked explicitly). The CR is In Development. Merge Desk ticket #12534: Beta, Acknowledge, owner Mohamed Saeed, repos API / WebContainer / Database, contract change **on**. `az` lacks the azure-devops extension on this machine, so the ADO calls went through the `azure-devops` MCP. |
| 1 Intake | done: [[facts]] (source: [[importUnits]]) |
| 1b Size | **L**: 3 repos, a new table, a new API contract and a new screen, about 25 files |
| 2 Set | done: `D:\Hadaf\worktrees\cr125487\` (db, erp, front), port offset **800**. Front `node_modules` is **not** linked (package.json differs), so run `npm install` before phase 8 |
| 3–4 Grill + spec | done: [[spec]], revised for [[importUnits v2]] (v2 answers Q1–Q12; new AC-9 and AC-10). **Q13** (engineer): this CR also removes «اثبات الإيراد» from the property. All decisions: [[decisions]] |
| 5 Business check | round 1: [[business-check-1]], all 8 rows resolved. Round 2: [[business-check-2]], 3 rows folded into the spec: (9) projects are loaded as a projection because `Project.CurrencyId` is `int` over a NULL column; (10) the property contract change is breaking; (11) coordination with CR-125486 and CR-125488 |
| 6 Plan | **approved 2026-10-18** |
| 8 Review | round 1: [[review-1]] (reviewer Fable 5.1 + backend / sql / front anti-pattern). 24 rows: code 0 block, 9 should; 1 **release-gate block** (row 9: the client pin bump belongs in this CR's PR, via pipeline 684 + `release-ticket`). Applied by Opus (13 done; 2 disagreements accepted in round 2: 3 and 11). Round 2: [[review-2]] **pass**, 0 block. **Q16** (row 18, should) is left for the engineer |
| Phase 9 | **done 2026-10-18** on db-all / Sabreen_Primary: AC-1…AC-10 pass, see [[test-results]]. Only this CR's schema objects were applied (cut-down script, not a full dacpac). Test data T125487-01…04 and log row 1 are left on Sabreen. Unproven: a NULL-currency project |
| Video | `demo_125487_import-units_Iapetus.mp4` in this folder (1:46, voice + captions). Its import added `T125487-21`…`-23` and log row 2 on Sabreen |
| 9 Clean | Q16 applied (`readRows` walks only the rows that hold cells; a Node check on `A1:S1048576` found the 3 data rows in <1 ms). `remove-redundant` over the DB, ERP and front lines: nothing to remove. Two judgement calls kept: `maybePropertyView` mirrors the Create/Update commands, and the double project load is the NULL-currency workaround. Front `npm run testing` EXIT 0 after Q16 |
| 7 Implement | phases 1–8 **done**, plus the Q14 and Q15 changes. Gates run by the agent: DB MSBuild EXIT 0 (dacpac built); the PropertyManager.API csproj builds with 0 errors; `PropertyManager.Application.Test` passes 20 of 20; front `npm run testing` EXIT 0. ESLint not run (no reliable target). Phase 9 (end to end on a tenant) waits only for the engineer's OK on which tenant. **Nothing committed** (the engineer's rule) |

## Ticket facts

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125487
  - Change Request, area `3- Customer Issues`, Program Property Manager
  - Customer نواصى العقارية, due 2026-11-01 (fields copied from sibling CR 125486)
- Branch `cr125487` exists on origin in all 3 repos (made by Merge Desk). First PR goes to `Stage_Beta`, second to `Master_Stable`. **Never merge `Stage_Beta` into `cr125487`.**

## Key code facts (from the scouts)

- **Create path:** `PropertyManager.Application\Properties\Commands\CreatePropertyCommand\CreatePropertyCommand.cs`
  - poco built at l.195-247, `Property.Create` at l.250
  - domain rules in `Property.ValidateProperties` (`Property.cs:270-324`)
- **Inheritance from the project is front-only:** `property-main-form.component.ts:89-117`. Currency is not copied on the screen.
- **Serial:** `GetNextCodeService.GetNextPropertyCode` (l.49) reads MAX from the DB, so the import saves per row.
- **Lookups:**
  - status, type, activity and view tables are shared with projects (`Pm_Project*`)
  - the investment type is the static list 1–4
  - the project's types are in `Pm_ProjectInvestmentType`
- **Module.cs:** max id 933, 934 is CR-125486's, so this CR takes **935**. Menu groups are only the group text on the module row.
- Main checkout `AccFlex_Cloud_ERP` is on `feature/payroll-tests-v2`. Read from the set, not the main checkout.

## Next step

- **2026-10-19, pushed:** Front `843ebc3e6d`. `amenity-main-grid.component.ts` uses `const AmenityServes = { Project: 1, Property: 2 } as const;` (the engineer's request). Front `npm run testing` EXIT 0. The open Merge Desk PR !67598 picks it up.

0. **Module id and menu fix, committed and pushed 2026-10-19:** DB `a0e1e276f`, ERP `13ffe7bc04`, Front `463d1ec8d0`. The Stage_Beta PRs !67597 / !67598 / !67599 carry them and still show Conflicts. Module **945** (was 935; ids after 943 are the engineer's rule, since Stage_Beta uses 934 and 940–943). The menu is root "5" «إعدادات العقارات» / "Property Settings" (the same line as Stage_Beta) › sub-group "5_2" «أدوات المشاريع والعقارات» › item "5_2_2" «استيراد العقارات». Siblings use the same sub-group: CR-125486 item "5_2_1" (module 944), CR-125488 item "5_2_3" (module 946). Files: ERP `Module.cs`, `WebMenuGroup.cs`, `WebMenuItem.cs` (the "5_1 is reserved" comment dropped); DB `0002_Acc_Module_Data.sql`; Front `property-manager/src/app/routes.ts`. 945 is free on every remote ERP / DB / Front branch. Gates: PropertyManager.API.csproj 0 errors, dacpac built; front `npm run testing` not re-run (only the ModuleId literal changed). Sabreen still has test module row 935. When the siblings merge, `WebMenuGroup.cs` conflicts textually; resolve it by listing every sibling item in the "5_2" sub-group.
1. **The engineer is resolving the Stage_Beta conflicts himself (2026-10-19).** Hint: Stage_Beta has root group "5" «إعدادات العقارات» (Property Settings) with sub-group "5_1" «البيانات الأساسية للعقارات». The note's path «إعدادات العقارات › أدوات المشاريع والعقارات» suggests this CR's group belongs under "5" as a sub-group (e.g. "5_2"), not as its own root group. Previously: The rules forbid merging Stage_Beta into `cr125487` and forbid using the ADO Conflicts tab. The only way is a `cr125487_Stage_Beta` branch off `origin/Stage_Beta`, with `cr125487` merged into it and the conflicts resolved there, cut only on the engineer's word. The menu group key ("5" is taken on Stage_Beta) needs a decision.
2. Then Stage Beta deploy (`release-env`) when asked, and PO check.
3. Remove the set with `remove-cr.ps1` when the engineer says so.

Gates after the review fixes (2026-10-18): API build 0 errors; tests 20 of 20; DB MSBuild EXIT 0; front `npm run testing` EXIT 0.

Build notes:
- The full `PropertyManager.sln` fails only on the WiX installer project (WiX is not installed here). Gate on `PropertyManager.API.csproj`.
- The front's `node_modules\property-manager.api.client` holds the locally generated client; the 1.0.108 backup is in the session scratchpad (`pm-client-1.0.108-backup`). The real pin bump happens at release.
- The front build log is in `%TEMP%\front-build-cr125487-*.log`.
