---
type: implementation-plan
cr: 94062
title: Logistics customers as a beneficiary type in Letters of Guarantee (web + desktop)
customer: تطوير داخلى
status: planned — awaiting plan gate
created: 2026-10-07
size: L
branch: cr94062
base: Master_Stable
stage: Stage_Beta
mergedesk_version: Beta
repos:
  - AccFlex_Cloud_Database
  - AccFlex_Cloud_ERP
  - AccFlex_Cloud_Front
  - AccFlex_ERP
tags: [cr, cr-94062, plan, cashcontrol, bank-guarantee, logistics]
---

# CR-94062 — Logistics customers in Letters of Guarantee

> [!info] Sources
> Ticket facts: [[CR-94062 - Source]] · Decisions and open questions: [[CR-94062 - Grilling Decisions]] · Mock-up: https://claude.ai/artifact/3Z39vqa9JYvnzQm1ybhDve#cr94062

> [!warning] Plan gate
> Size **L** (4 repos, desktop + web, a permission seed, report SQL). Q1–Q4 were answered on 2026-10-07: the recommended answers were accepted. Implementation starts only after the engineer approves this plan.

**Goal:** On the LG screen (web and desktop), let the user pick "عملاء اللوجستيك" as the beneficiary type and choose an active Logistics customer. Liquidation, the report, search and print must all work with it, behind a new additional permission and the Logistics licence.

**Why it is smaller than it looks:** the database already exposes Logistics customers to Cash Control (`Vw_TreasuryCustomers`, app 12, AR = `InvoiceAccountId`). So the work is mostly wiring the new type in. **No schema change, and no API contract change**, so no NSwag regeneration is needed (decisions D1, D2).

## Size evidence

| Signal | Value |
|---|---|
| Repos | 4: Database, Cloud_ERP (CashControl, Logistics, AnalyticsReader), Front, AccFlex_ERP |
| Files | about 25 (DB 3, backend about 9, AnalyticsReader 1, front 2-3, desktop about 9) |
| DB | reference data (permission 500) plus two report objects (function + view). No table change. |
| Behaviour | a new type through create, every transaction, liquidation, search, report, print and delete-guard |

## Global constraints (rules followed)

- **DB** (`AccFlex_Cloud_Database\CLAUDE.md`, `.claude\rules\prescript-no-ddl.md`): no DDL in Pre/Post scripts. The permission row is added to the reference-data MERGE `0003_Acc_ModulePermission.sql`, which is edited in place. Build with VS 2022 MSBuild, never `dotnet build`.
- **Backend** (`AccFlex_Cloud_ERP\CLAUDE.md`, `.claude\rules\*`):
  - MediatR-only controllers, `Result` over exceptions.
  - New errors in `BankGuaranteeErrors` with ar/en `.resx` entries.
  - Build `-c Release` (VS locks Debug).
  - `CashControl.Logic.Test` has 65 pre-existing failures across the solution. Compare against the baseline, not against zero.
- **Front** (`AccFlex_Cloud_Front\CLAUDE.md`):
  - Type names come from the API, so no new i18n keys are expected.
  - If one is needed, add it to both `ar-EG` and `en-US` `general-accounting.json`, and grep first for duplicates.
  - Gate: `front-verify-build`.
- **Desktop** (no `AccFlex_ERP\CLAUDE.md`; workspace rules):
  - VS MSBuild, serial build (no `/m`), and junction `References` into the worktree.
  - Editing `dsBankGurantee.xsd` means editing `dsBankGurantee.Designer.cs` to match.
  - `CashControl.API.Client` 1.0.1000 already has `GetCustomerByApplicationTypeForWebAsync`, so no package bump is needed.
- **Karpathy 3 (surgical changes):** only the two bugs the new type exposes are fixed (D7). Other pre-existing issues are listed under "Noticed, not fixed".

## Phase table

| # | Phase | Repo | Files | Done-when | Depends on | Wave |
|---|---|---|---|---|---|---|
| P1 | **DB: permission + report SQL.** Add `(500, N'Logistics Customers', N'عملاء خدمات لوجستية', 419)` to the permission MERGE. Add `UNION ALL SELECT CustomerId, CustomerName, 12 FROM dbo.Lgx_Customer` to the `Customers` CTE in the report function and the print view. Regenerate `RunReferenceDataScriptsGenerated.sql` if the repo's process requires it. | Database | `Scripts\ReferenceDataScripts\0003_Acc_ModulePermission.sql`, `dbo\Functions\Saf_Rpt_BankGuaranteeReport.sql`, `dbo\Views\Vw_Saf_BankGuaranteePrint.sql` | MSBuild of the `.sqlproj` exits 0. A local publish preview shows only these objects. | — | 1 |
| P2 | **Backend: the new type in CashControl.**<br>• Add `LogisticsCustomers (12, "عملاء خدمات لوجستية", "Logistics Customers", 500, 419)` to `BankGuaranteePayeeType` and `GetBankGuaranteeList()`.<br>• Add `ApplicationType.Logistics.Id` to `appList` in `GetCustomerOrAccountQuery`.<br>• Licence filter in `GetBankGuaranteePayeeTypeQuery`: drop the type when the tenant has no Logistics product.<br>• Same guard in Create/Update: reject app 12 without the licence, with a new `BankGuaranteeErrors` entry and ar/en resx text.<br>• D7 fixes: `GetHashCode()` → `.ApplicationId` in Create/Update, and the Search name lookup keyed on `(ApplicationId, CustomerId)`. | Cloud_ERP / CashControl | `CashControll.Logic\BankGuaranteeAggregate\BankGuaranteePayeeType.cs`, `BankGuaranteeErrors.cs`, `Resources\Resource*.resx`, `CashControl.Application\BankGuarantees\Query\GetCustomerOrAccount\GetCustomerOrAccountQuery.cs`, `...\GetBankGuaranteePayeeType\GetBankGuaranteePayeeTypeQuery.cs`, `...\SearchBankGurantee\SearchBankGuranteeQuery.cs`, `...\Command\CreateBankGuarantee\CreateBankGuaranteeCommand.cs`, `...\UpdateBankGuarantees\UpdateBankGuaranteeCommand.cs` | `dotnet build CashControl.sln -c Release` passes. P7's tests pass. | — | 1 |
| P3 | **Logistics delete guard.** `DeleteCustomerCommand` refuses to delete a customer when a `Saf_BankGuarantee` row has `ApplicationId = 12 AND CustomerId = @id`. Add an ar/en error. Use a read-only query that reaches `Saf_BankGuarantee` (mapped keyless entity or `SqlQuery`), following the Logistics rule files. | Cloud_ERP / Logistics | `Logistics.Application\Sales\Customers\Commands\DeleteCustomer\DeleteCustomerCommand.cs`, Logistics errors + resx, a context mapping if needed | `dotnet build Logistics.sln -c Release` passes. A unit test shows delete is refused when an LG exists. | — | 1 |
| P4 | **AnalyticsReader report header.** In `BankGuaranteeAng`, the application header handles Logistics, and customer names resolve per `ApplicationId`. Today they resolve from `Lgx_Customer` for every type, which is wrong for Construction: fix that only because this exact code has to change for Logistics anyway. | Cloud_ERP / AnalyticsReader | `AnalyticsReader.Api\AngularReports\CashControl\BankGuaranteeAng\BankGuaranteeAng.cs` | `dotnet build -c Release` passes. The report header shows the right Logistics customer name on a tenant. | P1 | 2 |
| P5 | **Front.**<br>• Report component: Logistics in `onApplicationIdChanged`, in the customer-required check and in the default ids.<br>• Form: changing the type clears the customer (check it already does), the "اختار العميل" message, and app 12 under the existing branch rule (Q3).<br>• Search shell: Logistics customers when type 12 is picked. | Front / cash-control | `projects\cash-control\src\app\modules\bank-guarantee-report\components\bank-guarantee-report\bank-guarantee-report.component.ts`, `modules\bank-guarantee\shared\Bank-Guarantee.form.service.ts`, `container\bank-guarantee-search-shell\*.ts` | `front-verify-build` is green (no new errors against the baseline). Browser check on a local API is in P8. | P2 | 2 |
| P6 | **Desktop LG screen.**<br>• Add radio item `12 = عملاء اللوجستيك` (Designer + resx + ar-EG resx).<br>• Remove it when `!Program.HasLogistics` or the user lacks extra permission 500 (pattern: `frmRecievableBankTransfer.SetCustomerType`).<br>• In the `rdTransferType_SelectedIndexChanged` case 12, load customers via `_customerClient.GetCustomerByApplicationTypeForWebAsync(12, …, bankBranchIds, lang)`.<br>• Search button: use `frmCustomerSearch_New` for 12.<br>• `btnCash_Click`: take `CustomerAccountId` from `CustomerForListDto` for 12. Today the `as ICustomer` cast would return null.<br>• Changing the type clears the customer.<br>• Add enum `AccModulePermissionList.Bank_Guarantee_Logistics_Customers = 500`. | AccFlex_ERP / CashManagement | `AccountingSafe\BankGuarantee\frmBankGuarantee.cs`, `.Designer.cs`, `.resx`, `.ar-EG.resx`, `GeneralAccounting\NetAccounting.BLL\AccModulePermissionList.cs` | Serial MSBuild of `CashManagement.sln` passes. The manual desktop check is in P8. | P1 (permission id) | 1 |
| P7 | **Desktop report.**<br>• Add Logistics (12) to `BankGuaranteeReportApplicationList`.<br>• Add a case 12 to the customer switch in `frmBankGuaranteeReport`, loading via the API.<br>• Add `UNION ALL … Lgx_Customer, 12` to both CTEs in `dsBankGurantee.xsd` and in the matching `.Designer.cs` SQL. | AccFlex_ERP / CashManagement | `BankGuarantee\BankGuaranteeReportApplicationList.cs`, `BankGuarantee\Reports\frmBankGuaranteeReport.cs`, `Reports\dsBankGurantee.xsd`, `dsBankGurantee.Designer.cs` | Serial MSBuild passes. The single print and the report print a Logistics customer's name. | P6 | 2 |
| P8 | **Tests + end-to-end check.**<br>• NUnit in `CashControl.Logic.Test`: the payee list includes Logistics; customer required for 12; permission 500 enforced in `ValidateBankGuarantee`; liquidation needs the customer account.<br>• Handler tests: the Search name lookup with colliding ids across apps, and the licence filter.<br>• Check on a web-test tenant with Logistics: create, increase, decrease, extend, liquidate (journal hits the customer's `InvoiceAccountId`) and close; search; report; print; delete-guard; desktop open/liquidate. | Cloud_ERP tests + manual | `CashControll.Logic.Test\BankGuarantee*`, `CashControl.Application` tests if the project exists | `dotnet test` shows no new failures against the baseline. The checklist in "Acceptance" is all ticked, with evidence in `review-1.md`. | P2–P7 | 3 |

Waves: **1** = P1, P2, P3, P6 (independent; P6 only needs the id 500, which is fixed here) · **2** = P4, P5, P7 · **3** = P8.

## Acceptance (numbered; maps to Source scope)

1. Web and desktop show "عملاء اللوجستيك" in the beneficiary type only when the tenant has Logistics **and** the user has permission 500. (Scope 1, 4)
2. Choosing it lists active Logistics customers (code – name), searchable by code and name, filtered by the bank branch as other types are. (Scope 2, Q1, Q3)
3. Saving without a customer shows the customer-required message. Changing the type clears the customer. (UI/UX)
4. Liquidation posts to the Logistics customer's receivable account (`InvoiceAccountId`), on web and desktop. (Scope 3)
5. Increase, decrease, extend and close work for an LG of type 12, and their VAT notes name the type. (Impacted points)
6. Screen search and the LG report filter by Logistics, and show the correct customer name. Print shows the name. (Scope 5)
7. Deleting a Logistics customer with an LG is refused with a clear message. (Impacted points)
8. Tenants without Logistics see no change. (Not a breaking change)

## Noticed, not fixed (Karpathy 3)

- Desktop never enforces permissions 286-289 (Q4).
- Desktop report type list has no Accounts entry (Q5).
- Web Inventory and Real-estate types are commented out (Q2).
- There is no backend customer-branch versus bank-branch check (Q3).

## Ship notes

- Merge Desk ticket: TFS 94062, version **Beta**, repositories Database, API, WebContainer, Desktop. Components: Database, CashControl, Logistics, AnalyticsReader, Web Container. Leave them for Merge Desk to detect.
- First PR goes to `Stage_Beta`, the second to `Master_Stable`. Merge Desk opens both on Solved. Never merge `Stage_Beta` into `cr94062`.
- No API contract change, so no client regeneration.
