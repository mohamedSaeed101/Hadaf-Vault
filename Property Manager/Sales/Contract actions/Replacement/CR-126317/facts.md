# CR 126317 – facts

- **ADO:** Change Request 126317, created by the agent at the engineer's explicit request ("plan … and create cr", 2026-10-28) from [[Replacement]]. Fields copied from sibling CR 126303 (area `3- Customer Issues`, Program Property Manager, نواصى العقارية, السعودية, 7.0.82.x, Beta, Paid, Web, due 2026-11-09). Assigned to Mohamed Saeed, state **In Development**. No attachments, no comments.
- **Merge Desk:** #13667, Beta, Acknowledge, contract change = yes, components Database / Property Manager / Web Container.
- **Branch / set:** `cr126317` in Database, API, WebContainer; set `C:\Hadaf_Work\worktrees\cr126317`, offset 1000.

## Scope (source: Replacement.md and «شرح - الاستبدال.md»)

1. New screen `rem.replacement`: Real-estate marketing › Contract actions › Replacement (also under Reservation & contracting). No button in the contract (decision 11/10). Requirement M11.
2. List of replacement documents (search, export): document DOC-YYYY-####, type «استبدال عقار», date, old contract, old unit, description «استبدال … بـ … – عقد جديد SC-…», amount = carried paid, status مُرحّل.
3. Popup: contract (sale «ساري»), new unit (Available except current; «code · type · actual price»; fills price), price (actual price from price lists, editable), date (today; new contract date and schedule start), fee type (fixed / % of current net, default fixed – decision 26/10), amount / % (default 0; shows fee + VAT). Summary: current unit, carried paid, new price, difference to schedule.
4. BR-1 new unit required («اختر العقار الجديد»). BR-7 document Posted at once; execute disabled until a contract is picked.
5. BR-2 fee > 0 → installment «رسوم استبدال» on the new contract, due on the replacement date, VAT at the country rate (S, admin service like transfer fee), invoiced from sale-installment follow-up; not deducted from the carried amount.
6. BR-3 carried paid = paid on revenue-installment invoices + collected reservation deposit; difference = price − carried.
7. BR-4 old contract: remaining uninvoiced installments cancelled, status «مستبدل», unit «متاح».
8. BR-5 new contract = copy: new number, date/start = date, new unit, price = net = entered price, discount 0, deposit = carried, no amenities, linked to the old; approved at once with the sale-contract approve logic under the current company policy: schedule = installment plan on the difference from the date, new unit «مباع», deposit settlement per policy, marketer/broker commissions on the new net.
9. BR-6 / BR-8 accounting (unified reversal, REM_Rescind, Cr advances, COGS reversal) → **all deferred** (`deferred.md`).
10. AC-1 fee 1% of 1,000,000 in KSA → line 10,000 + 1,500 VAT on the new contract. AC-2 paid 200,000, new price 1,200,000 → old «مستبدل», unit «متاح», new «ساري» deposit 200,000, schedule on 1,000,000, new unit «مباع». AC-3 new-unit list = Available only, actual price, fills price + difference. AC-4 → deferred (D5). AC-5 no new unit → message, nothing changes.

## Open questions in the source
- OQ-a cost reversal (→ D4). OQ-b commissions charged again on the new contract. OQ-c price < paid: no schedule, no refund. OQ-d button on «تم التسليم» vs eligibility «ساري» (moot: no button). OQ-e new contract takes the current company policy, not the old contract's; unpaid invoices reversed on the customer account (→ D3).

## Code facts (scout 2026-10-28, cr126317 = Master_Stable tip; see also `..\..\Waivers\CR-126303\facts.md`)
- Create: `CreateSaleContractCommand` → `SaleContract.Preview(poco)` → `GetNextSaleContractCode` (`SC-yyyy-0000`, GetNextCodeService.cs:89) → `SaleContract.Create` (Draft). Input `SaleContractInput` (TypeId, ContractDate, InstallmentsStart, CustomerId, PropertyId, InstallmentPlanId, SalePrice, Discount, RETT flags, Broker*, Buyers, Amenities, ClauseIds, SaleQuotationId).
- Schedule: `SaleContractScheduleBuilder.Build` on `SalePrice − Discount`. **No deposit / carried-paid field on the contract and no ReservationId**; nothing is subtracted before scheduling.
- Approve: `ApproveSaleContractCommand` (own transaction): sales-org check, Preview, `contract.Approve` (Draft only → Active, RevenueMethod Manual), `IsAvailableForSale`, `MarkSold`, PropertyLog, RETT journal when RETT on seller. **No commission posting** (broker amount is a field only). Own `BeginTransaction` → cannot nest; needs extraction to a shared service to run inside the replacement transaction.
- Link: `SaleContract.PreviousContractId` exists (set by Transfer) — reusable.
- Series: 1 DownPayment, 2 Installment, 3 MaintenanceDeposit, 4 Amenity, 5 Rett, 6 TransferFee. Transfer adds its fee line with country VAT (`CountryTax`, TaxTypeId 2), fails `VatPercentMissing` when null. Installment status Active 1, Transferred 2; **no Cancelled 3** on Master_Stable.
- Actual price: `GetEffectivePriceQuery{PropertyId, PriceKind, Date}` → `EffectivePriceDto.EffectivePrice`.
- Property: Reserve / Release / MarkSold / TransferSale; **no Sold → Available** (CR 126303 plans `ReleaseSold(saleContractId)`).
- Template: SaleContractTransfers (controller, Transfer command saving old before new for the one-live-contract index, document, PropertyLog, one transaction, sales-org check; Front module `sale-contract-transfers`).
- Shared pieces: `origin/cr126223` now carries Pm_ContractActionDocument(+Type, +Status) in DB (bb394a61b) and reschedule code in ERP (81361014). `origin/cr126303` = Master_Stable (no work pushed).

## Size: L
DB (document type, contract carried-paid column, fee series, status/module seed) + PM Logic/App/API (new aggregate methods on SaleContract and Property, approve extraction, command, queries) + new Front screen; new behaviour, > 15 files.
