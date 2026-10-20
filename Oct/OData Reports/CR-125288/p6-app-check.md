# CR-125288 — P6 app check (2026-10-15)

## Setup

- **Tenant:** `unp-ali` on `db-all`, company **UNP-Ali**, signed in through the localbeta identity. The engineer signed in.
- **Targeted deploy (no full dacpac):** the 4 TVF files and seed `0430` were run with sqlcmd.
  - Layout ids: 2800–2807. The pairs are R1 2800/2801, R2 2802/2803, R3 2804/2805 and R4 2806/2807, each ar-EG then en-US.
  - The same deploy was also run earlier on **ELGHONEIM_Primary**, which was used only for SQL smoke checks.
- **Local services:**
  - AnalyticsReader on `https://localhost:5355` and GL API on `https://localhost:5302`, both offset 300. Both ran Debug with `DebugTenantConnection` set to unp-ali and `Authority` set to localbeta.
  - Front on `http://localhost:4200`. In `config.json`, `analyticsreaderapi` and `generalledgerapi` pointed at the local APIs. That edit was restored afterwards.
- **Override proof:**
  - The API log contains "Overriding tenant connection string".
  - `sys.dm_exec_sessions` showed unp-ali sessions from `DESKTOP-KPT7EFB` at request time.

## Results

| Check | R1 Period balance | R2 Budget for a period | R3 By month | R4 By day |
|---|---|---|---|---|
| Screen opens, Arabic captions, "طباعة (التصميم السابق)" button | OK | OK | OK | OK |
| Grid preview → `odata/<Name>/$query` | 200, **209** rows (SQL 209) | 200, **1,336** rows with "show all" (SQL 1,336); account 1 = 5,504,551.635 (SQL 5,504,551.6352) | 200, no data (tenant has no budgets) | 200, no data |
| Print in viewer (ar) | 47 pages; header, period, branches, account groups and totals render | — | — | — |
| `AngularReportPdf` ar / en | 200 / 200 (42 / 53 pages) | 200 / 200 (35 / 35 pages) | 200 / 200 (1 page, empty) | 200 / 200 (1 page, empty) |
| `AngularReportXls` ar / en | 200 / 200 | 200 / 200 | 200 / 200 | 200 / 200 |
| Totals in print | Grand total Debit Local 15,021,441.51 / Credit Local 4,003,333.58, equal to SQL | no totals (as legacy) | — | — |

Visually checked:
- the en R1 PDF (first and last page)
- the ar R2 PDF (first page)
- the ar R1 in the DevExpress viewer

## Findings

1. **Grid PDF export returns 404.** `report-grid.component.ts:871` builds `…5355//angular/AngularReportPdf` when `analyticsreaderapi` ends with "/", which is the case on both stage hosts. Excel export uses the correct path. CR-125292 fixed this line on its own branch, which is not yet in `Master_Stable`. AC 3 (PDF from the grid) depends on that fix landing.
2. **Branch filter text is cut off** in the R1 Arabic header when all 17 branches are listed. The cell shows a fragment ("6,…"). When the list is NULL it prints "الكل"/"All".
3. **Arabic decimal separator:** ar prints use the culture's Arabic comma ("100،00%", "1،203،304.87"). This comes from the culture, not the layout.
4. **R1 page density:** each account is its own block, so 209 rows take 42–53 pages. The legacy layout was built the same way (group per account).
5. **Budget data:** R3 and R4 could not be shown with data on unp-ali, which has 0 budget rows. Their numbers are proven only by P5 parity (Rusasnew, dbriyadh, ERP_MainDB-Ali).

## Fixes applied after P6 (2026-10-15, engineer's ask), uncommitted

- **Grid PDF export:** `report-grid.component.ts:871` drops the extra `/` before `angular/AngularReportPdf`. The hunk is byte-identical to cr125292's, so the two merge cleanly. This touches a shared component outside the 4 reports' own files; flag it in the review.
  - Verified on unp-ali: the grid's own `DesignSelectedForDownload(2800)` now calls `https://localhost:5355/angular/AngularReportPdf` and gets a 200 with a PDF. Before the fix it returned 404.
  - `npm run testing` exits 0 with no TS/NG errors.
- **Branch filter truncation (0430):**
  - R1 ar and en: the filter table is now 116 high instead of 58, and the PageHeader is 546 instead of 488. Page-header controls cannot grow, so the extra height is what makes room for the list.
  - All 8 layouts: the branch and cost-center value cells (14 in total) get `TextFitMode="ShrinkOnly"`.
  - The 8 XMLs parse and the sqlproj builds with 0 errors.
  - Redeployed to unp-ali, updated in place with the same ids 2800–2807. With all 17 branches selected, the R1 ar print shows every branch (Branch_1 … Branch_27, wrapped, smaller font), and R2 ar shows the full list wrapped.
  - **ELGHONEIM_Primary still has the first 0430 version.** Re-run the seed there if it is used again.
