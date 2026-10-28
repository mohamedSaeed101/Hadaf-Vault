# CR 126303 – deferred (out of this CR, decided Q1 2026-10-28)

Items from `..\Waivers.md` that wait for infrastructure the cloud does not have yet. When the named prerequisite lands, the waiver needs a follow-up CR for each.

| # | Source rule | What is deferred | Waits for |
|---|---|---|---|
| D1 | BR-1, Q10 | Paid on the contract (revenue-installment invoices); today paid = 0, the reservation deposit never counts | installment invoicing with a paid amount per line |
| D2 | BR-1, BR-3 | «Remaining = uninvoiced installments» distinction (today all Active lines are uninvoiced) | installment invoicing |
| D3 | BR-3, BR-9 | Combined reversal entry (قيد العكس الموحد): Dr recognised revenue / output VAT, Cr contract receivable 1215 or customer advances, Cr customer account by unpaid invoices | revenue recognition («المثبت») posting; shared with rescission and replacement |
| D4 | BR-3 | Recognised amount on the contract back to 0, and restored on cancel (BR-6) | revenue recognition |
| D5 | BR-3 | Credit note on the customer account for the refund / unpaid invoices (D09); open question OQ-a | invoicing + a PM credit-note path |
| D6 | BR-8 | `REM_COGS` reversal (Dr 1312 / Cr 5112) and unit back to stock for a delivered contract | delivery (تسليم) CR with its cost entry |
| D7 | BR-6 | Reversal of the COGS reversal on cancel | D6 |
| D9 | BR-3, BR-6 (Q2) | `REM_Waiver` journal itself: Cr 2350 customer refunds payable (paid − fee), Cr 4140 service revenue (fee), the debit side for the collected deposit, the account settings for them, and its reversal on cancel | decision with D3 (engineer, Q2 2026-10-28) |
| D10 | BR-3, BR-6 (Q4) | Payment request «مرتجع عميل عقاري» (D24) for paid − fee (type 5 today is «تسويق عقاري»; OQ-b refund ≤ 0), and its cancellation when the waiver is cancelled | engineer, Q4 2026-10-28 |
| D11 | BR-4, BR-5, BR-6 (Q8) | «إلغاء التنازل»: restore from snapshot, block when the unit status changed, document «ملغي» + reversal document, fee line cancel; full snapshot of installment statuses | engineer, Q8 2026-10-28 |
| D12 | BC-1 row 2 | RETT on waiver: the RETT installment line (series 5) and the RETT journal posted on approve stay as they are; reverse / cancel them | engineer, 2026-10-28 |
| D8 | — | Brokerage commission + owners' payable for another owner's unit in the reversal | D3 |
