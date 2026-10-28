# CR 126318 – Rescind (فسخ العقود) – facts

- **ADO:** Change Request 126318, created by the agent at the engineer's explicit request ("plan … and create cr", then "Allow, retry create", 2026-10-28) from [[Rescind]]. Fields copied from sibling CR 126303 (area `3- Customer Issues`, Program Property Manager, نواصى العقارية, السعودية, 7.0.82.x, Beta, Paid, Web, due 2026-11-09). Assigned to Mohamed Saeed, state **In Development**.
- **Merge Desk:** #13668, Beta, Acknowledge, contract change = yes, components Database / Property Manager / Web Container (engineer: "and deployment").
- **Branch / set:** `cr126318` in Database, API, WebContainer (Merge Desk, off Master_Stable); set `C:\Hadaf_Work\worktrees\cr126318`, port offset 1100.
- **Kind:** Change Request → `cr<id>`, stage branch Stage_Beta, Merge Desk Beta.
- **Source:** [[Rescind]] (`..\Rescind.md`), explainer `..\..\شرح - فسخ العقود.md`. Siblings: `..\..\Waivers\CR-126303` (same shape: contract action + refund + unified reversal; its decisions Q1–Q9 are the template here), `..\..\Reschedule\CR-126223` (shared document table).
- **Size: L** — DB (new document type, document columns, new installment series, setting) + PM API (command, queries, aggregate methods) + Angular (new screen) + new behaviour. Plan gate applies.
- **Repos:** db, erp, front. Not AccFlex_ERP (desktop).

## Scope (source: Rescind.md)

1. New screen `rem.rescind`: Real-estate marketing › Contract actions › Rescind contracts (also under Reservation & contracting). No button in sale or lease contract (decision 11/10). Lease contracts are never rescinded; they end via «إشعارات الإنهاء».
2. List of rescission documents (search, export): document DOC-YYYY-####, type «فسخ عقد», date, contract, property, description «فسخ العقد – مسدد …، غرامة …», amount (penalty), status «مُرحّل».
3. Popup «فسخ عقد البيع»: contract (sale «ساري» / «تم التسليم» only), rescission date (today), penalty basis (percent of paid / percent of contract value / fixed; default percent of paid; decision 26/10), percent or amount (default 10 %), computed penalty under it, «تحميل باقي الغرامة على العميل» (required decision only when penalty > paid; default unchecked), reason (optional, stored on the document). Summary: paid, penalty, net refund; impact warning; «تنفيذ وترحيل» disabled until a contract is picked (BR-9).
4. BR-1 paid = paid on revenue-installment invoices + collected deposit; remaining = remaining uninvoiced installments.
5. BR-2 penalty by basis; taken = min(penalty, paid); refund = paid − taken (≥ 0).
6. BR-3 penalty > paid: checked → «غرامة فسخ» installment for the remainder on the rescinded contract, no VAT, invoiced from «متابعة أقساط البيع»; unchecked → company keeps all paid, no claim, no credit note, no payment request.
7. BR-4 penalty is compensation → no VAT; basis, penalty and remainder stored on the document.
8. BR-5 cancel remaining installments (Active, uninvoiced, nothing paid; except insurance, penalty and fees); contract → «مفسوخ»; unit → «متاح» with a log.
9. BR-6 `REM_Rescind` = unified reversal + Cr 2350 refunds payable (paid − penalty) + Cr 4190 penalty revenue; recognised back to 0; credit note (D09) and payment request type 5 «مرتجع عميل عقاري» (D24/D27) when refund > 0.
10. BR-7 another owner's unit: reverse brokerage commission + owner's payable; return to stock only for company units.
11. BR-8 Add permission on the screen; rescission approval (D39) — not enforced in the prototype.
12. BR-9 document created Posted; execute disabled until a contract is picked.
13. BR-10 delivered contract with a cost entry: reverse `REM_COGS` (Dr 1312 / Cr 5112).
14. BR-11 unified reversal (shared with waiver and replacement) — definition.
15. AC-1..AC-6 (see source).

## Source open questions
- OQ-a Unpaid invoiced installments are closed from the customer account in the entry — does the product need an e-credit note on them?
- OQ-b «On delivery» revenue policy, not delivered: reversing revenue net is wrong since none was recognised.
- OQ-c Suspended installments are not cancelled on rescission.

## Code facts (2026-10-28; origin/Master_Stable, origin/cr126223, and the 126303 scout in `..\..\Waivers\CR-126303\facts.md`)

- `SaleContractStatus` already has **Rescinded 8** «مفسوخ»; nothing sets it today. Active 2, Delivered 3.
- **CR 126223 is now pushed** (origin/cr126223 in DB, ERP, Front): `Pm_ContractActionDocument` (+Type, +Status), `ContractActionDocument` aggregate (`CreateReschedule`, type 1 Reschedule only), installment `Cancel(docId)` + `CancelledByContractActionDocumentId`, status Cancelled 3, `ContractActionController`, `GetNextContractActionDocumentCode`, module 967, menu 6_3_2.
- `InstallmentSeries`: DownPayment 1, Installment 2, MaintenanceDeposit 3 «وديعة صيانة», Amenity 4, Rett 5, TransferFee 6. **No penalty series.** Installment lines carry Amount, TaxPercent, Tax, TaxCategory, StatusId; no invoice id, no paid amount.
- No installment invoicing in the cloud → every installment is uninvoiced; "paid" can only be the reservation deposit (`ReservationInvoice.InvoicePaidAmount`).
- PM posts only the RETT journal on approve; no recognised-revenue posting, no REM_* types, no delivery / COGS, no credit-note path, payment request type 5 is «تسويق عقاري».
- `Property`: no Sold → Available method; 126303's spec adds `Property.ReleaseSold(saleContractId)` (clears `SaleContractId`, business-check row 1) and PropertyLog event 10 «تنازل».
- **Collision risk with 126303:** both CRs add a document type and nullable refund columns (`PreviousContractStatusId`, `PaidAmount`, `RemainingAmount`, `RefundAmount`) to `Pm_ContractActionDocument`, and both need `Property.ReleaseSold`. 126303 has a spec, no plan, no code yet.
- No "suspended" installment status exists → OQ-c is moot today.
