# CR 126223 – test results (2026-10-28)

## Unit / build gates
| Gate | Result |
|---|---|
| DB sqlproj (VS 2022 Community MSBuild) | exit 0, dacpac has the 3 tables + 2 columns |
| PM.Logic build | 0 errors |
| SaleContractRescheduleTests (35 cases) | 35 / 35 pass |
| RescheduleSaleContractHandlerTests | 1 / 1 (DOC-2026-0001 → 0002) |
| PropertyManager.Application.Test, full | **858 / 858 pass** (after module id 967) |
| PropertyManager.API Release build | 0 errors |
| sync-api-client PropertyManager | 0 orphans, parity ok (369 exports) |
| Front `npm run testing` | exit 0 (rebuilt after module id 967) |

## E2E on db-all / Sabreen_Primary
Setup: guarded cut-down script (3 tables, 2 columns, installment status 3, doc type/status 1, Acc_Module 967); local PM API from the set on https://localhost:1818; front dist on :4200 with a localbeta config; sign-in by the engineer, Sabreen picked on SelectTenant. Change limit on Sabreen = 10%.

| Check | Evidence | Result |
|---|---|---|
| Popup defaults (today, 6, quarterly, today+1m, «تنفيذ وترحيل» disabled) | e2e\1 | pass |
| A4: change % red + «يحتاج اعتماد من نظام الموافقات» (6× → 100.08%, 9× → 33.39%, 0007 → 500.47%) | e2e\1, 2, 4 | pass |
| Preview 6 rows per page (9 rows → 2 pages) | e2e\2 | pass |
| A1: SC-2026-0006 12 × «قسط» 715,500 → 9 × 79,500 quarterly 28/11/2026 … 28/11/2028 | DB: status 3 ×12 = 715,500; status 1 ×9 = 715,500 | pass |
| A2: sum new = sum cancelled exactly | both contracts | pass |
| DOC numbering + list row (type, contract, property, description, amount) | e2e\3; DOC-2026-0001, DOC-2026-0002 | pass |
| Line links: new lines `ContractActionDocumentId = 2`, cancelled `CancelledBy = 2` (SC-2026-0007, 36 → 6 × 144,112.50) | DB query | pass |
| Other series untouched (maintenance deposit 19,215; series 6 5,000) | DB query | pass |
| Contract still eligible after a reschedule (second reschedule possible) | picker lists SC-2026-0006 again | pass |
| Installment StatusName derived: 6 «Rescheduled», 36 «Cancelled», others «Active» | GET api/SaleContract/8 from the page | pass |
| Sale-contract form «الحالة» column / totals (7b) | — | **not verified**: the sale-contracts screen does not open (pre-existing, see below) |

## Findings
- **F1 (ours, nit):** reopening the popup briefly shows the previous preview grid (9 × 79,500) while contract and count are reset; it clears on the next interaction. For the review.
- **F2 (pre-existing, not ours):** `SaleContractsModule` never provides `PriceListClient`, which `SaleQuotationDataService` injects → `NullInjectorError`, blank sale-contracts screen. Same on base and on today's origin/Master_Stable. Out of scope.
- **F3 (environment):** at 10:17:50, 9 s after DOC-2026-0001 posted, a server-side schema publish on db-all (host DB-ALL, SqlClient, prouser — a stage DB deploy) dropped our two columns on Pm_SaleContractInstallment with their data. Re-applied the guarded script; DOC-2026-0002 was then verified. Any CR schema on Sabreen can be reverted by the next stage deploy.

## Left running
Local PM API (:1818, Sabreen) and the front dist (:4200). Sabreen keeps DOC-2026-0001/0002 and the rescheduled contracts SC-2026-0006 / 0007 (test data).
