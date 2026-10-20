
## Employee Save

Tenant UNP-Ali (db-all), 2026-10-14. `dbo.PR_EmployeeSaveReport` created with CREATE OR ALTER. Script: `parity\parity_Save.sql` (legacy dsEmployeeSaveRpt.xsd query verbatim, params per case, vs TVF; EXCEPT both directions over all 13 columns incl. RowNo and IsReturnedStr).
Data: 9 save rows (security levels 1×7, 3×1, 5×1), max EmployeeSecurityLevel 5, 88 employees, 0 returned saves.

| Case | @SecurityLevel | @IsArabic | Legacy | TVF | L−T | T−L |
|---|---|---|---|---|---|---|
| all, ids NULL | 5 | 1 | 9 | 9 | 0 | 0 |
| all, ids NULL | 5 | 0 | 9 | 9 | 0 | 0 |
| all, ids '' (legacy NULL) | 5 | 1 | 9 | 9 | 0 | 0 |
| all, ids '' (legacy NULL) | 5 | 0 | 9 | 9 | 0 | 0 |
| all | 3 | 1 | 8 | 8 | 0 | 0 |
| all | 3 | 0 | 8 | 8 | 0 | 0 |
| all | 1 | 0 | 7 | 7 | 0 | 0 |
| ids 31,30,17 | 5 | 1 | 3 | 3 | 0 | 0 |
| ids 31,30,17 | 5 | 0 | 3 | 3 | 0 | 0 |
| ids 31,30,17 | 3 | 0 | 3 | 3 | 0 | 0 |

**PASS** (every EXCEPT empty, counts equal). Gap: no returned save on this tenant, so the 'Yes' / 'نعم' branch is unexercised by data (code is the verbatim legacy CASE).

## Medical Insurance

Tenant UNP-Ali (db-all), 2026-10-14. `dbo.PR_EmployeesMedicalInsuranceReport` created with CREATE OR ALTER. Script: `parity\parity_Medical.sql` (legacy Employees + PR_MedicalInsurance queries verbatim, joined on the dataset relation, card filter as Detail_BeforePrint with the controller map 0→all, 1→true, 2→false, other→true; EXCEPT both directions over all data columns; Serial/RowNo checked separately to be 1..n by EmployeeId, MedicalInsuranceId, per D2).

| Case | @CardReceived | Legacy | TVF | L−T | T−L | Bad serial |
|---|---|---|---|---|---|---|
| all, ids NULL | 0 | 0 | 0 | 0 | 0 | 0 |
| all, ids NULL | 1 | 0 | 0 | 0 | 0 | 0 |
| all, ids NULL | 2 | 0 | 0 | 0 | 0 | 0 |
| all, ids '' | 0 | 0 | 0 | 0 | 0 | 0 |
| all (default branch) | 3 | 0 | 0 | 0 | 0 | 0 |
| ids 31,30,17 | 0 | 0 | 0 | 0 | 0 | 0 |
| ids 31,30,17 | 1 | 0 | 0 | 0 | 0 | 0 |
| ids 31,30,17 | 2 | 0 | 0 | 0 | 0 | 0 |

**PASS, vacuous**: UNP-Ali has 2 PR_MedicalInsurance rows, both expired (0 active), so every case is 0 = 0. Real parity needs a tenant with active insurance lines (open question Q1); not hunted per instruction.

## Employee Statistics

Run 2026-10-14 on UNP-Ali (db-all), P1b/P2. Script `parity/parity_Statistics.sql` (runner `parity/run.sh`, output `parity/parity_Statistics.out`); functions created with `parity/deploy_Statistics.sql` (CREATE OR ALTER of the two files only). The live `Pr_GetEmployee_Statistics` / `Pr_GetEmployee_Vacation_Statistics` on UNP-Ali are identical (whitespace-insensitive) to the worktree source.

Method: legacy procs via INSERT EXEC with the dates normalised as the `rptEmployeeStatistics` constructor does (from 00:00:00, to 23:59:59.997); C# rollup applied in SQL (master VacationBalance = SUM of the employee's detail rows, 0 when none). TVFs get the raw dates (range 3 has time parts) and normalise themselves. EXCEPT both ways; the detail compared with multiplicity (duplicate ordinal) because the `GROUP BY VacationDays` quirk can repeat a row. All 88 active employees.

| Range | Master legacy / TVF | Master L−T / T−L | Detail legacy / TVF | Detail L−T / T−L | Split type rows (quirk) | Σ counts | Σ VacationBalance |
|---|---|---|---|---|---|---|---|
| 1 wide 2000-01-01..2026-12-31 (all PR_Vacations/Advance/Penalty/Bonus data) | 88 / 88 | 0 / 0 | 617 / 617 | 0 / 0 | 1 | 30 | 31221.121339 |
| 2 narrow 2026-05-01..2026-06-30 | 88 / 88 | 0 / 0 | 617 / 617 | 0 / 0 | 1 | 19 | 30395.238992 |
| 3 raw times 2026-06-30 15:00..2026-09-21 08:00 | 88 / 88 | 0 / 0 | 617 / 617 | 0 / 0 | 1 | 15 | 30589.386673 |
| 4 narrow 2026-09-21..2026-09-28 | 88 / 88 | 0 / 0 | 617 / 617 | 0 / 0 | 1 | 1 | 30633.170350 |
| 5 before data 2024-01-01..2024-12-31 | 88 / 88 | 0 / 0 | 616 / 616 | 0 / 0 | 0 | 0 | 29884.446393 |

RowNo: unique and dense (master 1..88; detail distinct RowNo = row count in every range). PR_Purchase is empty on UNP-Ali, so PurchaseCount is only exercised as 0.

**Result: PASS** (every EXCEPT empty, counts equal).

## Risk Analysis

Run 2026-10-15 on UNP-Ali (db-all), P1c/P2. `dbo.PR_CalendarDateDifference` and `dbo.PR_RiskAnalysisReport` created with `parity/deploy_Risk.sql` (CREATE OR ALTER of the two worktree files only). Oracle `parity/risk-oracle/` (.NET 8, Microsoft.Data.SqlClient): the five legacy dsRiskAnalysis.xsd queries / proc verbatim, `rptRiskAnalysis.cs` line 50 and lines 67-137 (BeforePrint loop) and `Helper\DateDiffrence.cs` copied verbatim (checked with `diff`), PR_Employee as a real DataTable with the xsd DefaultValue 0 columns and the `Total` Expression column, so ADO.NET computes Total as legacy. Compared with the TVF row by row on (EmployeeId, CurrencyId), every column (CurrencyName, EmployeeName, EmployeeNumber, JobName, DateOfWork, Days/Monthes/Years/NetYearsOfWork, Compensation, RiskAmount, VacationBalance, Vacations, Others, Total), plus RowNo dense 1..n. Output: `parity/risk-oracle.out`. Run: source `.env.local`, then `dotnet run --project parity\risk-oracle\risk-oracle.csproj --artifacts-path <scratch>`.

Data: 88 employees (all EndWork = 0), 1 income currency (so 1 row per employee), 286 income lines, SelectSeparateInsuranceItem = 0 (the insurance filter branch is not exercised), 1 end-service policy with 3 bands (0-5 x0.5, 5-10 x1, 10-100 x1; 5 and 10 sit in two bands, desc order picks the higher), no employee without a Pr_VacationBalance row (the D2 path is not exercised by data).

| RiskDate | Ids | IsArabic | Legacy rows | TVF rows | Mismatches | Missing vacation rows | RiskAmount <> 0 rows (0 on 2024-03-01: no income started yet) | RowNo ok |
|---|---|---|---|---|---|---|---|---|
| 2026-10-15 14:37:21 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 14:37:21 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 14:37:21 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-10-15 14:37:21 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-10-15 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-10-15 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-30 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-30 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-30 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-30 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2025-12-31 | all active | 0 | 88 | 88 | 0 | 0 | 75 | yes |
| 2025-12-31 | all active | 1 | 88 | 88 | 0 | 0 | 75 | yes |
| 2025-12-31 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2025-12-31 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-12-31 | all active | 0 | 88 | 88 | 0 | 0 | 88 | yes |
| 2026-12-31 | all active | 1 | 88 | 88 | 0 | 0 | 88 | yes |
| 2026-12-31 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-12-31 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-03-01 | all active | 0 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-03-01 | all active | 1 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-03-01 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-03-01 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2024-03-01 | all active | 0 | 88 | 88 | 0 | 0 | 0 | yes |
| 2024-03-01 | all active | 1 | 88 | 88 | 0 | 0 | 0 | yes |
| 2024-03-01 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 0 | yes |
| 2024-03-01 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 0 | yes |
| 2026-01-15 | all active | 0 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-01-15 | all active | 1 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-01-15 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-01-15 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-04-10 | all active | 0 | 88 | 88 | 0 | 0 | 79 | yes |
| 2026-04-10 | all active | 1 | 88 | 88 | 0 | 0 | 79 | yes |
| 2026-04-10 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-04-10 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-28 | all active | 0 | 88 | 88 | 0 | 0 | 80 | yes |
| 2026-09-28 | all active | 1 | 88 | 88 | 0 | 0 | 80 | yes |
| 2026-09-28 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-28 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-29 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-29 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-29 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-29 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |

**Result: PASS**, 44 runs (11 RiskDates x {all 88 active, ids 31,30,17} x IsArabic {0,1}), 0 mismatches, first attempt.

Coverage measured with the TVF body run ad hoc (per RiskDate, all 88): date swaps (DateOfWork after RiskDate) 8-26 rows on 2025-12-31 / 2026-03-01 / 2024-03-01 / 2026-01-15 / 2026-04-10; day borrows 27-46 rows; a February borrow 1 row; under 90 days 7-26 rows; the 90-day edge itself (2026-07-01 hire: 89 days on 2026-09-28 not over, 90 days on 2026-09-29 over); Compensation non-zero 63-75 rows, band edges (5 or 10 years) 1-4 rows; negative VacationBalance 2 rows.

Findings:
- **Others / Total**: `Others` (xs:decimal, default="0") is never assigned in BeforePrint, but DataTable rows created by Fill take the column DefaultValue, so Others = 0, not DBNull. `Total` is the Expression `RiskAmount+Others+Compensation+Vacations` over three columns that are always assigned, so legacy prints Total = RiskAmount + Compensation + Vacations. The TVF returns Others = 0 and that Total; the oracle's real Expression column agrees on every row.
- **Rounding**: C# `Math.Round(decimal, n)` is half-to-even; SQL `ROUND` is half away from zero. The TVF rounds half to even. This shows in the data: Compensation (salary x 0.5 x odd years) lands exactly on .5 in 2-10 rows per RiskDate, where SQL `ROUND` would be 1 higher; legacy and TVF agree. Risk, VacationBalance and Vacations hit no tie on this tenant.
- **Salary is not per employee (legacy calculation, kept per D2)**: the two C# salary sums (`salary` for Risk / Vacations, `employeeSalary` for Compensation) filter PR_EmployeeIncome by start date and currency only, not by EmployeeId, so every row uses the total of all listed employees' incomes in that currency (UNP-Ali 2026-10-15: 522,814.50, so RiskAmount 1,045,629.00 on every row over 90 days). The amounts change with the employee selection (ids 31,30,17 gives other figures). The TVF reproduces it. Raised as Q3 in `open-questions.md`.
- Residual theoretical gap: legacy computes `salary / 30 * vacationBalance` in System.Decimal (division rounded to 28-29 digits first); the TVF computes `salary * vacationBalance / 30` exactly to 16 decimals. They can only round differently if the exact value sits on a .xx5 tie, which no row reached.

### Q3 fix (D6)

Engineer, 2026-10-15: **fix to a per-employee salary** (decision D6). `PR_RiskAnalysisReport` now adds `EmployeeId = row EmployeeId` to both salary sums: `salary` for RiskAmount / Vacations and the policy-band sum for Compensation. The currency filter, the StartDate <= RiskDate filter, the SelectSeparateInsuranceItem rule, the policy band, half-to-even rounding, Others = 0 and missing vacation row = 0 are unchanged. Deployed with `parity/deploy_Risk_D6.sql` (CREATE OR ALTER of that one function).

The oracle has a new `--fixed` mode that runs `BeforePrintFixed`. That method is the same verbatim legacy text with exactly two additions, `&& u.EmployeeId == dsRiskAnalysis1.PR_Employee[i].EmployeeId`, in the Where clauses of legacy lines 70 and 111 (checked with `diff`). `PR_EmployeeIncome` has `EmployeeId` (xs:int, query `SELECT *`). Without the flag the oracle runs the verbatim legacy loop. Output: `parity/risk-oracle-fixed.out`.

**New rounding finding.** With per-employee salaries, Vacations lands on exact .xx5 ties, and plain half-to-even no longer matched legacy (first fixed run: 40 mismatches, employees 2 and 23, Vacations and Total, 0.01 each). The cause is System.Decimal arithmetic:
- `salary / 30` is rounded to the widest scale that fits 96 bits (26 decimals for 100–790). It is therefore off by -1/3 of the last unit when the salary mantissa mod 3 = 1, and by +1/3 when it is 2.
- The product with the balance is then rounded to its own 96-bit scale (24–25 decimals).
- On a tie, that error decides the side, unless the product rounding absorbs it. In that case Math.Round sees the tie and goes to even.

The TVF now reproduces this rule (the `q` and `vacTie` applies). Across the 11 RiskDates there are 34 Vacations ties: 24 go to even and 10 follow the error's side. All of them match. Compensation has 20 ties (exact arithmetic, half to even); Risk has none. This closes the "residual theoretical gap" noted above.

| RiskDate | Ids | IsArabic | Legacy rows | TVF rows | Mismatches | Missing vacation rows | Over-90 rows | RowNo ok |
|---|---|---|---|---|---|---|---|---|
| 2026-10-15 14:37:21 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 14:37:21 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 14:37:21 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-10-15 14:37:21 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-10-15 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-10-15 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-10-15 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-30 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-30 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-30 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-30 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2025-12-31 | all active | 0 | 88 | 88 | 0 | 0 | 75 | yes |
| 2025-12-31 | all active | 1 | 88 | 88 | 0 | 0 | 75 | yes |
| 2025-12-31 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2025-12-31 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-12-31 | all active | 0 | 88 | 88 | 0 | 0 | 88 | yes |
| 2026-12-31 | all active | 1 | 88 | 88 | 0 | 0 | 88 | yes |
| 2026-12-31 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-12-31 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-03-01 | all active | 0 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-03-01 | all active | 1 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-03-01 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-03-01 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2024-03-01 | all active | 0 | 88 | 88 | 0 | 0 | 0 | yes |
| 2024-03-01 | all active | 1 | 88 | 88 | 0 | 0 | 0 | yes |
| 2024-03-01 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 0 | yes |
| 2024-03-01 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 0 | yes |
| 2026-01-15 | all active | 0 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-01-15 | all active | 1 | 88 | 88 | 0 | 0 | 75 | yes |
| 2026-01-15 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-01-15 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-04-10 | all active | 0 | 88 | 88 | 0 | 0 | 79 | yes |
| 2026-04-10 | all active | 1 | 88 | 88 | 0 | 0 | 79 | yes |
| 2026-04-10 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-04-10 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-28 | all active | 0 | 88 | 88 | 0 | 0 | 80 | yes |
| 2026-09-28 | all active | 1 | 88 | 88 | 0 | 0 | 80 | yes |
| 2026-09-28 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-28 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-29 | all active | 0 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-29 | all active | 1 | 88 | 88 | 0 | 0 | 81 | yes |
| 2026-09-29 | ids 31,30,17 | 0 | 3 | 3 | 0 | 0 | 3 | yes |
| 2026-09-29 | ids 31,30,17 | 1 | 3 | 3 | 0 | 0 | 3 | yes |

**Result: PASS**, 44 runs (11 RiskDates x {all 88 active, ids 31,30,17} x IsArabic {0,1}), 0 mismatches against the fixed oracle (third attempt: per-employee fix, then the Vacations tie rule).

Selection independence: 66 subset rows (3 employees x 22 runs) have the same RiskAmount / Compensation / Vacations / Total as the same employee in the full run, 0 differ. RiskAmount on 2026-10-15 (all 88) takes 53 distinct values; it was 1 under the legacy logic.

| Employee, 2026-10-15, IsArabic 0 | Run | RiskAmount before (legacy) | RiskAmount after (D6) | Total before | Total after |
|---|---|---|---|---|---|
| 17 | all 88 | 1,045,629.00 | 13,829.00 | 31,662,151.49 | 418,555.23 |
| 17 | ids 31,30,17 | 43,429.00 | 13,829.00 | 1,328,518.65 | 418,555.23 |
| 31 | all 88 | 1,045,629.00 | 14,050.00 | 4,284,986.95 | 57,924.94 |
| 31 | ids 31,30,17 | 43,429.00 | 14,050.00 | 178,814.21 | 57,924.94 |

### Review round 1, row 1: plain half-to-even Vacations (D8, 2026-10-15)

`PR_RiskAnalysisReport` no longer emulates the System.Decimal quotient error (`VacationBalanceScale`, `q`, `vacTie` removed): Vacations rounds with the same plain half-to-even CASE as Risk / VacationBalance, and `Salary` is cast to `DECIMAL(19,4)` (was `DECIMAL(15,4)`). Deployed to UNP-Ali with `parity/deploy_Risk_D8.sql` (CREATE OR ALTER of that one function, the worktree file verbatim). Oracle `--fixed`, output `parity/risk-oracle-fixed-D8.out`.

**Result: 40 mismatches in 44 runs, all expected.** Every mismatch is Vacations and Total on the same row, exactly 0.01 (20 x Vacations, 20 x Total; no other column, no missing / extra rows, RowNo dense 1..n in all 44 runs). They are the 10 ties where the legacy decimal error pushed the value off even (the "10 of 34" above), each seen at IsArabic 0 and 1:

| RiskDate | Employees (all active run) | Legacy (D6 oracle) | TVF (exact half to even) |
|---|---|---|---|
| 2026-10-15 and 2026-10-15 14:37:21 | 2 | 6,864.37 | 6,864.38 |
| 2026-10-15 and 2026-10-15 14:37:21 | 23 | 43,659.25 | 43,659.24 |
| 2026-04-10 | 26 | 57,279.11 | 57,279.10 |
| 2026-04-10 | 71, 73, 74, 75, 76 | 492,510.79 | 492,510.78 |

The other 24 ties and every non-tie row match; the subset runs (ids 31,30,17) have 0 mismatches. Selection independence unchanged: 66 rows checked, 0 differ; 53 distinct RiskAmount values on 2026-10-15. The `DECIMAL(19,4)` Salary cast changed no figure on this tenant (no salary needs more than 15 digits).

### Medical Insurance — real data (2026-10-15)
Only tenant on db-all with active `PR_MedicalInsurance` rows: **ERP_MainDB-Ali** (2 active rows, both `CardRecieved = 1`, 1 employee; found by a read-only scan of every tenant DB). No DDL there: `parity\parity_Medical_inline.sql` pastes the TVF body (HEAD) in place of the call. Output `parity\parity_Medical_inline.out`:

| Case | Legacy | TVF | L−T | T−L | BadSerial |
|---|---|---|---|---|---|
| all NULL ids, card 0 / 1 / 3 and empty ids card 0 | 2 | 2 | 0 | 0 | 0 |
| all NULL ids, card 2 | 0 | 0 | 0 | 0 | 0 |
| ids 31,30,17, cards 0/1/2 | 0 | 0 | 0 | 0 | 0 |

**PASS** on real rows for card all / delivered, all columns equal, Serial 1..n. Still not exercised by data: an undelivered card (card 2 with rows) and an expired policy row. Neither exists on any db-all tenant; covering them needs test rows inserted (engineer's OK) — logic is a single equality/date predicate copied from legacy.
