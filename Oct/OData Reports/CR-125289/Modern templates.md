# CR 125289 - Modern templates (scout)

Set: D:\Hadaf\worktrees\cr125289 (Database / Cloud_ERP / Front). Template = CR 123252 (branch fx123252, merged to Master_Stable).
Note: ERP repo has a double folder: AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\AnalyticsReader\AnalyticsReader.Api

## A) CR 123252 Income Statement (print-only OData)
Commits (grep 123252 on origin/Master_Stable):
- DB: 05c3a5c70 (PR 65060 merge of fx123252; also bc6803abe "wip123252"), rebase merge df6c6ee60
  files: .sqlproj (+3), Scripts/ReferenceDataScripts/0404_IncomeStatementReportLayout.sql (564), dbo/Functions/Acc_IncomeStatementReport.sql (172), dbo/Functions/Acc_IncomeStatementReportDetails.sql (87)
- ERP: 59f192c5fb (PR 65058); rebase 50e048a394. Files (6, all under AnalyticsReader.Api):
  AngularReports/GeneralLedger/BasicReports/IncomeStatementReports/IncomeStatementReport.cs
  Models/DataContext.cs (+3)
  ODataViews/GL/IncomeStatementReports/IncomeStatementReport.cs and IncomeStatementReportDetail.cs
  ODataViewsConfigurations/GL/IncomeStatementConfigurations/IncomeStatementReportConfigurations.cs and IncomeStatementReportDetailConfigurations.cs
  NO GLODataController change: print-only, report-grid printOnlyMode, endpoint = ReportName, no OData grid action.
- Front: 2898897303 (PR 65059); rebase d608e6cbe7. Files (5):
  financial-reports/brif-income-statment-report/brif-income-statment-report-form/ html + ts
  financial-reports/financial-reports.module.ts
  financial-reports/income-statement-print-report/income-statement-print-report-shell/ ts + html (new)
  No i18n files touched (reuses FINANCIALREPORTS._FinancialReports_ and FINANCIALREPORTS._IncomeStatementReport_).

### SQL
- Acc_IncomeStatementReport(@FromBalanceDate DATETIME, @ToBalanceDate DATETIME, @JournalRevise BIT=NULL, @JournalTypeList NVARCHAR(MAX)=NULL, @CostCenterList NVARCHAR(MAX)=NULL, @BranchList NVARCHAR(MAX)=NULL, @IsArabic BIT=0)
  returns RowNo (ROW_NUMBER() OVER (ORDER BY SortOrder), first col), SortOrder, RowType, MainItemId, MainItemName, IncomeStatmentSubItemId, SubItemName, CurrentBalance, PreviousYearBalance.
  RowType values: SubItem, CategoryTotal, GrossProfit, NetProfitBeforeTax, NetProfit. Computed rows have NULL ids; SortOrder = MainItemId*1000+10+Order (sub), +900 (cat total), 2950/5950/6950 computed. First UNION branch CASTs fix column types (NVARCHAR(500), DECIMAL(19,4)).
  Base fn: dbo.Acc_GetAccountJournalActionsBetweenDates(from,to,revise,NULLIF(list,''),NULLIF(cc,''),NULL,NULL,NULLIF(branch,'')); prior-year = DATEADD(YEAR,-1,..).
  Category keyed on fixed MainItemId (1 income, 2 opex, 6 tax), not name.
- Acc_IncomeStatementReportDetails(@From,@To,@JournalRevise,@JournalTypeList,@CostCenterList,@BranchList): account-level drill rows keyed by IncomeStatmentSubItemId (+MainItemId, SortOrder).
- sqlproj: lines 2192-2193 Build Include dbo\Functions\Acc_IncomeStatementReport.sql (+Details); seed line 4855 None Include Scripts\ReferenceDataScripts\0404_IncomeStatementReportLayout.sql.

### Layout seed 0404_IncomeStatementReportLayout.sql
- 2 x EXEC dbo.InsertLayout @Layout = N'<XtraReportsLayoutSerializer ...>', @ReportName = N'IncomeStatement', @Lang = 'ar-EG' | 'en-US', @ApplicationId = 1;
- Arabic = RTL master (RightToLeft="Yes", RightToLeftLayout="Yes"), English = LTR mirror. A4 landscape, DataSource ObjectStorageInfo = List of AnalyticsReader.Api.ODataViews.GL.IncomeStatementReports.IncomeStatementReport.
- Report Parameters (all Visible=false): CompanyName, Address, Telephone, Email, Fax, Logo, fromDate, toDate, journalReviseFilter, journalTypeFilter, branchFilter. Detail band styled by RowType (styles stSub, stCatTotal, stComputed, stLink); DetailReportBand DataMember="Details", DrillDownExpanded=false.

### AnalyticsReader
- Entity ODataViews/GL/IncomeStatementReports/IncomeStatementReport.cs: IODataEntity, long RowNo + nullable cols, List of IncomeStatementReportDetail Details; Configure: EntitySet IncomeStatementReport, HasKey RowNo.
- EF config: builder.HasNoKey(); builder.Ignore(x => x.Details). NO ToFunction (queried via FromSqlInterpolated in the IAngularReport). Deviates from report-backend.md (ToFunction); it is the nested-Details variant.
- DataContext.cs:392-393 DbSet IncomeStatementReport, DbSet IncomeStatementReportDetail; using at line 69.
- IAngularReport class IncomeStatementReport: ctor(DataContext, IUserSession); ReportName = "IncomeStatement"; EntityType = typeof(List of entity); GetDataSource(string filters, IEnumerable of string queryOptions).
  Params: ReportExtensions.ParseUtcDateRange(GetQueryOptionValue fromDate, toDate); costCenterIds, branchesIds, journalTypes via GetQueryOptionValue(..)?.RemoveSingleQuotes() (blank -> null); revised "true"/"false"/else null -> bool?.
  isArabic = _userSession.IsDefaultRequestCulture; names via _context.GetBranchesName / GetJournalTypesName; journalReviseFilter from ReportStrings (Culture ar/en): ReportJournalReviseFilterBoth / RevisedOnly / NotRevisedOnly.
  Query: _context.X.FromSqlInterpolated of SELECT * FROM dbo.Fn(fromDate.GetDayStart(), toDate.GetDayEnd(), revise-or-DBNull, ...) ORDER BY SortOrder, then AsNoTracking().ToListAsync(); details stitched to SubItem rows by IncomeStatmentSubItemId.
  Parameters dict (TryAdd): journalReviseFilter, journalTypeFilter, branchFilter, fromDate/toDate (dd/MM/yyyy), CompanyName, Telephone, Email, Fax, Address, Logo (empty strings, filled by framework). Returns new AngularDataSourceContainter with DataSource and Parameters.
- GLODataController: untouched by 123252 (print-only). cr125288 added grid actions there (see B).

### Front (income-statment-report)
- Route financial-reports.module.ts:97-100 path income-statment-report -> IncomeStatementPrintReportShellComponent, data.ModuleId 72.
- Shell: financial-reports/income-statement-print-report/income-statement-print-report-shell/, reportName=IncomeStatement, keyGrid=RowNo, headerColumns = one hidden column (DataField RowNo, Translate Id, Index 1, Visible false).
- Template: report-grid [ApplicationId]=1 [keyGrid] [ReportName]=reportName [endpoint]=reportName [columnIndex]=headerColumns [QueryOptions]=gridQueryOptions [ClearFilterClicked]=onClearFilterClicked [printOnlyMode]=true (no orderby input; ordering is SQL ORDER BY SortOrder).
- QueryOptions keys: fromDate, toDate (yyyy-MM-dd via date-fns format), revised, journalTypes (csv), costCenterIds (csv), branchesIds (csv). Built in updateGridQueryOptionsFromForm(), subscribed to FormRef.FilterForm.valueChanges + JournalTypeLookupRef.JournalTypeForm + BranchLookupRef.BranchForm valueChanges (ngAfterViewInit, SubSink).
- Reuses legacy form app-brif-income-statment-report-form (#FormRef) with new Input hideActions=false (html: searchFormBtn ngIf !hideActions) and new ViewChild BranchLookupRef (BranchCheckListComponent). Shell passes hideActions=true.
- The old iframe is NOT kept: the route is swapped to the new shell (module.ts diff: BrifIncomeStatmentReportShellComponent -> IncomeStatementPrintReportShellComponent). No "Print (previous design)" button. The legacy shell/form still serve other routes.
- i18n: FINANCIALREPORTS._FinancialReports_ (floating icons title), FINANCIALREPORTS._IncomeStatementReport_ (h6). No ODATAREPORTS.* keys.
- Wrapper: accflex-floating-icons, div.mainContainer, dx-card filter box.

## B) cr125288 (GL reports) diff vs origin/Master_Stable...cr125288
DB (6): sqlproj (+5); Scripts/ReferenceDataScripts/0430_GL_PeriodBalanceAndEstimatedBudgetReportsLayout.sql (2077 lines); dbo/Functions/Acc_EstimatedBudgetByDayReport.sql, Acc_EstimatedBudgetByMonthReport.sql, Acc_EstimatedBudgetPeriodReport.sql, Acc_PeriodBalanceReport.sql.
ERP (13): AngularReports/GeneralLedger/AdvancedReports/ (AdvancedReportOptions, EstimatedBudgetByDayReportAng, EstimatedBudgetByMonthReportAng, EstimatedBudgetPeriodReportAng, PeriodBalanceReportAng); Models/DataContext.cs; ODataControllers/GLODataController.cs (+90); ODataViews/GL/EstimatedBudgetReports/ (ByDay, ByMonth, Period reports); ODataViews/GL/PeriodBalanceReports/PeriodBalanceReport.cs; ODataViewsConfigurations/GL/EstimatedBudgetConfigurations/EstimatedBudgetReportConfigurations.cs; ODataViewsConfigurations/GL/PeriodBalanceConfigurations/PeriodBalanceReportConfigurations.cs.
Front (15): modules/advanced-reports/ (estimated-budget-by-day, estimated-budget-by-mounth, period-balance, period-estimated-budget) form html/ts + shell html/ts; shared report-grid.component.ts (1 line); i18n ar-EG and en-US general-accounting.json (+25 each).

### ReferenceDataScripts numbering
- Master_Stable top numbers: 0412_PR_MonthlySalaryPrintLayout (0411 gap), then 5000/5001/5003. 0404 = Income Statement.
- In use by sibling worktrees: cr125288 = 0430; cr125292 = 0414 (PR_SalaryReportsLayout); cr125294 = 0413 (PR_AdvanceAndPurchaseReportsLayout); cr125290 = none yet.
- Suggest for cr125289: 0431 (or 0440) to stay clear; 0411 and 0415-0429 are also free but near the others' ranges.

## C) Front routes (financial-reports.module.ts) and ModuleId
| route | shell component | ModuleId |
|---|---|---|
| brief-income-statment-report | BrifIncomeStatmentReportShell | 10 |
| brief-income-statment-costcenter-report | BrifIncomeStatmentCostcenterReportShell | 10 |
| brief-income-statment-branche-report | BrifIncomeStatmentBrancheReportShell | 10 |
| income-statment-report | IncomeStatementPrintReportShell (new) | 72 |
| income-statment-branche-report | BrifIncomeStatmentBrancheReportShell | 72 |
| income-statment-branche-report-production | BrifIncomeStatmentBrancheReportShell | 72 |
| income-statment-costcenter-report | BrifIncomeStatmentCostcenterReportShell | 72 |
| income-statment-activity-detail-report | BrifIncomeStatmentCostcenterReportShell | 267 |
| income-statment-barnche-detail-report | BrifIncomeStatmentBrancheReportShell | 55 |
| income-statment-arbic-period-report | BrifIncomeStatmentReportShell | 72 |
Three shells serve these routes; variants differ by route/ModuleId, so check how the shell/form tells them apart (route url) before splitting.
Also present, not in the list: income-statment-activity-budget-report 267, income-statment-branch-budget-report 72, costcenter-income-statment-budget-report 72, branch-income-statment-budget-report 72, branch-statment-arbic-month-report 72.

## D) Rule digest
Database (report-database-functions.md, sqlproj-registration.md):
1. Report = inline TVF (preferred) in dbo\Functions\Prefix_NameReport.sql; GL prefix Acc_.
2. ROW_NUMBER() BIGINT AS RowNo must be the FIRST column of the final SELECT.
3. ID-list params NVARCHAR(MAX)=NULL, NULL = show all; parse with dbo.Acc_ConvertIntListToTable; @IsArabic BIT=0 for language.
4. Column names must equal the C# entity property names; consistent DECIMAL/NVARCHAR types, ISNULL handling.
5. Every new Function/Table needs a Build Include in AccFlex_Cloud_Database_State.sqlproj (listed one by one); unlisted = silently missing from dacpac (Invalid object name).
6. Pre/Post/ReferenceData scripts run by folder scan, not sqlproj; still add None Include for them, never Build. Scripts hold data only, no DDL.
ERP (report-backend.md):
7. 4 artifacts + SQL: IODataEntity (ODataViews/Module/Sub), IEntityTypeConfiguration (ODataViewsConfigurations), DbSet in Models/DataContext.cs, IAngularReport (AngularReports/Module/Sub); auto-discovered by Scrutor, no manual registration.
8. Entity: long RowNo, other props nullable, EntitySet name equals class name, HasKey RowNo. Rule says ToFunction("Name"); 123252 used HasNoKey + FromSqlInterpolated (nested Details); both are precedent.
9. ReportName unique and equal to what the front sends; use queryOptions?.GetQueryOptionValue + RemoveSingleQuotes; always FromSqlInterpolated (no string concat).
10. Common failures: missing DbSet, function-name mismatch, property/column mismatch, null queryOptions.
Front (report-module.md):
11. Three patterns: (1) report-grid + buildQuery, (2) master-detail report-grid-multi-request, (3) popup details + column service; the print-only variant (123252) uses printOnlyMode.
12. Component: keyGrid, reportName (saves user prefs), form valueChanges subscription, SubSink unsubscribe in ngOnDestroy, clear filters, RTL via RTLService, date-range validation.
13. columnIndex ColumnIndex[] with DataField/Translate/Index/Visible.
Not read in full: rule files are 351/516/1358 lines; digest from headings and key rules.
