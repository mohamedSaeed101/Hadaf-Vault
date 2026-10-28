---
type: handoff
cr: 125733
kind: CR
branch: cr125733
base: Master_Stable
repos: db, erp, front
portOffset: 1300
updated: 2026-10-22
---

# CR-125733 — HANDOFF: Real Estate General Settings (الضبط العام)

## Where we are

| Step | State | Artifact |
|---|---|---|
| 0 Preflight | done 2026-10-22 | ADO CR 125733 created (In Development, Mohamed Saeed); Merge Desk #12602 (Beta, Acknowledge, contract change, components Database / Property Manager / Web Container); `cr125733` on origin in API / WebContainer / Database |
| 1 Intake | done | [[facts]] |
| 1b Size | **L** (3 repos, schema change, new contract, 7-tab front, ~45 files) | [[plan]] |
| 2 Set | done | `D:\Hadaf\worktrees\cr125733\` (db, erp, front on `cr125733`, clean), port offset 1300; front `npm install` still needed |
| 3 Grill | done (agent, self-interview; engineer answered one by one 2026-10-22) | [[open-questions]], [[decisions]] |
| 4 Spec | done | [[spec]] A1–A10; acceptance list posted as an ADO comment |
| 5 Business check | **not run** (the KG repo is not cloned; GL rules read from code) | run `business-check` before implementation if the engineer wants it |
| 6 Plan | **gate passed 2026-10-22** | [[plan]] 12 phases, waves A–G |
| 7 Implement | done, committed and pushed 2026-10-25 | run log in [[plan]]; module id 953 (Q11, was 937 under Q10) |
| 10 E2E | **done 2026-10-22** on Sabreen (schema + seeds applied, API on 2718, front on 4200) | [[test-results]], screenshots/, cr125733-sabreen-schema.sql, cr125733-sabreen-seed.sql |
| 11 Review | **pass 2026-10-22** (Fable 5.1 reviewed, Opus 5.5 applied; round 1: 1 block / 13 should / 14 nit → round 2: 0 / 0 / 0) | [[review-1]], [[review-2]]; gates after the fixes: sqlproj 0 errors, API build 0 errors, 610/0 tests, client regenerated, tsc 0, `npm run testing` 0, prettier clean |
| 13 Release | **done 2026-10-25**: pushed tips DB 7c9a116b1 / ERP 8776bae5ff / Front 26e99993fa (origin/cr125733); Merge Desk 12602 Solved; ADO 125733 Solved + PR comment; Merge Desk PRs to Stage_Beta: API 68226 (Conflicts), WebContainer 68227 (Conflicts), Database 68228 (Abandoned, by someone else after it was opened) | stage branches cut 2026-10-25 (next row) |
| 14 Stage_Beta | **done 2026-10-25**: `cr125733_Stage_Beta` in all 3 repos (DB f85166927 via worktree `cr125733_Stage_Beta_db`, ERP 1cc50831fa, Front 32237d2ef7), gates green (sqlproj 0 err; API 0 err + 841/0; tsc 0 + testing 0); DB PR 68292 **Completed** into Stage_Beta 09:47 UTC (auto-complete set by the other session, source branch deleted on the remote); API 68306 / Web 68307 Active, merge check clean, awaiting PR Approval Develop; 68226, 68227, 68228 abandoned; set back on cr125733, clean | watch the PRs; remove the set when the engineer is done |
| 12 Cleanup | **done 2026-10-22**: `remove-redundant` found 0 removals across the 3 repos (3 low-confidence lookup members kept as seed data; CurrencyCode/VatPercentage read by the general tab); gates unchanged | next: `release-ticket` on the engineer's word (commit by path first) |

## Key decisions so far

- The screen extends cr125638's `Pm_RealEstateSettings` / module 953 / route `real-estate-settings` (Stage_Beta only; no Master_Stable PR yet) with identical names, so the Stage_Beta merge is add/add "keep both" (Q1).
- `Pm_ProofOfIncomeAndExpenses` is reused as the sale revenue-recognition policy of the company: row 3 «نسبة الإنجاز» added, exposed by `GET api/RealEstateSettings/ProofOfIncomeAndExpenses` (Q3).
- Five mandatory accounts (BR-6 wins over BR-13), new menu group 5_3 «الإعدادات والصلاحيات», lookups as PM tables + static lists, country as `ACFX_Country` FK listing **all active countries** with neutral defaults outside SA / AE / EG, dunning stages as **four fixed slots** on the row, no child table (Q2, Q4, Q6, Q7, Q8).
- Consumers are out of scope (Q9).

## Next step

Nothing pending on the engineer's side except: `remove-cr.ps1 -Id 125733` when done with the set (also the extra DB worktree `D:\Hadaf\worktrees\cr125733_Stage_Beta_db`). If Stage_Beta moves before the PRs merge, re-merge origin/Stage_Beta into each `cr125733_Stage_Beta` (never into `cr125733`).

## Resume prompt

```
Resume CR 125733 (Real Estate General Settings). Set D:\Hadaf\worktrees\cr125733 (offset 1300).
Vault: D:\Hadaf\Hadaf Vault\Oct\Property Manager\Settings\Settings\CR-125733\ (facts, spec, open-questions, plan, HANDOFF).
Released 2026-10-25 (pushed, Merge Desk Solved, ADO Solved; module id 953). Stage_Beta: DB PR 68292 merged; API 68306 / Web 68307 open from cr125733_Stage_Beta. Next: remove-cr when done.
```
- 2026-10-22 phase 3 done (build green, uncommitted); phase 4 launched; phase 1 running
- 2026-10-22 phase 1 done (sqlproj green, uncommitted); phase 2 launched; phase 4 running; front npm install done
- 2026-10-22 phase 4 done (build green, uncommitted); phase 5 launched; phase 2 running
- 2026-10-22 phase 2 done (sqlproj green, publish preview at C:\Users\Hadaf\AppData\Local\Temp\publish-Sabreen_Primary-20261022155423.sql needs cutting down before apply); phase 5 running
- 2026-10-22 phase 5 done (build green, uncommitted; CurrencySymbol = code, VAT = GL ValueAddedTaxPercent); phases 6 and 7 launched
- 2026-10-22 phase 7 done (build green, swagger 13 ops, uncommitted); phase 8 launched; phase 6 running
- 2026-10-22 phase 8 done (client regenerated, tsc green; other CRs' synced client files must not be staged); phase 9 launched; phase 6 running
- 2026-10-22 phase 6 done (43 tests, 608/608 pass, uncommitted); phase 9 running
- 2026-10-22 engineer: module id 937 (not 953); Module.cs + 0002 changed, routes.ts pending phase 9; decisions.md Q10
- 2026-10-22 phase 9 done; routes.ts ModuleId 937; all gates green; loop stopped before phase 10 (needs the engineer OK to publish to Sabreen)
- 2026-10-22 phase 10 done: Sabreen schema + seeds applied (cut-down), A1–A10 walked (A4 partial), teardown done; findings in test-results.md; a parallel deploy (cr125720) deleted module 937/938 and proof row 3 mid-run (row 3 re-seeded)
- 2026-10-22 review round 1 (1 block / 13 should / 14 nit) applied by the implementer (23 done, 5 nits declined; CurrencyCode + VatPercentage moved into CountryDefaults, module 937 renamed "Property Manager General Settings" / «الضبط العام», cap decimal(19,4), InMemory persistence test, front form built once); round 2 pass; all gates green; nothing committed
- 2026-10-22 remove-redundant: 0 candidates (DB, ERP, Front scans); noticed, not touched: pre-existing duplicate 0328 `None Include` in the sqlproj (lines 418 / 4690)
- 2026-10-23 demo video (captions only) recorded on the local Sabreen run: demo/demo_125733_general-settings_captions-only.mp4; Gemini daily quota ran out after line 1 → regenerate lines 2-8 with tts.py --per-line and make.py --rebuild from the scratchpad demo-125733 folder (plan.json, lines.txt, rec30.mp4, marks.json copied/kept there); not yet attached to the ticket
- 2026-10-23 voiced demo built with the second Gemini key (GEMINI_API_KEY_2): demo/demo_125733_general-settings_Iapetus.mp4 (102 s, streams OK); awaiting the engineer's listen before attaching to the ticket
- 2026-10-23 demo accepted and attached to CR 125733 (attachment c42b0a24-a299-4a56-84fb-0fff3e020c99, work item rev 4) + Demo comment; PAT variable here is MERGEDESK_ADO_PAT
- 2026-10-25 release: commits by path (DB 619343793, ERP 99dfc19c39 + e458c282cd, Front ecff7a4342 + merge of origin/Master_Stable d08cb70e2f), pushed; Merge Desk 12602 Solved → PRs 68226/68228/68227; ADO Solved
- 2026-10-25 engineer: "make it 953" → module id back to 953 / "Property Manager Real Estate Settings" (decisions Q11); Module.cs, 0002, routes.ts; gates sqlproj 0 errors, API 0 errors + 610/0 tests, tsc 0, prettier clean; commits DB 7c9a116b1 / ERP 8776bae5ff / Front 26e99993fa pushed; PR-links comment posted on ADO; Merge Desk now shows 68226 Conflicts, 68227 Conflicts, 68228 Abandoned
- 2026-10-25 engineer: cut cr125733_Stage_Beta in the 3 repos; DB branch already existed from the engineer's other session (PR 68292, lookups 0468, module 937) → merged the 953 commit in; ERP (14 conflicts) and Front (12) resolved by implementer agents per the checklist; PRs 68306 / 68307 opened, 68226 / 68227 abandoned; ADO comment posted
