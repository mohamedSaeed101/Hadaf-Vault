---
type: spec
cr: 125808
updated: 2026-10-25
path: agent-written (to-spec sections); grilling by the agent against facts.md + decisions.md
---

# CR-125808 — Spec: Rent Reservations (حجوزات الإيجار)

## Problem Statement
A tenant agrees on a rental unit before the lease is signed. Today nothing records the agreement, so the same unit can be promised twice and the agreed rent / deposit lives outside the system.

## Solution
A new Property Manager screen, Leasing › Reservation › Rent Reservations: a list and a form. A reservation moves Draft → Confirmed → Cancelled (Converted is modelled for the future lease contract). Confirming reserves the unit (status Reserved + a property log row); cancelling a confirmed reservation releases it (Available). Accounting (invoice, receipt) and contract conversion are deferred (`deffer.md` D1–D7).

## User Stories
1. As a leasing officer I create a draft reservation: tenant, rent project (filter), available rent unit, expected start, years, annual rent, deposit, payment method, note.
2. I add a missing tenant from a «+ عميل جديد» popup without leaving the screen.
3. Picking the unit fills annual rent from the unit's rent price and deposit = rent × settings deposit %; changing the rent recomputes the deposit.
4. I confirm a draft; the unit becomes «محجوز» and nobody else can confirm it.
5. I cancel a draft or confirmed reservation (with a confirmation prompt); a confirmed one frees the unit.
6. In the list I see confirmed reservations past «صالح حتى» highlighted, and I can filter by status.

## Acceptance (A1..An)
- **A1** Saving a new reservation generates `RR-<yyyy>-<seq>`; status Draft; date defaults today, expiry = today + settings ReservationValidityDays (14 when unset), expected start = today + 15, years = 1, payment method = bank transfer in.
- **A2** Mandatory: date, expiry, tenant, unit, expected start, years (> 0), annual rent (> 0), deposit (≥ 0), payment method. Deposit default = rent × percent ÷ 100 (setting is a whole percent). Expiry ≥ date.
- **A3** Unit list = units of the chosen project whose investment type is Rent and whose status is Available; project list = projects with investment type Rent that have no child projects, shown «الرئيسي › الفرعي». Changing the project clears the unit. Project is not stored.
- **A4** Choosing a unit with rent price 120,000 and settings deposit 5 % fills rent 120,000 and deposit 6,000; editing rent to 100,000 sets deposit 5,000. (AC-1, reservation half.)
- **A5** Edit / delete allowed only in Draft (BR-1); the API rejects both otherwise.
- **A6** Confirm on a unit that is not Available fails with «العقار غير متاح» and changes nothing (BR-2, AC-4). Confirm on an Available unit sets status Confirmed, unit → Reserved, and writes a property log row (event Reservation, reservation no). (AC-1 unit half.)
- **A7** Cancel (Draft or Confirmed, after a confirm prompt) sets Cancelled; for a Confirmed one the unit goes back to Available only if it is still Reserved, and that cancel is logged whether or not the unit was released; a Draft cancel never touched the unit and writes no log row (BR-6, AC-3; review-1 row 4).
- "Available" everywhere (unit list A3 and Confirm A6) = `PropertyStatusId IS NULL OR Available`, the house predicate of `GetAvailableSaleUnitsQuery`.
- **A8** List columns: no, date, tenant, unit, expected start, annual rent, deposit, collected (0 until D4), expires, lease contract (empty until D1), status with a status filter. Confirmed rows with expiry < today use the warning colour and the form shows «انتهت صلاحية الحجز – حوّله لعقد أو ألغِه» (BR-7). No auto-expiry.
- **A9** «+ عميل جديد» reuses the existing `pm-quick-create-customer-popup` (Logistics `CreateRealEstateCustomer`: mobile mandatory + unique, B2B needs CRN and TRN, sales organization) with the group from settings `CustomerGroupId`, and selects the new customer. No «مستأجر» classification exists in the system, so none is set (decisions Q5).
- **A11** While a unit has a Confirmed reservation, Update Property keeps its stored status (no flip back to Available) and Delete Property is rejected; a unit with any reservation cannot be deleted. (business-check-1 row 1)
- **A10** Permissions: View / Add / Edit / Delete under the new module id; Confirm and Cancel require Edit (the house has no separate Confirm / Cancel policy; review-1 row 3); menu under Leasing › Reservation.

## Implementation Decisions
- New aggregate `RentReservation` in `PropertyManager.Logic` (behaviour methods Create, Update, Confirm(property), Cancel(property)); table `Pm_RentReservation`; status enum stored as int (Draft 1, Confirmed 2, Converted 3, Cancelled 4). Columns reserved for the deferred work: `CollectedAmount` (0), `LeaseContractId` (null) — only if they cost nothing; otherwise left out (Simplicity first) — decide in plan with the reviewer's rule.
- Unit status and property log follow the copied Stage_Beta design (decisions Q1) so the Stage_Beta merge is add/add, not a second design.
- Settings values read from `Pm_RealEstateSettings` (copied columns); defaults 14 days / 5 % when the row or value is null.
- Template: the ViolationPolicy feature (cr125716) for layering, controller, front module and menu.
- Hidden in this CR: Convert, Collect deposit, invoice tab (D1, D3–D5).

## Testing Decisions
- Unit tests on the aggregate: A5, A6, A7 transitions and guards; deposit computation helper (A4) if it lives in the backend.
- Command tests for Confirm / Cancel touching Property status (in-memory per house test pattern).
- Front build gate; manual run on Sabreen (the only tenant with PM data) for A1–A9.

## Out of Scope
`deffer.md` D1–D7: lease conversion and approval, invoice 386 + journal, receipt, invoice tab, auto-expiry, refund policy.

## Further Notes
Fields 1–13 in the source note duplicate 14–26 with older defaults; 14–26 win (expiry = today + settings, start = today + 15, payment method mandatory).
