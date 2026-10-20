---
type: decisions
cr: 125563
updated: 2026-10-19
---

# CR-125563 — Decisions

2026-10-19, plan gate: the engineer said "Yes to the plan with all recommended answers Q1-Q11. Run the phases." Every recommended answer in [[open-questions]] is now a decision, and [[spec]] holds them:

- Q1 Link table `Pm_ProjectProjectExpenseType` is created now with no UI; counts show 0 until the project «التكاليف» tab CR.
- Q2 New `Pm_ProjectExpenseType`; `Rst_ExpenseDetails` is not touched and nothing is migrated.
- Q3 Asset accounts: types 6, 7, 16. Expense accounts: types 2, 4, 5. Both must be leaf and active.
- Q4 The capitalised amount counts only revised non-void lines. The guards count any non-void line.
- Q5 Route `project-expense-types`; the id and the menu code are superseded by Q12.
- Q6 Grid with a popup form.
- Q7 The asset account cannot change while the current one carries value.
- Q8 The asset account must have `CostCenterLinked = 1`.
- Q9 «المُرسمل» is gross debits, in company currency, across all branches.
- Q10 Create or change is refused when the new asset account already carries value.
- Q11 Only leaf projects can be linked; the later tab enforces it.
- Q12 (raised by the CR-125562 session; decided by the agent 2026-10-19 with that question's recommendation, after checking): CR-125562 holds module 947 and menu 5_1_4. On Stage_Beta, 5_1_1 is Installment Plans (934), 5_1_2 Contract Clauses (935) and 5_1_3 Furnishing (936). This CR uses **module 948** and **menu 5_1_5**. The engineer can still change it, since nothing is committed.

Standing rule: no commits until the engineer says so. phase-loop leaves changes uncommitted.
- Implementation (phase 4, 2026-10-19): Update re-validates the asset / expense accounts only when they change; uniqueness is always checked. Otherwise an account later made inactive or turned into a parent in GL would block renaming or deactivating the type. "Carries value" checks the line's Void flag only, not the journal's (conservative). The GL flag is `Account.LinkedCostCenter` (column CostCenterLinked).
- Review (2026-10-19): command data annotations limited to [StringLength]. [Required]/[Range] would preempt the localized A9 messages from ProjectExpenseType.Validate. GetById keeps 404 for a missing row, because Ok(null) would open an empty create popup.
