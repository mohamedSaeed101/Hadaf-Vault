---
type: facts
cr: 125808
updated: 2026-10-25
source: "[[Reservations]]"
---

# CR-125808 — Facts: Rent Reservations (حجوزات الإيجار `rent.reservations`)

- **ADO:** Change Request 125808, created by the agent at the engineer's explicit request ("implement it and create cr", 2026-10-25) from [[Reservations]]. Fields copied from sibling CR 125716 (area `3- Customer Issues`, Program Property Manager, نواصى العقارية, السعودية, 7.0.82.x, Beta, Paid, due 2026-11-08). ADO assignment rules set Hassan Eldarwany on create; reassigned to Mohamed Saeed, state **In Development**.
  https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125808
- **Merge Desk:** #12622, Beta, Acknowledge, owner mohamed.saed, repos API / WebContainer / Database, contract change on, components Database / Property Manager / Web Container (engineer: "and create ticket deployment"). `cr125808` cut off Master_Stable in all three.
- **Kind:** cr → Stage_Beta then Master_Stable. Requirements M20. No attachments; the source note is the only source.

## Scope (source: [[Reservations]])

1. Screen Leasing › Reservation › Rent Reservations: list (expired confirmed rows in warning colour) + form (property card, groups «الحجز» and «الإيجار المتفق عليه والعربون», tab «الفاتورة والتحصيل» after save).
2. Fields 14–26 (rows 1–13 are an older duplicate of the same fields): No `RR-yyyy-seq` on first save; date (today); expiry (today + settings ReservationValidityDays); status draft/confirmed/converted/cancelled; tenant (customer, «+ عميل جديد» quick popup: group «عملاء عقاريون», classification «مستأجر»); project (rent projects without children, filter only, not saved, change clears unit); unit (available, investment type rent; fills rent + deposit); note; expected start (today + 15); years (1); annual rent (hint = unit rent price; change recomputes deposit); deposit (rent × settings ReservationDownPaymentPercent); payment method (cash / bank transfer in / cheque / Ottu, default bank transfer).
3. List columns: no, date, tenant, unit, expected start, annual rent, deposit, collected, expires, lease contract, status (filter).
4. BR-1..BR-7, buttons Save / Confirm / Collect deposit / Convert to lease / Cancel, AC-1..AC-4.
5. Source open questions: deposit off the security deposit or the first rent instalment; refund on cancel/expiry; auto-expiry.

## Code facts (explorer, 2026-10-25)

- **No lease contract aggregate on any ref** (Master_Stable, Stage_Beta, cr125716/733/759). PM has only ContractClauses (935) and ContractTemplate (951, Stage_Beta). BR-4, BR-5, AC-2 have nothing to hook into.
- **Unit = `Property` aggregate**, `int? PropertyStatusId`; lookup `PropertyStatus` (Available 1 «متاح», Reserved 2 «محجوز», Sold 3, Rented 4 «مؤجر», UnderMaintenance 5), table `Pm_PropertyStatus` — **Stage_Beta only, not on Master_Stable**. No status history; nearest is `PropertyLog` + `PropertyLogEventType` (only `Quotation = 1`, Stage_Beta).
- **Settings:** `ReservationValidityDays`, `ReservationDownPaymentPercent` on `Pm_RealEstateSettings` — Stage_Beta and origin/cr125733 only.
- **Cross-module:** PM → Logistics only via typed HttpClient `PropertyManager.API/Services/LogisticsCrmClient.cs` (Stage_Beta). No PM call creates a sales invoice, customer or receipt voucher.
- **Down-payment invoice:** no Logistics command. 386 only in Construction e-invoice (`IsSystemGeneratedForPrePaid`), `CreatePrepaidStatementEinvoiceCommand`.
- **Rent projects:** `Project.ProjectInvestmentTypeList`, `InvestmentType.Renting = 2`.
- **Module id:** next free 957 (954 Work Teams on Sabreen; 955 unchecked). Leasing menu root 7, Violations at 7_2 (cr125716).
