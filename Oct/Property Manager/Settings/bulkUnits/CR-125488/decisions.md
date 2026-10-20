---
type: decisions
cr: 125488
updated: 2026-10-18
source: "[[bulk Units V2]]"
---

# CR-125488 — Decisions (from [[bulk Units V2]], 2026-10-18)

V2 answers Q1–Q14 of [[open-questions]]. Where V2 and the v1 note differ, V2 wins.

- **Q1 Rent:** not in this CR. No rent column in the grid, no garage rent; it comes with the rent-prices CR.
- **Q2 History and «متاح»:** no history event; «حالة العقار» = the project's status.
- **Q3 `{P}`:** `Project.ProjectNumber`.
- **Q4 Building:** text in the code only; not stored, no parent property per building.
- **Q5 Types:** tenant list `Pm_ProjectType`, default the type named «شقة» when present; new pattern field «نوع الجراج», required when the garage option is on, default the type named «جراج» / "Garage".
- **Q6 Usage:** «نشاط العقار» (`PropertyActivityId`), optional; blank → the project's activity (V2 AC-6); garages take their unit's activity.
- **Q7 Garage values:** pattern inputs «مساحة الجراج» (15) and «سعر الجراج» (35,000), shown with the option (V2 AC-5); floor −1 and rooms 0 fixed.
- **Q8 Composite units:** the garage is a child property (`ParentPropertyId`); no new tab (V2 AC-4).
- **Q9 Model:** no model on generated units or garages; the blank-model guard at `Property.cs:119` / `:220`, identical to CR-125487's decision Q12.
- **Q10 Limit:** 500 rows per save including garages; over the limit → warning and the save button disabled (V2 BR-9, AC-8); the server enforces the same limit.
- **Q11 Import button:** routes to `property-import`, shown only with module 935.
- **Q12 Cost center:** the project's cost center; CR-125486 Q8 makes it non-leaf, so the Properties screen shows it (the business-check row 5 concern is closed).
- **Q13 Exists:** any property in the tenant, trimmed, case-insensitive (V2 AC-7).
- **Q14 Serial:** existing scheme; a clash rejects the batch with «تعارض في كود العقار – أعد المحاولة» (V2 BR-10).

## Wording in V2 read in favour of the answers above

- AC-3 says «مكرر»; the row status is «موجود – هيتخطى» (grid column 7, Q13).
- BR-13 lists «الإيجار» and «المبنى والاستخدام من النمط»; per Q1 / Q4 / Q6 there is no rent, the building is code text only, and usage is the row's activity.
- Grid column 6 «الإيجار» is not shown (fields 13 and 25, Q1).

## Round-2 business check ([[business-check-2]], pass)

- **Q15 Garage area / price (row 14, engineer 2026-10-18):** with the garage option on, «مساحة الجراج» is required and > 0 (pre-filled 15), «سعر الجراج» ≥ 0 (blank = 0); enforced on the server too, with a negative test.
- **Row 13 «اثبات الإيراد»:** not inherited; set id 1 (DB default) while the field exists on `Master_Stable`, following CR-125486 Q2/Q11 and CR-125487 Q13; whichever CR merges second deletes that line.
- **Rows 15–18:** 500-row count = ticked rows + their ticked garages, before the exists check; A5 holds on a بيع project; a null project activity stays null; the garage type default is the first active type named «جراج» / "Garage" in either language.

## Alignment with the shipped siblings (engineer 2026-10-19)

- Module 936, menu group "5" and the DB row use the exact category text of CR-125486 / CR-125487 (`Projects & Properties Tools`); the menu item id is **5_3** and the DB UI name `PropertyBulkGeneration`.
- Stage_Beta already uses group "5" for «إعدادات العقارات» (subgroup "5_1" Installment Plans, module 934). That collision is resolved in CR-125487's Stage_Beta PRs; this CR follows the same resolution when its own PRs open.
- Found while checking: CR-125486 uses module **934**, which Stage_Beta already gives to Installment Plans. Not this CR's code; raised to the engineer.

## Review (2026-10-19, [[review-1]] → [[review-2]], pass)

- **Permissions:** Verify keeps `AddPolicy`; the screen's Save and the properties-list «توليد عقارات» button are gated on Add (`PermissionsHandleService.getPermissionsOfModule`).
- **Transaction seam:** `IPropertyManagerContext` gains `DatabaseFacade Database { get; }` (additive, satisfied by `DbContext`); PM still has no `IApplicationTransaction` — say so in the PR.
- **Bent on purpose:** per-unit `SaveChanges` inside one transaction (serial reads MAX); `MockQueryable.Moq` added to the PM test project (first use in the solution) for async LINQ over lists.
- **At release (`release-ticket`):** keep every `0002_Acc_Module_Data.sql` row when merging with CR-125486 (937) / CR-125487 (935) because the MERGE deletes rows missing from the source; regenerate the PM client and bump the pin from 1.0.108; note on the work item that a mid-batch rollback is proven only with mocks.

## Module 946 and the Stage_Beta menu shape (engineer 2026-10-19)

- Module id is **946** (was 936) in `Module.cs`, the `0002_Acc_Module_Data.sql` row, `routes.ts`, the properties-list button and the shell. The menu follows Stage_Beta's layout: root group "5" «إعدادات العقارات» / "Property Settings", subgroup "5_2" «أدوات المشاريع والعقارات», item **5_2_3**. Edited outside the agent session at 10:58 and confirmed by the engineer.
- Sabreen_Primary still holds the E2E test row `Acc_Module` **936**; swap it to 946 only on the engineer's word.
