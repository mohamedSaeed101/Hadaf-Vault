# HANDOFF – CR 126303 (Waivers / التنازلات)

- Kind: Change Request → `cr`, stage branch Stage_Beta, Merge Desk Beta.
- ADO 126303 In Development (created by the agent 2026-10-28 at the engineer's ask). Merge Desk #13666 Acknowledge, components Database / Property Manager / Web Container, contract change.
- Set: `C:\Hadaf_Work\worktrees\cr126303` (db, erp, front), branch `cr126303` tracking origin, base Master_Stable, port offset 900.
- Vault: this folder. Source note: `..\Waivers.md`, explainer `..\..\شرح - التنازلات.md`. Sibling: `..\..\Reschedule\CR-126223` (shares Pm_ContractActionDocument, installment status Cancelled 3, ContractActions menu).

## Preflight (2026-10-28)
| repo | branch | state |
|---|---|---|
| AccFlex_Cloud_Database | cr126303 | clean, = origin |
| AccFlex_Cloud_ERP | cr126303 | clean, = origin |
| AccFlex_Cloud_Front | cr126303 | clean, = origin |
| AccFlex_ERP | none | not touched |

## Step reached
2026-10-28: **plan approved by the engineer ("Approve plan")**. origin/cr126223 now pushed (1 commit per repo with ContractActionDocument) → phase 0 copies from `origin/cr126223`. phase-loop started.

2026-10-28 (later): Q1–Q9 answered one by one by the engineer (`decisions.md`; Q2/Q3/Q4/Q8 + RETT deferred → `deferred.md` D1–D12). `spec.md` written (R1–R10, A1–A7). Business check round 1 violations → spec revised; round 2 **pass**. `plan.md` written (phases 0–8). **Next: plan gate — engineer approves plan.md.** Phase 0 (byte-identical copy of CR 126223's shared pieces) is blocked until 126223 is pushed or its set is reachable.

Earlier: 3 Grill (agent self-grill against facts + KG; KG has no waiver coverage). Size **L** (facts.md). **STOP gate 2:** Q1–Q9 in `open-questions.md` wait for the engineer — the note's accounting (recognised revenue, installment invoicing, unified reversal, COGS, credit note) does not exist in the cloud, and CR 126223's shared document table is unpushed. Next: answers → spec.md → business check → plan.md (plan gate).
- 2026-10-28 phase 0 done (DB 9614e366f, ERP ed4476248f); phase 1 DB started.
