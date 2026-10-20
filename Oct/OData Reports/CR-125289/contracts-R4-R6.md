# CR-125289 - TVF contracts R4-R6 (phase P1b)

Files (cr125289 set, `AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Functions\`), not yet in the sqlproj:
- `Acc_IncomeStatementByBranchReport.sql` (R4)
- `Acc_IncomeStatementByBranchProductionReport.sql` (R5, UTF-8 with BOM: it holds the Arabic total-column literal)
- `Acc_IncomeStatementByCostCenterReport.sql` (R6)

All three are inline TVFs in long format: one row per MainItem x SubItem x dimension, the cells the legacy XRPivotGrid summed.
Types were read from `tempdb.sys.columns` after running each body on db-all / Test_Primary. Every C# property is nullable except `RowNo`.

Shared rules (D2, exact port):
- An empty string in a list param counts as NULL (`NULLIF(x,'')`), like MVC's empty-string-to-null binding.
- Rows are grouped on the legacy keys: sub item **name** + OrderInReport + main item, not the sub item id. `SubItemId` is `MIN(IncomeStatmentSubItemId)` of the merged sub items.
- The INNER JOIN on the dimension table drops lines with a NULL branch or cost center, and sub items with no postings. Zero balances are kept.
- `Balance` = SUM(credit) - SUM(debit). The sign is not flipped. The print grand total is the "الفائض / العجز" line.
- `MainItemName` follows `@IsArabic`: Arabic, falling back to MainItemName. The legacy always showed MainItemNameArabic.
- Dimension names follow `@IsArabic`: `*NameSecondLanguage` when not Arabic, falling back to the name. The legacy always showed the primary name.
- `SortOrder` = `MainItemId*1000 + 10 + ISNULL(OrderInReport,0)` (the row-axis order; same formula as Acc_IncomeStatementReport).
- `*SortKey` = the legacy `CAST(code AS NVARCHAR(10))`. The pivot sorted the columns by it as text ("10" < "2"). It is truncated to 10 characters, as in the legacy. **Parity compares the legacy `BranchCode`/`CostCenterNo` with `*SortKey`.**
- `RowNo` = `ROW_NUMBER() OVER (ORDER BY MainItemId, OrderInReport, SubItemId, <SortKey>)`.

## R4 `dbo.Acc_IncomeStatementByBranchReport`

```sql
(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL,
 @JournalTypeList NVARCHAR(MAX) = NULL, @BranchList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
```

| # | Column | SQL | C# |
|---|---|---|---|
| 1 | RowNo | BIGINT | long |
| 2 | SortOrder | INT | int? |
| 3 | MainItemId | INT | int? |
| 4 | MainItemName | NVARCHAR(100) | string? |
| 5 | SubItemId | INT | int? |
| 6 | SubItemName | NVARCHAR(500) | string? |
| 7 | OrderInReport | INT | int? |
| 8 | BranchId | INT | int? |
| 9 | BranchCode | NVARCHAR(50) (full code) | string? |
| 10 | BranchName | NVARCHAR(500) | string? |
| 11 | BranchSortKey | NVARCHAR(10) | string? |
| 12 | PeriodCredit | MONEY | decimal? |
| 13 | PeriodDebit | MONEY | decimal? |
| 14 | Balance | MONEY | decimal? |

Print: XRCrossTab with rows MainItemName (sorted by MainItemId) > SubItemName (by OrderInReport), columns BranchName (by BranchSortKey, text), and data Sum(Balance). Grand totals go on both axes.

## R5 `dbo.Acc_IncomeStatementByBranchProductionReport`

Same params as R4. Columns 1-14 are as R4, then:

| # | Column | SQL | C# |
|---|---|---|---|
| 15 | TotalProductionQuantity | FLOAT | double? |
| 16 | AvgCost | FLOAT | double? |
| 17 | TotalQty | FLOAT | double? |

- This is the proc `Acc_IncomeStatmentWithBranchProd`'s UNION ALL inlined, with the dead `INSERT @ResultTbl` dropped and the `Acc_GetAccountActionsBetweenDatesByBranchs` call shared through one CTE.
- Synthetic total-produced-quantity rows:
  - `BranchId` NULL, `BranchCode` = `BranchSortKey` = `'2147483647'`.
  - `BranchName` = `N'إجمالى الكمية المنتجة'` when `@IsArabic=1`, otherwise `N'Total Produced Quantity'` (the English label is new).
  - Balance covers all branches, including lines with a NULL branch, and only `<> 0` rows are kept.
  - The quantity is filtered by the branch list.
- Per-branch rows: `TotalProductionQuantity` = the branch's produced qty, and it **ignores @BranchList** (legacy). `AvgCost` = `ISNULL(Balance / qty, 0)`.
- `TotalQty` = the TotalProductionQty adapter (branch-filtered produced qty, 0 if none). It carries the same value on every row and feeds the Arabic grand-total caption `إجمالى الكمية المنتجة \r\n {TotalQty}`.
- The types stay FLOAT because the quantity column is FLOAT and the xsd declared them as double. The legacy formatted them N2.
- Print: column grand totals off. The data fields are Sum(Balance) and Sum(AvgCost), with TotalProductionQuantity as a column sub-header.

## R6 `dbo.Acc_IncomeStatementByCostCenterReport`

```sql
(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT = NULL,
 @JournalTypeList NVARCHAR(MAX) = NULL, @CostCenterList NVARCHAR(MAX) = NULL, @IsArabic BIT = 0)
```

Columns 1-7 are as R4, then:

| # | Column | SQL | C# |
|---|---|---|---|
| 8 | CostCenterId | INT | int? |
| 9 | CostCenterNo | NVARCHAR(20) (full no) | string? |
| 10 | CostCenterName | NVARCHAR(300) | string? |
| 11 | CostCenterSortKey | NVARCHAR(10) | string? |
| 12 | PeriodCredit | MONEY | decimal? |
| 13 | PeriodDebit | MONEY | decimal? |
| 14 | Balance | MONEY | decimal? |

## Verification (2026-10-15, db-all / Test_Primary, read-only, temp tables only)

The legacy SQL ran verbatim (R5 through `EXEC` of the deployed proc plus the TotalProductionQty query), against the TVF bodies with the same params, compared with EXCEPT both ways:

| Set | Params | R4 rows | R5 rows | R6 rows | EXCEPT both ways |
|---|---|---|---|---|---|
| A | 2025 full year, all NULL | 1 / 1 | 2 / 2 | 65 / 65 | 0 / 0 |
| B | 2023-2026, revised=0, branches 1,2, cost centers 24,5,18,13,9 | 1 / 1 | 2 / 2 | 5 / 5 | 0 / 0 |
| C | 2024, types 5,13,20,21,36, branch 1 | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |

- The balance sums are equal in every set.
- R5 floats: TotalProductionQuantity and AvgCost differ only in the last bits (for example 3777326.6781999962 vs ...82000083), because float SUM order is nondeterministic. They are compared at ROUND 6 / 9.
- `SET PARSEONLY` passes on all three CREATE FUNCTION files.
- Test_Primary has only 2 branches and little income-statement mapping, so P5 should rerun this on a richer tenant.
