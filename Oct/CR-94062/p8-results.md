# CR-94062 — P8 end-to-end results (Sabreen, local APIs from cr94062)

Setup:
- APIs: Cash Control 5109, Logistics 5114, AnalyticsReader 5155, all Debug against support-db2/Sabreen.
- Front: localhost:4200 with the `localbeta` config.
- User: the engineer's test login, with extra permissions 287, 288 and 500.

| # | Acceptance | Result | Evidence |
|---|---|---|---|
| 1 | Type shows only with Logistics licence + permission 500 | **pass** (with permission) | Before the grant: `BankGuaranteePayeeType` → `[حسابات]` only. After the grant: `[حسابات, عملاء انشاءات, عملاء اللوجستيك]` (Id 12) |
| 2 | Active Logistics customers listed (code – name), filtered by bank branch | **pass** (API + UI: lookup shows "1 - ابو سهيل …" after picking بنك ساب) | `CustomerOrAccount` → 353 rows with ApplicationId 12, each with `BranchIdList`, e.g. "ابو سهيل - ABUSU" |
| 3 | Customer required; type change clears the customer | **pass** | New form: picked Logistics + customer 1, then switched the type to Construction → the customer was cleared and flagged required. Save → red toast "اختار العميل", nothing posted |
| 4 | Guarantee account = `Lgx_Customer.InvoiceAccountId`; liquidation posts to it | **pass** | LG1 `CR94062-TEST-1` (cust 1) has BankGuaranteeAccountId 104 = InvoiceAccountId 104. LG2 `CR94062-TEST-2` (cust 2) has 106 = 106. Created through the UI, `POST /api/BankGuarantee` 200. Liquidation of LG1 (customer picked in the popup = Logistics list) → journal 6733: **Dr 104** (customer 1's InvoiceAccountId) 10,000 / Cr bank 1205; journal 6732 returns the 1,200 cover (Dr 1205 / Cr 65) |
| 5 | Increase / decrease / extend / close work for type 12 | **increase pass**; decrease, extend and close not run | LG1 increase 2,000 + cover 200 → saved (screen row "تعليه 2000", journal 6731 cover 200), no exception from the `GetBankGuaranteeList().First` VAT-note path |
| 6 | Search and report filter by Logistics; names correct | **search pass; report data pass**; report grid UI and print not verified locally | `Search?ApplicationId=12` → both LGs with names "ابو سهيل - ABUSU" and "مخبز الرابية - RSB01". Report: the type list offers عملاء اللوجستيك and the customer list loads Logistics customers (`CustomerForReport?ApplicationId=12` 200). Local AnalyticsReader `odata/BankGuaranteeReport?applicationId=12&customerIds=1,2` → 200 with both LGs, ApplicationId 12, names "ابو سهيل - ABUSU" / "مخبز الرابية - RSB01" (TVF + Lgx_Customer CTE work). The shared `report-grid-multi-request` sends **no** request on "عرض", **also for the untouched Accounts type**, so this is local-environment behaviour, not this CR |
| 7 | Delete of a Logistics customer with an LG is refused | **pass** | `DELETE /api/Customer/2` (no sales orders or invoices, has LG2) → 400 "لا يمكن حذف العميل لارتباطه بخطابات ضمان" / "The customer cannot be deleted because it is linked to bank guarantees". Customer 1 was refused earlier by the older sales-transactions check |
| 8 | No change for tenants without Logistics | not testable on Sabreen (licensed); covered by `IsLicensed` unit tests | |
| R7 | (review-2 condition) Search with an id that collides across apps; payee list for an unlicensed tenant | **search pass**; unlicensed list unit-tested only | Ids 1 and 2 also exist in `Vw_TreasuryCustomers` for app 4 and as GL accounts 1 and 2; search still shows the Logistics names, so the (ApplicationId, CustomerId) lookup works |

## Findings outside this CR

- **Pre-existing:** editing an existing LG and saving sent `PUT /api/BankGuarantee/1` with `ExpenseTaxPercent: null`. The API rejected it with 400 ("Error converting value {null} to type 'System.Decimal'"). The update DTO and the form's expense-tax field are untouched by cr94062. Check on Beta whether it also fails there; if so, it's a separate bug.
- **Pre-existing, all types:** liquidation pays the **original** amount, not the current amount after increases. LG1 = 10,000 + increase 2,000; the screen row shows تسييل 12,000, but payable journal 6733 = 10,000. Cause: `CloseOrCashBankGuaranteeCommand.cs:270` uses `bankGuarantee.Amount`, while the cover return (line 218) uses `CurrentCoverAmount`. That file is unchanged in cr94062. Raise it as a separate bug if the PO agrees it's wrong.
- Test data left on Sabreen: LG `CR94062-TEST-1` (customer 1: created, increased, liquidated) and `CR94062-TEST-2` (customer 2: created), permission 500 granted to the engineer's test user, and the 2 report objects + permission row from `cr94062-sabreen.sql`.
- **Local environment:** the report grid's "عرض" fires no OData request on localhost:4200, for any type. Accounts was tested to rule out this CR. Print was not tested. Re-check the report grid and print on Stage Beta after the stage PR deploys.
