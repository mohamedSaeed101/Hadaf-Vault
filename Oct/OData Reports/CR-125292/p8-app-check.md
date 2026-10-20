---
type: test-results
cr: 125292
date: 2026-10-15
---

# CR-125292 — P8 app check (local API + front against unp-ali)

## Setup

- DB: the 10 TVFs + 0414 layouts deployed to **unp-ali on db-all** with the targeted script `worktrees\cr125292\deploy-cr125292-unp-ali.sql` (CREATE OR ALTER × 10, InsertLayout × 16; no table DDL). The full dacpac publish was refused by sqlpackage (would drop other branches' columns: `Lgx_Characteristic.IsSalesOrderReference`, `PR_SystemConfiguration.Notify*`…) and nothing was applied; never use `-AllowDataLoss` there.
- Verified: 10 inline TVFs, 16 layouts (ar-EG `الافتراضي` stored as proper Unicode, en-US `Default`), `PR_PostedSalariesReport(7,2026,5,1,NULL)` = 75 rows.
- AnalyticsReader from the set, Debug, `https://localhost:5255` (5055 + 200), `DebugTenantConnection` → unp-ali, `Authority` = localbeta identity (env vars only).
- Front from the set, `npm run dev`, `localhost:4200`; local `config.json` change: only `analyticsreaderapi` → `https://localhost:5255/` (restore at teardown).
- **UNP-Ali is a Stage Stable tenant** signing in through the localbeta identity server. Pointing `miscapi` / `dashboard` at localbeta made the session monitor end the session and land on `localstable.hadaf.website`; keep them on localstable.
- Override proof: API log line "Overriding tenant connection string with DebugTenantConnection", and a `sys.dm_exec_sessions` row on UNP-Ali from this PC (`DESKTOP-KPT7EFB`) at the request time.

## Results

| Report | Count via app API (Jul 2026 unless noted) | Parity | Screen / print checked |
|---|---|---|---|
| R1 Signature | 76 | 76 | API |
| R2 Summarized header / lines | 75 / 271 | 75 / 271 | grid + detail expand + AR print (23 pages, employee then its lines) |
| R3 Detailed header / lines | 76 / 1,421 | 76 / 1,421 | API |
| R4 In period Apr–Aug | 81 | 81 | API |
| R5 Income group 3 | 850 | 850 | API |
| R6 Departments | 76 | 76 | API |
| R7 No salary, branch 1 | 13 | 13 | API |
| R8 Posted Jul / unposted Aug | 75 / 78 | 75 / 78 | grid + AR print: footer Add 340,431.68 / Ded 39,337.75 / Net 301,093.93 = parity |

## Findings

1. **FIXED 2026-10-15 (uncommitted):** **Arabic layouts printed English employee names.** All 8 ar-EG layouts in `0414_PR_SalaryReportsLayout.sql` bind `[EmployeeName]` (lines 142, 578, 1211, 1847, 2420, 2908, 3487, 3924); the Arabic grid shows `EmployeeArabicName`. Fixed: the 8 ar-EG layouts bind `[EmployeeArabicName]` (8-line diff in 0414, EN untouched); seed redeployed to unp-ali (8 ar-EG layouts carry EmployeeArabicName, 8 en-US do not, no duplicates); R8 Arabic print re-checked (موظف_1 …); sqlproj build green. Not committed yet.
2. **Old-design print from localhost:** the button posts the legacy form (`employeeIds`, `lang`, `month`) to `https://localstable.hadaf.website/mvc/AccountingReports/EmployeeSalaryDetails` into `reportFrame`; the cross-origin stage MVC page stays blank when the front runs on localhost. Wiring correct; rendering to check on the deployed stage app. **Q8 resolved** on stage: legacy repeats the first employee header on every block (see [[open-questions]] Q8).
3. Typing a month into the masked month box left the bound value at today (both "07/2026" and "072026" typed by the browser tool; the tool inserts text instead of key strokes, which a mask ignores). Not reproducible as a user bug from here; the calendar works. Same unchanged control on the legacy stage screens: out of scope, not fixed.
4. Report-grid-multi-request (R2, R3) renders amounts in Eastern Arabic digits, report-grid (R8) in Western digits: grid-component behaviour, not this CR.
5. **FIXED 2026-10-15 (uncommitted):** two clear buttons on each screen. Removed the forms' own `search-cancel-button` (+ its `onCancel`) from `salary-report-form` and `income-group-report-form` (used only by these 8 shells); every shell's grid "Clear Filters" already calls `ReportFormRef.resetForm()`. Verified on R8: only "Print (previous design)" + grid "Clear Filters" remain.

## English UI and export (2026-10-15, engineer OK for language switch + downloads)

- English UI: R8 grid (English captions, Employee_n names, Saudi Riyal) and English print (LTR mirror, "Posted Salaries Report", July / 2026, 4 pages) OK.
- **Excel export OK:** grid "Export all data to XLS" → layout picker → XLSX with header, 75 employees, footer 340,431.68 / 39,337.75 / 301,093.93.
- **PDF export broken by a pre-existing shared-component bug:** `report-grid.component.ts:871` (unchanged vs Master_Stable, last commit 0548eb665b 2026-01-28) builds `${analyticsReaderUrl}/angular/AngularReportPdf` in the branch for a URL that already ends with "/", so the request goes to `//angular/AngularReportPdf` → 404. Both stage configs end with "/" (`analyticsreader.localstable.hadaf.website/`, `analyticsreader.localbeta.hadaf.website/`), so report-grid PDF export fails for every report there today. With the local URL without the trailing slash the same export returns 200 and a 4-page PDF. One-character fix: drop the "/" in line 871. **FIXED in this CR 2026-10-15 (engineer: no preference → recommended option), uncommitted:** `report-grid.component.ts:871` now `${analyticsReaderUrl}angular/AngularReportPdf` like the XLS branch; with the stage-style trailing-slash URL the export returns 200 and a 4-page PDF. Shared component: affects every report-grid PDF export (fixes them); call it out in the review.

## All 16 layouts render (2026-10-15)

POST `/angular/AngularReportPdf` per layout from the signed-in session (Jul 2026; R4 Apr–Aug; R5 group 3; R7 branch 1; R8 posted): all 16 (8 reports × ar-EG / en-US, LayoutId 2784–2799) return 200 with a PDF (base64 `%PDF-1`), 127k–604k chars. Content read page by page only for R2 (AR) and R8 (AR + EN); the rest proven to render with data.

Front build after both fixes: `npm run testing` EXIT 0, no TS/NG errors.

## Not checked yet

- Page-by-page reading of the R1, R3–R7 prints.
