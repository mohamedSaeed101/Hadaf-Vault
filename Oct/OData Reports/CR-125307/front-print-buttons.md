---
type: analysis
cr: 125307
updated: 2026-10-15
---

# Front — current print buttons (explorer, 2026-10-15)

Root `AccFlex_Cloud_Front\accflex-erp\projects\payroll\src\app\modules` (`M\`). Every legacy screen: Print → `OnPrint` shows `<accflex-report-iframe-post [ReportSrc]>`; `ReportSrc` is pre-built on record load via `ReportSrcHandlerService.getIframeSrc(path, query)` (`src\app\shared\services\report-src-handler\report-src-handler.service.ts:11`) → `${printRedirectUrl}${path}?lang=..&query` (+access_token off-prod).

| Screen | OnPrint / ReportSrc built | Legacy path + query | Id available |
|---|---|---|---|
| salary-items (module employees-incomes, ModuleId 277) | `M\employees-incomes\containers\employees-incomes-shell\employees-incomes-shell.component.ts:265` / `:140` | `HRScreens/EmployeeIncome?EmployeeId=` | EmployeeId (per employee) |
| employee-allowances | `M\employee-allowances\shared\employee-allowances-form.service.ts:307` / `:178` | `HRScreens/EmployeeAllowance?employeeAllowanceId=` | res.EmployeeAllowanceId |
| allowances | `M\allowances\containers\allowance-shell\allowance-shell.component.ts:459` / `:170` | `HrReports/AllowanceSerial?allowanceId=` | res.AllowanceId |
| bonus | `M\bonus\containers\bonus-shell\bonus-shell.component.ts:221` / `:173` | `HRScreens/Bonus?bonusId=` (stray space) | res.EmployeeBonusId |
| advance | `M\advance\containers\advance-shell\advance-shell.component.ts:553` / `:165` | `HRScreens/EmployeeAdvance?advanceId=` | res.AdvanceId |
| purchase | `M\purchase\containers\purchase-shell\purchase-shell.component.ts:504` / `:135` | `HRScreens/EmployeePurchase?purchaseId=` | res.PurchaseId |
| payments-request | `M\payments-request\shared\payments-request-data.service.ts:373` (exchange), `:433` (bank) / `:142`, `:146` | `HRScreens/SalaryExchange?salaryExchangeId=`; `AccountingReports/BankSalaryPrint?bankId&month&currencyId&employeeIds&payingsalaryid` | res.SalaryExchangeId, BankId, ExchangeDate, CurrencyId, EmployeesIds |
| employee-accruals | `M\employee-accruals\shared\employee-accruals.service.ts:152` / `:174` | `HRScreens/EmployeeAccrual?employeeId=` | employeeId (per employee); OnPrint shows iframe even with empty src (duplicate line) |

## New print precedent (monthly-salary, CR 125157)
`M\salary\containers\salary-shell\salary-shell.component.ts` — `reportName = 'MonthlySalaryPrint'` (:54), `printSalaryMainId` from `res.SalaryMainId` (:222, reset :539), `OnPrint` (:479) → `setTimeout(() => this.printRef.ProcessPrint())`. Template `salary-shell.component.html:57`: `<log-lgx-print #print [ApplicationId]="4" [HeaderId]="printSalaryMainId" [ReportName]="reportName">` — `LgxPrintComponent` in `src\app\shared\components\print\`. Single `HeaderId` input, ApplicationId 4.

## payments-request bank print
Standalone `bank-salary-print-report` (`M\accounting-reports\accounting-reports.module.ts:120`, `BankSalaryPrintShellComponent`) still prints via legacy `AccountingReports/BankSalaryPrint` (:96); its grid uses `ReportName="BankSalaryReport"` (report-grid). → reuse question, see decisions.
