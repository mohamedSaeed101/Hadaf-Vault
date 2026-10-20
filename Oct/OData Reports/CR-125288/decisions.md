# CR-125288 — decisions

The engineer took these decisions on 2026-10-15. Each one is the recommended option and matches CR-125292.

| # | Decision | Effect |
|---|---|---|
| D1 | **Full interactive report grid** for all 4 reports, not printOnlyMode. Same as CR-125292 D2. | Deviates from the `mvc-to-odata-report-migration` print-only default. The ticket AC wins (filter/sort/group/export on screen). Needs one `odata/<Name>` action per entity in `GLODataController`, plus a seeded print layout per report. |
| D2 | **Port the legacy SQL exactly** (CR-125292 D4). The quirks below are reproduced, then reported to the PO as separate Bugs. | Parity expects zero divergence. |
| D3 | **Keep the old print** as "Print (previous design)": the form's existing Print button is relabelled and still runs the iframe (CR-125292 D3). | No `-legacy` route. |

## Quirks reproduced (to report to the PO)
- **Estimated budget for a period (A):**
  - Budget = SUM of `IsFixedWeekly = 1` rows. It is not prorated to the dates.
  - The account lookup is required on screen but ignored by the server, because the legacy query passes `@AccountList = NULL`.
- **Estimated budget by month (B):**
  - Journals have no lower date bound, only `CreatedDate <= to`.
  - Grouping is by `MONTH()` alone, so different years fold into the same month number.
  - The budget is keyed by `AccountingSubPeriodId` used as a month number.
  - An account appears only when it has a budget row for that month.
  - A date range longer than 100 months fails (SQL error 530). The recursive month CTE has no MAXRECURSION, exactly as in the legacy query.
- **Estimated budget by day (C):**
  - The whole `IsFixedDaily` budget total repeats on every day row, and DeviationPercent divides by that total.
  - The form's `toDat` typo leaves toDate at today. This is a front-only quirk; the new screen keeps the same form.
- **A, B, C:** DeviationPercent divides by the signed Budget, and is 100 when Budget is 0.
- **Period balance:**
  - A NULL branch list includes balances whose branch is NULL.
  - The `Debit/Credit > 0` filter is on foreign-currency amounts.

## Rule bends (recorded at review round 1, 2026-10-15)
- **`report-backend.md` §Artifact 2 asks for `HasKey(RowNo)` + `ToFunction`.** The 4 EF configs use `HasNoKey()` with no `ToFunction` instead, as the GL siblings do (BalanceSheet fx123513, IncomeStatement, AccountBalanceByMonth). Every call path uses `FromSqlInterpolated`, and keyless avoids tracking on the composed OData path. The OData entities still key on `RowNo`.
- **Shared component:** `report-grid.component.ts:871`, a one-line PDF-URL fix outside the 4 reports, made at the engineer's request and byte-identical to cr125292's hunk. Name it in the PR.

## Technical choices (agent, within D2)
- **B keeps the legacy recursive month CTE.** It has the same 100-month limit as the legacy query, which had no MAXRECURSION. `DATEADD` on the previous value drifts the day-of-month, and that drift decides the `<= to` boundary. A tally would not reproduce it.
- **C replaces the recursive day CTE with a digits tally.** An inline TVF cannot carry `OPTION (MAXRECURSION 0)`, and EF composes OData queries over it. Day steps from 00:00 have no drift, so the output is identical.
- **Month names:** the TVF returns both `MonthName` (EN) and `MonthNameArabic` with no `@IsEnglish` parameter. The legacy names' trailing space is trimmed; parity compares on `Mnth`.
- **Currency in period balance:** the TVF adds `CurrencyNameArabic` so the Arabic grid and print show the Arabic name. Legacy printed `CurrencyName` in both languages.
