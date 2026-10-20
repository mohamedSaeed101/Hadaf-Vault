# CR-125290 — P6 app check (2026-10-16)

## Setup
- **Tenant:** `UNP-Ali` on `db-all`, company **UNP-Ali**, signed in through the localbeta identity. The engineer signed in; the agent picked the company on the SelectTenant page.
- **Targeted deploy (no full dacpac):** `worktrees\cr125290\deploy-cr125290-unp-ali.sql` (not committed).
  - It creates or alters the 5 TVFs and runs seed `0436`. Layout ids 2858–2867: R1 2858/2859, R2 2860/2861, R3 2862/2863, R4 2864/2865, R5 2866/2867, each ar-EG then en-US.
  - The objects stay on UNP-Ali, as CR-125288's did.
- **Local services:**
  - AnalyticsReader on `https://localhost:5455` and GL API on `https://localhost:5402` (offset 400). Both ran as Debug builds with `DebugTenantConnection` = UNP-Ali and `Authority` = localbeta.
  - Front on `http://localhost:4200`. In `config.json`, `analyticsreaderapi` and `generalledgerapi` pointed at the local APIs. That edit was restored afterwards.
- **Override proof:**
  - `sys.dm_exec_sessions` showed SqlClient sessions from `DESKTOP-KPT7EFB` on UNP-Ali at request time.
  - API row counts equal the SQL counts: R1 7 rows, R2 28 rows.

## Results
| Check | R1 CC period | R2 Branch period | R3 CC vs budget | R4 Branch vs budget | R5 per month |
|---|---|---|---|---|---|
| `odata/<Name>` grid feed | 200, 7 rows (= SQL) | 200, 28 rows (= SQL) | 200, 0 rows (UNP-Ali has no `Acc_AccountBudget` rows; the query is budget-driven, as in legacy) | 200, 0 rows (same) | 200, 3 total rows (no account is mapped to an income-statement item, so legacy would be empty too) |
| `AngularReportPdf` ar / en | 200 / 200 (1 page) | 200 / 200 (2 pages) | 200 / 200 | 200 / 200 | 200 / 200 |
| `AngularReportXls` ar / en | 200 / 200 | 200 / 200 | 200 / 200 | 200 / 200 | 200 / 200 |
- **Screen (R2, ar):**
  - The form, the "طباعة (التصميم السابق)" button and the report-grid render.
  - Preview loads the rows, with Arabic account-type names (report 2's blank Arabic captions bug is not copied).
  - The print viewer opens the seeded Arabic default layout.

## Legacy vs new, same filters (R2, sub-period 22 = Aug 2026, all branches, all journal types)
- The legacy MVC print (`localstable …/mvc/FinancialReports/IncomeStatmentBranchBudget`) and the new TVF agree line by line:
  - Branch_6 2,474.32 / GOP −2,474.32.
  - Total Branch GOP −11,310.31, with every other income-type row 0.00.
  - **Net Profit −11,310.31**, the same figure in both.
- **Open question 8 is settled.** The legacy Net Profit includes the operating (type 1/2) rows that are cancelled at print time. If they were excluded, Net Profit would be 0.00. The TVF's reading is correct.

## Defect found and fixed during P6
- **The print header listed every journal type name** (about 95), which filled most of page 1. The form selects every type by default, and the legacy print never showed journal types.
- **Fix:** `IncomeStatementBudgetReportOptions.JournalTypeFilter`. When the list covers every `Acc_JournalType` row, it prints `ReportStrings.ReportFilterAll` ("الكل" / "All", new key in both resx files and Designer.cs); otherwise it lists the names as before.
- **Re-checked in the viewer:** the header now reads "أنواع القيود: الكل", and the layout and numbers render.

## Not covered
- **Budget-driven paths (R3/R4 rows, R1/R2 budget columns):** UNP-Ali has no budgets, so they printed empty here. P5 covers their numbers on synthetic budget rows.
- **R5 with sub-item data:** none on this tenant; P5 covers it on dbriyadh / ACCFLEX-ERP.
- **Visual check of the R1/R3/R4/R5 layouts:** only the HTTP 200 renders and page counts were checked; only R2 was viewed on screen.
