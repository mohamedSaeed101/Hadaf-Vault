---
type: plan
cr: 125488
size: L
updated: 2026-10-18
status: plan gate passed 2026-10-18 (engineer: "Yes to the plan. Run the phases."); depends-on column confirmed; implementing. No commits until the engineer says so (standing rule).
---

# CR-125488 — Plan: Bulk generate properties (توليد العقارات)

- **Set:** `D:\Hadaf\worktrees\cr125488\` (branch `cr125488`, base `Master_Stable`, port offset **900**). Front `node_modules` is **not** linked (package.json differs): `npm install` with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1` before phase 7.
- **Spec and decisions:** [[spec]], [[decisions]] (source [[bulk Units V2]]), [[business-check-1]], [[business-check-2]].
- **Size: L.** Evidence:
  - 3 repos (DB, Cloud_ERP, Front)
  - a new API contract (3 actions) and a new screen with an editable grid
  - new behaviour (pattern generation, all-or-nothing batch create)
  - about 22 files expected; DB is one reference-data row, no schema change
- **Siblings:** CR-125486 (module 934) and CR-125487 (module 935), same menu group, not implemented. Shared only by adjacent lines and the identical blank-model guard (Q9).

## Rules each phase follows

- **CE** (`AccFlex_Cloud_ERP\CLAUDE.md`, `.claude\rules\accflex-erp-api.md`, `accflex-erp-core.md`, `accflex-erp-domain.md`, `accflex-erp-data.md`, `core.md`, `datetime-clock.md`, `test-doubles-and-baselines.md`):
  - controllers call MediatR only; `IHaveModulePermission` with `ModuleId` 936 and policies on every action
  - `Result`, no exceptions; resx ar + en + Designer for every message
  - one transaction for the save; lookups and existing numbers loaded once per request (no N+1)
  - `Property.Create` / `ValidateProperties` stay the single source of the domain rules
- **DB** (`AccFlex_Cloud_Database\CLAUDE.md`, `.claude\rules\db-rules.md`, `sqlproj-registration.md`, `prescript-no-ddl.md`):
  - the module row is reference data in `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` (re-runs every deploy); no table, no pre/post script
- **FE** (`AccFlex_Cloud_Front\CLAUDE.md`, `.claude\rules\core.md`, `accflex-erp.md`, `feature-data-service.md`, `feature-without-search.md`, `api-clients.md`, `permissions-and-drawer.md`, `template-bound-getters.md`):
  - NgModule; the generated client, never hand-edited; en-US + ar-EG `property-manager.json`; route `data: { ModuleId: 936 }`
  - theme-aware colours through the CSS vars, not Tailwind light-only colours (memory: Cloud Front theming)
- **Templates to copy:**
  - backend: `CreatePropertyCommand.cs:100-265` (lookups, poco, `Property.Create`, save, duplicate-name mapping)
  - front grid with cell editing: `projects\property-manager\src\app\modules\payment-terms\`
  - front per-row status grid: `projects\logistics\src\app\modules\material-import\`

## Phases

| # | Phase | Files | Done when | Depends on | Wave |
|---|---|---|---|---|---|
| 1 | **DB:** module row **936** in `0002_Acc_Module_Data.sql` (copy the 851 row; «توليد العقارات» / "Bulk Generate Properties", group «أدوات المشاريع والعقارات» / "Projects & Properties Tools") | `AccFlex_Cloud_Database\...\Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` | VS 2022 MSBuild of the sqlproj: 0 errors | — | A |
| 2 | **Shared + Logic:** `Module.PropertyManagerPropertyBulkGeneration` (936, app 14, parent 67) in `Module.cs`; the Q9 guard at `Property.cs:119` and `:220`; resx keys ar + en + Designer (BulkCodeEmpty, BulkCodeDuplicatedInGrid, BulkAreaMustBePositive, BulkFloorEmpty, BulkNegativePrice, BulkGarageCodeExists, BulkSelectLeafProject, BulkProjectHasNoCurrency, BulkGarageAreaRequired, BulkGarageTypeRequired, BulkSerialConflict, BulkTooManyRows, BulkRowsHaveErrors, BulkNothingToCreate) | `CE\Shared\SharedKernel.Logic\Modules\Module.cs`, `PropertyManager.Logic\PropertyAggregate\Property.cs`, `PropertyManager.Logic\Resources\Resource*.resx`, `Resource.Designer.cs` | `dotnet build PropertyManager.sln` exits 0 | — | A |
| 3 | **Application** `PropertyManager.Application\PropertyBulkGeneration\`: DTOs (`BulkPropertyPatternDto`, `BulkPropertyRowDto`, `BulkPropertyRowResultDto` with status + messages); `BulkPropertyRowChecker` (shared by verify and save: request checks incl. project currency, per-row checks in the spec's order with exists → skip before the garage check, poco build with project inheritance and lowest-id investment type, `Property.Create` without saving); `GetLeafProjectsForBulkGenerationQuery` (Id, ProjectNumber, names, investment type ids, no children); `VerifyBulkPropertiesCommand`; `CreateBulkPropertiesCommand` (one transaction, per unit save, garage with `GetNextPropertyCode(unit)`) | `PropertyManager.Application\PropertyBulkGeneration\**` | build exits 0 | 2 | B |
| 4 | **Unit tests** (list in [[spec]] §Testing: A3–A8, A10, A11, every message, inheritance (blank activity → project activity), garage type / area / price incl. Q15 negative cases, investment type + price 0, sales-org check, 500 limit, leaf project, all-or-nothing) | `PropertyManager.Application.Test\PropertyBulkGeneration\*Tests.cs` | `dotnet test PropertyManager.Application.Test --filter PropertyBulkGeneration` passes; the rest unchanged vs baseline (65 DB-backed failures are known noise) | 3 | C |
| 5 | **API:** `PropertyBulkGenerationController` (`api/PropertyBulkGeneration`: `GET LeafProjects`, `POST Verify`, `POST`), ModuleId 936, policies, `ProducesResponseType`, XML docs; `WebMenuItem` entry → route `property-bulk-generation` | `PropertyManager.API\ApiControllers\PropertyBulkGenerationController\PropertyBulkGenerationController.cs`, `PropertyManager.Application\MenuList\WebMenuItem.cs` | build exits 0; the API starts on base port + 900 and Swagger lists the 3 actions | 3 | C |
| 6 | **API client:** regenerate `property-manager.api.client` from the phase-5 swagger, build it locally, link it into the set's `node_modules`; nothing published, the pin bump happens at release | `PropertyManager.API.Client` (generated), the set's `node_modules` | `PropertyBulkGenerationClient` types resolve in the front `tsc` | 5 | D |
| 7 | **Front:** module `projects\property-manager\src\app\modules\property-bulk-generation\` (pattern form, `buildRowsFromPattern` pure function, summary line, dirty flag + rebuild warning, DevExtreme grid with cell editing / create checkbox / delete / add row, debounced verify, save → «تم إنشاء N عقار» → `Properties`; «استيراد العقارات» button gated on module 935); route in `routes.ts`; «توليد عقارات» button in `property-search` gated on 936; i18n ar-EG + en-US | `property-bulk-generation\**`, `property-manager\src\app\routes.ts`, `modules\properties\components\property-search\*`, `src\assets\i18n\{ar-EG,en-US}\property-manager.json` | `front-verify-build` green (`npm run testing` exit 0, no new errors over the baseline, prettier clean) | 6 | E |
| 8 | **End to end** on a tenant via `local-api-run` (PropertyManager on base + 900, front 4200): A1–A11 with screenshots and SQL proof (`PropertyNumber`, `PropertySerial`, `ParentPropertyId`, `NoOfFloor`, `PropertyPrice`) in `test-results.md`; the module row published to the tenant with the engineer's OK (`db-change`) | vault | every A passes; results in `test-results.md` | 1, 4, 7 | F |
| 9 | **Review** (the engineer runs `/review-code 125488`) | — | review passes, 0 block rows | 1–8 | — |
| 10 | **Cleanup** (`remove-redundant`) + gates green | — | gates green | 9 | — |

**Parallelism (depends-on column):**
- Wave A: phases 1 and 2 together (DB is independent of all the code).
- Wave B: 3.
- Wave C: 4 and 5 in parallel.
- Then 6 → 7 → 8.

## Risks

- **Serial under load:** `GetNextPropertyCode` reads MAX from the DB, so the save is per unit inside one transaction; a parallel create can hit `UQ_Pm_Properties_PropertySerial`, the transaction rolls back and the user retries. Acceptable for a setup tool (same as CR-125487).
- **Serial scheme (Q14):** a garage serial (parent + `01`) can equal a later root serial; the UQ failure rolls the batch back with «تعارض في كود العقار» and must never surface as the name-duplicate message (`CreatePropertyCommand` maps every `Duplicate` to it today, so the bulk handler maps its own).
- **Exists check is best effort:** `PropertyNumber` has no DB constraint; two simultaneous generations of the same codes both insert. Accepted.
- **Verify traffic:** debounced verify on every edit sends up to 500 rows; one query for the existing numbers per call keeps it cheap.
- **Merge with CR-125486 / CR-125487:** adjacent lines in `Module.cs`, `0002_Acc_Module_Data.sql`, `WebMenuItem.cs`, `routes.ts`, and the identical guard in `Property.cs`. Resolved by whichever branch lands second.
- **`Property.cs:200`** sets `PropertyInvestmentType.PropertyId` to the project id (CR-125487 risk); phase 4 asserts the rows this CR writes.

## Phase log (uncommitted; engineer's rule)

| # | Status | Notes |
|---|---|---|
| 2 | done | `Module.cs` 936 (constructor self-registers, no registry); `Property.cs:119,220` model guard; 14 `Bulk*` keys in `Resource.resx` / `Resource.en.resx` / `Resource.Designer.cs` + `PropertiesErrors.cs` enum (Resource is internal; `BulkRowsHaveErrors` via `string.Format`). Gate: `PropertyManager.sln` exits 1 only on `PropertyManager.Installer.wixproj` (WiX 3.11 not installed, environmental); all 15 csproj build with 0 errors. **Later gates build `PropertyManager.API.csproj`, not the .sln.** Encoding kept (UTF-8 BOM, CRLF) |
| 1 | done | `0002_Acc_Module_Data.sql` +1 row 936 (`ProjectsAndPropertiesTools`, Arabic group «أدوات المشاريع والعقارات», UI name "Bulk Generate Properties"); the table has no parent or English-group column, same as 851. BOM + CRLF kept, 1 insertion. Gate: VS 2022 Community MSBuild of the sqlproj exit 0, 0 errors |
| 3 | done | New `PropertyBulkGeneration\`: `BulkPropertyDtos.cs`, `BulkPropertyRowChecker.cs` (request checks, rows in spec order, lookups + existing numbers once per request, `Property.Create` unsaved, ProofOfIncome=1 one marked line), `GetLeafProjectsForBulkGenerationQuery.cs`, `VerifyBulkPropertiesCommand.cs`, `CreateBulkPropertiesCommand.cs` (one tx, unit then garage `GetNextPropertyCode(unit)`, Duplicate → BulkSerialConflict). Assumptions for review: ModuleId only on controllers (phase 5); checker built with `new` (no DI edit); tx via `ICurrentDbContext` (no IApplicationTransaction in PM); `Project.CurrencyId` is non-null int so "no currency" = id not found / ≤ 0; field-error rows stay Error even if the code exists. Gate: `PropertyManager.API.csproj` build exit 0 |
| 5 | done | `PropertyBulkGenerationController` (`GET LeafProjects` View, `POST Verify` Add (house import convention), `POST` Create Add + `refreshProperties()`), static `ModuleId` 936 like `PropertyController`; `WebMenuItem.PropertyBulkGeneration` ("5_1", route `property-bulk-generation`). Gate: API csproj build 0 errors; swagger on :2319 lists the 3 operations, saved to scratchpad `pm-swagger-125488.json` |
| 5b | done | appended: `WebMenuGroup.cs` group "5" «أدوات المشاريع والعقارات» / "Projects and Properties Tools" holding the item (the menu is built only from `RootGroup`). Gate: API csproj build 0 errors. **Merge note:** CR-125486/125487 will add the same group; whichever lands second merges the items into one group |
| 6 | done | `clientgen ./nswag.json` (house pattern, from the Release API DLL); TS package built in scratchpad (`pmclient-build\dist`) and **copied** into the set `node_modules\property-manager.api.client` (old 1.0.108 backed up at scratchpad `pm-client-1.0.108-backup`). Regenerated `TSClient\src\index.ts` had whitespace churn + unrelated drift (`postPaymentTerm`→`createPaymentTerm`, `updatePaymentTerm`, `getAmenityTypes`) so the **repo file was restored**; the generated copy is in scratchpad `pm-client-index-125488.ts` for `release-ticket` (regen + pin bump happen there). Gate: scratch `tsc --noEmit` importing the new types exit 0 |
| 4 | done | 65 tests (41 verify, 23 create, 1 leaf query) in `PropertyManager.Application.Test\PropertyBulkGeneration\` + `BulkScenario.cs`; adds `MockQueryable.Moq` 7.0.3 to the test csproj (not named in the plan; testing standard recommends it). Mocks, not EF InMemory (PropertyManagerContext forces SQL Server in OnConfiguring). All-or-nothing proven as rollback-called / commit-never; zero rows left needs phase 8 on a real DB. No defects found. Gate: `dotnet test ... --filter FullyQualifiedName~PropertyBulkGeneration` 65 passed, 0 failed |
| 7 | done | New `property-bulk-generation\` module (shell, `bulk-pattern-form`, `bulk-rows-grid`, pure `build-rows-from-pattern.ts`, data service, `user-can-view-module.ts`); route 936 in `routes.ts`; «توليد عقارات» button in `property-search` (module 936); `PmBulkGeneration` i18n ar-EG + en-US. Verify via switchMap + 400 ms debounce, skipped when invalid / > 500 / empty; save needs NewUnits > 0 and Errors = 0. Gate: `npm run testing` exit 1 **before and after** on the same 2 pre-existing errors (client drift, Q17), 0 new; prettier clean (`--end-of-line auto`); `buildRowsFromPattern` node check A1/A2 OK. Review note: each verify POST shows the global loading overlay (house interceptor) |
| 8 | done | 2026-10-19 on db-all / Sabreen_Primary: module row 936 inserted (guarded), A1–A11 pass, BR-3 + Q15 + menu 5_3 verified; 22 rows created (11 units + 11 garages). Two UI nits for the review (code-pattern input needs dir=ltr; grid overflows with the warning line). Details: [[test-results]] |
| 5c | done | 2026-10-19, engineer-approved alignment with shipped CR-125487 / CR-125486: `Module.cs` 936 category `Projects & Properties Tools`; `WebMenuGroup` "5" text `Projects & Properties Tools` (same line as the siblings; only the item list differs); `WebMenuItem` id **5_3** (5_1 = project import, 5_2 = property import); DB row 936 category columns `Projects & Properties Tools` and UI name `PropertyBulkGeneration`. Encoding kept; diffs still additions only. Gates: 65/65 bulk tests pass, API csproj 0 errors, sqlproj exit 0 |
