---
type: decisions
cr: 125487
updated: 2026-10-18
source: "[[importUnits v2]]"
---

# CR-125487 — Decisions

The engineer answered the plan-gate questions in [[importUnits v2]] (2026-10-18). Each answer matches the recommendation in [[open-questions]] unless noted.

- **Q1 Rent:** «الإيجار السنوي» is **not in this CR**. The column and its storage come back with the rent-prices CR (annual, and monthly = annual ÷ 12 × 1.05). v2 row 18, BR-6.
- **Q2 / Q3 History and «متاح»:** neither is in this CR. «حالة العقار» comes from the row, or from the project when the cell is blank. The import log is the audit. AC-8 is rewritten in v2.
- **Q4 Building:** no «المبنى» column. A building is a parent property (e.g. KWF-K), entered as a row or already existing, and named in «رقم العقار الرئيسي». v2 BR-9.
- **Q5 Meters:** integers only, ≤ 2,147,483,647. Letters or a larger value → «رقم عداد الكهرباء لازم يكون رقم صحيح» (new AC-9). Leading zeros are lost, the same as on the screen. Still to confirm with the customer that their meter numbers fit.
- **Q6 Model:** a lookup by name; an unknown name → «… مش من القيم المسموحة».
- **Q7 Uniqueness:** the import enforces unique number, name and second name (BR-3 / BR-4). The screen is unchanged.
- **Q8 Inheritance:** done on the server. The property takes from the project: ownership, sales department, cost center, currency, country / governorate / city / center, street and land number; and activity / status when blank. The project's sales department must be linked to the importing user. **New in v2:** «اثبات الإيراد» is **not** inherited, because it is removed from property and project (decision 18/10): the property side here (Q13), the project side in CR-125486.
- **Q9, Q10, Q11:** accepted as recommended (module 935, own log table, 1000 rows / 5 MB, no owner / gas / license / construction-date columns).
- **Q12 Blank model:** guard `Property.cs:119` and `:220`, so a blank model saves with no model (new AC-10).
- **Template:** 19 columns in this CR (v2 rows 2–21, without row 18 الإيجار السنوي).
- **Q13 «اثبات الإيراد» on the property (engineer 2026-10-18): move the property-side removal into this CR.**
  - This CR retires `Pm_Properties.ProofOfIncomeAndExpensesId` (made NULL with no FK, per Q14), and removes the field from `Property` / `PropertyPoco`, the Create/Update Property commands, `PropertyDto`, the property queries, the EF mapping and the Properties form.
  - CR-125486 keeps only the project side (`Pm_Project.ProofOfIncomeAndExpenses`, `Project`, `ProjectDto`, `ProjectInfoDto`, the Projects form).
  - The lookup table `Pm_ProofOfIncomeAndExpenses` stays.
  - Recorded in CR-125486's [[decisions]] too.
- **Q14 Column drop vs the deployer (engineer 2026-10-18):** don't drop `Pm_Properties.ProofOfIncomeAndExpensesId`. Make it `INT NULL` and drop `FK_Pm_Properties_Pm_ProofOfIncomeAndExpenses`. The code no longer maps it, so new rows store NULL. A later release drops the column with an approved data-loss deploy. Widening a column and dropping an FK lose no data, so `BlockOnPossibleDataLoss` does not stop the upgrade.
- **Q15 Amenity `Serves` (engineer 2026-10-18):** fixed in this CR. `amenity-main-grid.component.ts` now uses the API's `AmenityType` ids (`SERVES_PROJECT = 1`, `SERVES_PROPERTY = 2`) instead of the strings 'project' / 'property' (11 places, one file). It is an out-of-ticket fix that the client bump forces; name it in the PR.
- **Q15 follow-up (engineer 2026-10-19):** in `amenity-main-grid.component.ts` the ids are one object, `const AmenityServes = { Project: 1, Property: 2 } as const;` (uses `AmenityServes.Project` / `.Property`), not two separate constants. Front `npm run testing` EXIT 0. Pushed as Front `843ebc3e6d`.
