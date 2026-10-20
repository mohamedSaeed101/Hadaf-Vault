# Legacy dissection: Income Statement Period / Branch / Cost Center comparison (CR 125289)

Reports 7, 8, 9 of the MVC -> OData migration. Read-only dissection. Source: `D:\Hadaf\AccFlex_ERP` (main checkout is cr94062; `git diff --stat origin/Master_Stable` on the controller, `Reports\IncomeStatmentActivityDetail\` and `Reports\IncomeStatmentPerMonth\` is EMPTY, so Master_Stable equals what was read).

SQL below is copied VERBATIM from the typed-DataSet `.xsd` `SelectCommand/CommandText` (whitespace preserved).

## Common facts
- iframe URL: `{printUrl}FinancialReports/{report}?lang={lang}&{query}` (`financial-reports-data.service.ts` `initializeIFrame`). Controller: `AccFlexContainer\AccFlexContainer.MVC\Controllers\GeneralLedgerReports\FinancialReportsController.cs`, route attr `mvc/FinancialReports/<Action>`.
- Query built by `QuerySerializeService.serialize` (`accflex-erp\src\app\shared\services\query-serialize\`): each form value is `encodeURIComponent(key)=encodeURIComponent(value)`; an array becomes a comma list (`1,2,3`); empty array or "" becomes `key=` (MVC binds "" to null).
- Dates sent as `yyyy-MM-dd`; shell requires both; form blocks fromDate > toDate.
- Common params: `lang`, `fromDate`, `toDate`, `revised` (radio: 1 -> `true`, 2 -> `false`, else `' '` or null -> MVC null = both), `journalTypes` (comma list from the journal-type checklist).
- Window used by every rpt: `_fromDate = fromDate 00:00:00`, `_toDate = toDate 23:59:59.997`.
- Revised label: null "Both Journals Revised & NOT Revised"; true "All Journals Revised"; false "All Journals NOT Revised" (Arabic variants in rpt).
- `moneyApproximate1.ApplyApproximate(ApiLoggedUser.GetApproximateNo())` only rounds displayed money in the layout (reports 7/8); SQL values are not rounded.
- `AccountTypeId` (`GeneralLedger.Reports\Helper\AccAccountTypeList.cs`): 1 Operating_income, 2 Operating_expenses, 3 Other_income, 4 Administrative_General_Expenses, 5 Other_expenses, 6 Long_term_assets, 7 Current_Assets, 8 Current_Liabilities, 9 Equity, 10 Long_term_liabilities, 11 Other_Type, 12 Profit_Loss, 13 Taxes, 14 Main_Accounts. Cloud seed (`Scripts\ReferenceDataScripts\0001_GL_ReferenceDate.sql`) sets `AccountTypeNature = 1` for types 1,2,3,4,5,13,17 (17 = Unearned Revenue); `Acc_IncomeStatment` keeps only nature 1.
- `Acc_IncomeStatmentMainItem` seed: 1 Operating income, 2 Operating expenses, 3 Other income, 4 Administrative/General Expenses, 5 Other expenses, 6 Taxes.
- Generated adapters: `JournalTypeList` is a NON-nullable param; `journalTypes == null` throws `ArgumentNullException("JournalTypeList")` in every Fill/FillByPeriod used here. The UI always sends a list.

---

## 7. IncomeStatementActivityDetail (cost-center income statement, period comparison)

### 7.1 Route and params
- Angular route `financial-reports/income-statment-activity-detail-report` (core/routes.ts line 810, id `6_1_3_1`, "Comparison Cost Center Income Statement Period", Arabic menu: قائمة الدخل بمركز التكلفة مقارن فترات), ModuleId 267, route query param `report=IncomeStatementActivityDetail`.
- `financial-reports.module.ts` line 121 -> `BrifIncomeStatmentCostcenterReportShellComponent` (shared with `income-statment-costcenter-report`; `changeReportLabel` shows the activity label for this `report`). Folder `modules\financial-reports\brif-income-statment-costcenter-report\`.
- FilterForm: `fromDate` (req), `toDate` (req), `revised`, `journalTypes`, `costCenterIds` (`Validators.required`, cost-center checklist). Shell `whenSubmit`: `report = this.report || 'CostCenterIncomeStatement'`.
- iframe: `FinancialReports/IncomeStatementActivityDetail?lang=..&fromDate=yyyy-MM-dd&toDate=yyyy-MM-dd&revised=true|false|%20&journalTypes=1,2,..&costCenterIds=3,4,..`

### 7.2 MVC action
```csharp
[Route("mvc/FinancialReports/IncomeStatementActivityDetail")]
public IActionResult IncomeStatementActivityDetail(string lang, DateTime fromDate, DateTime toDate, bool? revised, string journalTypes, string costCenterIds)
{
    ChangeThreadCulture(lang);
    var report = new rptIncomeStatmentActivityDetail(fromDate, toDate, revised, journalTypes, costCenterIds);
    return View(REPORTS_ROOT_VIEW, report);
}
```
Rpt: `GeneralAccounting\GeneralLedger.Reports\Reports\IncomeStatmentActivityDetail\rptIncomeStatmentActivityDetail.cs` (+ Designer); dataset `dsIncomeStatmentActivity.xsd` (shared with report 8).


### 7.3 rpt computations (BeforePrint `rptIncomeStatemet_BeforePrint`)
- Fills: `Acc_SystemConfiguration.Fill`; `ActivityIncome.Fill(t, _fromDate, _toDate, revised, journalTypes, costCenterList, null)`; `Acc_IncomeStatment.Fill(t, _fromDate, _toDate, revised, journalTypes, costCenterList, null)` => @FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, @BranchList(=NULL).
- Labels: `clPeriod` "from dd/MM/yy to dd/MM/yy". `seconds = (int)(_fromDate - _toDate).TotalSeconds` (negative, truncated, e.g. -86399 for one day); `clLastPeriod` = `_fromDate.AddSeconds(seconds)` .. `_toDate.AddSeconds(seconds)` (label only); `clLastYear` = `AddYears(-1)` on both. `lblCostCenter` = cost-center names (`SELECT CostCenterName FROM dbo.Acc_CostCenter WHERE (@Ids is null or CostCenterId IN (SELECT * FROM dbo.Acc_ConvertIntListToTable(@Ids)))`), "" if null.
- `Detail1_BeforePrint` (band over `Acc_IncomeStatment`): `e.Cancel = true` when `AccountTypeId` = 1 (Operating_income) or 2 (Operating_expenses). So the bottom type-total block prints only types 3,4,5,13,17.
- Arabic: `localizer1.ApplyArabic()`, RTL, `lblTypeName` rebinds to `ActivityIncome.AccountTypeNameArabic`, `lblAccTypeNameTot` to `Acc_IncomeStatment.AccountTypeNameArabic`.
- Row formulas (in SQL, 7.4): `PeriodBalance/LastPeriodBalance/YearToPeriodBalance` = ABS(net Debit - Credit); `CalculatePeriod/LastPeriod/YearToPeriodBalance` = -1*ABS(..) when `AccountTypeId = 2` else ABS(..). In `Acc_IncomeStatment` the `Calculated*` columns negate types (2,4,5,13).
- Report summaries (Designer):
  - `GroupFooter4` per `CostCenterNo` group (label "GOP"): `xrTableCell8/6/14` = XRSummary Sum, `Running=Group` of `CalculatePeriodBalance / CalculateLastPeriodBalance / CalculateYearToPeriodBalance` => income minus operating expenses per cost center. `xrTableCell10/30/25` = XRSummary `Func=Percentage`, `Running=Report`, `{0:0%}` on `PeriodBalance / LastPeriodBalance / YearToPeriodBalance` (DevExpress percentage-of-report-total semantics: VERIFY on a real run).
  - `GroupFooter1` (report level, "Total CostCenter GOP"): `clmTotalProfit`, `xrTableCell12`, `xrTableCell13` = Sum, `Running=Report`, `{0:n2}` of `ActivityIncome.Calculate*`.
  - `GroupFooter2` ("Net Profit"): `xrTableCell70/71/72` = Sum, `Running=Report` of `Acc_IncomeStatment.Calculated*` over all nature-1 types, independent of cost center membership. UNVERIFIED: whether rows cancelled by `Detail1_BeforePrint` (types 1,2) are counted in that summary; check on a real run before fixing the Net Profit formula (arithmetic intent: 1+3-2-4-5-13).
  - Sorts: `Detail2` and `Detail1` by `AccountTypeId` asc; `GroupHeader1` by `CostCenterNo` asc; `Detail` band sorts by non-existent `SubItemBalance` (no effect).

### 7.4 SQL VERBATIM (dsIncomeStatmentActivity.xsd; CommandType Text, Fill/GetData)

#### 7.4.a TableAdapter `ActivityIncome` (per cost center x account type 1,2)

```sql
 WITH    AccountBalance ( AccountId, BusinessActivityId, AccountTypeId, PeriodBalance, LastPeriodBalance, LastYearPeriodBalance,CostCenterId)
          AS ( SELECT   Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.PeriodDebit), 0)
                        - ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodBalance,
                        ISNULL(SUM(Balance.LastDebit), 0)
                        - ISNULL(SUM(Balance.LastCredit), 0) AS LastPeriodBalance,
                        ISNULL(SUM(Balance.LastYearPeriodDebit), 0)
                        - ISNULL(SUM(Balance.LastYearPeriodCredit), 0) AS LastYearPeriodCredit,
						CostCenterId
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId AS AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    PeriodCredit AS PeriodCredit,
                                                    PeriodDebit AS PeriodDebit,
                                                    0 AS LastYearPeriodCredit,
                                                    0 AS LastYearPeriodDebit,
                                                    CostCenterId
										  FROM      Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    PeriodCredit AS LastCredit,
                                                    PeriodDebit AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS LastYearPeriodCredit,
                                                    0 AS LastYearPeriodDebit,
													CostCenterId
                                          FROM      Acc_GetAccountJournalActionsBetweenDates(DATEADD(SECOND, -1 -DATEDIFF(SECOND, @FromBalanceDate, @ToBalanceDate), @FromBalanceDate), DATEADD(SECOND, -1 -DATEDIFF(SECOND, @FromBalanceDate, @ToBalanceDate), @ToBalanceDate), @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_2
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    PeriodCredit AS LastYearPeriodCredit,
                                                    PeriodDebit AS LastYearPeriodDebit,
													CostCenterId
                                          FROM      Acc_GetAccountJournalActionsBetweenDates(DATEADD(Year, -1, @FromBalanceDate), DATEADD(Year, -1, @ToBalanceDate), @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_3
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        AccountTypeId,CostCenterId
             )
    SELECT  Acc_CostCenter.CostCenterNo,
            Acc_CostCenter.CostCenterName,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic,
            abs (ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) AS PeriodBalance,
            abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)) AS LastPeriodBalance,
            abs (ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)) AS YearToPeriodBalance,
			Acc_AccountType.AccountTypeId,
            case when Acc_AccountType.AccountTypeId = 2
			then (-1*abs(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0))) 
			else 
			abs (ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) end as CalculatePeriodBalance,
			case when Acc_AccountType.AccountTypeId = 2
			then (-1* abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)))
			else  abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)) end AS CalculateLastPeriodBalance,
			case when Acc_AccountType.AccountTypeId =2 
			then (-1 * abs (ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)))
			else  abs (ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)) end as CalculateYearToPeriodBalance
    FROM    AccountBalance AS AccountBalance_1
            inner JOIN dbo.Acc_CostCenter ON Acc_CostCenter.CostCenterId = AccountBalance_1.CostCenterId
            INNER JOIN dbo.Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
	where Acc_AccountType.AccountTypeId in (1,2)
    GROUP BY Acc_CostCenter.CostCenterNo,
             Acc_CostCenter.CostCenterName,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic
			,Acc_AccountType.AccountTypeId
    ORDER BY Acc_CostCenter.CostCenterNo  ,
	         Acc_AccountType.AccountTypeId
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 0`
- `@CostCenterList String None 0 Nullable`
- `@BranchList String None 0 Nullable`


#### 7.4.b TableAdapter `Acc_IncomeStatment` (per account type, nature = 1; also used by report 8)

```sql
 WITH    AccountBalance ( AccountId, BusinessActivityId, AccountTypeId, PeriodBalance, LastPeriodBalance, LastYearPeriodBalance )
          AS ( SELECT   Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.PeriodDebit), 0)
                        - ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodBalance,
                        ISNULL(SUM(Balance.LastDebit), 0)
                        - ISNULL(SUM(Balance.LastCredit), 0) AS LastPeriodBalance,
                        ISNULL(SUM(Balance.LastYearPeriodCredit), 0)
                        - ISNULL(SUM(Balance.LastYearPeriodCredit), 0) AS LastYearPeriodCredit
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId AS AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    PeriodCredit AS PeriodCredit,
                                                    PeriodDebit AS PeriodDebit,
                                                    0 AS LastYearPeriodCredit,
                                                    0 AS LastYearPeriodDebit
                                          FROM      Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    PeriodCredit AS LastCredit,
                                                    PeriodDebit AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS LastYearPeriodCredit,
                                                    0 AS LastYearPeriodDebit
                                          FROM      Acc_GetAccountJournalActionsBetweenDates(DATEADD(SECOND, -1 -DATEDIFF(SECOND, @FromBalanceDate, @ToBalanceDate), @FromBalanceDate), DATEADD(SECOND, -1 -DATEDIFF(SECOND, @FromBalanceDate, @ToBalanceDate), @ToBalanceDate), @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_2
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    PeriodCredit AS LastYearPeriodCredit,
                                                    PeriodDebit AS LastYearPeriodDebit
                                          FROM      Acc_GetAccountJournalActionsBetweenDates(DATEADD(Year, -1, @FromBalanceDate), DATEADD(Year, -1, @ToBalanceDate), @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_3
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        AccountTypeId
             )
    SELECT  Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic,
           ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) AS PeriodBalance,
            abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)) AS LastPeriodBalance,
            abs(ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)) AS YearToPeriodBalance,
           
		    case when Acc_AccountType.AccountTypeId in (2,4,5,13)
			 then (-1*ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)))
			 else ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) end as CalculatedPeriodBalance,
			
			 case when Acc_AccountType.AccountTypeId in (2,4,5,13)
			 then (-1*abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0))) 
			 else abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)) end  as CalculatedLastPeriodBalance,
			 
			 case when Acc_AccountType.AccountTypeId in (2,4,5,13)
			 then (-1*  abs(ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)))
			 else  abs(ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)) end as CalculatedYearToPeriodBalance
    
    FROM    AccountBalance AS AccountBalance_1
            RIGHT OUTER JOIN dbo.Acc_Account ON AccountBalance_1.AccountId = dbo.Acc_Account.AccountId
            RIGHT OUTER JOIN dbo.Acc_AccountType ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
    WHERE   Acc_AccountType.AccountTypeNature = 1
    GROUP BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic
    ORDER BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 0`
- `@CostCenterList String None 0 Nullable`
- `@BranchList String None 0 Nullable`


#### 7.4.c TableAdapter `Acc_SystemConfiguration` (company header)

```sql
 SELECT Acc_SystemConfiguration.*
FROM  Acc_SystemConfiguration
```
Parameters (name, DbType, ProviderType, Size, nullable):



Dataset columns: ActivityIncome(AccountTypeName, AccountTypeNameArabic, PeriodBalance, LastPeriodBalance, YearToPeriodBalance, CostCenterNo, CostCenterName, AccountTypeId int, CalculatePeriodBalance, CalculateLastPeriodBalance, CalculateYearToPeriodBalance); Acc_IncomeStatment(AccountTypeId int, AccountTypeName, AccountTypeNameArabic, PeriodBalance, LastPeriodBalance, YearToPeriodBalance, CalculatedPeriodBalance, CalculatedLastPeriodBalance, CalculatedYearToPeriodBalance). Money columns are xs:decimal.

### 7.5 Dependencies and cloud existence
Checked under `D:\Hadaf\worktrees\cr125289\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\`.
| Object | Cloud file | In .sqlproj |
|---|---|---|
| `dbo.Acc_GetAccountJournalActionsBetweenDates` (8 params; returns AccountId, CostCenterId, Credit=0, Debit=0, PeriodCredit, PeriodDebit, CreatedDate, BranchId, JournalTypeId) | dbo\Functions | yes |
| `dbo.Acc_ConvertIntListToTable` (used inside the TVF) | dbo\Functions | yes |
| `Acc_Account` (AccountId, ParentAccountId, AccountTypeId, BusinessActivityId, IncomeStatment) | dbo\Tables | yes |
| `Acc_AccountType` (AccountTypeName, AccountTypeNameArabic, AccountTypeNature) | dbo\Tables | yes |
| `Acc_CostCenter` (CostCenterNo, CostCenterName) | dbo\Tables | yes |
| `Acc_SystemConfiguration`, `Acc_Journal`, `Acc_JournalAction`, `Acc_BusinessActivity` | dbo\Tables | yes |

All exist; nothing missing. The cloud TVF is a re-implementation: `j.CreatedDate BETWEEN @From AND @To`, `ja.Void = 0 AND j.Void = 0`, `@JournalRevise` on `ja.Revised`, list params via LEFT JOIN with NULL = all, `PeriodDebit/PeriodCredit = DebitLocal/CreditLocal`, Credit/Debit constant 0. (Several sqlproj Build Include lines are duplicated, harmless.) Non-SQL helpers: `ApiLoggedUser.GetCostCenterNamesByCostCenterIdList`, `GetApproximateNo`.


### 7.6 Layout structure
- Page 2159 x 2794 (0.1 mm units, Dpi 254), content tables 2059 wide. Header: logo + company name/address/tel/fax/email from `Acc_SystemConfiguration`, title "Cost Center Income Statement Detail" (AR: قائمه الدخل بمركز التكلفة مقارن فترات), From/To dates, `lblRevised`, `lblCostCenter`; column headers Description | Period Balance (`clPeriod`) | Last Period Balance (`clLastPeriod`) | Last Year Balance (`clLastYear`). Footer: page no, print date, "PC: <machine>", "Powered By: www.AccFlex.com".
- Bands: `Detail` (empty) -> `DetailReport1` (DataMember `ActivityIncome`, Level 0): `GroupHeader1` (by `CostCenterNo`, prints cost-center name), `Detail2` (one row per account type: name, PeriodBalance, LastPeriodBalance, YearToPeriodBalance), `GroupFooter4` (GOP + percentages), `GroupFooter1` (total GOP). -> `DetailReport` (DataMember `Acc_IncomeStatment`, Level 1): `Detail1` (one row per account type, hidden for types 1,2), `GroupFooter2` (Net Profit).
- No cross-tab. `xrTableCell2` binds `ActivityIncome.BusinessActivity`, which is NOT a dataset column (blank).

### 7.7 Quirks to reproduce (or consciously fix)
1. SQL last-period window = both dates shifted by `-(1 + DATEDIFF(SECOND,@From,@To))` seconds (one-day period -> previous day). The C# label uses `(from - to)` truncated, so the `clLastPeriod` end date is one day later than the data window. Data = SQL; label = C#. Last-year window = `DATEADD(Year,-1,..)` on both dates.
2. `ActivityIncome` computes last-year net as `SUM(LastYearPeriodDebit) - SUM(LastYearPeriodCredit)` (correct), but `Acc_IncomeStatment` has `SUM(LastYearPeriodCredit) - SUM(LastYearPeriodCredit)` = ALWAYS 0, so `YearToPeriodBalance` / `CalculatedYearToPeriodBalance` of the type block and Net Profit are always 0. Reproduce for number fidelity (or confirm with the owner).
3. Only LEAF accounts (`AccountId NOT IN (SELECT ParentAccountId ... NOT NULL)`) are summed; leaf accounts with no journals contribute 0.
4. `ActivityIncome` INNER JOINs `Acc_CostCenter` on the action `CostCenterId`, so journal lines with NULL cost center are dropped from the cost-center rows but are included in the `Acc_IncomeStatment` totals (Net Profit); only types 1 and 2 are listed.
5. `ABS(sum)` everywhere: a net debit income account shows as positive income (sign lost). Negation only for type 2 in `ActivityIncome`, for (2,4,5,13) in `Acc_IncomeStatment`; type 17 (Unearned Revenue, nature 1) would be positive.
6. Order: `CostCenterNo, AccountTypeId` (CostCenterNo NVARCHAR(20), string order).
7. `@CostCenterList`/`@BranchList` NULL = no filter; filters apply equally to the 3 windows. `@JournalTypeList` must be non-null (see Common facts).

---

## 8. IncomeStatmentBranchPeriod (branch income statement, period comparison)

### 8.1 Route and params
- Angular route `financial-reports/income-statment-barnche-detail-report` (core/routes.ts line 818, id `6_1_3_2`, "Comparison Branch Income Statement Period", Arabic menu: قائمة الدخل بالفروع مقارن فترات), ModuleId 55, route query param `report=IncomeStatmentBranchPeriod`.
- Shell `BrifIncomeStatmentBrancheReportShellComponent` (financial-reports.module.ts line 127), folder `modules\financial-reports\brif-income-statment-branche-report\` (form folder is `...-report-from`). The same shell also serves `IncomeStatemetBranchs`, `IncomeStatemetBranchsProduction`, default `BranchIncomeStatement`.
- FilterForm: `fromDate` (req), `toDate` (req), `revised` (null / true / false; "all" = null here), `journalTypes`, `branchesIds` (NOT required; set in `filter()` from `BranchLookupRef.BranchForm.BranchList`).
- iframe: `FinancialReports/IncomeStatmentBranchPeriod?lang=..&fromDate=..&toDate=..&revised=..&journalTypes=..&branchesIds=..`

### 8.2 MVC action
```csharp
[Route("mvc/FinancialReports/IncomeStatmentBranchPeriod")]
public IActionResult IncomeStatmentBranchPeriod(string lang, DateTime fromDate, DateTime toDate, bool? revised, string journalTypes, string branchesIds)
{
    ChangeThreadCulture(lang);
    var report = new rptIncomeStatmentBranchPeriod(fromDate, toDate, revised, journalTypes, branchesIds);
    return View(REPORTS_ROOT_VIEW, report);
}
```
Rpt: `Reports\IncomeStatmentActivityDetail\rptIncomeStatmentBranchPeriod.cs` (lives in the ActivityDetail folder and shares `dsIncomeStatmentActivity`). The ctor names the 5th arg `_costCenterList` but stores it in `branchIdsList`.

### 8.3 rpt computations
Identical to report 7 (diff of the two .cs files) except:
- Fills: `BranchIncome.Fill(t, _fromDate, _toDate, revised, journalTypes, null, branchIdsList)` and `Acc_IncomeStatment.Fill(t, ..., journalTypes, null, branchIdsList)` => @CostCenterList = NULL, @BranchList = branch list.
- `lblBranch` = branch names (`SELECT BranchName FROM dbo.Acc_Branch WHERE (@Ids is null or BranchId IN (SELECT * FROM dbo.Acc_ConvertIntListToTable(@Ids)))`), "" if null.
- Group header by `BranchCode` asc. `Detail1_BeforePrint` identical (hides types 1,2 in the `Acc_IncomeStatment` block). Title "Branch Income Statement Comparsion Period" (typo in layout).
- Summaries identical: GOP per branch (Sum Running=Group of Calculate*), percentages (Percentage, Running=Report, `{0:0%}`), report total (Sum Running=Report), Net Profit (Sum Running=Report of `Acc_IncomeStatment.Calculated*`).

### 8.4 SQL VERBATIM
`Acc_IncomeStatment` and `Acc_SystemConfiguration` adapters: same xsd and text as 7.4.b / 7.4.c, called with @CostCenterList = NULL and @BranchList = branch list. Only `BranchIncome` is new.

#### 8.4.a TableAdapter `BranchIncome` (per branch x account type 1,2)

```sql
 WITH    AccountBalance ( AccountId, BusinessActivityId, AccountTypeId, PeriodBalance, LastPeriodBalance, LastYearPeriodBalance,BranchId)
          AS ( SELECT   Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.PeriodDebit), 0)
                        - ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodBalance,
                        ISNULL(SUM(Balance.LastDebit), 0)
                        - ISNULL(SUM(Balance.LastCredit), 0) AS LastPeriodBalance,
                        ISNULL(SUM(Balance.LastYearPeriodDebit), 0)
                        - ISNULL(SUM(Balance.LastYearPeriodCredit), 0) AS LastYearPeriodCredit,
						Balance.BranchId
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId AS AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    PeriodCredit AS PeriodCredit,
                                                    PeriodDebit AS PeriodDebit,
                                                    0 AS LastYearPeriodCredit,
                                                    0 AS LastYearPeriodDebit,
                                                    BranchId
										  FROM      Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    PeriodCredit AS LastCredit,
                                                    PeriodDebit AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS LastYearPeriodCredit,
                                                    0 AS LastYearPeriodDebit,
													BranchId

                                          FROM      Acc_GetAccountJournalActionsBetweenDates(DATEADD(SECOND, -1 -DATEDIFF(SECOND, @FromBalanceDate, @ToBalanceDate), @FromBalanceDate), DATEADD(SECOND, -1 -DATEDIFF(SECOND, @FromBalanceDate, @ToBalanceDate), @ToBalanceDate), @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_2
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    PeriodCredit AS LastYearPeriodCredit,
                                                    PeriodDebit AS LastYearPeriodDebit,
													BranchId
                                          FROM      Acc_GetAccountJournalActionsBetweenDates(DATEADD(Year, -1, @FromBalanceDate), DATEADD(Year, -1, @ToBalanceDate), @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_3
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        AccountTypeId,Balance.BranchId
             )
    SELECT  Acc_Branch.BranchCode,
            Acc_Branch.BranchName,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic,
            abs (ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) AS PeriodBalance,
            abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)) AS LastPeriodBalance,
            abs (ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)) AS YearToPeriodBalance,
			Acc_AccountType.AccountTypeId,
			case when Acc_AccountType.AccountTypeId = 2
			then (-1*abs(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0))) 
			else 
			abs (ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) end as CalculatePeriodBalance,
			case when Acc_AccountType.AccountTypeId = 2
			then (-1* abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)))
			else  abs(ISNULL(SUM(AccountBalance_1.LastPeriodBalance), 0)) end AS CalculateLastPeriodBalance,
			case when Acc_AccountType.AccountTypeId =2 
			then (-1 * abs (ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)))
			else  abs (ISNULL(SUM(AccountBalance_1.LastYearPeriodBalance), 0)) end as CalculateYearToPeriodBalance
    
	FROM    AccountBalance AS AccountBalance_1
            inner JOIN dbo.Acc_Branch ON Acc_Branch.BranchId = AccountBalance_1.BranchId
            INNER JOIN dbo.Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
	where Acc_AccountType.AccountTypeId in (1,2)
    GROUP BY Acc_Branch.BranchCode,
             Acc_Branch.BranchName,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic
			,Acc_AccountType.AccountTypeId
    ORDER BY Acc_Branch.BranchCode  ,
	         Acc_AccountType.AccountTypeId
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 0`
- `@CostCenterList String None 0 Nullable`
- `@BranchList String None 0 Nullable`


Dataset columns: BranchIncome(AccountTypeName, AccountTypeNameArabic, PeriodBalance, LastPeriodBalance, YearToPeriodBalance, AccountTypeId int, BranchCode, BranchName, CalculatePeriodBalance, CalculateLastPeriodBalance, CalculateYearToPeriodBalance).

### 8.5 Dependencies and cloud existence
Same as 7.5 with `Acc_Branch` (BranchCode NVARCHAR(50), BranchName) instead of `Acc_CostCenter`: `dbo\Tables\Acc_Branch.sql` exists and is in the sqlproj. Nothing missing. Non-SQL helper: `ApiLoggedUser.GetBranchNamesBybranchIdList`.

### 8.6 Layout structure
Same Designer as 7.6: `DetailReport1` over `BranchIncome` grouped by `BranchCode`; GOP row; total GOP footer; `DetailReport` over `Acc_IncomeStatment` with Net Profit. `xrTableCell2` again binds the non-existent `ActivityIncome.BusinessActivity` (copy-paste).

### 8.7 Quirks
Same as 7.7 plus:
1. `BranchIncome` CTE selects and groups by `Balance.BranchId`; `INNER JOIN dbo.Acc_Branch` drops journal lines whose action `BranchId` is NULL from the branch rows, but they stay in the `Acc_IncomeStatment` block.
2. The branch list is passed as @BranchList into the three function calls of `Acc_IncomeStatment` too, so Net Profit is branch filtered; @CostCenterList is always NULL here.
3. `ORDER BY Acc_Branch.BranchCode, AccountTypeId` (string order). The `LastYearPeriodCredit - LastYearPeriodCredit` bug (always-0 year column) is in the shared `Acc_IncomeStatment` query.

---

## 9. IncomeStatemetPerPeriod (monthly detailed income statement for a period)

### 9.1 Route and params
- Angular route `financial-reports/income-statment-arbic-period-report` (core/routes.ts line 874, id `6_1_4_2`, text "Branch Report Per Period", Arabic menu: قائمة الدخل الشهرية تفصيلي بالفترة), ModuleId 72, route query param `report=IncomeStatemetPerPeriod`.
- Shell `BrifIncomeStatmentReportShellComponent` (financial-reports.module.ts line 163), folder `modules\financial-reports\brif-income-statment-report\`. The same shell also serves `IncomeStatement` (default `BriefIncomeStatment`).
- FilterForm: `fromDate` (req), `toDate` (req), `revised`, `journalTypes`, `costCenterIds` (optional), `branchesIds` (optional; `whenBranchChange` sets `[]` when null).
- iframe: `FinancialReports/IncomeStatemetPerPeriod?lang=..&fromDate=..&toDate=..&revised=..&journalTypes=..&costCenterIds=..&branchesIds=..`
- Out of scope but nearby: route `branch-statment-arbic-month-report` and rpt `rptIncomeStatemetArabicPerMonth` (same folder, not used by this action).

### 9.2 MVC action
```csharp
[Route("mvc/FinancialReports/IncomeStatemetPerPeriod")]
public IActionResult IncomeStatemetPerPeriod(string lang, bool? revised, string journalTypes,
    string costCenterIds, string branchesIds, DateTime fromDate, DateTime toDate)
{
    ChangeThreadCulture(lang);
    var report = new rptIncomeStatemetPerPeriod(fromDate, toDate, revised, journalTypes, costCenterIds, branchesIds);
    return View(REPORTS_ROOT_VIEW, report);
}
```
Rpt: `Reports\IncomeStatmentPerMonth\rptIncomeStatemetPerPeriod.cs` (+ Designer); dataset `dsIncomeStatmentPerMonth.xsd`.


### 9.3 rpt computations (BeforePrint `rptIncomeStatemetPerPeriod_BeforePrint`)
- Six TableAdapters, each filled with `FillByPeriodArabic` when `ApiLoggedUser.IsArabic`, else `FillByPeriod`, args `(table, _fromDate, _toDate, revised, journalTypes, costCenterIds, branches)`:

| DataTable | MainItemId (SQL) | SubItemBalance sign | pivot grid |
|---|---|---|---|
| Acc_IncomeStatement_OperatingIncomePerMonth | 1 | Credit - Debit | xrPivotGrid1 |
| Acc_IncomeStatement_OperatingExpensesPerMonth | 2 | Debit - Credit | xrPivotGrid2 |
| Acc_IncomeStatement_OtherIncomePerMonth | 3 | Credit - Debit | xrPivotGrid3 |
| Acc_IncomeStatement_AdministrativePerMonth | 4 | Debit - Credit | xrPivotGrid4 |
| Acc_IncomeStatement_OtherExpensePerMonth | 5 | Debit - Credit | xrPivotGrid5 |
| Acc_IncomeStatement_TaxesPerMonth | 6 | Credit - Debit | xrPivotGrid6 |

- Totals (C#, sum over ALL rows of each table of `Convert.ToDecimal(row["SubItemBalance"])`): `_operatingIncome`, `_operatingExpenses`, `_otherIncome`, `_otherExpenses`, `_administrativeExpenses`, `_taxes`.
  - `_grossprofit = _operatingIncome - _operatingExpenses` -> `txtGrossProfit` (`N2`, label "Total Profit").
  - `_netProfitBeforeTax = _operatingIncome - _operatingExpenses - _otherExpenses + _otherIncome - _administrativeExpenses` -> `txtNetProfitBefore` ("Net Profit Before Tax").
  - `_netProfit = _netProfitBeforeTax + _taxes` -> `txtNetProfit` ("Net Profit"). Taxes are Credit - Debit, so a tax expense is negative and is ADDED.
  - Format `ToString("N2")` with the current thread culture (`ChangeThreadCulture(lang)`), not the tenant ApproximateNo.
- Visibility: gross profit label+value hidden when `_grossprofit == 0`; net before tax hidden when 0; net profit hidden when 0.
- Per pivot `BeforePrint`: row count 0 => `e.Cancel = true` (grid not printed). For grid 1 (income) and grid 2 (opex) with zero rows, additionally the three profit text boxes are hidden.
- `lblRevised` Arabic: "رصيد من قيود مرحله وقيود غير مرحله" / "رصيد من قيود مرحله فقط" / "رصيد من قيود غير مرحله فقط". `lblCostCenter` = cost-center names or "". Branch names are not displayed.

- Pivot `FieldValueDisplayText` (Arabic only): GrandTotal column -> "اجمالى"; Total -> per grid: grid1 "إجمالى ايرادات التشغيل", grid2 "إجمالى مصروفات التشغيل", grid3 "إجمالى مصروفات عمومية وادارية" (grid3 is OtherIncome), grid4 "إجمالى مصروفات أخرى" (grid4 is Administrative), grid5 and grid6 both "إجمالى مصروفات التشغيل" (grid5 OtherExpense, grid6 Taxes). Copy-paste mismatches; reproduce or fix consciously. `CustomColumnWidth`: GrandTotal column width 100 in Arabic.
- Month column sort: `CustomFieldSort` on `monthname` compares the hidden `number`, i.e. calendar-month order.

### 9.4 SQL VERBATIM (dsIncomeStatmentPerMonth.xsd)
Each TableAdapter has 4 commands: `Fill` (@FromMonth, @ToMonth + 6), `FillByArabic`, `FillByPeriod`, `FillByPeriodArabic`. This report uses ONLY `FillByPeriod` (English) and `FillByPeriodArabic` (Arabic month names + `MainItemNameArabic`), 6 params. `Fill` / `FillByArabic` belong to the month-based report and are omitted (they are in the xsd). The 6 adapters differ only in MainItemId (1..6), the sign of SubItemBalance, and Taxes drops the `AccountBalance_1.number is not null` filter (see table in 9.3).
Also `Acc_SystemConfiguration`: `SELECT Acc_SystemConfiguration.*` / `FROM  Acc_SystemConfiguration`.


#### 9.4.1a `Acc_IncomeStatement_OperatingIncomePerMonth` -> FillByPeriod (English)

```sql
 with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 
 )


,AccountTable as(
 SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId,
 ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit ,
   MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
    FROM      Acc_Account LEFT OUTER JOIN
	      (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
		       FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
			    @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
				  Acc_Account.AccountId = Balance.AccountId
				       WHERE   (Acc_Account.AccountId NOT IN
					     (SELECT ParentAccountId
						 FROM      Acc_Account AS Acc_Account_2
						    WHERE   (ParentAccountId IS NOT NULL))) 
					  GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId ,
					  MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) 
)
,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null

 )

  SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit,
	 ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit,
	  Acc_IncomeStatmentSubItem.SubItemName, 
                      (ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) AS SubItemBalance,
					   Acc_IncomeStatmentMainItem.MainItemName , AccountBalance_1.number , AccountBalance_1.monthname
    FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId 
					  ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 1) and AccountBalance_1.number is not null
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemName, Acc_IncomeStatmentSubItem.OrderInReport
	,AccountBalance_1.number , AccountBalance_1.monthname
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.1b `Acc_IncomeStatement_OperatingIncomePerMonth` -> FillByPeriodArabic

```sql
    with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname,
	   case when number=1 then N'يناير '
      when number=2 then N'فبراير '  
      when number=3 then N'مارس ' 
      when number=4 then N'أبريل ' 
      when number=5 then N'مايو ' 
      when number=6 then N'يونيو '  
      when number=7 then N'يوليو ' 
      when number=8 then N'أغسطس ' 
      when number=9 then N'سبتمبر ' 
      when number=10 then N'أكتوبر '
      when number=11 then N'نوفمبر '  
      when number=12 then N'ديسمبر '   
     end AS ArabicMonth 
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 
 )

,AccountTable as(
 SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId,
 ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit ,
   MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
    FROM      Acc_Account LEFT OUTER JOIN
	      (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
		       FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
			    @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
				  Acc_Account.AccountId = Balance.AccountId
				       WHERE   (Acc_Account.AccountId NOT IN
					     (SELECT ParentAccountId
						 FROM      Acc_Account AS Acc_Account_2
						    WHERE   (ParentAccountId IS NOT NULL))) 
					  GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId ,
					  MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) 
)
,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.ArabicMonth as monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null

 )

  SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit,
	 ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit,
	  Acc_IncomeStatmentSubItem.SubItemName, 
                      (ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) AS SubItemBalance,
					   Acc_IncomeStatmentMainItem.MainItemNameArabic as MainItemName, AccountBalance_1.number , AccountBalance_1.monthname
    FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId 
					  ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 1) and AccountBalance_1.number is not null
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport
	,AccountBalance_1.number , AccountBalance_1.monthname
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.2a `Acc_IncomeStatement_OperatingExpensesPerMonth` -> FillByPeriod (English)

```sql
 with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 
 )



, AccountTable (AccountId, ParentAccountId, PeriodCredit, PeriodDebit,MNTH ,Yer)
 AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
    ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
	MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
	     FROM      Acc_Account LEFT OUTER JOIN
		                (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
						  FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
						       @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
							       Acc_Account.AccountId = Balance.AccountId
								          WHERE   (Acc_Account.AccountId NOT IN
										    (SELECT ParentAccountId
											  FROM      Acc_Account AS Acc_Account_2
											      WHERE   (ParentAccountId IS NOT NULL)))

												   GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId
												   ,MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) 

												   )

,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null
 )
    SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, Acc_IncomeStatmentSubItem.SubItemName, 
                     ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0))  AS SubItemBalance, Acc_IncomeStatmentMainItem.MainItemName
                  ,AccountBalance_1.number, AccountBalance_1.monthname
	FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 2) and AccountBalance_1.number is not null
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemName, Acc_IncomeStatmentSubItem.OrderInReport
	 , AccountBalance_1.number, AccountBalance_1.monthname
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.2b `Acc_IncomeStatement_OperatingExpensesPerMonth` -> FillByPeriodArabic

```sql
 			   with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname,
	   case when number=1 then N'يناير '
      when number=2 then N'فبراير '  
      when number=3 then N'مارس ' 
      when number=4 then N'أبريل ' 
      when number=5 then N'مايو ' 
      when number=6 then N'يونيو '  
      when number=7 then N'يوليو ' 
      when number=8 then N'أغسطس ' 
      when number=9 then N'سبتمبر ' 
      when number=10 then N'أكتوبر '
      when number=11 then N'نوفمبر '  
      when number=12 then N'ديسمبر '   
     end AS ArabicMonth 
FROM   dbo.Acc_TableNumberRange( MONTH( @FromBalanceDate),  MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 

			   )


, AccountTable (AccountId, ParentAccountId, PeriodCredit, PeriodDebit,MNTH ,Yer)
 AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
    ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
	MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
	     FROM      Acc_Account LEFT OUTER JOIN
		                (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
						  FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
						       @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
							       Acc_Account.AccountId = Balance.AccountId
								          WHERE   (Acc_Account.AccountId NOT IN
										    (SELECT ParentAccountId
											  FROM      Acc_Account AS Acc_Account_2
											      WHERE   (ParentAccountId IS NOT NULL)))

												   GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId
												   ,MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) 

												   )

,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.ArabicMonth as monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null
 )
    SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, Acc_IncomeStatmentSubItem.SubItemName, 
                      ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0))  AS SubItemBalance,
					   Acc_IncomeStatmentMainItem.MainItemNameArabic   as MainItemName
                  ,AccountBalance_1.number, AccountBalance_1.monthname
	FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 2) and AccountBalance_1.number is not null
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport
	 , AccountBalance_1.number, AccountBalance_1.monthname
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.3a `Acc_IncomeStatement_OtherIncomePerMonth` -> FillByPeriod (English)

```sql
   WITH  date
          AS ( SELECT   number ,
                        DATENAME(MONTH, DATEADD(MONTH, number - 1, 0)) AS monthname ,
                        Acc_Account.AccountId ,
                        AccountName
               FROM     dbo.Acc_TableNumberRange(MONTH(@FromBalanceDate),
                                                 MONTH(@ToBalanceDate))
                        INNER JOIN Acc_Account ON 1 = 1
             ),
        AccountTable 
          AS ( SELECT   Acc_Account.AccountId ,
                        Acc_Account.ParentAccountId ,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit ,
                        MONTH(Balance.CreatedDate) AS MNTH ,
                        YEAR(Balance.CreatedDate) AS Yer ,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId ,
                                                    Credit ,
                                                    Debit ,
                                                    PeriodCredit ,
                                                    PeriodDebit ,
                                                    CreatedDate
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate,
                                                              @ToBalanceDate,
                                                              @JournalRevise,
                                                              @JournalTypeList,
                                                              @CostCenterList,
                                                              NULL, NULL,
                                                              @BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId ,
                        Acc_Account.ParentAccountId ,
                        MONTH(Balance.CreatedDate) ,
                        YEAR(Balance.CreatedDate)
             ),
        AccountBalance
          AS ( SELECT   AccountTable.AccountId ,
                        AccountTable.ParentAccountId ,
                        ISNULL(AccountTable.PeriodCredit, 0) AS PeriodCredit ,
                        ISNULL(AccountTable.PeriodDebit, 0) AS PeriodDebit ,
                        date.number ,
                        date.monthname
               FROM     AccountTable
                        RIGHT OUTER JOIN date ON AccountTable.MNTH = date.number
                                                 AND AccountTable.AccountId = date.AccountId
               WHERE    AccountTable.AccountId IS NOT NULL
             )
    SELECT  ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit ,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit ,
            Acc_IncomeStatmentSubItem.SubItemName ,
            ( ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)
              - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) ) AS SubItemBalance ,
            Acc_IncomeStatmentMainItem.MainItemName ,
            AccountBalance_1.monthname ,
            AccountBalance_1.number
    FROM    Acc_IncomeStatmentMainItem
            INNER JOIN Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId
            LEFT OUTER JOIN AccountBalance AS AccountBalance_1
            RIGHT OUTER JOIN Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE   ( Acc_IncomeStatmentMainItem.MainItemId = 3 ) AND AccountBalance_1.number IS NOT NULL
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName ,
            Acc_IncomeStatmentMainItem.MainItemId ,
            Acc_IncomeStatmentMainItem.MainItemName ,
            Acc_IncomeStatmentSubItem.OrderInReport ,
            AccountBalance_1.monthname ,
            AccountBalance_1.number
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport;
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.3b `Acc_IncomeStatement_OtherIncomePerMonth` -> FillByPeriodArabic

```sql
  WITH  date
          AS ( SELECT   number ,
                        DATENAME(MONTH, DATEADD(MONTH, number - 1, 0)) AS monthname ,
                        Acc_Account.AccountId ,
                        AccountName ,
                        CASE WHEN number = 1 THEN N'يناير '
                             WHEN number = 2 THEN N'فبراير '
                             WHEN number = 3 THEN N'مارس '
                             WHEN number = 4 THEN N'أبريل '
                             WHEN number = 5 THEN N'مايو '
                             WHEN number = 6 THEN N'يونيو '
                             WHEN number = 7 THEN N'يوليو '
                             WHEN number = 8 THEN N'أغسطس '
                             WHEN number = 9 THEN N'سبتمبر '
                             WHEN number = 10 THEN N'أكتوبر '
                             WHEN number = 11 THEN N'نوفمبر '
                             WHEN number = 12 THEN N'ديسمبر '
                        END AS ArabicMonth
               FROM     dbo.Acc_TableNumberRange(MONTH(@FromBalanceDate),
                                                 MONTH(@ToBalanceDate))
                        INNER JOIN Acc_Account ON 1 = 1
             ),
        AccountTable
          AS ( SELECT   Acc_Account.AccountId ,
                        Acc_Account.ParentAccountId ,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit ,
                        MONTH(Balance.CreatedDate) AS MNTH ,
                        YEAR(Balance.CreatedDate) AS Yer ,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId ,
                                                    Credit ,
                                                    Debit ,
                                                    PeriodCredit ,
                                                    PeriodDebit ,
                                                    CreatedDate
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate,
                                                              @ToBalanceDate,
                                                              @JournalRevise,
                                                              @JournalTypeList,
                                                              @CostCenterList,
                                                              NULL, NULL,
                                                              @BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId ,
                        Acc_Account.ParentAccountId ,
                        MONTH(Balance.CreatedDate) ,
                        YEAR(Balance.CreatedDate)
             ),
        AccountBalance
          AS ( SELECT   AccountTable.AccountId ,
                        AccountTable.ParentAccountId ,
                        ISNULL(AccountTable.PeriodCredit, 0) AS PeriodCredit ,
                        ISNULL(AccountTable.PeriodDebit, 0) AS PeriodDebit ,
                        date.number ,
                        date.ArabicMonth AS monthname
               FROM     AccountTable
                        RIGHT OUTER JOIN date ON AccountTable.MNTH = date.number
                                                 AND AccountTable.AccountId = date.AccountId
               WHERE    AccountTable.AccountId IS NOT NULL
             )
    SELECT  ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit ,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit ,
            Acc_IncomeStatmentSubItem.SubItemName ,
            ( ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)
              - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) ) AS SubItemBalance ,
            Acc_IncomeStatmentMainItem.MainItemNameArabic AS MainItemName ,
            AccountBalance_1.monthname ,
            AccountBalance_1.number
    FROM    Acc_IncomeStatmentMainItem
            INNER JOIN Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId
            LEFT OUTER JOIN AccountBalance AS AccountBalance_1
            RIGHT OUTER JOIN Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE   ( Acc_IncomeStatmentMainItem.MainItemId = 3 )
            AND AccountBalance_1.number IS NOT NULL
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName ,
            Acc_IncomeStatmentMainItem.MainItemId ,
            Acc_IncomeStatmentMainItem.MainItemNameArabic ,
            Acc_IncomeStatmentSubItem.OrderInReport ,
            AccountBalance_1.monthname ,
            AccountBalance_1.number
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport;
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.4a `Acc_IncomeStatement_AdministrativePerMonth` -> FillByPeriod (English)

```sql
 
with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 
 )

, AccountTable(AccountId, ParentAccountId, PeriodCredit, PeriodDebit,MNTH,Yer) 
AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                      ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
																																													  ,MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
                                                                                                                                                                    FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                          (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
                                                                                                                                                                                           FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
                                                                                                                                                                                                             @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
                                                                                                                                                                                      Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                    WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                          (SELECT ParentAccountId
                                                                                                                                                                                           FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                           WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId , MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) )

,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null
 )

    SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, Acc_IncomeStatmentSubItem.SubItemName, 
                     ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0))  AS SubItemBalance, Acc_IncomeStatmentMainItem.MainItemName
					  , AccountBalance_1.monthname,AccountBalance_1.number
    FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 4) and AccountBalance_1.number is not null 
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemName, Acc_IncomeStatmentSubItem.OrderInReport
    , AccountBalance_1.monthname,AccountBalance_1.number
	ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.4b `Acc_IncomeStatement_AdministrativePerMonth` -> FillByPeriodArabic

```sql
  WITH   date
          AS ( SELECT   number ,
                        DATENAME(MONTH, DATEADD(MONTH, number - 1, 0)) AS monthname ,
                        Acc_Account.AccountId ,
                        AccountName ,
                        CASE WHEN number = 1 THEN N'يناير '
                             WHEN number = 2 THEN N'فبراير '
                             WHEN number = 3 THEN N'مارس '
                             WHEN number = 4 THEN N'أبريل '
                             WHEN number = 5 THEN N'مايو '
                             WHEN number = 6 THEN N'يونيو '
                             WHEN number = 7 THEN N'يوليو '
                             WHEN number = 8 THEN N'أغسطس '
                             WHEN number = 9 THEN N'سبتمبر '
                             WHEN number = 10 THEN N'أكتوبر '
                             WHEN number = 11 THEN N'نوفمبر '
                             WHEN number = 12 THEN N'ديسمبر '
                        END AS ArabicMonth
               FROM     dbo.Acc_TableNumberRange(MONTH(@FromBalanceDate),
                                                 MONTH(@ToBalanceDate))
                        INNER JOIN Acc_Account ON 1 = 1
             ),
        AccountTable ( AccountId, ParentAccountId, PeriodCredit, PeriodDebit, MNTH, Yer )
          AS ( SELECT   Acc_Account.AccountId ,
                        Acc_Account.ParentAccountId ,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit ,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit ,
                        MONTH(Balance.CreatedDate) AS MNTH ,
                        YEAR(Balance.CreatedDate) AS Yer
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId ,
                                                    Credit ,
                                                    Debit ,
                                                    PeriodCredit ,
                                                    PeriodDebit ,
                                                    CreatedDate
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate,
                                                              @ToBalanceDate,
                                                              @JournalRevise,
                                                              @JournalTypeList,
                                                              @CostCenterList,
                                                              NULL, NULL,
                                                              @BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId ,
                        Acc_Account.ParentAccountId ,
                        MONTH(Balance.CreatedDate) ,
                        YEAR(Balance.CreatedDate)
             ),
        AccountBalance
          AS ( SELECT   AccountTable.AccountId ,
                        AccountTable.ParentAccountId ,
                        ISNULL(AccountTable.PeriodCredit, 0) AS PeriodCredit ,
                        ISNULL(AccountTable.PeriodDebit, 0) AS PeriodDebit ,
                        date.number ,
                        date.ArabicMonth AS monthname
               FROM     AccountTable
                        RIGHT OUTER JOIN date ON AccountTable.MNTH = date.number
                                                 AND AccountTable.AccountId = date.AccountId
               WHERE    AccountTable.AccountId IS NOT NULL
             )
    SELECT  ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit ,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit ,
            Acc_IncomeStatmentSubItem.SubItemName ,
           ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0))  AS SubItemBalance ,
            Acc_IncomeStatmentMainItem.MainItemNameArabic AS MainItemName ,
            AccountBalance_1.monthname ,
            AccountBalance_1.number
    FROM    Acc_IncomeStatmentMainItem
            INNER JOIN Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId
            LEFT OUTER JOIN AccountBalance AS AccountBalance_1
            RIGHT OUTER JOIN Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE   ( Acc_IncomeStatmentMainItem.MainItemId = 4 )
            AND AccountBalance_1.number IS NOT NULL
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName ,
            Acc_IncomeStatmentMainItem.MainItemId ,
            Acc_IncomeStatmentMainItem.MainItemNameArabic ,
            Acc_IncomeStatmentSubItem.OrderInReport ,
            AccountBalance_1.monthname ,
            AccountBalance_1.number
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport;
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.5a `Acc_IncomeStatement_OtherExpensePerMonth` -> FillByPeriod (English)

```sql
 with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 
 )


, AccountTable (AccountId, ParentAccountId, PeriodCredit, PeriodDebit,MNTH,Yer) 
AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                      ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
                                                                                                                                                                    FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                          (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
                                                                                                                                                                                           FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
                                                                                                                                                                                                             @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
                                                                                                                                                                                      Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                    WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                          (SELECT ParentAccountId
                                                                                                                                                                                           FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                           WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId,MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) )

		,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null
 )
    SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, Acc_IncomeStatmentSubItem.SubItemName, 
                  ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0))  AS SubItemBalance, Acc_IncomeStatmentMainItem.MainItemName
          ,AccountBalance_1.number,AccountBalance_1.monthname
    FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 5) and number is not null
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemName, Acc_IncomeStatmentSubItem.OrderInReport
	  ,AccountBalance_1.number,AccountBalance_1.monthname
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.5b `Acc_IncomeStatement_OtherExpensePerMonth` -> FillByPeriodArabic

```sql
    with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname,
	   case when number=1 then N'يناير '
      when number=2 then N'فبراير '  
      when number=3 then N'مارس ' 
      when number=4 then N'أبريل ' 
      when number=5 then N'مايو ' 
      when number=6 then N'يونيو '  
      when number=7 then N'يوليو ' 
      when number=8 then N'أغسطس ' 
      when number=9 then N'سبتمبر ' 
      when number=10 then N'أكتوبر '
      when number=11 then N'نوفمبر '  
      when number=12 then N'ديسمبر '   
     end AS ArabicMonth 
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 

			   )


, AccountTable (AccountId, ParentAccountId, PeriodCredit, PeriodDebit,MNTH,Yer) 
AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                      ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
                                                                                                                                                                    FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                          (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
                                                                                                                                                                                           FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
                                                                                                                                                                                                             @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
                                                                                                                                                                                      Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                    WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                          (SELECT ParentAccountId
                                                                                                                                                                                           FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                           WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId,MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) )

		,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.ArabicMonth as monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null
 )
    SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, Acc_IncomeStatmentSubItem.SubItemName, 
                   ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0))  AS SubItemBalance, Acc_IncomeStatmentMainItem.MainItemNameArabic as MainItemName
          ,AccountBalance_1.number,AccountBalance_1.monthname
    FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 5) and number is not null
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport
	  ,AccountBalance_1.number,AccountBalance_1.monthname
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.6a `Acc_IncomeStatement_TaxesPerMonth` -> FillByPeriod (English)

```sql
 with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 
 )





, AccountTable (AccountId, ParentAccountId, PeriodCredit, PeriodDebit,MNTH,Yer) 
AS (
SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId,
 ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
 ,MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
  FROM      Acc_Account LEFT OUTER JOIN
     (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
	    FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
		 @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
		  Acc_Account.AccountId = Balance.AccountId
		    WHERE   (Acc_Account.AccountId NOT IN
			   (SELECT ParentAccountId
			    FROM      Acc_Account AS Acc_Account_2
				   WHERE   (ParentAccountId IS NOT NULL)))
				    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId
			, MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) 
					)

,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null
 )


    SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, Acc_IncomeStatmentSubItem.SubItemName, 
                      (ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) AS SubItemBalance, Acc_IncomeStatmentMainItem.MainItemName
    ,AccountBalance_1.monthname , AccountBalance_1.number
	FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 6)
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemName, Acc_IncomeStatmentSubItem.OrderInReport
	,AccountBalance_1.monthname , AccountBalance_1.number
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


#### 9.4.6b `Acc_IncomeStatement_TaxesPerMonth` -> FillByPeriodArabic

```sql
 
  with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname,
	   case when number=1 then N'يناير '
      when number=2 then N'فبراير '  
      when number=3 then N'مارس ' 
      when number=4 then N'أبريل ' 
      when number=5 then N'مايو ' 
      when number=6 then N'يونيو '  
      when number=7 then N'يوليو ' 
      when number=8 then N'أغسطس ' 
      when number=9 then N'سبتمبر ' 
      when number=10 then N'أكتوبر '
      when number=11 then N'نوفمبر '  
      when number=12 then N'ديسمبر '   
     end AS ArabicMonth 
FROM   dbo.Acc_TableNumberRange(MONTH( @FromBalanceDate), MONTH( @ToBalanceDate)) 
inner join Acc_Account on 1=1 

			   )


, AccountTable (AccountId, ParentAccountId, PeriodCredit, PeriodDebit,MNTH,Yer) 
AS (
SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId,
 ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
 ,MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
  FROM      Acc_Account LEFT OUTER JOIN
     (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit,CreatedDate
	    FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, 
		 @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1) AS Balance ON 
		  Acc_Account.AccountId = Balance.AccountId
		    WHERE   (Acc_Account.AccountId NOT IN
			   (SELECT ParentAccountId
			    FROM      Acc_Account AS Acc_Account_2
				   WHERE   (ParentAccountId IS NOT NULL)))
				    GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId
			, MONTH(Balance.CreatedDate) ,year(Balance.CreatedDate) 
					)

,AccountBalance as (
select  AccountTable.AccountId,AccountTable.ParentAccountId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit 
,isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,date.number,date.ArabicMonth as monthname

from AccountTable 

right outer join date on AccountTable.MNTH = date.number and AccountTable.AccountId = date.AccountId
where AccountTable.AccountId is not null
 )


    SELECT ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, Acc_IncomeStatmentSubItem.SubItemName, 
                      (ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) AS SubItemBalance,
					   Acc_IncomeStatmentMainItem.MainItemNameArabic as MainItemName
    ,AccountBalance_1.monthname , AccountBalance_1.number
	FROM     Acc_IncomeStatmentMainItem INNER JOIN
                      Acc_IncomeStatmentSubItem ON Acc_IncomeStatmentMainItem.MainItemId = Acc_IncomeStatmentSubItem.MainItemId LEFT OUTER JOIN
                      AccountBalance AS AccountBalance_1 RIGHT OUTER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId ON Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId = Acc_Account_1.IncomeStatment
    WHERE  (Acc_IncomeStatmentMainItem.MainItemId = 6)
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName, Acc_IncomeStatmentMainItem.MainItemId, Acc_IncomeStatmentMainItem.MainItemNameArabic, Acc_IncomeStatmentSubItem.OrderInReport
	,AccountBalance_1.monthname , AccountBalance_1.number
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport
```
Parameters (name, DbType, ProviderType, Size, nullable):
- `@FromBalanceDate DateTime None 0`
- `@ToBalanceDate DateTime None 0`
- `@JournalRevise Boolean None 0 Nullable`
- `@JournalTypeList String None 1024`
- `@CostCenterList String None 1024 Nullable`
- `@BranchList String None 1024 Nullable`


Dataset columns of each table: PeriodCredit, PeriodDebit (decimal), SubItemName, SubItemBalance (decimal), MainItemName, number (int, month 1..12), monthname.

### 9.5 Dependencies and cloud existence
| Object | Cloud |
|---|---|
| `dbo.Acc_GetAccountJournalActionsBetweenDates` (needs `CreatedDate`, returned) | exists, in sqlproj |
| `dbo.Acc_TableNumberRange(@nMin,@nMax)` (multi-statement TVF, WHILE loop inserting @nMin..@nMax) | `dbo\Functions\Acc_TableNumberRange.sql` exists, in sqlproj |
| `Acc_Account` (`IncomeStatment` FK to `Acc_IncomeStatmentSubItem.IncomeStatmentSubItemId`) | exists |
| `Acc_IncomeStatmentMainItem` (MainItemId, MainItemName, MainItemNameArabic), `Acc_IncomeStatmentSubItem` (SubItemName, MainItemId, OrderInReport, IncomeStatmentSubItemId) | exist, in sqlproj; MainItem seed 1..6 in `Scripts\ReferenceDataScripts\0001_GL_ReferenceDate.sql` |
| `Acc_SystemConfiguration` | exists |

All referenced objects exist and are registered. Missing: none. Related, already in cloud (another CR): `dbo.Acc_IncomeStatementReport` (brief statement, `@IsArabic`) and `Acc_IncomeStatementReportDetails`, both in the sqlproj.

### 9.6 Layout structure (Designer)
- Landscape, page 2794 x 2159 (0.1 mm), margins 50, Tahoma 8, DevExpress 19.1. Report `DataMember = Acc_IncomeStatement_AdministrativePerMonth` (incidental).
- Header: logo/company block, title "Income Statement Per Period", from/to dates, `lblRevised`, `lblCostCenter`.
- Detail band holds 6 `XRPivotGrid`s stacked (1 income, 2 opex, 3 other income, 4 administrative, 5 other expense, 6 taxes), then the profit text boxes (Total Profit, Net Profit Before Tax, Net Profit). Pivot fields (each grid): row area `MainItemName` (AreaIndex 0) then `SubItemName` (AreaIndex 1); column area `monthname` (custom sort by `number`); data area `SubItemBalance` (`N2`); `number` hidden. Column/data/row headers hidden. Default totals: per-MainItemName "Total" and a "Grand Total" column across months; no SortMode on SubItemName.
- Footer: page number, print date, PC name.
- Cross-tab = DevExpress pivot (months as columns): the OData TVF either returns long format (one row per month) and the grid pivots client-side, or fixed 12 month columns.


### 9.7 Quirks to reproduce
1. The month axis uses ONLY `MONTH()` of the two dates: `Acc_TableNumberRange(MONTH(@From), MONTH(@To))`. A period crossing a year end (e.g. Nov..Feb, range 11..2) produces NO months, so an empty report. Periods longer than 12 months or covering the same month in 2 years merge into one month column (join `AccountTable.MNTH = date.number`; the year `Yer` is carried but ignored).
2. The `date` CTE cross-joins every month with EVERY account (`inner join Acc_Account on 1=1`); `AccountBalance` then keeps `where AccountTable.AccountId is not null`, i.e. only (leaf account, month) pairs with journal activity. Months without activity for a main item do not show for that grid; each grid can have a different set of month columns.
3. Leaf accounts only; accounts whose `IncomeStatment` is NULL map to no sub item and are excluded from all six grids and from the totals even if they carry journals.
4. Grouping is by `SubItemName` text, not SubItemId: sub items with equal names merge. The SQL `ORDER BY OrderInReport` is not preserved by the pivot (default value sort, no SortMode on `SubItemName`/`MainItemName`). Verify visually which order is shown before choosing the OData order.
5. The Taxes adapter lacks `AccountBalance_1.number is not null`: sub items of main item 6 without activity can show rows with NULL month/number (SubItemBalance 0).
6. Signs: income and taxes = Credit - Debit; expenses = Debit - Credit. The gross/net formulas in 9.3 rely on those signs (taxes added).
7. Arabic month names are literals in `FillByPeriodArabic` (with a trailing space); the English `monthname` = `DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0))` (SQL Server session language dependent). In the Arabic query `MainItemName` = `MainItemNameArabic`; `SubItemName` is the single (non-localized) column.
8. `@JournalTypeList` must be non-null; `@CostCenterList` and `@BranchList` nullable. The adapter declares these 3 string params with Size 1024, so lists longer than 1024 characters are truncated by the SqlParameter in the legacy path.
9. Money: pivot cells and the profit boxes are `N2` (2 decimals), not tenant ApproximateNo.
10. Profit boxes hidden when the value is exactly 0; a grid with no rows is not printed.
