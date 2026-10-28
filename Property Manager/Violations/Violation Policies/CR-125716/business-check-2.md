---
type: business-check
cr: 125716
round: 2
updated: 2026-10-22
source: "[[spec]]"
---

# Business check round 2 — CR_125716   verdict: pass (0 block; 2 should, one of them confirm-with-PO; 4 nits)

Scope of this round: (a) the round-1 rows against the revised [[spec]] / [[plan]]; (b) what changed since round 1: Q3 (the «سياسة المخالفة» picker, D1–D3), Q8a, Q8b, A9 / A11 / A12 ([[decisions]]). Sources, in place of the KG (still not cloned; PM has no KG coverage, CR-125562 D12): the source note [[Violation Policies]] (§الهدف, §الوصول والتدفق, field 5, field 6, BR-5), CR-125562 decisions.md (D4, D7), and the shipped code in the set: ContractClauseAggregate (ContractClause.cs, ContractClausePoco.cs, ContractType.cs), ContractClauses\Commands\{Create,Update,Delete}ContractClause, ContractClauseController.cs, Pm_ContractClause.sql, ProjectExpenseTypeController.cs / FurnishingController.cs (lookup precedents), and the front contract-clauses\** (form, shell, data service).

## Round-1 rows

| # | status | where |
|---|---|---|
| 1 | resolved | spec line 33 (pre-deploy null script + FK); plan phase 1. See nit row 3: the plan bullet "Rules each phase follows / DB" still says "no pre or post script" |
| 2 | resolved | Q7: Pm_ViolationType, Pm_ViolationApplyMode, reference-data script, FKs (spec lines 31–32) |
| 3 | resolved | Q6: DB CHECKs (spec line 31) |
| 4 | resolved | spec line 31 "Amounts are in the base currency" |
| 5 | withdrawn | CountryEnum.SaudiArabia = 193 exists at projects\logistics\src\app\models\enums\CountryEnum.ts:3; the plan rejection stands. Whether the PM front imports a logistics enum is a code-structure call for the review, not a business rule |
| 6 | resolved | spec line 34 (collation-based, handler compares in SQL) |
| 7 | resolved | spec Out of Scope names the violation half of BR-5 |
| 8 | resolved | spec line 35 (IsActive through Update, no Activate / Deactivate) |

## Round-2 rows

| # | severity | rule | where documented | what the spec breaks | proposed fix |
|---|---|---|---|---|---|
| 1 | should (confirm with PO) | A violation policy fines the **tenant** and hangs on **lease** terms; a contract clause can apply to Sale only (ContractType.Sale = 1, ResidentialRent = 2, CommercialRent = 3, multi-select) | source §الهدف («على المستأجر»), §الوصول («سياسة المخالفة» على شروط **الإيجار**); ContractClauseAggregate\ContractType.cs; ContractClause.Validate (ContractTypeIds required) | Spec lines 42–43 / A11 let any clause carry FinePolicyId, so a Sale-only clause can hold a tenant fine policy that no document will ever apply; a future lease / sale contract reading the clause has no rule to follow | Either (a) the clause handlers reject FinePolicyId when ContractTypeIds holds neither 2 nor 3 (ContractClauseFinePolicyRequiresRentType, resx ar+en) and the form disables / clears the picker on Sale-only clauses, or (b) the PO confirms a sale clause may carry one and the spec says so in one line. Ask the PO; (a) matches the source |
| 2 | should | A lookup lives under the module of the screen that calls it (precedent: ProjectExpenseType/Accounts under 948, Furnishing/Properties under 936, ContractClause/ContractTypes under 935); a user records violations with the rights of the violation log, not of the clause screen | ProjectExpenseTypeController.cs:83, FurnishingController.cs:152, accflex-erp-core.md §ModuleId and policies; D1 ("the violation log CR adds its own lookup") | A9 still calls api/ContractClause/ViolationPolicies "the seam for AC-3", and [[deferred]] (AC-3 row) still points at a GetActive that D1 removed. If the log CR takes A9 at its word and reuses the 935 lookup, recording a violation needs **935 view** (clause rights): a permission-model leak | A9: drop "(the seam for AC-3)"; add to Out of Scope and to the "for the violation log CR" list in [[open-questions]]: «AC-3 lookup = a GetActive on ViolationPolicyController (954), added by the log CR». Update the [[deferred]] AC-3 row to the same wording |
| 3 | nit | A plan must not contradict itself | [[plan]] "Rules each phase follows / DB" vs phase 1 | The DB bullet says «no pre or post script (… the FK column is null everywhere)»; phase 1 adds <ts>_NullContractClauseFinePolicyId.sql (Q2, round-1 row 1). An implementer reading the bullet skips the script | Rewrite the bullet: «table, lookups and FK as model files; one data-only pre-deploy script that nulls FinePolicyId (Q2); module row as reference data» |
| 4 | nit | The vault tells the next session the truth | [[deferred]] section "Deferred to a contract-clause CR (CR 125483)", rows "Approval or tenant notification" and "VAT" | [[deferred]] still defers the picker to CR 125483 (Q3 reversed that), says VAT is decided in the log (Q8b: none, now or later) and does not carry the Q8a "wanted, deferred" | Update [[deferred]]: remove the CR-125483 section (the picker is in scope, A11 / A12); VAT row: «none (Q8b)»; notice row: «wanted before the apply date, designed by the log CR (Q8a)» |
| 5 | nit (confirm with PO) | Penalties are 0 % VAT in the product today, and the VAT flag on a PM catalog row is a PO call, not an engineering one (service items carry IsSubjectToVat, CR-125562 D4 / D7) | source open question 2 («حالياً 0% مثل باقي الغرامات»); CR-125562 decisions.md D4, D7 | Q8b "no VAT field, now or later" is answered by the engineer, not the PO, and binds the posting in the violation log CR. Nothing in this CR blocks an additive IsSubjectToVat later, so the shape is safe either way | Keep "no VAT field in this CR"; phrase the "never" half in Out of Scope as «fines carry no VAT (engineer, Q8b); the PO confirms when the log CR posts the fine». No code change |
| 6 | nit | Apply mode semantics are a field of the policy: «تلقائي» = the fine is added to the lease **on record**; «بعد التأكيد» = held until «تأكيد وتطبيق» | source field 5; Q8a ("notified before the fine apply date") | Q8a implies an apply date later than the record date even for «تلقائي» (record, notice, apply). That changes the meaning of field 5 and may make the notice period a **policy-level** attribute (per violation type), i.e. a future additive column on Pm_ViolationPolicy, not only a log field | Add one line to [[open-questions]] "For the violation log CR": «the notice period may belong on the policy (additive nullable column); field-5 «تلقائي» becomes "applied after the notice period"». No change to this CR table |

## Checked and kept (no row)

- **Q3 picker vs source field 6:** the lookup returns active policies only and keeps the current (possibly inactive) link of the clause through includeId; D2 rejects a *new* inactive id and accepts the unchanged one on update. Matches «غير الفعالة لا تظهر في سياسة المخالفة» without silently breaking an existing clause. Pass.
- **BR-5 (clause half) end to end:** Pm_ContractClause.FinePolicyId is written only through the two clause handlers after D2 validation; the policy delete handler checks Any(FinePolicyId == id) and the FK backs it. DeleteContractClauseCommand removes the clause and its reference, so no orphan. A12 covers link, then delete-rejected. Pass.
- **Shipped clause behaviour:** Create / Update / Validate / Apply gain one optional field; existing tests asserting FinePolicyId == null (ContractClauseValidationTests.cs:53, 249, 292; CreateContractClauseCommandHandlerTests.cs:37) stay true for a command that omits it. ContractClauseDto and SearchContractClausesQuery already project FinePolicyId, so D3 (list unchanged) costs nothing. The front shell builds the PUT from the whole form (buildUpdateCommand), so "clearing saves null" (A11) holds; PUT is full-replace, same as every other field. Pass.
- **Permission model of the picker (D1):** GET api/ContractClause/ViolationPolicies under 935 view is the same contract as ContractClause/ContractTypes; a clause editor fills the picker without 954 rights, like a project-expense-type editor sees GL accounts without GL rights (ProjectExpenseType/Accounts). Consistent. Row 2 is only about the *log* reusing it. Pass.
- **Tenancy / branch:** no Pm_* table carries BranchId / CompanyId; the picker reads the same tenant DB. No cross-reach. Pass.
- **BR-4:** a clause changing its policy affects future violations only; nothing recorded yet. Pass.
- **Q8a, nothing added now:** no notice-days field on the policy; the catalog stays the 10 fields of the source note. Pass (row 6 is a note for the log CR).
- **Q8b, no VAT field:** matches «0% مثل باقي الغرامات» and the late-penalty fields on Pm_InstallmentPlan / Pm_PaymentTerm, which carry no tax flag either. Pass (row 5 is about who signs it).

Round 3: not needed unless the PO answers row 1 with (a), which adds a rule to the clause handlers (then only that rule is re-checked).
