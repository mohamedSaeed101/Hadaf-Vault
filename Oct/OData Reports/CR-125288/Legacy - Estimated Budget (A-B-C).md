# Legacy MVC Estimated Budget reports: A (Period), B (ByMonth), C (ByDay)

Paths: FRONT = `D:\Hadaf\AccFlex_Cloud_Front\accflex-erp\projects\general-accounting\src\app\modules\advanced-reports\`;
RPT = `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\`;
CTRL = `D:\Hadaf\AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\GeneralLedgerReports\AdvancedReportsController.cs`;
DB = `D:\Hadaf\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\`.

## Shared / cross-report facts (read first)
- Three separate datasets (`dsEstimatedBudgetPeriod`, `...ByMonth`, `...ByDay`), three different queries. Not one query with different grouping. A reads balances via TVFs and budget `IsFixedWeekly=1`; B and C read Acc_JournalAction directly and generate a calendar CTE.
- All three: Deviation = ABS(PeriodBalance) - ABS(Budget); DeviationPercent = 100 when Budget=0, else (Deviation*100)/Budget (divides by signed Budget, not ABS). All computed in SQL; zero C# arithmetic in any rpt*.cs.
- B and C "pivot" is cosmetic: pivot rows = AccountNo, AccountName, (NameMonth or DayDate); data area = PeriodBalance, Budget; the column area holds only an empty field (B: `xrPivotGridField1` with no FieldName; C: `ForPivotColHeader`, a dataset column with default 4 spaces that is NOT in the SELECT). Deviation / DeviationPercent / Mnth have no Area, so they are not printed. Net output = flat rows per (account, month or day) with 2 measures. No true cross-tab. Column headers, data headers, totals and grand totals are all switched off.
- Front: the form component of A (`PeriodEstimatedBudgetFormComponent`) is reused by the shell of B; C has its own form. Iframe URL = `${printUrl}AdvancedReports/<Action>?lang=<lang>&<query>` (FRONT `shared\advanced-report-data.service.ts:26-28`; lang `ar-EG` when null). Query = `QuerySerializeService.serialize` (`D:\Hadaf\AccFlex_Cloud_Front\accflex-erp\src\app\shared\services\query-serialize\query-serialize.service.ts:16-33`): `encodeURIComponent(key)=encodeURIComponent(value)` joined with `&`; arrays become comma strings; Date objects would go ISO, but the shells pre-format dates to `yyyy-MM-dd` strings.
- All routes: `advanced-reports.module.ts` lines 114-131, `canActivate: [AccflexAuthGuard, CanActivateRouteGuard]`, `data: { ModuleId: 362 }` for all three.
- Controller common: `ChangeThreadCulture(lang)`; `return View(REPORTS_ROOT_VIEW, report)`. Date range normalized in every rpt ctor: from = 00:00:00, to = 23:59:59.997.
- Ar/En: `ApiLoggedUser.IsArabic` picks `this.Name` = `rpt<X>` vs `rpt<X>ArEg`, `localizer1.ApplyArabic()` (plus `pivotLocalizer1.ApplyArabic()` for B/C) swaps captions; RTL set in BeforePrint. No .repx exists in the repo (see x.6).
- Drill-through: none in any of the three.
- DB: all SQL objects exist in Cloud_Database; NO stored procedures used (only table-valued functions and tables). Nothing named EstimatedBudget exists in the Cloud DB, so new TVFs / OData views are needed.

## Dependency objects (shared)
| Object | Kind | File | Used by |
|---|---|---|---|
| Acc_GetAccountBalanceBeforeDate | inline TVF | DB`Functions\Acc_GetAccountBalanceBeforeDate.sql` | A |
| Acc_GetAccountJournalActionsBeforeDate | inline TVF | DB`Functions\Acc_GetAccountJournalActionsBeforeDate.sql` | A |
| Acc_GetAccountJournalActionsBetweenDates | inline TVF | DB`Functions\Acc_GetAccountJournalActionsBetweenDates.sql` | A |
| Acc_ConvertIntListToTable | multi-statement TVF (`@list` NULL becomes '0') | DB`Functions\Acc_ConvertIntListToTable.sql` | A, B, C |
| Acc_Account, Acc_AccountBudget, Acc_Journal, Acc_JournalAction, Acc_SystemConfiguration, Acc_AccountBalance, Acc_AccountingSubPeriod | tables | DB`Tables\<name>.sql` | A-C (last two via TVF) |

```sql
Acc_GetAccountBalanceBeforeDate(@FromBalanceDate DATETIME, @CurrencyId int = null, @BranchList NVARCHAR(max) = NULL)
  RETURNS TABLE: AccountId, BranchId, Credit, Debit, PeriodCredit(0), PeriodDebit(0)
Acc_GetAccountJournalActionsBeforeDate(@FromBalanceDate DATETIME, @JournalRevise BIT=NULL, @JournalTypeList NVARCHAR(MAX)=NULL, @CostCenterList NVARCHAR(MAX)=NULL, @AccountList NVARCHAR(MAX)=NULL, @CurrencyId INT=NULL, @BranchList NVARCHAR(MAX)=NULL)
  RETURNS TABLE: AccountId, BranchId, CostCenterId, Credit, Debit, PeriodCredit(0), PeriodDebit(0), CreatedDate, JournalTypeId
Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT=NULL, @JournalTypeList NVARCHAR(MAX)=NULL, @CostCenterList NVARCHAR(MAX)=NULL, @AccountList NVARCHAR(MAX)=NULL, @CurrencyId INT=NULL, @BranchList NVARCHAR(MAX)=NULL)
  RETURNS TABLE: AccountId, CostCenterId, Credit(0), Debit(0), PeriodCredit, PeriodDebit, CreatedDate, BranchId, JournalTypeId
  (filter: j.CreatedDate BETWEEN from AND to, ja.Void=0, j.Void=0)
Acc_ConvertIntListToTable(@list nvarchar(MAX)) RETURNS @tbl TABLE (number int NOT NULL)
```
Acc_AccountBudget (DB`Tables\Acc_AccountBudget.sql`): AccountBugetId PK, AccontId (sic), AccountingSubPeriodId, BudgetValue MONEY, BranchId, CostCenterId, IsFixedMonthly, IsFixedWeekly, IsFixedDaily (bits).
Gotcha: B and C query Acc_JournalAction directly with `Void=0` on the action only (not `Acc_Journal.Void`); the TVFs used by A also check `Acc_Journal.Void=0`. Local amounts (CreditLocal/DebitLocal) everywhere.
Gotcha: A passes `@AccountList` as NULL (see A.3), so the account filter of A is dead in the legacy.

---
# A. EstimatedBudgetPeriodcs (route `advanced-reports/period-estimated-budget`)

## A.1 Angular
- Route: `advanced-reports.module.ts:114-119`, `PeriodEstimatedBudgetShellComponent`, ModuleId 362. Titles: `ADVANCEDREPORTS._EstimatedBudgetReports_` (header), `ADVANCEDREPORTS._PeriodEstimatedBudget_` (h6).
- Files: FRONT`period-estimated-budget\period-estimated-budget-shell\period-estimated-budget-shell.component.ts` (whenSubmit :54-77) and `period-estimated-budget-form\period-estimated-budget-form.component.{ts,html}` (FormGroup :79-86).

| Control | Type / source | Default | Validation | Serialized as |
|---|---|---|---|---|
| fromDate | dx-date-box dd/MM/yyyy, label COMMON._From_ | new Date(), then patched with getReportConfigs().ReportingStartDate (SharedDataService) | required; from<=to else toast COMMON._DateError_ (form.ts:143-165) | fromDate=yyyy-MM-dd (date-fns, shell:58) |
| toDate | dx-date-box | new Date(), patched with ReportingEndDate | same | toDate=yyyy-MM-dd |
| accountsIds | app-accounts-lookup (single account, emits e.value) | empty string | REQUIRED in shell (if (account) else toast COMMON._DataRequired_, shell:62-76) | accountsIds=id (ignored server side) |
| costCentersIds | app-cost-center-lookup | empty string | none (isShowCostCenterError never set true) | costCentersIds=csv or empty (empty becomes NULL in rpt) |
| branchesIds | app-branch-check-list, tree from branchDataService.getBranchListRelatedToCurrentUseTree() | empty string; populated with ALL branch Ids only after an account is picked (updateBranches, form.ts:110-126) | none in shell | branchesIds=csv |
| viewAll | dx-check-box BASICREPORTS._ShowAllAccounts_ | false | none | viewAll=true or false, becomes showZero |
- Query key order = FormGroup order: fromDate, toDate, costCentersIds, branchesIds, accountsIds, viewAll. Action name `EstimatedBudgetPeriodcs`.
- Shell ngOnInit removes `collapse` from `#accountLookup` and `#accountCheck` (account lookup and viewAll are visible only in A).

## A.2 Controller
CTRL:118-127
```csharp
[Route("mvc/AdvancedReports/EstimatedBudgetPeriodcs")]
public IActionResult EstimatedBudgetPeriodcs(string lang, DateTime fromDate, DateTime toDate, string costCentersIds,
    string branchesIds, string accountsIds, bool viewAll)
{ ChangeThreadCulture(lang);
  var report = new rptEstimatedBudgetPeriod(fromDate, toDate, costCentersIds, branchesIds, accountsIds, viewAll);
  return View(REPORTS_ROOT_VIEW, report); }
```
No hard-coded args at controller level.

## A.3 Code-behind (RPT`EstimatedBudgetPeriod\rptEstimatedBudgetPeriod.cs`)
- ctor :37-52: dates normalized; costCentersName = ApiLoggedUser.GetCostCenterNamesByCostCenterIdList(ids), or "all cost center is selected" / Arabic equivalent when empty; branchesName = GetBranchNamesBybranchIdList; accList = accountsIds; showZero = viewAll.
- BeforePrint :54-81: fills Acc_SystemConfiguration, then accountEstimatedBudgetTableAdapter.Fill(ds.AccountEstimatedBudget, ShowZero=showZero, FromBalanceDate=fromDate, CurrencyId=null, BranchList=branchesIds or null, JournalRevise=null, JournalTypeList=null, CostCenters=costCentersIds or null, AccountList=null (accList is never passed), ToBalanceDate=toDate). Order = xsd parameter order (xsd lines 126-134).
- Header labels: txtDateFrom/To dd/MM/yyyy, txtCostCenters, txtBranches. Rounding via moneyApproximate1.ApplyApproximate(ApiLoggedUser.GetApproximateNo()).
- No C# computation, no drill-through.

## A.4 Dataset dsEstimatedBudgetPeriod.xsd (RPT`EstimatedBudgetPeriod\dsEstimatedBudgetPeriod.xsd`)
Tables: AccountEstimatedBudget (adapter AccountEstimatedBudgetTableAdapter, Fill/GetData) and Acc_SystemConfiguration (SELECT Acc_SystemConfiguration.* FROM Acc_SystemConfiguration, plus generated insert/update/delete).
Columns AccountEstimatedBudget: AccountName string, AccountId int, OpenningCredit / OpenningDebit / PeriodCredit / PeriodDebit / OpenningBalance / PeriodBalance / Budget / Deviation / DeviationPercent decimal, AccountNo string(200).
Parameters: @ShowZero bit, @FromBalanceDate datetime, @CurrencyId int?, @BranchList nvarchar?, @JournalRevise bit?, @JournalTypeList nvarchar?, @CostCenters nvarchar?, @AccountList nvarchar?, @ToBalanceDate datetime.
Query (xsd lines 15-124):
```sql
WITH    AccountBalance ( AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit )
AS ( SELECT   Acc_Account.AccountId ,
    Acc_Account.ParentAccountId ,
    ISNULL(SUM(Balance.Credit), 0) AS Credit ,
    ISNULL(SUM(Balance.Debit), 0) AS Debit ,
    ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit ,
    ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
FROM     Acc_Account
    LEFT OUTER JOIN ( SELECT    AccountId ,
                                Credit ,
                                Debit ,
                                PeriodCredit ,
                                PeriodDebit
                      FROM      dbo.Acc_GetAccountBalanceBeforeDate(@FromBalanceDate,
                                          @CurrencyId,
                                          @BranchList) AS Acc_GetAccountBalanceBeforeDate_1
                      UNION ALL
                      SELECT    AccountId ,
                                Credit ,
                                Debit ,
                                PeriodCredit ,
                                PeriodDebit
                      FROM      dbo.Acc_GetAccountJournalActionsBeforeDate(@FromBalanceDate,
                                          @JournalRevise,
                                          @JournalTypeList,
                                          @CostCenters,
                                          @AccountList,
                                          @CurrencyId,
                                          @BranchList) AS Acc_GetAccountJournalActionsBeforeDate_1
                      UNION ALL
                      SELECT    AccountId ,
                                Credit ,
                                Debit ,
                                PeriodCredit ,
                                PeriodDebit
                      FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate,
                                          @ToBalanceDate,
                                          @JournalRevise,
                                          @JournalTypeList,
                                          @CostCenters,
                                          @AccountList,
                                          @CurrencyId,
                                          @BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1
                    ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
WHERE    ( Acc_Account.AccountId NOT IN (
      SELECT    ParentAccountId
      FROM      Acc_Account AS Acc_Account_2
      WHERE     ( ParentAccountId IS NOT NULL ) ) )
GROUP BY Acc_Account.AccountId ,
    Acc_Account.ParentAccountId
UNION ALL
SELECT   Acc_Account_1.AccountId ,
    Acc_Account_1.ParentAccountId ,
    ISNULL(AccountBalance_2.OpenningCredit, 0) AS Credit ,
    ISNULL(AccountBalance_2.OpenningDebit, 0) AS Debit ,
    ISNULL(AccountBalance_2.PeriodCredit, 0) AS PeriodCredit ,
    ISNULL(AccountBalance_2.PeriodDebit, 0) AS PeriodDebit
FROM     Acc_Account AS Acc_Account_1
    INNER JOIN AccountBalance AS AccountBalance_2 ON Acc_Account_1.AccountId = AccountBalance_2.ParentAccountId
),
Balances
AS ( SELECT   AccountId ,
    ISNULL(SUM(OpenningCredit), 0) AS OpenningCredit ,
    ISNULL(SUM(OpenningDebit), 0) AS OpenningDebit ,
    ISNULL(SUM(PeriodCredit), 0) AS PeriodCredit ,
    ISNULL(SUM(PeriodDebit), 0) AS PeriodDebit ,
    ISNULL(SUM(OpenningDebit), 0)
    - ISNULL(SUM(OpenningCredit), 0) AS OpenningBalance ,
    ISNULL(SUM(PeriodDebit), 0) - ISNULL(SUM(PeriodCredit),
                                         0) AS PeriodBalance
FROM     AccountBalance AS AccountBalance_1
WHERE    @AccountList IS NULL
    AND @AccountList IS NULL
    OR AccountId IN (
    SELECT  number
    FROM    dbo.Acc_ConvertIntListToTable(@AccountList) AS Acc_ConvertIntListToTable_1 )
GROUP BY AccountId
)
SELECT  Acc_Account.AccountNo ,
Acc_Account.AccountName ,
Balances.* ,
ISNULL(Budget.Budget, 0) AS Budget ,
ABS(Balances.PeriodBalance) - ABS(ISNULL(Budget.Budget, 0)) AS Deviation ,
CASE WHEN ABS(ISNULL(Budget.Budget, 0)) = 0 THEN 100
ELSE ( ( ABS(Balances.PeriodBalance)
      - ABS(ISNULL(Budget.Budget, 0)) ) * 100 )
  / Budget.Budget
END AS DeviationPercent
FROM    Balances
INNER JOIN Acc_Account ON Acc_Account.AccountId = Balances.AccountId
LEFT JOIN ( SELECT  Acc_AccountBudget.AccontId ,
            SUM(ISNULL(Acc_AccountBudget.BudgetValue, 0)) AS Budget
    FROM    Acc_AccountBudget
    WHERE   IsFixedWeekly = 1 
                   AND( @BranchList IS NULL
                  OR Acc_AccountBudget.BranchId IN (
                  SELECT    *
                  FROM      Acc_ConvertIntListToTable(@BranchList) )
                )
            AND ( ( @CostCenters IS NULL
                  OR Acc_AccountBudget.CostCenterId IN (
                  SELECT    *
                  FROM      Acc_ConvertIntListToTable(@CostCenters) )
                )
                )
    GROUP BY Acc_AccountBudget.AccontId
  ) AS Budget ON Budget.AccontId = Balances.AccountId
WHERE   @ShowZero = 1
OR Budget.Budget > 0
ORDER BY Acc_Account.AccountNo;
```
Semantics: leaf accounts get balances (opening via the Balance TVF + pre-period journals + in-period journals); a recursive CTE rolls them up to every ancestor, so parent accounts are included. Budget = SUM(BudgetValue) where IsFixedWeekly = 1 (verbatim, odd for a "period" report), filtered by branch and cost-center lists (budgets with NULL cost center are excluded when a list is supplied; with no list all cost centers are summed). Rows shown: @ShowZero = 1 OR Budget > 0. Budget is a flat figure, not prorated to the period. The first TVF gets the branch list but not the cost-center list (verbatim).
Dependencies: Acc_Account, Acc_AccountBudget, Acc_GetAccountBalanceBeforeDate, Acc_GetAccountJournalActionsBeforeDate, Acc_GetAccountJournalActionsBetweenDates, Acc_ConvertIntListToTable. No stored procedures.

## A.5 DB check
All present (shared table). No proc.

## A.6 Layout
No .repx for these reports exists under D:\Hadaf (35 .repx in total, none with "budget" in the name; D:\Hadaf\ReportLayout does not exist). The layout is code-designed. From rptEstimatedBudgetPeriod.Designer.cs: A4 portrait 827x1169, margins 7/9/10/12, DataMember AccountEstimatedBudget, DevExpress 19.1.
- ReportHeader: logo (Acc_SystemConfiguration.Logo), company name, address, tel, fax, email, title lblReportName ("Period Estimated Budget Report" / Arabic "تقرير الموازنة التقديرية خلال فترة"), labels From Date / To Date / Cost Centers / Branches.
- GroupHeader1 (no GroupFields, acts as column header, :605-625): row 1 = "Account" (w .354, over No+Name; ar الحساب) | "Balance" (.186; الرصيد) | "Estimated Budget" (.461; الموازنة التقديرية). Row 2 = "No." (.125; رقم) | "Name" (.229; اسم) | blank cell (.186, under Balance) | "Budget" (.180; الموازنه) | "Deviation" (.180; الانحراف) | "Deviation %" (.101; نسبة الانحراف).
- Detail (xrTable2 / xrTableRow3, :530-537), columns in order: AccountNo, AccountName, PeriodBalance {0:n2}, Budget {0:n2}, Deviation {0:n2}, DeviationPercent {0:n2}%. Opening/period debit/credit are fetched but not printed.
- No totals, no grouping, no pivot. PageFooter empty.

---
# B. EstimatedBudgetByMonth (route advanced-reports/estimated-budget-month)

## B.1 Angular
- Route advanced-reports.module.ts:120-125, ModuleId 362, EstimatedBudgetByMonthShellComponent; FRONT`estimated-budget-by-mounth\estimated-budget-by-month-shell\estimated-budget-by-month-shell.component.{ts,html}`. h6 title ADVANCEDREPORTS._PeriodEstimatedBudgetBymonth_.
- Uses the form component of A (same controls); the account lookup and the viewAll check are hidden by adding class collapse to #accountLookup / #accountCheck (shell:45-51).
- Controls used: fromDate, toDate (as A, yyyy-MM-dd), costCentersIds (cost-center lookup, optional), branches (branch-check-list). Submit (shell:62-89): delete obj.viewAll; delete obj.accountsIds; obj.branchesIds = FormRef.BranchLookupRef.BranchForm.value.BranchList; the required check is only if (branch) (truthy, so an empty array passes; the toast path is effectively for null only). Because the account lookup is hidden, updateBranches is never triggered, so branches rely on the initial value of the check-list.
- URL: .../AdvancedReports/EstimatedBudgetByMonth?lang=..&fromDate=..&toDate=..&costCentersIds=..&branchesIds=a,b,c
- from<=to validation happens in the shared form filter() (form.ts:143-165) before whenSubmit.

## B.2 Controller
CTRL:130-138
```csharp
[Route("mvc/AdvancedReports/EstimatedBudgetByMonth")]
public IActionResult EstimatedBudgetByMonth(string lang, DateTime fromDate, DateTime toDate, string costCentersIds, string branchesIds)
{ ChangeThreadCulture(lang); var report = new rptEstimatedBudgetByMonth(fromDate, toDate, costCentersIds, branchesIds); return View(REPORTS_ROOT_VIEW, report); }
```

## B.3 Code-behind (RPT`EstimatedBudgetByMonth\rptEstimatedBudgetByMonth.cs`)
- ctor :36-47: dates normalized; accList = null hard-coded; names resolved (the cost-center name call is not null-guarded, unlike A).
- BeforePrint :60-88: acc_EstimatedBudgetByMonthTableAdapter.Fill(ds.Acc_EstimatedBudgetByMonth, IsEnglish = !IsArabic, FromBalanceDate = fromdate, ToBalanceDate = todate, CostCenterList = ids or null, CurrencyId = null, BranchList = ids or null, AccountList = accList (null)).
- xrPivotGrid1_CustomFieldSort :90-101 sorts the NameMonth field by the Mnth int column (calendar order).
- Ar: pivot captions via pivotLocalizer1 (رقم الحساب, اسم الحساب, الموازنه, الرصيد, الشهر), title ar "تقرير الموازنة التقديرية بالشهر".
- No computation, no drill-through.

## B.4 Dataset dsEstimatedBudgetByMonth.xsd (RPT`EstimatedBudgetByMonth\dsEstimatedBudgetByMonth.xsd`)
Table Acc_EstimatedBudgetByMonth columns: AccountNo string(200), AccountName string, Budget decimal, PeriodBalance decimal, Mnth int, NameMonth string(7), Deviation decimal, DeviationPercent decimal, ForPivotColHeader string (default 4 spaces, not selected). Plus Acc_SystemConfiguration.
Parameters (order): @IsEnglish bit, @FromBalanceDate datetime, @ToBalanceDate datetime, @CostCenterList string?, @CurrencyId int?, @BranchList string?, @AccountList string?.
Query (xsd lines 440-584):
```sql
WITH
Balance ( AccountId, ParentAccountId, PeriodCredit, PeriodDebit , PeriodMonth )
AS
(

SELECT Acc_Account.AccountId ,
Acc_Account.ParentAccountId,
ISNULL(SUM(Actions.PeriodCredit), 0) AS PeriodCredit ,
ISNULL(SUM(Actions.PeriodDebit), 0) AS PeriodDebit,
PeriodMonth
FROM Acc_Account
INNER JOIN (
SELECT
Acc_JournalAction.AccountId,
ISNULL(Acc_JournalAction.CreditLocal, 0) AS PeriodCredit,
ISNULL(Acc_JournalAction.DebitLocal, 0) AS PeriodDebit,
MONTH(Acc_Journal.CreatedDate) AS PeriodMonth
FROM
Acc_JournalAction INNER JOIN
Acc_Journal ON Acc_JournalAction.JournalId = Acc_Journal.JournalId
WHERE 
( Acc_Journal.CreatedDate <= @ToBalanceDate) AND
( Acc_JournalAction.Void = 0 ) AND
( @CostCenterList IS NULL
AND @CostCenterList IS NULL
OR Acc_JournalAction.CostCenterId IN (
                                   SELECT number
FROM dbo.Acc_ConvertIntListToTable(@CostCenterList)
                                    AS Acc_ConvertIntListToTable_2 ) ) AND
( @CurrencyId IS NULL
OR Acc_JournalAction.CurrencyId = @CurrencyId )AND
( @BranchList IS NULL
AND @BranchList IS NULL
OR Acc_JournalAction.BranchId IN (
                                  SELECT number
FROM dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_2 )
					                                  ) ) AS Actions ON Actions.AccountId=Acc_Account.AccountId

WHERE    ( Acc_Account.AccountId NOT IN (
          SELECT ParentAccountId
FROM Acc_Account AS Acc_Account_2
WHERE     ( ParentAccountId IS NOT NULL ) ) )
GROUP BY Acc_Account.AccountId ,
        Acc_Account.ParentAccountId,Actions.PeriodMonth
) ,

Monthes
AS
(
SELECT CAST(@FromBalanceDate AS DATETIME) AS cte_start_date
UNION ALL
SELECT DATEADD(MONTH, 1, cte_start_date)
FROM Monthes
WHERE DATEADD(MONTH, 1, cte_start_date) <=CAST( @ToBalanceDate   AS DATETIME)
),
MonthesWithAccounts
AS
(
SELECT Month(Monthes.cte_start_date) AS Mnth, Acc_Account.AccountId
FROM Monthes CROSS JOIN Acc_Account
WHERE @AccountList IS NULL OR Acc_Account.AccountId IN (SELECT *
FROM Acc_ConvertIntListToTable(@AccountList))
)
					,
ExistedBalances
AS

(
SELECT Balance.AccountId, Balance.PeriodMonth,
ISNULL(SUM(PeriodCredit), 0) AS PeriodCredit ,
ISNULL(SUM(PeriodDebit), 0) AS PeriodDebit
FROM Balance
group by Balance.PeriodMonth,Balance.AccountId
) ,
Budget
AS
(
SELECT Acc_AccountBudget.AccontId, Acc_AccountBudget.AccountingSubPeriodId AS Mnth, IsFixedMonthly,
SUM(ISNULL(Acc_AccountBudget.BudgetValue,0)) AS Budget
FROM Acc_AccountBudget
WHERE 
(Acc_AccountBudget.AccountingSubPeriodId IS NULL OR Acc_AccountBudget.AccountingSubPeriodId BETWEEN MONTH(@FromBalanceDate) AND MONTH(@ToBalanceDate))
AND
(@BranchList IS NULL OR Acc_AccountBudget.BranchId IN (SELECT *
FROM Acc_ConvertIntListToTable(@BranchList)))
AND
((@CostCenterList IS NULL AND Acc_AccountBudget.CostCenterId IS NULL) OR Acc_AccountBudget.CostCenterId IN (SELECT *
FROM Acc_ConvertIntListToTable(@CostCenterList)))
AND (Acc_AccountBudget.IsFixedMonthly = 1 
OR ( IsFixedMonthly = 0 AND IsFixedDaily = 0 AND IsFixedWeekly = 0 ))

GROUP BY Acc_AccountBudget.AccontId,Acc_AccountBudget.AccountingSubPeriodId,IsFixedMonthly
),
Estimated
AS
(
SELECT
MonthesWithAccounts.AccountId, MonthesWithAccounts.Mnth,
ISNULL(PeriodDebit,0)  - ISNULL(PeriodCredit,0) AS PeriodBalance , ISNULL(Budget.Budget,0) Budget
FROM MonthesWithAccounts
INNER JOIN Budget ON (Budget.Mnth  = MonthesWithAccounts.Mnth 
AND Budget.AccontId  = MonthesWithAccounts.AccountId)
LEFT JOIN ExistedBalances ON ExistedBalances.PeriodMonth  = MonthesWithAccounts.Mnth AND ExistedBalances.AccountId  = MonthesWithAccounts.AccountId
)

select Acc_Account.AccountNo,
Acc_Account.AccountName,
Estimated.Mnth,
Budget,
Estimated.PeriodBalance,
CASE WHEN @IsEnglish=1 THEN
			case when Estimated.Mnth=1 then'Jan '
when Estimated.Mnth=2 then'Feb '
when Estimated.Mnth=3 then'Mar '
when Estimated.Mnth=4 then'Apr '
when Estimated.Mnth=5 then'May '
when Estimated.Mnth=6 then'Jun '
when Estimated.Mnth=7 then'Jul '
when Estimated.Mnth=8 then'Aug '
when Estimated.Mnth=9 then'Sep '
when Estimated.Mnth=10 then'Oct '
when Estimated.Mnth=11 then'Nov '
when Estimated.Mnth=12 then'Dec ' END
			ELSE
case when Estimated.Mnth=1 then N'يناير ' 
			when Estimated.Mnth=2 then N'فبراير '
when Estimated.Mnth=3 then N'مارس ' 
when Estimated.Mnth=4 then N'أبريل '
when Estimated.Mnth=5 then N'مايو ' 
when Estimated.Mnth=6 then N'يونيو ' 
when Estimated.Mnth=7 then N'يوليو '  
when Estimated.Mnth=8 then N'أغسطس ' 
when Estimated.Mnth=9 then N'سبتمبر ' 
when Estimated.Mnth=10 then N'أكتوبر '
when Estimated.Mnth=11 then N'نوفمبر ' 
when Estimated.Mnth=12 then N'ديسمبر ' END
			END AS NameMonth ,
ABS(Estimated.PeriodBalance )-ABS(ISNULL(Estimated.Budget,0)) AS Deviation,
CASE WHEN ABS(ISNULL(Estimated.Budget,0))=0 THEN 100 
ELSE ((ABS(Estimated.PeriodBalance)-ABS(ISNULL(Estimated.Budget,0)))*100)/Estimated.Budget END AS  DeviationPercent

from Estimated inner JOIN Acc_Account ON Acc_Account.AccountId=Estimated.AccountId AND @IsEnglish = @IsEnglish
order by AccountNo


```
Semantics and gotchas: no lower date bound on journals (CreatedDate <= @ToBalanceDate only) and the grouping key is MONTH() alone, so a multi-year range or older history folds into the same month number; Budget is keyed by AccountingSubPeriodId used as a calendar month number (BETWEEN MONTH(from) AND MONTH(to)); an account appears only if it has a budget row for that month (INNER JOIN Budget), and budget rows with NULL sub-period never match a month; budgets taken: IsFixedMonthly=1, or none of the three flags set; cost-center filter: when the list is NULL only budgets with CostCenterId NULL. Month names Jan..Dec or يناير..ديسمبر (trailing space) chosen by @IsEnglish. Leaf accounts only (no parent rollup).
Dependencies: Acc_Account, Acc_AccountBudget, Acc_Journal, Acc_JournalAction, Acc_ConvertIntListToTable. No procs.

## B.5 DB check
All present. Nothing named EstimatedBudget in the DB.

## B.6 Layout
rptEstimatedBudgetByMonth.Designer.cs: A4 landscape (PageWidth 1169, Landscape = true), margins 5/7/10/24; ReportHeader with the same company block and title "Monthly Estimated Budget Report" (:145); Detail band holds a single xrPivotGrid1 (1157x83, DataMember Acc_EstimatedBudgetByMonth):
- Row area in order: AccountNo (AreaIndex 0, "Account No"), AccountName (1, "Account Name", Descending), NameMonth (2, "Month", custom sort by Mnth).
- Data area: PeriodBalance (idx 0, "Period Balance", n2), Budget (idx 1, "Budget", n2).
- Column area: only an empty xrPivotGridField1. Fields without area (hidden): Mnth, Deviation, DeviationPercent.
- Column headers, data headers, totals and grand totals are all off. Cell font Tahoma 8, centered. Arabic: RightToLeft on report and pivot.

---
# C. EstimatedBudgetByDay (route advanced-reports/estimated-budget-day)

## C.1 Angular
- Route advanced-reports.module.ts:126-131, ModuleId 362, EstimatedBudgetByDayShellComponent. FRONT`estimated-budget-by-day\estimated-budget-by-day-shell\...component.ts` (whenSubmit :49-58) and `estimated-budget-by-day-form\...component.{ts,html}`. h6 ADVANCEDREPORTS._PeriodEstimatedBudgetByday_.

| Control | Type | Default | Validation | Serialized |
|---|---|---|---|---|
| fromDate | dx-date-box | new Date(); the getReportConfigs patch sets fromDate = ReportingStartDate but writes a misspelled key toDat (form.ts:44-46), so toDate stays today | from>to or empty gives toast COMMON._DateError_ | fromDate=yyyy-MM-dd (form.ts:83-84) |
| toDate | dx-date-box | today | same | toDate=yyyy-MM-dd |
| costCentersIds | app-cost-center-lookup | undefined | optional; key deleted from the payload when falsy (form.ts:96) | costCentersIds=csv, or omitted |
| branchesIds | app-branch-check-list | patched from BranchLookupRef.BranchesForInit (form.ts:71-74) | required (no branches gives toast + error) | branchesIds=csv |
- Payload = FilterForm.value emitted as is: keys fromDate, toDate, costCentersIds (optional), branchesIds. The shell hides the account lookup and check with class hide.
- URL: .../AdvancedReports/EstimatedBudgetByDay?lang=..&fromDate=..&toDate=..&costCentersIds=..&branchesIds=..

## C.2 Controller
CTRL:141-149
```csharp
[Route("mvc/AdvancedReports/EstimatedBudgetByDay")]
public IActionResult EstimatedBudgetByDay(string lang, DateTime fromDate, DateTime toDate, string costCentersIds, string branchesIds)
{ ChangeThreadCulture(lang); var report = new rptEstimatedBudgetByDay(fromDate, toDate, costCentersIds, branchesIds); return View(REPORTS_ROOT_VIEW, report); }
```

## C.3 Code-behind (RPT`EstimatedBudgetByDay\rptEstimatedBudgetByDay.cs`)
- ctor :37-48: as B; accList = null.
- The BeforePrint handler is named rptEstimatedBudgetByMonth_BeforePrint (:61, copy-paste name). It sets ClearBeforeFill = true and ds.EnforceConstraints = false, fills the config, then Fill(ds.Acc_EstimatedBudgetByDay, fromdate, todate, CostCenterList = ids or null, CurrencyId = null, BranchList = ids or null, AccountList = accList (null)). No IsEnglish parameter (the day is a date shown dd/MM/yyyy).
- xrPivotGrid1_CustomFieldSort :89-100 is dead code (never subscribed; refers to NameMonth / Mnth which do not exist in this dataset).
- Ar captions: رقم الحساب, اسم الحساب, الموازنه, الرصيد, اليوم; title ar "تقرير الموازنة التقديرية باليوم". One label translation (itemTranslation16) maps a date label to "الي تاريخ :", the same text as the To label (likely a bug for From).
- No computation, no drill-through.

## C.4 Dataset dsEstimatedBudgetByDay.xsd (RPT`EstimatedBudgetByDay\dsEstimatedBudgetByDay.xsd`)
Table Acc_EstimatedBudgetByDay columns: AccountNo string(200), AccountName string, Budget decimal, ForPivotColHeader string (default 4 spaces, not selected), DayDate dateTime, PeriodBalance decimal, Deviation decimal, DeviationPercent decimal. Plus Acc_SystemConfiguration.
Parameters (order): @FromBalanceDate datetime, @ToBalanceDate datetime, @CostCenterList string?, @CurrencyId int?, @BranchList string?, @AccountList string?.
Query (xsd lines 440-555):
```sql
WITH    Balance ( AccountId, ParentAccountId, PeriodCredit, PeriodDebit, DayDate )
AS ( SELECT   Acc_Account.AccountId ,
    Acc_Account.ParentAccountId ,
    ISNULL(SUM(Actions.PeriodCredit), 0) AS PeriodCredit ,
    ISNULL(SUM(Actions.PeriodDebit), 0) AS PeriodDebit ,
    DayDate
FROM     Acc_Account
    INNER JOIN ( SELECT Acc_JournalAction.AccountId ,
                        ISNULL(Acc_JournalAction.CreditLocal,
                               0) AS PeriodCredit ,
                        ISNULL(Acc_JournalAction.DebitLocal,
                               0) AS PeriodDebit ,
                        CAST(Acc_Journal.CreatedDate AS DATE) AS DayDate
                 FROM   Acc_JournalAction
                        INNER JOIN Acc_Journal ON Acc_JournalAction.JournalId = Acc_Journal.JournalId
                 WHERE  ( Acc_Journal.CreatedDate >= @FromBalanceDate )
                        AND ( Acc_Journal.CreatedDate <= @ToBalanceDate )
                        AND ( Acc_JournalAction.Void = 0 )
                        AND ( @CostCenterList IS NULL
                              AND @CostCenterList IS NULL
                              OR Acc_JournalAction.CostCenterId IN (
                              SELECT    number
                              FROM      dbo.Acc_ConvertIntListToTable(@CostCenterList)
                                        AS Acc_ConvertIntListToTable_2 )
                            )
                        AND ( @CurrencyId IS NULL
                              OR Acc_JournalAction.CurrencyId = @CurrencyId
                            )
                        AND ( @BranchList IS NULL
                              AND @BranchList IS NULL
                              OR Acc_JournalAction.BranchId IN (
                              SELECT    number
                              FROM      dbo.Acc_ConvertIntListToTable(@BranchList)
                                        AS Acc_ConvertIntListToTable_2 )
                            )
               ) AS Actions ON Actions.AccountId = Acc_Account.AccountId
WHERE    ( Acc_Account.AccountId NOT IN (
      SELECT    ParentAccountId
      FROM      Acc_Account AS Acc_Account_2
      WHERE     ( ParentAccountId IS NOT NULL ) ) )
GROUP BY Acc_Account.AccountId ,
    Acc_Account.ParentAccountId ,
    Actions.DayDate

),
Monthes
AS ( SELECT   CAST(@FromBalanceDate AS DATETIME) AS cte_start_date
UNION ALL
SELECT   DATEADD(DAY, 1, cte_start_date)
FROM     Monthes
WHERE    DATEADD(DAY, 1, cte_start_date) <= CAST(@ToBalanceDate AS DATETIME)
),
MonthesWithAccounts
AS ( SELECT   CAST(Monthes.cte_start_date AS DATE) AS DayDate ,
    Acc_Account.AccountId
FROM     Monthes
    CROSS JOIN Acc_Account
WHERE    @AccountList IS NULL
    OR Acc_Account.AccountId IN (
    SELECT  *
    FROM    Acc_ConvertIntListToTable(@AccountList) )
),
ExistedBalances
AS ( SELECT   Balance.AccountId ,
    Balance.DayDate ,
    ISNULL(SUM(PeriodCredit), 0) AS PeriodCredit ,
    ISNULL(SUM(PeriodDebit), 0) AS PeriodDebit
FROM     Balance
GROUP BY Balance.DayDate ,
    Balance.AccountId
),
Budget
AS ( SELECT   Acc_AccountBudget.AccontId ,
    SUM(ISNULL(Acc_AccountBudget.BudgetValue, 0)) AS Budget
FROM     Acc_AccountBudget
WHERE    ( Acc_AccountBudget.IsFixedDaily = 1 )
    AND ( @BranchList IS NULL
          OR Acc_AccountBudget.BranchId IN (
          SELECT    *
          FROM      Acc_ConvertIntListToTable(@BranchList) )
        )
    AND ( ( @CostCenterList IS NULL
            OR Acc_AccountBudget.CostCenterId IS NULL
          )
          OR Acc_AccountBudget.CostCenterId IN (
          SELECT    *
          FROM      Acc_ConvertIntListToTable(@CostCenterList) )
        )
						AND dbo.Acc_AccountBudget.IsFixedDaily = 1
GROUP BY Acc_AccountBudget.AccontId
),
Estimated
AS ( SELECT   MonthesWithAccounts.AccountId ,
    MonthesWithAccounts.DayDate ,
    ISNULL(PeriodDebit, 0) - ISNULL(PeriodCredit, 0) AS PeriodBalance ,
    ISNULL(Budget.Budget, 0) Budget
FROM     MonthesWithAccounts
    INNER JOIN Budget ON Budget.AccontId = MonthesWithAccounts.AccountId
    LEFT JOIN ExistedBalances ON ExistedBalances.DayDate = MonthesWithAccounts.DayDate
                                 AND ExistedBalances.AccountId = MonthesWithAccounts.AccountId
)
SELECT  Acc_Account.AccountNo ,
Acc_Account.AccountName ,
Estimated.DayDate ,
Budget ,
Estimated.PeriodBalance ,
ABS(Estimated.PeriodBalance) - ABS(ISNULL(Estimated.Budget, 0)) AS Deviation ,
CASE WHEN ABS(ISNULL(Estimated.Budget, 0)) = 0 THEN 100
ELSE ( ( ABS(Estimated.PeriodBalance)
      - ABS(ISNULL(Estimated.Budget, 0)) ) * 100 )
  / Estimated.Budget
END AS DeviationPercent
FROM    Estimated
INNER JOIN Acc_Account ON Acc_Account.AccountId = Estimated.AccountId
ORDER BY AccountNo
OPTION  ( MAXRECURSION 0 );
```
Semantics and gotchas: day calendar via recursive CTE with OPTION (MAXRECURSION 0); cross join of every day with every account (filtered by @AccountList, which is NULL), INNER JOIN Budget keeps only accounts having an IsFixedDaily=1 budget; Budget is the SUM over all matching rows, NOT prorated or per day: the same total repeats on every day row (and DeviationPercent divides by it). Cost-center filter: @CostCenterList IS NULL OR Budget.CostCenterId IS NULL OR IN (list), more permissive than B. Journal date filter is >= from AND <= to (bounded, unlike B). Leaf accounts only. Days with no activity show PeriodBalance 0.
Dependencies: same as B. No procs.

## C.5 DB check
All present.

## C.6 Layout
rptEstimatedBudgetByDay.Designer.cs: A4 landscape 1169, margins 5/7/10/24; header title "Daily Estimated Budget Report" (:144) with Arabic hard-coded Tel/Fax/Email labels; Detail has Expanded = false with a single xrPivotGrid1 (1151x81):
- Row area: AccountNo (0, width 150), AccountName (1, width 150, Descending), DayDate (2, "Day", format dd/MM/yyyy).
- Data area: PeriodBalance (0, width 200, empty text "0"), Budget (1, width 200, empty "0"). Deviation (n2, caption "الانحراف") and DeviationPercent have no area (hidden).
- Column area: ForPivotColHeader only. All headers, totals, grand totals off.

---
# Not found / caveats
- .repx: none exist for these reports; layouts are code-designed, Ar/En switched by report Name + localizer. D:\Hadaf\ReportLayout is absent.
- Not read: the lookup components (accounts-lookup, cost-center-lookup, branch-check-list) and the APIs they call; ApiLoggedUser name-resolution bodies; the WinForms twins frmEstimatedBudget*.
- Related but not in scope: an EstimatedBudgetByWeek dataset exists in RPT with no web route found.
