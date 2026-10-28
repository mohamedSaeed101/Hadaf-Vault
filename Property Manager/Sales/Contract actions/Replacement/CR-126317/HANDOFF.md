# HANDOFF – CR 126317 (Replacement / استبدال العقارات)

- Kind: Change Request → `cr`, stage branch Stage_Beta, Merge Desk Beta.
- ADO 126317 In Development (created by the agent 2026-10-28 at the engineer's ask "plan … and create cr"; fields copied from CR 126303). Merge Desk #13667 Acknowledge, contract change = yes, components Database / Property Manager / Web Container (engineer: "and deployment").
- Set: `C:\Hadaf_Work\worktrees\cr126317` (db, erp, front), branch `cr126317` tracking origin, base Master_Stable, port offset 1000. Front: package.json differs from main checkout → `npm install` in the set (SKIP_INSTALL_SIMPLE_GIT_HOOKS=1) before the front gate.
- Vault: this folder. Source note `..\Replacement.md`, explainer `..\..\شرح - الاستبدال.md`. Siblings: `..\..\Reschedule\CR-126223` (shared Pm_ContractActionDocument, installment Cancelled 3), `..\..\Waivers\CR-126303` (unified reversal deferred there too).
- Deferred: `deferred.md` — everything about قيد عكس الإيراد (engineer, 2026-10-28).

## Preflight (2026-10-28)
| repo | branch | state |
|---|---|---|
| AccFlex_Cloud_Database | cr126317 | new, = origin = Master_Stable |
| AccFlex_Cloud_ERP | cr126317 | new, = origin = Master_Stable |
| AccFlex_Cloud_Front | cr126317 | new, = origin = Master_Stable |
| AccFlex_ERP | none | not touched |

## Step reached
3 Grill. Size **L** (facts.md). **STOP gate 2:** Q1–Q8 in `open-questions.md` wait for the engineer. Next: answers → decisions.md → spec.md → business check → plan.md (plan gate).
