# CR 126223 – Spec: Reschedule installments (sale contracts)

Source: [[Reschedule]] + `decisions.md` (Q1–Q9, C1–C3). Written by the agent (to-spec sections), 2026-10-27.

## Problem Statement
A buyer in difficulty, or one who wants a different payment rhythm, needs the remaining installments of an approved sale contract spread over a new count, frequency and first due date, with the same total and without cancelling the contract. Today the cloud schedule can only be built once, at approval.

## Solution
A new PM screen «إعادة جدولة الأقساط» (Real-estate marketing › Contract actions 6_3 › 6_3_2, module 967). It lists posted reschedule documents. A popup takes a contract, the document date, the new count, the frequency and the first due date. It shows a summary and a preview, then «تنفيذ وترحيل». That action:
- marks the remaining lines «ملغي» (Cancelled, 3)
- adds the new lines as Active (1), linked to the document; the grid shows them as «معاد جدولته» because of that link
- creates a posted `Pm_ContractActionDocument` of type Reschedule, code `DOC-YYYY-####`

## Rules
- **R1 Eligible contracts:** sale contracts in status Active (2) or Delivered (3).
- **R2 Remaining lines (interim, Q2/Q3):** series Installment (2), status Active (1), DueDate >= document date (same cutoff as transfer). A line already rescheduled once is Active and can be rescheduled again. Down payment, maintenance deposit, amenity and RETT lines never change. When collection is built, the due-date cutoff is replaced by "not invoiced, nothing paid" (BR-1).
- **R3 Amounts:** per = Round2(total ÷ n), last = total − per × (n − 1); n = count; the popup normalises 0 or empty to 1, and the aggregate refuses n < 1. Due k = first due + k × period months (Monthly 1, Quarterly 3, Semi-annual 6, Annual 12; `InstallmentPlanFrequency`). k starts at 0.
- **R4 Tax (Q8):** each new line takes TaxPercent and TaxCategory from the first remaining line (by DueDate, RowNo), and Tax = Round2(amount × % / 100), per line as at approval. Σ new Tax may differ from Σ cancelled Tax by a few piasters; that drift is accepted.
- **R5 Change % (BR-4):** |per − first remaining amount| ÷ first remaining amount × 100. When `RealEstateSettings.InstallmentChangeLimitPercent` has a value and is exceeded, a warning shows «يحتاج اعتماد من نظام الموافقات» and the % turns red. It does not block posting (Q7). No warning when the limit is null (Q6). This knowingly relaxes Settings.md field 23 / BR-17 (approval required) until REM-PLAN exists (`decisions.md`).
- **R6 Sum:** Σ new amounts = Σ cancelled amounts, exactly. The aggregate enforces it.
- **R7 Execute** is refused when the contract is not eligible, there are no remaining lines, n < 1, the first due date is missing, or the first due date is before the document date. «تنفيذ وترحيل» is disabled until a contract is picked (BR-7).
- **R8 New lines:** status Active (1), series Installment, RowNo continuing after the contract's current max, `ContractActionDocumentId` set. Cancelled lines keep their values; only the status changes to Cancelled (3) and `CancelledByContractActionDocumentId` is set to the document that cancelled them.
- **R9 No journals** (BR-6).
- **R10 Document:** Code DOC-YYYY-#### (per-year counter over all action types), TypeId Reschedule (1), Date, SaleContractId, UnitId, CustomerId (representative buyer), Description «إعادة جدولة n قسط بإجمالي X إلى m قسط», Amount = Σ cancelled Amount (net of tax; the contract list's Remaining is gross, so the two differ by the tax), StatusId Posted (1), plus OldCount, NewCount, FrequencyId, FirstDueDate, NewInstallment, ChangePercent.

## User Stories
1. As a sales accountant I open Contract actions › Reschedule installments and see the posted reschedule documents (search, export).
2. I click «إعادة جدولة الأقساط المتبقية», pick an eligible contract, and see the count and total of the remaining lines.
3. I set the count (default 6), frequency (default quarterly), first due (default today + 1 month) and document date (default today), and see the new installment, the change % and a preview (due, series, amount, tax; 6 rows per page).
4. If the change exceeds the limit I see a red % and the approval warning, and can still post.
5. I post; the contract's installments grid shows the old lines «ملغي» and the new lines «معاد جدولته» (Active lines linked to a reschedule document) in a new «الحالة» column.
6. I open a document row and see its details.

## Implementation Decisions
- **DB:**
  - `Pm_ContractActionDocument`, plus lookups `Pm_ContractActionDocumentType` (1 Reschedule) and `Pm_ContractActionDocumentStatus` (1 Posted).
  - `Pm_SaleContractInstallment.ContractActionDocumentId INT NULL` and `CancelledByContractActionDocumentId INT NULL` (both FK to Pm_ContractActionDocument).
  - Statuses 2 Transferred (byte-identical from cr126102) and 3 Cancelled in the 0466 MERGE. No id 4.
  - `Pm_RealEstateSettings.InstallmentChangeLimitPercent`, byte-identical from cr125733.
  - Module row 967 in 0002_Acc_Module_Data.sql.
- **Logic:**
  - New statuses in `SaleContractInstallmentStatus`.
  - `SaleContract.Reschedule(RescheduleInput, now) → Result<RescheduleOutcome>`, which owns R1–R8 and returns the totals for the document.
  - New aggregate `ContractActionDocument` with factory `CreateReschedule(...)`.
  - The `PeriodMonths` mapping is exposed from `InstallmentPlanFrequency` (reuse, no copy).
  - `InstallmentChangeLimitPercent` copied into `RealEstateSettings`.
- **Application:**
  - `ContractActions\Commands\RescheduleSaleContract` (single-file command + handler, transaction).
  - `Queries\GetRescheduleDocuments` (search, paging).
  - `Queries\PreviewSaleContractReschedule` (summary, preview, change %, limit).
  - `Queries\GetEligibleContracts`.
  - Next code in `GetNextCodeService` (`DOC-`).
- **API:** `ContractActionController` with module 967 and the View/Add policies. The sale-contract installment DTO gains StatusId / StatusName; StatusName is «معاد جدولته» when StatusId = 1 and the linked document is a Reschedule, otherwise the status lookup name.
- **Menu:** `ContractActions` 6_3 group copied from cr126102 unchanged; item 6_3_2 «إعادة جدولة الأقساط».
- **Front:**
  - New module `contract-reschedules` (list + popup) under property-manager, plus its route.
  - Sale-contract installments tab gets a «الحالة» column.
  - Client regenerated with sync-api-client.
- **Shared with CR-126102 (Q4):** the status column and the API status field are built here in a way 126102 can take as-is. Ids 1–2 match its code.

## Testing Decisions
- **Aggregate unit tests** (NUnit, FluentAssertions, `SaleContractMother`):
  - AC-1: 8 × 75,000 → 6 × 100,000 quarterly.
  - AC-2: sum equality with a rounding remainder (e.g. 100,000 / 3).
  - R2: lines due before the document date and non-Installment lines untouched; a line due on the document date is rescheduled; a second reschedule picks up the first one's lines.
  - New lines are Active (1) with ContractActionDocumentId set.
  - R1: ineligible status refused.
  - R7: first due date before the document date refused.
  - Cancelled lines carry CancelledByContractActionDocumentId.
  - Change % and limit flag.
  - Tax copied from the first remaining line.
- **Handler test:** document code `DOC-2026-0001` and the next code.
- **Manual E2E** on a test tenant: AC-1 and AC-4 in the browser.

## Acceptance
- **A1** An Active sale contract with 8 remaining «قسط» × 75,000, count 6, quarterly: the 8 become «ملغي» and 6 × 100,000 «معاد جدولته» lines appear every 3 months from the first due date.
- **A2** Σ new = Σ cancelled exactly; the rounding difference sits on the last line.
- **A3** Lines due before the document date, and down payment, maintenance deposit, amenity and RETT lines, are unchanged (AC-3 is partly deferred until collection exists).
- **A4** A change above «حد تعديل الأقساط %» shows the % in red with the approval warning; no warning when the limit is empty.
- **A5** A posted document DOC-YYYY-#### appears in the list with contract, unit, description and amount.
- **A6** The contract's installments grid shows a «الحالة» column (ساري / منقول / ملغي / معاد جدولته).
- **A7** Draft, FullyPaid and other ineligible contracts cannot be picked or rescheduled.

## Out of Scope
- Lease contracts (Q1).
- Approval request REM-PLAN / D39 (Q7).
- Invoiced / paid detection (collection not built; Q3).
- Journals.
- Cancelling or reversing a reschedule document.
- The other contract-action types (waiver, rescind, …) beyond the shared table.

## Further Notes
- Rescheduled lines stay Active (1), so every existing "remaining" filter (GetAllSaleContracts, Pm_Rpt_SoldUnits, cr126102 TransferringInstallments) keeps working unchanged (business-check-1 rows 1/2).
- Stage_Beta merge: 6_3 and statuses 1–2 will already exist there from cr126102. Expect conflicts in WebMenuGroup.cs, WebMenuItem.cs, SaleContractInstallmentStatus.cs, Module.cs and 0466. Keep the cr126102 lines and add ours.
- The `PeriodMonths` change touches `InstallmentScheduleCalculator`; behaviour must not change (covered by the existing tests).
