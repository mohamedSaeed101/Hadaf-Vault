---
type: review
cr: 125808
round: 2
updated: 2026-10-25
reviewer: Fable 5.1 (reviewer agent)
---

# Review round 2 — CR_125808   base DB 567969f1d / ERP bc2e0aae49 / Front e134b1b0ad (set HEAD)  head: uncommitted working tree   verdict: changes required (1 block: local `config.json` edit must not be committed; every round-1 row otherwise verified)

Scope: only the rows of `review-1.md`, verified against the working tree (`git diff HEAD` + untracked) of the three repos in `D:\Hadaf-worktrees\cr125808`, `spec.md` (A7 / A10 as amended) and `decisions.md` Q8–Q10. Gates (DB MSBuild, API build, 703 tests, `npm run testing`) taken as reported; spot-checked by reading, not re-run.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | AccFlex_Cloud_Front/…/modules/properties/** (+ property-import/shared/property-import-columns.ts, api-clients/property-manager/clients/property.client.ts) | verified done (code) | decisions Q1; Backward compatibility | `git diff --stat origin/cr125720 -- modules/properties property-import-columns.ts property.client.ts` is empty: the Properties screen is byte-identical to cr125720; `properties.service.ts:246` fills `propertyStatuses$` from `PropertyClient.getAllPropertyStatuses()` and `property-main-form.component.html:158` binds it; `property-status-popup` deleted as on cr125720; `_Note_Status_` present ar/en. The Sabreen re-run of the Properties screen (open / save / change status) is still not in `test-results.md`. | Code: none. Add the Properties-screen re-run on Sabreen to `test-results.md` before the push (should). |
| 2 | AccFlex_Cloud_ERP/…/PropertyManager.Logic/RentReservationAggregate/RentReservation.cs | verified done | Coding guidelines 2 | No `CalculateDeposit` anywhere in the ERP repo; `DefaultDepositPercent` kept and used by `GetRentReservationDefaultsQuery.cs:63`. | None. |
| 3 | spec A10 | verified done (main) | spec A10 | A10 now reads «Confirm and Cancel require Edit»; decisions Q8 records it; controller still gates both by `EditPolicy`. | None. |
| 4 | spec A7 | verified done (main) | spec A7 | A7 now states a Draft cancel writes no log row; decisions Q8; `CancelRentReservationCommand` matches. | None. |
| 5–10, 18–20, 22–26 | — | skip accepted | nit | Nits accepted in round 1; nothing to re-check. | None. |
| 11 | AccFlex_Cloud_ERP/…/RentReservations/Shared/RentReservationReferences.cs:13 (+ Create…Command.cs:33, Update…Command.cs:34) | verified done | accflex-erp-domain.md §Application Layer, §Validation and Localization | `Check` runs after `Validate` and before `GetNextCode` / `Create` / `Update`: property existence, `PropertyInvestmentTypeList.Any(Renting)` (same predicate as `GetAvailableRentUnitsQuery`), `QuotationCustomers.Any`; three new `RentReservationErrors` with ar/en resource values, returned via `ToNoModelError()`. Tests `Create_UnknownProperty_…`, `Create_SaleOnlyProperty_…`, `Create_UnknownCustomer_…`, `Update_SaleOnlyProperty_…` assert the error, the empty store and `SaveCalls == 0`, so they fail without the check. | None. |
| 12 | AccFlex_Cloud_Front/…/shared/services/components/quick-create-customer-popup/ | verified done | AP core.md §Follow the code that is there | Component, module and `quick-customer-data-source.ts` live under the existing shared-components folder; `sale-quotations.module.ts:6-7,28` and `rent-reservations.module.ts:6-7,28` both import from there with `useExisting` providers; old `sale-quotations/components/quick-create-customer-popup` deleted. `quick-create-customer-popup.component.ts:11` still imports `CustomerType` from `modules/sale-quotations/shared/sale-quotation.constants` (shared → feature dependency). | None required; nit: move `CustomerType` next to the popup or into `shared/` when convenient. |
| 13 | AccFlex_Cloud_Front/…/rent-reservations/shared/rent-reservation-data.service.ts:20 | verified done | AP api-clients.md §Where they live | `import { CompanyInfoClient } from 'misc.api.client';` | None. |
| 14 | AccFlex_Cloud_Database/…/PostScripts/20261022151259_Pm_Properties_RemapPropertyStatus.sql | verified done (main) | db-rules idempotency | decisions Q9 records the byte-identical copy and defers the guard to cr125720. | None. |
| 15 | AccFlex_Cloud_Database/…/ReferenceDataScripts/0464_Pm_SaleQuotationLookups.sql | verified done (main) | db-rules MERGE delete | decisions Q10 records the 1–5 list, the missing comma and the Stage_Beta menu root '7' handling for the `cr125808_Stage_Beta` resolution. | None. |
| 16 | AccFlex_Cloud_Front/…/sale-quotations/shared/sale-quotation-data.service.ts:49 | verified done | AP SOLID-L/I | `export class SaleQuotationDataService implements QuickCustomerDataSource`; `RentReservationDataService` likewise (line 26). | None. |
| 17 | AccFlex_Cloud_Front/…/rent-reservation-form/rent-reservation-form.component.ts:207 | verified done | AP core.md §TypeScript | `private buildInput = (): IRentReservationInput => …`, imported from the client barrel. | None. |
| 21 | AccFlex_Cloud_Database/…/dbo/Tables/Pm_RentReservation.sql:15 (+ RentReservationConfigurations.cs:18, RentReservationInput.cs:24, form html:156) | verified done | db-rules §Data Types | `Note NVARCHAR(500)`, EF `HasMaxLength(500)`, `[StringLength(500)]`, front `[maxLength]="500"`. Sabreen_Primary still has the earlier `NVARCHAR(MAX)` column (manual ALTER noted by the implementer; harmless either way). | None. |
| 27 | AccFlex_Cloud_Front/accflex-erp/src/assets/configs/config.json:3-18,29,38 | block | Front `config-json.md` ("never commit local edits"); reviewer rule 7 (ports / local paths) | New since round 1: the working tree carries the E2E local config (`propertymanagerapi` → `https://localhost:1618/api`, every other API → `localbeta`, `printRedirectUrl` / reporting host → `localbeta`). Round 1 recorded `config.json` untouched; it is now a tracked modification that `git add -A` / `git commit -a` would ship to `cr125808`. | `git -C AccFlex_Cloud_Front checkout -- accflex-erp/src/assets/configs/config.json` before staging (or stage by path and confirm `git diff --cached --name-only` does not list it). No code change. |

## Checked and clean (no row)

- Round-1 fixes broke no neighbour: `Create` still validates once before the code is consumed (row 5 ordering kept), the new `Check` is `AsNoTracking` and returns before `GetNextCode`, so a refused create still consumes no code; `Update` loads the reservation first, then checks references, then `Update(poco)` (Draft-only guard unchanged).
- `PropertyStatusTests/` and `GetAllPropertyStatuses/` are the cr125720 copies the Front now depends on; `GetAllPropertyStatuses` route is additive.
- No secrets in the diff; the only local path / port is row 27.

Round 3: not needed. Row 27 is a one-command revert of a local file; the orchestrator can close it by confirming `git -C AccFlex_Cloud_Front status --short -- accflex-erp/src/assets/configs/config.json` is empty before the commit. Row 1's Sabreen re-run of the Properties screen is a `should` for `test-results.md`, not a code change.

## Closed by main (2026-10-25)
- Row 27 (block): config.json was the temporary E2E edit of the Properties-screen follow-up, live while round 2 read the tree. Restored: `git status --short -- accflex-erp/src/assets/configs/config.json` is empty; `git diff --cached` empty in all three repos. **done**
- Row 1 should (Sabreen re-run of the Properties screen): done, recorded in test-results.md 'Review-1 follow-up'. **done**
- Remaining nit (CustomerType imported from sale-quotation.constants by the shared popup): accepted.

**Final verdict: pass** (0 block).
