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

## 2026-10-21 iterate 1 — Sabreen's comment of 2026-10-20 (Pay Check totals)
- Merge Desk ticket #12499 is at ReadyForTest; the 3 stage PRs (!67218, !67219, !67220) are merged. ADO is back In Development. Set recreated at D:\Hadaf\worktrees\cr125293 (front only, tracking origin/cr125293 cc8f17d6ec, port offset 1000).
- [[change-note-1]]: report-grid has a new opt-in `totalSummaryOptions` (a total row) and an opt-in `ColumnIndex.Lookup`. Pay Check sums EmployeeSalary in the grand total and per group, and IsPaid is a lookup that shows مصروف / غير مصروف.
- Gates: `npm run testing` EXIT 0; prettier is clean on all 5 files once CRLF is normalised (the working copy is CRLF and the blobs are LF). **Not committed** (user preference: no commit until told).
- Browser check NOT done: the localbeta identity CORS only allows localhost:4200, which is held by another session's static server (cr125289 dist, python spa.py). `npm run dev` crashed in esbuild (out of memory). The worktree config.json points at localbeta, including analyticsreader.localbeta.hadaf.website, which serves PayCheck: this is a local-only edit, never commit it. The dist build in the worktree carries that config, so a static server on 4200 is enough to check.
- Point 3 (foreign files in PRs): there is no code change. The branch diff against Master_Stable is CR-only; the extras are Master_Stable commits that Stage_Beta lacks (e.g. CR_124989). Draft ADO reply: [[reply-2026-10-21-draft]] (not posted).
- 2026-10-21 browser check on Beta, Sabreen, 07/2026. The cr125289 dist server on :4200 was stopped (with the user's OK) and this set's dist was served on :4200, pointed at localbeta. Results:
  - AR: grand-total row 300,718.93 over 75 rows (= SQL in app-check). Grouping by bank gives 1 group of 75 rows, 300,718.93. Grouping by job gives ACCOUNTANT (2) 12,700 = 7,600 + 5,100, AEALSMANE 5,000 and so on. The «مصروف» column shows مصروف. Column filter Paid → 75 rows / 300,718.93, Not Paid → 0.
  - EN after a fresh load: caption Paid, cells Paid, lookup Paid / Not Paid, total 300,718.93.
  - Known: after a LIVE language switch on the open screen, the status radios (pre-existing) and the new lookup texts show raw SALARYODATAREPORTS.* keys until reload, because translate.instant runs before the new language JSON loads. Not fixed; it is the same pattern as the existing radios.
- 2026-10-21 committed front cdef696e0c (5 files, +41/-4; config.json left local, not committed). Not pushed.
- 2026-10-21 review round 3 (Fable reviewer, implementation by Opus) gave pass: 0 block, 0 should, 3 nit. [[review-3]]
- 2026-10-21 pushed cr125293 front: cc8f17d6ec..cdef696e0c (fast-forward).
- 2026-10-21 ADO 125293 → Solved (rev 34, board column Resolved). New PRs !67970 / !67971 / !67972 were linked at 09:07 (opened by the user / Merge Desk). Posting [[reply-2026-10-21-draft]] is left to the user.
- Local leftovers: worktree config.json points at localbeta (do not commit). :4200 serves this set's dist (launch entry front-cr125293), and cr125289's server there was stopped. The set can be removed with remove-cr.ps1 once it is no longer needed. The stage PRs are merged, so a new Stage_Beta PR is needed for the delta. Afterwards, restart cr125289's server on :4200 if that session needs it.

## 2026-10-25 iterate 2 — insurance To date (Muhammed Tariq, ADO comment 10021304)
- [[change-note-2]]: reverted 857d878a94 → `_toDate.GetDayEnd()` in PayrollOdataController + InsuranceRegistrationRptAng (desktop frmInsuranceRegistrationReport sends 23:59:59).
- ERP added to the set at D:\Hadaf-worktrees\cr125293 (new-cr.ps1); AnalyticsReader.Api build OK (`-p:LibraryRestore=false`, the worktree has no node_modules for libman).
- Pushed ERP cr125293 857d878a94..997bde3a39. Review skipped on the engineer's explicit "fix and ship" for a 2-line revert.
- Merge Desk still Solved; its API PR to Stage_Beta !67971 is ABANDONED and no API PR from cr125293 is open, so the push does not reach Stage_Beta (where QA checks). ADO left In Development until a PR carries it.
- Next: engineer decides on a new API PR cr125293 → Stage_Beta, then ADO → Solved with a reply to Muhammed.
- 2026-10-25 15:01: opened API PR !68386 cr125293 → Stage_Beta on the engineer's ask (1 commit, 2 files, merges clean). ADO 125293 → Solved; reply to Muhammed Tariq (comment 10021317). Next: PR !68386 merges + AnalyticsReader Stage Beta deploy; then QA re-checks 27/09→27/09 on Sabreen.
