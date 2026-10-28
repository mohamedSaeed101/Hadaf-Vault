---
type: facts
cr: 125562
updated: 2026-10-19
source: "[[services]]"
---

# CR-125562 — Facts: Service items (بنود الخدمات `set.services`)

- **ADO:** Change Request 125562, created by the agent at the engineer's explicit request (2026-10-19). Fields copied from sibling CR 125488 (area `3- Customer Issues`, Program Property Manager, customer نواصى العقارية, version 7.0.82.x, due 2026-11-01). Assigned back to Mohamed Saeed (ADO rules had set Hassan Eldarwany). State In Development.
  https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125562
- **Merge Desk:** ticket #12554: Beta, Acknowledge, owner Mohamed Saeed, repos API / WebContainer / Database, contract change on. Components Database / Property Manager / Web Container, added by hand at the engineer's ask. Branch `cr125562` on origin in all three (= Master_Stable tip).
- **Set:** `D:\Hadaf\worktrees\cr125562\` (db, erp, front), port offset **1100**. Front `node_modules` is not linked: run `npm install` with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1` before the front phase.
- **Source:** [[services]] (the only source). No attachments.

## Scope (one source per point: [[services]])

1. New screen «بنود الخدمات» under إعدادات العقارات › البيانات الأساسية للعقارات. (§الوصول والتدفق)
2. Fields: code (required), Arabic name (required), English name (optional), default annual value (money, default 0), VAT-subject (default yes), active (default yes). (§الحقول 1–6)
3. Grid: code, item, default annual value, VAT, lease contracts, active. (§أعمدة القائمة)
4. BR-1 unique code. BR-2 no delete when used in a lease contract (deactivate instead). BR-3 inactive items hidden in new-contract pickers.
5. Buttons: save, delete (only when unused).
6. AC-1 a 3,600 annual item on a quarterly contract → a 900 service line with every rent installment. AC-2 a non-VAT item → a 0% VAT line.

## Code facts (scout, 2026-10-19)

- **No service-item entity exists** anywhere in PM cloud (no `Pm_Service*` table or `ServiceItem` class).
- **No lease / rent contract exists in the cloud**, on Master_Stable or on Stage_Beta: no aggregate, table, controller or Angular module. The «بنود الخدمات» tab, the installment spread (AC-1), the VAT line (AC-2), the «عقود الإيجار» count and the BR-2 usage check have **no data source** today.
- **Template to copy: ContractClause** (cr125483, on Stage_Beta, not yet on Master_Stable). It has the same shape: Code unique NVARCHAR(50), NameAr(200), NameEn(200) NULL, audit columns, RowVer.
  - DB: `dbo\Tables\Pm_ContractClause.sql` with `UQ_Pm_ContractClause_Code`.
  - Logic: `PropertyManager.Logic\ContractClauseAggregate\` (entity with static Create / Update returning Result, plus Error and Poco).
  - Data: `EFConfigurations\ContractClauseConfigurations.cs`, and the DbSet on `PropertyManagerContext` and `IPropertyManagerContext`.
  - Application: `ContractClauses\Commands\{Create,Update,Delete}`, `Queries\GetContractClauseById`, `Queries\SearchContractClauses`.
  - API: `ApiControllers\ContractClauseController\ContractClauseController.cs` (ModuleId; Add / Edit / Delete / View policies).
  - Front: `modules\contract-clauses\` (shell + list + form + data service + constants; a `dx-data-grid` list with a separate form).
- **Module ids:** 931–936 and 940–946 are claimed on Stage_Beta and the open cr/fx branches. The engineer's rule (2026-10-19) is that PM ids come after 943, so **947** is the next free one. The C# constants are in `Shared\SharedKernel.Logic\Modules\Module.cs`, and the row in `Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` follows row 934/935 («البيانات الأساسية للعقارات», category 14).
- **Menu** is backend C#: `PropertyManager.Application\MenuList\WebMenuItem.cs` and `WebMenuGroup.cs`.
  - 5_1_1 (InstallmentPlans, cr125402), 5_1_2 (ContractClauses, cr125483) and 5_1_3 (Furnishing, cr125491) are taken, so the next free item is **5_1_4**.
  - Master_Stable has no group "5" / "5_1"; they exist only on Stage_Beta.
  - **Stage_Beta's `WebMenuGroup.cs` declares `PropertyBasicData` and `PropertySettings` twice**, a merge artifact of cr125402 + cr125483. Two fields with the same name do not compile, so check the Stage_Beta build; it is not this CR's to fix.
- **VAT:** PM has no VAT code. Country VAT is `SharedKernel.Logic\CountryAggregate\CountryTax.cs` (`TaxPercentage`, whole percent). PM's context has no CountryTax DbSet. See [[sales-vat-rate-resolution]] for the fraction vs whole-percent trap.
- **Client:** TSClient is regenerated with Client.Generator at release, then the `property-manager.api.client` pin in Front is bumped (see [[cr-125487-import-units]] for the empty-package trap on pipeline 684).
- **Rule files:**
  - ERP `CLAUDE.md` and `.claude\rules\` (accflex-erp-api, -core, -data, -domain, core, test-doubles-and-baselines).
  - DB `CLAUDE.md` and `.claude\rules\` (db-rules, sqlproj-registration).
  - Front `CLAUDE.md` and `.claude\rules\` (accflex-erp, api-clients, feature-data-service, feature-form-service-pattern, feature-simple-with-search-component, feature-with-search-grid, permissions-and-drawer).
