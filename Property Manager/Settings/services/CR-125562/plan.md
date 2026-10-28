---
type: plan
cr: 125562
updated: 2026-10-19
status: gate passed 2026-10-19. Size L.
---

# CR-125562 — Plan: Service items (بنود الخدمات)

Spec: [[spec]]. Set: `D:\Hadaf\worktrees\cr125562\` (db, erp, front), port offset 1100. Template: ContractClause (`origin/cr125483`). Copy its files by `git show origin/cr125483:<path>`, since it is not on Master_Stable. Commits go `cr125562: <phase title>`, **only when the engineer says commit** (standing rule).

| # | Phase | Files | Done-when | Depends-on | Wave | Rule followed |
|---|---|---|---|---|---|---|
| 1 | DB: table + module row | `dbo\Tables\Pm_ServiceItem.sql` (new); `AccFlex_Cloud_Database_State.sqlproj` (`<Build Include>`); `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` (row 947, shaped like 935) | VS 2022 MSBuild of the sqlproj: 0 errors ([[local-msbuild-path]]) | — | A | DB `db-rules.md`, `sqlproj-registration.md`; reference data, not a post-script ([[db-referencedata-vs-postscripts]]) |
| 2 | ERP domain + data | `SharedKernel.Logic\Modules\Module.cs` (`PropertyManagerServiceItems` 947); `PropertyManager.Logic\ServiceItemAggregate\{ServiceItem,ServiceItemError,ServiceItemPoco}.cs`; `Resources\Resource.resx` / `.en.resx` / `.Designer.cs`; `PropertyManager.Data\EFConfigurations\ServiceItemConfigurations.cs`; DbSet on `PropertyManagerContext` + `IPropertyManagerContext` | `dotnet build PropertyManager.API.csproj`: 0 errors (not the .sln: WiX) | — | A | ERP `accflex-erp-domain.md` (Result, no exceptions), `accflex-erp-data.md` |
| 3 | ERP CQRS + API + menu | `PropertyManager.Application\ServiceItems\Commands\{Create,Update,Delete}ServiceItem\*`; `Queries\GetServiceItemById\*`, `Queries\SearchServiceItems\*` (text + `IsActive` filter, paged); `PropertyManager.API\ApiControllers\ServiceItemController\ServiceItemController.cs` (ModuleId 947, policies); `MenuList\WebMenuItem.cs` (5_1_4 `service-items`), `WebMenuGroup.cs` (groups 5 / 5_1 as on Stage_Beta) | API csproj build: 0 errors; `GET api/ServiceItem/Search` in Swagger | 2 | B | ERP `accflex-erp-api.md` (MediatR-only controller, ModuleId + policies), `add-cqrs-feature` recipe |
| 4 | Tests | `PropertyManager.*Tests\ServiceItems\*` (aggregate rules, create duplicate code, update not found, delete, search active filter) | `dotnet test --filter ServiceItem`: all green | 3 | C | ERP `test-doubles-and-baselines.md`, `write-tests` |
| 5 | TS client (local) | regenerate the PM TSClient with Client.Generator into the set's `node_modules\property-manager.api.client` (the repo `index.ts` is regenerated at release) | `ServiceItemClient` exported in the local client | 3 | C | Front `api-clients.md` |
| 6 | Front screen | `property-manager\src\app\modules\service-items\` (module, shell, list, form, data service, constants); `routes.ts` (`service-items`, ModuleId 947, guards); ar/en translation keys | `front-verify-build`: no new errors vs baseline | 5 | D | Front `feature-with-search-grid.md`, `feature-simple-with-search-component.md`, `feature-form-service-pattern.md`, `feature-data-service.md`, `permissions-and-drawer.md`; theming ([[cloud-front-theming]]) |
| 7 | End to end | Sabreen_Primary: module row 947 + `Pm_ServiceItem` (cut-down script); local PM API on base + 1100; browser pane; `test-results.md` | A1–A8 pass, written in `test-results.md` | 1, 4, 6 | E | [[pm-test-tenant-sabreen]], `local-api-run` |

Waves: **A** (1, 2 in parallel) → **B** (3) → **C** (4, 5 in parallel) → **D** (6) → **E** (7). Then propose `/review-code 125562` (gate 6).

Size **L**: 3 repos, a new table, a new API contract, a new screen, about 25 files.
