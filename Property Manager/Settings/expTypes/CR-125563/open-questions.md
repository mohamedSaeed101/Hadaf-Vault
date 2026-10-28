---
type: open-questions
cr: 125563
updated: 2026-10-19
---

# CR-125563 — Open questions (for the plan gate)

Each has the recommended answer already written into [[spec]]. Q8–Q11 come from [[business-check-1]].

- [x] **Q1 Project ↔ type link.** Recommended: create the link table `Pm_ProjectProjectExpenseType` now (no UI); counts show 0 until the project «التكاليف» tab CR fills it. Alternative: drop the two columns and the usage check from this CR.
- [x] **Q2 Table.** Recommended: new `Pm_ProjectExpenseType`; desktop `Rst_ExpenseDetails` untouched, no migration.
- [x] **Q3 Account types.** Recommended: asset = leaf active types 6, 7, 16 (prepaid 18 dropped); expense = 2, 4, 5. The customer picks whichever fits their chart (answers the note's open question).
- [x] **Q4 "Posted".** Recommended: capitalised amount counts revised (`Revised = 1`) non-void lines only; delete / asset-change guards count any non-void line (conservative).
- [x] **Q5 Module / menu.** Recommended: module **947**; root "5" › "5_1" «البيانات الأساسية للعقارات» › item **5_1_2**, route `project-expense-types`.
- [x] **Q6 Layout.** Recommended: grid + popup form. Alternative: inline cell editing like payment terms.
- [x] **Q7 Changing the asset account.** Recommended: refuse while the current account carries value.
- [x] **Q8 Cost-centre-linked asset account.** Postings to an account not linked to cost centres carry no cost centre, so the type would never show cost. Recommended: the asset lookup and the API accept only `CostCenterLinked = 1` accounts. Alternative: allow with a warning.
- [x] **Q9 Which figure is «المُرسمل».** Recommended: gross capitalised (debits only); the "charged on handover" and "remaining" figures belong to the project «التكاليف» tab. Alternative: net balance (debit − credit).
- [x] **Q10 Asset account already used elsewhere.** Recommended: refuse create / change when the chosen account already carries value (BR-2's own reason: the type's balance must be its own). Alternative: warning only.
- [x] **Q11 Parent projects.** Recommended: only leaf projects can be linked to types (parents have no cost centre, D32); the later «التكاليف» tab enforces it. Alternative: roll sub-projects up into the parent.

- [x] **Q12 (from CR-125562, 2026-10-19)** Module **947** and menu **5_1_4** are taken by CR-125562 (engineer's call), and **5_1_2** is ContractClauses (cr125483). *Recommended:* module **948**, menu **5_1_5**.
