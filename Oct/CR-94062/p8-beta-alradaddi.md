# CR-94062 — web test on BETA-Alradaddi (2026-10-12)

Setup:
- Branch `cr94062` in the main checkouts (`D:\Hadaf\…`): Cloud_ERP `0db81200e5`, Front `718390d9d0`.
- Local APIs, Debug, Development environment:
  - Cash Control https://localhost:5009 (build 14:05, contains the cr94062 code).
  - Logistics https://localhost:5014 (build 14:08).
  - AnalyticsReader https://localhost:5055 (`Authority` env var = localbeta).
- Front: http://localhost:4200 (`ng serve --watch`). The local `config.json` points cashcontrol, logistics and analyticsreader at those ports. **Not to be committed.**
- Signed in as the engineer on tenant **BETA-Alradaddi**, through `accesscontrol.localbeta`.
- Front clients: `cashcontrol.api.client@1.0.1018-local.1`, `logistics.api.client@1.0.3898-local.1` (dev tag).
- Tenant data: 2,107 Logistics customers. The tenant had **no** letters of guarantee before this test.

Screenshots: `evidence-beta-alradaddi/`.

| # | Acceptance | Result | Evidence |
|---|---|---|---|
| 1 | Type shows with the Logistics licence + permission 500 | **pass** | `GET api/BankGuarantee/BankGuaranteePayeeType` → `[حسابات (1), عملاء انشاءات (9), عملاء اللوجستيك (12)]`. The screen's نوع الجهة list shows عملاء اللوجستيك (`01-payee-type-list.jpg`) |
| 2 | Active Logistics customers listed (code – name), searchable by code, filtered by bank branch | **pass** | `CustomerOrAccount` → 2,107 rows with ApplicationId 12, each with `Number` and `BranchIdList`. After picking Bank_1, the lookup shows "111002 - م/احمد توفيق …" (`02-…`). Typing `111063` finds "111063 - ناصر عبد الله الاحمدي" (`03-…`) |
| 3 | Type change clears the customer; save without a customer shows "اختار العميل" | **pass** | Customer 111063 selected (`04a`), type changed to حسابات → customer empty and flagged required (`04b`). Back to Logistics with no customer, Save → red toast "اختار العميل", and no POST was sent (network log) (`05-…`) |
| 4 | Liquidation posts to the customer's `InvoiceAccountId` | not run | Needs a saved guarantee (writes to the tenant) |
| 5 | Increase / decrease / extend / close for type 12 | not run | Needs a saved guarantee |
| 6 | Search, report and print by Logistics | **partial** | `Search?ApplicationId=12` → 200, 0 rows (the tenant has no guarantees). `api/CustomerForReport?ApplicationId=12` → 200, 2,107 customers with `CustomerCode` and `CustomerAccountId` (e.g. customer 1 → account 298). Report grid and print not run |
| 7 | Deleting a Logistics customer that has a guarantee is refused | not run | Needs a saved guarantee |
| 8 | No change for tenants without Logistics | not testable here | BETA-Alradaddi has the Logistics licence |

Not checked: whether BETA-Alradaddi's `Saf_Rpt_BankGuaranteeReport` / `Vw_Saf_BankGuaranteePrint` contain `Lgx_Customer`. The direct DB read was blocked by the session's safety check. Permission 500 does work on this tenant (item 1).
