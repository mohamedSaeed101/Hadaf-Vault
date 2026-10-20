# Legacy dissection - Income Statement Branch / Branch Production / Cost Center (CR 125289)

Source: `D:\Hadaf\AccFlex_ERP` (`git diff --stat origin/Master_Stable` is empty for FinancialReportsController.cs and the Reports\IncomeStatmentBranchs + IncomeStatmentCostCenter folders, so cr94062 equals Master_Stable for these files).
Cloud DB checked: `D:\Hadaf\worktrees\cr125289\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State` (`dbo\...`, sqlproj `<Build Include>`).
Not in scope: `income-statment-report` -> IncomeStatement (CR 123252).

## 0. Shared facts (all three reports)

- Controller: `AccFlexContainer\AccFlexContainer.MVC\Controllers\GeneralLedgerReports\FinancialReportsController.cs` lines 76-105. Each action: `ChangeThreadCulture(lang); new rptXxx(...); return View(REPORTS_ROOT_VIEW, report)`.
- Report classes: `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\IncomeStatmentBranchs\` (rptIncomeStatemetBranchs, rptIncomeStatemetBranchsProduction, dsIncomeStatement.xsd, dsIncomeStatmentWithBranchProduction.xsd) and `...\IncomeStatmentCostCenter\` (rptIncomeStatemetCostCenter, dsIncomeStatmentCostCenter.xsd).
- Ctor date handling (all 3): `_fromDate = Y/M/D 00:00:00`; `_toDate = Y/M/D 23:59:59.997`. Header texts dd/MM/yyyy.
- `lblRevised`: revised null -> "Both Journals Revised & NOT Revised" / "كلا الحسابات المراجعه و غير المراجعه"; true -> "All Journals Revised" / "الحسابات المراجعه فقط"; false -> "All Journals NOT Revised" / "الحسابات الغير المراجعه فقط" (Production: "...الغير مراجعه فقط"; CostCenter: "الحسابات الغير مراجعه").
- Ctor applies `localizer1.ApplyArabic()` (+ `pivotLocalizer1` in Production/CostCenter) and `moneyApproximate1.ApplyApproximate(ApiLoggedUser.GetApproximateNo())` (tenant ApproximateNo decimals on money cells; Branch/CostCenter cell format = Numeric without FormatString, Production = "N2").
- `Acc_SystemConfiguration` adapter: `SELECT Acc_SystemConfiguration.* FROM Acc_SystemConfiguration` (company header/logo only).
- All three are DevExpress XRPivotGrid cross-tabs. No per-row C# arithmetic; every subtotal / grand total is a pivot Sum.
- Angular: branch form fields `fromDate,toDate,revised(null|true|false),journalTypes,branchesIds`; cost-center form `fromDate,toDate,revised(default ''),journalTypes,costCenterIds (required)`. Dates sent `yyyy-MM-dd`. Iframe URL = `${printUrl}FinancialReports/<report>?lang=<lang>&<serialized form>` (`financial-reports\shared\financial-reports-data.service.ts:63`).
- Angular routes: `AccFlex_Cloud_Front\accflex-erp\projects\general-accounting\src\app\modules\financial-reports\financial-reports.module.ts` lines 103-119; menu items with the `report` param: `projects\general-accounting\src\app\core\routes.ts` lines 778-796 (ModuleId 72).

## 1. Report 4 - IncomeStatemetBranchs

### Route and params
- Route `financial-reports/income-statment-branche-report`, query `?report=IncomeStatemetBranchs`, component `BrifIncomeStatmentBrancheReportShellComponent`. Shell submits `report || 'BranchIncomeStatement'`.
### MVC action
`GET mvc/FinancialReports/IncomeStatemetBranchs(string lang, DateTime fromDate, DateTime toDate, bool? revised, string journalTypes, string branchesIds)` -> `new rptIncomeStatemetBranchs(fromDate,toDate,revised,journalTypes,branchesIds)`.
### BeforePrint
RTL if Arabic; ConnectionString = ApiLoggedUser.ConnectionString; Fill SystemConfiguration; `acc_IncomeStatmentTableAdapter.Fill(ds.Acc_IncomeStatment, _fromDate, _toDate, revised, journalTypes, branches)`; set lblRevised. No other C# computation. (revised/journalTypes/branches are `static` fields.)
### Pivot (xrPivotGrid1, DataMember Acc_IncomeStatment)
- Rows: MainItemNameArabic (idx0, GrandTotalText "اجمالى القيمه"), SubItemName (idx1).
- Columns: BranchName (GrandTotalText "الفائض / العجز"); hidden helper column fields OrderInReport, MainItemId, BranchCode.
- Data: SubItemBalance = Sum (Numeric, ApproximateNo). Column/data/row headers hidden. Landscape.
- CustomFieldSort: MainItemNameArabic by MainItemId asc; SubItemName by OrderInReport asc; BranchName by BranchCode asc (BranchCode is CAST to NVARCHAR(10), so comparison is STRING: "10" < "2").
- FieldValueDisplayText (Arabic only): GrandTotal column -> "اجمالى القيمه"; GrandTotal row -> "الفائض / العجز".
- Grand totals on both axes (defaults).

### SQL - Acc_IncomeStatment TableAdapter (CommandType Text), VERBATIM
```sql
WITH AccountBalance(AccountId, ParentAccountId, PeriodCredit, PeriodDebit,BranchId) AS 
(SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,Balance.BranchId
    FROM      Acc_Account LEFT OUTER JOIN
                            (SELECT AccountId ,PeriodCredit, PeriodDebit,BranchId
                            FROM      dbo.Acc_GetAccountActionsBetweenDatesByBranchs(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
                                                @JournalTypeList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
                        Acc_Account.AccountId = Balance.AccountId
   
    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId,Balance.BranchId)
    SELECT 
	
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS SubItemBalance, 
					  Acc_IncomeStatmentSubItem.SubItemName,Acc_IncomeStatmentMainItem.MainItemNameArabic,BranchName, Acc_IncomeStatmentMainItem.MainItemId,
            CAST(BranchCode AS NVARCHAR(10)) AS BranchCode, Acc_IncomeStatmentSubItem.OrderInReport
    FROM    Acc_IncomeStatmentMainItem INNER JOIN
            Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
            AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
            Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
			inner join Acc_Branch on Acc_Branch.BranchId = AccountBalance_1.BranchId
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport,BranchName,BranchCode
    ORDER BY Acc_IncomeStatmentMainItem.MainItemId
```
Parameters (name, DbType): @FromBalanceDate DateTime; @ToBalanceDate DateTime; @JournalRevise Boolean (nullable); @JournalTypeList String size 1024 (nullable); @BranchList String size 1024 (nullable).
Fill args (_fromDate,_toDate,revised,journalTypes,branches) map to these in order.

### Dependencies and cloud existence (all present and registered in sqlproj)
| Object | Cloud file | In sqlproj |
|---|---|---|
| dbo.Acc_GetAccountActionsBetweenDatesByBranchs (TVF) | dbo\Functions\Acc_GetAccountActionsBetweenDatesByBranchs.sql | yes |
| dbo.Acc_ConvertIntListToTable (TVF, used inside) | dbo\Functions\Acc_ConvertIntListToTable.sql | yes |
| Acc_Account, Acc_Branch, Acc_IncomeStatmentMainItem, Acc_IncomeStatmentSubItem, Acc_SystemConfiguration | dbo\Tables\*.sql | yes |
| Acc_JournalAction, Acc_Journal (inside the TVF) | dbo\Tables | not individually re-checked (core tables) |

Branchs TVF body (cloud): journal actions joined to Acc_Journal where `Acc_Journal.CreatedDate` between from and to inclusive (so the .997 to-date matters), `Acc_JournalAction.Void = 0`, `(@JournalRevise IS NULL OR Revised=@JournalRevise)`, journal type IN list if given, branch IN list if given; returns AccountId, CostCenterId, PeriodCredit=ISNULL(CreditLocal,0), PeriodDebit=ISNULL(DebitLocal,0), BranchId. Branch filter is on `Acc_JournalAction.BranchId`.

### Layout structure
Landscape; bands TopMargin, ReportHeader (company data, title, date from/to, lblRevised, splitter), PageHeader, GroupHeader1, Detail (the pivot), PageFooter, BottomMargin. Cross-tab: branches across, main item > sub item down, one data cell (Sum SubItemBalance), grand totals.

### Quirks to reproduce
1. `SubItemBalance = SUM(credit) - SUM(debit)`: income positive, expenses negative. No sign flip and no gross/net profit formula in C#; "profit" = pivot grand total over all main items (Arabic label "الفائض / العجز").
2. `INNER JOIN Acc_Branch ON Acc_Branch.BranchId = AccountBalance_1.BranchId` is applied after the outer joins: sub items with no postings (or lines with NULL branch) vanish; zero-activity items are NOT shown as 0.
3. Only accounts whose `Acc_Account.IncomeStatment` equals a sub item count; ParentAccountId is selected but unused (no hierarchy roll-up).
4. SQL ORDER BY MainItemId, but the pivot re-sorts: main item by MainItemId, sub item by OrderInReport, branch by BranchCode as TEXT.
5. Row hierarchy MainItem > SubItem, so identical SubItemName under two main items stays separate.
6. Zero balances are emitted (no HAVING) in the per-branch select.
7. NULL list = no filter; empty string is NOT null: the TVF then runs `IN (SELECT number FROM Acc_ConvertIntListToTable(''))`. Check what the Angular check-lists send when nothing is selected before assuming "all".

## 2. Report 5 - IncomeStatemetBranchsProduction

### Route and params
- Route `financial-reports/income-statment-branche-report-production`, query `?report=IncomeStatemetBranchsProduction`, SAME shell and form components as report 4 (only the label flag `isProductionReport` differs). Same query params (`branchesIds`).
### MVC action
`GET mvc/FinancialReports/IncomeStatemetBranchsProduction(lang, fromDate, toDate, bool? revised, string journalTypes, string branchesIds)` -> `new rptIncomeStatemetBranchsProduction(...)`.
### BeforePrint
1. Fill SystemConfiguration. 2. `Acc_IncomeStatmentWithBranchProductionTableAdapter.Fill(ds.Acc_IncomeStatmentWithBranchProduction, _fromDate,_toDate,revised,journalTypes,branches)` = stored procedure `dbo.Acc_IncomeStatmentWithBranchProd`. 3. `totalProductionQtyTableAdapter1.Fill(ds.TotalProductionQty, _fromDate,_toDate,branches)`. 4. `totalQty = Convert.ToDecimal(dt.Compute("Sum(TotalProductionQuantity)", ""))` when rows exist, else 0. 5. lblRevised.
### FieldValueDisplayText (Arabic only, GrandTotal value type)
Inside `if (e.ValueType == GrandTotal)`: `e.Field == null` -> `string.Format("إجمالى الكمية المنتجة \r\n {0}", totalQty)` (total produced qty from the separate TotalProductionQty query, not from the proc); else `Convert.ToString(e.DataField) == "متوسط"` -> "اجمالى المتوسط"; `== "إجمالى"` -> "اجمالى القيمة"; other cases set nothing. Re-read lines 92-120 of rptIncomeStatemetBranchsProduction.cs when porting captions.
### Pivot (DataMember Acc_IncomeStatmentWithBranchProduction)
Same as report 4 plus column field `TotalProductionQuantity` (colProductionQty, ColumnArea idx1, N2) and two data fields: `SubItemBalance` (Sum, N2) and `AvgCost` (Sum, N2, idx1). `ShowColumnGrandTotals=false`, `ShowColumnGrandTotalHeader=false`. Same three custom sorts.
### Shared with report 4
Same TVF, same CTE skeleton and params. Differences: SQL is a stored procedure, adds production qty and average cost columns, adds a synthetic total column.

### SQL 1 - TotalProductionQty TableAdapter (Text), VERBATIM
```sql
select sum(Inv_ProductionOrderDetails.Quantity) as TotalProductionQuantity ,BranchId
 from Inv_ProductionOrderDetails
inner join Inv_ProductionOrder on Inv_ProductionOrder.ProductionOrderId = Inv_ProductionOrderDetails.ProductionOrderId
inner join Inv_Warehouse on Inv_Warehouse.WarehouseID = Inv_ProductionOrder.DestinationWarehouseId
where Inv_ProductionOrder.IsFinalProductAdded = 1 
and Inv_ProductionOrderDetails.ProductionDate between @FromBalanceDate and @ToBalanceDate and
(( @BranchList IS NULL )
            OR ( Inv_Warehouse.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
group by Inv_Warehouse.BranchId
```
Params: @FromBalanceDate DateTime (nullable); @ToBalanceDate DateTime (nullable); @BranchList NVarChar, NOT nullable.

### SQL 2 - Acc_IncomeStatmentWithBranchProduction TableAdapter = StoredProcedure `dbo.Acc_IncomeStatmentWithBranchProd`
Params (DbType): @RETURN_VALUE Int; @startDate DateTime; @EndDate DateTime; @JournalRevise Bit (nullable); @JournalTypeList NVarChar(max) (nullable); @BranchList NVarChar(max) (nullable).
Body VERBATIM from the cloud DB project (`dbo\Stored Procedures\Acc_IncomeStatmentWithBranchProd.sql`). The legacy repo has no copy of the proc, so the cloud script is the only source; confirm it matches the tenant-DB proc before relying on it.
```sql
﻿-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Acc_IncomeStatmentWithBranchProd]
	-- Add the parameters for the stored procedure here
	@startDate DATETIME,
    @EndDate DATETIME,
	@JournalRevise bit,
	@JournalTypeList nvarchar(max),
	@BranchList nvarchar(max)
AS
BEGIN
	DECLARE @SubItemBalance DECIMAL;
	DECLARE @SubItemName nvarchar(max);
	declare @MainItemNameArabic nvarchar(max);
	declare @BranchName nvarchar(max);
	declare @MainItemId int ;
	declare @BranchCode nvarchar(max);
	declare @OrderInReport int;
	declare @TotalProductionQuantity decimal;
	declare @AvgCost decimal;

DECLARE @ResultTbl TABLE 
	(
	SubItemBalance DECIMAL,
	 SubItemName nvarchar(max),
	 MainItemNameArabic nvarchar(max),
	 BranchName nvarchar(max),
	 MainItemId int ,
	 BranchCode nvarchar(max),
	 OrderInReport int,
	 TotalProductionQuantity decimal,
	  AvgCost decimal
	 );


	SET NOCOUNT ON;
 DECLARE @_fromDate DATETIME;
        DECLARE @_toDate DATETIME; 
		DECLARE @_JournalRevise bit;
        DECLARE @_JournalTypeList nvarchar(max);
		DECLARE @_BranchList nvarchar(max);

		
        SET @_fromDate = @startDate;
        SET @_toDate = @EndDate;
        SET @_JournalRevise = @JournalRevise;
        SET @_JournalTypeList = @JournalTypeList;
		SET @_BranchList = @BranchList;


	with ProductionQty as 
   (select sum(Inv_ProductionOrderDetails.Quantity) as TotalProductionQuantity ,BranchId
 from Inv_ProductionOrderDetails
inner join Inv_ProductionOrder on Inv_ProductionOrder.ProductionOrderId = Inv_ProductionOrderDetails.ProductionOrderId
inner join Inv_Warehouse on Inv_Warehouse.WarehouseID = Inv_ProductionOrder.DestinationWarehouseId
where Inv_ProductionOrder.IsFinalProductAdded = 1 
and Inv_ProductionOrderDetails.ProductionDate between @startDate and @EndDate 

group by Inv_Warehouse.BranchId
 )
 , ProductionQtyWithOutBranch as 
   (select sum(Inv_ProductionOrderDetails.Quantity) as TotalProductionQuantity ,0 as branchid
 from Inv_ProductionOrderDetails
inner join Inv_ProductionOrder on Inv_ProductionOrder.ProductionOrderId = Inv_ProductionOrderDetails.ProductionOrderId
inner join Inv_Warehouse on Inv_Warehouse.WarehouseID = Inv_ProductionOrder.DestinationWarehouseId
where Inv_ProductionOrder.IsFinalProductAdded = 1 
and Inv_ProductionOrderDetails.ProductionDate between @startDate and @EndDate
 and
(( @BranchList IS NULL )
            OR ( Inv_Warehouse.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
)
, AccountBalance(AccountId, ParentAccountId, PeriodCredit, PeriodDebit,BranchId) AS 
(SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,Balance.BranchId
    FROM      Acc_Account LEFT OUTER JOIN
                            (SELECT AccountId ,PeriodCredit, PeriodDebit,BranchId
                            FROM      dbo.Acc_GetAccountActionsBetweenDatesByBranchs(@startDate, @EndDate, @JournalRevise, 
                                                @JournalTypeList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
                        Acc_Account.AccountId = Balance.AccountId
   
    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId,Balance.BranchId
	)
	,AccountBalanceWithoutBranch (AccountId, ParentAccountId, PeriodCredit, PeriodDebit,BranchId) AS 
(
SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,0 as BranchId
    FROM      Acc_Account LEFT OUTER JOIN
                            (SELECT AccountId ,PeriodCredit, PeriodDebit,BranchId
                            FROM      dbo.Acc_GetAccountActionsBetweenDatesByBranchs(@startDate, @EndDate, @JournalRevise, 
                                                @JournalTypeList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
                        Acc_Account.AccountId = Balance.AccountId
   
    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId
	)
	 SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS SubItemBalance, 
					  Acc_IncomeStatmentSubItem.SubItemName,Acc_IncomeStatmentMainItem.MainItemNameArabic,BranchName, Acc_IncomeStatmentMainItem.MainItemId,

            CAST(BranchCode AS NVARCHAR(10)) AS BranchCode, Acc_IncomeStatmentSubItem.OrderInReport
             , ISNULL (min(ProductionQty.TotalProductionQuantity),0) TotalProductionQuantity 
			 ,

    ISNULL(((ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) / min (ProductionQty.TotalProductionQuantity)),0) as AvgCost


    FROM    Acc_IncomeStatmentMainItem INNER JOIN
            Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
            AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
            Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
			inner join Acc_Branch on Acc_Branch.BranchId = AccountBalance_1.BranchId
            left outer join ProductionQty on ProductionQty.BranchId = Acc_Branch.BranchId
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId,
	 Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport,BranchName,BranchCode

	union all

	SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS SubItemBalance, 
					  Acc_IncomeStatmentSubItem.SubItemName,Acc_IncomeStatmentMainItem.MainItemNameArabic,N'إجمالى الكمية المنتجة' as BranchName, Acc_IncomeStatmentMainItem.MainItemId,

           '2147483647' AS BranchCode, Acc_IncomeStatmentSubItem.OrderInReport
             , ISNULL (min(ProductionQtyWithOutBranch.TotalProductionQuantity),0) TotalProductionQuantity 
			 ,

    ISNULL(((ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) / min (ProductionQtyWithOutBranch.TotalProductionQuantity)),0) as AvgCost


    FROM    Acc_IncomeStatmentMainItem INNER JOIN
            Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
            AccountBalanceWithoutBranch AS AccountBalance_1 RIGHT OUTER JOIN
            Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
			
            left outer join ProductionQtyWithOutBranch on ProductionQtyWithOutBranch.BranchId = AccountBalance_1.BranchId
	
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId,
	 Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport
	 having ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)  <>0 

INSERT  @ResultTbl
 (
    SubItemBalance ,
	 SubItemName ,
	 MainItemNameArabic ,
	 BranchName ,
	 MainItemId  ,
	 BranchCode ,
	 OrderInReport ,
	 TotalProductionQuantity ,
	  AvgCost 
)
VALUES (
@SubItemBalance ,
	 @SubItemName ,
	 @MainItemNameArabic ,
	 @BranchName ,
	 @MainItemId  ,
	 @BranchCode ,
	 @OrderInReport ,
	 @TotalProductionQuantity ,
	  @AvgCost 
);
END

```

### Dependencies and cloud existence (all present and registered)
| Object | Cloud file | In sqlproj |
|---|---|---|
| dbo.Acc_IncomeStatmentWithBranchProd (proc) | dbo\Stored Procedures\Acc_IncomeStatmentWithBranchProd.sql | yes |
| dbo.Acc_GetAccountActionsBetweenDatesByBranchs, dbo.Acc_ConvertIntListToTable | dbo\Functions | yes |
| Inv_ProductionOrderDetails, Inv_ProductionOrder, Inv_Warehouse | dbo\Tables | yes |
| Acc_Account, Acc_Branch, Acc_IncomeStatmentMainItem/SubItem | dbo\Tables | yes |

### Layout structure
Same as report 4 (landscape; splitter 2059 wide vs 2694; PageHeader 290 vs 278). Two data fields per branch (balance, average cost) with production quantity as a column sub-header; no column grand total.

### Quirks to reproduce
1. The proc ends with `INSERT @ResultTbl VALUES(@SubItemBalance, ...)` of all-NULL variables into a table variable that is never selected: dead code. The result set returned is the `UNION ALL` of the two SELECTs; do not port the dead insert.
2. Part 1 (per branch) = report 4 plus `TotalProductionQuantity = ISNULL(MIN(ProductionQty.TotalProductionQuantity),0)` and `AvgCost = ISNULL((balance)/MIN(ProductionQty.TotalProductionQuantity),0)`. Division by NULL gives 0; a real 0 quantity would raise divide-by-zero. AvgCost is summed again by the pivot.
3. The `ProductionQty` CTE (per branch) has NO @BranchList filter; `ProductionQtyWithOutBranch` does. Production filter: `ProductionDate BETWEEN @startDate AND @EndDate`, `Inv_ProductionOrder.IsFinalProductAdded = 1`, branch = destination warehouse branch (`DestinationWarehouseId`).
4. Part 2 (synthetic column): BranchName = the Arabic literal for "total produced quantity", BranchCode = '2147483647' (string sort: lands between "2" and "3"), no join to Acc_Branch, balances over all branches (BranchId 0), `HAVING balance <> 0` (zero rows dropped ONLY in this part), qty = branch-list-filtered total, AvgCost = total / qty.
5. XSD declares AvgCost and TotalProductionQuantity as xs:double; the pivot formats N2 regardless of ApproximateNo.
6. The Arabic grand-total header shows `totalQty` from the separate query (branch-filtered sum over production orders).
7. Report 4 quirks 2-3 also apply (inner join on Acc_Branch in part 1, no parent roll-up).

## 3. Report 6 - IncomeStatementCostCenter

### Route and params
- Route `financial-reports/income-statment-costcenter-report`, query `?report=IncomeStatementCostCenter`, component `BrifIncomeStatmentCostcenterReportShellComponent` (shared with brief cost-center, which uses report='' -> default 'CostCenterIncomeStatement', and IncomeStatementActivityDetail).
- Form fields: `fromDate,toDate,revised,journalTypes,costCenterIds` (costCenterIds required). `revised` defaults to `''`, which binds to `bool?` null.
### MVC action
`GET mvc/FinancialReports/IncomeStatementCostCenter(lang, fromDate, toDate, bool? revised, string journalTypes, string costCenterIds)` -> `new rptIncomeStatemetCostCenter(...)` (action name IncomeStatementCostCenter, class name has the Statemet typo).
### BeforePrint
Fill SystemConfiguration; `acc_IncomeStatmentCostCenterTableAdapter.Fill(ds.Acc_IncomeStatmentCostCenter, _fromDate, _toDate, revised, journalTypes, costCenterList)`; lblRevised. Nothing else.
### Pivot (DataMember Acc_IncomeStatmentCostCenter)
Identical to report 4 with BranchName replaced by CostCenterName (GrandTotalText "الفائض / العجز") and hidden BranchCode replaced by CostCenterNo (CAST NVARCHAR(10), text sort). Sorts: MainItemNameArabic by MainItemId, SubItemName by OrderInReport, CostCenterName by CostCenterNo. Arabic grand-total captions as report 4.

### SQL - Acc_IncomeStatmentCostCenter TableAdapter (Text), VERBATIM
```sql
WITH AccountBalance(AccountId, ParentAccountId, PeriodCredit, PeriodDebit,CostCenterId) AS 
(SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,Balance.CostCenterId
    FROM      Acc_Account LEFT OUTER JOIN
                            (SELECT AccountId ,PeriodCredit, PeriodDebit,BranchId,CostCenterId
                            FROM      dbo.Acc_GetAccountActionsBetweenDatesByCostCenters(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
                                                @JournalTypeList, NULL, NULL,@CostCenterList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
                        Acc_Account.AccountId = Balance.AccountId
   
    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId,Balance.CostCenterId)
   
    SELECT   ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS SubItemBalance, 
					  Acc_IncomeStatmentSubItem.SubItemName,Acc_IncomeStatmentMainItem.MainItemNameArabic,CostCenterName, Acc_IncomeStatmentMainItem.MainItemId,
            CAST(CostCenterNo AS NVARCHAR(10)) AS CostCenterNo, Acc_IncomeStatmentSubItem.OrderInReport
    FROM    Acc_IncomeStatmentMainItem INNER JOIN
            Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
            AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
            Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
			inner join Acc_CostCenter on Acc_CostCenter.CostCenterId = AccountBalance_1.CostCenterId
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport,CostCenterName,CostCenterNo
    ORDER BY Acc_IncomeStatmentMainItem.MainItemId
```
Params (DbType): @FromBalanceDate DateTime; @ToBalanceDate DateTime; @JournalRevise Boolean (nullable); @JournalTypeList String (size 0, NOT nullable); @CostCenterList String (size 0, NOT nullable). Fill order: from, to, revised, journalTypes, costCenterList.

### Dependencies and cloud existence (all present and registered)
| Object | Cloud file | In sqlproj |
|---|---|---|
| dbo.Acc_GetAccountActionsBetweenDatesByCostCenters (TVF) | dbo\Functions\Acc_GetAccountActionsBetweenDatesByCostCenters.sql | yes |
| dbo.Acc_ConvertIntListToTable | dbo\Functions | yes |
| Acc_CostCenter, Acc_Account, Acc_IncomeStatmentMainItem/SubItem, Acc_SystemConfiguration | dbo\Tables | yes |

CostCenters TVF: same body as the Branchs TVF, but the optional list filters `Acc_JournalAction.CostCenterId IN (list)`; same output columns (AccountId, CostCenterId, PeriodCredit, PeriodDebit, BranchId).

### Layout structure
Same as report 4 (PageHeader 324.5 tall, splitter 2059 wide); single data field SubItemBalance; grand totals on both axes.

### Quirks to reproduce
1. Report 4 quirks 1-4 apply, with `INNER JOIN Acc_CostCenter` instead of Acc_Branch: lines with NULL CostCenterId are DROPPED, so the report total does not tie to the full income statement. Reproduce, do not fix.
2. Cost-center filter is on `Acc_JournalAction.CostCenterId`; branch is not filtered.
3. Columns sorted by CostCenterNo as string.
4. No synthetic total column.

## 4. What shares SQL
- 4 and 5 share TVF `Acc_GetAccountActionsBetweenDatesByBranchs` and the CTE / outer-join skeleton; 5 adds production qty, average cost and a total column through a proc.
- 4 and 6 share the query skeleton and differ ONLY in the TVF (ByBranchs vs ByCostCenters), the dimension join (Acc_Branch BranchName/BranchCode vs Acc_CostCenter CostCenterName/CostCenterNo) and the list parameter (@BranchList vs @CostCenterList).
- The migrated IncomeStatement (CR 123252) is the same skeleton without a dimension column.

## 5. Missing cloud dependencies
None found: every table, TVF and the proc referenced exists in the cloud database project and is registered via `<Build Include>`. Caveats: (a) proc Acc_IncomeStatmentWithBranchProd body is available only from the cloud project; (b) Acc_JournalAction / Acc_Journal not individually checked.
