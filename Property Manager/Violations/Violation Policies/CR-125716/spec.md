---
type: spec
cr: 125716
updated: 2026-10-22
status: Q1–Q8 answered ([[decisions]]); Q3 adds the contract-clause picker
---

# CR-125716 — Spec: Violation Policies (سياسات المخالفات)

Written by the agent itself (to-spec sections), from [[facts]] and the source note [[Violation Policies]]. The KG (`Accflex_KG`) isn't cloned in this workspace, so the grilling ran on the source note, the sibling CR notes and the code on `origin/Master_Stable` / `origin/Stage_Beta`.

## Problem Statement

Property managers fine tenants for violations (noise, littering, damage, breaking lease terms). Today the amount is decided by hand each time, with no rule for repeat offences. The meeting of 11/10 kept late-payment penalties inside the instalment plan and payment term, and asked for a separate catalog of violation policies with tiered amounts.

## Solution

A new Property Manager screen, التأجير › المخالفات › سياسات المخالفات, backed by a new table `Pm_ViolationPolicy` and a CRUD API. Each policy has a code, names, a violation type, an apply mode, an active flag, three tiered amounts and a repeat window. The aggregate exposes `AmountForOccurrence(n)` (BR-3) for the future violation log. The contract-clause form («شروط وأحكام العقود») gains an optional «سياسة المخالفة» picker that saves `Pm_ContractClause.FinePolicyId`, which now has an FK (Q3). Delete of a policy is blocked while a clause references it (BR-5).

## User Stories

1. As a property manager, I add a violation policy with a code, an Arabic name and the fine for the first, second and third-or-later offence, so fines are consistent.
2. As a property manager in Saudi Arabia, a new policy defaults to «بعد التأكيد», because fines there are usually enforced through Ejar or the court.
3. As a property manager, I deactivate a policy I no longer use, so it disappears from pickers without losing history.
4. As a property manager, I can't delete a policy that a contract clause uses.
5. As a property manager, I export the list to Excel.
6. As a property manager, I attach a violation policy to a lease term in «شروط وأحكام العقود», so a breach of that term carries a known fine.

## Implementation Decisions

- **Table** `Pm_ViolationPolicy`: Id, Code NVARCHAR(50) UQ, ViolationPolicyName NVARCHAR(200) (Arabic), ViolationPolicyNameSecondLanguage NVARCHAR(200) NULL (English), ViolationTypeId FK → `Pm_ViolationType`, ApplyModeId FK → `Pm_ViolationApplyMode`, IsActive BIT DF 1, FirstAmount / SecondAmount / ThirdAmount DECIMAL(19,4) (DF 0 for 2nd / 3rd), RepeatWindowMonths INT DF 12, audit columns, RowVer. `CHECK` constraints: FirstAmount > 0, Second / Third ≥ 0, window ≥ 0. Amounts are in the base currency. This copies the `Pm_ContractClause` shape and the `Pm_InstallmentPlan` lookups (Q6, Q7).
- **Lookups** `Pm_ViolationType` (5 rows) and `Pm_ViolationApplyMode` (2 rows), with columns `Id`, `Name`, `NameSecondLanguage` like `Pm_InstallmentPlanLatePenaltyType`, seeded by one reference-data script (Q7).
- **FK** `Pm_ContractClause.FinePolicyId` → `Pm_ViolationPolicy(Id)`. A data-only pre-deploy script first nulls any hand-set values (Q2).
- **Code uniqueness** is case-insensitive through the DB collation, and the handler compares trimmed codes the same way.
- **Aggregate** `ViolationPolicyAggregate\ViolationPolicy` with `Create` / `Update` (trim; required code, `ViolationPolicyName`, type, mode; type and mode ids defined; first > 0; second, third ≥ 0; window ≥ 0; `IsActive` set through `Update`, like the siblings) and `AmountForOccurrence(int n)`:
  - n ≤ 1 → First
  - n = 2 → Second > 0 ? Second : First
  - n ≥ 3 → Third > 0 ? Third : (Second > 0 ? Second : First)
- **Handlers:** code uniqueness on create / update (and the unique-index violation mapped to the same message); delete checks `Pm_ContractClause.Any(FinePolicyId == id)` → `ViolationPolicyUsedInContractClause`.
- **API** `api/ViolationPolicy`: GetAll, `{id}`, POST, PUT, DELETE `{id}`. Module **938**, view / add / edit / delete policies (Q4, changed from 954 by D6).
- **Contract clause (Q3, D1–D3):**
  - `ContractClausePoco` and the create / update commands gain `int? FinePolicyId`, which the aggregate stores.
  - The handlers validate the id. null is fine. A missing id → `ContractClauseFinePolicyNotFound`. An inactive one → `ContractClauseFinePolicyInactive`, unless it is the clause's current value on update.
  - New lookup `GET api/ContractClause/ViolationPolicies?includeId=` under module 935. It returns active policies (id, code, `ViolationPolicyName`, `ViolationPolicyNameSecondLanguage`, type, mode), plus `includeId` even when inactive.
  - The clause list is unchanged.
  - Any clause may carry a policy, whatever its contract types (D4).
- **No VAT** on violation fines (Q8b). No tenant-notice field (Q8a: deferred).
- **Menu:** root group "7" «التأجير» / "Leasing", child "7_1" «المخالفات» / "Violations", item "7_1_1" «سياسات المخالفات» / "Violation Policies" → `violation-policies` (Q4).
- **Front:** a list screen with the 8 columns from facts §5, `dxo-export` like `contract-clauses`, and a popup form with two groups (المخالفة, الغرامة حسب التكرار). It also shows the note that this is separate from the late-payment penalty. New-form defaults: Noise, active, window 12, amounts 0, apply mode by company country (Q5).
- **BR-4** holds by construction: no violation stores a policy yet. The future violation log must copy the amount at record time.

## Acceptance (A1..A12)

- **A1** New form defaults: type إزعاج, active, window 12, amounts 0. Apply mode is «بعد التأكيد» on a KSA company (CountryId 193) and «تلقائي» otherwise.
- **A2** Saving with no code, Arabic name, type or apply mode returns one required message per missing field.
- **A3** Saving with first amount 0 is rejected (AC-4).
- **A4** A duplicate code (after trim) is rejected on create and on update.
- **A5** A negative second or third amount, or a negative window, is rejected.
- **A6** The list shows Code, Violation, Type, 1st, 2nd, 3rd+, Repeat window, Apply mode and Active (user story 3, [[review-1]] row 5), and Export writes the shown rows to Excel.
- **A7** `AmountForOccurrence`:
  - 500 / 1000 / 2000 with n = 3 → 2000 (the amount part of AC-1)
  - 500 / 0 / 0 with n = 3 → 500
  - 500 / 1000 / 0 with n = 3 → 1000
  - 500 / 0 / 2000 with n = 2 → 500
- **A8** Delete of an unused policy succeeds. Delete of a policy referenced by a `Pm_ContractClause` row is rejected with the "used in contract clause" message.
- **A9** The clause lookup `api/ContractClause/ViolationPolicies` excludes inactive policies, but returns `includeId` even when it is inactive. It serves the clause form only; the violation log CR adds its own lookup under its own module (D1), so recording a violation never needs clause-screen (935) rights.
- **A10** Edit saves every field. The menu shows التأجير › المخالفات › سياسات المخالفات to a user with module 938 view, and hides it without.
- **A11** On the contract-clause form, «سياسة المخالفة» is optional and lists active policies only. Save stores it, and reopening shows it. Clearing it saves null.
- **A12** Saving a clause through the API with a missing or inactive policy id is rejected with the matching message. An inactive policy already on the clause still shows, and the clause saves unchanged. After a clause is linked through the picker, deleting that policy is rejected (BR-5 end to end).

## Testing Decisions

- Unit tests in `PropertyManager.Application.Test\ViolationPolicies\` cover A2–A5, A7 and A8, using the CR 125563 test-context pattern. Tests in `ContractClauseTests\` cover A9 and the API half of A12. The existing clause tests that assert `FinePolicyId` is null stay green, because a clause saved without the id still stores null.
- End to end on Sabreen (`local-api-run`, PM API on base + 1200): A1–A12, with screenshots and SQL proof in `test-results.md`.

## Out of Scope

The violation log «سجل المخالفات» and occurrence counting (BR-2, AC-1 end to end, AC-2, AC-3 in the log). The violation half of BR-5 (block delete of a policy used by a recorded violation) is the violation log CR's job. So is the tenant notice before the fine's apply date (Q8a). A policy column on the contract-clause list (D3). VAT: fines carry none (Q8b). Desktop.

## Further Notes

- Siblings touch the same `Module.cs`, `WebMenuGroup.cs`, `WebMenuItem.cs` and `0002_Acc_Module_Data.sql` lines, so expect trivial conflicts on the Stage_Beta PR. Never merge `Stage_Beta` into `cr125716`.
- Source prototype id: `rent.violPolicy`, requirement S21.
