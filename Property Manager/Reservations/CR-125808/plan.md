---
type: plan
cr: 125808
updated: 2026-10-25
size: L
gated: approved by the engineer 2026-10-25 ("Plan approved, run phase-loop")
commits: none per phase — engineer rule "no commit until told"; changes stay uncommitted in the set
set: D:\Hadaf-worktrees\cr125808 (offset 200)
---

# CR-125808 — Plan: Rent Reservations

Paths: DB = `AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State`, PM = `AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\PropertyManager`, FE = `AccFlex_Cloud_Front\accflex-erp`. All under the set.

Settled for the plan (explorer 2026-10-25):
- Module id **959** «حجوزات الإيجار» (957 VacancyBoard and 958 SaleContracts are taken; 955 is unsafe because Sabreen holds it). Menu: group **7_3** «الحجز / Reservation» under 7 «التأجير», item **7_3_1** (route `rent-reservations`).
- Copied pieces are **byte-identical** to their source files and keep the same file names, so the Stage_Beta merge collapses to add/add: `0466_Pm_PropertyStatus.sql` and the remap post-script come from `origin/cr125720`. The 2 settings columns come from `origin/cr125733`, lines 17–18.
- Property log event types: new seed `0469_Pm_RentReservationLookups.sql`: `2 حجز إيجار / RentReservation` and `3 إلغاء حجز إيجار / RentReservationCancelled`. Re-check that 0469 and event ids 2–3 are free on Stage_Beta before commit.
- Quick customer: reuse `pm-quick-create-customer-popup` (sale-quotations). The group comes from settings `CustomerGroupId`. **No «مستأجر» classification exists**, so A9 drops the classification. Recorded in decisions as Q5.
- Code `RR-<yyyy>-<0000>` (source note) via a new `GetNextCodeService.GetNextReservationCode`, same pattern as `GetNextQuotationCode`.

| # | Phase | Files | Done when | Depends on | Wave | Rule |
|---|---|---|---|---|---|---|
| 1 | DB: copy PropertyStatus (table + `0466` seed + remap post-script, from origin/cr125720 DB commits 5325ce6e2 and 0ee588d77). Add the 2 settings columns. New `dbo\Tables\Pm_RentReservation.sql` (Id, Code, Date, ExpiryDate, StatusId, CustomerId, PropertyId FK Pm_Properties, ExpectedStartDate, Years, AnnualRent decimal(18,3), Deposit decimal(18,3), PaymentMethodId, Note, audit cols per house table rule). Seed `0469` (event types). Module row 959 in `0002_Acc_Module_Data.sql`. Register every file in the sqlproj once | DB\dbo\Tables\*, DB\Scripts\ReferenceDataScripts\*, DB\Scripts\PostScripts\*, *.sqlproj | VS 2022 MSBuild of the sqlproj: 0 errors | — | A | db-rules, sqlproj-registration, prescript-no-ddl, prescript-no-go |
| 2 | ERP: copy PropertyStatus from origin/cr125720 ERP commits 8600eb66a4 and 49a719c9cb. Take PropertyStatus.cs, its configuration, error, resources, GetAllPropertyStatuses query + controller lines, and the Create/UpdateProperty, PropertyPoco, Property.cs, GetProjectInfoById, BulkPropertyRowChecker, PropertyImportValidator, SalePriceScope and GetAvailableSaleUnits edits. Leave out the report and module 956. Add the 2 settings props + decimal(5,2) config | PM\* | `dotnet build` PropertyManager API csproj (BaseOutputPath redirected) exits 0 | — | A | accflex-erp-core, accflex-erp-data |
| 3 | Logic: `RentReservationAggregate\{RentReservation, RentReservationPoco, RentReservationStatus, ReservationPaymentMethod, RentReservationErrors}.cs`. Methods Create / Update / Confirm(property) / Cancel(property) return Result. Only Draft is editable or deletable. Confirm requires the property Available, then sets it Reserved. Cancel releases a Confirmed reservation. Add Property `Reserve()` / `Release()`, and PropertyLogEventType entries 2 and 3. Resources ar/en | PM\PropertyManager.Logic\* | build exits 0 | 2 | B | accflex-erp-domain |
| 4 | Unit tests for 3 (A5, A6, A7 transitions and guards, deposit default) | PM\PropertyManager.Application.Test\RentReservations\* | `dotnet test` filter `RentReservation` passes | 3 | C | test-doubles-and-baselines, core.md test map |
| 5 | Application + API: Create/Update/Delete/Confirm/CancelRentReservation commands. Queries GetAll (list columns + expired flag), GetById, GetRentProjects (Renting, no children, «الرئيسي › الفرعي»), GetAvailableRentUnits(projectId), GetReservationDefaults (validity days, deposit %, CustomerGroupId). `GetNextReservationCode`. EF config + DbSet. `RentReservationController` with View/Add/Edit/Delete policies on 959. Module.cs 959. Menu 7_3 / 7_3_1. Guard `UpdatePropertyCommand` (keep the stored status while a Confirmed reservation exists) and `DeletePropertyCommand` (reject when any reservation exists) — spec A11. Available = `null OR Available` in GetAvailableRentUnits and Confirm | PM\PropertyManager.{Data,Application,API}\*, Shared\SharedKernel.Logic\Modules\Module.cs | build exits 0; contract additive only | 3 | C | accflex-erp-api, accflex-erp-data, datetime-clock |
| 6 | Command tests: Confirm on a not-Available unit fails; Confirm/Cancel flip the unit status and write the log; code numbering | PM\PropertyManager.Application.Test\RentReservations\* | filter passes | 5 | D | test-doubles-and-baselines |
| 7 | Front: `api:sync` PropertyManager client (sync-api-client). Module `modules\rent-reservations\` with a grid with status filter and expired-row warning class, a form with project→unit cascade, rent→deposit recompute and Confirm / Cancel with prompts, and the quick-customer popup reused. Hide the deferred buttons and tab. Route + ModuleId 959, ar/en i18n | FE\projects\property-manager\*, FE\src\api-clients\property-manager\*, FE\src\assets\i18n\*\property-manager.json | `front-verify-build` green | 5 | D | feature-simple-with-search-component, feature-data-service, api-clients, permissions-and-drawer, template-bound-getters, cloud-front-theming (memory) |
| 8 | E2E on Sabreen: publish DB (publish-db.ps1), run the PM API locally on +200, run the front against it, walk A1–A10, write `test-results.md` | — | A1–A10 rows pass or are logged in open-questions | 1,6,7 | E | local-api-run |

Waves: A = {1,2} in parallel. B = 3. C = {4,5}. D = {6,7}. E = 8. Then STOP for `/review-code 125808` (gate 6).
