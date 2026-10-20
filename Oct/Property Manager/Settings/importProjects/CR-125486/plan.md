---
type: plan
cr: 125486
size: L
updated: 2026-10-18
status: v2. All questions answered; waiting for the engineer's yes at the plan gate
---

# CR-125486 — Plan v2: Import projects from Excel

## Sources and authority

- [[importProjects v3]] is the requirement.
- [[decisions]] overrides it where they differ:
  - Q3: activity is entered **by id**
  - Q4: uniqueness is enforced on the screen too
  - Q10: cost center code = parent + next sequence
  - Q11: **drop** the «اثبات الإيراد» columns
- [[spec]] gives the shape. Where spec and decisions differ, decisions win.

## Set

- Worktrees: `D:\Hadaf\worktrees\cr125486\`, branch `cr125486`, base `Master_Stable`, port offset 700.
- Merge Desk #12533. The contract change flag is on, and the contract change is now **breaking** (Q11): the front and the API deploy together.

## Size: L

- 3 repos.
- Schema changes: a new table, two dropped columns and a module row.
- A new API plus a breaking change to the existing project/property contracts.
- A new screen plus edits to the Projects and Properties screens.
- About 35 files.

## Rules per surface (cite in each commit / review)

**CE.** Sources: `AccFlex_Cloud_ERP\CLAUDE.md`, `.claude\rules\accflex-erp-api.md`, `accflex-erp-core.md`, `accflex-erp-domain.md`, `accflex-erp-data.md`, `datetime-clock.md`, `test-doubles-and-baselines.md`.
- Controllers call MediatR only.
- `IHaveModulePermission` with `ModuleId`, and a policy on every action.
- `Result`, no exceptions.
- resx ar + en + Designer.
- `IApplicationTransaction` across contexts.
- No N+1.
- `IDateTime.Now`.

**DB.** Sources: `AccFlex_Cloud_Database\CLAUDE.md`, `.claude\rules\db-rules.md`, `sqlproj-registration.md`, `prescript-no-ddl.md`, `prescript-no-go.md`.
- The module row is reference data.
- No DDL in pre/post scripts. The column drop is done in the table files (SSDT).

**FE.** Sources: `AccFlex_Cloud_Front\CLAUDE.md`, `.claude\rules\core.md`, `accflex-erp.md`, `feature-data-service.md`, `api-clients.md`, `permissions-and-drawer.md`, `template-bound-getters.md`.
- NgModule.
- The generated client only.
- en + ar i18n.
- `data: { ModuleId }`.

**Front patterns to copy:** `projects\logistics\src\app\modules\material-import\` and `projects\general-accounting\...\journal-import\shared\journal-import-handler.service.ts`.

## Phases

| # | Phase | Files | Done when | Depends on | Wave |
|---|---|---|---|---|---|
| 1 | **DB** (property column moved to CR-125487 per the split, so only the Pm_Project column is dropped here): (a) new table `Pm_ProjectImportLog` (Id, ImportDate, FileName, UserId, TotalRows, NewRows, ErrorRows, NewCostCenters, ParentCostCenterId NULL, audit) + sqlproj entry; (b) **drop** `Pm_Project.ProofOfIncomeAndExpenses` + `DF_Pm_Project_ProofOfIncomeAndExpenses`, and `Pm_Properties.ProofOfIncomeAndExpensesId` + `FK_Pm_Properties_Pm_ProofOfIncomeAndExpenses` (keep the `Pm_ProofOfIncomeAndExpenses` table and `0328_` script); grep views/TVFs/procs for the columns; (c) module row 934 in `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` (group «أدوات المشاريع والعقارات» / "Projects & Properties Tools", copy the 856 row) | `dbo\Tables\Pm_ProjectImportLog.sql`, `Pm_Project.sql`, `Pm_Properties.sql`, `*.sqlproj`, `0002_Acc_Module_Data.sql` | VS 2022 MSBuild of the sqlproj: 0 errors; `publish-db.ps1 -Id cr125486 -Script` shows only: create table, 2 column drops (+DF/FK), module merge | — | A |
| 2 | **Remove «اثبات الإيراد» (back end, Q2/Q11), project side only; the property side is CR-125487's:** remove it from `Project` / `ProjectPoco`, `Property` / `PropertyPoco`, Create/Update Project + Property commands, `ProjectDto`, `PropertyDto`, `ProjectInfoDto`, the GetById queries and the EF mappings; keep the `ProofOfIncomeAndExpenses` entity + its configuration (lookup table stays); drop `PropertiesErrors.ProofOfIncomeAndExpensesNotFound` if it becomes unused | `PropertyManager.Logic\ProjectAggregate\*`, `PropertyAggregate\*`, `PropertyManager.Application\Projects\**`, `Properties\**`, `PropertyManager.Data\EFConfigurations\*` | `dotnet build PropertyManager.sln` exits 0; `grep ProofOfIncomeAndExpenses` only hits the lookup entity/config | — | A |
| 3 | **Shared + Logic:** `Module.PropertyManagerProjectImport` (934, app 14, parent 67); `ProjectImportLog` entity (static `Create`, Result); **uniqueness rule (Q4)** as one Application service used by Create, Update (exclude self) and import → `ProjectsErrors.ProjectNumberAlreadyExists` / `ProjectNameAlreadyExists` / `ProjectNameSecondLanguageAlreadyExists`; new resx keys ar + en + Designer for every import message; GL: `CostCenter.CreateForAutoGeneration` overload (name, second name, number, parent, level, **isLastNode: false**) | `CE\Shared\SharedKernel.Logic\Modules\Module.cs`, `PropertyManager.Logic\ProjectImportAggregate\*`, `ProjectAggregate\ProjectsErrors.cs`, `Resources\Resource*.resx` + Designer, `PropertyManager.Application\Projects\Shared\ProjectUniquenessService.cs`, Create/UpdateProjectCommand, `GeneralLedger.Logic\CostCenterAggregate\CostCenter.cs` | `dotnet build PropertyManager.sln` and `GeneralLedger.sln` exit 0 | 2 | B |
| 4 | **Data:** EF config `ProjectImportLogConfigurations` (`Pm_ProjectImportLog`, Id → `ProjectImportLogId`); `DbSet` on `IPropertyManagerContext` + the context | `PropertyManager.Data\EFConfigurations\`, context, `IPropertyManagerContext.cs` | build exits 0 | 3 | C |
| 5 | **Application, import:** `ProjectImport\Shared\ProjectImportValidator` (lookups loaded once; resolve by name ar/en/code with Arabic normalisation; **activity by id** (Q3); status by name, blank = null (Q5); cost distribution = the screen's current list (Q9); builds `ProjectPoco` → `Project.Create`; import-only rules: add-only number, uniqueness via the phase-3 service + within the file (error at first line), parent existing or earlier valid line, ≠ self, ambiguous parent number → error, country → gov → city chain, numbers ≥ 0 / int, yes/no/blank, multi-value split `،`/`,`, sales org ↔ user, max 1000 rows); `VerifyProjectImportCommand`; `ImportProjectsCommand` (re-validate; parent cost center check once: active, non-leaf, no transactions → reject all; one `IApplicationTransaction`; file order; per-row save via `GetNextCodeService`; non-leaf auto cost center for leaf projects with yes/blank, code = parent + next seq (Q10), names = project names, link `CostCenterId`; log row; result N / K / cost center count); `GetProjectImportLogQuery` (paginated, newest first); `GetActivitiesForTemplate` if the static list lacks ids | `PropertyManager.Application\ProjectImport\**` | build exits 0 | 3, 4 | D |
| 6 | **Unit tests:** validator + uniqueness + ordering (AC-1 leaf detection, AC-2, AC-3, AC-4, AC-5, AC-12, AC-13, duplicate in file → first line, parent on a later line, ambiguous parent, `،`/`,` split, update excludes self) | `PropertyManager.Application.Test\ProjectImport\*Tests.cs`, `Projects\ProjectUniquenessTests.cs` | `dotnet test PropertyManager.Application.Test` passes | 5 | E |
| 7 | **API:** `ProjectImportController` (`api/ProjectImport`: `POST Verify`, `POST`, `GET Log`), `ModuleId` 934, policies, `ProducesResponseType`, XML docs; `WebMenuItem` entry (new group) → route `project-import` | `PropertyManager.API\ApiControllers\ProjectImportController\*`, `PropertyManager.Application\MenuList\WebMenuItem.cs` | build exits 0; the API on base port + 700 shows the 3 actions in Swagger | 5 | E |
| 8 | **API client:** regenerate `property-manager.api.client` (new import client + project/property DTOs without the field), build locally, link into the set's `node_modules`; not committed or published (pin bump at release) | `PropertyManager.API.Client` (generated) | the front `tsc` resolves the new types | 2, 7 | F |
| 9 | **Front, existing screens** (Projects form only; the Properties form is CR-125487's): remove the «اثبات الإيراد» radio + form control from the Projects form (`project-main-form` html/ts, `project-data.service.ts:139`) and the Properties form (`property-main-form` html:395, ts:106, `properties.service.ts:154`); show the new duplicate errors | `projects\property-manager\src\app\modules\projects\**`, `properties\**` | `npm run testing` exit 0 | 8 | G |
| 10 | **Front, import screen:** module `modules\project-import\` (shell, step bar, last-result message with «فتح المشاريع», cost center group (parent dropdown from `costCenterList$` filtered: active, non-leaf; the API is the final check; kept in session), file group, summary bar, 2 buttons, 3 tabs: row review (with a cost center column), template columns (lists activity ids), import log); template + error file with `exceljs`; parse with `xlsx` by position; 1000 rows / 5 MB guard; route `project-import` `{ ModuleId: 934 }`; en + ar i18n | `projects\property-manager\src\app\modules\project-import\**`, `routes.ts`, i18n | `front-verify-build` green | 8 | G |
| 11 | **End to end** via `local-api-run` on a tenant the engineer names (targeted DB script for phase 1, with the engineer's OK): test workbook in the vault; AC-1…AC-14 + Q4 on the Projects screen + Q11 (field gone on both screens); proof in `test-results.md` | vault | all ACs pass | 1, 6, 9, 10 | H |
| 12 | Review: the engineer runs `/review-code 125486` | — | 0 block rows | 1–11 | — |
| 13 | Cleanup: `remove-redundant` + gates green | — | gates green | 12 | — |

## Parallelism (depends-on decides it)

| Wave | Phases |
|---|---|
| A | 1 DB and 2 removing the field (independent) |
| B | 3 |
| C | 4 |
| D | 5 |
| E | 6 tests and 7 API, in parallel |
| F | 8 client |
| G | 9 and 10, in parallel (different folders) |
| H | 11 |

## Risks

- **Q11 drop = data loss + BlockOnPossibleDataLoss.** The stage dacpac publish stops on the drop unless the profile allows it. Phase 1 checks the publish profile and records how stage will apply it, in `open-questions.md` if the engineer must decide. Existing values are lost on every tenant (the engineer accepted this).
- **Breaking contract.** The project and property DTOs lose a field. The front and API must ship together (the Merge Desk contract flag is already on). The desktop app does not read these tables (to confirm in phase 2 with a grep in `AccFlex_ERP`).
- **Q4 on the screen.** Tenants that already have duplicates get the duplicate error when they edit one of those projects (the engineer's call: not handled).
- **Cost center parent.** The "no transactions" check needs a GL query (journal lines by cost center). Phase 5 reuses whatever `CostCenterService` uses (`CostCenterService.cs:171-177`).
