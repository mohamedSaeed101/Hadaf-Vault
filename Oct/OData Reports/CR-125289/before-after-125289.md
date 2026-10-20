# CR-125289 — before / after data test (legacy MVC iframe vs OData)

Run 2026-10-15, at the engineer's request. Tenant **UNP-Ali**, plus a re-run of the P5 SQL parity. Nothing was written to any DB, nothing was committed, and no repo file was edited. See [[parity-125289]] for the method and [[p6-app-check]] for how the services ran.

## Verdict

| Report | SQL parity, current TVFs (parts PASS, all 5 tenants) | UNP-Ali SQL: rows legacy / new, key totals | App on UNP-Ali: legacy print vs new print | Match |
|---|---|---|---|---|
| R1 Brief | 18/18 | 9 / 9. GOP 2,319,136.8548; NPBT and Net −2,319,136.8548 (printed `(2,319,136.85)`) | ar and en: 1,876,185.13 / 4,195,321.98 / GOP 2,319,136.85 / 0.00 ×3 / NPBT (2,319,136.85) / tax 0.00 / Net (2,319,136.85), line for line | **yes** |
| R2 Brief by cost center | 18/18 | 7 / 7, all values NULL (no line on UNP-Ali has a cost center) | Legacy prints **0.00** in other income, G&A, other expenses, NPBT, taxes and net. The new print leaves them **blank** | **data yes, print no** (divergence 1) |
| R3 Brief by branch | 18/18 | 21 / 21. GOP −2,319,136.8548, Net −2,319,136.8548 | ar and en: 7 branch groups with the same GOP each (Branch_4 1,876,185.13 … Branch_27 −495,059.96), Total GOP −2,319,136.85, NPBT −2,319,136.85, Net −2,319,136.85 | **yes** |
| R4 By branch | 18/18 | 0 / 0 (UNP-Ali has no income-statement sub items) | Both prints are empty. Legacy shows the surplus/deficit cell as `0`; the new cell is blank | **yes** (no data; cosmetic note) |
| R5 By branch, production | 18/18 | 0 / 0 | Both empty. Legacy shows balance 0 / avg cost 0; new shows total produced qty 0.00 and blank cells | **yes** (no data) |
| R6 By cost center | 18/18 | 0 / 0 | Both empty (legacy surplus/deficit `0`, new blank) | **yes** (no data) |
| R7 Cost-center period compare | 36/36 | 6 / 6 (cost center 1). The 5 type totals are 0; Net 0 / 0 / 0 | ar: 5 type rows 0.00 ×3 and Net 0.00 ×3. Period headers 01/10/25–15/10/26, 16/09/24–01/10/25, 01/10/24–15/10/25 on both | **yes** |
| R8 Branch period compare | 36/36 | 21 / 21. GOP −2,319,136.8548 / 0 / 444,931.3967; Net −2,319,136.8548 / 0 / 0 | ar and en: Total Branch GOP −2,319,136.85 / 0.00 / 444,931.40; 5 type rows 0.00; Net −2,319,136.85 / 0.00 / 0.00. The per-branch columns are equal (e.g. Branch_20 −1,230,111.75 / 0.00 / −29,108.52) | **yes** |
| R9 Per period | 38/38 | 0 / 0 item rows; C# totals 0 = 0 | Both empty | **yes** (no data) |

- **SQL parity re-run:** 0 failures across 249 non-control compare parts: counts, EXCEPT both ways, the duplicate-aware check and the SUMs. 163/163 key-total lines are equal (legacy = new). Negative controls: 8 of 9 parts detected. The one miss is FHCG R9T, whose S1 totals are all 0, so a branch perturbation cannot move them; the R9 cell part of the same control is detected.
- **R8's percentage fix is confirmed.** The R78 part (with percentages) now passes on all 13 P5 sets. In P5 it failed 13/13.
- **The deployed TVFs on UNP-Ali equal the current repo files**, all 9, compared whitespace-insensitively with `OBJECT_DEFINITION`. They are not deployed on the 4 parity tenants; parity runs the bodies inline.

## Divergences

1. **R2 (and R3) with no detail rows: legacy prints 0.00, the new report prints blank.**
   - Evidence: `ba-R2-before.png` / `ba-R2-before-en.png` show 0.00 in other income, G&A, other expenses, NPBT, taxes and net profit. `ba-R2-after.png` shows the same rows with no values. UNP-Ali, cost center 1, 2025-10-01..2026-10-15.
   - Cause: `Acc_CostCenterBriefIncomeStatementReport` returns NULL for the report-wide rows when `DetailCount = 0` (`CASE WHEN s.DetailCount > 0 THEN … END`). Its header comment says the legacy computed them only when a group printed. The legacy print still shows its design-time `0.00`. P5's expected side models the same assumption, so the SQL parity cannot catch this. It is print-only: no money differs, and the case arises only when the filter returns no group.
   - `Acc_BranchBriefIncomeStatementReport` has the same CASE, so it presumably behaves the same (not seen here, because R3 has data on UNP-Ali).
   - Not fixed (per instructions). Options: return 0 instead of NULL in that branch, or have the layout print `0.00` for NULL.
2. **R1 grid (not the print): profit and loss look the same.** The grid shows `Total` (the ABS value): GOP, NPBT and Net all read `2,319,136.855` with no parentheses or sign (`ba-R1-after-grid-ar.png` / `-en.png`). The legacy print and the new print show NPBT and Net as `(2,319,136.85)`. The grid has no legacy counterpart, so this is a usability note rather than a parity break. The data has `SignedValue` and `IsNegativeShownInParens`.
3. **Cosmetic, empty data only (R4 and R6):** legacy prints `0` in the empty cross-tab's surplus/deficit cell; the new one leaves it blank.

Not divergences:
- The grid shows 3 decimals (`4,195,321.985`) where both prints round to 2 (`4,195,321.98`). This is the accepted N2 print decision in [[decisions]].
- The new en print of R1/R3/R8 runs to 2 pages because of the all-types journal-type cell (P6 finding 1, now much smaller than P6's 27 pages). Totals are unaffected.
- Branch names print `فرع_N` in en: that is the data, as in P6.

## Setup and parameters

- **DB:** `db-all`, database `UNP-Ali` (ApproximateNo 2, SQL_Latin1_General_CP1_CI_AS). Activity runs 2025-10 to 2026-10. No journal line carries a cost center, `Acc_IncomeStatmentSubItem` is empty, and no account is mapped, so R4/R5/R6/R9 are empty by data.
- **App parameters (the screens' defaults):** 2025-10-01..2026-10-15, revised = all, all 95 journal types, all 17 branches (1–7, 18–27). Cost center = 1 ("البلاستيك") on R2/R6/R7, where the screen requires it; none on R1/R9.
- **SQL sets on UNP-Ali:**
  - U1 ar / U2 en: app parameters with cost center 1 on every report that takes it.
  - U4 ar / U5 en: same window, no cost center. These are the R1/R9 app parameters.
  - U3 en: 2026-01-01..2026-06-30 with all lists NULL.
- **4 parity tenants:** the 13 P5 sets, unchanged (see [[parity-125289]]).
- **Before (legacy).**
  - Source: the "Print (previous design)" iframe src, `https://localstable.hadaf.website/mvc/FinancialReports/<Action>?lang=…&fromDate&toDate&revised&journalTypes&costCenterIds|branchesIds`. That is `printRedirectUrl` from config.json; no token is added to the URL.
  - Actions: BriefIncomeStatment, CostCenterIncomeStatement, BranchIncomeStatement, IncomeStatemetBranchs, IncomeStatemetBranchsProduction, IncomeStatementCostCenter, IncomeStatementActivityDetail, IncomeStatmentBranchPeriod, IncomeStatemetPerPeriod.
  - Opened in a tab with the same query (Chrome already had a session) and read from the DevExpress viewer, ar and en.
  - It reached the same DB: `sys.dm_exec_sessions` on UNP-Ali showed a `.Net SqlClient` session from host **DB-ALL** at 21:39:27, right after the first legacy render, and the print footer says `PC: DB-ALL`.
- **After (new).**
  - Grid: the screen's Show/Preview.
  - Print: `POST angular/AngularReportPdf?reportName=…&layoutId=…`, sent with the grid's own `{filters, queryOptions}` through its HttpClient. The PDF was shown in the page and never downloaded.
  - Layouts: ar 2840/2842/…/2856, en 2841/2843/2845/2855.
  - en was run with the UI in English (`SelectedLang`), so the TVF names and the number culture are English.
- **Services:**
  - The P6 build (`scratchpad\p6\bin`, built 20:14, after the last code change at 20:02; the 21:24 remove-redundant edit only dropped XML comments): AnalyticsReader on https://localhost:5555 and GL on https://localhost:5502.
  - Process environment variables only: `ASPNETCORE_ENVIRONMENT`, `Authority` = localbeta, `ConnectionStrings__DebugTenantConnection` → db-all/UNP-Ali.
  - Front `npm run dev` on 4200, with config.json pointed at the two local APIs.
  - Proof that the override took: UNP-Ali sessions from `DESKTOP-KPT7EFB` ("Core Microsoft SqlClient Data Provider") at 21:38, and the grid values equal the SQL.
- **Script:** scratchpad `ba\parity-ba.sql`, generated by `ba\gen_ba.py` from the P5 generator.
  - Every TVF body comes from the current files (R2/R3 19:58, R7/R8 19:57; `PrintedOnly*` removed from the holder).
  - It adds the UNP-Ali sets, a KEY-totals line per case, and the deployed-vs-file check.
  - Raw output: `ba\out_<tenant>.txt`.

## Screenshots (this folder)

| Report | Before (legacy) | After (new) |
|---|---|---|
| R1 | `ba-R1-before.png` (ar), `ba-R1-before-en.png` | `ba-R1-after.png` (ar print), `ba-R1-after-en.png`, `ba-R1-after-grid-ar.png`, `ba-R1-after-grid-en.png` |
| R2 | `ba-R2-before.png`, `ba-R2-before-en.png` | `ba-R2-after.png`, `ba-R2-after-grid-ar.png` |
| R3 | `ba-R3-before.png` (totals), `ba-R3-before-ar-top.png`, `ba-R3-before-en.png` | `ba-R3-after.png`, `ba-R3-after-en.png`, `ba-R3-after-grid-ar.png` |
| R4 | `ba-R4-before.png` | `ba-R4-after.png`, `ba-R4-after-grid-ar.png` |
| R5 | `ba-R5-before.png` | `ba-R5-after.png`, `ba-R5-after-grid-ar.png` |
| R6 | `ba-R6-before.png` | `ba-R6-after.png`, `ba-R6-after-grid-ar.png` |
| R7 | `ba-R7-before.png` | `ba-R7-after.png`, `ba-R7-after-grid-ar.png` |
| R8 | `ba-R8-before.png` (totals), `ba-R8-before-ar-top.png`, `ba-R8-before-en.png` | `ba-R8-after.png`, `ba-R8-after-en.png`, `ba-R8-after-grid-ar.png` |
| R9 | `ba-R9-before.png` | `ba-R9-after.png`, `ba-R9-after-grid-ar.png` |

## Restored

- `config.json`: restored with `git restore`. No appsettings or launchSettings file was touched. `git status` in all 3 repos shows no config, appsettings, launchSettings or wwwroot entry.
- AnalyticsReader (5555), GL (5502) and `npm run dev` / `ng serve` (4200) were stopped, and none of the three ports answers.
- Browser: the two tabs this run opened are closed, and `SelectedLang` is back to unset. The P6 tab that was already open was left alone.
- DB: read-only throughout. Writes went only to `#temp` tables.

## Fix after this test (2026-10-15)
- **R2/R3 with no detail rows:** legacy printed 0.00 on the report-wide lines (other income, general expenses, other expenses, net profit before tax, taxes, net profit); the new print was blank. Both TVFs now return 0 (`CASE WHEN s.DetailCount > 0 THEN … ELSE 0 END`). Redeployed to UNP-Ali (CREATE OR ALTER) and checked with a cost center that has no rows: Partial/Total = .0000 on those lines. Rows with data are unchanged, because the CASE only changes the zero-detail branch.
- **Accepted, not changed:**
  - On an empty R4/R6 the legacy cross-tab printed 0 in the surplus/deficit cell, while the new print is blank. It is cosmetic, with no data.
  - The R1 grid shows the signed raw value; the print applies the legacy parentheses rule, and the legacy had no grid.
