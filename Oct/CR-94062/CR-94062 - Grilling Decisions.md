---
type: grilling-decisions
cr: 94062
status: answered
created: 2026-10-07
tags: [cr, cr-94062, decisions, open-questions]
---

# CR-94062 — Decisions and open questions

> [!info] Self-grilled against [[CR-94062 - Source]], the code (explorer reports, 2026-10-07) and `accflex-docs/Logistics/Sales Cycle/Customer`. Each question carries the recommended answer the plan assumes. Answers from the PO replace them.

## Settled by the code (no question needed)

| # | Decision | Evidence |
|---|---|---|
| D1 | Beneficiary type is stored as `Saf_BankGuarantee.ApplicationId`; Logistics uses **12**, already defined on web (`ApplicationType.Logistics`), desktop (`AccApplicationsList.Logistics`) and front (`ApplicationsEnum.Logistics`). | `CashControll.Logic\Common\ApplicationType.cs:21`, `NetAccounting.BLL\AccApplicationsList.cs:82` |
| D2 | **No schema change.** `Vw_TreasuryCustomers`, `Saf_GetCustomerById` and `Saf_GetCustomersListForReport` already return Logistics customers (app 12, AR = `Lgx_Customer.InvoiceAccountId`). | `dbo\Views\Vw_TreasuryCustomers.sql:62-75` |
| D3 | "Active only" is already enforced: the view takes `Lgx_Customer.Active = 1` with at least one sales organization. | same view |
| D4 | Liquidation account = the Logistics customer's `InvoiceAccountId` (receivable). Web reads it from the view's `CustomerAccountId`; desktop reads `CustomerForListDto.CustomerAccountId` from the CashControl API. | `CloseOrCashBankGuaranteeCommand.cs:99-108` |
| D5 | New additional permission **500 "Logistics Customers / عملاء خدمات لوجستية"** on module 419, added **inside** `0003_Acc_ModulePermission.sql` (its MERGE deletes rows not in source, so a post-script would be wiped). | `0003_Acc_ModulePermission.sql:287-290, 491` |
| D6 | Desktop loads Logistics customers through the CashControl API (`GetCustomerByApplicationTypeForWebAsync(12, …)`), the pattern already used by the receivable bank transfer; there is no NetTiers entity for `Lgx_Customer`. | `frmReceivableBankTransfer.Api.cs:268-277` |
| D7 | Fix two web bugs the new type exposes: Search resolves names by `CustomerId` only (ids collide across modules once 12 is added), and Create/Update compare `Accounts.GetHashCode()` instead of `ApplicationId`. | `SearchBankGuranteeQuery.cs:110`; `CreateBankGuaranteeCommand.cs:119,147`; `UpdateBankGuaranteeCommand.cs:128,157` |
| D8 | Licence gate: web hides the type when the tenant has no Logistics product (`AccApplicationLicense` / `ProductLicenseFilter`); desktop uses `Program.HasLogistics`. | `SharedKernel.Logic\AccApplication\AccApplicationLicense.cs`; `frmUserLogin.cs:471-473` |
| D9 | Deleting a Logistics customer that has an LG is refused (ticket "النقاط اللي هتتأثر"). No central "is used" hook exists, so a check goes into the Logistics `DeleteCustomerCommand`. | `DeleteCustomerCommand.cs:58-69` |

## Questions: answered by the engineer 2026-10-07; recommended answer accepted for Q1–Q4, Q5 default

- [x] **Q1 — Sales-org scoping.** Does the user see all active Logistics customers, or only those on their own sales organizations?
  **Recommended: all active Logistics customers, filtered by the bank's branch like the other customer types.** Construction customers aren't scoped by sales org today; scoping would be a new rule. *Blocked on: PO.*
- [x] **Q2 — Web Inventory / Real-estate.** Do we also switch on Inventory and Real-estate customers on web?
  **Recommended: no — Logistics only; the others stay a separate CR** (they need their own customer-view checks). *Blocked on: PO.*
- [x] **Q3 — Branch rule.** Must the customer's account branch match the bank branch?
  **Recommended: keep today's behaviour** — the front filters the customer list by bank branch, and the backend does not validate. Desktop gets the same filter through `bankBranchIds` in the API call. *Blocked on: PO (only if a hard backend check is wanted).*
- [x] **Q4 — Desktop permissions for the existing types.** Permissions 286-289 exist, but desktop never enforces them. Do we enforce all of them now, or only the new Logistics permission?
  **Recommended: enforce only 500 (Logistics) on desktop.** Enforcing 286-289 would suddenly hide types from existing desktop users; raise that separately. *Blocked on: PO.*
- [x] **Q5 — Desktop report type list** has no "Accounts" entry today. Do we add Logistics only?
  **Recommended: add Logistics only.** *Blocked on: none (default applies).*
