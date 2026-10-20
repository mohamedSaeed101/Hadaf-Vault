# CR-125289: contracts R1–R3 (TVFs, phase P1a)

Files: `AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Functions\`
`Acc_BriefIncomeStatementReport.sql`, `Acc_CostCenterBriefIncomeStatementReport.sql`, `Acc_BranchBriefIncomeStatementReport.sql`
(not registered in the sqlproj yet; not committed). Legacy source: [[Legacy - Brief Income Statement]]. Decision D2 (exact port).

Common to all three:
- Inline TVFs; `RowNo` = `ROW_NUMBER() OVER (ORDER BY SortOrder)`, and `SortOrder` is unique, so the order is stable.
- Money columns are `DECIMAL(19,4)` and C# `decimal?`, raw and unrounded. The only rounding is where the legacy
  re-parsed formatted text mid-formula, to `ApproximateNo` = `ISNULL((SELECT TOP (1) ApproximateNo FROM dbo.Acc_SystemConfiguration), 0)`
  (the same query as legacy `ApiLoggedUser.GetApproximateNo`; SQL `ROUND` rounds half away from zero, like .NET decimal formatting).
- Display formats belong to the layout (P4): legacy brief = `n<ApproximateNo>`; R2/R3 SubItemBalance / GOP / Total GOP use `n2` in the
  Designer, but `moneyApproximate1` overrides them to `n<ApproximateNo>`; the percentage format is `0%`.
- All three compose over `dbo.Acc_GetAccountJournalActionsBetweenDates` (repo body == the body deployed on db-all Test_Primary).
  The legacy MVC reports ran against that same tenant DB function, so there is no semantic drift (local currency, `ja.Revised`, `j.CreatedDate`).

## R1 `dbo.Acc_BriefIncomeStatementReport`

```sql
dbo.Acc_BriefIncomeStatementReport(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL,
    @JournalTypeList NVARCHAR(MAX) = NULL, @CostCenterList NVARCHAR(MAX) = NULL, @BranchList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
```

| # | Column | SQL | C# |
|---|---|---|---|
| 1 | RowNo | BIGINT | long |
| 2 | SortOrder | INT | int? |
| 3 | RowType | NVARCHAR(30) | string |
| 4 | Description | NVARCHAR(100) | string |
| 5 | Partial | DECIMAL(19,4) | decimal? |
| 6 | Total | DECIMAL(19,4) | decimal? |
| 7 | SignedValue | DECIMAL(19,4) | decimal? |
| 8 | IsNegativeShownInParens | BIT | bool? |

There are always 9 rows, `SortOrder` 1–9 in legacy print order. D(t) = PeriodDebit − PeriodCredit of account type t (query A, leaf accounts, all types, no nature filter).

| SortOrder | RowType | Partial | Total | SignedValue | Parens flag |
|---|---|---|---|---|---|
| 1 | OperatingIncome | ABS(D1) | NULL | D1 | 0 |
| 2 | OperatingExpenses | ABS(D2) | NULL | D2 | 0 |
| 3 | GrossProfit | NULL | ABS(GP) | GP = D1 + D2 | 0 |
| 4 | OtherIncome | ABS(D3) | NULL | D3 | 0 |
| 5 | GeneralExpenses | ABS(D4) | NULL | D4 | 0 |
| 6 | OtherExpenses | ABS(D5) | NULL | D5 | 0 |
| 7 | NetProfitBeforeTax | NULL | ABS(NPBT) | NPBT = GP + D3 + D5 + D4 | 1 when NPBT >= 0 |
| 8 | Taxes | ABS(D13) | NULL | D13 | 0 |
| 9 | NetProfit | NULL | ABS(NP) | NP = NPBT + ROUND(ABS(D13), ApproximateNo) | 1 when NP >= 0 |

`IsNegativeShownInParens` = 1 means "print Total in parentheses" (legacy: parens when >= 0, which is a loss in debit−credit terms; zero prints "(0.000)").
Description follows `@IsArabic`, with the legacy localizer texts (row 7 merges the "Net Profit" and "( Before Taxes )" cells).

## R2 `dbo.Acc_CostCenterBriefIncomeStatementReport`

```sql
dbo.Acc_CostCenterBriefIncomeStatementReport(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL,
    @JournalTypeList NVARCHAR(MAX) = NULL, @CostCenterList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
```

## R3 `dbo.Acc_BranchBriefIncomeStatementReport`

```sql
dbo.Acc_BranchBriefIncomeStatementReport(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL,
    @JournalTypeList NVARCHAR(MAX) = NULL, @BranchList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
```

R2 and R3 have the same columns:

| # | Column | SQL | C# | Filled on |
|---|---|---|---|---|
| 1 | RowNo | BIGINT | long | all |
| 2 | SortOrder | INT | int? | all |
| 3 | RowType | NVARCHAR(30) | string | all |
| 4 | GroupId | INT | int? | Detail, GroupTotal (CostCenterId / BranchId) |
| 5 | GroupNo | NVARCHAR(50) | string | Detail, GroupTotal (CostCenterNo / BranchCode) |
| 6 | GroupName | NVARCHAR(500) | string | Detail, GroupTotal (CostCenterName / BranchName; no language switch, as legacy) |
| 7 | AccountTypeId | INT | int? | Detail (1 or 2) |
| 8 | AccountTypeName | NVARCHAR(50) | string | Detail (`AccountTypeNameArabic` when @IsArabic = 1, no fallback, as legacy) |
| 9 | Description | NVARCHAR(100) | string | non-Detail rows (label by @IsArabic) |
| 10 | SubItemBalance | DECIMAL(19,4) | decimal? | Detail ("Partial Balance" column) |
| 11 | CalSubItemBalance | DECIMAL(19,4) | decimal? | Detail (feeds the GOP sums; not printed) |
| 12 | Partial | DECIMAL(19,4) | decimal? | OtherIncome, GeneralExpenses, OtherExpenses, Taxes |
| 13 | Total | DECIMAL(19,4) | decimal? | GroupTotal, ReportTotal, NetProfitBeforeTax, NetProfit |
| 14 | PercentageOfReport | DECIMAL(19,10) | decimal? | R2 GroupTotal only (fraction: 0.17 = 17%); always NULL in R3 |

RowType values and sort:

| RowType | SortOrder | Values |
|---|---|---|
| Detail | GroupSeq*10 + k | R2: k = AccountTypeId (legacy Detail sort AccountTypeId asc). R3: k = 1,2 by SubItemBalance DESC, then AccountTypeId (legacy Detail sort SubItemBalance desc) |
| GroupTotal | GroupSeq*10 + 9 | Total = SUM(CalSubItemBalance) in group ("GOP"); R2 PercentageOfReport = SUM(group SubItemBalance) / SUM(report SubItemBalance), NULL when the denominator is 0 |
| ReportTotal | 2000000000 | Total = SUM(CalSubItemBalance) over all groups ("Total Activity GOP" / "Total Branch GOP") |
| OtherIncome | 2000000001 | Partial: R2 ABS(C3−D3); R3 ABS(C3−D3) |
| GeneralExpenses | 2000000002 | Partial = D4 (signed, no ABS) |
| OtherExpenses | 2000000003 | Partial = D5 (signed, no ABS) |
| NetProfitBeforeTax | 2000000004 | R2: TotalGOP + ROUND(ABS(C3−D3)) − ROUND(D5) − ROUND(D4). R3: TotalGOP + (C3−D3) raw signed − ROUND(D5) − ROUND(D4) |
| Taxes | 2000000005 | Partial = ABS(D13) |
| NetProfit | 2000000006 | NPBT − ROUND(ABS(D13)) |

GroupSeq = DENSE_RANK over (CostCenterNo, CostCenterId) / (BranchCode, BranchId): text order, as the legacy GroupField sorted.
ROUND is to ApproximateNo. C/D here are query B (types with AccountTypeNature = 1, leaf accounts). R2 passes @CostCenterList with no branch filter; R3 passes no cost-center filter and `NULLIF(@BranchList,'')`.
Detail = query C (R2) or query D (R3): only types 1 and 2; journal lines with a NULL cost center or branch are dropped.
- R2: SubItemBalance = D for type 2, else ABS(D); CalSubItemBalance = −D for type 2, else ABS(D).
- R3: SubItemBalance = D for type 2, else C−D; CalSubItemBalance = C−D for both types.

With no Detail rows, the ReportTotal and report-wide rows are still returned, with NULL values: the legacy filled those cells only in GroupHeader1.BeforePrint.

## Empty-string lists (quirk 9)
- R1 and R2 pass the lists through untouched. `Acc_ConvertIntListToTable('')` returns id 0, so '' gives no journal rows, as on the legacy brief and cost-center routes. The backend sends NULL for an empty value anyway.
- R3 applies `NULLIF(@BranchList,'')` (the legacy branch route mapped '' to null).

## Verified
- All three bodies were executed read-only (as DECLARE + SELECT, no DDL) on db-all `Test_Primary` (ApproximateNo 6):
  2025 full year (EN, lists NULL) and Q1 2025 (AR, revised = 1, lists ''). They return the shapes above. NPBT and Net were hand-checked against the formulas.
- The legacy dataset's PK on `ActivityIncome.CostCenterId` does NOT merge type 1/2 rows (EnforceConstraints = false before Fill; tested with SqlDataAdapter).
- No MSBuild yet: the files are not in the sqlproj (the orchestrator registers them).

## Open risks
- DevExpress `Percentage` summary with `Running = Report` placed in a group footer: assumed group share of the report total. Confirm against the legacy print in P5/P6.
- Legacy throws (`FindByAccountTypeId` null) when type 3/4/5/13 lacks `AccountTypeNature = 1` (R2/R3) or is missing (R1); the TVF yields 0. Test_Primary has nature 1 on all of them.
- Group order: SQL collation vs the DevExpress culture string sort of CostCenterNo / BranchCode can differ on unusual codes. One NULL CostCenterNo is allowed; it sorts first in both.
- Culture re-parse (`Convert.ToDecimal` of `n<approx>` text) is assumed to round-trip under ar-EG and en-US.
