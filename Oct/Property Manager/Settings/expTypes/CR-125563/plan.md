---
type: plan
cr: 125563
size: L
updated: 2026-10-19
status: plan gate passed 2026-10-19 (engineer: "Yes to the plan with all recommended answers Q1-Q11. Run the phases."); Q12 → module 948, menu 5_1_5; implementing. No commits until the engineer says so (standing rule).
---

# CR-125563 — Plan: Project Expense Types (أنواع تكاليف المشاريع)

- **Set:** `D:\Hadaf\worktrees\cr125563\` (branch `cr125563`, base `Master_Stable`, port offset **1000**). Front `node_modules` not linked (package.json differs): `npm install` with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1` before phase 7.
- **Spec:** [[spec]] (A1–A10), [[facts]], [[open-questions]], business check [[business-check-1]].
- **Size: L.** Evidence:
  - 3 repos (DB, Cloud_ERP, Front)
  - DB schema change: 2 new tables + a module row
  - a new API contract (7 actions) and a new screen
  - about 25 files expected
- **Siblings:** CR-125486/87/88 (modules 944–946) touch the same `Module.cs` / `WebMenuGroup.cs` / `0002_Acc_Module_Data.sql` lines; expect trivial conflicts.

## Rules each phase follows

- **CE** (`AccFlex_Cloud_ERP\CLAUDE.md`, `.claude\rules\accflex-erp-api.md`, `accflex-erp-core.md`, `accflex-erp-domain.md`, `accflex-erp-data.md`, `core.md`, `test-doubles-and-baselines.md`):
  - controllers call MediatR only; `ModuleId` 948 and the view / add / edit / delete policies on every action
  - `Result`, no exceptions; resx ar + en + Designer for every message
  - domain rules in the aggregate (`ProjectExpenseType.Create / Update`), DB-dependent checks (uniqueness, postings, usage) in the handlers
  - one query per concern, no N+1: counts and capitalised sums grouped in a single GL query per list call
- **DB** (`AccFlex_Cloud_Database\CLAUDE.md`, `.claude\rules\db-rules.md`, `sqlproj-registration.md`, `prescript-no-ddl.md`):
  - tables as model files under `dbo\Tables\`, registered in the sqlproj; no pre/post script (new tables, no data)
  - module row as reference data in `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql`
- **FE** (`AccFlex_Cloud_Front\CLAUDE.md`, `.claude\rules\core.md`, `accflex-erp.md`, `feature-data-service.md`, `feature-without-search.md`, `api-clients.md`, `permissions-and-drawer.md`, `template-bound-getters.md`):
  - NgModule; generated client, never hand-edited; i18n ar-EG + en-US `property-manager.json`; route `data: { ModuleId: 948 }`
  - theme-aware colours through the CSS vars (memory: Cloud Front theming)
- **Templates to copy:**
  - backend: `PropertyManager.Logic\PaymentTermAggregate\`, `PropertyManager.Application\PaymentTerms\Commands\*`, `DeletePaymentTermCommand.cs` (usage check → `ToNoModelError`), `PaymentTermController.cs`, `PropertyManager.Data\EFConfigurations\PaymentTermConfigurations.cs`
  - GL access: `IGeneralLedgerContext` as in `CreateProjectCommand.cs:69`
  - front: `property-manager\src\app\modules\amenity\` (grid + data service)

## Phases

| # | Phase | Files | Done when | Depends on | Wave |
|---|---|---|---|---|---|
| 1 | **DB:** `Pm_ProjectExpenseType` (UQ Code, UQ AssetAccountId, FKs to `Acc_Account`, defaults), `Pm_ProjectProjectExpenseType` (PK ProjectId + type id, FKs); register both in the sqlproj; module row **948** in `0002_Acc_Module_Data.sql` (copy the 856 row; «أنواع تكاليف المشاريع» / "Project Expense Types", group «البيانات الأساسية للعقارات») | `dbo\Tables\Pm_ProjectExpenseType.sql`, `dbo\Tables\Pm_ProjectProjectExpenseType.sql`, `*.sqlproj`, `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` | VS 2022 MSBuild of the sqlproj: 0 errors | — | A |
| 2 | **Shared + Logic:** `Module.PropertyManagerProjectExpenseTypes` (948, app 14, parent 67) in `Module.cs`; aggregate `ProjectExpenseTypeAggregate\{ProjectExpenseType.cs, ProjectExpenseTypeError.cs, ProjectExpenseTypePoco.cs}` (required fields, trim, asset ≠ expense, `Activate/Deactivate`); resx ar + en + Designer (ExpenseTypeCodeRequired, ExpenseTypeNameRequired, ExpenseTypeAssetAccountRequired, ExpenseTypeExpenseAccountRequired, ExpenseTypeCodeDuplicated, ExpenseTypeAssetAccountDuplicated, ExpenseTypeInvalidAssetAccount, ExpenseTypeInvalidExpenseAccount, ExpenseTypeSameAccounts, ExpenseTypeHasPostedCost, ExpenseTypeUsedInProject, ExpenseTypeAssetAccountHasPostings, ExpenseTypeAssetAccountInUse, ExpenseTypeAssetAccountNotCostCenterLinked, ExpenseTypeNotFound) | `Shared\SharedKernel.Logic\Modules\Module.cs`, `PropertyManager.Logic\ProjectExpenseTypeAggregate\**`, `PropertyManager.Logic\Resources\Resource*.resx`, `Resource.Designer.cs` | `dotnet build PropertyManager.API.csproj` exits 0 (the .sln has the WiX project) | — | A |
| 3 | **Data:** EF configurations for both tables (unique indexes mapped), DbSets in `PropertyManagerContext` and `IPropertyManagerContext` | `PropertyManager.Data\EFConfigurations\ProjectExpenseType*Configurations.cs`, `PropertyManagerContext.cs`, `Application\Common\Interfaces\IPropertyManagerContext.cs` | build exits 0 | 2 | B |
| 4 | **Application** `PropertyManager.Application\ProjectExpenseTypes\`: `CreateProjectExpenseTypeCommand`, `UpdateProjectExpenseTypeCommand` (Q7 check), `DeleteProjectExpenseTypeCommand` (carries value, then link rows); shared `ProjectExpenseTypeAccountValidator` (account exists, leaf, active, type set from Q3, `CostCenterLinked` Q8, "carries value" for Q10 = `HasTransactions` / opening debit / non-void lines; one GL read per command); queries `GetAllProjectExpenseTypesQuery` (list + projects count + capitalised sum: revised non-void debits over each project's cost centre + child centres, one grouped GL query), `GetProjectExpenseTypeByIdQuery`, `GetActiveProjectExpenseTypesQuery`, `GetProjectExpenseTypeAccountsQuery`; DTOs; duplicate-index → message mapping | `PropertyManager.Application\ProjectExpenseTypes\**` | build exits 0 | 3 | C |
| 5 | **Unit tests** (A2–A6, A8–A11, both delete messages, account-type + cost-centre-linked filters, opening-balance guard, capitalised sum: excludes void / unrevised lines, voided journals and unrelated cost centres, includes child cost centres) | `PropertyManager.Application.Test\ProjectExpenseTypes\*Tests.cs` | `dotnet test PropertyManager.Application.Test --filter ProjectExpenseType` passes; the rest unchanged vs baseline | 4 | D |
| 6 | **API:** `ProjectExpenseTypeController` (`api/ProjectExpenseType`: GetAll, {id}, GetActive, Accounts, POST, PUT, DELETE {id}), ModuleId 948, policies, `ProducesResponseType`, XML docs; menu: groups "5" «إعدادات العقارات» and "5_1" «البيانات الأساسية للعقارات» + item `5_1_5` → `project-expense-types` | `PropertyManager.API\ApiControllers\ProjectExpenseTypeController\ProjectExpenseTypeController.cs`, `PropertyManager.Application\MenuList\WebMenuItem.cs`, `WebMenuGroup.cs` | build exits 0; API starts on base port + 1000 and Swagger lists the 7 actions | 4 | D |
| 7 | **API client:** regenerate `property-manager.api.client` from the phase-6 swagger, build locally, link into the set's `node_modules`; nothing published (pin bump at release) | `PropertyManager.API.Client` (generated), set `node_modules` | `ProjectExpenseTypeClient` types resolve in the front `tsc` | 6 | E |
| 8 | **Front:** module `projects\property-manager\src\app\modules\project-expense-types\` (data service, grid with the 7 columns, popup form with 2 searchable account lookups, land / active checkboxes, save / delete with server messages); route in `routes.ts`; i18n ar-EG + en-US | `project-expense-types\**`, `property-manager\src\app\routes.ts`, `src\assets\i18n\{ar-EG,en-US}\property-manager.json` | `front-verify-build` green (exit 0, no new errors over the baseline, prettier clean) | 7 | F |
| 9 | **End to end** on Sabreen via `local-api-run` (PM API on base + 1000, front 4200): A1–A11 with screenshots and SQL proof; tables + module row published to the tenant with the engineer's OK (`db-change`) | vault `test-results.md` | every A passes | 1, 5, 8 | G |
| 10 | **Review** (the engineer runs `/review-code 125563`) | — | 0 block rows | 1–9 | — |
| 11 | **Cleanup** (`remove-redundant`) + gates green | — | gates green | 10 | — |

**Parallelism (depends-on column):**
- Wave A: phases 1 and 2 together (DB independent of the code).
- Then 3 → 4.
- Wave D: 5 and 6 in parallel.
- Then 7 → 8 → 9.

## Risks

- **Link table without a writer** (Q1): counts stay 0 until the project «التكاليف» CR. Accepted by design if Q1 = yes.
- **GL sum cost:** one grouped query over `Acc_JournalAction` filtered by the types' asset accounts; `IX` on `AccountId` exists in GL — verify the plan in phase 9 on Sabreen.
- **Menu groups 5 / 5_1** don't exist on Master_Stable; this CR adds them, as do the three sibling CRs → conflicts in `WebMenuGroup.cs` resolved by keeping one declaration.
