# CR 126223 – facts

- **ADO:** Change Request 126223, created by the agent at the engineer's explicit request ("implement it and create cr", 2026-10-26) from [[Reschedule]]. Fields copied from sibling CR 125808 (area `3- Customer Issues`, Program Property Manager, نواصى العقارية, السعودية, 7.0.82.x, Beta, Paid, due 2026-11-09). Assigned to Mohamed Saeed, state **In Development**.
- **Merge Desk:** #13639, Beta, status Acknowledge, contract change = yes, components Database / Property Manager / Web Container (set by hand at the engineer's ask "create ticket deployment").
- **Branch / set:** `cr126223` in Database, API, WebContainer (Merge Desk, off Master_Stable). Set `D:\Hadaf-worktrees\cr126223`, port offset 400.

## Scope (source: Reschedule.md unless noted)

1. New screen `rem.reschedule`: Real-estate marketing › Contract actions › Reschedule installments (also under Reservation & contracting). No button in the sale contract (decision 11/10); a button on an active lease contract.
2. List of reschedule documents (search, export): document no (DOC-YYYY-####), type, date, contract, property, description «إعادة جدولة n قسط بإجمالي X إلى m قسط», amount (remaining total), status (Posted).
3. Popup: contract (sale Active/Delivered, lease Active), document date (today), new count (6 sale / 4 lease; 0 or empty = 1), frequency (monthly / quarterly / semi-annual / annual; default quarterly), first due (today + 1 month), schedule preview (due, series, amount, tax; 6 rows per page), summary (count and total remaining, new installment, change %).
4. BR-1 remaining = active, uninvoiced, unpaid lines, excluding deposit/penalty/fee series (down payment, maintenance deposit and amenities included if uninvoiced).
5. BR-2 new = total ÷ count rounded to 2 dp, last = total − new × (count − 1); due k = first due + k × period months.
6. BR-3 new lines series «قسط» (sale) / «إيجار» (lease), note «معاد جدولته», tax % of the first remaining line.
7. BR-4 change % = |new − first remaining| ÷ first remaining × 100; above the settings «حد تعديل الأقساط %» → warning «يحتاج اعتماد من نظام الموافقات».
8. BR-5 product should raise an approval request (REM-PLAN, D39) and apply only after approval; prototype does not block.
9. BR-6 invoiced or partly paid lines unchanged; no journal entries (table in the note lists a 2315/1225 adjustment for lease schedules only).
10. BR-7 document created Posted; «تنفيذ وترحيل» disabled until a contract is chosen.
11. AC-1..AC-4 as in the note.
12. Open questions in the note: merging maintenance deposit / amenities / down payment into «قسط» changes credit account and VAT; approval path D39 not built; suspended lines ignored.

## Code facts (scout 2026-10-26, Master_Stable and Stage_Beta)

- Sale contract aggregate exists: `PropertyManager.Logic\SaleContractAggregate\` (SaleContract, SaleContractInstallment, SaleContractScheduleBuilder …), tables Pm_SaleContract, Pm_SaleContractInstallment(+Status).
- Installment line fields: SaleContractId, RowNo, SeriesId, DueDate, Amount, TaxPercent, Tax, TaxCategory, StatusId, AmenityId. **No notes field.**
- Line status: only `Active = 1 «ساري»`. No cancelled / invoiced / paid.
- Series: DownPayment 1, Installment 2, MaintenanceDeposit 3, Amenity 4, Rett 5. No rent / deposit / penalty / fee series.
- Sale contract status: Draft 1, Active 2, Delivered 3, FullyPaid 4, Assigned 5, Transferred 6, Replaced 7, Rescinded 8.
- **No lease contract** in the cloud on any ref.
- `RealEstateSettings.InstallmentChangeLimitPercent` (decimal?, default 10) exists on Stage_Beta (cr125733).
- **No approvals («نظام الموافقات») integration** in PM.
