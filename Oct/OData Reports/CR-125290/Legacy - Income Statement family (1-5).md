# Legacy inventory: five MVC Income Statement reports (budget / per-month family)

Read-only dissection, 2026-10-15. Main checkouts only. Paths are absolute.
Repos: Front `D:\Hadaf\AccFlex_Cloud_Front\accflex-erp`, MVC/reports `D:\Hadaf\AccFlex_ERP`,
DB `D:\Hadaf\AccFlex_Cloud_Database`, AnalyticsReader `D:\Hadaf\AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\AnalyticsReader`.

## 0. Common plumbing (applies to all five)

| Piece | Value |
|---|---|
| Module file | `D:\Hadaf\AccFlex_Cloud_Front\accflex-erp\projects\general-accounting\src\app\modules\financial-reports\financial-reports.module.ts` |
| Guards | every route: `canActivate: [AccflexAuthGuard, CanActivateRouteGuard]` |
| Menu file | `D:\Hadaf\AccFlex_Cloud_Front\accflex-erp\projects\general-accounting\src\app\core\routes.ts` (menu 6_1 "Income Statement" > 6_1_3 "Comparison Income Statement Report" / 6_1_4 "Branch Report Per Month") |
| iframe URL builder | `...\financial-reports\shared\financial-reports-data.service.ts` `initializeIFrame(reportUrl, query)` = `` `${this.printUrl}FinancialReports/${reportUrl}?lang=${this.lang}&${query}` `` (lang = `ar-EG` default / `en-US`) |
| Report name in URL | `this.route.queryParams.report` if present, else the hard-coded default in each shell. All 5 menu entries pass `params: ''`, so the default is always used. |
| Serializer | `D:\Hadaf\AccFlex_Cloud_Front\accflex-erp\src\app\shared\services\query-serialize\query-serialize.service.ts` `serialize(obj)`: for each key of `FilterForm.value` → `encodeURIComponent(key)=encodeURIComponent(value)`; `Date` → ISO string via `addHoursUTCDifferent`. Arrays become `1,2,3` (Array.toString → `1%2C2%2C3`). `null` → literal `null`; `' '` → `%20`; `''` → empty. **Every form control is sent, including unused ones** (`toDate`). |
| `revised` tri-state | radio Id 0/1/2 → form `revised` = `' '` (or `null` in forms 4 & 5) / `true` / `false`. MVC binds `bool? revised`: `"%20"`/`"null"` fail to bind → `null` = both. |
| Checklists | `app-costcenter-checklist` (emits array → `costCenterIds`), `app-branch-check-list` (`BranchForm.BranchList`, emits array, `[]` when nothing → `''`), `app-journal-type-checklist` (`JournalTypeForm.JournalTypeList`, read again in `filter()`). |
| MVC controller | `D:\Hadaf\AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\GeneralLedgerReports\FinancialReportsController.cs` (class `FinancialReportsController : BaseController`), every action: `ChangeThreadCulture(lang); var report = new rpt…(…); return View(REPORTS_ROOT_VIEW, report);` with `REPORTS_ROOT_VIEW = "~/Views/Report/ReportView.cshtml"`. |
| Layout lookup | `D:\Hadaf\AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Views\Report\ReportView.cshtml` line 9: `reportLayoutStore.GetReportLayoutByNameAndLanguage(Model.GetType().Name, CurrentUICulture.Name)` → if a tenant saved a custom layout in the legacy store it is loaded; otherwise the compiled `*.Designer.cs` layout is used. |
| `.repx` on disk | **None.** No `D:\Hadaf\ReportLayout` folder exists and no `.repx`/`.sql` anywhere under `D:\Hadaf` names any of these five reports. The only layout source is the `*.Designer.cs` files (+ any tenant-saved layout in the legacy MVC layout store, not inspectable from the repo). |
| `.resx` | All five `.resx` are boilerplate (`Name1/Color1/Bitmap1/Icon1`). Arabic captions live in the Designer's `localizer1` (`GeneralLedger.Reports.Helper.Localizer`, `itemTranslationN.Arabic = "..."`), applied by `localizer1.ApplyArabic()` when `ApiLoggedUser.IsArabic`. |
| Rounding | every rpt: `moneyApproximate1.ApplyApproximate(ApiLoggedUser.GetApproximateNo())` (tenant decimal places). |
| Company header | Every layout: `ReportHeader` band bound to `Acc_SystemConfiguration` (`SELECT Acc_SystemConfiguration.* FROM Acc_SystemConfiguration`): `MainLogo` (Logo), `MainCompanyName` (CompanyName), `MainComapnyAddress` (Address), Tel (`Telephone`), Fax (`Fax`), E-Mail (`Email`), `MainReportHeaderSplitter`. `PageFooter`: page `Page {0} Of {1}`, `Printed On {0:dd/MM/yyyy hh:mm tt}`, `PC :` + machine name, "Powered By: www.AccFlex.com". The migrated OData report passes the same six `CompanyInfo` parameters. |

### Shared Angular form contract (one table, per-report differences in each section)

| Report | form controls (in `FilterForm` order = query-string order) | required |
|---|---|---|
| 1 Cost Center Month/Year | `accountingPeriodId` (dx-lookup, sub-period Id), `toDate` (unused, always `''`), `revised`, `journalTypes`, `costCenterIds` | `accountingPeriodId` |
| 2 Branch Month/Year | `accountingPeriodId`, `toDate` (unused), `revised`, `journalTypes`, `branchesIds` | `accountingPeriodId` |
| 3 Cost Center vs Budget | `month` (true/false/null), `year` (`yyyy`), `revised`, `journalTypes`, `costCenterIds` | `year` |
| 4 Branch vs Budget | `month`, `year`, `revised`, `journalTypes`, `branchesIds` | `year` |
| 5 Arabic per Month | `month` (true/false only), `year`, `revised`, `journalTypes`, `costCenterIds`, `branchesIds` | `year` |

---

## 1. Income Statement by Cost Center Month/Year (`income-statment-activity-budget-report`)

### Angular
- Route: `financial-reports.module.ts` line 133 `path: 'income-statment-activity-budget-report'`, component `IncomeStatmentPeriodsReportShellComponent`, `data: { ModuleId: 267 }` (only report of the five on ModuleId 267; the rest are 72).
- Menu: `routes.ts` line 822-828, id `6_1_3_3`, text "By Cost Center Month to Year", textAr "مراكز تكلفة شهر / سنة", `params: ''`.
- Shell: `...\financial-reports\income-statment-periods-report\income-statment-periods-report-shell\income-statment-periods-report-shell.component.ts` — default report `'IncomeStatmentActivityBudget'`; requires `accountingPeriodId` else toast `COMMON._DataRequired_`. Title key `FINANCIALREPORTS._IncomeStatmentActivityBudgetReport_`.
- Form: `...\income-statment-periods-report-form\income-statment-periods-report-form.component.ts/.html`:
  - `accountingPeriodId` = `dx-lookup` over `PeriodsDataService.getSubPeriodsList()` (`AccountingSubPeriodForListDto`, valueExpr `Id`, display `SubPeriodStart / SubPeriodEnd` as `yyyy-MM-dd`). **It is a sub-period (month), not a year.**
  - `costCenterIds` ← `app-costcenter-checklist (whenCostCenterChange)`.
  - `journalTypes` ← re-read from `JournalTypeLookupRef.JournalTypeForm.JournalTypeList` in `filter()`.
  - `revised` radio (0 All → `' '`, 1 → `true`, 2 → `false`); `ngAfterViewInit` patches `revised: ' '` and sets radio to `getReportConfigs().RadioValue`.
- iframe URL: `{printUrl}FinancialReports/IncomeStatmentActivityBudget?lang=ar-EG&accountingPeriodId=<id>&toDate=&revised=<%20|true|false>&journalTypes=<csv>&costCenterIds=<csv>`

### MVC
- `FinancialReportsController.cs` line 131-142:
```csharp
[Route("mvc/FinancialReports/IncomeStatmentActivityBudget")]
public IActionResult IncomeStatmentActivityBudget(string lang, int accountingPeriodId, bool? revised, string journalTypes, string costCenterIds)
{
    ChangeThreadCulture(lang);
    var PeriodDates = ApiLoggedUser.GetSubPeriodStartDateAndEndDate(accountingPeriodId);
    var report = new rptIncomeStatmentActivityBudgetYearToDate(accountingPeriodId, PeriodDates["Start"], PeriodDates["End"],
        revised, journalTypes, costCenterIds);
    return View(REPORTS_ROOT_VIEW, report);
}
```
- `GetSubPeriodStartDateAndEndDate` (`D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Helper\ApiLoggedUser.cs` line 650): `SELECT TOP(1) SubPeriodStart, SubPeriodEnd FROM dbo.Acc_AccountingSubPeriod WHERE AccountingSubPeriodId = @accountingSubPeriodId;` — dates are used **only for header captions**; all SQL is driven by `accountingPeriodId`.

### rpt: `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\IncomeStatmentActivityBudgetYearToDate\rptIncomeStatmentActivityBudgetYearToDate.cs`
- Ctor `(int _accountingPeriodId, DateTime fromDate, DateTime toDate, bool? _revised, string _journalTypes, string _costCenterList)`; fields are **`private static`** (`revised`, `journalTypes`, `costCenterList`, `accountingPeriodId`) — shared across concurrent requests (thread-safety bug, irrelevant to migration but explains odd prints).
- Name for layout: `!IsArabic ? "rptIncomeStatmentActivityBudgetYearToDate" : "rptIncomeStatmentActivityBudgetYearToDateAr"`.
- Header captions computed in the ctor (reproduce as report parameters):
  - `clPeriod1/2/3 = fromDate.ToString("M/yyyy")`; `clLastPeriod = fromDate.AddYears(-1).ToString("M/yyyy")`
  - `clYearDate1/2/3 = "1-" + fromDate.ToString("M/yyyy")`; `clLastYearDate = "1-" + fromDate.AddYears(-1).ToString("M/yyyy")`
  - `clYearYear/clYearYear2 = "yyyy-(yyyy-1)"` of fromDate
  - `txtDateFrom/txtDateTo = {0:dd/MM/yyyy}` of sub-period start/end
  - `lblRevised`: null → "Both Journals Revised & NOT Revised" / "كلا الحسابات المراجعه و غير المراجعه"; true → "All Journals Revised" / "الحسابات المراجعه فقط"; false → "All Journals NOT Revised" / "الحسابات الغير مراجعه فقط"
  - `lblCostCenter = costCenterList != "" ? ApiLoggedUser.GetCostCenterNamesByCostCenterIdList(costCenterList) : ""`
- `rptIncomeStatemet_BeforePrint`:
  - Arabic: RTL; rebinds `lblAccType` → `ActivityIncome.AccountTypeNameArabic`, `lblAccTypeTot` → `Acc_IncomeStatment.AccountTypeNameArabic`.
  - Fills (exact):
    ```csharp
    acc_SystemConfigurationTableAdapter.Fill(ds.Acc_SystemConfiguration);
    activityIncomeTableAdapter.Fill(ds.ActivityIncome, accountingPeriodId, revised, journalTypes, (costCenterList.Length == 0) ? null : costCenterList, null);
    acc_IncomeStatmentTableAdapter.Fill(ds.Acc_IncomeStatment, accountingPeriodId, revised, journalTypes, (costCenterList.Length == 0) ? null : costCenterList, null);
    ```
    (args map to `@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, @BranchList`)
- `Detail2_BeforePrint` (detail of `Acc_IncomeStatment`): `e.Cancel = true` when `AccountTypeId == 1 (Operating_income) || == 2 (Operating_expenses)` → the bottom section prints only the **other** income-nature account types (3 Other income, 4 Admin & General, 5 Other expenses, 13 …), because types 1/2 are already shown per cost center above.
- `GroupFooter2_BeforePrint` (per cost-center group, the "%" row) — reproduce exactly (it is buggy):
  ```csharp
  string name = DetailReport.GetCurrentColumnValue("CostCenterName").ToString();
  decimal[] gop = new decimal[10]; decimal[] revenu = new decimal[10];
  foreach (var item in ds.ActivityIncome.Where(u => u.CostCenterName == name)) {
      gop[0] += item.PeriodBalance; gop[1] += item.PeriodBudget; gop[2] += item.BudgetDiff;
      gop[3] += item.LastBalance;   gop[4] += item.LastBalanceDiff; gop[5] += item.YearToPeriodBalance;
      gop[6] += item.YearToPeriodBudget; gop[7] += item.YearToPeriodBudgetDiff;
      gop[8] += item.LastYearToPeriodBalance; gop[9] += item.YearToPeriodBudgetDiff;   // [9] copy bug: should be LastYearToPeriodBalanceDiff
      revenu[i] = <same field> < 0 ? <same field> : revenu[i];                       // for i = 0..9, same field order
  }
  cell_i.Text = (revenu[i] == 0 ? 0 : gop[i] / revenu[i]).ToString("p");
  ```
  Every `ActivityIncome` numeric column is `ABS(...)` in SQL, so `< 0` is never true → `revenu[i]` stays 0 → **every % cell prints 0.00 %** in practice. (Designer also gives these cells `XRSummary Func=Percentage`, but the BeforePrint text overrides.)
- Layout summaries (from Designer, all `{0:n2}`):
  - `GroupFooter2` "GOP" row (Ar "اجمالي الربح"): `SummaryRunning.Group` SUM of `CalculatedPeriodBalance, CalculatedPeriodBudget, CalBudgetDiff, CalLastBalance, CalLastBalanceDiff, CalYearToPeriodBalance, CalYearToPeriodBudget, CalYearToPeriodBudgetDiff, CalLastYearToPeriodBalance, CasLastYearToPeriodBalanceDiff` over the cost center's type-1 and type-2 rows (Cal* = value, negated for type 2 → GOP = |income| − |expense| per column; note the Diff columns are `±ABS(diff)` so GOP of a diff column is not a real variance).
  - `ReportFooter` of DetailReport "Total Cost Center GOP" (Ar "اجمالي ارباح مركز التكلفة"): same 10 Cal* columns, `SummaryRunning.Report` (all cost centers).
  - `GroupFooter1` of DetailReport1 "Net Profit" (Ar "صافي الربح"): `SummaryRunning.Report` SUM of `Acc_IncomeStatment.Cal*` (10 columns: `CalPeriodBalance, CalPeriodBudget, CalBudgetDiff, CalLastBalance, CalLastBalanceDiff, CalYearToPeriodBalance, CalYearToPeriodBudget, CalYearToPeriodBudgetDiff, CalLastYearToPeriodBalance, CalLastYearToPeriodBalanceDiff`), where Cal = −ABS for types (2,4,5,13), +ABS otherwise. Open question: whether the summary includes the cancelled type 1/2 rows (DevExpress normally accumulates summaries on data rows even when the band print is cancelled → Net Profit = all income-nature types).

### ds: `...\IncomeStatmentActivityBudgetYearToDate\dsIncomeStatmentActivity.xsd` (shared with report 2)
TableAdapters: `Acc_SystemConfiguration`, `ActivityIncome` (report 1), `BranchIncomeState` (report 2), `Acc_IncomeStatment` (both). All params: `@AccPeriodList Int32 (not null), @JournalRevise Boolean (nullable), @JournalTypeList String, @CostCenterList String (nullable), @BranchList String (nullable)`.

**ActivityIncome** (verbatim):
```sql
WITH    AccountBalance ( AccountId, AccountTypeId, LastBalance, PeriodBalance, PeriodBudget, YearToPeriodBalance, LastYearToPeriodBalance, YearToPeriodBudget,CostCenterId )
          AS ( SELECT   Acc_Account.AccountId,
                       Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.LastDebit), 0)
                        - ISNULL(SUM(Balance.LastCredit), 0) AS LastBalance,
                        ISNULL(SUM(Balance.PeriodDebit), 0)
                        - ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodBalance,
                        ISNULL(SUM(Balance.PeriodBudget), 0) AS PeriodBudget,
                        ISNULL(SUM(Balance.YearToPeriodDebit), 0)
                        - ISNULL(SUM(Balance.YearToPeriodCredit), 0) AS YearToPeriodBalance,
                        ISNULL(SUM(Balance.LastYearToPeriodDebit), 0)
                        - ISNULL(SUM(Balance.LastYearToPeriodCredit), 0) AS LastYearToPeriodBalance,
                        ISNULL(SUM(Balance.YearToPeriodBudget), 0) AS YearToPeriodBudget
                        ,CostCenterId
			   FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId AS AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    PeriodCredit AS PeriodCredit,
                                                    PeriodDebit AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, CostCenterId
                                          FROM      Acc_GetAccountJournalActionsBetweenAccPeriod
										  (@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenAccPeriod_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    PeriodCredit AS LastCredit,
                                                    PeriodDebit AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, CostCenterId
                                          FROM      Acc_GetAccountJournalActionsBetweenAccPeriodLastYear
										  (@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenAccPeriodLastYear_1
                                          UNION ALL
                                          SELECT    Acc_AccountBudget.AccontId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    Acc_AccountBudget.BudgetValue,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, CostCenterId
                                          FROM      Acc_AccountBudget
                                          WHERE     AccountingSubPeriodId = @AccPeriodList 
										  and (( @CostCenterList IS NULL )
            OR ( Acc_AccountBudget.CostCenterId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@CostCenterList) AS Acc_ConvertIntListToTable_1 ) ))
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    PeriodCredit AS YearToPeriodCredit,
                                                    PeriodDebit AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, CostCenterId
                                          FROM      Acc_GetAccountJournalActionsYearToAccPeriod(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsYearToAccPeriod_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    PeriodCredit AS LastYearToPeriodCredit,
                                                    PeriodDebit AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, CostCenterId
                                          FROM      Acc_GetAccountJournalActionsLastYearToAccPeriod(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsLastYearToAccPeriod_1
                                          UNION ALL
                                          SELECT    Acc_AccountBudget.AccontId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    Acc_AccountBudget.BudgetValue AS YearToPeriodBudget
													, CostCenterId
                                          FROM      Acc_AccountBudget
                                          WHERE     AccountingSubPeriodId in (
                                                    SELECT  AccountingSubPeriodId
                                                    FROM    Acc_AccountingSubPeriod
                                                    WHERE   ( AccountingPeriodId = ( SELECT AccountingPeriodId
                                                                                     FROM   Acc_AccountingSubPeriod AS Acc_AccountingSubPeriod_1
                                                                                     WHERE  ( AccountingSubPeriodId = @AccPeriodList )
                                                                                   ) )
                                                            AND ( SubPeriodStart < ( SELECT SubPeriodStart
                                                                                     FROM   Acc_AccountingSubPeriod
                                                                                     WHERE  ( AccountingSubPeriodId = @AccPeriodList )
                                                                                   ) ) )
									and (( @CostCenterList IS NULL )
            OR ( Acc_AccountBudget.CostCenterId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@CostCenterList) AS Acc_ConvertIntListToTable_1 ) ))
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               
               GROUP BY Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        AccountTypeId
						,CostCenterId
             )
    SELECT  Acc_CostCenter.CostCenterNo,
            Acc_CostCenter.CostCenterName,
           Acc_AccountType.AccountTypeName,
		    Acc_AccountType.AccountTypeNameArabic,
           ABS( ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) AS PeriodBalance,
           ABS(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) AS PeriodBudget,
           ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) AS BudgetDiff,
            ABS(ISNULL(SUM(AccountBalance_1.LastBalance), 0)) AS LastBalance,

            ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0)) AS LastBalanceDiff,

            abs(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)) AS YearToPeriodBalance,
            abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)) AS YearToPeriodBudget,

            abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)) AS YearToPeriodBudgetDiff,


            abs(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance),0)) AS LastYearToPeriodBalance,

           ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)) AS LastYearToPeriodBalanceDiff

            ,AccountBalance_1.CostCenterId,AccountBalance_1.AccountTypeId,

         case when AccountBalance_1.AccountTypeId = 2
		 then (-1* abs( ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)))
		 else  abs( ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) end as CalculatedPeriodBalance ,

		  case when AccountBalance_1.AccountTypeId = 2
		 then (-1* abs(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)))
		 else  abs(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) end as CalculatedPeriodBudget,

		 case when AccountBalance_1.AccountTypeId = 2
		 then (-1*  ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0))) 
	else (  ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0))) end as CalBudgetDiff,

			case when AccountBalance_1.AccountTypeId = 2 
			then (-1* abs (ISNULL(SUM(AccountBalance_1.LastBalance), 0)) )
	else  abs (ISNULL(SUM(AccountBalance_1.LastBalance), 0)) end as CalLastBalance,

      case when AccountBalance_1.AccountTypeId = 2
	  then (-1* ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0)))
	else ( ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0))) end as CalLastBalanceDiff,

case when AccountBalance_1.AccountTypeId = 2
then (-1* abs(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)))
else  abs(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)) end as CalYearToPeriodBalance,

case when AccountBalance_1.AccountTypeId = 2
then (-1*  abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) 
else (  abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) end as CalYearToPeriodBudget,

CASE WHEN AccountBalance_1.AccountTypeId = 2 
then (-1* abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)))
else ( abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) end as CalYearToPeriodBudgetDiff,

CASE WHEN AccountBalance_1.AccountTypeId = 2 
then (-1* abs(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance),0)))
else ( abs(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance),0))) end as CalLastYearToPeriodBalance ,

case when AccountBalance_1.AccountTypeId = 2 
then (-1 *ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)))
else (ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0))) end as CasLastYearToPeriodBalanceDiff 


    FROM    AccountBalance AS AccountBalance_1
            inner JOIN Acc_CostCenter ON Acc_CostCenter.CostCenterId = AccountBalance_1.CostCenterId
            INNER JOIN Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
			where AccountBalance_1.AccountTypeId in (1,2)
	    GROUP BY Acc_CostCenter.CostCenterNo,
             Acc_CostCenter.CostCenterName,
            Acc_AccountType.AccountTypeName,
			  Acc_AccountType.AccountTypeNameArabic ,AccountBalance_1.CostCenterId,
			  AccountBalance_1.AccountTypeId
    ORDER BY Acc_CostCenter.CostCenterNo , AccountBalance_1.AccountTypeId
```
Columns: AccountTypeName, AccountTypeNameArabic, PeriodBalance, PeriodBudget, BudgetDiff, LastBalance, LastBalanceDiff, YearToPeriodBalance, YearToPeriodBudget, YearToPeriodBudgetDiff, LastYearToPeriodBalance, LastYearToPeriodBalanceDiff, CostCenterNo, CostCenterName, CostCenterId, AccountTypeId, CalculatedPeriodBalance, CalculatedPeriodBudget, CalBudgetDiff, CalLastBalance, CalLastBalanceDiff, CalYearToPeriodBalance, CalYearToPeriodBudget, CalYearToPeriodBudgetDiff, CalLastYearToPeriodBalance, CasLastYearToPeriodBalanceDiff.
Notes: no leaf-account filter here (unlike `Acc_IncomeStatment`); budget rows filtered only by cost center (branch list ignored for budget even if passed); journal rows with `CostCenterId NULL` and budget rows with `CostCenterId NULL` are dropped by the `INNER JOIN Acc_CostCenter`; only `AccountTypeId IN (1,2)`.

**Acc_IncomeStatment** (verbatim; also used by report 2):
```sql
WITH    AccountBalance ( AccountId, BusinessActivityId, AccountTypeId, LastBalance, PeriodBalance, PeriodBudget, YearToPeriodBalance, LastYearToPeriodBalance, YearToPeriodBudget )
          AS ( SELECT   Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.LastDebit), 0)
                        - ISNULL(SUM(Balance.LastCredit), 0) AS LastBalance,
                        ISNULL(SUM(Balance.PeriodDebit), 0)
                        - ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodBalance,
                        ISNULL(SUM(Balance.PeriodBudget), 0) AS PeriodBudget,
                        ISNULL(SUM(Balance.YearToPeriodDebit), 0)
                        - ISNULL(SUM(Balance.YearToPeriodCredit), 0) AS YearToPeriodBalance,
                        ISNULL(SUM(Balance.LastYearToPeriodDebit), 0)
                        - ISNULL(SUM(Balance.LastYearToPeriodCredit), 0) AS LastYearToPeriodBalance,
                        ISNULL(SUM(Balance.YearToPeriodBudget), 0) AS YearToPeriodBudget
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId AS AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    PeriodCredit AS PeriodCredit,
                                                    PeriodDebit AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
                                          FROM      Acc_GetAccountJournalActionsBetweenAccPeriod(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenAccPeriod_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    PeriodCredit AS LastCredit,
                                                    PeriodDebit AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
                                          FROM      Acc_GetAccountJournalActionsBetweenAccPeriodLastYear(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenAccPeriodLastYear_1
                                          UNION ALL
                                          SELECT    Acc_AccountBudget.AccontId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    Acc_AccountBudget.BudgetValue,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
                                          FROM      Acc_AccountBudget
                                          WHERE     AccountingSubPeriodId = @AccPeriodList
										  and  (( @BranchList IS NULL )
            OR ( Acc_AccountBudget.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
and  (( @CostCenterList IS NULL )
            OR ( Acc_AccountBudget.CostCenterId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@CostCenterList) AS Acc_ConvertIntListToTable_1 ) ))
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    PeriodCredit AS YearToPeriodCredit,
                                                    PeriodDebit AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
                                          FROM      Acc_GetAccountJournalActionsYearToAccPeriod(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsYearToAccPeriod_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    PeriodCredit AS LastYearToPeriodCredit,
                                                    PeriodDebit AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
                                          FROM      Acc_GetAccountJournalActionsLastYearToAccPeriod(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsLastYearToAccPeriod_1
                                          UNION ALL
                                          SELECT    Acc_AccountBudget.AccontId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    Acc_AccountBudget.BudgetValue AS YearToPeriodBudget
                                          FROM      Acc_AccountBudget
                                          WHERE     AccountingSubPeriodId in (
                                                    SELECT  AccountingSubPeriodId
                                                    FROM    Acc_AccountingSubPeriod
                                                    WHERE   ( AccountingPeriodId = ( SELECT AccountingPeriodId
                                                                                     FROM   Acc_AccountingSubPeriod AS Acc_AccountingSubPeriod_1
                                                                                     WHERE  ( AccountingSubPeriodId = @AccPeriodList )
                                                                                   ) )
                                                            AND ( SubPeriodStart < ( SELECT SubPeriodStart
                                                                                     FROM   Acc_AccountingSubPeriod
                                                                                     WHERE  ( AccountingSubPeriodId = @AccPeriodList )
                                                                                   ) ) )
								and  (( @BranchList IS NULL )
            OR ( Acc_AccountBudget.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
and  (( @CostCenterList IS NULL )
            OR ( Acc_AccountBudget.CostCenterId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@CostCenterList) AS Acc_ConvertIntListToTable_1 ) ))
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
			case when Acc_AccountType.AccountTypeId in (2,4,5,13) 
			then (-1 * ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0))) else ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) end AS CalPeriodBalance,

            ABS(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) AS PeriodBudget,
			case when Acc_AccountType.AccountTypeId in (2,4,5,13) 
			then (-1 *  ABS(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0))) else  ABS(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) end as CalPeriodBudget,

            ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) AS BudgetDiff,
			case when Acc_AccountType.AccountTypeId in (2,4,5,13) 
			then (-1 *ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0))) else
			 ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0))  end as CalBudgetDiff,

            ABS(ISNULL(SUM(AccountBalance_1.LastBalance), 0)) AS LastBalance,
case when Acc_AccountType.AccountTypeId in (2,4,5,13) 
			then(-1 * ABS(ISNULL(SUM(AccountBalance_1.LastBalance), 0)))
	else  ABS(ISNULL(SUM(AccountBalance_1.LastBalance), 0)) end as CalLastBalance,

            ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0)) AS LastBalanceDiff,
case when Acc_AccountType.AccountTypeId in (2,4,5,13) 
then (-1 *  ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0)))
else ( ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0))) end as CalLastBalanceDiff,

            ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)) AS YearToPeriodBalance,
case when Acc_AccountType.AccountTypeId in (2,4,5,13) then (-1 * ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0))) 
else ( ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)))
end as CalYearToPeriodBalance,

            ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)) AS YearToPeriodBudget,
case when  Acc_AccountType.AccountTypeId in (2,4,5,13) then (-1 *  ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) 
else (ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) end as CalYearToPeriodBudget,

            ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)) AS YearToPeriodBudgetDiff,
	case when  Acc_AccountType.AccountTypeId in (2,4,5,13) then (-1 *ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)))
		else (ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)))
			end as CalYearToPeriodBudgetDiff,

            ABS(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)) AS LastYearToPeriodBalance,
case when  Acc_AccountType.AccountTypeId in (2,4,5,13) then (-1 *ABS(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)))
else (ABS(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0))) end as CalLastYearToPeriodBalance,

            ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)) AS LastYearToPeriodBalanceDiff,
case when  Acc_AccountType.AccountTypeId in (2,4,5,13) then (-1* ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)))
else ( ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)))	
			 end as CalLastYearToPeriodBalanceDiff
   
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
Columns: AccountTypeId, AccountTypeName, AccountTypeNameArabic, PeriodBalance, PeriodBudget, BudgetDiff, LastBalance, LastBalanceDiff, YearToPeriodBalance, YearToPeriodBudget, YearToPeriodBudgetDiff, LastYearToPeriodBalance, LastYearToPeriodBalanceDiff, CalPeriodBalance, CalPeriodBudget, CalBudgetDiff, CalLastBalance, CalLastBalanceDiff, CalYearToPeriodBalance, CalYearToPeriodBudget, CalYearToPeriodBudgetDiff, CalLastYearToPeriodBalance, CalLastYearToPeriodBalanceDiff.
Semantics of the four period TVFs (all keyed on a sub-period id): `BetweenAccPeriod` = the selected sub-period; `BetweenAccPeriodLastYear` = same sub-period one year earlier ("Last Year"); `YearToAccPeriod` = start of fiscal period → end of selected sub-period ("Year To Date"); `LastYearToAccPeriod` = same YTD window a year earlier. YTD budget = budgets of all sub-periods of the same `AccountingPeriodId` with `SubPeriodStart < selected SubPeriodStart` (**excludes the selected month's own budget** — check whether that is intended).

### SQL objects used → cloud DB (`D:\Hadaf\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\...`)
| Object | Cloud path |
|---|---|
| `Acc_GetAccountJournalActionsBetweenAccPeriod` | `Functions\Acc_GetAccountJournalActionsBetweenAccPeriod.sql` (7 params, returns AccountId, CostCenterId, Credit, Debit, PeriodCredit, PeriodDebit, BranchId) |
| `Acc_GetAccountJournalActionsBetweenAccPeriodLastYear` | `Functions\Acc_GetAccountJournalActionsBetweenAccPeriodLastYear.sql` |
| `Acc_GetAccountJournalActionsYearToAccPeriod` | `Functions\Acc_GetAccountJournalActionsYearToAccPeriod.sql` |
| `Acc_GetAccountJournalActionsLastYearToAccPeriod` | `Functions\Acc_GetAccountJournalActionsLastYearToAccPeriod.sql` |
| `Acc_ConvertIntListToTable` | `Functions\Acc_ConvertIntListToTable.sql` |
| `Acc_AccountBudget` (AccontId, AccountingSubPeriodId, BudgetValue money, BranchId, CostCenterId, IsFixed*) | `Tables\Acc_AccountBudget.sql` |
| `Acc_AccountingSubPeriod`, `Acc_Account`, `Acc_AccountType`, `Acc_CostCenter`, `Acc_Branch`, `Acc_SystemConfiguration` | `Tables\<name>.sql` (all present, all registered in the .sqlproj) |

### Layout (Designer: `rptIncomeStatmentActivityBudgetYearToDate.Designer.cs`)
- **Fixed column set, NOT a pivot.** 11 columns: Description + Period block (Balance, Budget, B. Deviation, Last Year, LY Deviation) + Year-To-Date block (same five). Header row 2 shows `M/yyyy`, `1-M/yyyy`, `yyyy-yyyy` captions.
- Bands: `ReportHeader` (company), `PageHeader` (title "Income Statement Year To Date Report" / Ar "تقرير قائمة الدخل مقارن مراكز تكلفة شهر / سنه", From/To date, lblRevised, lblCostCenter, 2-row column header with "Year To Date" span), `DetailReport` (DataMember `ActivityIncome`, Level 0): `GroupHeader2` (GroupFields `CostCenterNo`, prints `CostCenterName`), `Detail1` (one row per account type 1 / 2 with the 10 numbers), `GroupFooter2` (GOP row + % row), `ReportFooter` ("Total Cost Center GOP"); `DetailReport1` (DataMember `Acc_IncomeStatment`, Level 1): `Detail2` (other types, 1/2 cancelled), `GroupFooter1` ("Net Profit"). `PageFooter`.
- Cells bound to `ActivityIncome.BusinessActivity` in GroupFooter2 — column does not exist (prints blank).

---

## 2. Income Statement by Branch Month/Year (`income-statment-branch-budget-report`)

**Same rpt family / same xsd as report 1** (branch twin). Only differences listed.

### Angular
- Route: module line 139, `IncomeStatmentPeriodsBranchReportShellComponent`, `data: { ModuleId: 72 }`.
- Menu: `routes.ts` line 830-836, id `6_1_3_4`, "By Branch Month to Year" / "فروع شهر / سنة", `params: ''`.
- Shell: `...\income-statment-periods-branch-report\income-statment-periods-branch-report-shell\...component.ts`, default report `'IncomeStatmentBranchBudget'`, title key `FINANCIALREPORTS._IncomeStatmentBranchBudgetReport_`.
- Form: `...\income-statment-periods-branch-report-form\...`: `accountingPeriodId` (required), `toDate` (unused), `revised` (initial `''`, radio → `' '`/true/false), `journalTypes`, `branchesIds` (re-read from `branchRef.BranchForm.BranchList` in `filter()`).
- iframe: `{printUrl}FinancialReports/IncomeStatmentBranchBudget?lang=..&accountingPeriodId=<id>&toDate=&revised=..&journalTypes=<csv>&branchesIds=<csv>`

### MVC
- Controller line 145-154: `IncomeStatmentBranchBudget(string lang, int accountingPeriodId, bool? revised, string journalTypes, string branchesIds)` → `new rptIncomeStatmentBranchBudgetYearToDate(accountingPeriodId, PeriodDates["Start"], PeriodDates["End"], revised, journalTypes, branchesIds)`.

### rpt: `...\IncomeStatmentActivityBudgetYearToDate\rptIncomeStatmentBranchBudgetYearToDate.cs`
- Identical to report 1 except (diffed):
  - Fills: `branchIncomeStateTableAdapter1.Fill(ds.BranchIncomeState, accountingPeriodId, revised, journalTypes, null, (branchList.Length == 0) ? null : branchList);` and `acc_IncomeStatmentTableAdapter.Fill(ds.Acc_IncomeStatment, accountingPeriodId, revised, journalTypes, null, (branchList.Length == 0) ? null : branchList);` (cost-center list always NULL).
  - `lblCostCenter` code commented out (no branch-name caption).
  - **Bug:** Arabic rebinds `lblAccType` to `ActivityIncome.AccountTypeNameArabic` while the band is bound to `BranchIncomeState` → account-type names print blank in Arabic.
  - **Bug:** `GroupFooter2_BeforePrint` reads `DetailReport.GetCurrentColumnValue("BranchName")` but then iterates `dsIncomeStatementActivity1.ActivityIncome.Where(u => u.CostCenterName == name)` — `ActivityIncome` is never filled here → all % cells 0.00 % (they are 0 anyway, see report 1).
  - Name: `"rptIncomeStatmentBranchBudgetYearToDate"` / `"...Ar"`.
- Layout: identical tree; DetailReport DataMember `BranchIncomeState`, `GroupHeader2` GroupFields `BranchCode`, header cell `BranchName`, title "Income Statement By Branch Year To Date Report" / "تقرير قائمة الدخل مقارن فروع شهر / سنه"; Ar footer label "اجمالي ربح مركز التكلفة" (says cost center though it is branch).

### ds `BranchIncomeState` (verbatim)
```sql
WITH    AccountBalance ( AccountId, AccountTypeId, LastBalance, PeriodBalance, PeriodBudget, YearToPeriodBalance, LastYearToPeriodBalance, YearToPeriodBudget,BranchId )
          AS ( SELECT   Acc_Account.AccountId,
                       Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.LastDebit), 0)
                        - ISNULL(SUM(Balance.LastCredit), 0) AS LastBalance,
                        ISNULL(SUM(Balance.PeriodDebit), 0)
                        - ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodBalance,
                        ISNULL(SUM(Balance.PeriodBudget), 0) AS PeriodBudget,
                        ISNULL(SUM(Balance.YearToPeriodDebit), 0)
                        - ISNULL(SUM(Balance.YearToPeriodCredit), 0) AS YearToPeriodBalance,
                        ISNULL(SUM(Balance.LastYearToPeriodDebit), 0)
                        - ISNULL(SUM(Balance.LastYearToPeriodCredit), 0) AS LastYearToPeriodBalance,
                        ISNULL(SUM(Balance.YearToPeriodBudget), 0) AS YearToPeriodBudget
                        ,Balance.BranchId
			   FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId AS AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    PeriodCredit AS PeriodCredit,
                                                    PeriodDebit AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, BranchId
                                          FROM      Acc_GetAccountJournalActionsBetweenAccPeriod
										  (@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenAccPeriod_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    PeriodCredit AS LastCredit,
                                                    PeriodDebit AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, BranchId
                                          FROM      Acc_GetAccountJournalActionsBetweenAccPeriodLastYear
										  (@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenAccPeriodLastYear_1
                                          UNION ALL
                                          SELECT    Acc_AccountBudget.AccontId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    Acc_AccountBudget.BudgetValue,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, BranchId
                                          FROM      Acc_AccountBudget
                                          WHERE     AccountingSubPeriodId = @AccPeriodList 
										  and (( @BranchList IS NULL )
            OR ( Acc_AccountBudget.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    PeriodCredit AS YearToPeriodCredit,
                                                    PeriodDebit AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, BranchId
                                          FROM      Acc_GetAccountJournalActionsYearToAccPeriod(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsYearToAccPeriod_1
                                          UNION ALL
                                          SELECT    AccountId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    PeriodCredit AS LastYearToPeriodCredit,
                                                    PeriodDebit AS LastYearToPeriodDebit,
                                                    0 AS YearToPeriodBudget
													, BranchId
                                          FROM      Acc_GetAccountJournalActionsLastYearToAccPeriod(@AccPeriodList, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsLastYearToAccPeriod_1
                                          UNION ALL
                                          SELECT    Acc_AccountBudget.AccontId,
                                                    0 AS LastCredit,
                                                    0 AS LastDebit,
                                                    0 AS PeriodCredit,
                                                    0 AS PeriodDebit,
                                                    0 AS PeriodBudget,
                                                    0 AS YearToPeriodCredit,
                                                    0 AS YearToPeriodDebit,
                                                    0 AS LastYearToPeriodCredit,
                                                    0 AS LastYearToPeriodDebit,
                                                    Acc_AccountBudget.BudgetValue AS YearToPeriodBudget
													, BranchId
                                          FROM      Acc_AccountBudget
                                          WHERE     AccountingSubPeriodId in (
                                                    SELECT  AccountingSubPeriodId
                                                    FROM    Acc_AccountingSubPeriod
                                                    WHERE   ( AccountingPeriodId = ( SELECT AccountingPeriodId
                                                                                     FROM   Acc_AccountingSubPeriod AS Acc_AccountingSubPeriod_1
                                                                                     WHERE  ( AccountingSubPeriodId = @AccPeriodList )
                                                                                   ) )
                                                            AND ( SubPeriodStart < ( SELECT SubPeriodStart
                                                                                     FROM   Acc_AccountingSubPeriod
                                                                                     WHERE  ( AccountingSubPeriodId = @AccPeriodList )
                                                                                   ) ) )
									and (( @BranchList IS NULL )
            OR ( Acc_AccountBudget.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               
               GROUP BY Acc_Account.AccountId,
                        Acc_Account.BusinessActivityId,
                        AccountTypeId
						,Balance.BranchId
             )
    SELECT  Acc_Branch.BranchCode,
            Acc_Branch.BranchName,
           Acc_AccountType.AccountTypeName,
		    Acc_AccountType.AccountTypeNameArabic,
           abs( ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) AS PeriodBalance,
            abs(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) AS PeriodBudget,

           ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) AS BudgetDiff,

            abs (ISNULL(SUM(AccountBalance_1.LastBalance), 0)) AS LastBalance,

            ABs(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0)) AS LastBalanceDiff,

            abs(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)) AS YearToPeriodBalance,
            abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)) AS YearToPeriodBudget,
            abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)) AS YearToPeriodBudgetDiff,
            abs(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance),0)) AS LastYearToPeriodBalance,
           ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)) AS LastYearToPeriodBalanceDiff
            ,AccountBalance_1.BranchId,AccountBalance_1.AccountTypeId,
			   case when AccountBalance_1.AccountTypeId = 2
		 then (-1* abs( ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)))
		 else  abs( ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)) end as CalculatedPeriodBalance ,

		  case when AccountBalance_1.AccountTypeId = 2
		 then (-1* abs(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)))
		 else  abs(ISNULL(SUM(AccountBalance_1.PeriodBudget), 0)) end as CalculatedPeriodBudget,

		 case when AccountBalance_1.AccountTypeId = 2
		 then (-1*  ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0))) 
	else (  ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodBudget), 0))) end as CalBudgetDiff,

			case when AccountBalance_1.AccountTypeId = 2 
			then (-1* abs (ISNULL(SUM(AccountBalance_1.LastBalance), 0)) )
	else  abs (ISNULL(SUM(AccountBalance_1.LastBalance), 0)) end as CalLastBalance,

      case when AccountBalance_1.AccountTypeId = 2
	  then (-1* ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0)))
	else ( ABS(ISNULL(SUM(AccountBalance_1.PeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastBalance), 0))) end as CalLastBalanceDiff,

case when AccountBalance_1.AccountTypeId = 2
then (-1* abs(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)))
else  abs(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)) end as CalYearToPeriodBalance,

case when AccountBalance_1.AccountTypeId = 2
then (-1*  abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) 
else (  abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) end as CalYearToPeriodBudget,

CASE WHEN AccountBalance_1.AccountTypeId = 2 
then (-1* abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0)))
else ( abs (ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.YearToPeriodBudget), 0))) end as CalYearToPeriodBudgetDiff,

CASE WHEN AccountBalance_1.AccountTypeId = 2 
then (-1* abs(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance),0)))
else ( abs(ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance),0))) end as CalLastYearToPeriodBalance ,

case when AccountBalance_1.AccountTypeId = 2 
then (-1 *ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0)))
else (ABS(ISNULL(SUM(AccountBalance_1.YearToPeriodBalance), 0)
            - ISNULL(SUM(AccountBalance_1.LastYearToPeriodBalance), 0))) end as CasLastYearToPeriodBalanceDiff 
    
	FROM    AccountBalance AS AccountBalance_1
            inner JOIN Acc_Branch ON Acc_Branch.BranchId = AccountBalance_1.BranchId
            INNER JOIN Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
			where AccountBalance_1.AccountTypeId in (1,2)
	    GROUP BY Acc_Branch.BranchCode,
             Acc_Branch.BranchName,
            Acc_AccountType.AccountTypeName,
			  Acc_AccountType.AccountTypeNameArabic ,AccountBalance_1.BranchId,
			  AccountBalance_1.AccountTypeId
    ORDER BY Acc_Branch.BranchCode , AccountBalance_1.AccountTypeId
```
Columns: BranchCode, BranchName, AccountTypeName, AccountTypeNameArabic, PeriodBalance, PeriodBudget, BudgetDiff, LastBalance, LastBalanceDiff, YearToPeriodBalance, YearToPeriodBudget, YearToPeriodBudgetDiff, LastYearToPeriodBalance, LastYearToPeriodBalanceDiff, BranchId, AccountTypeId, CalculatedPeriodBalance, CalculatedPeriodBudget, CalBudgetDiff, CalLastBalance, CalLastBalanceDiff, CalYearToPeriodBalance, CalYearToPeriodBudget, CalYearToPeriodBudgetDiff, CalLastYearToPeriodBalance, CasLastYearToPeriodBalanceDiff.
Plus `Acc_IncomeStatment` (verbatim in report 1) called with `@CostCenterList = NULL, @BranchList = branches`. SQL objects: same as report 1 (all present).

---

## 3. Cost Center Income Statement vs Budget (`costcenter-income-statment-budget-report`)

### Angular
- Route: module line 145, `CostcenterIncomeBudgetShellComponent`, `data: { ModuleId: 72 }`.
- Menu: `routes.ts` line 838-844, id `6_1_3_5`, "Cost Center Income Statement Budget Comparison" / "قائمة الدخل بمراكز التكلفة مقارن تقديري", `params: ''`.
- Shell: `...\costcenter-income-budget\costcenter-income-budget-shell\costcenter-income-budget-shell.component.ts`: default report `'CostCenterIncomeStatementBudget'`; `obj.year = format(new Date(obj.year), 'yyyy')`; requires `year`. Title key `FINANCIALREPORTS._CostCenterIncomeStatementBudgetReport_`.
- Form: `...\costcenter-income-budget-form\...`: `month` (init `0`, patched `true` in ngAfterViewInit), `year` (dx-date-box `displayFormat="yyyy"`, default `new Date()`, required), `revised` (`''` → radio `' '`/true/false), `journalTypes`, `costCenterIds`. Period radio (`onOptionChanged`, not `onValueChanged`): Id 0 "من 1 إلى 6 / From 1 To 6" → `month=true`; Id 1 "من 6 إلى 12 / From 6 To 12" → `false`; Id 2 "من 1 إلى 12 / From 1 To 12" → `null`.
- iframe: `{printUrl}FinancialReports/CostCenterIncomeStatementBudget?lang=..&month=<true|false|null>&year=<yyyy>&revised=..&journalTypes=<csv>&costCenterIds=<csv>`

### MVC (controller line 157-195)
```csharp
public IActionResult CostCenterIncomeStatementBudget(string lang, bool? revised, string journalTypes, string costCenterIds, bool? month, int year)
// month == true  : fromMonth=1, toMonth=6,  fromDate=new DateTime(year,1,1), toDate=new DateTime(year,6,30,23,59,59)
// month == false : fromMonth=6, toMonth=12, fromDate=new DateTime(year,6,1), toDate=new DateTime(year,12,31,23,59,59)   <-- June counted in BOTH halves
// month == null  : fromMonth=1, toMonth=12, fromDate=new DateTime(year,1,1), toDate=new DateTime(year,12,31,23,59,59)
var report = new rptCostCenterIncomeStatementBudgetComparison(fromDate, toDate, revised, journalTypes, costCenterIds, fromMonth, toMonth);
```

### rpt: `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\CostCenterIncomeStatementBudgetComparison\rptCostCenterIncomeStatementBudgetComparison.cs`
- Ctor `(DateTime _fromDate, DateTime _toDate, bool? _revised, string _journalTypes, string _CostCenterList, int _FromMonth, int _ToMonth)`: from 00:00:00, to 23:59:59.997; `txtDateFrom.Text = fromMonth`, `txtDateTo.Text = toMonth` (header shows **month numbers** under "From Date"/"To Date").
- Name: `"rptCostCenterIncomeStatementBudgetComparison"` / `"...Ar"`.
- BeforePrint fills:
  ```csharp
  if (!IsArabic) {
    acc_ComparisonIncomeStatmentTableAdapter1.Fill(ds.Acc_ComparisonIncomeStatment, fromMonth, toMonth, fromDate, toDate, revised, journalTypes, costCenterList);
    comparisonActivityIncomeTableAdapter1.Fill(ds.ComparisonActivityIncome, fromMonth, toMonth, fromDate, toDate, revised, journalTypes, costCenterList);
  } else {
    acc_ComparisonIncomeStatmentTableAdapter1.FillByArabic(...same args...);
    comparisonActivityIncomeTableAdapter1.FillByArabic(...same args...);
  }
  ```
  (`costCenterList` passed raw — `''` vs null not normalized.)
- `lblRevised`: null → "Both Journals Revised & NOT Revised" / "جميع القيود"; true → "All Journals Revised" / "جميع القيودالمراجعة"; false → "All Journals NOT Revised" / "جميع الغير مراجعة".
- No C# arithmetic on the data. All math is in the **XRPivotGrid** engine:
  - `xrPivotGrid1_CustomCellDisplayText` / `xrPivotGrid2_CustomCellDisplayText`: for `ColumnValueType == Value` cells, `DisplayText = Math.Round(Math.Abs(value), 2)` → **detail cells print absolute values; total / grand-total cells keep the sign** (they are not `Value` type).
  - `CustomFieldSort`: `monthname` sorted by `number`; pivot 2 also sorts `AccountTypeName(Arabic)` by `AccountTypeId`.
  - Pivot 1 hidden (`e.Cancel`) if `ComparisonActivityIncome` empty; pivot 2 hidden if `Acc_ComparisonIncomeStatment` empty.
  - Arabic: field captions switched to `AccountTypeNameArabic`; grand total captions: pivot1 column GT "اجمالى القيمه", row GT "أجمالى الربح", column Total "اجمالى القيمه"; pivot2 column GT "اجمالى القيمه", row GT "الربح".

### Layout (Designer `rptCostCenterIncomeStatementBudgetComparison.Designer.cs`) — **PIVOT, dynamic month columns**
- Bands: `ReportHeader` (company), `PageHeader` (title "Cost Center Income Statement Budget Comparison" / "قائمة الدخل بمراكز التكلفة مقارن تقديرى", From/To month numbers, lblRevised), `GroupHeader1` holding two `XRPivotGrid`s, `PageFooter`. Report DataMember `Acc_SystemConfiguration`.
- `xrPivotGrid1` (DataMember `ComparisonActivityIncome`): Rows = `CostCenterName` (idx 0) > `AccountTypeName` (idx 1, custom sort); Columns = `monthname` (sorted by hidden `number`) > `MainItemId` (non-existent column, empty); Data = `SubItemBudgetValueBalance` "Budget" (idx 0), `SubItemActualBalance` "Actual" (idx 1). Default pivot totals on: per-cost-center row total, grand total row, grand-total column per data field. Headers hidden.
- `xrPivotGrid2` (DataMember `Acc_ComparisonIncomeStatment`): Rows = `AccountTypeName` (all income-nature types); Columns = `monthname` > `MainItemId`; Data = `BudgetValue` "Budget Value", `AcutalValue` "Acutal Value"; grand total row = "profit".
- Column count = number of months in range (6, 7 or 12) × 2 data fields + grand total × 2. Months appear only if at least one row has that `number`.

### ds: `...\CostCenterIncomeStatementBudgetComparison\dsCostCenterIncomeStatementBudgetComparison.xsd` (shared with report 4)
TableAdapters: `Acc_ComparisonIncomeStatment` (Fill, FillByArabic, FillByBranch, FillByBranchArabic), `Acc_SystemConfiguration`, `ComparisonActivityIncome` (Fill, FillByArabic), `ComparisonBranchIncome` (Fill, FillByArabic).
Params (cost-center variants): `@FromMonth Int32, @ToMonth Int32, @FromBalanceDate DateTime, @ToBalanceDate DateTime, @JournalRevise Boolean?, @JournalTypeList String, @CostCenterList String?`.

**ComparisonActivityIncome.Fill** (verbatim):
```sql
with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname,Acc_CostCenter.CostCenterId
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
inner join Acc_Account on 1=1 
inner join Acc_CostCenter on 1=1
			   )
,    AccountTable ( AccountId,AccountTypeId, PeriodCredit, PeriodDebit,CostCenterId,MNTH,Yer)
          AS ( 
		  
		  SELECT   Acc_Account.AccountId,
                         Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
						Balance.CostCenterId,
                       MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
				 FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId,
                                                     Credit,
                                                    Debit,
                                                    PeriodCredit,
                                                    PeriodDebit,
													CostCenterId,
													CreatedDate
										   FROM      dbo.Acc_GetAccountJournalActionsBetweenDates
										  (@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,null)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                        
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) ) 
			 GROUP BY Acc_Account.AccountId,Balance.CostCenterId,AccountTypeId
			   ,MONTH(Balance.CreatedDate),year(Balance.CreatedDate)
)
,accountBudgetTable as 
(        
 select case when AccountTypeId = 1 then 
	 sum(BudgetValue)
	 else (-1*sum(BudgetValue)) end as BudgetValue

 , AccontId as AccountId,Acc_AccountBudget.BranchId,CostCenterId , AccountingSubPeriodId
 ,Acc_Account.AccountTypeId
from Acc_AccountBudget
inner join Acc_Account on Acc_Account.AccountId = Acc_AccountBudget.AccontId 
where   (( @CostCenterList IS NULL )
            OR ( Acc_AccountBudget.CostCenterId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@CostCenterList) AS Acc_ConvertIntListToTable_1 ) ))
and ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
and AccountTypeId in (1,2)
group by Acc_AccountBudget.BranchId , CostCenterId,AccontId ,AccountingSubPeriodId,AccountTypeId
)
,AccountBalance as (
select  DISTINCT
accountBudgetTable.AccountId,accountBudgetTable.AccountTypeId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit ,
isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,
 isnull(accountBudgetTable.BudgetValue,0) as BudgetValue,accountBudgetTable.CostCenterId
,date.number,date.monthname
 
from accountBudgetTable 

right outer join date on date.number = accountBudgetTable.AccountingSubPeriodId
  and date.AccountId = accountBudgetTable.AccountId
  
 left outer join AccountTable on  AccountTable.AccountId = date.AccountId 
 and AccountTable.MNTH = accountBudgetTable.AccountingSubPeriodId
 and accountBudgetTable.CostCenterId = AccountTable.CostCenterId 
  )
   SELECT   Acc_CostCenter.CostCenterNo,
            Acc_CostCenter.CostCenterName,
			 Acc_CostCenter.CostCenterId,
           ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit,
           Acc_AccountType.AccountTypeName,
           Acc_AccountType.AccountTypeNameArabic,
		  AccountBalance_1.AccountTypeId,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS SubItemActualBalance
			, ISNULL (SUM(AccountBalance_1.BudgetValue),0) as SubItemBudgetValueBalance
           ,AccountBalance_1.number, AccountBalance_1.monthname  
    FROM    AccountBalance AS AccountBalance_1
            inner JOIN dbo.Acc_CostCenter ON Acc_CostCenter.CostCenterId = AccountBalance_1.CostCenterId
            INNER JOIN dbo.Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
			  where AccountBalance_1.AccountTypeId in (1,2)
            GROUP BY Acc_CostCenter.CostCenterNo,
           Acc_CostCenter.CostCenterName,
           Acc_AccountType.AccountTypeName,
		   Acc_CostCenter.CostCenterId,
		   AccountBalance_1.AccountTypeId,
           Acc_AccountType.AccountTypeNameArabic
		  ,AccountBalance_1.number, AccountBalance_1.monthname
           ORDER BY  Acc_CostCenter.CostCenterNo
```
**ComparisonActivityIncome.FillByArabic** = same, plus the `ArabicMonth` CASE (1→N'يناير ' … 12→N'ديسمبر ', note trailing space) projected `as monthname`, **and the actual sign is flipped**: `ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS SubItemActualBalance` (English: Debit − Credit). Detail cells hide it (ABS) but row totals / grand totals differ in sign between languages.
Columns: PeriodCredit, PeriodDebit, AccountTypeName, AccountTypeNameArabic, CostCenterNo, CostCenterName, CostCenterId, AccountTypeId, SubItemActualBalance, SubItemBudgetValueBalance, number, monthname.

**Acc_ComparisonIncomeStatment.Fill** (verbatim):
```sql
with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
inner join Acc_Account on 1=1 

			   )
,    AccountTable ( AccountId, ParentAccountId,AccountTypeId,PeriodCredit, PeriodDebit,MNTH,Yer,CostCenterId)
          AS ( 
		  
		  SELECT   Acc_Account.AccountId,
                        Acc_Account.ParentAccountId,
						AccountTypeId,
					   ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
						MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
						,CostCenterId
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId,
						                            CostCenterId,
													  Credit,
                                                    Debit,
                                                    PeriodCredit,
                                                    PeriodDebit,
													CreatedDate
													
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,null)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    Acc_Account.AccountId NOT IN (
                        SELECT  ParentAccountId
                        FROM    dbo.Acc_Account
                        WHERE   ParentAccountId IS NOT NULL )
               GROUP BY Acc_Account.AccountId,AccountTypeId,
                        Acc_Account.ParentAccountId,Balance.CostCenterId,MONTH(Balance.CreatedDate),year(Balance.CreatedDate)
             )
	, accountBudgetTable as (
	select case when AccountTypeId IN(1 ,3 )	 then 
	 sum(BudgetValue) 
	 else (-1*sum(BudgetValue)) end as BudgetValue , AccontId as AccountId ,CostCenterId, AccountingSubPeriodId
 ,Acc_Account.AccountTypeId
from Acc_AccountBudget
inner join Acc_Account on Acc_Account.AccountId = Acc_AccountBudget.AccontId 
where 
  (( @CostCenterList IS NULL )
            OR ( Acc_AccountBudget.CostCenterId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@CostCenterList) AS Acc_ConvertIntListToTable_1 ) ))
and ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
group by  CostCenterId,AccontId ,AccountingSubPeriodId,AccountTypeId
)
,AccountBalance as (

select  DISTINCT
accountBudgetTable.AccountId,AccountTable.ParentAccountId,accountBudgetTable.CostCenterId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit ,
isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,
 isnull(accountBudgetTable.BudgetValue,0) as BudgetValue
,date.number,date.monthname
 
from accountBudgetTable 

right outer join date on date.number = accountBudgetTable.AccountingSubPeriodId
  and date.AccountId = accountBudgetTable.AccountId
  
 left outer join AccountTable on  AccountTable.AccountId = date.AccountId 
 and AccountTable.MNTH = accountBudgetTable.AccountingSubPeriodId
 and accountBudgetTable.CostCenterId = AccountTable.CostCenterId
)


  SELECT  Acc_AccountType.AccountTypeId,
           CASE Acc_AccountType.AccountTypeId
    WHEN 1 THEN 'Total Operating Income' 
    WHEN 2 THEN 'Total Operating expenses '
   else Acc_AccountType.AccountTypeName
  END AS AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic,
            ISNULL(SUM(AccountBalance.PeriodCredit), 0) AS PeriodCredit,
            ISNULL(SUM(AccountBalance.PeriodDebit), 0) AS PeriodDebit,
		 ISNULL(sum(AccountBalance.BudgetValue),0) as BudgetValue,
			 AccountBalance.number,AccountBalance.monthname,
			case when Acc_AccountType.AccountTypeId in (1,3) then
			 abs(ISNULL(SUM(AccountBalance.PeriodDebit), 0)-ISNULL(SUM(AccountBalance.PeriodCredit), 0))
			 else 
			  (ISNULL(SUM(AccountBalance.PeriodCredit), 0)-ISNULL(SUM(AccountBalance.PeriodDebit), 0))
			  end
			 as AcutalValue
    FROM    AccountBalance
            RIGHT OUTER JOIN dbo.Acc_Account ON AccountBalance.AccountId = dbo.Acc_Account.AccountId
            RIGHT OUTER JOIN dbo.Acc_AccountType ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
			
    WHERE   Acc_AccountType.AccountTypeNature = 1 and AccountBalance.number is not null
    GROUP BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic, 
			AccountBalance.number,AccountBalance.monthname
    ORDER BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic , AccountBalance.number
```
**Acc_ComparisonIncomeStatment.FillByArabic** = same + `ArabicMonth` CASE as `monthname` (numbers identical).
Columns: AccountTypeId, AccountTypeName, AccountTypeNameArabic, PeriodCredit, PeriodDebit, BudgetValue, number, monthname, AcutalValue.

Critical semantics of both queries:
1. **Month ↔ budget join is `date.number = Acc_AccountBudget.AccountingSubPeriodId`** and **journal month `MONTH(CreatedDate) = AccountingSubPeriodId`**. The sub-period *id* (an identity) is treated as a calendar month number 1..12, and the budget has **no year filter**. Only correct on tenants whose sub-period ids happen to be 1..12. Needs a decision (reproduce or fix via `Acc_AccountingSubPeriod.SubPeriodStart`).
2. Driven by **budget rows**: `accountBudgetTable RIGHT JOIN date` then `INNER JOIN Acc_CostCenter ON AccountBalance_1.CostCenterId` (budget's cost center) → actuals for (account, cost center, month) with no budget row are **dropped**; actuals join on `accountBudgetTable.CostCenterId = AccountTable.CostCenterId`.
3. `SELECT DISTINCT` in `AccountBalance` collapses duplicate (AccountId, CostCenterId, credit, debit, budget, month) tuples (e.g. two budget rows split by branch with equal values) — fidelity trap.
4. Budget sign: ComparisonActivityIncome: `AccountTypeId = 1` → +SUM, else −SUM (only types 1,2). Acc_ComparisonIncomeStatment: `AccountTypeId IN (1,3)` → +SUM else −SUM; `AcutalValue` = ABS(Debit−Credit) for types 1,3 else (Credit−Debit). Hard-coded `AccountTypeName` override: 1 → 'Total Operating Income', 2 → 'Total Operating expenses ' (English only; Arabic uses `AccountTypeNameArabic`).
5. Journal TVF call passes branch list `null` (8th arg); budget not filtered by branch.

### SQL objects → cloud DB
`Acc_TableNumberRange` → `Functions\Acc_TableNumberRange.sql` (multi-statement TVF, `number` from @nMin to @nMax inclusive); `Acc_GetAccountJournalActionsBetweenDates` → `Functions\Acc_GetAccountJournalActionsBetweenDates.sql` (8 params; returns AccountId, CostCenterId, Credit, Debit, PeriodCredit, PeriodDebit, CreatedDate, BranchId, JournalTypeId; cloud version also filters `j.Void = 0`); `Acc_ConvertIntListToTable`, `Acc_AccountBudget`, `Acc_Account`, `Acc_AccountType`, `Acc_CostCenter` — all present (paths as in report 1).

---

## 4. Branch Income Statement vs Budget (`branch-income-statment-budget-report`)

**Branch twin of report 3: same xsd, same layout shape.**

### Angular
- Route: module line 151, `BranchIncomeBudgetShellComponent`, `data: { ModuleId: 72 }`.
- Menu: `routes.ts` line 846-852, id `6_1_3_6`, "Branch Income Statement Budget Comparison" / "قائمة الدخل بالفروع مقارن تقديري", `params: ''`.
- Shell: `...\branch-income-budget\branch-income-budget-shell\branch-income-budget-shell.component.ts`, default `'BranchIncomeStatementBudget'`, `year` → `yyyy`, title key `FINANCIALREPORTS._BranchIncomeStatementBudgetReport_`.
- Form `...\branch-income-budget-form\...`: `month` (init `true`), `year` (required), `revised` (init `null`; radio → `null`/true/false), `journalTypes`, `branchesIds` (from `BranchLookupRef.BranchForm.BranchList` in `filter()`). Period radio uses `onValueChanged`: 0 → true, 1 → false, 2 → null.
- iframe: `{printUrl}FinancialReports/BranchIncomeStatementBudget?lang=..&month=..&year=yyyy&revised=<null|true|false>&journalTypes=<csv>&branchesIds=<csv>`

### MVC
- Controller line 198-234: `BranchIncomeStatementBudget(string lang, bool? revised, string journalTypes, string branchesIds, bool? month, int year)`; identical month→date mapping as report 3; `new rptBranchIncomeStatementBudgetComparison(fromDate, toDate, revised, journalTypes, branchesIds, fromMonth, toMonth)`.

### rpt: `...\CostCenterIncomeStatementBudgetComparison\rptBranchIncomeStatementBudgetComparison.cs`
- Diff vs report 3:
  ```csharp
  if (IsArabic)      // <-- INVERTED: Arabic UI gets the English-month fills, English UI gets Arabic month names
  {
      acc_ComparisonIncomeStatmentTableAdapter1.FillByBranch(ds.Acc_ComparisonIncomeStatment, fromMonth, toMonth, fromDate, toDate, revised, journalTypes, null, branches);
      comparisonBranchIncomeTableAdapter1.Fill(ds.ComparisonBranchIncome, fromMonth, toMonth, fromDate, toDate, revised, journalTypes, branches);
  }
  else
  {
      acc_ComparisonIncomeStatmentTableAdapter1.FillByBranchArabic(... null, branches);
      comparisonBranchIncomeTableAdapter1.FillByArabic(... branches);
  }
  ```
  Numbers are the same in both variants (the branch Arabic/English queries differ only in month names), so only labels are swapped.
  - No empty-data `e.Cancel` on the pivots (report 3 has it).
  - `txtDateFrom/To` = month numbers set again in BeforePrint.
- Layout: same as report 3 with pivot1 DataMember `ComparisonBranchIncome`, row field `BranchName` instead of `CostCenterName`; title "قائمة الدخل بالفروع مقارن تقديرى".

### ds
**ComparisonBranchIncome.Fill** (verbatim; FillByArabic = + ArabicMonth only, same sign):
```sql
 with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname,Acc_Branch.BranchId
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
inner join Acc_Account on 1=1 
inner join Acc_Branch on 1=1
			   )
,    AccountTable ( AccountId,AccountTypeId, PeriodCredit, PeriodDebit,BranchId,MNTH,Yer)
          AS ( 
		  
		  SELECT   Acc_Account.AccountId,
                         Acc_Account.AccountTypeId,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
						Balance.BranchId,
                       MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
				 FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId,
                                                     Credit,
                                                    Debit,
                                                    PeriodCredit,
                                                    PeriodDebit,
													BranchId,
													CreatedDate
										   FROM      dbo.Acc_GetAccountJournalActionsBetweenDates
										  (@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, Null, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                        
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) ) 
			 GROUP BY Acc_Account.AccountId,Balance.BranchId,AccountTypeId
			   ,MONTH(Balance.CreatedDate),year(Balance.CreatedDate)
)
,accountBudgetTable as 
(        
 select case when AccountTypeId = 1 then  sum(BudgetValue) 
  else (-1*sum(BudgetValue)) end as BudgetValue , AccontId as AccountId,Acc_AccountBudget.BranchId,CostCenterId , AccountingSubPeriodId
 ,Acc_Account.AccountTypeId
from Acc_AccountBudget
inner join Acc_Account on Acc_Account.AccountId = Acc_AccountBudget.AccontId 
where   (( @BranchList IS NULL )
            OR ( Acc_AccountBudget.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
and ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
and AccountTypeId in (1,2)
group by Acc_AccountBudget.BranchId , CostCenterId,AccontId ,AccountingSubPeriodId,AccountTypeId
)
,AccountBalance as (
select  DISTINCT
accountBudgetTable.AccountId,accountBudgetTable.AccountTypeId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit ,
isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,
 isnull(accountBudgetTable.BudgetValue,0) as BudgetValue,
accountBudgetTable.BranchId,date.number,date.monthname
 
from accountBudgetTable 

right outer join date on date.number = accountBudgetTable.AccountingSubPeriodId
  and date.AccountId = accountBudgetTable.AccountId
  
 left outer join AccountTable on  AccountTable.AccountId = date.AccountId 
 and AccountTable.MNTH = accountBudgetTable.AccountingSubPeriodId
 and accountBudgetTable.BranchId = AccountTable.BranchId 
 )   
  SELECT   Acc_Branch.BranchCode,
            Acc_Branch.BranchName,
			 Acc_Branch.BranchId,
           ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit,
           Acc_AccountType.AccountTypeName,
           Acc_AccountType.AccountTypeNameArabic,
		  AccountBalance_1.AccountTypeId,
            ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)
            - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS SubItemActualBalance
			, ISNULL (SUM(AccountBalance_1.BudgetValue),0) as SubItemBudgetValueBalance
           ,AccountBalance_1.number, AccountBalance_1.monthname  
    FROM    AccountBalance AS AccountBalance_1
            inner JOIN dbo.Acc_Branch ON Acc_Branch.BranchId = AccountBalance_1.BranchId
            INNER JOIN dbo.Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
			  where AccountBalance_1.AccountTypeId in (1,2)
            GROUP BY Acc_Branch.BranchCode,
           Acc_Branch.BranchName,
           Acc_AccountType.AccountTypeName,
		   Acc_Branch.BranchId,
		   AccountBalance_1.AccountTypeId,
           Acc_AccountType.AccountTypeNameArabic
		  ,AccountBalance_1.number, AccountBalance_1.monthname
           ORDER BY  Acc_Branch.BranchCode,AccountBalance_1.AccountTypeId
```
Params: `@FromMonth, @ToMonth, @FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @BranchList`. Columns: BranchCode, BranchName, BranchId, PeriodCredit, PeriodDebit, AccountTypeName, AccountTypeNameArabic, AccountTypeId, SubItemActualBalance (Credit − Debit), SubItemBudgetValueBalance, number, monthname.

**Acc_ComparisonIncomeStatment.FillByBranch** (verbatim; FillByBranchArabic = + ArabicMonth only):
```sql
with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
inner join Acc_Account on 1=1 

			   )
,    AccountTable ( AccountId, ParentAccountId,AccountTypeId,PeriodCredit, PeriodDebit,MNTH,Yer,BranchId)
          AS ( 
		  
		  SELECT   Acc_Account.AccountId,
                        Acc_Account.ParentAccountId,
						AccountTypeId,
					   ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
						MONTH(Balance.CreatedDate) AS MNTH,year(Balance.CreatedDate) AS Yer
						
						,Balance.BranchId
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId,
						                          	BranchId,
                                                    Credit,
                                                    Debit,
                                                    PeriodCredit,
                                                    PeriodDebit,
													CreatedDate
													
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    Acc_Account.AccountId NOT IN (
                        SELECT  ParentAccountId
                        FROM    dbo.Acc_Account
                        WHERE   ParentAccountId IS NOT NULL )
               GROUP BY Acc_Account.AccountId,AccountTypeId,
                        Acc_Account.ParentAccountId,Balance.BranchId,MONTH(Balance.CreatedDate),year(Balance.CreatedDate)
             )
	, accountBudgetTable as (
	select case when AccountTypeId IN(1 ,3 )	 then 
	 sum(BudgetValue) 
	 else (-1*sum(BudgetValue)) end as BudgetValue , AccontId as AccountId ,Acc_AccountBudget.BranchId,CostCenterId, AccountingSubPeriodId
 ,Acc_Account.AccountTypeId
from Acc_AccountBudget
inner join Acc_Account on Acc_Account.AccountId = Acc_AccountBudget.AccontId 
where (( @BranchList IS NULL )
            OR ( Acc_AccountBudget.BranchId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@BranchList) AS Acc_ConvertIntListToTable_1 ) ))
and
  (( @CostCenterList IS NULL )
            OR ( Acc_AccountBudget.CostCenterId IN (
                 SELECT number
                FROM   dbo.Acc_ConvertIntListToTable(@CostCenterList) AS Acc_ConvertIntListToTable_1 ) ))
and ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
group by Acc_AccountBudget.BranchId , CostCenterId,AccontId ,AccountingSubPeriodId,AccountTypeId
)
,AccountBalance as (

select  DISTINCT
accountBudgetTable.AccountId,AccountTable.ParentAccountId,accountBudgetTable.BranchId,ISNULL (AccountTable.PeriodCredit,0) as PeriodCredit ,
isnull (AccountTable.PeriodDebit,0) as PeriodDebit ,
 isnull(accountBudgetTable.BudgetValue,0) as BudgetValue
,date.number,date.monthname
 
from accountBudgetTable 

right outer join date on date.number = accountBudgetTable.AccountingSubPeriodId
  and date.AccountId = accountBudgetTable.AccountId
  
 left outer join AccountTable on  AccountTable.AccountId = date.AccountId 
 and AccountTable.MNTH = accountBudgetTable.AccountingSubPeriodId
 and accountBudgetTable.BranchId = AccountTable.BranchId
)


  SELECT  Acc_AccountType.AccountTypeId,
           CASE Acc_AccountType.AccountTypeId
    WHEN 1 THEN 'Total Operating Income' 
    WHEN 2 THEN 'Total Operating expenses '
   else Acc_AccountType.AccountTypeName
  END AS AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic,
            ISNULL(SUM(AccountBalance.PeriodCredit), 0) AS PeriodCredit,
            ISNULL(SUM(AccountBalance.PeriodDebit), 0) AS PeriodDebit,
		 ISNULL(sum(AccountBalance.BudgetValue),0) as BudgetValue,
			 AccountBalance.number,AccountBalance.monthname,
			(ISNULL(SUM(AccountBalance.PeriodCredit), 0)-ISNULL(SUM(AccountBalance.PeriodDebit), 0))
			 as AcutalValue
    FROM    AccountBalance
            RIGHT OUTER JOIN dbo.Acc_Account ON AccountBalance.AccountId = dbo.Acc_Account.AccountId
            RIGHT OUTER JOIN dbo.Acc_AccountType ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
			
    WHERE   Acc_AccountType.AccountTypeNature = 1 and AccountBalance.number is not null
    GROUP BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic, 
			AccountBalance.number,AccountBalance.monthname
    ORDER BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic , AccountBalance.number
```
Params: `@FromMonth, @ToMonth, @FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList (always NULL from rpt), @BranchList`. Note `AcutalValue` here is Credit − Debit for **all** types (no 1/3 ABS branch as in the cost-center Fill), budget sign still `IN (1,3)` → +.
Same month-id / budget-driven / DISTINCT caveats as report 3. SQL objects: same as report 3 + `Acc_Branch` (present).

---

## 5. Income Statement Arabic per Month (`branch-statment-arbic-month-report`)

### Angular
- Route: module line 157, `BranchStatmentMonthReportShellComponent`, `data: { ModuleId: 72 }`.
- Menu: `routes.ts` line 862-868, id `6_1_4_1` under `6_1_4` "Branch Report Per Month" / "تقارير قائمة الدخل الشهرية تفصيلي"; item text "Branch Report Per Month" / "قائمة الدخل تفصيلي نصف سنوي", `params: ''`. (Sibling `6_1_4_2` "Branch Report Per Period" → `income-statment-arbic-period-report` uses `BrifIncomeStatmentReportShellComponent` and the same xsd's `FillByPeriod*` queries via `rptIncomeStatemetPerPeriod` — out of scope but same dataset.)
- Shell: `...\branch-statment-month-report\branch-statment-month-report-shell\branch-statment-month-report-shell.component.ts`, default report `'IncomeStatemetArabicPerMonth'`, `year` → `yyyy`, title key `FINANCIALREPORTS._IncomeStatemetArabicPerMonthReport_`.
- Form `...\branch-statment-month-report-form\...`: `month` (init `false`, patched `true` after view init), `year` (required), `revised` (`null`/true/false), `journalTypes`, `costCenterIds`, `branchesIds`. Period radio has only two options: 0 "من 1 إلى 6" → `true`; 1 "من 6 إلى 12" → `false` (no full-year option in UI; controller still supports `null`).
- iframe: `{printUrl}FinancialReports/IncomeStatemetArabicPerMonth?lang=..&month=<true|false>&year=yyyy&revised=..&journalTypes=<csv>&costCenterIds=<csv>&branchesIds=<csv>`

### MVC (controller line 237-276)
```csharp
public IActionResult IncomeStatemetArabicPerMonth(string lang, bool? revised, string journalTypes, string costCenterIds, string branchesIds, bool? month, int year)
// same month mapping as report 3 (true → Jan 1..Jun 30 23:59:59; false → Jun 1..Dec 31; null → Jan 1..Dec 31)
var report = new rptIncomeStatemetArabicPerMonth(_fromDate, _toDate, revised, journalTypes, costCenterIds, branchesIds, toMonth);
```

### rpt: `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\IncomeStatmentPerMonth\rptIncomeStatemetArabicPerMonth.cs`
- Ctor `(DateTime fromDate, DateTime toDate, bool? _revised, string _journalTypes, string _costCenterList, string _branches, int _NoMonth)` → `toMonth = _NoMonth`; **`fromMonth` is never assigned (stays 0)** → every query runs `Acc_TableNumberRange(0, toMonth)`; month 0 never matches a journal so it is harmless, but the month window comes only from the date range.
- Name for layout: `"rptIncomeStatemetPerMonth"` / `"rptIncomeStatemetPerMonthAr"` (differs from the class name).
- BeforePrint header: `toMonth == 6` → txtDateFrom "1", txtDateTo "6"; else "6"/"12" (so the 1..12 case would also print 6..12).
- Fills (Arabic → `FillByArabic`, else `Fill`), each with `(fromMonth=0, toMonth, _fromDate, _toDate, revised, journalTypes, costCenterList, branches)`:
  `Acc_IncomeStatement_AdministrativePerMonth`, `_OperatingExpensesPerMonth`, `_OperatingIncomePerMonth`, `_OtherExpensePerMonth`, `_OtherIncomePerMonth`, `_TaxesPerMonth`. (`Acc_IncomeStatmentPerMonth` adapter exists but is never filled.)
- C# math (reproduce exactly):
  ```csharp
  _administrativeExpenses = Σ AdministrativePerMonth.SubItemBalance     // MainItemId 4, Debit-Credit
  _operatingIncome        = Σ OperatingIncomePerMonth.SubItemBalance    // MainItemId 1, Credit-Debit
  _operatingExpenses      = Σ OperatingExpensesPerMonth.SubItemBalance  // MainItemId 2, Debit-Credit
  _otherIncome            = Σ OtherIncomePerMonth.SubItemBalance        // MainItemId 3, Credit-Debit
  _otherExpenses          = Σ OtherExpensePerMonth.SubItemBalance       // MainItemId 5, Debit-Credit
  _taxes                  = Σ TaxesPerMonth.SubItemBalance              // MainItemId 6, Credit-Debit (!)
  _grossprofit        = _operatingIncome - _operatingExpenses;                                   // txtGrossProfit "N2", label "Total Profit"/"اجمالي الارباح"
  _netProfitBeforeTax = _operatingIncome - _operatingExpenses - _otherExpenses + _otherIncome - _administrativeExpenses; // "Total Profit Before Tax"/"اجمالي الارباح قبل الضريبة"
  _netProfit          = _netProfitBeforeTax - _taxes;                                            // "Net Profit"/"صافي الارباح"
  // each of the three lines (value + caption) is hidden when its value == 0
  ```
  Taxes are Credit − Debit (normally negative for a debit-balance tax expense), so `- _taxes` **adds** tax to profit — differs from the migrated detailed TVF (`NetBeforeTax - ABS(Cat6)`, all categories Credit − Debit). Decide: reproduce or align.
  Totals are **whole-range only** — there is no per-month gross/net profit line.
- `lblRevised`: null → "Balance From Both Journals Revised & NOT Revised" / "رصيد من قيود مرحله وقيود غير مرحله"; true → "Balance From All Journals Revised" / "رصيد من قيود مرحله فقط"; false → "... NOT Revised" / "رصيد من قيود غير مرحله فقط". `lblCostCenter = costCenterList != null ? GetCostCenterNamesByCostCenterIdList(costCenterList) : ""`.
- Pivot events: each grid `e.Cancel` when its table is empty; `CustomFieldSort` monthname by `number`; Arabic captions: column GT "اجمالى"; row Total per grid: 1 "إجمالى ايرادات التشغيل", 2 "إجمالى مصروفات التشغيل", 3 "إجمالى مصروفات عمومية وادارية" (but grid 3 is Other **Income**), 4 "إجمالى مصروفات أخرى" (but grid 4 is **Administrative**), 5 and 6 "إجمالى مصروفات التشغيل" (copy-paste) — caption/grid mismatches.

### Layout (Designer `rptIncomeStatemetArabicPerMonth.Designer.cs`) — **six PIVOT grids, dynamic month columns**
- Bands: `ReportHeader` (company), `PageHeader` (title "Income Statement Detail  Branch Per Month Report" / "تقرير قائمة الدخل تفصيلى نصف سنوى ", From/To month numbers, lblRevised, lblCostCenter), `GroupHeader7` containing in order: `xrPivotGrid1` (OperatingIncome), `xrPivotGrid2` (OperatingExpenses), `xrTable10` "Total Profit" = `txtGrossProfit`, `xrPivotGrid3` (OtherIncome), `xrPivotGrid4` (Administrative), `xrPivotGrid5` (OtherExpense), `xrTable5` "Total Profit Before Tax", `xrPivotGrid6` (Taxes); `GroupFooter1` "Net Profit"; `PageFooter`.
- Each pivot: Rows = `MainItemName` (idx 0) > `SubItemName` (idx 1); Columns = `monthname` (sorted by hidden `number`); Data = SUM(`SubItemBalance`); headers hidden; default totals → a per-MainItem total row and a grand-total column ("اجمالى"). Values are printed **signed** (no ABS display hook here).
- 6 or 7 month columns + total (range 1..6 or 6..12, June overlaps).

### ds: `...\IncomeStatmentPerMonth\dsIncomeStatmentPerMonth.xsd`
Common params for every category query: `@FromMonth Int32, @ToMonth Int32, @FromBalanceDate DateTime, @ToBalanceDate DateTime, @JournalRevise Boolean?, @JournalTypeList String, @CostCenterList String?, @BranchList String?`. Columns: PeriodCredit, PeriodDebit, SubItemName, SubItemBalance, MainItemName, number, monthname.
`FillByArabic` variants differ only by the ArabicMonth CASE (as `monthname`) and `Acc_IncomeStatmentMainItem.MainItemNameArabic as MainItemName` (verified by diff; sign identical). `FillByPeriod*` variants are used by `rptIncomeStatemetPerPeriod` (not this report).

Category matrix (main `Fill`):
| Adapter | MainItemId | SubItemBalance | `number IS NOT NULL` filter |
|---|---|---|---|
| OperatingIncomePerMonth | 1 | Credit − Debit | yes |
| OperatingExpensesPerMonth | 2 | Debit − Credit | yes |
| OtherIncomePerMonth | 3 | Credit − Debit | yes |
| AdministrativePerMonth | 4 | Debit − Credit | yes |
| OtherExpensePerMonth | 5 | Debit − Credit | yes (`number is not null`) |
| TaxesPerMonth | 6 | Credit − Debit | **no** → emits rows with NULL month for sub-items without movement (a blank month column in the pivot / 0 contribution) |

**OperatingIncomePerMonth.Fill** (verbatim):
```sql
with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
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
**OperatingExpensesPerMonth.Fill** (verbatim):
```sql
  with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
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
                     ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS SubItemBalance, Acc_IncomeStatmentMainItem.MainItemName
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
**OtherIncomePerMonth.Fill** (verbatim):
```sql
  WITH  date
          AS ( SELECT   number ,
                        DATENAME(MONTH, DATEADD(MONTH, number - 1, 0)) AS monthname ,
                        Acc_Account.AccountId ,
                        AccountName
               FROM     dbo.Acc_TableNumberRange(@FromMonth, @ToMonth)
                        INNER JOIN Acc_Account ON 1 = 1
             ) ,
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
             ) ,
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
    WHERE   ( Acc_IncomeStatmentMainItem.MainItemId = 3 )
	 AND AccountBalance_1.number IS NOT NULL
    GROUP BY Acc_IncomeStatmentSubItem.SubItemName ,
            Acc_IncomeStatmentMainItem.MainItemId ,
            Acc_IncomeStatmentMainItem.MainItemName ,
            Acc_IncomeStatmentSubItem.OrderInReport ,
            AccountBalance_1.monthname ,
            AccountBalance_1.number
    ORDER BY Acc_IncomeStatmentSubItem.OrderInReport;
```
**AdministrativePerMonth.Fill** (verbatim):
```sql
 	with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
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
**OtherExpensePerMonth.Fill** (verbatim):
```sql
 with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
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
**TaxesPerMonth.Fill** (verbatim):
```sql
with  date as ( 
  SELECT NUMBER, DATENAME(MONTH, DATEADD(MONTH, NUMBER - 1, 0)) as monthname 
       ,Acc_Account.accountid,accountname
FROM   dbo.Acc_TableNumberRange(@FromMonth, @ToMonth) 
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
Note: month is `MONTH(CreatedDate)` only (year comes from the date window), so the per-month grid is calendar-month, not accounting sub-period.

### SQL objects → cloud DB
`Acc_TableNumberRange`, `Acc_GetAccountJournalActionsBetweenDates`, `Acc_Account` (uses column `IncomeStatment` = sub-item id), `Acc_IncomeStatmentMainItem` (`MainItemName`, `MainItemNameArabic`), `Acc_IncomeStatmentSubItem` (`IncomeStatmentSubItemId`, `SubItemName`, `OrderInReport`, `MainItemId`), `Acc_SystemConfiguration` — all present under `...\dbo\Functions\` / `...\dbo\Tables\`.

---

## 6. The already-migrated detailed Income Statement (WI 123252) — reuse target

| Piece | Path |
|---|---|
| TVF | `D:\Hadaf\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Functions\Acc_IncomeStatementReport.sql` |
| Detail TVF | `...\dbo\Functions\Acc_IncomeStatementReportDetails.sql` (account-level rows: RowNo, MainItemId, IncomeStatmentSubItemId, AccountId, AccountNo, AccountName, Debit, Credit, Net, PreviousYearNet, SortOrder) |
| Layout seed | `...\Scripts\ReferenceDataScripts\0404_IncomeStatementReportLayout.sql` (`EXEC dbo.InsertLayout`, ReportName `IncomeStatement`, ApplicationId 1, Ar RTL master + En mirror; flat RowType-driven Detail band + collapsible `DetailReportBand` on `Details`) |
| Entity | `D:\Hadaf\AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\AnalyticsReader\AnalyticsReader.Api\ODataViews\GL\IncomeStatementReports\IncomeStatementReport.cs` (+ `IncomeStatementReportDetail.cs`) |
| EF config | `...\ODataViewsConfigurations\GL\IncomeStatementConfigurations\IncomeStatementReportConfigurations.cs` (`HasNoKey`, `Ignore(Details)`) and `IncomeStatementReportDetailConfigurations.cs` (`HasKey(RowNo)`, `ToFunction("Acc_IncomeStatementReportDetails")`) |
| DbSet | `...\Models\DataContext.cs` lines 405-406 |
| IAngularReport | `...\AngularReports\GeneralLedger\BasicReports\IncomeStatementReports\IncomeStatementReport.cs` — `ReportName => "IncomeStatement"` |
| Angular | `...\financial-reports\income-statement-print-report\income-statement-print-report-shell\income-statement-print-report-shell.component.ts/.html`; route `income-statment-report` (module line 97, ModuleId 72); menu `6_1_2_2` with `params: { report: 'IncomeStatement' }` |

Structure:
- TVF signature `(@FromBalanceDate, @ToBalanceDate, @JournalRevise BIT, @JournalTypeList, @CostCenterList, @BranchList, @IsArabic BIT)`; inline TVF; uses `NULLIF(list,'')`.
- **Fixed two value columns** (`CurrentBalance`, `PreviousYearBalance`, `DECIMAL(19,4)`) and **RowType rows**: `SubItem` (sort `MainItemId*1000+10+OrderInReport`), `CategoryTotal` (`MainItemId*1000+900`), `GrossProfit` (2950 = Cat1+Cat2), `NetProfitBeforeTax` (5950 = Cat1..Cat5), `NetProfit` (6950 = NPBT − ABS(Cat6)). All balances Credit − Debit (leaf accounts only). Output columns: RowNo (ROW_NUMBER by SortOrder), SortOrder, RowType, MainItemId, MainItemName (Ar/En/fallback), IncomeStatmentSubItemId, SubItemName, CurrentBalance, PreviousYearBalance.
- IAngularReport reads query options `fromDate, toDate, costCenterIds, branchesIds, journalTypes, revised` (`"true"/"false"/else null`), normalizes `""` → null, runs both TVFs with `FromSqlInterpolated`, stitches `Details` onto SubItem rows, and returns parameters `journalReviseFilter, journalTypeFilter, branchFilter, fromDate, toDate` + empty `CompanyInfo` keys (CompanyName, Telephone, Email, Fax, Address, Logo).
- Angular: `<report-grid [ApplicationId]="1" [ReportName]="'IncomeStatement'" [endpoint]="'IncomeStatement'" keyGrid="RowNo" [printOnlyMode]="true" [QueryOptions]="gridQueryOptions">`, reusing `app-brif-income-statment-report-form` with `[hideActions]="true"`; query options rebuilt on every form / checklist `valueChanges` (dates `yyyy-MM-dd`, lists CSV).

What is reusable for the five: the RowType/SortOrder pattern, the `MainItemId`-position category keys and Ar/En name fallback, the leaf-account CTE shape over `Acc_GetAccountJournalActionsBetweenDates` (report 5 is the same data per calendar month), the IAngularReport parameter plumbing, the company-header parameters and the print-only shell. What does NOT carry over: reports 1-4 group by **AccountType** (types 1/2 and income-nature types), not by `Acc_IncomeStatmentMainItem`/SubItem, and use budgets (`Acc_AccountBudget`); reports 3-5 need a month dimension.

---

## 7. Shared building blocks

| Block | Used by | Notes |
|---|---|---|
| `dsIncomeStatmentActivity.xsd` + twin rpts | 1, 2 | Same `Acc_IncomeStatment` query; per-dimension query differs only in `CostCenterId`↔`BranchId`, `Acc_CostCenter`↔`Acc_Branch`, and which list filters the budget. One TVF with a `@Dimension` switch (or two thin TVFs over one shared CTE) can serve both. |
| `dsCostCenterIncomeStatementBudgetComparison.xsd` + twin rpts | 3, 4 | Same summary query (`Acc_ComparisonIncomeStatment.Fill` vs `FillByBranch`) + dimension query. Same pivot layout. |
| `dsIncomeStatmentPerMonth.xsd` | 5 (+ `rptIncomeStatemetPerPeriod`) | Six near-identical category queries, differing in `MainItemId`, sign, and the `number IS NOT NULL` filter. |
| Period TVFs `Acc_GetAccountJournalActions{BetweenAccPeriod,BetweenAccPeriodLastYear,YearToAccPeriod,LastYearToAccPeriod}` | 1, 2 | All in cloud DB. |
| `Acc_GetAccountJournalActionsBetweenDates` | 3, 4, 5, migrated detailed IS | In cloud DB. |
| `Acc_TableNumberRange`, `Acc_ConvertIntListToTable` | 3-5 / all | In cloud DB. |
| `Acc_AccountBudget` | 1-4 | `AccountingSubPeriodId` is a sub-period id in 1/2 but used as a **month number** in 3/4. |
| Month → Arabic name CASE | 3-5 | `N'يناير '` … `N'ديسمبر '` (trailing space). English = `DATENAME(MONTH, DATEADD(MONTH, number-1, 0))`. |
| Month-half mapping (controller) | 3, 4, 5 | true → 1..6 (Jan 1 – Jun 30), false → 6..12 (**Jun 1** – Dec 31), null → 1..12. |
| Company header / page footer | all | `Acc_SystemConfiguration`; OData equivalent = `CompanyInfo` parameters. |
| Revised caption texts | all | three variants per report family (strings quoted in each section). |

**Entity-shape implication.** Reports 1 and 2 are fixed-column (10 numbers × rows), not pivots: rows = dimension (cost center / branch) × account type 1/2 + per-dimension GOP + a "Total GOP" row + other account types + Net Profit, which fits a RowType list with 10 decimal columns. Reports 3, 4 and 5 are true `XRPivotGrid`s whose **column set is dynamic**: months in the selected range (6 or 7, or 12), times 1 data field (report 5) or 2 (Budget/Actual, reports 3/4), plus pivot-generated totals. The rows are dynamic too: cost centers / branches (3/4) and sub-items (5). The month set is bounded at 12, so the OData entity can be either:
- (a) long/unpivoted rows `(Dimension, AccountType/SubItem, MonthNo, MonthName, Budget, Actual)` with an XRPivotGrid in the new `.repx` (keeps layout parity, and the pivot computes totals), or
- (b) a fixed-wide entity `M01..M12 Budget/Actual + Total` with RowType total rows computed in SQL (`printOnlyMode`-friendly, Excel-safe, and unused months hidden by parameters).

The choice belongs to the plan gate. The legacy totals come from the pivot engine, so with (b) every total must be written in SQL.

## 8. Risks / open questions

1. **Budget month = sub-period id (reports 3/4).** `date.number = Acc_AccountBudget.AccountingSubPeriodId` and `MONTH(CreatedDate) = AccountingSubPeriodId`, with no year on the budget. Reproducing this exactly gives budget numbers that are wrong on any tenant whose sub-period ids are not 1..12. Fixing it (join through `Acc_AccountingSubPeriod` by year/month) changes the numbers. Needs a business decision. Check the real ids on a tenant DB before choosing.
2. **Actuals without budget are dropped (3/4).** The queries are driven by budget rows: `RIGHT JOIN date` and then `INNER JOIN` on the budget's dimension. Combined with `SELECT DISTINCT` (which can collapse equal tuples), a "same numbers" SQL diff must copy this exactly or document the deviation.
3. **Sign inconsistencies.**
   - Report 3: the Arabic `ComparisonActivityIncome.FillByArabic` flips `SubItemActualBalance` (Credit−Debit against Debit−Credit in English). Detail cells hide it (ABS), but pivot totals differ by language.
   - Reports 3/4: `Acc_ComparisonIncomeStatment.Fill` (cost center) and `FillByBranch` compute `AcutalValue` differently.
   - Report 5: Taxes are Credit−Debit and then subtracted, so tax increases net profit. The migrated detailed IS instead uses `- ABS(Cat6)`.
4. **Report 4 language inversion.** `if (IsArabic)` calls the English fills. The numbers are unaffected; only the month names are swapped.
5. **Report 2 Arabic bug.** The account-type caption is bound to the empty `ActivityIncome` table, so it prints blank. The % row reads the unfilled table.
6. **% rows (1/2) always print 0 %.** Every value is ABS, so `revenu` never becomes non-zero. Decide whether to reproduce 0 % or implement the intended "share of revenue" %. There is also a copy bug: `gop[9]` uses YearToPeriodBudgetDiff.
7. **YTD budget (1/2)** sums the sub-periods *before* the selected one (`SubPeriodStart < selected`), so it excludes the selected month's budget. The "Diff" columns are ABS values and their Cal* sums are not true variances.
8. **Net Profit summary (1/2).** It is unclear whether DevExpress's Report-running SUM in `GroupFooter1` includes the type 1/2 rows that `Detail2_BeforePrint` cancels. Verify against a live MVC print before writing the SQL.
9. **June overlap.** The "6 to 12" half starts June 1 (`fromMonth = 6`), so June appears in both halves. The "1 to 6" half ends June 30 23:59:59 (not .997).
10. **Report 5 `fromMonth` is never set** (it stays 0). The UI offers no full-year option, but the controller supports `month=null`, and its header would then print "6..12".
11. **Report 5 Taxes query has no `number IS NOT NULL` filter.** It produces NULL-month rows, which show as an extra blank pivot column when a tax sub-item has no movement.
12. **Null/empty list handling.**
    - ASP.NET Core binds empty query values to `null`. Reports 1/2 call `costCenterList.Length` / `branchList.Length`, which throws an NRE when the list is empty. Check whether the checklists always emit a value, or whether "no selection" currently crashes the MVC report.
    - Reports 3/4 pass `''` / null straight through to SQL.
    - The new screen should normalize `''` to null, as `IncomeStatementReport.cs` does.
13. **ModuleId mismatch.** Report 1 is on ModuleId 267; the others are on 72. Keep each one's ModuleId.
14. **Static fields in the rpt classes** (1-5) are shared across concurrent requests. Legacy prints can therefore mix filters under load. Keep this in mind when diffing numbers.
15. **No `.repx` exists on disk.** Layout parity must come from the Designer.cs trees summarized above. Tenants may also have customized layouts saved in the legacy MVC layout store (keyed by class name + culture, and report 5 renames itself `rptIncomeStatemetPerMonth`), which the repo cannot show.
16. **Report 3's form uses `onOptionChanged`** for the period radio, so any option change on the radio can patch `month`. Reuse the clean `onValueChanged` behaviour from forms 4/5 in the new screen.
17. **Pivot captions are partly wrong** in Arabic (row totals for grids 3-6 of report 5). Treat them as a layout improvement, not as fidelity.
