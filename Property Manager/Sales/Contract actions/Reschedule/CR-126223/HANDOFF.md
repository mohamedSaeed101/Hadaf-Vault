# HANDOFF – CR 126223 (Reschedule installments)

- Kind: Change Request → `cr`, stage branch Stage_Beta, Merge Desk Beta.
- ADO 126223 In Development (created by the agent 2026-10-26 at the engineer's ask). Merge Desk #13639 Acknowledge, components Database / Property Manager / Web Container, contract change.
- Set: `D:\Hadaf-worktrees\cr126223` (db, erp, front), branch `cr126223` tracking origin, base Master_Stable, port offset 400.
- Vault: this folder. Source note: `..\Reschedule.md`.

## Preflight
| repo | branch | state |
|---|---|---|
| AccFlex_Cloud_Database | cr126223 | clean, = origin |
| AccFlex_Cloud_ERP | cr126223 | clean, = origin |
| AccFlex_Cloud_Front | cr126223 | clean, = origin |

## Size: L
Evidence: DB schema change (new table, 2 columns, status seed, module seed, settings column) + PM API (aggregate method, command, queries, controller) + new Front screen; new behaviour. ~25 files.

## Step reached
4 Spec written 2026-10-27 (spec.md, A1–A7); Q1–Q9 + C1–C3 in decisions.md. Next: business check round 1 → plan.md (plan gate, L). ADO discussion comment with A1–A7 not posted yet (needs the engineer's OK).


## 2026-10-28
- Business check round 2: pass (`business-check-2.md`). Rows 6–8 folded into spec/decisions (CancelledByContractActionDocumentId, first due >= doc date, Amount net + tax drift accepted). Id 4 dropped; rescheduled lines stay Active.
- `plan.md` written (8 phases). **Next: plan gate — engineer approves plan.md, then phase-loop.**
- ADO discussion comment with A1–A7 still not posted (ask first).
- Plan approved by the engineer in the main chat ("I approve plan.md for CR 126223 — run phase-loop now, no commits until I say so"). phase-loop started; **no commits** — changes stay uncommitted in the set. Phase 1 (DB) running.
- Phases 1–8 + appended 7b done (uncommitted in all 3 repos). Module id 964 → **967** (964–966 taken on Sabreen/cr126228). Full PM.Application.Test 858/858; front build exit 0; E2E A1/A2/A4 + line links passed on Sabreen (`test-results.md`, `e2e\`). Findings F1 (popup stale preview, nit), F2 (pre-existing PriceListClient provider bug on sale-contracts), F3 (stage DB deploy dropped our columns on Sabreen once).
- Before shipping: sync the set with origin/Master_Stable (cr126102 merged there; WebMenuGroup 6_3 conflict → keep theirs, add ContractReschedules).
- Review done 2026-10-28: round 1 (Fable reviewer + backend/sql/AP) block 0 · should 8 · nit 11 → applied by Opus implementer (864/864 tests, API Release 0 errors, front build exit 0, client re-synced); round 2 **pass** (`review-2.md`), 5 disagree rows accepted. PR description must state the bent cross-aggregate INT-FK rule (decisions.md).
- **Next (engineer's continue):** remove-redundant + gates, then commit when told, sync with origin/Master_Stable, release-ticket.
- ~~Next: `/review-code 126223`~~ (engineer's trigger). ADO A1–A7 comment still not posted (ask first). Nothing committed or pushed.
