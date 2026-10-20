---
type: handoff
cr: 125292
updated: 2026-10-14
status: P1–P7 done, committed and pushed (one commit per repo); P4 parity PASS on UNP-Ali; next P8
---

# HANDOFF — CR-125292: payroll salary reports to OData

## Where we are (2026-10-14)

| Step (onboard-ticket spine) | State |
|---|---|
| 0 Preflight + Merge Desk | done: Merge Desk ticket **#12459**, Beta, owner Mohamed Saeed, status Acknowledge; `cr125292` cut by Merge Desk in Database (`8a3f097c5`), API (`84dc84ff0e`), WebContainer (`69b8fb2428`) |
| 1 Intake | done: [[CR-125292 - Source]] |
| 1b Size | **L** (~60 files, 3 repos) |
| Legacy dissection | done: the four `Legacy - …` notes |
| 2 Set | done: `D:\Hadaf\worktrees\cr125292` (db, erp, front), port offset **200**. ADO **In Development**. Front: `npm install` needed in `AccFlex_Cloud_Front\accflex-erp` (package.json differs from main; `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1`) |
| 3–6 Plan | [[CR-125292 - Plan]]; decisions D2–D6 in [[decisions]]; engineer continued after the plan = approval |
| 7 P1 (TVFs R1–R4), P2 (TVFs R5–R8) | **done**, uncommitted. P1 parsed with ScriptDom TSql160; deviations recorded in [[decisions]] "Applied during P1/P2" |
| P3 sqlproj | **done**: 10 `<Build Include>` lines; VS 2022 Community MSBuild green (520 pre-existing warnings, none in new files); all 10 in the dacpac model.xml |
| P5 backend | **done**: 10 OData endpoints + 8 IAngularReport + SalaryReportOptions helper; `dotnet build -p:LibraryRestore=false` 0 errors (LibMan cannot find node_modules in the set; the build rewrites 5 wwwroot bundles: `git checkout` them after each build) |
| P6 layouts | **done**: `0414_PR_SalaryReportsLayout.sql`, 16 InsertLayout (8 reports × ar-EG/en-US), registered as `<None>`; sqlproj build green. R3 insurance footer now binds `?totalEmployeesInsurance`, computed once in `EmployeesDetailedSalariesRptAng` |
| P7 front | **done, built**: `npm run testing` EXIT 0 (131 s, no TS/NG errors) after `npm install` (engineer OK). Prettier flags all 19 changed files but they fail on the base too (line endings); pretty-quick formats at commit. 8 shells + module ModuleIds + SALARYREPORTS keys (en/ar). Build gate needs `npm install` in the set front (engineer OK pending). Legacy print = the forms' own Print button relabelled "Print (previous design)" |
| P4 parity | **PASS, all 8** on **UNP-Ali / db-all** (2026-10-14), read-only; the TVFs are not deployed there. Results and data gaps: [[CR-125292 - Implementation Log]] §7; scripts in `parity\` here |
| Commits | pushed to `origin/cr125292`: DB `b4c7f47f5`, ERP `b22707afbb`, Front `80b98cabdb`; no PRs yet. The worktree set is on the first PC (`D:\Hadaf\worktrees\cr125292`); the second PC (`C:\Hadaf_Work`) has none |

## Ticket facts

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125292. Board lane shows STABLE although a CR goes to Beta (not changed).
- Branch `cr125292` → first PR to `Stage_Beta`, second to `Master_Stable`. **Never merge `Stage_Beta` into `cr125292`.**
- AccFlex_ERP is read only (legacy MVC source).

## Next step

1. ~~npm install + front build~~ done 2026-10-14 (EXIT 0).
2. ~~P4 parity~~ done 2026-10-14 on UNP-Ali / db-all: all 8 PASS.
3. P8 app check on UNP-Ali: deploy the 10 TVFs + the 0414 layout seed there (a write to the tenant: engineer's OK first), run AnalyticsReader locally (`local-api-run`) + the front against it, print and export each report AR/EN, compare with the old print; settle Q8.
4. Then propose `/review-code 125292` (engineer's trigger).
5. PO list beside D4: R6 prepaid-vacation net ≠ additions − deductions (legacy, unchanged). Untested paths (end-of-work, double bank account, insurance/tax) need a tenant with such data.
6. On the second PC the Merge Desk MCP has no PAT (`MERGEDESK_ADO_PAT` missing from `C:\Hadaf_Work\.env.local`).

## Session log

- 2026-10-14 (second PC): where-are-we found the work pushed; P4 parity on UNP-Ali by 4 parallel read-only agents, all PASS.
