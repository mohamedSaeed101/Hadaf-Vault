---
type: review
cr: 125808
round: 3
scope: iterate 1 (change-note-1.md, derived «منتهي» status)
updated: 2026-10-26
---

# Review round 3 — CR_125808   base ERP 9a119db7f4 (cr125808 HEAD)  head: uncommitted working tree + untracked `RentReservationQueryHandlerTests.cs`   verdict: pass

Scope: only the uncommitted iterate in `AccFlex_Cloud_ERP` (7 modified files + 1 untracked). Rounds 1–2 cover everything committed on `cr125808`; not re-reviewed. Front and DB have no uncommitted change.

## Change-note conformance (verified, no row)

- Display-only Expired id 5: `RentReservationStatus.Expired` is built through the private parameterless ctor, so it never enters `List` and no command can resolve it; the only command touching `StatusId` is Cancel (`wasConfirmed` check on id 2), so id 5 is neither stored nor assignable.
- GetAll / GetById: `StatusName` is «منتهي» / "Expired" when `StatusId == Confirmed && ExpiryDate < today` (`IDateTime.Now.Date`), `StatusId` stays 2, `IsExpired` kept. Expiry == today is not expired (strict `<`).
- Filter: 5 → Confirmed AND expired; 2 → Confirmed AND not expired; other ids unchanged. Both filters are applied before `CountAsync`, so `TotalCount` and the page agree.
- Defaults `Statuses` = `List.Append(Expired)` → the front filter (fed from Defaults) gains «منتهي» with no front change.
- Unit untouched; Cancel of an expired Confirmed still releases the unit (`Cancel_ExpiredConfirmed_ReleasesUnit`).
- Front check: `rent-reservation.constants.ts` hard-codes ids 1–4 but is used only for Draft/Confirmed gating (edit, confirm, cancel); the form shows `dto.StatusName`, the list column binds `StatusName`, the filter items come from `defaults.Statuses`. An expired row keeps `StatusId` 2, so the Cancel button stays visible. No front change needed.
- API contract: additive only (`StatusName` helper signature is internal; DTOs unchanged).
- Tests: 31/31 RentReservation tests pass (`dotnet test --filter FullyQualifiedName~RentReservation`, 2026-10-26). The four query tests fail without the change (StatusName was «مؤكد», filter 5 returned nothing, filter 2 returned both).
- Surgical: the GetAll projection was rewritten from an expression-bodied lambda to a block lambda only to hoist `isExpired`; no adjacent code touched. No secrets, ports or local paths.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | PropertyManager.Application.Test/RentReservations/RentReservationQueryHandlerTests.cs:51 | nit | change-note Test / Karpathy 3 | `StatusId = 5` is a magic literal while the neighbouring test uses `RentReservationStatus.Confirmed.Id`. | Use `RentReservationStatus.Expired.Id`. |
| 2 | PropertyManager.Application.Test/RentReservations/RentReservationQueryHandlerTests.cs | nit | change-note "ExpiryDate < today" | No boundary test: a Confirmed reservation with `ExpiryDate == Today` must still read «مؤكد» / `IsExpired == false`. Code is correct (strict `<`), but the boundary is the easiest thing to regress. | Optional: add `GetAll_ExpiresToday_IsNotExpired` (set `ExpiryDate = Today`, assert StatusName «مؤكد», IsExpired false). |

No `block` or `should` rows. Round 4 not needed.

## Merged by main (backend-reviewer, 2026-10-26)
| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| B1 | PropertyManager.Logic/RentReservationAggregate/RentReservationStatus.cs:17 + Application/RentReservations/Shared/RentReservationInput.cs:48-58 | nit | backend: root CLAUDE.md coding guideline 3 (match existing style) | Sale quotations solve the same thing in Application (SaleQuotationDisplayStatus + DisplayStatusId on DTOs); here Expired lives in the Logic enumeration and the DTOs carry StatusId 2 + IsExpired. | **skip (accepted):** works as is - the front filter goes to the server (statusId=5) and rows render StatusName; a DisplayStatusId refactor would need a client re-sync for no behaviour change. Note for the lease-contract CR. |
| B2 | PropertyManager.Application.Test/RentReservations/RentReservationQueryHandlerTests.cs:50 | nit | backend: match existing style | Literal StatusId = 5. | **done (main):** RentReservationStatus.Expired.Id. |

Reviewer nit 2 (no ExpiryDate == today boundary test): skip (accepted; strict < verified by reading).

**Final verdict round 3: pass** (0 block, 0 should). Reviewed by Fable 5.1 + backend-reviewer.
