---
type: spec
cr: 125307
updated: 2026-10-15
---

# CR-125307 — Spec: Payroll screen prints → AngularPrints

## Problem Statement
Eight Payroll screens print their document through the legacy MVC print viewer in an iframe (`accflex-report-iframe-post` → `/mvc/HRScreens/*`, `/mvc/HrReports/AllowanceSerial`, `/mvc/AccountingReports/BankSalaryPrint`). Customers cannot edit those layouts in the report designer, the look differs from the other screens, and the legacy print service cannot be retired ([[facts]] 1, 16).

## Solution
Move each screen's print to an AngularPrint in AnalyticsReader, following CR 125157 (monthly-salary): one SQL TVF per print that returns the same data as the legacy typed-DataSet queries plus their C# post-processing, one `IAngularPrint<T>` per print, a seeded Arabic + English layout per print (ApplicationId 4), and the screen's print button switched to `<log-lgx-print>` ([[decisions]] D1–D3, D9).

## User Stories
1. As a payroll user, when I press Print on Salary Items, Employee Allowances, Allowances, Bonus, Advance, Employee Purchase, Salary Payments Request (both prints) or Employee Accruals, the new print dialog opens and no iframe is shown.
2. As a payroll user, the printed document shows the same rows, amounts, totals and logo as the old print for the same record.
3. As a payroll user, I can print each document in Arabic (RTL) and English (LTR), with names and labels in the print language.
4. As a customer admin, I can open each of these prints in the report designer and adjust its layout.

## Acceptance
1. Each of the 9 prints (D3) opens from its screen's Print button through `<log-lgx-print>` with ReportName = the D3 value and ApplicationId 4; the screen no longer renders `accflex-report-iframe-post`.
2. For each print, the new TVF and the legacy `.xsd` query (with the C# post-processing of D4) return identical rows and values for the same ids on the number-check tenant — zero divergence ([[decisions]] D7).
3. Each ReportName has two seeded layouts (ar-EG RTL `الافتراضي`, en-US LTR `Default`), registered in the `.sqlproj`, carrying the legacy layout's fields, columns and totals.
4. The Arabic and English prints both render; employee names, currency names and type names follow the print language (D10).
5. A record with no detail lines (an advance / purchase with no repayments, an allowance doc with no rows) still prints its header.
6. Salary Payments Request: "print" gives `SalaryExchangePrint`; "bank salary print" gives `BankSalaryPrint` for the same bank, month, currency, employees and paying-salary id that the legacy URL used.
7. AnalyticsReader builds, the DB project builds, the front build gate passes.
8. Each screen's Print button keeps its existing Print-permission gating (D14).

## Known legacy behaviour kept (D17)
Reproduced for parity, flagged for a PO follow-up: no security level on prints 1 and 8; accrual working period to today for terminated staff; allowance AccumulatedBalance ignores type/currency; SalaryExchange prints the employee's first bank account; customised legacy bank-sheet layouts must be redone in the designer (roll-out note).

## Implementation Decisions
See [[decisions]] D1–D11. Key ones: AngularPrints pattern (D1), naming (D2), HeaderId per print (D3), legacy quirks reproduced in data (D4), seeds 0416+ (D5), front change limited to each screen's own print code (D6), bank print params through `moreDataWithPrint` (D9), language follows the print (D10).

## Testing Decisions
- Number check per print (acceptance 2): scratch SQL in the vault (`parity-125307.sql`) runs legacy query vs TVF on UNP-Ali / db-all with real ids; results in `parity-results.md`. A print with no data on the tenant is recorded as untested.
- Builds: DB `.sqlproj` with VS MSBuild, AnalyticsReader `dotnet build`, front build gate (`front-verify-build`).
- In-app check: each screen's print in ar and en on the set's local AnalyticsReader against the test tenant.
- No unit tests: the prints hold no logic beyond a TVF call (same as 125157 and the other Payroll prints).

## Out of Scope
- The standalone `bank-salary-print-report` screen and the other 96 iframe usages (D9, D6).
- Removing legacy MVC endpoints or the shared iframe components.
- Migrating tenant-customised legacy layouts (D11).
- Fixing legacy data quirks (D4) beyond the language display (D10).

## Further Notes
- Shared files with CR-125294 (`DataContext.cs`, `.sqlproj`): expect trivial merge conflicts (D8).
- Legacy layouts are code-first in `*.Designer.cs`; `C:\Work\Hadaf\ReportLayout` does not exist on this machine.
