# CR 126303 – open questions (grill round 1, 2026-10-28)

All answered 2026-10-28, see `decisions.md` (Q2, Q3, Q4, Q8 deferred → `deferred.md`).

Each has the agent's recommended answer. Blocked on: the engineer (or the PO through them).

- [x] Q1 Scope vs missing infrastructure. The note's accounting (recognised revenue «المثبت», installment invoices, unified reversal, delivery/COGS) does not exist in the cloud. Rec: build the waiver on what exists — paid = collected deposit, remaining = all Active installments; no revenue reversal (nothing is recognised); keep BR-8/BR-9 out of scope until revenue recognition / invoicing / delivery CRs land.
- [x] Q2 Journal. Rec: one ContractJournal (19) on waiver: Dr deposit liability/customer account by paid / Cr refunds payable (paid − fee) / Cr service revenue (fee); two new RealEstateSettings accounts (CustomerRefundsPayableAccountId, WaiverFeeRevenueAccountId). Need: which account is debited for the collected deposit (what the deposit invoice credited).
- [x] Q3 Credit note D09. Rec: out of scope (no unpaid installment invoices exist to cancel); the refund goes through the payment request only.
- [x] Q4 Payment request. Rec: CashControl type 5 RealEstate «تسويق عقاري» (no new type), amount = paid − fee; none when ≤ 0.
- [x] Q5 Fee default. Rec: new RealEstateSettings `WaiverFeePercent` (default 1) like DefaultTransferFee; popup default = % × contract net, editable.
- [x] Q6 Dependency on CR 126223 (Pm_ContractActionDocument, installment status Cancelled 3, ContractActions menu) — unpushed. Rec: ship 126223 first, then sync this set with origin/Master_Stable; until then copy its pieces byte-identical.
- [x] Q7 Eligible contracts. Rec: Active and Delivered (Delivered is never set today, harmless); unit Sold → Available via a new `Property.ReleaseSold()`.
- [x] Q8 Cancel waiver. Rec: allowed only while the unit is still Available and the payment request is not paid; cancels the payment request, reverses the journal, restores from snapshot.
- [x] Q9 Permissions. Rec: new module id, View / Add for the waiver, Delete policy for cancel.

## Phase 4 (2026-10-28)

- [x] Q10 (phase 4, answered: paid = 0, see decisions.md Q10): R2 says paid = the collected deposit of "the contract's reservation", but nothing links a sale contract to a reservation: `Pm_SaleContract` has no ReservationId, `Pm_Reservation` has no SaleContractId, no code ever sets ReservationStatus.ConvertedToContract 3, and SaleQuotation has no reservation link either (checked this set and origin/Stage_Beta). Which reservation's `ReservationInvoice.InvoicePaidAmount` counts as paid? Options: (a) the latest reservation on the same PropertyId **and** CustomerId with status Confirmed 2 or ConvertedToContract 3 (agent's recommendation; a transferred contract's new customer then gets paid 0); (b) same PropertyId only, any non-cancelled status, latest (the deposit follows the unit, also through a transfer); (c) add a ReservationId to the sale contract (new column + set it on create from reservation; bigger scope, belongs to another CR). Also: when several match, sum or latest? ; blocked on: the engineer
  - [x] Answered 2026-10-28: «التنازلات على العقد مش الحجز» — the reservation deposit does not count; paid = collected on the contract = 0 today (D1). `decisions.md` Q10.
