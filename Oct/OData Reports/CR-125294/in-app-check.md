---
type: in-app-check
cr: 125294
updated: 2026-10-14
---

# CR-125294 — In-app check (UNP-Ali, partial)

**Setup:** AnalyticsReader Debug from `cr125294` (`277ebf7d56`) on https://localhost:7485, using `DebugTenantConnection` → `db-all` / `UNP-Ali` and Authority localbeta. Front from `cr125294` (`1ef801747b`) on http://localhost:4200, signed in to UNP-Ali, Arabic. The front used the main checkout's packages via per-package links, except `logistics.api.client`, which is the pinned 1.0.3893.

**Proof the queries reach UNP-Ali:** `sys.dm_exec_sessions` on db-all shows sessions named `cr125294-local` on `UNP-Ali`, ending 18:03:34. That matches the API log `SELECT * FROM PR_UnpaidAdvancePaymentsReport(...)` at 18:03:34.

| Screen | Result |
|---|---|
| رصيد سلف الموظفين — Unpaid advance payments | Renders as the OData report grid (no iframe). The request reaches the TVF. 0 rows: the tenant has no paid advances (see [[parity-results]]) |
| السلف — Employees advance | 01/06/2026–14/10/2026, no employee filter: **8 rows** for the browser-pane user, **9 rows** for the `.env.local` user (higher security level), matching the number check;, grouped by employee, amounts and dates correct. Employee 4 (20,661.20) is hidden because their `EmployeeSecurityLevel` is 5, above the signed-in user's level. That is the security filter added on purpose (parity at level 5 shows 9) |
| Detail expand (Employees advance) | Employee 79, AdvanceId 8: 3 installments × 500 = 1,500 = the advance amount. Filtered by `AdvanceId eq 8` |
| Currency column | Stored letter is `ê` (Acc_Currency 1, U+00EA). The house font renders it as the riyal symbol. Data, not code |
| Print | **Pass (ar + en)**, 2026-10-14, headless Chrome. Picker → seeded default layout → viewer renders 7 pages from `DXXRDVAngular` (all 200). House header with company logo, "تقرير السلف" / "Employees Advance Report", From/To, one block per advance with its installments and total. English is the LTR mirror. Note: unpaid installments show Paid Amount = installment amount, same as the legacy SQL (`ar.Amount AS PaiedAmount`) |
| Employee purchase | Not opened (tenant has 0 purchases) |
| English | **Pass**: grid (9 items), detail tab "Installments", print layout in English |
| Excel/PDF export | **Pass (ar + en)**: "Export all data to PDF/XLS" → layout picker → Select → download. PDF 139 KB / 133 KB. XLSX 178 rows, including advance total 20,661.20, installment 1,500 and report total **132,436.23** (= number check) |

## Finding

- **F1 — fixed 2026-10-14, front `8c1accad0e` (local, not pushed):** the detail tab title shows `ODATAREPORTS.الأقساط`. `advance-report-shell` (and the same pattern in `employee-deduction-shell`) passes `details = [t('Repayments')]`, which is already translated. `report-grid-multi-request` translates `details` again as `ODATAREPORTS.<key>`. Sibling shells pass the raw key (`['Details']`, `['Transactions']`). Fix: pass a key the grid can resolve, either a key under `ODATAREPORTS` or one the grid's `TranslationObjectKey` points to.

## Tester note

The date box uses mask input: typed text only commits with real keystrokes. Pasted text shows in the box but leaves the value at today.

**F1 fix:** `details = ['Repayments']` plus `[customTransalatePropertyList]="detailTitles"` (`{ Key: 'Repayments', Value: t('Repayments') }`), the same mechanism the logistics aging reports use. Re-checked in the app: the tab now reads الأقساط. `npm run testing`: exit 0, no errors.

## With test data (`testdata-125294-UNP-Ali.sql`, 2026-10-14)

| Screen | Result |
|---|---|
| Unpaid advance payments | Grid: 2 rows (emp 10: before 3,000 → end 3,000; emp 31: advance 3,000, paid 1,000 → end 2,000). Print ar + en: 1 page, totals 3,000 / 3,000 / 1,000 / 5,000. XLSX export ar + en: pass. **PDF export: 404** (see F2) |
| Employee purchase | Grid 2 rows, Installments tab, print, PDF + XLSX export: **pass in ar + en** |

## F2 — fixed 2026-10-14, front `f58eff4e44` (local, not pushed)

Shared `src/app/shared/components/report-grid/report-grid.component.ts:869-871` (last changed by fx123482, 2026-09-29): when `analyticsreaderapi` ends with `/`, the PDF branch still prepends `/`, so the URL becomes `…//angular/AngularReportPdf` → 404. The XLS branch just above handles it correctly. It affects every simple `report-grid` PDF export whenever the configured URL ends with `/` (the committed default does). Fixed on cr125294 at the engineer's request (it bends the scope rule): the PDF branch drops the extra `/`. Re-checked: Unpaid PDF export downloads in ar + en. `npm run testing`: exit 0.

## Before / after video (2026-10-14)

[[CR-125294-before-after.mp4]] (2 min 25 s). **Before** = the legacy iframe reports on Stage Stable (https://localstable.hadaf.website, company UNP-Ali, which reads the same db-all/UNP-Ali data: the `CR-125294 test data` rows appear there). **After** = cr125294 on localhost (AnalyticsReader on 7485, front on 4200). Same filters (From 01/01/2026). Signed in with the engineer's `app-login.ps1` profile.

| Report | Before (legacy) | After (cr125294) |
|---|---|---|
| Unpaid advance payments | No employee selected → fails: `Conversion failed when converting the nvarchar value 'null' to data type int`. "Select all" also sends `employeesIds=null` and fails. With employees 10 + 31 picked one by one, the report renders them | Grid with no employee selection needed; same 2 employees |
| Employees advance | Each of the 9 employees picked by hand; iframe viewer, one form per advance with its installments | 11 advances grouped by employee (139,436.23), installments on expand, print with the seeded 0413 layout |
| Employee purchase | Employees 64 + 70 picked by hand; iframe viewer with installments | 2 purchases (4,900), installments on expand |

**Print (after) verified:** the seeded Arabic layout renders the header, date range, each advance and its installments, and the totals (e.g. Employee_4: 15 installments, 20,661.20). The currency letter prints as the stored `ê`.

Not covered: English print and Excel/PDF export (English grid shown in the earlier take only).

