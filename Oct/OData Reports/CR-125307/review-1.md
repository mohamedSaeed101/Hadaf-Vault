---
type: review
cr: 125307
round: 1
updated: 2026-10-15
---

# Review round 1 — CR_125307   base db 489493497 / erp 20e781f504 / front 0abc198bbd   head db 3f08ed829 / erp bee584ccc6 / front 6729358a50   verdict: pass

Diff built per repo with `git diff origin/Master_Stable...HEAD` (working trees clean, `diff HEAD` empty). Read in full: 9 TVFs, 9 seeds (bound fields extracted), `.sqlproj` hunk, 9 entities + 9 configs + `DataContext.cs`, 9 `*PrintAng.cs`, all 19 front files, plus `lgx.print.component.ts`, `ReportExtensions.GetHeaderPrintData`, `ObjectDataSourceInjector.Process`, the 125157 precedent (front `12372f1b03`, erp `MonthlySalaryPrintAng.cs`), `SalaryExchangeDto` typings and the PR_* table definitions behind the entity types.

## Spec conformance (Acceptance 1–8)

| AC | Evidence | Status |
|---|---|---|
| 1 | 8 screens render `<log-lgx-print [ApplicationId]="4" [HeaderId] [ReportName]>`; `accflex-report-iframe-post` / `ReportSrcHandlerService` no longer referenced in any of the 8 modules (grep). ReportName strings in front = `*PrintAng.ReportName` = seed `@ReportName`, all nine equal to D3. | met (screen click-through still pending, row 3) |
| 2 | `parity-results.md`: 0 divergence on UNP-Ali + ERP_MainDB-Ali for all 9; prints 2, 3 had no data on UNP-Ali and were proven on ERP_MainDB-Ali. | met |
| 3 | 0416–0424, two `InsertLayout` each (`ar-EG` `الافتراضي` RTL, `en-US` `Default` LTR, `@ApplicationId = 4`), 9 `<None Include>` + 9 `<Build Include>` in the `.sqlproj`; base has only 0412 in the 041x range, 0413–0415 reserved for CR-125294 (D5). Every `[Field]` bound in each layout exists in its TVF / entity (checked all nine). | met |
| 4 | `@IsArabic` from `IUserSession.IsDefaultRequestCulture` in all nine; TVFs switch EmployeeName (Arabic fallback), CurrencyName, TypeName, BonusTypeName; `in-app-check.md` 9 x ar/en rendered. | met |
| 5 | Prints 2, 3, 5, 6, 8 LEFT JOIN from the header; header-only path exercised in-app for 2 and 3. | met |
| 6 | Two `<log-lgx-print>` in payments-request, same `HeaderId` = `printSalaryExchangeId`; bank print passes `bankId|yyyy-MM-dd|currencyId|employeeIds` via `moreDataWithPrint` → `HeaderPrintData` → `BankSalaryPrintAng` → `PR_BankSalaryPrint(headerId, bankId, month, currencyId, employeeIds, SecurityLevel, isArabic)`; values taken from the same `SalaryExchangeDto` fields the legacy URL used (`BankId`, `ExchangeDate`, `CurrencyId`, `EmployeesIds`, `SalaryExchangeId`). The pipe format survives `Split(",,")` + `Split(":").Last` (no `:` or `,,` possible: ints, ISO date, dashes). | met (data path; viewer render pending, row 3) |
| 7 | plan.md status: DB phase 4 MSBuild, erp phase 5 `dotnet build`, front phase 7 build gate; `prettier --check` on sampled changed files clean. | met per plan status (not re-run here) |
| 8 | `checkPrintPermission` left at its default `true` on all 9 `<log-lgx-print>`; the print buttons/floating icons unchanged. | met |

Out-of-scope items respected: no change to `bank-salary-print-report`, the shared iframe components, legacy MVC endpoints or other screens.

## Scope / surgical judgement

- Removing `showForm` / `hideForm` / `displayForm`, `showIframe` and the `[class.hiddednCotent]` bindings on 5 screens: these flags were toggled only by `OnPrint` / `whenPrintCancel` (iframe flow); once the iframe is gone they are orphans created by this change, so removing them is required by guideline 3 ("remove what YOUR changes made unused"), and D6 explicitly lists show/hide iframe code. Not a finding.
- Moving `OnPrint` from the data/form services to the shell components (employee-accruals, employee-allowances, payments-request): `ProcessPrint()` lives on the `@ViewChild` `LgxPrintComponent`, which a service cannot hold; the id stays in the service. Same shape as the 125157 precedent (`OnPrint` guard + `setTimeout(() => this.printRef.ProcessPrint())`). Not a finding.
- `QuerySerializeService` / `ReportSrcHandlerService` constructor params removed only where this change made them unused; `CleanObjectService` kept in payments-request because `cleanNullAndEmptyString` still uses it. Correct.

## Findings

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | AccFlex_Cloud_Front/accflex-erp/projects/payroll/src/app/modules/payments-request/shared/payments-request-data.service.ts:115-131 | nit | root CLAUDE.md Coding guidelines §3 Surgical Changes | `isFormValid` condition was re-flowed (`if (!(` … `))`) although no line of it belongs to the print change; logic is identical, current prettier accepts both shapes. | Revert the hunk unless `npm run prettier` re-produces it; if prettier forces it, leave it and note it in the PR as formatter noise. |
| 2 | AccFlex_Cloud_Front/accflex-erp/projects/payroll/src/app/modules/employee-accruals/components/employee-accruals/employee-accruals.component.html:31; employee-allowances/containers/employee-allowances-shell/employee-allowances-shell.component.html:29 | nit | root CLAUDE.md Coding guidelines §2 Simplicity | A bare `<div>` wrapper is left where only the `[class.hiddednCotent]` binding was removed (`<div>` around the form). | Either unwrap (move the child up one level) or keep as is; cosmetic. |
| 3 | vault in-app-check.md §Not verified here | should | spec Acceptance 1, 6 | AC1 (Print button → layout picker → viewer) and the BankSalaryPrint viewer render were not exercised end-to-end: the local AnalyticsReader could not be reached from a screen with a real record. Front wiring is reviewed here and the API path is proven, but no row shows a click on each of the 9 buttons. | Before Merge Desk Solved: click each of the 9 prints once on Stage Beta (ar and en for BankSalaryPrint) and record the 9 rows in `in-app-check.md`; a failure there reopens this round. |
| 4 | AccFlex_Cloud_Database/…/dbo/Functions/PR_EmployeeAdvancePrint.sql:42-43 | nit | decisions D4 / D17 (legacy behaviour kept) | `PaiedAmount` is aliased from `PR_AdvanceRepayment.Amount` (the scheduled amount), not from the `PaiedAmount` column; parity shows this is what the legacy `.xsd` returned, but it is not on the D17 follow-up list, so the PO will not hear that the "paid amount" column prints the instalment. | Add it as D17 item (8) in `decisions.md` (and the ship report's follow-up list); no code change. |
| 5 | AccFlex_Cloud_Database/…/dbo/Functions/PR_BankSalaryPrint.sql:23,87 | nit | AccFlex_Cloud_Database/.claude/rules/report-database-functions.md §Comma-Separated ID List Handling | Uses `Acc_ConvertStringListToTable(@EmployeeIds)` where the rule names `Acc_ConvertIntListToTable`; the parity run proves it works and it likely mirrors the legacy `.xsd`. | Keep if copied from the legacy query (say so in the header comment); otherwise switch to `Acc_ConvertIntListToTable`. |

## Checked and clean

- Backward compatibility: only additions (9 new TVFs, 9 new seeds, 9 new entity sets / DbSets / prints); no shipped DTO, route, column or TVF signature changed. `DataContext.cs` and `.sqlproj` hunks are pure inserts next to the 125157 lines (D8 merge note holds).
- HeaderId per screen = D3: salary-items `printEmployeeId` (EmployeeId), employee-allowances `printEmployeeAllowanceId`, allowances `printAllowanceId`, bonus `printEmployeeBonusId`, advance `printAdvanceId`, purchase `printPurchaseId`, payments-request `printSalaryExchangeId` (both prints), employee-accruals `printEmployeeId`. Each is set in the screen's open/load handler and reset to 0 in its `clearState` / clear (`advance:649`, `allowances:438`, `bonus:367`, `employee-accruals.service:62`, `employee-allowances-form.service:167`, `employees-incomes:255`, `payments-request-data.service:351-352`, `purchase:561`); `OnPrint` returns early on 0, matching the legacy "no ReportSrc → nothing".
- Entity property names/types vs TVF columns: all nine match column-for-column; types cross-checked against the table definitions where the in-app run could not have exercised them (prints 2 and 3 detail columns: `DECIMAL`/`MONEY` → `decimal?`, `INT` → `int?`, `BIT` → `bool?`, `DATETIME` → `DateTime?`). `EmployeeArabicName` is `NOT NULL`, so the three TVFs that test `LTRIM(RTRIM(...)) = ''` without `ISNULL` behave the same as the ISNULL variants.
- `BankSalaryPrintAng`: `int?`/`string` nulls go to `FromSqlInterpolated` as DBNull (TVF defaults `NULL` = all); bad/empty `printData` → empty list, no throw (D12); `ExchangeDate` is `Date` in the client typings so `format(…, 'yyyy-MM-dd')` is valid.
- Secrets, ports, local paths in the diff: none (grep for `C:\`, `localhost`, `Password=`, `:dddd`).
- Tests: none by spec Testing Decisions (prints hold no logic beyond the TVF call); parity + in-app check stand in. Accepted.
- Deliberate legacy quirks (D4/D17): the accrual working period to `GETDATE()`, allowance `AccumulatedBalance` without type/currency filter, SalaryExchange first bank account, no security level on prints 1 and 8: present as decided, not findings.

## Summary for the orchestrator

verdict: pass
counts: block 0, should 1, nit 4
block rows: none
round 2: not needed for code; row 3 (Stage Beta click-through of the 9 prints) is a ship-gate item to record in `in-app-check.md`, and rows 1, 2, 4, 5 are optional.

### Merged rows (main, round 1) — sql-reviewer, check-antipatterns (Front + Git hygiene)
| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 6 | AccFlex_Cloud_Database/…/dbo/Functions/PR_BankSalaryPrint.sql:53 | should | sql: AccFlex_Cloud_Database CLAUDE.md §Build (warnings naming a touched file) | `SalaryHeader.IdNumber` vs view column `IDNumber` → SQL71558 build warning | `SalaryHeader.IDNumber AS IdNumber` — done (691c70477) |
| 7 | AccFlex_Cloud_Database/…/dbo/Functions/PR_BankSalaryPrint.sql:23,87 | — (dup of #5) | sql: report-database-functions.md §Comma-Separated ID List | StringList vs IntList helper | **keep** — legacy `dsBankSalaryPrint.xsd` and sibling `PR_BankSalaryReport` use `Acc_ConvertStringListToTable`; parity proven with it (decision, no change) |
| 8 | …/PR_BankSalaryPrint.sql:5 | nit | sql: report-database-functions.md §Standard Parameter Patterns | `@Month DATE` vs DATETIME | optional |
| 9 | …/PR_EmployeeAccrualPrint.sql:1 | nit | sql: consistency | UTF-8 BOM (Arabic literals) | optional; keep (repo files with Arabic literals carry a BOM) |
| 10 | …/PR_EmployeeAccrualPrint.sql:32-110 | nit | sql: style | unqualified `PR_EmployeeTransactions` | prefix `dbo.` — done (691c70477) |
| 11 | …/ReferenceDataScripts/0416–0424_*.sql:1 | nit | sql: db-rules.md §Pre/Post Deployment Scripts | no `SET NOCOUNT`/`XACT_ABORT` (precedent 0412 has none) | optional |
| 12 | AccFlex_Cloud_Front/…/payments-request-data.service.ts:113-127 | — (dup of #1) | AP: Git hygiene "Change unrelated to the work item" | isFormValid reflow | **no change possible**: the pre-commit hook `pretty-quick --staged` reformats the whole staged file; the block is unformatted on Master_Stable, any revert is re-applied on commit |
| 13 | AccFlex_Cloud_Front/…/employees-incomes-shell.component.ts:~86 | should | AP: R:core.md correctness | `printEmployeeId = e` set before `getEmployeeIncomeInfo` succeeds → Print enabled for an employee whose data never loaded | set the id after the load succeeds — done (0a077d503a) |
| 14 | AccFlex_Cloud_Front/…/payments-request-shell.component.ts:~33-43 | nit | AP: Architecture DRY | OnPrint / OnPrintBankSalary duplicate guard | optional |
| 15 | AccFlex_Cloud_ERP/…/AngularPrints/Payroll/BankSalaryPrintAng.cs:36,40 | should | backend: core.md §Error Handling; report-backend.md §Artifact 4 ("return empty list, don't throw") | non-numeric employee-id token → SqlException at materialisation instead of the empty path | `int.TryParse` each dash token; any failure → empty data source; join parsed ints with ',' — done (a610bee481) |
| 16 | AccFlex_Cloud_ERP/…/Models/DataContext.cs:379-387 | nit | backend: report-backend.md §Artifact 3 (alphabetical in module section) | 9 DbSets not alphabetical | reorder the nine lines — done (a610bee481) |
| 17 | AccFlex_Cloud_ERP/…/ODataViewsConfigurations/Payroll/*PrintConfigs.cs | — | backend: report-backend.md §Naming | `*PrintConfigs` vs `*Config` | none — Payroll folder precedent (MonthlySalaryPrintConfigs) |

**Verdict after merge: pass** — block 0 · should 4 (#3 ship-gate, #6, #13, #15) · nit 9.
Apply now: #6, #13, #15 (should), #10, #16 (cheap nits). #3 runs after the Stage Beta deploy. Others: keep/optional as noted.
Known platform limitation (backend reviewer, outside the diff): server-side PDF/XLS export paths call `GetDataSource(headerId, string.Empty)` → BankSalaryPrint is empty there; the screens use the viewer path (`printWithServerPdf` false), which passes the print data → recorded as D19.
