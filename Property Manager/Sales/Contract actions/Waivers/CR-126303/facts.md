# CR 126303 – facts

- **ADO:** Change Request 126303, created by the agent at the engineer's explicit request ("plan … and create cr", 2026-10-28) from [[Waivers]]. Fields copied from sibling CR 126223 (area `3- Customer Issues`, Program Property Manager, نواصى العقارية, السعودية, 7.0.82.x, Beta, Paid, Web, due 2026-11-09). Assigned to Mohamed Saeed, state **In Development**. No attachments, no comments.
- **Merge Desk:** #13666, Beta, status Acknowledge, contract change = yes, components Database / Property Manager / Web Container (set at the engineer's ask "and ticket deployment").
- **Branch / set:** `cr126303` in Database, API, WebContainer (Merge Desk, off Master_Stable).

## Scope (source: Waivers.md and «شرح - التنازلات.md» unless noted)

1. New screen `rem.waivers`: Real-estate marketing › Contract actions › Waivers (also under Reservation & contracting). No button in the contract (decision 11/10).
2. List of waiver documents (search, export): document (DOC-YYYY-####), type «تنازل», date, contract, property, description («تنازل للشركة، رد …»), amount (waiver fee), status (مُرحّل / ملغي).
3. Popup «تنازل عن العقار»: contract (sale «ساري» / «تم التسليم»), date (today), waiver fee (optional, default 1% of contract net); summary bar: current customer, paid, remaining; impact warning; «تنفيذ وترحيل» disabled until a contract is picked (BR-7).
4. BR-1 paid = paid on revenue-installment invoices + collected reservation deposit; remaining = sum of remaining uninvoiced installments.
5. BR-2 waiver to the company only (decision 26/10, CR 126102: new buyer goes through «نقل الملكية»).
6. BR-3 cancel remaining uninvoiced installments; contract → «متنازل عنه»; unit → «متاح»; entry `REM_Waiver` = unified reversal + Cr 2350 customer refunds payable (paid − fee) + Cr 4140 service revenue (fee); recognised amount on the contract back to 0; credit note on the customer account for the refund (D09); payment request type 5 «مرتجع عميل عقاري» (D24).
7. BR-4 document stores a pre-execution snapshot: customer, contract status, unit status, installment statuses.
8. BR-5 «إلغاء التنازل» on a Posted waiver: restore from snapshot, cancel the fee line if not invoiced, document → «ملغي», add a reversal document «ملغي» on the contract.
9. BR-6 cancel posts the reversal of the waiver entry (and of the COGS reversal if any) and restores the recognised amount. Prototype does NOT cancel the credit note / payment request nor check the unit was not re-sold — **the product must cancel them and block cancel if the unit status changed.**
10. BR-8 delivered contract with a cost entry: reverse `REM_COGS` (Dr 1312 / Cr 5112, same amounts as the delivery entry), unit back to stock without increasing the type balance.
11. BR-9 unified reversal (shared with rescission and replacement), reverses what was actually recognised: Dr recognised revenue (4110 sale revenue, or brokerage commission + owners' payable for another owner's unit) + Dr output VAT on issued invoices (2410) / Cr contract receivable 1215 by (recognised − invoiced; debit if invoiced is larger); before delivery under the «on delivery» policy Dr customer advances instead of 1215; Cr customer account by unpaid invoices (one line per invoiced customer). Invoiced = revenue-installment invoices before tax (excluding maintenance, RETT, amenities, fees, penalties) + deposit; paid = paid on the same invoices + deposit.
12. AC-1 net 1,000,000, paid 200,000, fee 10,000 → contract «متنازل عنه», unit «متاح», credit note and payment request 190,000.
13. AC-2 cancel restores the previous customer, contract and unit status; document «ملغي» plus a reversal document.

## Open questions in the source

- OQ-a Decision 15/10: waiver reverses actual recognised + unpaid invoices — confirm unpaid invoices are cancelled by a credit note.
- OQ-b Payment request is created even when the refund ≤ 0 (fee > paid).
- OQ-c Default 1% fee is hard-coded — from General Settings?
- OQ-d No permission / approval for the waiver in the source.

## Code facts (scout 2026-10-28, origin/Master_Stable, origin/Stage_Beta, origin/cr126303)

- Contract status: `SaleContractStatus` Draft 1, Active 2, Delivered 3, FullyPaid 4, **Assigned 5 «متنازل عنه»** (= waived), Transferred 6, Replaced 7, Rescinded 8. Only `Approve` (Active) and `Transfer` (Transferred) set a status; nothing sets Delivered/Assigned/Rescinded.
- Unit status: `PropertyStatus` Available 1, Reserved 2, Sold 3, Rented 4, UnderMaintenance 5. `Property.MarkSold` (Property.cs:416) from ApproveSaleContract; **no Sold → Available** method.
- Installment line: no invoice id, no paid amount; statuses Active 1 (+ Transferred 2 on Stage_Beta). **No installment invoicing anywhere** → in the cloud every installment is uninvoiced; "paid" can only be the deposit.
- Deposit: `ReservationInvoice` read model (InvoiceId, InvoiceTotal, InvoicePaidAmount, IsInvoiceVoid); collected = `InvoicePaidAmount` (GetReservationByIdQuery.cs:81); built by `ReservationDepositInvoice.cs` (CashControl invoice).
- Journals: PM posts only the RETT journal on approve (`NormalJournalBuilder`, `JournalType.ContractJournal` 19, accounts from RealEstateSettings ids). **No recognised-revenue posting, no REM_* types, no unified reversal, no delivery / COGS.** `CreateJournalsManually` flag exists.
- Payment request: CashControl `PaymentRequestType` 5 = RealEstate «تسويق عقاري» (not «مرتجع عميل عقاري»). PM creates none today.
- Credit note: no PM path; only CustomerMemo aggregates in Logistics / StockControl and Construction OwnerMemo.
- RealEstateSettings: DefaultTransferFee, RettPercent, Rett accounts, UnbilledSaleReceivablesAccountId, PropertyStockAccountId, AmenityRevenueAccountId, InstallmentChangeLimitPercent … **no waiver fee %, no refunds-payable / service-revenue account**.
- Contract actions: menu group `ContractActions` 6_3 + SaleContractTransfers 6_3_1 on Stage_Beta (cr126102). **`Pm_ContractActionDocument` and installment status Cancelled 3 (CR 126223) are on no remote ref** — uncommitted in the cr126223 set.
- KG: no note or glossary term for تنازل / فسخ / مثبت; closest `Accflex_KG\RealEstateMarketing\Sell Contract Core Cycle\`, `Sell Contract GL & Commissions Cycle\` (legacy desktop).

## Size: L
DB (document reuse, settings columns, statuses, module seed) + PM Logic/App/API (aggregate methods on SaleContract and Property, command, cancel command, queries, journal) + CashControl integration (payment request) + new Front screen; new behaviour.
