# Legacy inventory: Cash Flow Report (تقرير التدفقات النقدية), CR 125291

Read-only dissection, 2026-10-15. Paths are absolute.
Front `D:\Hadaf\worktrees\cr125291\AccFlex_Cloud_Front\accflex-erp`, MVC/reports `D:\Hadaf\AccFlex_ERP` (main checkout),
cloud DB `D:\Hadaf\worktrees\cr125291\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State`.

**One-paragraph summary.** The report is a single flat list (no groups, no sub-reports). All the
numbers come from ONE stored procedure, `dbo.Acc_CashFlowReport(@FromBalanceDate, @ToBalanceDate, @BranchList)`,
which returns 12 rows (indirect-method items + opening and closing cash). The rpt's `BeforePrint` then
appends 4 C# subtotal rows (net operating / investing / financing / net change) and builds the
printed string `DisplayValue` (absolute value, negatives in parentheses, `N{ApproximateNo}`). Cash-flow
classification is **hard-coded in the proc** by `Acc_Account.AccountTypeId`, `Acc_Account.EquityType`,
and the account ids held by `Saf_Store` / `Saf_Bank` / `Inv_Item` / `Acc_AssetType`. There is no setup
table and no account flag for it.

## 0. Plumbing

| Piece | Value |
|---|---|
| Module file | `...\projects\general-accounting\src\app\modules\financial-reports\financial-reports.module.ts` lines 192-197 |
| Route | `path: 'cash-flow'`, `component: CashFlowShellComponent`, `canActivate: [AccflexAuthGuard, CanActivateRouteGuard]`, **`data: { ModuleId: 79 }`** |
| Menu | `...\projects\general-accounting\src\app\core\routes.ts` ~line 936: id `6_3_1`, text "Cash Flow", textAr "التدفقات النقدية", icon `fas fa-coins`, `route: 'financial-reports/cash-flow'`, `params: ''` |
| Title key | `FINANCIALREPORTS._CashFlowReport_` → "Cash Flow Report" / "تقرير التدفقات النقدية" (found in `src\assets\i18n\{en-US,ar-EG}\cash-control.json`) |
| Shell | `...\financial-reports\cash-flow\cash-flow-shell\cash-flow-shell.component.ts/.html` |
| Form | `...\financial-reports\cash-flow\cash-flow-form\cash-flow-form.component.ts/.html` (also reused by `equity-changing-shell`) |
| iframe URL builder | `...\financial-reports\shared\financial-reports-data.service.ts` line 63 `initializeIFrame(reportUrl, query)` = `` `${this.printUrl}FinancialReports/${reportUrl}?lang=${this.lang}&${query}` `` (`lang` = `ar-EG` / `en-US`) |
| Report name in URL | `this.route.queryParams.report` if present, else `'CashFlow'`. Menu passes `params: ''` → always `CashFlow`. |
| Serializer | `src\app\shared\services\query-serialize\query-serialize.service.ts` `serialize(obj)`: every key of `FilterForm.value` → `encodeURIComponent(key)=encodeURIComponent(value)`; arrays → `1,2,3` (encoded `1%2C2%2C3`); `''` → empty. |
| MVC controller | `D:\Hadaf\AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\GeneralLedgerReports\FinancialReportsController.cs` lines 335-344 (`FinancialReportsController : BaseController`, project `netcoreapp3.1`) |
| View / layout lookup | `REPORTS_ROOT_VIEW = "~/Views/Report/ReportView.cshtml"`; it loads a tenant-saved layout by `Model.GetType().Name` + UI culture from the legacy layout store if one exists, else the compiled Designer layout. |
| `.repx` on disk | **None.** `D:\Hadaf\ReportLayout\` does not exist; no `.repx` / InsertLayout seed under `D:\Hadaf` names `rptCashFlow`. Only layout source = `rptCashFlow.Designer.cs`. |
| `.resx` | `rptCashFlow.resx` is boilerplate (`Name1/Color1/Bitmap1/Icon1`). Arabic captions live in the Designer's `localizer1` (`GeneralLedger.Reports.Helper.Localizer`); `ApplyArabic()` skips entries whose Arabic is `""`. |
| Desktop twin | `D:\Hadaf\AccFlex_ERP\GeneralAccounting\Accounting\Reports\CashFlowReport\frmCashFlow.cs` builds the same `rptCashFlow` (see Quirk Q14). |

## 1. Angular input contract

`FilterForm = fb.group({ fromDate: [new Date(), required], toDate: [new Date(), required], branchesIds: [''] })`

| # | Param (query order) | Type | Format on the wire | Default | How the form fills it |
|---|---|---|---|---|---|
| – | `lang` | string | `ar-EG` / `en-US` | `ar-EG` | from the data service, prepended |
| 1 | `fromDate` | date | `yyyy-MM-dd` (shell does `format(new Date(obj.fromDate), 'yyyy-MM-dd')`, local date, no time) | `getReportConfigs().ReportingStartDate`, initially today | `dx-date-box` displayFormat `dd/MM/yyyy`, required |
| 2 | `toDate` | date | `yyyy-MM-dd` | `getReportConfigs().ReportingEndDate`, initially today | `dx-date-box`, required; form rejects `from > to` with `COMMON._EndBeforeStartDateErr_` |
| 3 | `branchesIds` | CSV of int | `1%2C2%2C3`, or empty | `''` (all branches) | `app-branch-check-list (whenBranchChange)` → `patchValue({ branchesIds: e })` (array; `[]` → empty) |

- `ngAfterViewInit` calls `patchValue({ revised: ' ' })`, but there is **no `revised` control**, so it does nothing. No `revised` / journal-type / cost-center filter exists for this report.
- The shell shows toast `COMMON._DataRequired_` if either date is empty. `isShowAccount=true` shows the branch list. `isForSabreen=false` is unused.
- Full URL template:
  `{printUrl}FinancialReports/CashFlow?lang=<ar-EG|en-US>&fromDate=<yyyy-MM-dd>&toDate=<yyyy-MM-dd>&branchesIds=<csv or empty>`

## 2. MVC action

```csharp
[Route("mvc/FinancialReports/CashFlow")]
public IActionResult CashFlow(string lang, DateTime fromDate, DateTime toDate, string branchesIds)
{
    ChangeThreadCulture(lang);
    var BranchesName = ApiLoggedUser.GetBranchNamesBybranchIdList(branchesIds);
    var report = new rptCashFlow(fromDate, toDate, branchesIds, BranchesName);
    return View(REPORTS_ROOT_VIEW, report);
}
```
- `ChangeThreadCulture(lang)` (`BaseController.cs` line 65): anything other than `en-US` → `ar-EG`; sets both `CurrentCulture` and `CurrentUICulture`. `ApiLoggedUser.IsArabic` = `CurrentUICulture.Name == "ar-EG"`.
- `branchesIds=` (empty) binds to **`null`** (ASP.NET Core `ConvertEmptyStringToNull`), so the proc gets `@BranchList = NULL` (all branches). The generated TableAdapter `Fill` maps C# `null` → `DBNull`.
- `GetBranchNamesBybranchIdList` (`D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Helper\ApiLoggedUser.cs` line 342):
  ```sql
  SELECT  BranchName
  FROM    dbo.Acc_Branch
  WHERE  (@Ids is null or BranchId IN ( SELECT    *
                            FROM      dbo.Acc_ConvertIntListToTable(@Ids) ));
  ```
  It is joined in C# with `" - "`. With no branch selected it prints **every branch name** joined by ` - `, not "All".

## 3. rpt: `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\CashFlowReport\rptCashFlow.cs`

- `rptCashFlow : XtraReport, IConnectionString, IReportLayoutProvider`; no sub-reports. Name = `"rptCashFlow"` (en) / `"rptCashFlowAr"` (ar). The ctor applies `localizer1.ApplyArabic()` when Arabic.
- Ctor `(DateTime fromDate, DateTime toDate, string branchsesIds, string branchesName)`:
  `fromDate` → `00:00:00`, `toDate` → `23:59:59.997` (inclusive whole last day). Instance fields (not static).
- `rptCashFlow_BeforePrint` (verbatim logic):
  - Arabic: `RightToLeft = Yes`, `RightToLeftLayout = Yes`; rebinds `clmAccountNo` (the Item cell) from `Acc_CashFlowReport.ItemName` → `Acc_CashFlowReport.ArabicItemName`.
  - `txtBranches.Text = branchesName; txtDateFrom.Text = fromDate.ToShortDateString(); txtDateTo.Text = toDate.ToShortDateString();` (culture-dependent; see Q11).
  - Fills: `acc_SystemConfigurationTableAdapter.Fill(dsCashFlow1.Acc_SystemConfiguration); acc_CashFlowReportTableAdapter.Fill(dsCashFlow1.Acc_CashFlowReport, fromDate, toDate, branchesIds);`
  - Appends 4 rows. `AddAcc_CashFlowReportRow(int Grp, int Ordr, string GroupName, string ArabicGroupName, string ArabicItemName, string ItemName, decimal Value, decimal SumValue, string DisplayValue)`, **in this order** (so each total sees only the rows that exist at that moment):
    ```csharp
    // Grp 0, Ordr 15 — computed FIRST, over SQL rows only (Grp 0 = opening/closing cash excluded)
    AddRow(0, 15, "All", "الكل", "صافي التغير في النقدية", "Net Cash Cahnging",
           Math.Abs(rows.Where(u => u.Grp != 0).Sum(u => u.SumValue)),
           rows.Where(u => u.Grp != 0).Sum(u => u.SumValue), "");
    AddRow(1, 8,  "Operating Activity",  "نشاط التشغيل",  "صافي التدفقات من نشاط التشغيل",  "Net Cash Flow From Operating Activity",
           Math.Abs(Σ SumValue where Grp==1), Σ SumValue where Grp==1, "");
    AddRow(2, 11, "Investment Activity", "نشاط الاستثمار", "صافي التدفقات من نشاط الاستثمار", "Net Cash Flow From Investment Activity",
           Math.Abs(Σ Grp==2), Σ Grp==2, "");
    AddRow(3, 14, "Finance Activity",    "نشاط التمويل",   "صافي التدفقات من نشاط التمويل",   "Net Cash Flow From Finance Activity",
           Math.Abs(Σ Grp==3), Σ Grp==3, "");
    ```
    Net change (15) = Σ SumValue of all SQL rows with Grp 1, 2, 3 = row 8 + row 11 + row 14.
  - Display string for **every** row (SQL + C#):
    ```csharp
    if (row.SumValue < 0) row.DisplayValue = $"({row.Value.ToString($"N{ApiLoggedUser.GetApproximateNo()}")})";
    else                  row.DisplayValue = $"{row.Value.ToString($"N{ApiLoggedUser.GetApproximateNo()}")}";
    ```
    `Value` is always the ABS. The sign is taken from `SumValue`. `GetApproximateNo()` = `SELECT TOP(1)ApproximateNo FROM dbo.Acc_SystemConfiguration` (one DB call per row). The `N` format uses the **thread culture** (ar-EG or en-US).
- `Detail_BeforePrint`: `Ordr` ∈ {8, 11, 14, 15} → both cells `BackColor = Silver`; else Transparent. These are the 4 C# total rows.
- `moneyApproximate1` is configured in the Designer (`clmName` IsMoney) but `ApplyApproximate` is **never called** in this rpt. The value cell is a preformatted string anyway; its binding format `{0:n2}` has no effect on a string.
- The Designer also declares an unused `acc_AccountTableAdapter` (from `PeriodJournalReport.dsPeriodJournal`). It is never filled.

## 4. ds: `...\CashFlowReport\dsCashFlow.xsd`

Two TableAdapters only.

**Acc_CashFlowReport**: `CommandType="StoredProcedure"`, `CommandText` = `dbo.Acc_CashFlowReport`. Params: `@FromBalanceDate datetime (nullable)`, `@ToBalanceDate datetime (nullable)`, `@BranchList nvarchar(max) (nullable)`.
Columns: `Grp int`, `Ordr int`, `GroupName`, `ArabicGroupName`, `ArabicItemName`, `ItemName` (nvarchar max), `Value decimal`, `SumValue decimal`, `DisplayValue string` (DataSet-only, filled in C#).

**Acc_SystemConfiguration** (verbatim select):
```sql
SELECT Acc_SystemConfiguration.*
FROM  Acc_SystemConfiguration
```

### Proc body: `dbo\Stored Procedures\Acc_CashFlowReport.sql` (cloud DB; identical in the main checkout `D:\Hadaf\AccFlex_Cloud_Database`; registered in the .sqlproj line 3442). Verbatim:

```sql
-- =============================================
-- Author:		Abd AlRahman Hamaj
-- Create date: 3/10/2021
-- Description:	Cash Flow Report
-- =============================================
CREATE PROCEDURE [dbo].[Acc_CashFlowReport]
-- Add the parameters for the stored procedure here
    @FromBalanceDate DATETIME ,
    @ToBalanceDate DATETIME ,
    @BranchList NVARCHAR(MAX) = NULL
AS
    BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
        SET NOCOUNT ON;
        DECLARE @_FromBalanceDate DATETIME;
        DECLARE @_ToBalanceDate DATETIME;
        DECLARE @_BranchList NVARCHAR(MAX);
        SET @_FromBalanceDate = @FromBalanceDate;
        SET @_ToBalanceDate = @ToBalanceDate;
        SET @_BranchList = @BranchList;
        DECLARE @CashAccounts NVARCHAR(MAX);
        DECLARE @AccountBalances TABLE
            (
              AccountId INT ,
              PeriodCredit MONEY ,
              PeriodDebit MONEY ,
              PeriodBalance MONEY
            );
     -- Insert statements for procedure here
        SELECT  @CashAccounts = COALESCE(@CashAccounts + ',', '')
                + CAST(TreasuryBankAccounts.AccountId AS NVARCHAR(20))
        FROM    ( SELECT    AccountId
                  FROM      dbo.Saf_Store
                  WHERE     AccountId IS NOT NULL
                  UNION ALL
                  SELECT    BankAccountId
                  FROM      dbo.Saf_Bank
                  WHERE     BankAccountId IS NOT NULL
                ) TreasuryBankAccounts;

        DECLARE @CashAccountsTb TABLE ( AccountId INT PRIMARY KEY );
        INSERT  INTO @CashAccountsTb ( AccountId )
                SELECT DISTINCT number
                FROM    dbo.Acc_ConvertIntListToTable(@CashAccounts);

        DECLARE @StockAccounts TABLE ( AccountId INT PRIMARY KEY );
        INSERT  INTO @StockAccounts ( AccountId )
                SELECT DISTINCT ItemStockAccountId
                FROM    dbo.Inv_Item
                WHERE   ItemStockAccountId IS NOT NULL;

        DECLARE @TreasuryBankAccountsBalances TABLE
            (
              AccountId INT ,
              OpenningCredit MONEY ,
              OpenningDebit MONEY ,
              PeriodCredit MONEY ,
              PeriodDebit MONEY ,
              OpenningBalance MONEY ,
              PeriodBalance MONEY
            );
        INSERT  INTO @TreasuryBankAccountsBalances
                SELECT  AccountId ,
                        OpenningCredit ,
                        OpenningDebit ,
                        PeriodCredit ,
                        PeriodDebit ,
                        OpenningBalance ,
                        PeriodBalance
                FROM    dbo.Acc_GetAccountsBalancePeriod(@_FromBalanceDate,
                                                         @_ToBalanceDate,
                                                         @CashAccounts, NULL,
                                                         NULL, NULL,
                                                         @_BranchList);

        INSERT  INTO @AccountBalances
                ( AccountId ,
                  PeriodCredit ,
                  PeriodDebit ,
                  PeriodBalance
                )
                SELECT  Acc_JournalAction.AccountId ,
                        ISNULL(SUM(Acc_JournalAction.CreditLocal), 0) AS PeriodCredit ,
                        ISNULL(SUM(Acc_JournalAction.DebitLocal), 0) AS PeriodDebit ,
                        ISNULL(SUM(Acc_JournalAction.DebitLocal), 0)
                        - ISNULL(SUM(Acc_JournalAction.CreditLocal), 0) AS PeriodBalance
                FROM    Acc_JournalAction
                        INNER JOIN Acc_Journal ON Acc_JournalAction.JournalId = Acc_Journal.JournalId
                        INNER JOIN ( SELECT number
                                     FROM   dbo.Acc_ConvertIntListToTable(@BranchList)
                                            AS Acc_ConvertIntListToTable_2
                                   ) AS BranchTb ON @BranchList IS NULL
                                                    OR ( BranchTb.number = dbo.Acc_JournalAction.BranchId )
                WHERE   ( Acc_Journal.CreatedDate <= @ToBalanceDate )
                        AND ( Acc_Journal.CreatedDate >= @FromBalanceDate )
                        AND ( Acc_JournalAction.Void = 0
                              AND dbo.Acc_Journal.Void = 0
                            )
                        AND JournalTypeId <> 4
                GROUP BY AccountId;

        WITH    AllItems
                  AS ( SELECT   1 AS GRP ,
                                1 AS ORDR ,
                                N'Operating Activity' AS GroupName ,
                                N'نشاط التشغيل' AS ArabicGroupName ,
                                N'قائمة الدخل' AS ArabicItemName ,
                                N'Income Statemant' AS ItemName ,
                                ABS(( SELECT    SUM(ISNULL(PeriodBalance, 0))
                                      FROM      @AccountBalances AS Blnc
                                                RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                      WHERE     Acc_Account.AccountTypeId = 1
                                                OR Acc_Account.AccountTypeId = 3
                                                OR Acc_Account.AccountTypeId = 2
                                                OR Acc_Account.AccountTypeId = 4
                                                OR Acc_Account.AccountTypeId = 5
                                    )) AS Value ,
                                ( SELECT    SUM(ISNULL(PeriodBalance, 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     Acc_Account.AccountTypeId = 1
                                            OR Acc_Account.AccountTypeId = 3
                                            OR Acc_Account.AccountTypeId = 2
                                            OR Acc_Account.AccountTypeId = 4
                                            OR Acc_Account.AccountTypeId = 5
                                ) * -1 AS SumValue
                       UNION ALL
                       SELECT   1 AS GRP ,
                                2 AS ORDR ,
                                N'Operating Activity' AS GroupName ,
                                N'نشاط التشغيل' AS ArabicGroupName ,
                                N'الاهلاك' AS ArabicItemName ,
                                N'Depreciation' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(Blnc.PeriodDebit),
                                                       0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     Acc_Account.AccountId IN (
                                            SELECT  Acc_AssetType.DepreciationExpensesAccountId
                                            FROM    Acc_AssetType )
                                ) ,
                                ( SELECT    ISNULL(SUM(Blnc.PeriodDebit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     Acc_Account.AccountId IN (
                                            SELECT  Acc_AssetType.DepreciationExpensesAccountId
                                            FROM    Acc_AssetType )
                                ) AS SumValue
                       UNION ALL
                       SELECT   1 AS GRP ,
                                3 AS ORDR ,
                                N'Operating Activity' AS GroupName ,
                                N'نشاط التشغيل' AS ArabicGroupName ,
                                N'المخصصات' AS ArabicItemName ,
                                N'Allocations' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodBalance), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     Acc_Account.EquityType = 6
                                ) ,
                                ( SELECT    ISNULL(SUM(PeriodBalance), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     Acc_Account.EquityType = 6
                                ) AS SumValue
                       UNION ALL
                       SELECT   1 AS GRP ,
                                4 AS ORDR ,
                                N'Operating Activity' AS GroupName ,
                                N'نشاط التشغيل' AS ArabicGroupName ,
                                N'النقص / الزياده في الاصول المتداوله' AS ArabicItemName ,
                                N'Current Assets Decress/Increase' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodDebit
                                                           - PeriodCredit), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     ( AccountTypeId = 7
                                              OR AccountTypeId = 15
                                            )
                                            AND Acc_Account.AccountId NOT IN (
                                            SELECT  AccountId
                                            FROM    @StockAccounts
                                            UNION ALL
                                            SELECT  AccountId
                                            FROM    @CashAccountsTb )
                                ) ,
                                ( SELECT    ISNULL(SUM(PeriodDebit
                                                       - Blnc.PeriodCredit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     ( AccountTypeId = 7
                                              OR AccountTypeId = 15
                                            )
                                            AND Acc_Account.AccountId NOT IN (
                                            SELECT  AccountId
                                            FROM    @StockAccounts
                                            UNION ALL
                                            SELECT  AccountId
                                            FROM    @CashAccountsTb )
                                ) * -1 AS SumValue
                       UNION ALL
                       SELECT   1 AS GRP ,
                                6 AS ORDR ,
                                N'Operating Activity' AS GroupName ,
                                N'نشاط التشغيل' AS ArabicGroupName ,
                                N'النقص/ الزياده في الخصوم المتداوله' AS ArabicItemName ,
                                N'Current Liabilities Decress/Increase' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodDebit
                                                           - PeriodCredit), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     AccountTypeId = 8
                                            OR Acc_Account.AccountTypeId = 12
                                            OR Acc_Account.AccountTypeId = 19
                                ) ,
                                ( SELECT    ISNULL(SUM(PeriodDebit
                                                       - PeriodCredit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     AccountTypeId = 8
                                            OR Acc_Account.AccountTypeId = 12
                                            OR Acc_Account.AccountTypeId = 19
                                ) * -1 AS SumValue
                       UNION ALL
                       SELECT   1 AS GRP ,
                                4 AS ORDR ,
                                N'Operating Activity' AS GroupName ,
                                N'نشاط التشغيل' AS ArabicGroupName ,
                                N'النقص / الزياده في المخزون' AS ArabicItemName ,
                                N'Inventory Decress/Increase' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodDebit
                                                           - PeriodCredit), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     Acc_Account.AccountId IN (
                                            SELECT  AccountId
                                            FROM    @StockAccounts )
                                ) ,
                                ( SELECT    ISNULL(SUM(PeriodDebit
                                                       - Blnc.PeriodCredit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     Acc_Account.AccountId IN (
                                            SELECT  AccountId
                                            FROM    @StockAccounts )
                                ) * -1 AS SumValue
                       UNION ALL
                       SELECT   2 AS GRP ,
                                9 AS ORDR ,
                                N'Investment Activity' AS GroupName ,
                                N'نشاط الاستثمار' AS ArabicGroupName ,
                                N'بيع اصول طويلة الأجل' AS ArabicItemName ,
                                N'Fixed Assets Sale' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodCredit), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     AccountTypeId = 6
                                ) ,
                                ( SELECT    ISNULL(SUM(PeriodCredit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     AccountTypeId = 6
                                ) AS SumValue
                       UNION ALL
                       SELECT   2 AS GRP ,
                                10 AS ORDR ,
                                N'Investment Activity' AS GroupName ,
                                N'نشاط الاستثمار' AS ArabicGroupName ,
                                N'شراء اصول طويلة الأجل' AS ArabicItemName ,
                                N'Fixed Assets Purchase' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodDebit), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     AccountTypeId = 6
                                ) ,
                                ( SELECT    ISNULL(SUM(-1 * PeriodDebit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     AccountTypeId = 6
                                ) AS SumValue
                       UNION ALL
                       SELECT   3 AS GRP ,
                                12 AS ORDR ,
                                N'Finance Activity' AS GroupName ,
                                N'نشاط التمويل' AS ArabicGroupName ,
                                N'الزيادة في حقوق الملكية و الخصوم طويلة الأجل' AS ArabicItemName ,
                                N'Equity (Owners’ equity)&Long-term liabilities Increase' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodCredit), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     ( AccountTypeId = 9
                                              OR AccountTypeId = 10
                                            )
                                            AND Blnc.AccountId NOT IN (
                                            SELECT  AccumulatedDepAccountId
                                            FROM    dbo.Acc_AssetType
                                            WHERE   AccumulatedDepAccountId IS NOT NULL )
                                ) ,
                                ( SELECT    ISNULL(SUM(PeriodCredit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     ( AccountTypeId = 9
                                              OR AccountTypeId = 10
                                            )
                                            AND Blnc.AccountId NOT IN (
                                            SELECT  AccumulatedDepAccountId
                                            FROM    dbo.Acc_AssetType
                                            WHERE   AccumulatedDepAccountId IS NOT NULL )
                                ) AS SumValue
                       UNION ALL
                       SELECT   3 AS GRP ,
                                13 AS ORDR ,
                                N'Finance Activity' AS GroupName ,
                                N'نشاط النمويل' AS ArabicGroupName ,
                                N'النقص في حقوق الملكية و الخصوم طويلة الأجل' AS ArabicItemName ,
                                N'Equity (Owners’ equity)&Long-term liabilities Decress' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(PeriodDebit), 0))
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     ( AccountTypeId = 9
                                              OR AccountTypeId = 10
                                            )
                                            AND Blnc.AccountId NOT IN (
                                            SELECT  AccumulatedDepAccountId
                                            FROM    dbo.Acc_AssetType
                                            WHERE   AccumulatedDepAccountId IS NOT NULL )
                                ) ,
                                ( SELECT    ISNULL(SUM(-1 * PeriodDebit), 0)
                                  FROM      @AccountBalances AS Blnc
                                            RIGHT JOIN Acc_Account ON Blnc.AccountId = Acc_Account.AccountId
                                  WHERE     ( AccountTypeId = 9
                                              OR AccountTypeId = 10
                                            )
                                            AND Blnc.AccountId NOT IN (
                                            SELECT  AccumulatedDepAccountId
                                            FROM    dbo.Acc_AssetType
                                            WHERE   AccumulatedDepAccountId IS NOT NULL )
                                ) AS SumValue
                       UNION ALL
                       SELECT   0 AS GRP ,
                                16 AS ORDR ,
                                N'Start Period Cash Balance' AS GroupName ,
                                N'رصيد النقدية اول الفترة' AS ArabicGroupName ,
                                N'رصيد النقدية اول الفترة' AS ArabicItemName ,
                                N'Start Period Cash Balance' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(OpenningDebit
                                                           - OpenningCredit),
                                                       0))
                                  FROM      @TreasuryBankAccountsBalances
                                ) ,
                                ( SELECT    ISNULL(SUM(OpenningDebit
                                                       - OpenningCredit), 0)
                                  FROM      @TreasuryBankAccountsBalances
                                ) AS SumValue
                       UNION ALL
                       SELECT   0 AS GRP ,
                                17 AS ORDR ,
                                N'End Period Cash Balance' AS GroupName ,
                                N'رصيد النقدية اخر الفترة' AS ArabicGroupName ,
                                N'رصيد النقدية اخر الفترة' AS ArabicItemName ,
                                N'End Period Cash Balance' AS ItemName ,
                                ( SELECT    ABS(ISNULL(SUM(( OpenningDebit
                                                             + PeriodDebit )
                                                           - ( OpenningCredit
                                                              + PeriodCredit )),
                                                       0))
                                  FROM      @TreasuryBankAccountsBalances
                                ) ,
                                ( SELECT    ISNULL(SUM(( OpenningDebit
                                                         + PeriodDebit )
                                                       - ( OpenningCredit
                                                           + PeriodCredit )),
                                                   0)
                                  FROM      @TreasuryBankAccountsBalances
                                ) AS SumValue
                     )
            SELECT  *
            FROM    AllItems
            ORDER BY ORDR;
    END;
```

### Proc semantics (what a TVF port must reproduce)

- `@AccountBalances` = per-account sums of `Acc_JournalAction.CreditLocal` / `DebitLocal` (local currency), `PeriodBalance = Debit − Credit`.
  - The window is `Acc_Journal.CreatedDate BETWEEN @From AND @To` (inclusive on both ends; `CreatedDate` is the journal's date column; `JournalCreatedDate` is a separate nullable column).
  - `Acc_JournalAction.Void = 0 AND Acc_Journal.Void = 0`.
  - `JournalTypeId <> 4` (4 = "End Period Journal / قيود اقفال فتره": closing entries are excluded).
  - **No `Revised` filter. No leaf-account filter.** Opening balances (`Acc_AccountBalance`) are not used for the flows.
  - Branch: `INNER JOIN Acc_ConvertIntListToTable(@BranchList) ON @BranchList IS NULL OR number = JournalAction.BranchId`. `Acc_ConvertIntListToTable(NULL)` returns exactly one row (`0`), so NULL = all branches, including actions whose `BranchId` IS NULL. With a list, actions with a NULL branch are dropped.
  - Note: the branch join uses the raw `@BranchList`, not the `@_BranchList` copy. The date filter also uses the raw parameters.
- Cash accounts: `@CashAccounts` = CSV of `Saf_Store.AccountId` (treasuries) ∪ `Saf_Bank.BankAccountId` (banks).
  - `@CashAccountsTb` = the same ids, distinct.
  - `@StockAccounts` = distinct `Inv_Item.ItemStockAccountId`.
- Opening and closing cash: `Acc_GetAccountsBalancePeriod(@From, @To, @CashAccounts, NULL, NULL, NULL, @_BranchList)`. It returns per account (with parent roll-up, then filtered to the list):
  - `Openning*` = transferred balances (`Acc_AccountBalance` of the last non-transferred sub-period, via `Acc_GetAccountBalanceBeforeDate`) + actions before `@From` since that sub-period start (`Acc_GetAccountJournalActionsBeforeDate`).
  - `Period*` = actions `BETWEEN @From AND @To` (`Acc_GetAccountJournalActionsBetweenDates`).
  - All of these use `CreatedDate` and `Void = 0`, and **do not exclude JournalTypeId 4**.
- How each item is classified, and its sign (`SumValue` is the signed contribution to cash; `Value` = ABS):

| Grp | Ordr | ItemName / ArabicItemName | Accounts | SumValue |
|---|---|---|---|---|
| 1 | 1 | Income Statemant / قائمة الدخل | `AccountTypeId IN (1,2,3,4,5)` (op. income, op. exp., other income, G&A, other exp.) | `−Σ(D−C)` = net profit |
| 1 | 2 | Depreciation / الاهلاك | `AccountId IN Acc_AssetType.DepreciationExpensesAccountId` | `+Σ PeriodDebit` (add-back, debits only) |
| 1 | 3 | Allocations / المخصصات | `Acc_Account.EquityType = 6` (Allocations) | `+Σ(D−C)` (**not negated**, see Q3) |
| 1 | 4 | Current Assets Decress/Increase / النقص / الزياده في الاصول المتداوله | `AccountTypeId IN (7,15)` minus stock accounts minus cash accounts | `−Σ(D−C)` |
| 1 | 4 | Inventory Decress/Increase / النقص / الزياده في المخزون | stock accounts (`Inv_Item.ItemStockAccountId`) | `−Σ(D−C)` |
| 1 | 6 | Current Liabilities Decress/Increase / النقص/ الزياده في الخصوم المتداوله | `AccountTypeId IN (8,12,19)` (curr. liab., Profit/Loss, accrued exp.) | `−Σ(D−C)` |
| 2 | 9 | Fixed Assets Sale / بيع اصول طويلة الأجل | `AccountTypeId = 6` | `+Σ PeriodCredit` |
| 2 | 10 | Fixed Assets Purchase / شراء اصول طويلة الأجل | `AccountTypeId = 6` | `−Σ PeriodDebit` |
| 3 | 12 | Equity (Owners’ equity)&Long-term liabilities Increase / الزيادة في حقوق الملكية و الخصوم طويلة الأجل | `AccountTypeId IN (9,10)` minus `Acc_AssetType.AccumulatedDepAccountId` | `+Σ PeriodCredit` |
| 3 | 13 | Equity (Owners’ equity)&Long-term liabilities Decress / النقص في حقوق الملكية و الخصوم طويلة الأجل | same | `−Σ PeriodDebit` |
| 0 | 16 | Start Period Cash Balance / رصيد النقدية اول الفترة | cash accounts | `Σ(OpenningDebit − OpenningCredit)` |
| 0 | 17 | End Period Cash Balance / رصيد النقدية اخر الفترة | cash accounts | `Σ((OpenningDebit+PeriodDebit) − (OpenningCredit+PeriodCredit))` |

Every sub-select is `FROM @AccountBalances Blnc RIGHT JOIN Acc_Account ON ...`, so accounts with no movement add 0 / NULL. `ISNULL` sits inside the SUM for row 1 and around the SUM for the others.

## 5. Printed statement: final row order

Detail `SortFields = Ordr ASC`. No group bands. Rows 8/11/14/15 are silver (C#).

| Ordr | Source | English | Arabic |
|---|---|---|---|
| 1 | SQL | Income Statemant | قائمة الدخل |
| 2 | SQL | Depreciation | الاهلاك |
| 3 | SQL | Allocations | المخصصات |
| 4 | SQL | Current Assets Decress/Increase | النقص / الزياده في الاصول المتداوله |
| 4 | SQL | Inventory Decress/Increase | النقص / الزياده في المخزون |
| 6 | SQL | Current Liabilities Decress/Increase | النقص/ الزياده في الخصوم المتداوله |
| **8** | C# | Net Cash Flow From Operating Activity | صافي التدفقات من نشاط التشغيل |
| 9 | SQL | Fixed Assets Sale | بيع اصول طويلة الأجل |
| 10 | SQL | Fixed Assets Purchase | شراء اصول طويلة الأجل |
| **11** | C# | Net Cash Flow From Investment Activity | صافي التدفقات من نشاط الاستثمار |
| 12 | SQL | Equity (Owners’ equity)&Long-term liabilities Increase | الزيادة في حقوق الملكية و الخصوم طويلة الأجل |
| 13 | SQL | Equity (Owners’ equity)&Long-term liabilities Decress | النقص في حقوق الملكية و الخصوم طويلة الأجل |
| **14** | C# | Net Cash Flow From Finance Activity | صافي التدفقات من نشاط التمويل |
| **15** | C# | Net Cash Cahnging | صافي التغير في النقدية |
| 16 | SQL | Start Period Cash Balance | رصيد النقدية اول الفترة |
| 17 | SQL | End Period Cash Balance | رصيد النقدية اخر الفترة |

Always 16 rows; zero rows print `0.00` (or `0` / `0.000` per ApproximateNo). Nothing is hidden or cancelled. `GroupName` / `ArabicGroupName` are **never printed**.

## 6. Layout (`rptCashFlow.Designer.cs`, DevExpress v20.2)

- Report: `DataMember = "Acc_CashFlowReport"`, `DataSource = dsCashFlow1`, Margins (4, 5, 7, 14). Portrait default paper (no PaperKind / Landscape set). Width 841.
- Bands: `TopMargin`, `ReportHeader`, `GroupHeader1`, `Detail`, `PageFooter`, `BottomMargin`.
  - **ReportHeader** (company header, bound to `Acc_SystemConfiguration`): `MainLogo` (ImageSource ← `Logo`), `MainCompanyName` (`CompanyName`), `MainComapnyAddress` (`Address`), Tel `xrLabel2` (`Telephone`), Fax `xrLabel3` (`Fax`), E-Mail `MainCompanyContact` (`Email`), `MainReportHeaderSplitter`, title `xrLabel1` "Cash Flow Report" / "تقرير التدفقات النقدية" (Tahoma 14.25 bold), `From Date`/"من تاريخ" `txtDateFrom`, `To Date`/"الي تاريخ" `txtDateTo`, `Branches`/"الفروع" `txtBranches`.
  - **GroupHeader1** (no GroupFields, so it acts as a column header printed once): `xrTable1`, PowderBlue, Times New Roman 12 bold, cells "Item"/"البند" (weight 0.6158) and "Value"/"القيمه" (weight 0.3984).
  - **Detail**: `xrTable2` borders L/R/B; `clmAccountNo` ← `ItemName` (Ar: `ArabicItemName`), Tahoma 10 bold, MiddleCenter, weight 0.6114; `clmName` ← `DisplayValue`, Tahoma 10 bold, MiddleCenter, weight 0.3956. Silver back color on Ordr 8/11/14/15.
  - **PageFooter**: `MainPageNo`, `mainPrintedFrom` static "PC:", `xrPageInfo1` UserName "Printed by :{0}" (server process user), `MainPrintDate` "Printed on :{0:dd/MM/yyyy}", `lblHadaf` "Powered By : www.AccFlex.com". These have no Arabic translation (`""`) → stay English in Arabic.

## 7. Arabic vs English differences

| Aspect | en-US | ar-EG |
|---|---|---|
| Item text | `ItemName` | `ArabicItemName` (rebinding in BeforePrint) |
| Direction | LTR | `RightToLeft` + `RightToLeftLayout` |
| Captions | English | localizer: title, From/To, Branches, Tel/Fax/E-mail, Item/Value |
| Numbers | `N{n}` under en-US | `N{n}` under ar-EG thread culture (separators per the server's culture data, see Q11) |
| Header dates | `ToShortDateString()` en-US → `M/d/yyyy` | ar-EG → `dd/MM/yyyy` |
| Language-only bugs | English label typos "Income Statemant", "Decress", "Net Cash Cahnging" | `ArabicGroupName` typo `نشاط النمويل` on Ordr 13 (not printed) |

## 8. Cloud dependencies (`...\AccFlex_Cloud_Database_State\dbo\`)

| Object | Kind | Cloud |
|---|---|---|
| `Acc_CashFlowReport` | proc (the whole report) | EXISTS `Stored Procedures\Acc_CashFlowReport.sql` |
| `Acc_ConvertIntListToTable` | TVF (`NULL` → one row `0`; `''` → one row `0`) | EXISTS `Functions\Acc_ConvertIntListToTable.sql` |
| `Acc_GetAccountsBalancePeriod` | inline TVF (7 params, parent roll-up) | EXISTS `Functions\Acc_GetAccountsBalancePeriod.sql` |
| ↳ `Acc_GetAccountBalanceBeforeDate` | TVF | EXISTS `Functions\Acc_GetAccountBalanceBeforeDate.sql` |
| ↳ `Acc_GetAccountJournalActionsBeforeDate` | TVF | EXISTS `Functions\Acc_GetAccountJournalActionsBeforeDate.sql` |
| ↳ `Acc_GetAccountJournalActionsBetweenDates` | TVF | EXISTS `Functions\Acc_GetAccountJournalActionsBetweenDates.sql` |
| `Acc_JournalAction`, `Acc_Journal`, `Acc_Account`, `Acc_AccountType`, `Acc_AssetType` (`DepreciationExpensesAccountId`, `AccumulatedDepAccountId`), `Saf_Store` (`AccountId`), `Saf_Bank` (`BankAccountId`), `Inv_Item` (`ItemStockAccountId`), `Acc_Branch`, `Acc_SystemConfiguration` (`ApproximateNo`, header) | tables | all EXIST `Tables\<name>.sql` |
| `Acc_EquityType` (6 = Allocations / المخصصات), `Acc_JournalType` (4 = End Period Journal), `Acc_AccountType` (1-19) | reference data | `Scripts\ReferenceDataScripts\0001_GL_ReferenceDate.sql` |
| Existing cash-flow TVF / view / AnalyticsReader entity | — | **NONE** (only the proc matches `cashflow`; nothing in `AccFlex_Cloud_ERP`) |

Nothing is MISSING. The port can wrap the proc's logic in a new TVF (a TVF cannot call the proc or use table variables inline, so the CTE has to be rewritten as a multi-statement or inline TVF).

## 9. Quirks a faithful port must reproduce

- **Q1 Sign and display.** `Value = ABS`, `SumValue` = signed. The printed text is `(x)` when `SumValue < 0`, else `x`, formatted `N{ApproximateNo}`. This applies to the Start/End cash rows too (overdrawn cash prints in parentheses).
- **Q2 Totals in C#.** Rows 8/11/14 = Σ SumValue of their Grp. Row 15 = Σ of Grp 1-3 SQL rows. Start + Net ≠ End is **not checked**, and in general it does not reconcile (see Q5-Q8).
- **Q3 Allocations sign.** `SumValue = Σ(Debit − Credit)` with no `* -1`. A provision build-up (credit) therefore *reduces* operating cash, the opposite of an indirect-method add-back. Allocation accounts (EquityType 6) may also be type 8/9/10 → counted again in rows 6 or 12/13.
- **Q4 Depreciation** adds back only `PeriodDebit` of the depreciation-expense accounts. Those accounts are already inside the row 1 net profit (types 2/4/5), so this is a true add-back.
- **Q5 Unclassified types** never appear: 11 Other, 13 Taxes, 14 Main, 16 Projects under construction, 17 Unearned revenue, 18 Prepaid expenses. Row 1 covers only types 1-5.
- **Q6 Type 6 gross both ways.** Sale = all credits on type-6 accounts, Purchase = all debits. If accumulated-depreciation accounts are typed 6, depreciation credits show as "Fixed Assets Sale". Accumulated depreciation is excluded only from the 9/10 rows.
- **Q7 Journal type 4 asymmetry.** Flows exclude End-Period journals; the opening/closing cash function does not.
- **Q8 Window asymmetry.** Flows ignore opening balances. Cash Start/End use `Acc_AccountBalance` transferred balances + roll-up. Flows have no leaf filter, so actions posted on a parent account still count.
- **Q9 Duplicate Ordr 4** (Current Assets and Inventory). The order between them is not deterministic (DataTable / DevExpress sort stability). Pin it explicitly, e.g. by proc UNION order: Current Assets first. Ordr 5 and 7 are unused.
- **Q10 Branch filter.** NULL → all branches incl. NULL-branch actions. A list → INNER JOIN, so a duplicated id in the CSV doubles the flows, but not the cash balances (`IN`). An empty string `''` would mean "branch 0" → empty flows; the MVC path never sends `''` (binds null), the desktop does (Q14).
- **Q11 Culture formatting.** `N{n}` and `ToShortDateString()` follow the thread culture: en-US dates print `M/d/yyyy`, ar-EG `dd/MM/yyyy`. The MVC is `netcoreapp3.1` (NLS on Windows / ICU on Linux), so ar-EG separators depend on the host.
- **Q12 Edge nulls.** If `Saf_Store` and `Saf_Bank` have no accounts, `@CashAccounts` is NULL → `Acc_GetAccountsBalancePeriod` returns **all accounts incl. parent roll-ups** → Start/End = Σ of everything (double-counted parents). If no account of type 1-5 exists, row 1 `SumValue` is NULL → `u.SumValue` throws `StrongTypingException`.
- **Q13 Header branches.** With no branch selected, the header prints every branch name joined by `" - "`, not "All".
- **Q14 Desktop twin** (`frmCashFlow.cs`): passes `string.Join(",", SelectedBranchesIds)` → `''` when none are selected → the proc treats it as branch 0 → every flow row is 0. It sets the header to "All"/"الكل" and `ToDate = date+1d−1s` (23:59:59, not .997).

## 10. Open questions

1. Reproduce Q3 (Allocations sign) and Q6 (type-6 gross sale/purchase) bug-for-bug, or fix them? The data-fidelity rule says reproduce. Confirm with the PO before "fixing".
2. Q9: which order does production actually print for the two Ordr-4 rows? Capture one live MVC print to pin it.
3. Should the port expose `Grp`/`GroupName` (section headers Operating / Investing / Financing) in the new layout? Legacy prints none; the Arabic group-name typo (`نشاط النمويل`) must be fixed if it is ever shown.
4. Number format of the port: OData returns numbers, and the parentheses-for-negative display moves to the `.repx` format string. Confirm ApproximateNo-based decimals vs the fixed `n2` used by other ODATA reports.
5. Is the non-reconciliation (Start + Net ≠ End, Q5/Q7/Q8) known to users? A port should not silently add a "difference" row unless asked.
6. Tenant-saved legacy layouts for `rptCashFlow` / `rptCashFlowAr` in the MVC layout store: check whether any tenant customized it before choosing the seeded `.repx` design.
