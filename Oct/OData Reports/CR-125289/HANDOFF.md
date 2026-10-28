# CR-125289 — HANDOFF

Updated 2026-10-15 (after review round 2: pass).

- Set: `D:\Hadaf\worktrees\cr125289` (db, erp, front), branch `cr125289`, off `Master_Stable`, port offset 500. Nothing is committed: the engineer commits.
- Plan: [[CR-125289 - Plan]]. Decisions: [[decisions]] (D1 full grid, D2 exact port, D3 old print kept as a button). Facts: [[facts]].
- Legacy inventory: [[Legacy - Brief Income Statement]], [[Legacy - Income Statement Branch and Cost Center]], [[Legacy - Income Statement Period and Activity]]. Templates: [[Modern templates]].

## Where it stands
- Done, uncommitted:
  - **P1:** 9 TVFs, registered in the sqlproj. MSBuild is green and all 9 are in the dacpac. contracts-R1-R3/R4-R6/R7-R9.md.
  - **P2:** AnalyticsReader, 9 entities + configs + DbSets + IAngularReports + 9 GLODataController actions (ModuleIds 10/72/267/55). `dotnet build` passes with 0 errors (flags `-p:LibraryRestore=false -p:BaseOutputPath=<scratch>`).
  - **P3:** the 3 shells + forms, report-grid per route; "Print (previous design)"; INCOMESTATEMENTREPORTS i18n block; report-grid PDF-URL fix (as cr125288).
  - **P4:** seeds 0431 (R1–R4) and 0432 (R5–R9), 18 InsertLayout calls, `<None Include>` registered. Generators are in the session scratchpad (gen0431.py, p4b/gen.ps1).
- Front build gate: `npm run testing` exits 0 (2026-10-15, after npm install with SKIP_INSTALL_SIMPLE_GIT_HOOKS=1; the first attempt hit a transient esbuild out-of-memory error).
- Done: P5 parity. R1–R9 match the legacy (R8 after its percentage fix); see decisions.md "Parity verdicts".
- Open:
  - Remove the dead `PrintedOnly*` columns (R7/R8 TVFs, entities, shells, i18n).
  - (settled) Percentage semantics.
  - R4–R6/R9 grid groups sort by MainItemName, not MainItemId.
  - Computed-row labels in XLS/PDF export (P6).
  - DataContext.GetCostCentersName duplicates cr125288's (merge conflict expected).
- Done: P6 on UNP-Ali ([[p6-app-check]]; layout ids 2840–2857). Review: [[review-1]] (28 rows) → [[review-2]], **pass** (row 29, the truncated wwwroot bundles, was restored).
- Gotcha: `dotnet build` of AnalyticsReader truncates 5 tracked wwwroot bundles. Run `git checkout -- …/AnalyticsReader.Api/wwwroot` after every build.
- Done: remove-redundant. The only change was dropping 9 restating XML summaries in IncomeStatementReportsConfigurations.cs. ERP build passes with 0 errors and wwwroot is restored.
- Done: before/after test on UNP-Ali ([[before-after-125289]]). SQL parity was re-run with the current TVFs on 5 tenants, 0 failures. Legacy and new prints match on R1/R3/R7/R8, and R4/R5/R6/R9 are empty on both. One print divergence, open: R2/R3 report-wide rows print blank where the legacy prints 0.00 when there are no detail rows. Services were stopped and config.json restored.
- Next: commit (engineer) → release-ticket.

## Iteration 1, 2026-10-21 (QA return, comment 10010795)
- Iterate path on branch `cr125289`. Merge Desk is Solved with the stage PRs merged, so there is no status move and no new PR; the push updates the open PRs.
- [[change-note-1]] holds the findings, the engineer's answers and the uncommitted front edits.
- Point 1a was reproduced on Beta. The filters are sent and the data is right. The gaps were 3-decimal money and missing loss parentheses, both now fixed with `moneyText` and `parenthesizedTotal`.
- Build gate is green. The screen check passed for R1 and the R7 guard. The R4–R6 totals and the R2/R7 percentages are not yet seen on screen, because Sabreen has no data for them. See [[change-note-1]].
- R4/R5 totals were checked on BETA-dbriyadhbn. R5's double count was fixed: it now sums only the pivot's total column rows.
- R6 totals and R2/R7 percentages were checked on BETA-dbriyadhbn (dbMarbo-tech is not on the engineer's Beta list). Every QA point has now been seen on screen.
- R3, R8, R9 and R1 in English were also checked. New finding: the R9 main-item groups are out of legacy order (they sort on the raw Arabic name). See [[change-note-1]].
- The R9 group order is fixed (`Grouping.SortField` + a label map) and rechecked on R9/R4/R5/R6. See [[change-note-1]].
- Gotcha: when other builds run, `npm run testing` can die in the parallel TS worker. Use `$env:NG_BUILD_PARALLEL_TS='0'`.
- Review round 3: [[review-3]], **pass**. Fable 5.1 reviewed, with the Front anti-pattern scan merged in; Opus 5.5 applied the rows: 0 block, rows 2/3/5/6/8/9/10 done (the `groupLabels` clear, `any` → types, `ALL_BRANCHES_CODE`, prettier). The build is green (119 s). These typing/cleanup changes were not re-checked on screen.
- For the PR / ADO comment: the R4/R5/R6/R9 group headers drop the «البند الرئيسي:» caption and row count (review-3 row 4).
- remove-redundant (2026-10-21) is done, with no edits. It found 0 unused code, 0 narration comments and 0 debug leftovers. The engineer kept the 5 optional defensive `?.` checks (core.md asks for optional chaining, and the html mirrors the group-item lines). Noticed, not touched: the pre-existing block-body arrow in the report-grid `customizeText` fallback.
- Committed (on the engineer's instruction) as Front `15e5beb9e0` "cr125289: QA fixes for the income statement report grids" (12 files; pretty-quick rewrapped 3 of them). Pushed with a fast-forward, 9b6deff6cc..15e5beb9e0.
- **Catch:** all three Stage_Beta PRs (DB !67333, API !67334, Web !67335) were already merged, and no Master_Stable PRs exist yet. So the push reached no open PR, and Beta will not get this commit until a new Web PR cr125289 → Stage_Beta merges. If it conflicts, cut a `cr125289_Stage_Beta` branch; never merge Stage_Beta into cr125289. merge-desk.md does not cover this case.
- The QA comment draft is [[qa-comment-iteration-1]], not posted. Hold it until the fix is on Beta.
- 2026-10-21: the engineer will get 15e5beb9e0 onto Stage_Beta themselves. **Hold the QA comment** ([[qa-comment-iteration-1]]) and the ADO Solved move until the engineer says so.
- Next (on the engineer's word): post the QA comment on 125289, then move ADO to Solved.

## Resume prompt
Resume CR 125289 in `D:\Hadaf\worktrees\cr125289`: read this HANDOFF, the plan and the `contracts-R*.md`, then continue from "Next".

## Released 2026-10-15
- Commits, pushed to origin/cr125289 (fast-forward; no Co-Authored-By):
  - DB f6c99f6a5
  - ERP a9baaabf87
  - Front 9b6deff6cc
- Merge Desk ticket 12514 was created (Beta) and moved Acknowledge → Solved.
- ADO 125289 → Solved, with a comment carrying the PR links.
- Video `demo_125289_income-statement-odata.mp4` is attached to the work item.
- Stage_Beta PRs:
  - DB !67333 (Conflicts)
  - API !67334 (Conflicts)
  - Web !67335 (Open)
- The Master_Stable PRs are not opened yet (Merge Desk opens them).
- Before/after: see [[before-after-125289]]. The R2/R3 empty-data 0.00 fix is in the DB commit.
- Next: the Stage_Beta conflicts on !67333/!67334 need a `cr125289_Stage_Beta` branch, cut only when the engineer asks; never merge Stage_Beta into cr125289. After that, cleanup with remove-cr.ps1 is the engineer's choice.
