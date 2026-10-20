---
type: review
cr: 125307
round: 2
updated: 2026-10-15
---

# Review round 2 — CR_125307   base db 489493497 / erp 20e781f504 / front 0abc198bbd   head db 691c70477 / erp a610bee481 / front 0a077d503a   verdict: pass

Round 2 re-reads only the round-1 rows. Working trees clean in all three repos (`git status --short` empty); each repo has exactly one commit on top of the round-1 heads. Each `done` row was checked with `git show <sha>` plus the surrounding code; each `keep` / `no change` row against the reason in `review-1.md` and `decisions.md`.

## Round-1 rows re-checked

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 6 | AccFlex_Cloud_Database/…/dbo/Functions/PR_BankSalaryPrint.sql:53 | done | sql: CLAUDE.md §Build warnings | `SalaryHeader.IDNumber AS IdNumber` (691c70477); `Vw_SalaryHeader.sql:27` column is `IDNumber`; alias keeps the entity property `BankSalaryPrint.IdNumber` (ODataViews/Payroll/BankSalaryPrint.cs:29) and the outer `SELECT *` from the CTE; layout 0423 binds no `IdNumber`, so nothing else moves. | none |
| 10 | AccFlex_Cloud_Database/…/dbo/Functions/PR_EmployeeAccrualPrint.sql:32-110 | done | sql: style | 15 `FROM PR_EmployeeTransactions` → `FROM dbo.PR_EmployeeTransactions` (691c70477); only the schema prefix changed, the correlated `PR_EmployeeTransactions.CurrencyId` references still resolve. | none |
| 13 | AccFlex_Cloud_Front/…/employees-incomes-shell.component.ts:84-93 | done | AP: core.md correctness | `printEmployeeId = reuslt ? e : 0` set after `await getEmployeeIncomeInfo(e)` (0a077d503a); the helper returns `true` on load, `false` from its catch, so a failed load leaves the print id at 0 and `OnPrint` returns early. | none |
| 15 | AccFlex_Cloud_ERP/…/AngularPrints/Payroll/BankSalaryPrintAng.cs:29-37 | done | backend: core.md §Error Handling; report-backend.md Artifact 4 | Employee tokens split on `-` and each `int.TryParse`d in the guard (a610bee481); any bad token → empty data source, no SqlException; empty `parts[3]` → `employeeIds = null` (TVF default = all) as before. `Array`, `.All`, `.Select` resolve via `<ImplicitUsings>enable</ImplicitUsings>` (csproj:5). | none |
| 16 | AccFlex_Cloud_ERP/…/Models/DataContext.cs:379-387 | done | backend: report-backend.md Artifact 3 | Nine DbSets reordered AllowanceSerial, BankSalary, EmployeeAccrual, EmployeeAdvance, EmployeeAllowance, EmployeeBonus, EmployeeIncome, EmployeePurchase, SalaryExchange; pure reorder, neighbours (MonthlySalaryPrint, ProductionIncentives) untouched. | none |
| 5 / 7 | AccFlex_Cloud_Database/…/PR_BankSalaryPrint.sql:23,87 | dropped | report-database-functions.md §Comma-Separated ID List | Disagreement accepted: `Acc_ConvertStringListToTable` mirrors the legacy `.xsd` and sibling `PR_BankSalaryReport`, parity proven; recorded as D17 item (9). | none |
| 4 | AccFlex_Cloud_Database/…/PR_EmployeeAdvancePrint.sql:42-43 | dropped | D17 | `PaiedAmount` quirk recorded as D17 item (8) as asked. | none |
| 1 / 12 | AccFlex_Cloud_Front/…/payments-request-data.service.ts:113-131 | dropped | Coding guidelines §3 | Disagreement accepted: the `pretty-quick --staged` pre-commit hook re-applies the reflow to any staged version of the file; a revert cannot survive a commit. Note it in the PR as formatter noise. | none |
| 17 | AccFlex_Cloud_ERP/…/ODataViewsConfigurations/Payroll/*PrintConfigs.cs | dropped | report-backend.md §Naming | Payroll folder precedent (`MonthlySalaryPrintConfigs`) accepted. | none |
| 2, 8, 9, 11, 14 | various | dropped | nits | Optional in round 1, left as is by decision; no change needed. | none |
| D19 | AccFlex_Cloud_ERP/…/BankSalaryPrintAng.cs | dropped | platform limitation | Server PDF / XLS / email export paths pass `string.Empty` print data; pre-existing limitation shared with BarcodePrintPrinter / QuotationRequestPrint, screen uses the viewer path; recorded as D19. | none |
| 3 | vault in-app-check.md | should (ship gate) | spec Acceptance 1, 6 | Not a code row: click each of the 9 prints on Stage Beta (ar and en for BankSalaryPrint) and record the rows in `in-app-check.md` before Merge Desk Solved. | run at ship gate; a failure reopens the review |

## New rows

None. The three fix commits touch only the lines the round-1 rows named; no fix introduced a `block`.

## Summary for the orchestrator

verdict: pass
counts: block 0, should 1 (#3, ship-gate, unchanged), nit 0; done 5, dropped 10
block rows: none
round 3: not needed.
