# CR 125808 Rent Reservations — test results

## Sabreen inventory

Phase 8a, 2026-10-25, `db-all` / `Sabreen_Primary`, read-only `sqlcmd` before any write.

| Object | State on Sabreen |
|---|---|
| `Pm_PropertyStatus` table | **exists**, 5 rows; ids 1-5 with names متاح / محجوز / مباع / مؤجر / تحت الصيانة (all 5 match `0466_Pm_PropertyStatus.sql`) |
| `Pm_RentReservation` table | **missing** |
| `Pm_RealEstateSettings.ReservationValidityDays` | **exists**, `int NULL` (row 1 value 14) |
| `Pm_RealEstateSettings.ReservationDownPaymentPercent` | **exists**, `decimal(5,2) NULL` (row 1 value 5.00) |
| `Pm_PropertyLogEventType` rows | only id 1 (عرض سعر / Quotation). Ids 2, 4, 5 **missing**; 4/5 not used by anything else |
| `Acc_Module` 959 | **missing**, and the id is free (nothing else uses it). PM modules present: 945-953, 956, 957; `IDENT_CURRENT` 957; `ModuleId` is an identity column |
| `_MigrationScriptsHistory` for `20261022151259_Pm_Properties_RemapPropertyStatus.sql` | **present**, run 2026-10-22 16:39:29, hash `zL6sx+FRL/uIgxqM+Q+Tjg==` (same hash as the set's file) |
| `Pm_Properties.PropertyStatusId` distribution | 1 → 60 rows, 4 → 1 row (no NULLs, nothing outside 1-5) |
| `Pm_ProjectStatus` rows | 1 row: id 1, Under Construction, IsActive 1, IsAvailableForSale 0 |
| FK on `Pm_Properties.PropertyStatusId` | none |
| FK targets for `Pm_RentReservation` | `Lgx_Customer.CustomerId` and `Pm_Properties.PropertyId` are the PKs |

Stop conditions: none (959 free; event ids 4/5 unused).

Conclusion: the status table, the settings columns and the remap were applied to Sabreen on
2026-10-22 by an earlier run. Missing: `Pm_RentReservation`, event types 4/5, module 959.
Event type 2 (تحديث سعر البيع / Sale price update) is also missing, but it is not part of the
phase 8a brief, so it is left out.

## Applied

2026-10-25, `db-all` / `Sabreen_Primary`, one transaction with `XACT_ABORT`, a cut-down
guarded script (scratchpad `cr125808-sabreen.sql`, not in any repo). No full publish.

| Step | Result |
|---|---|
| `Pm_PropertyStatus` create + seed | no-op (table and 5 rows already there; 0 rows inserted) |
| Remap `Pm_Properties.PropertyStatusId` | **did not run**: the status table already existed and `_MigrationScriptsHistory` already has the 2026-10-22 row. Distribution still 1 → 60, 4 → 1 |
| `Pm_RealEstateSettings` reservation columns | no-op (both already there) |
| `Pm_RentReservation` | **created**, 0 rows; PK, `UQ_..._Code`, 4 CHECKs, FKs to `Lgx_Customer` and `Pm_Properties` all present |
| `Pm_PropertyLogEventType` 4 / 5 | **2 rows inserted** (حجز إيجار / Rent Reservation; إلغاء حجز إيجار / Rent Reservation Cancelled); names verified |
| `Acc_Module` 959 | **1 row inserted** (Property Manager Rent Reservations, app 14, UI name `Rent Reservations`), with `IDENTITY_INSERT` |

A second run of the script changed nothing (all counts 0, no CREATE), so it is idempotent.
Still missing on Sabreen: event type 2 (Sale price update), outside this brief.

## E2E walkthrough (2026-10-25, db-all / Sabreen_Primary)

Setup: PM API from the set (Debug build) on https://localhost:1618, `ASPNETCORE_ENVIRONMENT=Development`, Authority localbeta, `DebugTenantConnection` -> Sabreen_Primary (Application Name `cr125808-e2e`). Front = the set's `npm run testing` dist served on :4200, local config.json: propertymanagerapi -> localhost:1618, every other API -> localbeta (localstable URLs signed the user out with 401). Signed in as company Sabreen.
Override proof: `sys.dm_exec_sessions` shows `cr125808-e2e` sessions on Sabreen_Primary from this machine right after the requests; the saved row is in Sabreen_Primary.

| # | Result | Evidence |
|---|---|---|
| A1 | pass | new form: date today, expiry 2026/11/08 (+14 from settings), start 2026/11/09 (+15), years 1, bank transfer, Draft; save -> RR-2026-0001 |
| A2 | pass | empty save -> «أكمل الحقول الإلزامية» |
| A3 | pass | projects = leaf projects «الرئيسي › الفرعي»; البرج A shows no units (no rent units in DB); القدس shows its 1 rent unit; after confirm the unit drops out of the list; after cancel it returns |
| A4 | pass | rent 120,000 -> deposit 6,000 (settings 5 %) |
| A5 | pass | PUT / DELETE on a Confirmed reservation -> 400 «لا يمكن تعديل/حذف الحجز إلا وهو مسودة»; UI save on a cancelled one -> «الحجز قابل للتعديل والحذف في مسودة فقط»; confirmed form read-only |
| A6 / AC-4 | pass | confirm dialog -> «تم تأكيد الحجز وحجز العقار»; DB: StatusId 2, unit 4 PropertyStatusId 2, Pm_PropertyLog (event 4, source 959, sourceId 1, note RR-2026-0001). Second draft on an already reserved unit -> confirm 400 «The property is not available» |
| A7 / AC-3 | pass | cancel confirmed (API and UI with prompt) -> Cancelled, unit back to 1, log event 5; cancel draft -> Cancelled, no log (never reserved); second cancel -> 400 |
| A8 | pass | 11 columns + status filter; Confirmed with expiry in the past (row backdated by SQL for the test) highlighted; form shows «انتهت صلاحية الحجز – حوّله لعقد أو ألغِه»; Convert / Collect / invoice tab not rendered |
| A9 | pass (render only) | «+ عميل جديد» enabled once a project is chosen; popup opens with the real-estate customer fields; not submitted, to avoid creating a customer on the shared tenant |
| A10 | partial | screen reachable at /apps/Sabreen/property-manager/rent-reservations as an admin user; menu 7_3_1 and per-permission behaviour not checked in the drawer |
| A11 | unit tests only | not exercised live: a failing guard would really delete a Sabreen unit; covered by the RentReservation command tests (Delete refused, Update keeps Reserved) |

Data left on Sabreen: RR-2026-0001..0003 all Cancelled; units 4 and 7 back to Available (1); 4 Pm_PropertyLog rows (ids 6-9).
Note: the first Confirm click landed on the Save button's tooltip overlay; the second click opened the dialog. Cosmetic, toolbar-wide, not this CR.

## Review-1 follow-up (2026-10-25)
- Properties screen on Sabreen (local API + rebuilt front): unit «عمارة K» opens with status «متاح»; the status lookup lists the five PropertyStatus values (متاح، محجوز، مباع، مؤجر، تحت الصيانة) from GetAllPropertyStatuses. Not saved (real tenant unit with an unrelated missing field); save path covered by the cr125720 tests.
- Sabreen Pm_RentReservation.Note narrowed to NVARCHAR(500) (guarded ALTER; table holds only this CR's 3 test rows).
