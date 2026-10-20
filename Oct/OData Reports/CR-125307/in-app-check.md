---
type: test-results
cr: 125307
updated: 2026-10-15
---

# In-app check — phase 8 (2026-10-15)

## Setup
- **DB**: only this CR's objects applied to **UNP-Ali on db-all** — the 9 `PR_*Print` functions + 9 seeds (18 layouts, ApplicationId 4, layout ids 2808–2825). The full dacpac publish was **not** run: the `-Script` preview showed UNP-Ali is ahead of Master_Stable (it would drop `PR_SystemConfiguration.NotifyEmployeeOn{Bonus,HolidayWork,LeaveBalance}` and touch ~3,800 lines of other objects).
- **API**: AnalyticsReader from the set, Debug, `https://localhost:7485` (7285 + offset 200), `DebugTenantConnection` → UNP-Ali, `Authority` = accesscontrol.localbeta (front's authority).
- **Front**: set front on 4200 (`npm run dev`), `config.json` `analyticsreaderapi` → local API (local only, restored). Signed in with `scripts\app-login.ps1` (company UNP-Ali).
- **Proof the override took** (local-api-run step 4): log line `DEBUG: Overriding tenant connection string with DebugTenantConnection` ✅; `sys.dm_exec_sessions` on UNP-Ali shows sessions from host DEV5 at the call times ✅.

## Results

| # | Print | header id | ar-EG | en-US |
|---|---|---|---|---|
| 1 | EmployeeIncomePrint | 1 | ✅ 200, PDF rendered | ✅ |
| 2 | EmployeeAllowancePrint | 1 (no docs on UNP-Ali → header-only path) | ✅ | ✅ |
| 3 | AllowanceSerialPrint | 1 (no docs on UNP-Ali → header-only path) | ✅ | ✅ |
| 4 | EmployeeBonusPrint | 3 | ✅ | ✅ |
| 5 | EmployeeAdvancePrint | 1 | ✅ read: header, 15 repayments, Total 20,661.20, logo, RTL + Arabic name | ✅ read: same values, LTR |
| 6 | EmployeePurchasePrint | 1 | ✅ | ✅ |
| 7a | SalaryExchangePrint | 2 | ✅ | ✅ |
| 7b | BankSalaryPrint | 2 + `1\|2026-07-01\|1\|` | ✅ data path (see below) | ✅ |
| 8 | EmployeeAccrualPrint | 1 | ✅ | ✅ |

Rows 1–7a, 8: `angular/AngularPrintPdf` (the endpoint `log-lgx-print` uses for server PDFs) called from the signed-in page with the user's token; all 16 calls 200 with a rendered report (110–150 KB). No errors in the API log.

Currency cell shows `ê`: UNP-Ali's `Acc_Currency.EnglishLetter` for Saudi Riyal is U+00EA (tenant data; legacy prints the same).

### Bug found and fixed here — BankSalaryPrint print data
The viewer passes params as `…,,HeaderPrintData:<data>,,…` and `ReportExtensions.GetHeaderPrintData` takes `Split(":").LastOrDefault()` — the D12 JSON would have arrived truncated → bank print always empty. Fixed: printData = `bankId|yyyy-MM-dd|currencyId|employeeIds(dash)` — front `6729358a50`, AnalyticsReader `bee584ccc6` (D12 revised).
Verified: the viewer string → `GetHeaderPrintData` → `1|2026-07-01|1|` → `BankSalaryPrintAng` 4 parts → `PR_BankSalaryPrint(2,1,'2026-07-01',1,NULL,…)` on UNP-Ali = 75 rows, total 301,093.93, Bank_1, ar and en.

## Not verified here
- **Screen click-through** (Print button → layout picker → viewer): the screens' record search goes to the remote stage Payroll API, whose UNP-Ali tenant is not the db-all DB the local AnalyticsReader reads, so no record could be opened against the local prints; the GL report-viewer route redirected (GL app not open for this company). Front wiring is covered by the build gate and review; to be clicked through on Stage Beta after deploy.
- BankSalaryPrint rendered through the DevExpress viewer (data path proven, render not).
