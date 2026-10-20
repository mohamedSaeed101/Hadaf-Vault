# CR 125293 parity — seeded follow-up (rollback-only) on db-all / UNP-Ali (2026-10-14)

Covers the coverage gaps of results-R1-R3.md / results-R4-R5.md by seeding the missing data **inside one transaction per script that ends with ROLLBACK TRAN** (no COMMIT, no DDL, no persistent object; results kept in table variables, which survive the rollback).
Scripts: `seeded_R1.sql` … `seeded_R4.sql` (legacy SQL embedded verbatim from `legacy_r*.sql`, run via `sp_executesql` with the TableAdapter parameter types), raw output `out_seeded_R<n>.txt`. Proof of no persistence: `seeded_verify.sql`, outputs `seeded_verify_before.txt` / `seeded_verify_after.txt`.
Run: `bash run.sh seeded_R<n>.sql`.

Each script: `SET XACT_ABORT ON`, table-variable declarations and a "before" read, `BEGIN TRAN`, seed, legacy + TVF captured, `ROLLBACK TRAN`, `@@TRANCOUNT` (0), comparisons, then a `GO` batch that re-queries the touched rows outside any transaction.
Triggers: none on Pr_PayingSalaries, Pr_PayingSalariesDetail, PR_Employee, PR_Salaries, PR_SalaryDetail, PR_EmployeeIncome (`sys.triggers`).
Transaction time: R1 335 ms, R2 968 ms, R3 369 ms, R4 621 ms.
Comparison: shared columns (RowNo excluded), EXCEPT both ways, grouped multiset diff (duplicates), and the sum of each money column.

## R1 EmployeesSalariesItems — EndWork = 1 on employees 1 and 2 (1 + 5 open income rows)

| case | legacy → new params | legacy rows | new rows | except L-N | except N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| a0 | 'All',0 → (NULL,NULL,0) | 286 | 286 | 0 | 0 | yes (522814.50) | PASS |
| a1 | 'All',0 → (NULL,'All',0) | 286 | 286 | 0 | 0 | yes | PASS |
| a2 | 'All',1 → (NULL,'All',1) | 286 | 286 | 0 | 0 | yes | PASS |
| b1 | 'AllInService',0 | 280 | 280 | 0 | 0 | yes (479739.50) | PASS |
| b2 | 'AllInService',1 | 280 | 280 | 0 | 0 | yes | PASS |
| c1 | 'AllTerminated',0 | 6 | 6 | 0 | 0 | yes (43075.00) | PASS |
| c2 | 'AllTerminated',1 | 6 | 6 | 0 | 0 | yes | PASS |
| d1 | '1,9',0 → ('1,9',NULL,0) | 7 | 7 | 0 | 0 | yes (51600.00) | PASS |

AllTerminated returns only employees 1,2 (legacy and TVF), 6 rows = their 6 open income rows → PASS. All 286 = AllInService 280 + AllTerminated 6; 0 terminated rows in AllInService.

## R2 PayCheck — one unpaid header (id -1, 7/2026, bank 1, IsPaid 0) with 5 lines copied from paid header 2 (employees 1–5; employee 4 is security level 5)

Legacy (no paid filter) vs TVF `@IsPaid NULL`:

| case | params | legacy rows | new rows | except L-N | except N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| a1 | all, lvl 5 | 80 | 80 | 0 | 0 | yes (349801.93) | PASS |
| a2 | all, lvl 1 | 78 | 78 | 0 | 0 | yes (337051.93) | PASS |
| b1 | ids 1,4,9 + bank 1, lvl 5 | 5 | 5 | 0 | 0 | yes (80350.00) | PASS |
| b2 | ids 1,4,9 + bank 1, lvl 1 | 3 | 3 | 0 | 0 | yes (67600.00) | PASS |

Fix (`@IsPaid`), expected = base-table lines split by the header flag:

| case | NULL | @IsPaid=0 (exp) | @IsPaid=1 (exp) | 0 vs exp diff | 1 vs exp diff | wrong flag | (0 ∪ 1) vs NULL diff | sum NULL = sum 0+1 | result |
|---|---|---|---|---|---|---|---|---|---|
| a1 | 80 | 5 (5) | 75 (75) | 0 | 0 | 0 | 0 | 349801.93 = 49083.00 + 300718.93 | PASS |
| a2 | 78 | 4 (4) | 74 (74) | 0 | 0 | 0 | 0 | yes | PASS |
| b1 | 5 | 2 (2) | 3 (3) | 0 | 0 | 0 | 0 | yes | PASS |
| b2 | 3 | 1 (1) | 2 (2) | 0 | 0 | 0 | 0 | yes | PASS |

@IsPaid=0 returned exactly the seeded lines (employees 1,2,3,4,5 at lvl 5; 4 dropped at lvl 1; 1,4 / 1 with the id filter).
Identity: the seed used explicit negative ids (`SET IDENTITY_INSERT`, a session option, not DDL), so the identity seed did not move: IDENT_CURRENT header/detail 2/89 before, inside the transaction and after rollback (a normal insert would have left a persistent identity gap).

## R3 EmployeeSalaryReceipt — 8/2026: PR_Salaries.Suspend = 1 on SalaryId 733 (employee 3, 20 lines), PR_SalaryDetail.Suspend = 1 on SalaryDetailId 13377 only

| case | params | legacy rows | new rows | except L-N | except N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| a1 | 8/2026 all, lvl 5 | 1458 | 1458 | 0 | 0 | yes | PASS |
| a2 | 8/2026 all, lvl 1 | 1416 | 1416 | 0 | 0 | yes | PASS |
| b1 | 8/2026 ids 3, lvl 5 | 20 | 20 | 0 | 0 | yes | PASS |

Mapping (legacy captured by position): legacy 1st Suspend = 1 on 20 rows ↔ TVF Suspend = 1 on 20 rows; legacy 2nd Suspend (Suspend1) = 1 on 1 row (13377) ↔ TVF SalaryDetailSuspend = 1 on 1 row (13377); legacy 2nd SalaryId = SalaryId on every row. The swapped mapping (Suspend ↔ SalaryDetailSuspend) gives 19 EXCEPT rows per case, so the data now tells the two columns apart and the mapping is proven by data, not only by reading the SQL. Full EXCEPT stays 0 → PASS.

## R4 InsuranceRegistration — EndWorkingDate on employees 5 (2026-01-31, passed) and 6 (2027-12-31, future); today 2026-10-14

(a) TVF vs `legacy_r4_fixed.sql` (22 legacy columns):

| case | params | legacy rows | new rows | except L-N | except N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| wide | 1900..2100, '' / NULL, sec 5 | 87 | 87 | 0 | 0 | yes (508939.50) | PASS |
| wide low sec | same, sec 1 | 85 | 85 | 0 | 0 | yes | PASS |
| ids | 1900..2100, '5,6,9', sec 5 | 2 | 2 | 0 | 0 | yes (36950.00) | PASS |
| narrow | 2014-01-01..2014-12-31, '' / NULL, sec 5 | 4 | 4 | 0 | 0 | yes (37425.00) | PASS |

(b) Fix effect, untouched `legacy_r4.sql` vs fixed (differences expected, every case): row count unchanged (one in, one out), EXCEPT 1 / 1.

| case | untouched rows | fixed/TVF rows | added by Fix | removed by Fix |
|---|---|---|---|---|
| wide sec 5 | 87 | 87 | Employee_6 (EndWorkingDate 2027-12-31, not reached) | Employee_5 (2026-01-31, passed) |
| wide sec 1 | 85 | 85 | Employee_6 | Employee_5 |
| ids 5,6,9 | 2 | 2 | Employee_6 | Employee_5 |
| narrow 2014 | 4 | 4 | Employee_6 | Employee_5 |

Why: legacy `EndWorkingDate < GETDATE()` kept an EndWork = 0 employee whose end date has passed and dropped one whose end date is still ahead; the Fix `EndWorkingDate >= CAST(GETDATE() AS DATE)` inverts that. TVF matches the fixed legacy in every case (TVF has Employee_6, not Employee_5).

## Nothing persisted

- Every script: `@@TRANCOUNT` = 0 right after ROLLBACK and in the post-run batch.
- Touched rows re-read after rollback: employees 1,2 EndWork 0; employees 5,6 EndWorkingDate NULL; SalaryId 733 and SalaryDetailId 13377 Suspend 0; no Pr_PayingSalaries / detail row with a negative id, no unpaid header; 1 header / 75 lines.
- `seeded_verify.sql` before vs after all runs: identical (diff empty) — row counts, CHECKSUM_AGG(BINARY_CHECKSUM) of Pr_PayingSalaries, Pr_PayingSalariesDetail, PR_Salaries, PR_SalaryDetail and of PR_Employee (EmployeeId, EndWork, EndWorkingDate), IDENT_CURRENT 2 / 89, EndWork = 1 count 0, EndWorkingDate count 0, Suspend = 1 counts 0.
- The first R2 attempt failed at compile time (a variable name clash), so no statement ran; fixed and re-run.

## Verdict
R1 8/8, R2 4/4 + Fix 4/4, R3 3/3 + mapping 3/3, R4 (a) 4/4 PASS; R4 (b) shows exactly the approved Fix (one employee in, one out per case). The coverage gaps in the earlier results are now closed by data.
