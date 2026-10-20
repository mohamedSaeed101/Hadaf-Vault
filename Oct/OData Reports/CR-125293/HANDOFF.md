# CR-125293 HANDOFF — Payroll reports from iframe to OData

Set: C:\Hadaf_Work\worktrees\cr125293 (branch cr125293, not pushed). Plan: [[CR-125293 - Plan]].
Commits: DB a1da17c2a (TVFs), 512ee1255 (layouts); ERP ee183e8d1b; Front d7d4c5f353.

## Tenant state
- 2026-10-14 ~21:45: UNP-Ali on db-all — COPY_ONLY backup `UNP-Ali_pre_cr125293_20261014.bak` (server default backup dir), then applied ONLY the 5 PR_*Report TVFs and the 5 layout PostScripts (20261014191001..005). No full publish: UNP-Ali carries other branches' columns (full publish would drop PR_SystemConfiguration.NotifyEmployeeOn*).
- Rollback: DROP the 5 functions; DELETE ACFX_ReportLayout rows Name IN (EmployeesSalariesItems, PayCheck, EmployeeSalaryReceipt, InsuranceRegistration, EmployeeBonus).

## Gotchas
- publish-db.ps1's build fails on this machine (x86 MSBuild); build with ...\2022\Community\MSBuild\Current\Bin\amd64\MSBuild.exe and use -NoBuild.
- Merge Desk MCP needs MERGEDESK_ADO_PAT in .env.local.

## Next
Parity results in parity\results-*.md → app check (local-api-run against UNP-Ali) → /review-code 125293 → release.

## 2026-10-14 tests
- Parity R1-R5 PASS on UNP-Ali (see parity\results-*.md). Fixes: DB 3a7a8d86c, ERP 857d878a94; fixed Insurance TVF redeployed on UNP-Ali.
- Front gate: npm install + npm run testing EXIT 0, prettier clean (node_modules now installed in the worktree).
- Not provable on UNP-Ali data: PayCheck unpaid rows, terminated employees, Insurance EndWorkingDate fix effect, Suspend columns.
- Next: app check (local-api-run, both languages) → /review-code 125293.
- 2026-10-14: seeded (rollback-only) parity R1-R4 PASS, nothing persisted — parity\results-seeded.md
- 2026-10-14: review round 1 pass (block 0) → applied (DB db8d8fa24, Front 2514d6b727) → round 2 pass, 0 rows. [[review-2]]. R1/R4/R5 parity re-run PASS after re-applying 3 TVFs to UNP-Ali.
- 2026-10-15: before/after app check (5 reports, ar+en) — numbers match SQL everywhere; 5 display defects sent to implementer. [[app-check/app-check]]
- 2026-10-15: display defects fixed (DB 4e411fb79 PayCheck grand total; Front cc8f17d6ec dates dd/MM/yyyy, year plain, اسم البنك, PayCheck Arabic names) and re-checked in app (recheck-*.png). PayCheck print grand total 300,718.93 = SQL.
- 2026-10-15: explainer video (Hanafi, Gemini Iapetus, 2:00) → demo_125293_payroll-odata-reports_Iapetus.mp4
- 2026-10-15 RELEASE: pushed cr125293 (DB 4e411fb790, ERP 857d878a94, Front cc8f17d6ec). Merge Desk ticket #12499 created (Beta; components Database, AnalyticsReader, Web Container) → Solved. ADO 125293 → Solved, video attached, PR comment.
  - PRs → Stage_Beta: API !67219 (open), Database !67218 (CONFLICTS), WebContainer !67220 (open).
  - Database conflict (sqlproj only) resolved on cr125293_Stage_Beta (5327a65af) → PR !67222 to Stage_Beta. Merge Desk PR !67218 left open. Stage Beta deploy waits for the PRs to merge.
  - Database conflict (sqlproj only) resolved on cr125293_Stage_Beta (5327a65af) → PR !67222 to Stage_Beta. Merge Desk PR !67218 left open. Stage Beta deploy waits for the PRs to merge. Temp worktree worktrees/cr125293/_stage_db still on disk (locked by a build process).
- 2026-10-15: layouts moved PostScripts → ReferenceDataScripts 0423-0427 (DB f8944a194, pushed). My Stage_Beta PR !67222 was abandoned 07:17 by an automated process (no closedBy); Merge Desk's !67218 still conflicts (sqlproj). Local merge into cr125293_Stage_Beta discarded, not pushed.
