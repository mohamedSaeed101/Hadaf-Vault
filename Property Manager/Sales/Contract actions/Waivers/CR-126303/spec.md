# CR 126303 – Spec: Waivers (التنازلات), waiver to the company

Path: agent-written (`to-spec` sections), from `facts.md`, `decisions.md` (Q1–Q9), `deferred.md`. Source note `..\Waivers.md`. 2026-10-28.

## Problem Statement
A buyer who wants to back out of a sale contract has no way to hand the unit back to the company in the cloud: the contract stays active, its installments stay due, and the unit stays «مباع», so it cannot be sold again.

## Solution
A new Property Manager screen, Real-estate marketing › Contract actions › Waivers (also under Reservation & contracting), lists waiver documents and lets a user waive an Active or Delivered sale contract back to the company. The waiver cancels every Active installment, sets the contract to «متنازل عنه» (Assigned 5), puts the unit back to «متاح», and records a posted waiver document carrying the fee and the refund amount (paid − fee). Accounting, the payment request, the credit note and the cancel action are deferred (`deferred.md` D1–D11).

## Requirements
- **R1** Eligible contracts: sale contracts with status Active 2 or Delivered 3 (Q7). Any other status is refused by the aggregate.
- **R2** Paid = collected reservation deposit of the contract's reservation (`ReservationInvoice.InvoicePaidAmount`, 0 when none or the invoice is void) (Q1).
- **R3** Remaining = sum (Amount + Tax) of the contract's Active installment lines, excluding the RETT series 5 (Q1, D12).
- **R4** Fee: optional, ≥ 0; popup default = `RealEstateSettings.WaiverFeePercent` (new, default 1) × contract net, rounded to 2 dp; editable (Q5). Refund = paid − fee (may be ≤ 0, shown as is).
- **R5** Execute and post: one transaction — create the document (code `DOC-YYYY-####`, shared sequence with other contract-action documents), every Active installment except the RETT line (series 5, left untouched like Transfer; D12) → Cancelled 3 with `CancelledByContractActionDocumentId` = the document, contract → Assigned 5, unit Sold → Available **and `SaleContractId` cleared** (new `Property.ReleaseSold(saleContractId)`, refused if the unit is not Sold or is linked to another contract) (BC-1 row 1), and a `PropertyLog` event «تنازل» (new event type) carrying the document id (BC-1 row 4).
- **R6** Document: type «تنازل» (new type id), status Posted 1, date, contract, unit, customer = `SaleContract.CustomerId` (the representative buyer; co-buyer split rides with D10) (BC-1 row 6), `PreviousContractStatusId`, amount = fee, refund, paid, remaining, description «تنازل للشركة، رد <refund>» (Q8 snapshot minimum). The reservation stays ConvertedToContract and its deposit invoice is untouched (BC-1 row 5).
- **R7** «تنفيذ وترحيل» is disabled until a contract is picked; date defaults to today and is required.
- **R8** List columns: document, type, date, contract, property, description, amount (fee), status; search and Excel export; opening a row shows a read-only details popup (no cancel button, Q8).
- **R9** Permissions: new module id (next free), View for list / preview / eligible, Add for execute (Q9). Eligible list and execute are scoped to the user's sales organizations, as Transfer does (`CheckUserSalesOrganizationAsync`) (BC-1 row 3).
- **R10** Settings: `WaiverFeePercent` (decimal(5,2), 0–100) readable and editable in Real Estate Settings like `DefaultTransferFee`.

## Acceptance (A1..An)
- **A1** Active contract, net 1,000,000, deposit paid 200,000, fee 10,000 → contract «متنازل عنه», unit «متاح», all Active installments except the RETT line «ملغي», document `DOC-2026-xxxx` «تنازل» Posted with amount 10,000 and refund 190,000.
- **A2** Default fee with WaiverFeePercent 1 and net 1,000,000 = 10,000; with the setting changed to 2 → 20,000.
- **A3** Contract Draft / FullyPaid / Assigned / Transferred / Replaced / Rescinded is not in the eligible list and is refused by the command.
- **A4** Fee > paid (paid 0, fee 10,000) posts with refund −10,000 shown.
- **A5** After a waiver the unit is Available with no sale contract, can be reserved again, and a new sale contract on it can be approved; it shows in the stock report again.
- **A7** A user outside the contract's sales organization does not see it in the eligible list and is refused by the command.
- **A6** Document codes are sequential per year across reschedule and waiver documents.

## User Stories
1. As a sales officer, I pick a contract, see the customer, paid and remaining, set the fee, and post the waiver.
2. As a sales manager, I list and export waiver documents.
3. As an admin, I set the default waiver fee % in Real Estate Settings.

## Implementation Decisions
- Shared contract-action pieces copied byte-identical from CR 126223 (Q6): `Pm_ContractActionDocument(+Type, +Status)`, installment status Cancelled 3, `CancelledByContractActionDocumentId`, `ContractActionDocument` aggregate, `GetNextContractActionDocumentCode`. The waiver adds type 2 «تنازل» and nullable waiver columns (PreviousContractStatusId, PaidAmount, RemainingAmount, RefundAmount) to the document.
- `SaleContract.Waive(input, docId)` in the aggregate returns `Result`; `Property.ReleaseSold()` new.
- Menu: item under `ContractActions` 6_3 (already on Master_Stable from cr126102).
- No journal, no payment request, no credit note, no cancel (Q2–Q4, Q8).

## Testing Decisions
- Aggregate tests: R1 statuses, R5 line cancel + link, contract status, unit release refused when not Sold, R4 default fee rounding.
- Handler test: document code sequence (A6), transaction, refund.
- E2E on the test tenant: A1, A5.

## Out of Scope
`deferred.md` D1–D11; waiver to a new customer (→ «نقل الملكية», CR 126102); lease contracts.

## Further Notes
- Module ids 964–967 are taken (cr126228, Sabreen, cr126223); pick the next free at phase 1.
- Shipping order with 126223 is free; both carry the same shared pieces byte-identical.
