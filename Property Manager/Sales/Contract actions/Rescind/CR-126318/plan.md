# CR 126318 – Plan: Rescind sale contracts (فسخ العقود) — DRAFT

**Status: draft.** Written 2026-10-28 on the recommended answers in `open-questions.md` (Q1–Q8, all open). Not gated yet: spec.md and the business check come after the answers; then this table is revised and goes to the plan gate (size L). Everything in `deferred.md` section A (قيد عكس الإيراد) is out; nothing here posts a journal.

Shape copies CR 126223 (`..\..\Reschedule\CR-126223\plan.md`) and the waiver spec (`..\..\Waivers\CR-126303\spec.md`). Rules to follow: `AccFlex_Cloud_Database\.claude\rules\` (reference data via ReferenceDataScripts MERGE, sqlproj registration, no DDL in post-scripts), `AccFlex_Cloud_ERP\.claude\rules\` (CQRS single-file command+handler, Result over exceptions, ModuleId + policies, transaction in handler), `AccFlex_Cloud_Front\.claude\rules\` (theme CSS vars, api-clients via sync-api-client). Re-read them at phase start; cite in each phase note.

Root `ERP` = `AccFlex_Cloud_ERP\AccFlex_Cloud_ERP`; `PM` = `ERP\PropertyManager`.

## Phases

| # | Phase | Files | Done when | Depends on |
|---|---|---|---|---|
| 0 | **Shared pieces** | byte-identical from origin/cr126223: `Pm_ContractActionDocument(+Type,+Status).sql`, installment columns + status 3, `ContractActionDocument` aggregate, `GetNextContractActionDocumentCode`, `ContractActionController` shell, menu 6_3; and the 126303 shared columns / `Property.ReleaseSold` / PropertyLog event once its plan fixes them (Q7) | `git diff origin/cr126223 -- <copied files>` empty; builds | — |
| 1 | **DB** | `Pm_ContractActionDocument.sql` (+`PenaltyBasisId`, `PenaltyPercent`, `PenaltyRemainder`, `Reason` nvarchar(500); shared refund columns per Q7); `Pm_RealEstateSettings.sql` (+`RescissionPenaltyPercent` decimal(5,2) NULL); ReferenceData: doc type 3 «فسخ عقد», installment series 7 «غرامة فسخ», penalty basis lookup (1 percent of paid, 2 percent of contract value, 3 fixed) if stored as a table, PropertyLog event 11; `0002_Acc_Module_Data.sql` (next free module id); `.sqlproj` | VS MSBuild of the sqlproj exit 0; sql-reviewer no block | 0 |
| 2 | **Logic** | `InstallmentSeries` (+7 RescissionPenalty); `ContractActionDocumentType` (+3 Rescission); `ContractActionDocument.CreateRescission(code, contract, input, outcome)`; new `SaleContractRescission.cs` records `RescissionInput(Date, BasisId, PercentOrAmount, ChargeRemainder, Reason)`, `RescissionOutcome(Paid, Remaining, Penalty, Taken, Refund, Remainder)`; `SaleContract.PreviewRescission(input, paid)` pure and `SaleContract.Rescind(input, paid, docId)`: Active 2 / Delivered 3 only, cancel Active lines of series 1, 2, 4 (Q5), status → Rescinded 8, remainder line series 7 when charged (Q4); `Property.ReleaseSold(saleContractId)` (Q7); `RealEstateSettings` +percent; errors + resources | PM.Logic builds; existing SaleContract tests pass | 1 |
| 3 | **Aggregate tests** | `PM.Application.Test\SaleContracts\SaleContractRescissionTests.cs` with `SaleContractMother`: AC-1 (300,000 paid, 10 % of paid → 30,000 / refund 270,000), AC-2 (net 1,000,000, 10 % of value → 100,000 / 200,000), AC-3 (50,000 paid, 100,000 penalty → refund 0; with charge → series-7 line 50,000, tax 0), fixed basis, refused statuses, kept series 3/5/6, cancelled lines linked to doc, rounding 2 dp, `ReleaseSold` refused when not Sold or linked elsewhere | `dotnet test --filter SaleContractRescission` green | 2 |
| 4 | **Data + Application** | EF config (new columns, setting); `ContractActions\Commands\RescindSaleContract\RescindSaleContractCommand.cs` (transaction: preview → doc code → doc → `Rescind` → `ReleaseSold` → PropertyLog → save; sales-organization check as Transfer); queries `GetRescissionDocuments`, `GetRescissionEligibleContracts` (Active/Delivered sale only, never lease — AC-5), `PreviewSaleContractRescission` (paid from `ReservationInvoice`, default % from settings); settings DTO / update command +percent; handler test DOC code sequence shared with reschedule | PM.Application + tests build; handler test green; backend-reviewer no block | 2 |
| 5 | **API + Module + Menu** | `ContractActionController` (+`Rescissions` GET list, GET eligible, POST preview — View; POST execute — Add); `Module.cs` (new id); `WebMenuItem` 6_3_x «فسخ العقود» under ContractActions; resources | PropertyManager.API Release build 0 errors; Swagger shows the endpoints | 4 |
| 6 | **Front client** | `sync-api-client` property-manager | client has the Rescission endpoints and the settings field | 5 |
| 7 | **Front UI** | `projects\property-manager\src\app\modules\contract-rescissions\` (list 8 columns + search + Excel export + read-only details; popup: contract picker, date today, basis radio, % / amount default from settings, computed penalty (and its share of contract value), «تحميل باقي الغرامة» shown only when penalty > paid, reason, summary paid / penalty / refund, impact warning, «تنفيذ وترحيل» disabled until a contract is picked); `routes.ts`; Real Estate Settings field; sale-contract installments tab shows series 7 and status; i18n ar-EG / en-US | `front-verify-build` passes; prettier clean | 6 |
| 8 | **E2E** | test tenant, local PM API + front from the set | AC-1, AC-3 (with charge), AC-5, AC-6 seen in the browser; unit Available and re-sellable; screenshots in this folder | 1, 7 |

Waves: 0 → 1 → 2 → {3, 4} → 5 → 6 → 7 → 8.

## Acceptance mapping
AC-1, AC-2, AC-3 → phases 2–3, 8. AC-4 → deferred D8. AC-5 → phase 4 eligible query, 8. AC-6 → no installment invoicing exists, so "invoiced lines stay Active" holds vacuously; kept series 3/5/6 stay Active (phase 3).

## Risks
- 126303 and this CR touch the same table, aggregate and `Property` method: agree Q7 before phase 0, or the second merge conflicts.
- Stage_Beta conflicts in WebMenuGroup/Item, Module.cs, InstallmentSeries, ReferenceData: keep theirs, add ours.
- The series-7 line on a Rescinded contract: every installment sum / follow-up screen must still show it (check the 126223 phase 7b filters, which skip only status 3).
