# CR-125289 — contracts R7–R9 (P1c)

Written 2026-10-15. Column types below are from `sp_describe_first_result_set` on each body (db-all, `dbriyadh_Primary`), not guessed. Files in `D:\Hadaf\worktrees\cr125289\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Functions\`, UTF-8 with BOM, CRLF. Not yet in the sqlproj (orchestrator registers them).

Every list param: NULL or `''` = no filter (the TVFs `NULLIF(..., '')` them). Dates: from 00:00:00, to 23:59:59.997, as in the legacy rpt.

## R7 `dbo.Acc_IncomeStatementCostCenterPeriodReport` / R8 `dbo.Acc_IncomeStatementBranchPeriodReport`

```sql
dbo.Acc_IncomeStatementCostCenterPeriodReport(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL, @JournalTypeList NVARCHAR(MAX) = NULL, @CostCenterList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
dbo.Acc_IncomeStatementBranchPeriodReport    (@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL, @JournalTypeList NVARCHAR(MAX) = NULL, @BranchList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
```

The two have the same columns, so one C# entity shape fits both (two classes or one base class).

| # | Column | SQL | C# |
|---|---|---|---|
| 1 | RowNo | bigint | `long` |
| 2 | SortOrder | bigint | `long?` |
| 3 | Section | nvarchar(30) | `string?` |
| 4 | GroupNo | nvarchar(50) | `string?` (R7 CostCenterNo, R8 BranchCode) |
| 5 | GroupName | nvarchar(500) | `string?` (R7 CostCenterName, R8 BranchName) |
| 6 | AccountTypeId | int | `int?` |
| 7 | AccountTypeName | nvarchar(50) | `string?` (Arabic name when @IsArabic = 1) |
| 8–10 | PeriodBalance, LastPeriodBalance, YearToPeriodBalance | decimal(19,4) | `decimal?` |
| 11–13 | CalculatePeriodBalance, CalculateLastPeriodBalance, CalculateYearToPeriodBalance | decimal(19,4) | `decimal?` |
| 14–16 | PeriodPercentage, LastPeriodPercentage, YearToPeriodPercentage | decimal(38,12) | `decimal?` (a fraction, legacy format `{0:0%}`) |
| 17–19 | PrintedOnlyPeriodBalance, PrintedOnlyLastPeriodBalance, PrintedOnlyYearToPeriodBalance | decimal(19,4) | `decimal?` |
| 20–21 | PeriodFrom, PeriodTo | datetime | `DateTime?` |
| 22–23 | LastPeriodFrom, LastPeriodTo | datetime | `DateTime?` (the legacy C# label, one day after the data window) |
| 24–25 | LastYearFrom, LastYearTo | datetime | `DateTime?` |

Section values, in print order:

| Section | Rows | Filled columns | SortOrder |
|---|---|---|---|
| `Group` | one per group × account type 1, 2 (only types with data) | Group*, AccountType*, the 3 balances (ABS), Calculate* (type 2 negated) | GroupIndex × 10 + AccountTypeId |
| `GroupTotal` | one per group ("GOP") | GroupNo, GroupName, Calculate* (sum), *Percentage (group ABS sum / report ABS sum) | GroupIndex × 10 + 9 |
| `ReportTotal` | one ("Total GOP"), only when there are groups | Calculate* | 2000000000 |
| `TypeTotal` | one per nature-1 type except 1, 2 (3, 4, 5, 13, 17) | AccountType*, the 3 balances, Calculate* (2, 4, 5, 13 negated) | 2000000000 + AccountTypeId |
| `NetProfit` | one | Calculate* = all nature-1 types incl. 1, 2; PrintedOnly* = without 1, 2 | 2100000000 |

GroupIndex = `DENSE_RANK()` over GroupNo (SQL collation order, codes as text). Sort: `RowNo` (= ORDER BY SortOrder, GroupName). The date columns repeat on every row.

Known values (reproduced under D2): YearToPeriodBalance of TypeTotal and the year column of NetProfit are always 0 (legacy `LastYearPeriodCredit - LastYearPeriodCredit`). Lines with no cost center (R7) / branch (R8) count in TypeTotal and NetProfit but not in the groups.

## R9 `dbo.Acc_IncomeStatementPerPeriodReport`

```sql
dbo.Acc_IncomeStatementPerPeriodReport(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL, @JournalTypeList NVARCHAR(MAX) = NULL, @CostCenterList NVARCHAR(MAX) = NULL, @BranchList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
```

| # | Column | SQL | C# |
|---|---|---|---|
| 1 | RowNo | bigint | `long` |
| 2 | SortOrder | int (not null) | `int?` |
| 3 | RowType | nvarchar(30) | `string?` |
| 4 | MainItemId | int | `int?` (1–6; NULL on computed rows) |
| 5 | MainItemName | nvarchar(100) | `string?` (MainItemNameArabic when @IsArabic = 1; NULL on computed rows) |
| 6 | SubItemName | nvarchar(500) | `string?` (not localised, as legacy; NULL on computed rows) |
| 7 | Mnth | int | `int?` (1–12) |
| 8 | MonthName | nvarchar(30) | `string?` (`DATENAME(MONTH, ...)`, session language) |
| 9 | MonthNameArabic | nvarchar(30) | `string?` (legacy literals, trailing space kept) |
| 10 | Balance | decimal(19,4) | `decimal?` |

RowType values:

| RowType | SortOrder | Rows | Balance |
|---|---|---|---|
| `Item` | MainItemId (1–6) | one per main item × SubItemName × month with activity | credit − debit for 1, 3, 6; debit − credit for 2, 4, 5 |
| `GrossProfit` | 7 | one per month present in the Item rows | 1 − 2 |
| `NetProfitBeforeTax` | 8 | same months | 1 − 2 − 5 + 3 − 4 |
| `NetProfit` | 9 | same months | NetProfitBeforeTax + 6 |

The computed rows have no MainItemName; the front and the layout label them from RowType ("Total Profit", "Net Profit Before Tax", "Net Profit" in the legacy English layout). Summed over the months, they equal the legacy C# totals. Legacy hid each total when it was exactly 0; that hiding is a layout concern.

Sort: `RowNo` (= ORDER BY SortOrder, SubItemName, Mnth). Sub items are in name order, as the legacy pivot showed them (default value sort), not `OrderInReport`.

Quirks kept (D2): only months `MONTH(from)..MONTH(to)` are included and lines match on the month number only, so a period across a year end returns no rows. Accounts with a NULL `IncomeStatment` are dropped. Taxes (main item 6) sub items with no activity come back once with Mnth NULL and Balance 0. Rows are keyed by SubItemName text, so equal names merge, as the pivot did; the legacy SQL split them by OrderInReport, and the totals are the same.

## Verified (db-all, `dbriyadh_Primary`, read-only, no object created)
- `SET PARSEONLY ON` on each full `CREATE FUNCTION`: all 3 parse.
- Each body run ad hoc with declared variables. Set 1: 2025-01-01..2025-06-30, all lists NULL, EN. Set 2: March 2025, revised = 1, journalTypes `''`, cost centers 49,55, branch 2, AR. Both sets run without error.
- Set 1 against the verbatim legacy SQL:
  - R7 vs ActivityIncome: 73 rows, the 6 sums equal, same order.
  - R8 vs BranchIncome and Acc_IncomeStatment: every value equal.
  - R9 vs the six FillByPeriod adapters: row counts and SubItemBalance sums equal per main item, including the Taxes NULL-month row.
  - The R9 per-month NetProfitBeforeTax sums to 15,764,195.8209, the legacy formula's total.
- Not done: the full EXCEPT parity (P5), the MSBuild gate (needs the sqlproj entries), and an Arabic run of R9 with data in more than one month.

## Open for P5 / P6
- NetProfit: whether the XRSummary counted the cancelled type 1, 2 rows (Calculate*) or not (PrintedOnly*). This must be checked on a real legacy print.
- *Percentage: DevExpress `Percentage` with `Running=Report` in a group footer is assumed to be group sum / report sum. Check it against a legacy print.
- Group order: SQL collation here vs the .NET string compare in the DevExpress group sort. They can differ only on codes with punctuation or mixed case.
