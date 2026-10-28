# CR 126223 – open questions (grilling, 2026-10-26)

Asked to the engineer in one message; recommended answer first.

- [ ] Q1 Scope: sale contracts only, lease half deferred (no lease contract in the cloud). Rec: yes.
- [ ] Q2 Which lines are "remaining": no invoice/payment link exists on installments. Rec: every Active line of series «قسط» (Installment); down payment, maintenance deposit, amenities, RETT untouched (avoids the credit-account / VAT merge the note itself flags). Alt: BR-1 as written (all non-RETT series).
- [ ] Q3 AC-3 (invoiced / part-paid lines stay): nothing tracks it. Rec: lines due on or before the document date stay as they are; only later-due lines are rescheduled; AC-3 recorded as partly deferred. Alt: all Active «قسط» lines regardless of due date.
- [ ] Q4 Old lines: new status `Cancelled = 2 «ملغي»`, kept (not deleted), shown with their status. Rec: yes.
- [ ] Q5 Document: new table Pm_SaleContractReschedule (code RS-YYYY-####, date, contract, old count/total, new count, frequency, first due, new installment, change %, status Posted) + `RescheduleId` on new lines and `CancelledByRescheduleId` on cancelled lines; «معاد جدولته» shown from RescheduleId. Rec: yes.
- [ ] Q6 «حد تعديل الأقساط %»: not on Master_Stable (cr125733 / Stage_Beta only). Rec: copy that one column from cr125733 byte-identical (as cr125808 did); warning skipped when null.
- [ ] Q7 BR-5 approval request: Rec: warning only, no approval request (deferred).
- [ ] Q8 Tax: new lines take TaxPercent / TaxCategory of the first remaining line, Tax = Round2. Rec: yes.
- [ ] Q9 Module / menu: new module 961 «إعادة جدولة الأقساط» under الحجز والتعاقد, menu 6_1_3 (re-check Stage_Beta). No «إجراءات العقود» group exists yet. Rec: yes.
