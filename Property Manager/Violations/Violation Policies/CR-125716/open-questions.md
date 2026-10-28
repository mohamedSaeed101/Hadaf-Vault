---
type: open-questions
cr: 125716
updated: 2026-10-22
---

# CR-125716 — Open questions

All answered on 2026-10-22; the decisions are in [[decisions]]. Nothing is open.

- [x] **Q1 Scope.** The policy list only; occurrence counting is deferred to the violation log CR.
- [x] **Q2 FK on the contract clause.** FK + a pre-deploy null script.
- [x] **Q3 «سياسة المخالفة» picker on the contract-clause form.** **Yes, in this CR** (changed from the recommendation).
- [x] **Q4 Module and menu.** 954; 7 › 7_1 › 7_1_1.
- [x] **Q5 Default apply mode.** The front reads it from the company country.
- [x] **Q6 Validation.** First > 0, the rest ≥ 0, DB CHECKs.
- [x] **Q7 Storage.** Lookup tables.
- [x] **Q8 Notice and VAT.** The tenant notice is wanted but deferred to the violation log CR; fines carry no VAT.

- [x] **Q9 Publish to Sabreen for the end-to-end test (phase 9).** Blocked on: the engineer. Recommended: yes, with a cut-down script, not a full dacpac publish (DB `CLAUDE.md`). Run SqlPackage `/Action:Script` against db-all/Sabreen_Primary and keep only: the 3 new tables, `FK_Pm_ContractClause_Pm_ViolationPolicy`, the pre-script null update, the 0467 seed and the module 954 row. Read the diff, then run it. Then run the local PM API on 2619 and the front on 4200 for A1–A12.

## For the violation log CR (not this one)

- Send the tenant a notice before the fine's apply date, and design the notice period. No confirmation after the fine is applied (Q8a).
- BR-2 occurrence counting, AC-1 end to end, AC-2, AC-3 in the log, and the violation half of BR-5.
- Copy the amount onto the violation at record time, so BR-4 holds.
