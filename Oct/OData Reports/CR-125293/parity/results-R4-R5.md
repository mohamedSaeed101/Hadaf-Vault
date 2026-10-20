# CR 125293 parity — R4 InsuranceRegistration, R5 EmployeeBonus

DB `db-all` / `UNP-Ali` (read-only; temp tables only). TVFs as created there 2026-10-14 21:42 (Fix clause present).
Run: `bash run.sh parity_R4.sql`, `bash run.sh parity_R5.sql`, `bash run.sh probe_R4_fraction.sql`.
Legacy SQL: `legacy_r4.sql` (untouched), `legacy_r4_fixed.sql` (only the approved Fix line changed), `legacy_r5.sql`.
Comparison: 22 shared columns (R4) / 20 shared columns (R5), multiset EXCEPT both ways (ROW_NUMBER dup column), RowNo excluded, sums of money columns.

Data caveat: UNP-Ali has 88 employees, none with an EndWorkingDate, all EndWork = 0; TotalInsuranceLocal is 0 everywhere; only 3 PR_EmployeeBonus rows (employee 14, 2026-10-14).

## R4 InsuranceRegistration — (a) fixed legacy vs TVF (Int/Fraction columns excluded here)

| case | params (from, to, ids, sec) | legacy rows | new rows | L-N | N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| wide | 1900-01-01, 2100-01-01, legacy '' / new NULL, 5 | 88 | 88 | 0 | 0 | Y (522814.5) | PASS |
| wide low sec | same, 1 | 86 | 86 | 0 | 0 | Y | PASS |
| narrow | 2026-01-01, 2026-09-27 (midnight both), all, 5 | 19 | 19 | 0 | 0 | Y (86961) | PASS |
| 3 ids | wide, '4,9,113', 5 | 3 | 3 | 0 | 0 | Y (47350) | PASS |
| 3 ids low sec | wide, '4,9,113', 1 | 1 | 1 | 0 | 0 | Y | PASS |
| new '' | wide, legacy '' / new '', 5 | 88 | 88 | 0 | 0 | Y | PASS |
| backend toDate | narrow, new toDate = GetDayEnd 23:59:59.997, legacy midnight | 19 | 22 | 0 | 3 | N (86961 vs 107228) | FAIL (not a TVF diff) |

But the full TVF row (all columns, as EF/OData reads it) **fails with Msg 8115** on wide/wide-low-sec/'' cases — see Int/Fraction.

### (b) Fix effect vs untouched legacy
0 rows added, 0 removed in every case: no employee in UNP-Ali has an EndWorkingDate, so the Fix cannot be observed on this DB.
(Legacy kept EndWork = 0 employees whose EndWorkingDate already passed and dropped those with a future end date; the Fix inverts that.)

### Int/Fraction (legacy C# InsuranceRegistrationReport.cs:66-79 emulated in SQL)
- TotalIncomeLocal / TotalInsuranceLocal are decimal(38,13) → legacy `ToString()` always has '.' and 13 decimals → legacy would never crash (0 crash cells); assumes a '.' decimal separator culture.
- Int columns: TotalIncomeInt / InsuranceInt identical to legacy in every case.
- Fraction columns: **FAIL**. `PR_InsuranceRegistrationReport.sql:221` and `:227`: `(TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100`. FLOOR(decimal(38,13)) is decimal(38,0); the subtraction overflows precision and SQL Server cuts its scale to 0, so the fractional part rounds to 0 or 1 before `* 100`:
  - fraction >= .5 → 100 → `CAST(... AS VARCHAR(2))` → **Msg 8115 Arithmetic overflow**, the whole report query fails (15 of 88 employees here have .50, so the wide range errors out);
  - 0 < fraction < .5 → '00' instead of legacy digits (e.g. 1234.25 → '00', legacy '25'; probe_R4_fraction.sql).
  - Candidate (not applied): `RIGHT('0' + CAST(CAST(FLOOR(v * 100) - FLOOR(v) * 100 AS INT) AS VARCHAR(2)), 2)` matched legacy on 88/88 rows and on all probe literals.

### Backend toDate deviation (not in the approved Fixes)
Legacy front sends `toDate` as `yyyy-MM-dd` and the legacy report uses it as is (midnight), so employees whose SocialInsuranceStartDate is on the toDate with a time part are excluded. The new backend passes `_toDate.GetDayEnd()` (`AnalyticsReader.Api\ODataControllers\Payroll\PayrollOdataController.cs:285`, `AngularReports\Payroll\SalariesReports\InsuranceRegistrationRptAng.cs:34`), which includes them: +3 rows (Employee_118/119/120, start 2026-09-27 08:27 / 08:38 / 14:31). 24 of 88 employees have a time part. Decide: accept as a Fix or pass `_toDate.GetDayStart()`.

## R5 EmployeeBonus (legacy toDate = toDate + 1 day - 1 s; TVF toDate = GetDayEnd .997)

| case | params (from, to, ids, sec, isArabic) | legacy rows | new rows | L-N | N-L | sums equal | result |
|---|---|---|---|---|---|---|---|
| range ar0 | 2026-01-01..2026-10-14, NULL, 5, 0 | 3 | 3 | 0 | 0 | Y (1006 / 1452.5) | PASS |
| low sec ar0 | same, 1, 0 | 3 | 3 | 0 | 0 | Y | PASS |
| 3 ids ar0 | '4,14,113', 5, 0 | 3 | 3 | 0 | 0 | Y | PASS |
| range ar1 | NULL, 5, 1 | 3 | 3 | 0 | 0 | Y | PASS |
| low sec ar1 | NULL, 1, 1 | 3 | 3 | 0 | 0 | Y | PASS |
| 3 ids ar1 | '4,14,113', 5, 1 | 3 | 3 | 0 | 0 | Y | PASS |
| before bonus day | ..2026-10-13, NULL, 5, 0 | 0 | 0 | 0 | 0 | Y | PASS |
| 3 ids no bonus | '4,9,113', 5, 1 | 0 | 0 | 0 | 0 | Y | PASS |

jobName → JobName compared as the same column. Only edge: bonuses stamped 23:59:59.003-.997 on the toDate are included by the new call, excluded by legacy (none in data).

## Re-run after fixes (2026-10-14, main session)
- TVF fix DB 3a7a8d86c: fraction = FLOOR(v*100) - FLOOR(v)*100 → redeployed on UNP-Ali. Direct check vs legacy C# split: 88/88 rows Int and Fraction equal (15 rows with .50 now '50'), no overflow. (The probe columns TvfIncFrac in parity_R4.sql re-compute the OLD formula inline, so their "15 error cells" are stale — ignore.)
- Backend fix ERP 857d878a94: Insurance toDate GetDayEnd → GetDayStart (legacy used the date at midnight). The "narrow midnight" case = what the backend now sends: PASS 19/19.
- All other R4 cases PASS (out_R4_rerun.txt).
