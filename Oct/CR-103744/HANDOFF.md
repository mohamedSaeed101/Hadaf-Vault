---
cr: 103744
updated: 2026-10-07
phase: 6 — PRs into Stage_Beta open, waiting for approval; no deploy yet
---

# CR-103744 HANDOFF

- **State:** intake and investigation done; plan written. **No worktree set, no branch, no code yet.**
- **Route (proposed):** set `cr103744` · base `Master_Stable` (D9) · repos db, erp, front (desktop out, D6) · tenant UnitedPlastic · target Temp Cloud Beta after merge · final merge held for the tester.
- **Decisions D1–D10 taken with the engineer on 2026-10-07**; the plan was rewritten to match.
- **Notes:** [[CR-103744 - Source]] · [[CR-103744 - Plan]] · [[CR-103744 - Open Questions]]
- **No remote branch** `cr103744` / `fx103744` existed on 2026-10-07.
- **Tooling:** `az boards` stopped at an interactive prompt (extension install?), so the ticket was read through the ADO MCP. Fix with `az extension add --name azure-devops`.

## Set (created 2026-10-07)
- `D:\Hadaf_Work\worktrees\cr103744\` holds AccFlex_Cloud_Database, AccFlex_Cloud_ERP and AccFlex_Cloud_Front, each on branch `cr103744` cut from `origin/Master_Stable` (0 ahead / 0 behind at creation). Front HEAD = `7d555c886a`.
- Front: `package.json` differs from the main checkout, so `node_modules` is not linked. Run `npm install` in the worktree (with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1`) before the front gate.
- **The plan's line numbers were taken from the main checkout on `Stage_Beta`.** Re-locate by symbol in the worktree.

## What's next
**Full state: [[CR-103744 - Session Summary 2026-10-07]]** (scope, decisions, commits, PRs, findings, remaining steps).

- Tips: `cr103744` DB `418af662a` / ERP `7cc5afea16`; `cr103744_Stage_Beta` DB `566ca03be` / ERP `da4232c761`. All pushed.
- PRs into Stage_Beta: DB !66595, ERP !66596. Both merge cleanly and wait on reviewers.
- Next, with the user's OK: Stage Beta pipelines 341 (DB), then 337 (Payroll). Then verify, put evidence on WI 103744, and hold the Master_Stable PRs for the tester.

## Session log
- 2026-10-15 — **Shipped.** Merged `origin/Master_Stable` into `cr103744` (ERP +120, DB +24; no conflicts), gates green (Payroll + Misc Release 0 errors, Payroll.Application.Test 33/33, DB MSBuild amd64 exit 0; the x86 MSBuild cannot load the 4tecture task). Pushed: ERP `56210a09d5`, DB `e827f8a84`, Front `a1f2ab4397`. Merge Desk 12501 → **Solved**; ADO 103744 → **Solved** with a PR comment; explainer video attached to the work item.
  - Merge Desk stage PRs into Stage_Beta: API **!67227 (Conflicts)**, Database **!67228 (Conflicts)**, Web **!67229 (Open)**.
  - The older agent-opened PRs !66595 (DB) / !66596 (ERP) from `cr103744_Stage_Beta` are still open and now duplicate Merge Desk's; abandon them or reuse that branch to resolve the conflicts, the user's call.
  - Client SDK 221 already ran (run 183072); the settings contract has not changed since and the front uses none of the new fields, so no client bump.
- 2026-10-15 — Merge Desk ticket **12501** created (Beta, status Acknowledge, contract change, repos API / Database / WebContainer on the existing `cr103744` branches; remote tips unchanged after creation). Deploy components set: Database, Payroll, Misc, Web Container. Explainer video delivered: `demo_103744_ess-notifications_gemini-Iapetus.mp4` in this folder (80 s, Hanafi voice, Arabic captions; recorded as ess1 = employee 14). Recording takes left test data on UNP-Ali: bonuses 7–10 (100 SAR each) and leave rows 13–14 (1 day each), all "CR-103744 demo".
- 2026-10-15 — Remaining tests, all **PASS** ([[CR-103744 - Test Plan 2026-10-15]]): front build gate (EXIT 0), company switch off (no send, settings restored), holiday work leave days (new holiday date 06/10/2026, sheet 9277), recalculate no resend, bonus import (bonus 6). Not run: approval-count job (would notify real users on every tenant), mobile push on a device, Stage Beta. Local Payroll API (5012, started from the ERP main checkout) and the front dev server (4200) left running.
- 2026-10-14 — Pushed `cr103744`: ERP `7cc5afea16..e03bf84002` (approval-count link), Front new remote branch at `a1f2ab4397` (ess:// handling + web redirect). DB unchanged (`418af662a`). Not yet in `cr103744_Stage_Beta` / PR !66596; the front has no Stage_Beta PR. The user's own dirty files in the ERP main checkout (`QueueScopedSqlServerConnection.cs`, `README.md`, `appsettings.Development.json`) stay uncommitted on purpose.
- 2026-10-14 — **Retest on UNP-Ali after the user added the 3 switch columns by hand (db-all, all = 1). Local Payroll API 5012, front 4200 from the worktree.**
  - Leave balance: **PASS.** 1 day earned leave for employee 14 → "تم إضافة رصيد إجازات لك", `ess://leaves/2`; popup button opens `payroll/vacation-balance-transfer`.
  - Holiday work, cash: **PASS.** Sheet 8849 (23/09/2026, National Day, policy depends on holiday date, date set to cash 1.5) given 07:00–15:00 and calculated → allowance 108.75 SAR → "تم احتساب بدل عمل في إجازة رسمية … يصرف مع راتب الشهر", `ess://attendance/2026-09-23`; button opens `payroll/attendence-by-month`.
  - Recalculation unchanged: **PASS**, still one holiday-work notification (the existing early-quit penalty push re-sends; not this CR).
  - Holiday work, leave days: **not tested**; the tenant's only holiday date is set to cash.
  - Test data left on UNP-Ali: accrued rows "CR-103744 test" (1 day each) for employee 14; sheet 8849 now has 07:00–15:00, the allowance and an early-quit penalty.
  - Screen quirk (existing): the attendance screen's date boxes don't take typed dates; set them via the picker.
  - The 3 columns were added by hand; the next Stage Stable DB deploy (381) from a branch without this CR drops them.
- 2026-10-14 — **Test on UNP-Ali (tenant 1840, db-all), front 4200 from the worktree:**
  - Bonus: the user saw 3 "تم إضافة مكافأة لك" entries (`ess://bonus/3..5`); web redirect works. Those notifications are **not** in the db-all identity DB, so they were sent by a Payroll API wired to another identity DB (not verified which).
  - Leave balance: **FAILED, no notification.** Saved twice (1 day earned leave, employee 14, "CR-103744 test"): rows 7 (via Stage Stable API, which has no CR code) and 8 (via local Payroll 5012, HTTP 200). Cause: UNP-Ali on db-all has **no `NotifyEmployeeOn*` columns** on `PR_SystemConfiguration` (DB change never published there), so `GetSettingsAsync` throws, is caught and logged, and nothing is sent.
  - Holiday work: not run; same failure expected until the DB change is published to that tenant.
  - Worktree `config.json` has a local-only edit: `payrollapi` → `https://localhost:5012/api` (never commit).
  - Existing bugs seen on vacation-balance-transfer (Master_Stable, not this CR): `clearState` calls itself (stack overflow toast after save); `onEditorPreparing` reads `e.row.inserted` when `e.row` is undefined.
- 2026-10-14 — Two additions on `cr103744`, committed locally, **not pushed**, not yet merged into `cr103744_Stage_Beta`:
  - ERP `e03bf84002`: the daily `PendingApprovalNotificationScheduler` (Misc) now sets `Url`. One pending request opens it (`approval/approval-requests?approvalId=<id>`); several open the list. Misc.Application Release build: 0 errors.
  - Front `adeac8b068` (new worktree `C:\Hadaf_Work\worktrees\cr103744\AccFlex_Cloud_Front`, off Master_Stable): the bell popup ignores URLs with a scheme, so `ess://bonus/5` no longer shows as `/apps/<co>/ess://...`. Prettier ok; `npm run testing` not run (no node_modules in the worktree).
  - The front is now in scope for this CR (one file). Misc API joins the deploy list.
  - Front `a1f2ab4397`: the bell popup maps `ess://` links to web screens instead of hiding them: bonus → `payroll/bonus?id=<id>` (opens the record), leaves → `payroll/vacation-balance-transfer`, attendance → `payroll/attendence-by-month` (screen only; those screens don't read an id). Dev server on 4200 from the worktree serves it; not clicked through (needs sign-in).
- 2026-10-07 — D11' (TenantId reverted, `498be286c2`) and D13 (log table removed, before/after dedupe: DB `418af662a`, ERP `7cc5afea16`). Merged into cr103744_Stage_Beta locally (DB `566ca03be`, ERP `da4232c761`); DB and Payroll.API build. **Not pushed yet.**
- 2026-10-07 — pushed cr103744; SDK 221 run 183072 succeeded; cr103744_Stage_Beta built (DB ok, Payroll.API ok; Stage_Beta's own Logistics and IntegrationTest breakage flagged); PRs !66595 (DB) and !66596 (ERP) into Stage_Beta.
- 2026-10-07 — D11/D12 decided; phase 12 (driver-bonus TenantId) committed. All open questions closed.
- 2026-10-07 — phases 2-7 committed; review: SQL 1 BLOCK (FK) fixed in 10a, backend 4 WARN fixed in 10b; docs proposal written. Q11, Q12 open.
- 2026-10-07 — phase 2 gates green, kept uncommitted; loop stopped by the user; main DB checkout → Master_Stable.
- 2026-10-07 — phase 1 DB done, `641261959` (DB repo).
- 2026-10-07 — intake via the ADO MCP; 3 investigation sub-agents (Payroll hooks, notification plumbing, desktop/DB); plan + questions written.
