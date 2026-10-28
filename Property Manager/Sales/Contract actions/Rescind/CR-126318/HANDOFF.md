# HANDOFF – CR 126318 Rescind / فسخ العقود

- Kind: Change Request → `cr`, stage branch Stage_Beta, Merge Desk Beta. Size **L** (facts.md).
- ADO 126318 In Development (created by the agent 2026-10-28 at the engineer's ask). Merge Desk #13668 Acknowledge, components Database / Property Manager / Web Container, contract change.
- Set: `C:\Hadaf_Work\worktrees\cr126318` (db, erp, front), branch `cr126318` tracking origin, base Master_Stable, port offset 1100. Front `node_modules` not linked (package.json differs): run `npm install` in `AccFlex_Cloud_Front\accflex-erp` with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1` before the front phases.
- Vault: this folder. Source `..\Rescind.md`. Siblings: `..\..\Waivers\CR-126303` (template for decisions), `..\..\Reschedule\CR-126223` (shared document table; pushed to origin/cr126223).

## Preflight (2026-10-28)
| repo | branch | state |
|---|---|---|
| AccFlex_Cloud_Database | cr126318 | clean, = origin (= Master_Stable) |
| AccFlex_Cloud_ERP | cr126318 | clean, = origin |
| AccFlex_Cloud_Front | cr126318 | clean, = origin |
| AccFlex_ERP | none | not touched |

## Step reached
3 Grill (self-grill done). **STOP gate 2:** Q1–Q8 in `open-questions.md` wait for the engineer. قيد عكس الإيراد and everything tied to it is deferred by the engineer → `deferred.md` A (D1–D8); proposed deferrals P1–P5 pend Q1, Q2, Q4, Q6. `plan.md` is a **draft** on the recommended answers.

## Next
Answers Q1–Q8 → `decisions.md` → `spec.md` (ADO comment with A1..An) → business check → revise `plan.md` → plan gate.
