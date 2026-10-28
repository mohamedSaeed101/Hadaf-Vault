---
type: test-results
cr: 125716
updated: 2026-10-22
---

# CR-125716 — Test results (phase 9, end to end)

## Setup

- **Tenant:** db-all / Sabreen_Primary (company Sabreen; the company-info call returned CountryId 193, KSA).
- **Schema:**
  - The cut-down script (scratchpad `cr125716-sabreen.sql`) was applied after a COPY_ONLY backup `Sabreen_Primary_cr125716_20261022.bak`.
  - Contents: 3 tables, `FK_Pm_ContractClause_Pm_ViolationPolicy`, pre-script logic, the 0467 seed and module 954.
  - Check after the apply: 5 types, 2 modes, FK present, module 954, 0 clauses with a policy (the pre-script nulled nothing).
- **PM API:**
  - Set Debug build, `http://localhost:2619` (1419 + 1200), Development, Authority localbeta.
  - DebugTenantConnection pointed at Sabreen.
  - **Override proof:** `sys.dm_exec_sessions` showed `Sabreen_Primary | cr125716-pm-local | DESKTOP-KPT7EFB` right after the first GetAll.
- **Front:**
  - `npm run dev` on :4200, with a regenerated PM client in `node_modules`.
  - `config.json` was edited locally (propertymanagerapi → localhost:2619, miscapi / dashboard → localbeta) and restored at teardown.
  - The engineer signed in; the agent picked Sabreen.
- **Method:** UI in the browser pane for A1, A2 (client side), A6, A11 and creating NOISE-01. API calls from the page with the user's token for the server-side rules. SQL for proof.

## Results

| A | Check | Result |
|---|---|---|
| A1 | New form: type إزعاج, active, window 12, amounts 0/0/0; apply mode «بعد التأكيد» on a KSA company (CountryId 193) | **pass** (form values read from the popup). The non-KSA branch («تلقائي») is not verified: there is no non-KSA PM tenant. |
| A2 | Required fields | **pass.** UI: Save with an empty form flags Code / Name / First amount, and no POST is sent; type and mode can't be emptied because they default. API `POST {}` returns 400 with 5 messages: code, name, type, mode, first amount. An undefined type id 9 returns the type message. |
| A3 | First amount 0 rejected | **pass** (400 «غرامة المرة الأولى يجب أن تكون أكبر من صفر»). |
| A4 | Duplicate code | **pass.** `" NOISE-01 "` and `"noise-01"` are rejected on create, and an update to another policy's code is rejected («كود السياسة مستخدم من قبل»). An update keeping its own code returns 200. |
| A5 | Negative 2nd / 3rd / window rejected | **pass** (400, two messages). |
| A6 | List columns and export | **pass.** The grid shows Code, Violation, Type, 1st, 2nd, 3rd+, window, apply mode, active, edit, delete, and the Excel export button is present. The export file wasn't downloaded. |
| A7 | `AmountForOccurrence` tiers | **pass (unit tests only).** 8 cases in `ViolationPolicyAggregateTests`. No endpoint exposes it until the violation log CR. |
| A8 | Delete | **pass.** LITTER-01 (unused) deleted with 200; deleting it again returns 400 «سياسة المخالفة غير موجودة». NOISE-01, linked to clause 3, returns 400 «السياسة مستخدمة في شرط من شروط العقود». |
| A9 | Clause lookup | **pass.** Without includeId it returns active policies only, ordered by code (LITTER-01, NOISE-01). With includeId=3 it adds inactive DAMAGE-01, with type and mode names. |
| A10 | Edit saves every field; menu | **pass.** A PUT changing all 10 fields of DAMAGE-01 returned 200, GET matched every field, and the original was restored. `GET api/MenuList` returns 7 «التأجير» › 7_1 «المخالفات» › 7_1_1 «سياسات المخالفات» (module 954, route `violation-policies`) for this user. Not verified: the menu hidden for a user without 954 view (needs a second user); the drawer itself is served by the remote environment. |
| A11 | Picker on the clause form | **pass.** The picker on clause PO-TEST-125483 lists active policies only («LITTER-01 - رمي مخلفات في الممرات», «NOISE-01 - إزعاج الجيران»). Picking NOISE-01 and saving from the toolbar gave PUT `api/ContractClause/3` 200, and SQL shows `FinePolicyId = 1 (NOISE-01)`. On edit, the lookup is called with the clause's current FinePolicyId. Clearing it saves null (checked through the API). |
| A12 | Clause validation | **pass.** FinePolicyId 999 → «سياسة المخالفة المختارة غير موجودة». Picking an inactive policy → «… غير نشطة». After NOISE-01 was deactivated, the clause already linked to it still saved (200), and the lookup with includeId=1 still returned it. Delete of the linked policy was blocked (A8). NOISE-01 was then reactivated. |

## Observations (not failures)

- **The popup is taller than the 536 px browser pane:** Save sits below the fold and the popup doesn't scroll at that height. It was tested at a 1000 px emulated height. Worth a look in review if small laptop screens matter.
- **Clause toolbar hidden at narrow width:** at the pane's 681 px width the contract-clause toolbar (save / edit) is hidden. This is the shipped screen's behaviour, not this CR's.
- **Required markers before Save:** the policy form shows required errors on Code / Name / First amount as soon as New opens, before any Save attempt.

## Data left on Sabreen

- Policies NOISE-01 (id 1, active) and DAMAGE-01 (id 3, inactive); LITTER-01 was deleted.
- Clause PO-TEST-125483 is back to FinePolicyId NULL.
- The schema stays applied. The backup is available to roll back.
