# CR 125293 parity R1-R3 (2026-10-14)

db-all / UNP-Ali, read-only (temp tables only). Legacy = xsd CommandText verbatim (`legacy_r1..3.sql`, identical on origin/Master_Stable) run through `sp_executesql` with the TableAdapter parameter types; new = the deployed TVF (deployed definition = branch file `cr125293` a1da17c2a). Run: `bash run.sh parity_R<n>.sql`; raw output in `out_R<n>.txt`.
Per case: row counts, EXCEPT both ways on all shared columns (RowNo excluded), a grouped multiset diff (duplicates), and the sum of every money column. Security level hi = 5 (max), lo = 1 (min; excludes employees 4 (lvl 5) and 113 (lvl 3)).

## R1 EmployeesSalariesItems — PR_Emp_Income vs PR_EmployeesSalariesItemsReport
Money: IncomeAmount, EmployeeInsuranceAmount, CompanyInsuranceAmount (the two insurance columns are NULL on every row).

| case | params legacy → new | legacy | new | L-N | N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| a1 | 'All',0 → (NULL,NULL,0) | 286 | 286 | 0 | 0 | yes (522814.50) | PASS |
| a2 | 'All',1 → (NULL,NULL,1) | 286 | 286 | 0 | 0 | yes | PASS |
| a3 | 'All',0 → (NULL,'All',0) | 286 | 286 | 0 | 0 | yes | PASS |
| b1 | 'AllInService',0 → (NULL,'AllInService',0) | 286 | 286 | 0 | 0 | yes | PASS |
| b2 | 'AllInService',1 → (NULL,'AllInService',1) | 286 | 286 | 0 | 0 | yes | PASS |
| c1 | 'AllTerminated',0 → (NULL,'AllTerminated',0) | 0 | 0 | 0 | 0 | yes (null) | PASS |
| c2 | 'AllTerminated',1 → (NULL,'AllTerminated',1) | 0 | 0 | 0 | 0 | yes (null) | PASS |
| d1 | '4,9,10',0 → ('4,9,10',NULL,0) | 18 | 18 | 0 | 0 | yes (53075.00) | PASS |
| d2 | '4,9,10',1 → ('4,9,10',NULL,1) | 18 | 18 | 0 | 0 | yes | PASS |

Coverage gap: UNP-Ali has no employee with EndWork = 1, so AllTerminated is 0 = 0 and AllInService equals All. IsArabic is exercised: all 286 EmployeeName values differ between ar and en.

## R2 PayCheck — Salaries vs PR_PayCheckReport (busiest pay month 7/2026, @IsPaid NULL)
Money: EmployeeSalary. Shared: all legacy columns; new-only EmployeeId, IsPaid, RowNo.

| case | params | legacy | new | L-N | N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| a1 | all, lvl 5 | 75 | 75 | 0 | 0 | yes (300718.93) | PASS |
| a2 | all, lvl 1 | 74 | 74 | 0 | 0 | yes (294343.93) | PASS |
| b1 | ids 1,2,4 + bank 1, lvl 5 | 3 | 3 | 0 | 0 | yes (41050.00) | PASS |
| b2 | ids 1,2,4 + bank 1, lvl 1 | 2 | 2 | 0 | 0 | yes (34675.00) | PASS |
| c1 | banks 1,2, lvl 5 | 75 | 75 | 0 | 0 | yes | PASS |
| c2 | bank 2 (no rows), lvl 5 | 0 | 0 | 0 | 0 | yes | PASS |

Fix (IsPaid filter): for every case IsPaid=1 rows + IsPaid=0 rows = the NULL result (multiset diff 0 both ways, sums equal), the IsPaid=1 subset has only IsPaid=1 and the IsPaid=0 subset only 0 → PASS.
Coverage gap: UNP-Ali has one Pr_PayingSalaries header (id 2, bank 1, IsPaid = 1, 75 lines) and no unpaid header in any month, so the IsPaid=0 subset is always empty; the "Not paid" branch is only proven to return nothing here, not to return unpaid rows.

## R3 EmployeeSalaryReceipt — FillByEmployeeId vs PR_EmployeeSalaryReceiptReport
Mapping: legacy 1st Suspend (PR_Salaries, DataSet `Suspend`) = Suspend; legacy 2nd Suspend (PR_SalaryDetail, DataSet `Suspend1`) = SalaryDetailSuspend; legacy 2nd SalaryId (PR_Salaries) dropped — equal to SalaryId on every row (0 mismatches). Money: IncomeAmount, Total, InsuranceCompany, TotalAdditions, TotalDeductions.

| case | params | legacy | new | L-N | N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| a1 | 8/2026 all, lvl 5 | 1458 | 1458 | 0 | 0 | yes | PASS |
| a2 | 8/2026 all, lvl 1 | 1416 | 1416 | 0 | 0 | yes | PASS |
| b1 | 8/2026 ids 1,4,113, lvl 5 | 58 | 58 | 0 | 0 | yes | PASS |
| b2 | 8/2026 ids 1,4,113, lvl 1 | 16 | 16 | 0 | 0 | yes | PASS |
| c1 | 7/2026 all, lvl 5 | 1421 | 1421 | 0 | 0 | yes | PASS |

Coverage gap: every Suspend / SalaryDetailSuspend value is 0 in 8/2026, so the data cannot tell the two Suspend columns apart; the mapping is verified by reading the SQL (TVF lines 52-53 vs legacy column order and the xsd Mappings Suspend / Suspend1).

## Verdict
20/20 cases PASS, no unexplained difference. No FAIL to trace.
