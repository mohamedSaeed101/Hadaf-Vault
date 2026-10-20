# CR-125289 — decisions

**Settled 2026-10-15 by the engineer: D1 full grid, D2 port exactly, D3 keep the old print as a button** (the recommended option each time, matching cr125288 and cr125292).

| # | Question | Recommended | Alternative |
|---|---|---|---|
| D1 | Grid style | **Full interactive report grid** plus a seeded print layout (the ticket's business value names filter/sort/group/export on screen; cr125288 D1, cr125292 D2) | Print-only, like 123252 IncomeStatement |
| D2 | Legacy quirks | **Port exactly** and report the quirks to the PO as separate Bugs (cr125288 D2) | Fix them in the port |
| D3 | Legacy print | **Keep it** as "Print (previous design)" on the form (ticket risk note; cr125288 D3) | Swap the route outright, as 123252 did |

## Quirks found so far (reproduced under D2)
- R1: income and expense lines show ABS. Net is in parentheses when ≥ 0 and plain when < 0. Net adds the *rounded* tax.
- R2/R3: other income, expenses and tax are report-wide, not per group. Sign rules differ between the cost-center and branch queries. Net is computed from values rounded to ApproximateNo. Rows with a NULL cost center or branch are dropped from the groups.
- R4/R6: branch and cost-center columns sort as text ("10" < "2"). The INNER JOIN drops lines with a NULL dimension.
- R5: the proc's per-branch production CTE ignores the branch filter. The total-quantity header shows in Arabic only.
- R7/R8: the type-total block's last-year column is always 0 (`LastYearPeriodCredit - LastYearPeriodCredit`), so Net Profit's last-year figure is 0. ABS drops signs. The previous-period label ends one day after the data window.
- R9: months are matched by number only, so a period across a year end returns nothing. Accounts with no IncomeStatment mapping are dropped. The Taxes query lacks the `number is not null` filter.
- Brief by cost center / by branch (routes 2, 3) are activity-style reports, not "brief" ones.

## Technical choices (agent, within D2)
- **R4–R6 names follow `@IsArabic`.** This covers main item, sub item, branch and cost center (legacy showed the primary name in both languages). The same call as cr125288 `CurrencyNameArabic`. Parity compares on ids and codes, not names.
- **R4/R6 codes.** `BranchCode` / `CostCenterNo` carry the full code. `*SortKey` holds the legacy `CAST(code AS NVARCHAR(10))` used for the text sort and for parity.
- **R5 FLOAT columns** (quantity, AvgCost) are kept as in the legacy proc. Parity compares them rounded to 6/9 dp. A production quantity of exactly 0 raises a divide-by-zero error, as in the legacy.
- **NULL / empty lists mean "all"** in every TVF. Some legacy adapters had non-nullable params and crashed on an empty filter; that crash is not reproduced.
- **Print money is `{0:N2}`, not `n<ApproximateNo>`** (review-1 row 4). This is an accepted deviation from the legacy print. The shipped sibling `0404_IncomeStatementReportLayout.sql` (123252) has 10 `{0:N2}` and cr125288's `0430` has 36, and neither reads `ApproximateNo`. The grid and the data keep full precision. Name it in the PR.
- **EF configs use `HasNoKey()` without `ToFunction`** (review-1 row 7), which bends `report-backend.md` Artifact 2. The GL siblings fx123513 and cr125288 do the same, and the data loads through `FromSqlInterpolated` + `[EnableQuery]`. Name it in the PR.

## Parity verdicts (P5, 2026-10-15, parity-125289.md)
- R1–R7 and R9 match exactly: 13 param sets on 4 tenants. R8 matches after its percentage columns were set to NULL (the legacy cells were bound to ActivityIncome and print blank).
- **R7/R8 Net Profit = `Calculate*`.** DevExpress 19.1.3 counts rows cancelled in BeforePrint in a report Sum (probe), and the data confirms it on 26 runs. The `PrintedOnly*` columns are dead and are to be removed in the review/cleanup round (TVFs R7/R8, 2 entities, 2 shells, i18n).
- Percentage = group sum ÷ report sum, signed. R2/R7 match; R3/R8 print blank, as in the legacy.
- R9 merges same-name sub items as the legacy pivot did (the print, not the raw SQL).
