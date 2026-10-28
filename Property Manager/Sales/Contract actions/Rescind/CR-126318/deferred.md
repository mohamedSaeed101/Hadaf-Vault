# CR 126318 – Rescind – deferred (out of this CR)

## A. قيد عكس الإيراد and everything tied to it — deferred by the engineer, 2026-10-28

"defer any thing related with قيد عكس الإيراد". The rescission posts **no journal** in this CR. Each row needs a follow-up CR once its prerequisite lands. Rows match the waiver's deferrals (`..\..\Waivers\CR-126303\deferred.md` D3, D4, D6, D8, D9) so one revenue-recognition CR can close them for waiver, rescission and replacement together.

| # | Source rule | What is deferred | Waits for |
|---|---|---|---|
| D1 | BR-11 | Unified reversal (قيد العكس الموحد): Dr recognised revenue 4110 + Dr output VAT 2410 on issued invoices / Cr unbilled receivables 1215 by (recognised − invoiced; debit when invoiced is larger); before delivery under «on delivery» Dr customer advances instead of 1215; Cr customer account 1210-xxxx by unpaid invoices, one line per invoiced customer | revenue recognition («المثبت») posting + installment invoicing |
| D2 | BR-6 | `REM_Rescind` journal itself: D1 + Cr 2350 customer refunds payable (paid − penalty) + Cr 4190 penalty revenue (penalty taken), the debit for the collected deposit, the new account settings for 2350 / 4190, and the journal type | D1 |
| D3 | BR-6 | Recognised amount on the contract back to 0 | revenue recognition |
| D4 | BR-7 | Another owner's unit: reverse brokerage commission + owners' payable instead of sale revenue | D1 + broker / owner postings |
| D5 | BR-10 | `REM_COGS` reversal (Dr 1312 / Cr 5112, same lines as the delivery entry) and unit back to stock for a delivered contract | delivery (تسليم) CR with its cost entry |
| D6 | OQ-a | Unpaid invoiced installments closed from the customer account inside the reversal; whether they also need an e-credit note | D1 + installment invoicing |
| D7 | OQ-b | «On delivery» revenue policy, contract not delivered: reverse against customer advances, not revenue (nothing recognised) | D1 |
| D8 | AC-4 | «REM_Rescind is balanced» acceptance | D2 |

## B. Proposed deferrals — pending the engineer's answer (`open-questions.md`)

Not tied to the revenue reversal itself, but each needs infrastructure the cloud lacks. Same choices the waiver made (126303 Q1, Q3, Q4, Q9). Move to section A once answered "defer".

| # | Source rule | What would be deferred | Waits for | Question |
|---|---|---|---|---|
| P1 | BR-1 | Paid on revenue-installment invoices; "remaining = uninvoiced" distinction (today paid = collected deposit, remaining = Active lines) | installment invoicing | Q1 |
| P2 | BR-6 | Credit note on the customer account for the refund (D09) | PM credit-note path | Q2 |
| P3 | BR-6 | Payment request «مرتجع عميل عقاري» (D27) for refund > 0 | new payee shape in CashControl | Q2 |
| P4 | BR-8 | Rescission approval (D39) | approvals extension | Q6 |
| P5 | BR-3 | Invoicing the «غرامة فسخ» line from «متابعة أقساط البيع» (the line itself is built here) | installment invoicing | Q4 |
