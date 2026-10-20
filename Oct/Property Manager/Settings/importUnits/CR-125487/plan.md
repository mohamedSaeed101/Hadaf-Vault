---
type: plan
cr: 125487
size: L
updated: 2026-10-18
status: approved 2026-10-18; phase-loop running
---

# CR-125487 — Plan: Import properties (units) from Excel

- **Set:** `D:\Hadaf\worktrees\cr125487\` (branch `cr125487`, base `Master_Stable`, port offset **800**).
- **Spec and decisions:** [[spec]], [[decisions]] (v2 + Q13), [[business-check-1]], [[business-check-2]] (rows 9–11 folded into the spec).
- **Commits:** none. The engineer's standing rule is no commits until told, so each phase leaves its changes uncommitted in the set.
- **Q13:** this CR also removes «اثبات الإيراد» from the **property** (DB column + back end + Properties form). CR-125486 keeps the project side.
- **Size: L.** Evidence:
  - 3 repos (DB, Cloud_ERP, Front)
  - a new table (schema change), a new API contract and a new screen
  - about 25 files expected
- **Sibling:** CR-125486 (import projects), same shape, not implemented yet. Nothing is shared between the two branches (Q9).

## Rules each phase follows

- **CE** (`AccFlex_Cloud_ERP\CLAUDE.md`, `.claude\rules\accflex-erp-api.md`, `accflex-erp-core.md`, `accflex-erp-domain.md`, `accflex-erp-data.md`, `core.md`, `datetime-clock.md`, `test-doubles-and-baselines.md`):
  - controllers call MediatR only
  - `IHaveModulePermission` with `ModuleId`, and policies on every action
  - `Result`, no exceptions
  - resx ar + en + Designer
  - one transaction
  - no N+1: lookups loaded once per file
  - `IDateTime.Now`
- **DB** (`AccFlex_Cloud_Database\CLAUDE.md`, `.claude\rules\db-rules.md`, `sqlproj-registration.md`, `prescript-no-ddl.md`):
  - the new table is registered in the sqlproj
  - the module row is reference data (`0002_Acc_Module_Data.sql`), which re-runs every deploy
  - no pre/post script is needed
- **FE** (`AccFlex_Cloud_Front\CLAUDE.md`, `.claude\rules\core.md`, `accflex-erp.md`, `feature-data-service.md`, `feature-without-search.md`, `api-clients.md`, `permissions-and-drawer.md`, `template-bound-getters.md`):
  - NgModule
  - the generated client, never hand-edited
  - en-US + ar-EG `property-manager.json`
  - `data: { ModuleId }`
- **Templates to copy:**
  - front: `projects\logistics\src\app\modules\material-import\`, for Verify → Post with per-row status
  - front: `journal-import-handler.service.ts`, for `XLSX.read`
  - backend: `CreatePropertyCommand.cs:100-265`, for the poco build and `Property.Create`

## Phases

| # | Phase | Files | Done when | Depends on | Wave |
|---|---|---|---|---|---|
| 1 | **DB:** table `Pm_PropertyImportLog` + sqlproj entry; **drop** `Pm_Properties.ProofOfIncomeAndExpensesId` + `FK_Pm_Properties_Pm_ProofOfIncomeAndExpenses` in `Pm_Properties.sql` (keep the lookup table; grep views/TVFs/procs for the column; record how the stage profile handles `BlockOnPossibleDataLoss`); module row 935 in `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` (copy the 851 row; group «أدوات المشاريع والعقارات» / "Projects & Properties Tools") | `AccFlex_Cloud_Database\...\dbo\Tables\Pm_PropertyImportLog.sql`, `Pm_Properties.sql`, `*.sqlproj`, `0002_Acc_Module_Data.sql` | VS 2022 MSBuild of the sqlproj: 0 errors; `publish-db.ps1 -Id cr125487 -Script` shows only: create table, 1 column drop (+FK), module merge | — | A |
| 2 | **Shared + Logic:** `Module.PropertyManagerPropertyImport` (935, app 14, parent 67) in `SharedKernel.Logic\Modules\Module.cs`; `PropertyImportLog` entity (static `Create`, `Result`); resx keys ar + en + Designer for the import messages; the Q12 guard on `maybePropertyModel` at `Property.cs:119` and `:220`; **remove «اثبات الإيراد» from the property** (Q13): `Property`, `PropertyPoco`, Create/Update Property commands (incl. the l.128 check), `PropertyDto`, property queries, EF mapping; keep the `ProofOfIncomeAndExpenses` lookup entity + config | `CE\Shared\SharedKernel.Logic\Modules\Module.cs`, `PropertyManager.Logic\PropertyImportAggregate\*`, `PropertyManager.Logic\PropertyAggregate\Property.cs`, `PropertyManager.Logic\Resources\Resource*.resx`, `Resource.Designer.cs` | `dotnet build PropertyManager.sln` exits 0; `grep ProofOfIncomeAndExpenses` under `PropertyAggregate\` and `Properties\` finds nothing | — | A |
| 3 | **Data:** EF config `PropertyImportLogConfigurations` (table `Pm_PropertyImportLog`, Id → `PropertyImportLogId`); `DbSet` on `IPropertyManagerContext` and the context | `PropertyManager.Data\EFConfigurations\`, `PropertyManager.Data\...Context.cs`, `PropertyManager.Application\Common\Interfaces\IPropertyManagerContext.cs` | build exits 0 | 2 | B |
| 4 | **Application:** `PropertyImport\Shared\PropertyImportValidator` (see the list below); command `VerifyPropertyImportCommand`; command `ImportPropertiesCommand`; query `GetPropertyImportLogQuery` (paginated, newest first); DTOs | `PropertyManager.Application\PropertyImport\**` | build exits 0 | 2, 3 | C |
| 5 | **Unit tests** for `PropertyImportValidator` and the import order (list in [[spec]] §Testing: AC-2…AC-7, all errors per row, blank → project values, Arabic-normalised and ambiguous match, `PropertyInvestmentType.PropertyId` points at the property) | `PropertyManager.Application.Test\PropertyImport\*Tests.cs` | `dotnet test PropertyManager.Application.Test` passes | 4 | D |
| 6 | **API:** `PropertyImportController` (`api/PropertyImport`: `POST Verify`, `POST`, `GET Log`), `ModuleId` 935, policies, `ProducesResponseType`, XML docs; `WebMenuItem` entry → route `property-import` | `PropertyManager.API\ApiControllers\PropertyImportController\PropertyImportController.cs`, `PropertyManager.Application\MenuList\WebMenuItem.cs` | build exits 0; the API starts on base port + 800 and Swagger lists the 3 actions | 4 | D |
| 7 | **API client:** regenerate `property-manager.api.client` from the phase-6 swagger, build it locally, link it into the set's `node_modules`. Nothing is published; the pin bump (now `1.0.108`) happens at release | `PropertyManager.API.Client` (generated), the set's `node_modules` | the new `PropertyImportClient` types resolve in the front `tsc` | 6 | E |
| 8 | **Front:** module `projects\property-manager\src\app\modules\property-import\` (see the list below); route `property-import` `{ ModuleId: 935 }` in `routes.ts`; en-US + ar-EG i18n; **remove the «اثبات الإيراد» radio + control from the Properties form** (Q13: `property-main-form` html:395, ts:106, `properties.service.ts:154`) | `projects\property-manager\src\app\modules\property-import\**`, `modules\properties\**`, `property-manager\src\app\routes.ts`, `src\assets\i18n\{ar-EG,en-US}\property-manager.json` | `front-verify-build` green (`npm run testing` exit 0, no new errors over the baseline) | 7 | F |
| 9 | **End to end** on a tenant via `local-api-run` (PropertyManager on base + 800, front on 4200 + 800): test workbook `CR-125487 - Test Import.xlsx` in this folder; AC-1…AC-10 (from v2) plus a create + edit on the Properties screen without «اثبات الإيراد», with screenshots and SQL proof in `test-results.md` | vault | every AC passes; results in `test-results.md` | 1, 5, 8 | G |
| 10 | **Review** (the engineer runs `/review-code 125487`) | — | review passes, 0 block rows | 1–9 | — |
| 11 | **Cleanup** (`remove-redundant`) + gates green | — | gates green | 10 | — |

**Phase 4, `PropertyImportValidator`:**
- loads the lookups once per file
- resolves cells by name ar/en/code, Arabic-normalised
- copies the project fields (Q8)
- builds `PropertyPoco` and calls `Property.Create`
- re-runs the handler's checks: ownership, sales org ↔ user; a project with no currency is a row error
- import-only rules:
  - add-only number
  - number / name / second name unique against the DB and the file, with the first line named
  - leaf project
  - investment type ∈ the project's types
  - sale price > 0 for بيع
  - parent in the same project or on an earlier line
  - number formats (Q5)

**Phase 4, `ImportPropertiesCommand`:**
- re-validates the rows
- one transaction, file order
- saves per row with `GetNextPropertyCode(parent)` and `SaveChanges`, so a later row can reference an earlier one's id
- writes the log row
- returns N / K

**Phase 8, front module:**
- shell + step bar + "addition" note + last-result message with «فتح العقارات» → `Properties`
- file group + summary bar
- buttons «استيراد الصفوف الصالحة (N)» and «تحميل ملف الأخطاء»
- 3 tabs: row review with a status filter; template columns; import log
- template and error file built with `exceljs`; parsing with `xlsx` by column position
- a 1000-row / 5 MB guard

**Parallelism (depends-on column):**
- Wave A: phases 1 and 2 together. Phase 1 (DB) is independent of all the code.
- Then 3 → 4.
- Wave D: 5 and 6 in parallel.
- Then 7 → 8 → 9.
- Phase 9 needs the DB on the test tenant: `db-change` / `publish-db.ps1 -Id cr125487`, a targeted script for the new table + module row, with the engineer's OK on the tenant.
- Before phase 8: `npm install` in `D:\Hadaf\worktrees\cr125487\AccFlex_Cloud_Front\accflex-erp\` with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1`. `package.json` differs from the main checkout, so `node_modules` was not linked.

## Risks

- **`Property.cs:200`** sets `PropertyInvestmentType.PropertyId` to the project id. The screen works, presumably because EF fixes the FK on add. Phase 5 asserts the import's rows; if it is wrong, the fix is one line and in scope, because the import depends on it.
- **The serial generator reads the DB**, so the import saves per row inside one transaction. Two imports at the same moment could clash on `UQ_Pm_Properties_PropertySerial`; the transaction rolls back and the user retries. Acceptable for a setup tool.
- **Name matching across languages.** Two rows with the same name are reported as ambiguous, never guessed.
- **Module 935** must appear in the misc API module list (`getAllUserModules`, from `Acc_Module`) for the route guard. Phase 1 covers it; phase 9 verifies it.
- **Merge with CR-125486 / CR-125488:** adjacent new lines in `Module.cs`, `0002_Acc_Module_Data.sql`, `WebMenuItem.cs` and `routes.ts`, plus the identical blank-model guard (125488) and `ProjectInfoDto` / `onProjectChanged` (125486's project-side removal). Resolved by hand by whichever branch lands second.
- **Column drop = data loss** on every tenant (accepted in CR-125486 Q11). The stage dacpac publish stops under `BlockOnPossibleDataLoss` unless the profile allows it; phase 1 records how stage applies it.

## Phase status

| # | Status | Notes |
|---|---|---|
| 1 | done | `Pm_PropertyImportLog` + sqlproj; `Pm_Properties` column made `INT NULL` + FK dropped (Q14; it was first dropped, then changed per the engineer's answer); module row 935 (`ModuleNameForUI` = 'PropertyImport'; Acc_Module has no parent column). MSBuild: 0 errors. No view, TVF or proc reads the column. Q14 answered: no data loss, so the deployer does not block |
| 2 | done | Module 935; `PropertyImportLog` + `PropertyImportErrors`; 19 resx keys; Q12 guard; «اثبات الإيراد» removed from Property, Poco, Create/Update commands, GetById and Dto; `ProofOfIncomeAndExpensesNotFound` dropped. The API, test and client projects build with 0 errors. The full .sln fails only on the WiX installer (WiX is not installed here), so the gates build the API csproj. The grep keeps the lookup entity and `ProjectInfoDto` (CR-125486's), by design |
| 3 | done | `PropertyImportLogConfigurations` (Amenity style) and the `PropertyImportLogs` DbSet on the context and its interface. Picked up by ApplyConfigurationsFromAssembly. The API csproj builds with 0 errors |
| 4 | done | `PropertyImport\**`: DTOs, `PropertyImportValidator`, the Verify and Import commands, the paged log query. One EF `IDbContextTransaction` (`IApplicationTransaction` is commented out in Program.cs), via a new `BeginTransactionAsync` on the context. No FluentValidation (core.md). Column names come from a static ar/en pair. A project with a NULL currency is read through a scalar subquery: **unproven, phase 9 checks it**. The API csproj builds with 0 errors |
| 5 | done | `PropertyImportValidatorTests` (NUnit + Moq + FluentAssertions; a mocked async DbSet; no new package): **20 of 20 pass**. Covers AC-2 to AC-7, AC-9, AC-10, all errors per row, blank → project values, Arabic normalisation, ambiguous match, no currency. `Property.Create` stores investment types against the property. The `PropertyId = project id` line is in `Property.Update`: harmless, because EF overwrites it with the property's id before saving (checked in a separate session). Left for phase 9: the exact no-currency message, EF translation of the currency subquery, and the import save order + transaction. Review 1 row 3: phase 9 is the only proof for `ImportPropertiesCommand` (file order, parent wiring, per-row serial, rollback, log counts); an EF InMemory test is not possible without a new package and a context whose `OnConfiguring` always calls `UseSqlServer` |
| 6 | done | `PropertyImportController` (Verify / Import / GetLog; module 935; `PropertyManagerBaseController` style). `WebMenuItem` 5_2 `property-import`, plus a **new root group "5" in `WebMenuGroup.cs`** ("Projects & Properties Tools"); CR-125486 needs the same group, so expect a merge overlap. The API builds with 0 errors. Swagger on :2219 (base + 800) lists all 3 actions; saved to `worktrees\cr125487\pm-swagger.json` |
| 7 | done | clientgen produced `PropertyImportClient` (verify / import / getLog) and its DTOs; the Property DTOs no longer carry «اثبات الإيراد» (only `ProjectInfoDto` keeps it). Its dist is placed in the set's front `node_modules\property-manager.api.client` (package.json stays 1.0.108). Backup of the original: scratchpad `pm-client-1.0.108-backup`. Generated TSClient src/lock were restored in git. The front `tsc` exits 0. Review 1 row 2: regenerated again, and `TSClient/src/index.ts` is now kept in the ERP working tree (the package.json and lock files are unchanged) |
| 8 | done | `modules\property-import\**` (7 files): template, upload checks, verify, summary, import, error file, 3 tabs, «فتح العقارات»; route `property-import` (935); `PROPERTY_IMPORT` i18n ar/en; «اثبات الإيراد» radio + control removed from the Properties form. `tsc` (the app tsconfig) exits 0, and a wider check passes for every new file. Prettier passes on the new files. **Front gate** (`npm run testing`, full shell build, rerun after the Q15 fix, 2026-10-18): **EXIT 0**, bundle complete (157 s). **Q15 fixed:** `amenity-main-grid` uses `AmenityType` ids 1 / 2 instead of the strings |
| 9 | done | db-all / Sabreen_Primary (company Sabreen), 2026-10-18: AC-1…AC-10 **pass** through the real screen and API with SQL proof; see [[test-results]]. Not covered: a NULL-currency project (none in Sabreen), rollback, the downloads, a 403 without module 935 |
