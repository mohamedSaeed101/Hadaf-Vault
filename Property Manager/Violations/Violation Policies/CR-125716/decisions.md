---
type: decisions
cr: 125716
updated: 2026-10-22
---

# CR-125716 — Decisions

The engineer answered Q1–Q8 one by one on 2026-10-22. The questions are in [[open-questions]].

| Q | Decision | By |
|---|---|---|
| Q1 | **The policy list only.** BR-3 is built as `AmountForOccurrence(n)`. BR-5 is checked against `Pm_ContractClause.FinePolicyId`. BR-2, AC-1 end to end, AC-2 and AC-3 (in the log) wait for the violation log CR. | engineer (recommended; asked twice, confirmed) |
| Q2 | Add `FK_Pm_ContractClause_Pm_ViolationPolicy` (renamed from `FK_Pm_ContractClause_ViolationPolicy` per `db-rules.md` `FK_FromTable_ToTable`, sql-reviewer nit), with a data-only pre-deploy script that nulls hand-set `FinePolicyId` values on every tenant first. **Superseded by D9: the pre-script is removed.** | engineer (recommended) |
| Q3 | **Changed from the recommendation: add the «سياسة المخالفة» picker to the contract-clause form now.** It is optional and offers active policies only. Create and update save `FinePolicyId`, so BR-5 becomes testable end to end. | engineer |
| Q4 | Module ~~954~~ **938** (D6). New menu root "7" «التأجير», child "7_1" «المخالفات», item "7_1_1" «سياسات المخالفات». | engineer (recommended) |
| Q5 | The front defaults the apply mode from the company `CountryId`: 193 (KSA) → «بعد التأكيد», anything else → «تلقائي». The API stores what is sent. | engineer (recommended) |
| Q6 | First amount > 0. Second, third and window ≥ 0, with no ordering between tiers. Amounts are `DECIMAL(19,4)` in base currency. The rules are enforced in the aggregate and as DB `CHECK`s. | engineer (recommended) |
| Q7 | Lookup tables `Pm_ViolationType` (5 rows) and `Pm_ViolationApplyMode` (2 rows), seeded by one reference-data script, with FKs from the policy. | engineer (recommended) |
| Q8a | **Tenant notice before the fine applies: yes in principle, deferred.** The tenant should be notified before the fine's apply date, and no confirmation is needed after the fine is applied. Nothing is added in this CR (no notice-days field); the violation log CR designs it. | engineer |
| Q8b | **Violation fines carry no VAT.** No VAT field, now or later. | engineer |

## Agent calls that follow from Q3

- **D1 Where the picker reads from.** The lookup lives on `ContractClauseController` as `GET api/ContractClause/ViolationPolicies?includeId=`, under module **935** (contract clauses). A user who can edit clauses can then fill the picker without view rights on 954. It returns active policies, plus `includeId` when that one is inactive, so an existing link still shows. `ViolationPolicyController` has no separate GetActive; the violation log CR adds its own lookup.
- **D2 Validation of `FinePolicyId` on clause save.**
  - null: allowed.
  - Not found: `ContractClauseFinePolicyNotFound`.
  - Inactive: rejected (`ContractClauseFinePolicyInactive`) unless it is the clause's current value on update.
- **D4 Contract type of the clause (engineer, [[business-check-2]] row 1).** Any clause may carry a fine policy, including a Sale-only clause (`ContractType` 1). There is no check on the clause's contract types.
- **D5 Name columns (engineer).** On `Pm_ViolationPolicy`, the policy's own name columns are `ViolationPolicyName` (Arabic, required) and `ViolationPolicyNameSecondLanguage` (English, optional), not NameAr / NameEn. The entity properties and DTO fields use the same names. The two lookup tables follow the PM lookup convention, `Name` / `NameSecondLanguage` (`Pm_InstallmentPlanLatePenaltyType`), rather than the `NameAr` / `NameEn` that Q7's wording implied.
- **D6 Module id 938 (engineer, 2026-10-22, during review round 1).** The module is **938**, not 954. 938 is unused on all 661 origin refs in ERP and DB. On Sabreen, 954 already belonged to "Work Teams" (Payroll, app 4) from unpushed work. This supersedes the 954 in Q4.
- **D7 Bent rule: unpaginated GetAll** ([[review-1]] row 11). `GET api/ViolationPolicy/GetAll` returns the whole catalog, against `accflex-erp-api.md` §API Layer "Always paginate list endpoints". Why: a small configuration catalog; the A6 grid and Excel export need every row; same as the sibling `ProjectExpenseTypeController.GetAll`. Cite in the PR description.
- **D8 Bent rule: `Id` PK column** ([[review-1]] row 7). `Pm_ViolationPolicy.Id`, not `ViolationPolicyId` (`accflex-erp-data.md`), to match `Pm_ContractClause` / `Pm_ProjectExpenseType`. Cite in the PR description.
- **D3 Clause list.** The contract-clause list is unchanged: no new column. The picker shows only in the form.
- **D9 No pre-deploy null script (engineer, 2026-10-22, after release).** `20261022144037_NullContractClauseFinePolicyId.sql` is removed: no customer has data in `Pm_ContractClause.FinePolicyId`, so the FK deploys cleanly without it. Risk accepted: a tenant with a hand-set `FinePolicyId` would fail the FK on upgrade (Sabreen has 0 such rows). Supersedes the script half of Q2.
- **D10 Menu ids 7_2 / 7_2_1 (engineer, 2026-10-25).** On Stage_Beta, cr125720 owns `7_1` / `7_1_1` (Rental Reports). Violations moves from `7_1` / `7_1_1` to `7_2` / `7_2_1` on cr125716 too, so Master matches Stage_Beta. This supersedes the sub-ids in Q4; root `7` stays.
