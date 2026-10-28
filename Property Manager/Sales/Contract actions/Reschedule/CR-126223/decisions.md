# CR 126223 – decisions (PO answers, 2026-10-27)

Answers to Q1–Q9 of `open-questions.md`, as relayed by the engineer.

| Q | Decision | Note |
|---|---|---|
| Q1 | Sale contracts only. The lease half waits until the lease contract is built. | Stage_Beta now has module 963 `PropertyManagerLeaseContracts`; it is still out of scope here. |
| Q2 | Only active «قسط» (Installment) lines. Down payment, maintenance deposit, amenities and RETT do not change. | |
| Q3 | Interim rule: lines due on or before the document date stay as they are; AC-3 is partly deferred. When collection is built, the filter returns to BR-1 (not invoiced, nothing paid), so overdue unpaid lines can be rescheduled. | The prototype's `remainingInst` has no due-date cutoff; the interim rule is deliberate. |
| Q4 | Old lines get a cancelled status «ملغي» and are kept. The contract's installments grid gets a «الحالة» column (ساري / ملغي / منقول / معاد جدولته), and the API returns the line status. CR-126102 needs the same, so build it once for both. | **Conflict:** on cr126102 / Stage_Beta, id 2 is already `Transferred «منقول»`, so Cancelled cannot be 2. See C1 and C2. |
| Q5 | Agreed. | **Ambiguous:** the PO's numbering follows the original list, where Q5 was the dedicated `Pm_SaleContractReschedule` table + `RescheduleId` + `CancelledByRescheduleId`. The later recommendation was a generic `Pm_ContractActionDocument` (DOC-YYYY-####), as the prototype does. See C3. |
| Q6 | Copy `InstallmentChangeLimitPercent` byte-identical from cr125733. No warning when it is empty. | |
| Q7 | Warning only. The approval request (REM-PLAN) is deferred. | |
| Q8 | New lines take TaxPercent and TaxCategory from the first remaining line; Tax = Round2. | |
| Q9 | **Rejected.** The menu group «إجراءات العقود» is 6_3, added in cr126102 (on Stage_Beta). Reschedule goes under it, next to «نقل الملكية» 6_3_1 (decision 11/10). If cr126102 is not on Master_Stable yet, copy its 6_3 definition unchanged. | cr126102 is **not** in Master_Stable (checked 2026-10-27). Copy `ContractActions` 6_3 from origin/cr126102. Item → 6_3_2. Module **961 is taken** (SaleContractTransfers, cr126102), 962 by the sold-units report and 963 by lease contracts on Stage_Beta → use **964** (superseded 2026-10-28: **967**, see below). |

## Conflicts — resolved by the engineer 2026-10-27

- C1 → ids 1 Active, 2 Transferred, 3 Cancelled, 4 Rescheduled.
- C2 → «معاد جدولته» is a status on the new lines (id 4).
- C3 → generic `Pm_ContractActionDocument`, code `DOC-YYYY-####`.
- Module 967 (was 964; changed 2026-10-28 — 964 is origin/cr126228 «Update Rent Prices», 965/966 exist on Sabreen), menu 6_3_2.

## Business check round 1 — resolved by the engineer 2026-10-28

- **C2 reversed (rows 1/2).** New lines stay Active (1). «معاد جدولته» is a display status derived from `ContractActionDocumentId` (an Active line linked to a Reschedule document). Id 4 is dropped. Statuses are 1 Active, 2 Transferred, 3 Cancelled. Existing Active filters (GetAllSaleContracts, Pm_Rpt_SoldUnits, cr126102 TransferringInstallments) need no change.
- **Row 5.** Remaining lines are those with DueDate **>=** the document date, matching transfer.
- **Row 3.** Settings.md field 23 / BR-17 (a change above «حد تعديل الأقساط %» goes through approvals) is **knowingly relaxed to a warning** until the REM-PLAN approval request exists (Q7).

## Conflicts as first raised

- **C1** Status ids. Proposal: keep 1 Active and 2 Transferred «منقول» from cr126102 byte-identical, then add 3 Cancelled «ملغي» and 4 Rescheduled «معاد جدولته» for the new lines. The 0466 MERGE carries all four ids.
- **C2** «معاد جدولته»: the PO lists it as a status. Was it meant as a status for the new lines (C1, id 4), or as a note? With it as a status, a rescheduled line is active but not `Active`, and every "active line" filter must cover ids 1 and 4.
- **C3** Q5: dedicated table (original Q5) or the generic contract-action document?

## Business check round 2 advisories — accepted by the engineer 2026-10-28

- **Row 6.** Add `Pm_SaleContractInstallment.CancelledByContractActionDocumentId INT NULL` (FK), set on lines a reschedule cancels.
- **Row 7.** Refuse posting when the first due date is before the document date.
- **Row 8.** Document Amount = Σ cancelled Amount, net of tax. Tax is rounded per line as at approval; the few-piaster drift in Σ Tax is accepted.

## Review round 1 — implementation calls, 2026-10-28

- **Row 2 (Description language).** Stored text stays as spec R10 fixes it: always the Arabic sentence from the neutral `Resource.resx` (`ResourceManager.GetString(..., InvariantCulture)`), numbers formatted with `CultureInfo.InvariantCulture` (`900,000.00`), whatever the poster's culture. Precedent: `ApplySalePricesUpdateCommand` stores its Arabic note the same way. The list shows the stored text to every reader; formatting per reader from OldCount/OldTotal/NewCount was rejected (more code, and the column would then be redundant). The English `Resource.en.resx` value is kept only because every key lives in both files; it is never read.
- **Row 6.** «معاد جدولته» / "Rescheduled" moved to the resource pair `SaleContractInstallmentRescheduled`, exposed as `SaleContractInstallment.RescheduledStatusName(isDefaultCulture)` (the Logic `Resource` class is internal).
- **Row 7 (DOC code race).** Accepted as is: `MAX + 1` inside the transaction, same as SC- / QT- in `GetNextCodeService`; two posts in the same instant race and the loser gets the `UQ_Pm_ContractActionDocument_Code` violation as a save error. Not to be re-investigated unless SC- gets a fix.
- **Row 10 (frequencies).** Kept the constants: `InstallmentPlan/Frequencies` needs module 934 View, which a reschedule user may not have. Labels now come from `translate.stream`, so a language switch or late translation load updates them.
- **Row 15.** `[Range(1, int.MaxValue)]` on SaleContractId / Count / FrequencyId and `[Required]` on FirstDueDate (PM precedent: `CreateInstallmentPlanCommand`). `[Required]` made `FirstDueDate` non-optional in the TS models; client re-synced. The Logic R7 checks stay. The popup never sends these invalid values, so the unlocalized model-state 400 is not reachable from the UI.
- **Row 16 (bent rule).** `ContractActionDocumentId` / `CancelledByContractActionDocumentId` on `Pm_SaleContractInstallment` are INT FKs to another aggregate root, against `accflex-erp-data.md` (cross-aggregate = GUID, no FK). Decided in business check round 2 row 6: PM links aggregates by INT throughout. Say so in the PR description.
