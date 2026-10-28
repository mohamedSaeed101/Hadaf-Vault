# CR 126317 – deferred (out of this CR)

Engineer, 2026-10-28: "defer any thing related with قيد عكس الإيراد and write them in defer file". Everything below that touches the revenue reversal is out of this CR. Rows marked *(agent)* are deferred because they rest on the same missing infrastructure (no revenue recognition, no installment invoicing in the cloud — same ground as CR 126303 Q1); confirm or pull back at the grill.

| # | Source rule | What is deferred | Waits for |
|---|---|---|---|
| D1 | BR-6, BR-8 | Unified reversal entry (قيد العكس الموحد) for the replaced contract: Dr recognised revenue 4110 (or brokerage commission + owners' payable for another owner's unit), Dr output VAT 2410 on issued invoices / Cr contract receivable 1215 by (recognised − invoiced; debit when invoiced is larger); before delivery under «عند التسليم» Dr customer advances instead of 1215 | revenue recognition («المثبت») posting; shared with rescission (فسخ) and waiver (CR 126303 D3) |
| D2 | BR-6 | `REM_Rescind` journal type for the replaced contract, including its Cr 2330 customer advances by the carried paid amount (settled on the new contract), and the account settings it needs | D1 |
| D3 | BR-6, BR-8, accounting table row 1 | Cr customer account 1210 by unpaid invoices (one line per invoiced customer); open question «الأقساط المفوترة غير المسددة بتتعكس على حساب العميل» | D1 + installment invoicing |
| D4 | BR-6, accounting table row 3, open Q1 | `REM_COGS` reversal (Dr 1312 / Cr 5112, same amounts as the delivery entry) when the old contract carries cost (percentage of completion) | delivery / cost CR; D1 |
| D5 | AC-4 | Acceptance AC-4 as written (reversal entry moving paid to advances + deposit-settlement entry on the new contract with the same amount); the settlement half pairs with D2's Cr 2330 and is deferred with it | D2 |
| D6 | BR-8 | Recognised amount («المثبت») on the old contract back to 0 | revenue recognition |
| D7 *(agent)* | BR-3 | «Paid on revenue-installment invoices» part of the carried amount (today carried = collected reservation deposit only); invoiced / paid split of BR-8 | installment invoicing with a paid amount per line |
| D9 *(agent, pending Q6)* | — | Reversal of the old contract's posted RETT journal (Dr RETT expense / Cr RETT payable, `JournalType.ContractJournal`) when its RETT line is cancelled | D1 decision; confirm at Q6 |
| D8 *(agent)* | BR-4 | «Remaining *uninvoiced* installments» distinction (today every Active line is uninvoiced, so all are cancelled) | installment invoicing |
