# CR 126317 – open questions (grill round 1, 2026-10-28)

Each has the agent's recommended answer. Blocked on: the engineer (or the PO through them). Revenue reversal is deferred (`deferred.md`), not asked.

- [ ] Q1 Carried paid. Rec: = collected reservation deposit of the reservation converted to the old contract (+ the old contract's own carried amount when it was itself a replacement), as CR 126303 Q1; invoiced-installment part deferred (D7).
- [ ] Q2 How the new contract carries the paid amount. Rec: new column `SaleContract.CarriedPaidAmount` (decimal, default 0); Preview schedules on `SalePrice − Discount − CarriedPaidAmount`; shown on the contract as «عربون مرحّل».
- [ ] Q3 Price ≤ carried paid. Rec: refuse execute («السعر أقل من المسدد المرحّل») — refund is not built here.
- [ ] Q4 Fee series. Rec: new InstallmentSeries 7 «رسوم استبدال» (country VAT like TransferFee 6).
- [ ] Q5 Shared pieces (Pm_ContractActionDocument, installment status Cancelled 3) now on origin/cr126223. Rec: byte-identical copy into this set (as CR 126303 Q6), either merge order clean.
- [ ] Q6 RETT. Old contract's RETT journal is posted; new approve posts RETT on the new price. Rec: cancel the old RETT line with the others, post the new RETT journal normally; old RETT journal reversal → deferred (D9).
- [ ] Q7 What the new contract copies. Rec: customer + co-buyers + ownership split, plan, contract type, clauses, RETT flags, broker (percent recomputed on the new net); no amenities, discount 0, no SaleQuotationId.
- [ ] Q8 Permissions. Rec: new module id, View list / Add execute, scoped to the user's sales organizations as Transfer; no approval workflow, no cancel of a replacement.
