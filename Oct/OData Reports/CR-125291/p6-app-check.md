# CR-125291 — P6 app check: before (legacy MVC) vs after (OData), 2026-10-17

## Setup
- **Tenant:** company **ELGHONEIM** on `db-all`. The database was `ELGHONEIM_Primary` when the deploy ran (14:16). At 14:24 something outside this session renamed it to `ELGHONEIM`, and the tenant record now points there. The data (177,587 journals) and this CR's objects carried over.
- **Targeted deploy** (`worktrees\cr125291\deploy-cr125291-elghoneim.sql`, not committed): CREATE OR ALTER of the 5 TVFs plus seed `0437`. Layout ids 566–575, ar then en:

  | Report | ar | en |
  |---|---|---|
  | Brief | 566 | 567 |
  | Compare | 568 | 569 |
  | Financial Position | 570 | 571 |
  | Cash Flow | 572 | 573 |
  | Equity Changing | 574 | 575 |

  The objects stay on ELGHONEIM, as the sibling CRs left theirs on UNP-Ali.
- **After (new):** local AnalyticsReader (Debug) on `https://localhost:5655` (offset 600), with `DebugTenantConnection` = ELGHONEIM and Authority localbeta. Front on `http://localhost:4200`, where only `analyticsreaderapi` was edited, locally, and restored after. The engineer signed in.
- **Override proof:**
  - The log shows `DEBUG: Overriding tenant connection string with DebugTenantConnection`.
  - `sys.dm_exec_sessions` showed a `Core Microsoft SqlClient` session from DESKTOP-KPT7EFB on `ELGHONEIM` at request time.
- **Before (legacy):** `https://localstable.hadaf.website/mvc/FinancialReports/<X>`, which resolves the same tenant DB. Text was read from the DevExpress viewer's bricks, not from screenshots.
- **Filters:** Brief, Compare and Financial Position on 2025-12-31. Cash Flow and Equity from 2025-01-01 to 2025-12-31. All branches.

## Results — legacy print vs new print, same filters

| Report | Legacy en | Legacy ar | New OData rows | New screen grid | New print ar (viewer) | PDF/XLS ar+en | Verdict |
|---|---|---|---|---|---|---|---|
| Brief Balance Sheet | 8 figures, 1 page | same 8 | 8 = legacy | 8 = legacy, captions ar | 8 = legacy, 1 page | 200 ×4 | **MATCH** |
| Comparative Balance Sheet | 66 values, 2 pages | same 66, same order | 33 rows: all totals and both years = legacy, 24 sub-items | 33 | 66 values, same sequence as legacy, 2 pages | 200 ×4 | **MATCH** |
| Financial Position | 85 values (52 non-zero), 2 pages | same | 52/52 non-zero values, 0 diff | 37 | all values = legacy, 2 pages | 200 ×4 | **MATCH** |
| Cash Flow | 16 values, 1 page | same 16 | 16 = legacy | 16 | 16 = legacy; 1 page after the fix below | 200 ×4 | **MATCH** |
| Equity Changing | Opening 40,062,724.49, Change −1,263,077.78, Balance 38,799,646.71 | same | 7 long rows = legacy cells | 7 | same cells and totals, 1 page | 200 ×4 | **MATCH** |

Key figures, equal on both sides:
- **Brief:**
  - Fixed Assets 37,563,728.84
  - Working Capital 13,858,505.81
  - Capital Invested −44,748,425.54
- **Compare:**
  - Summary Assets 52,345,226.37 / 48,382,390.70
  - Summary of Liabilities −54,878,185.35 / −52,384,384.31
- **Financial Position:**
  - Capital 4,651,737.72
  - Total Investment 42,215,466.56
  - Investment Financing −44,748,425.55
- **Cash Flow:**
  - Operating 9,460,088.68
  - Investing (6,134,631.98)
  - Financing (1,294,551.25)
  - Net change 2,030,905.45
  - Start 3,590,583.77
  - End 3,250,787.22

## Defect found and fixed during P6
- **Branch caption overflow.** The forms select every branch by default (49 on ELGHONEIM). The print header listed all 49 names, which pushed Cash Flow's last two rows onto page 2.
- **Fix:** `FinancialStatementReportOptions.BranchFilter` prints "All" / "الكل" when the selected ids cover every `Acc_Branch` row, as CR-125290 did for journal types. The ids sent to the TVF are unchanged.
- **Re-checked:** Cash Flow ar now prints "الفروع: الكل" on 1 page, with the same 16 values.

## Visible differences (intended, D2/D6)
- **Captions fixed in the new print:**
  - Brief row 9 now reads "تمويل رأس المال المستثمر"; legacy repeated "رأس المال المستثمر".
  - The FPS Arabic header reads "الإهلاك"; legacy read "التفاصيل".
  - Cash Flow English typos are fixed.
  - Equity row captions are readable; legacy showed the raw keys "OpeningBlance / PeriodBalance / EndBalance" and sorted them alphabetically.
- **FPS English date:** legacy printed 12/31/2025 (en-US short date); the new print uses dd/MM/yyyy.
- **Equity total column:** legacy Arabic reads "اجمالى القيمه"; the new print reads "Grand Total" in both languages (DevExpress pivot limitation, as in CR-125290).
- **Paper:** A4 landscape and the house header, replacing the legacy portrait layouts.

## Not covered
- **English new print:** read only through the OData rows plus the 200 PDF/XLS renders. The viewer text was read in Arabic only, since the app session was in Arabic.
- **One tenant and one filter set** in this app check. P5 parity covers 5 tenants × 3 parameter sets.
