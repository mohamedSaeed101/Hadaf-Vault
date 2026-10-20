# Review round 2 — CR_125293   verdict: pass

Bases / heads (`git diff origin/Master_Stable...HEAD`; working trees clean except the local-only `config.json`, never staged):
- AccFlex_Cloud_Database  base 489493497bb  head db8d8fa24 (round-2 commit: S1, S2, S3, S4)
- AccFlex_Cloud_ERP       base 20e781f504a  head 857d878a94 (unchanged since round 1)
- AccFlex_Cloud_Front     base 0abc198bbd4  head 2514d6b727 (round-2 commit: F2, F3, F4, F5, F6)

Scope of this round: only the rows of `review-1.md`. No new rows; no fix introduced a `block`.

## Verification of round-1 rows

| Row | Status claimed | Verified | Evidence |
|---|---|---|---|
| 1 | done (D5) | accepted | User decision recorded; no code change required. |
| 2, 3, 4 | left | accepted | Non-binding nits, unchanged. |
| S1 | done | yes | `PR_EmployeesSalariesItemsReport.sql:65` now `Acc_ConvertIntListToTable(@EmployeeIds)`; the function returns `number int`, `NULL` → `'0'` (guarded by `@EmployeeIds IS NULL OR` before it), so the "All" path is intact. All five TVFs now use the Int variant. |
| S2 | done | yes | `PR_InsuranceRegistrationReport.sql:146` same change; the `@EmployeeIds = ''` branch still works (`''` → `convert(int,'')` = 0, no error, and the OR short-circuits logically). |
| S3 | done | yes | `PR_InsuranceRegistrationReport.sql:193` `ORDER BY EmployeeName, InsuranceNum, IDNumber`; both columns are in the final CTE select list (lines 151-154). Output column set and types unchanged. |
| S4 | done | yes | `PR_EmployeeBonusReport.sql:33` `N'Yes'` / `N'No'`; `IsPaidStr` stays NVARCHAR. |
| B1, B2, B3 | left | accepted | Resolved by D4 / controller precedent / sibling-CR precedent, as agreed in round 1. |
| F1 | disagree | accepted, row dropped | `EmployeeMonthFormComponent.getQuery` (`projects/payroll/src/app/shared/components/employee-month-form/employee-month-form.component.ts:55-79`) returns a different shape (`{ Month, EmployeeList, InServiceFilter }`, `Month` mandatory, reads the form's own `employeeRef`), so reuse would mean embedding the whole month form or refactoring the shared component outside the CR. Keeping the logic local is the surgical choice (Coding guidelines 3). |
| F2 | done | yes | `insurance-registration-report-shell.component.ts:51-57` `onPreviewClick(e: PreviewArgs)` with `sqlMinDate` / `toDate < fromDate` check, `COMMON._dateOutOfRangeMessage_` (exists in both `shared.json`), `e.Canceled = true`; `.html:67` binds `(OnPreviewClick)="onPreviewClick($event)"`. Identical to the bonus shell precedent; `PreviewArgs` and `AccflexToasterService.showErrorToast` paths exist. |
| F3 | done | yes | 17 duplicated keys removed from `SALARYODATAREPORTS` in both languages; every column that used them now reads `ODATAREPORTS.<key>`. Script check: all 17 keys exist in `ODATAREPORTS` of both `en-US/shared.json` and `ar-EG/shared.json`; no shell references a `SALARYODATAREPORTS` key that no longer exists; no `ODATAREPORTS` block added to `payroll.json`; en/ar `SALARYODATAREPORTS` key sets identical. |
| F4 | done | yes | `pay-check-shell.component.ts:51-53` uses `SALARYODATAREPORTS.All / Paid / NotPaid`; keys added in both languages. |
| F5 | done | yes | `gridQueryOptions: Record<string, string>`, `EmployeeIdList: number[]`, `BankList: number[]` in all five shells; `handleEmployeeIdChange` already typed `selectedRowKeys: number[]`. |
| F6 | done | yes | `sharedEmployeeListRef` renamed in `.ts:14-15` and `.html:12`; the single usage at `.ts:52` follows. |

## Findings

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| — | — | — | — | No open rows. | — |

Verdict: pass. block 0, should 0, nit 0. Round 3 not needed.
