# Legacy dissection: Brief Income Statement family (CR 125289)

Source: D:\Hadaf\AccFlex_ERP (checkout cr94062). `git diff origin/Master_Stable` is EMPTY for FinancialReportsController.cs and Reports\IncomeStatment, IncomeStatmentActivity, IncomeStatmentBranchs (checkout == Master_Stable for these).
Legacy TVF `Acc_GetAccountJournalActionsBetweenDates` source is NOT in the legacy repo (lives in the legacy DB); only the cloud version was read.

## 1. Routes & params
All actions in FinancialReportsController.cs, route prefix `mvc/FinancialReports/`.
| Web route | default action | rpt class | query params |
|---|---|---|---|
| financial-reports/brief-income-statment-report | BriefIncomeStatment | rptBriefIncomeStatmentReport (Reports\IncomeStatment) | lang, fromDate, toDate, revised, journalTypes, costCenterIds, branchesIds |
| financial-reports/brief-income-statment-costcenter-report | CostCenterIncomeStatement | rptIncomeStatmentActivity (Reports\IncomeStatmentActivity) | lang, fromDate, toDate, revised, journalTypes, costCenterIds |
| financial-reports/brief-income-statment-branche-report | BranchIncomeStatement | rptIncomeStatmentBranch (Reports\IncomeStatmentActivity) | lang, fromDate, toDate, revised, journalTypes, branchesIds |

IMPORTANT: routes 2 and 3 are NOT "brief" classes; they are activity-style reports (grouped per cost center / branch, only account types 1 and 2 per group).
Shells accept `?report=` overrides (IncomeStatement, IncomeStatemetPerPeriod, IncomeStatementCostCenter, IncomeStatementActivityDetail, IncomeStatemetBranchs, IncomeStatemetBranchsProduction, IncomeStatmentBranchPeriod): OTHER reports, out of scope. Empty report = defaults above.
ModuleId: not visible in forms/shells (not read). Menu entries: AccFlex_Cloud_Front projects\general-accounting\src\app\core\routes.ts lines ~721-762 (settings route at 762).
Form fields (dirs under modules\financial-reports: brif-income-statment-report, brif-income-statment-costcenter-report, brif-income-statment-branche-report): fromDate, toDate (required, sent yyyy-MM-dd, from<=to enforced), revised (radio All -> ' ' i.e. blank => null; Revised -> true; Not revised -> false), journalTypes (checklist, comma list), costCenterIds (required on cost-center form, optional on brief), branchesIds (brief + branch forms; [] when none).

## 2. Controller actions
```csharp
[Route("mvc/FinancialReports/BriefIncomeStatment")]
public IActionResult BriefIncomeStatment(string lang, DateTime fromDate, DateTime toDate, bool? revised, string journalTypes, string costCenterIds, string branchesIds)
{ ChangeThreadCulture(lang); var report = new rptBriefIncomeStatmentReport(fromDate,toDate,revised,journalTypes,costCenterIds,branchesIds); return View(REPORTS_ROOT_VIEW, report); }
CostCenterIncomeStatement(lang,fromDate,toDate,revised,journalTypes,costCenterIds) -> new rptIncomeStatmentActivity(fromDate,toDate,revised,journalTypes,costCenterIds)
BranchIncomeStatement(lang,fromDate,toDate,revised,journalTypes,branchesIds)       -> new rptIncomeStatmentBranch(fromDate,toDate,revised,journalTypes,branchesIds)
```
Ctor common: from = date 00:00:00; to = date 23:59:59.997 (inclusive). Arabic: RTL, report name `...Ar`, AccountTypeNameArabic for the type cell. Numbers formatted `{0:n<approx>}`, approx = ApiLoggedUser.GetApproximateNo() (tenant ApproximateNo).

## 3. rpt classes and computations
### 3a. rptBriefIncomeStatmentReport (BeforePrint StatmentOfIncomeReport_BeforePrint)
Fills Acc_SystemConfiguration and Acc_IncomeStatment(from,to,revised,journalTypes,costCenterList,branches) = query A (one row per AccountType, all 15 types, no nature filter).
D(t) = PeriodDebit - PeriodCredit of AccountTypeId t (FindByAccountTypeId; throws if row missing). Type ids: 1 Operating_income, 2 Operating_expenses, 3 Other_income, 4 Administrative_General_Expenses, 5 Other_expenses, 13 Taxes.
```
income=D(1); expenses=D(2); otherincome=D(3); generalExpenses=D(4); otherExpenses=D(5)
fmt = "{0:n<approx>}"
clmIncome=fmt(ABS(income)); clmExpenses=fmt(ABS(expenses)); clmOtherIncomes=fmt(ABS(otherincome))
clmOtherExpenses=fmt(ABS(otherExpenses)); clmGeneralExpenses=fmt(ABS(generalExpenses)); clmTaxes=fmt(ABS(D(13)))
totalProfit = income + expenses                                   # signed debit-credit (profit shows as negative)
netProfitBeforeTax = totalProfit + otherincome + otherExpenses + generalExpenses
netProfit = netProfitBeforeTax + Convert.ToDecimal(clmTaxes.Text)  # ternary has identical branches; ADDS the formatted/rounded tax
clmTotalProfit = fmt(Round(ABS(totalProfit), approx, AwayFromZero))
clmNetProfitBeforeTax = netProfitBeforeTax<0 ? fmt(Round(ABS(v),approx,AwayFromZero)) : "(" + fmt(Round(ABS(v),...)) + ")"
clmNetProfit          = netProfit<0 ? fmt(Round(ABS(v),...)) : "(" + fmt(...) + ")"   # parentheses when >= 0, plain when < 0
txtDateFrom/To = dd/MM/yyyy; mainPrintedFrom = "PC: "+MachineName
lblRevised: null "Both Journals Revised & NOT Revised"; true "All Journals Revised"; false "All Journals NOT Revised" (Arabic variants exist)
lblCostCenter = costCenterList==null ? "" : GetCostCenterNamesByCostCenterIdList(list)
```
Quirks: Convert.ToDecimal(clmTaxes.Text) re-parses the formatted, rounded, thousands-separated string (culture dependent). Branch filter applied but not displayed. Params are static fields.

### 3b. rptIncomeStatmentActivity (cost-center route)
BeforePrint: fills Acc_SystemConfiguration; EnforceConstraints=false; fills ActivityIncome(from,to,revised,journalTypes,costCenterList) = query C. lblCostCenter = names.
GroupHeader1_BeforePrint: fills Acc_IncomeStatment(from,to,revised,journalTypes,costCenterList,null) = query B (only AccountTypeNature = 1 types).
```
clmOtherIncomes    = fmt(ABS(C(3) - D(3)))      # PeriodCredit - PeriodDebit
clmOtherExpenses   = fmt(D(5))                  # NOT abs, debit-credit
clmGeneralExpenses = fmt(D(4))                  # NOT abs
clmTaxes           = fmt(ABS(D(13)))
totalProfit = SUM over all ActivityIncome rows of CalSubItemBalance   (all cost centers together)
netProfitBeforeTax = totalProfit + parse(clmOtherIncomes.Text) - parse(clmOtherExpenses.Text) - parse(clmGeneralExpenses.Text)
netProfit = netProfitBeforeTax - parse(clmTaxes.Text)
clmNetProfitBeforeTax = fmt(Round(.,approx,AwayFromZero)); clmNetProfit likewise
```
(parse = Convert.ToDecimal of the formatted text.) costCenterList also filters query B.
### 3c. rptIncomeStatmentBranch (branch route)
Same as 3b with BranchIncomeState (query D) fed (from,to,revised,journalTypes, IsNullOrEmpty(branches)?null:branches); query B called with costCenter=null and the branch list. Differences:
```
otherIncome = C(3) - D(3)  (decimal, signed)
clmOtherIncomes = fmt(ABS(otherIncome))
netProfitBeforeTax = SUM(BranchIncomeState.CalSubItemBalance) + otherIncome(RAW signed, not ABS, not rounded) - parse(clmOtherExpenses) - parse(clmGeneralExpenses)
netProfit = netProfitBeforeTax - parse(clmTaxes)
lblBranch = GetBranchNamesBybranchIdList(IsNullOrEmpty(branches)?null:branches)
```
### Layout summaries (activity + branch)
GOP per group = XRSummary Sum(CalSubItemBalance) Running=Group ("Total Activity GOP" / "Total Branch GOP"). Percentage cell: XRSummary Func=Percentage of SubItemBalance, Running=Report, format {0:0%}. clmTotalProfit: Summary Running=Report, format {0:n2} (not the tenant approx).

## 4. SQL VERBATIM (typed DataSet SelectCommand)
Fill passes params positionally in the order listed. Date params DateTime, @JournalRevise Boolean (nullable), lists String (comma separated int ids).
### 4a. Brief, Reports\IncomeStatment\dsIncomeStatement.xsd, Acc_IncomeStatmentTableAdapter (query A)
```sql
WITH    AccountBalance ( AccountId, ParentAccountId, PeriodCredit, PeriodDebit )
          AS ( SELECT   Acc_Account.AccountId,
                        Acc_Account.ParentAccountId,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId,
                                                    Credit,
                                                    Debit,
                                                    PeriodCredit,
                                                    PeriodDebit
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    Acc_Account.AccountId NOT IN (
                        SELECT  ParentAccountId
                        FROM    dbo.Acc_Account
                        WHERE   ParentAccountId IS NOT NULL )
               GROUP BY Acc_Account.AccountId,
                        Acc_Account.ParentAccountId
             )
    SELECT  Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic,
            ISNULL(SUM(AccountBalance.PeriodCredit), 0) AS PeriodCredit,
            ISNULL(SUM(AccountBalance.PeriodDebit), 0) AS PeriodDebit
    FROM    AccountBalance
            RIGHT OUTER JOIN dbo.Acc_Account ON AccountBalance.AccountId = dbo.Acc_Account.AccountId
            RIGHT OUTER JOIN dbo.Acc_AccountType ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
    GROUP BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic
    ORDER BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic

-- params (name DbType): @FromBalanceDate DateTime, @ToBalanceDate DateTime, @JournalRevise Boolean, @JournalTypeList String, @CostCenterList String, @BranchList String
```
### 4b. Cost-center / branch, Reports\IncomeStatmentActivity\dsIncomeStatmentActivity.xsd, Acc_IncomeStatmentTableAdapter (query B = A plus nature filter)
```sql
WITH    AccountBalance ( AccountId, ParentAccountId, PeriodCredit, PeriodDebit )
          AS ( SELECT   Acc_Account.AccountId,
                        Acc_Account.ParentAccountId,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId,
                                                    Credit,
                                                    Debit,
                                                    PeriodCredit,
                                                    PeriodDebit
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate, @ToBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, NULL, NULL,@BranchList)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    Acc_Account.AccountId NOT IN (
                        SELECT  ParentAccountId
                        FROM    dbo.Acc_Account
                        WHERE   ParentAccountId IS NOT NULL )
               GROUP BY Acc_Account.AccountId,
                        Acc_Account.ParentAccountId
             )
    SELECT  Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic,
            ISNULL(SUM(AccountBalance.PeriodCredit), 0) AS PeriodCredit,
            ISNULL(SUM(AccountBalance.PeriodDebit), 0) AS PeriodDebit
    FROM    AccountBalance
            RIGHT OUTER JOIN dbo.Acc_Account ON AccountBalance.AccountId = dbo.Acc_Account.AccountId
            RIGHT OUTER JOIN dbo.Acc_AccountType ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
    WHERE   Acc_AccountType.AccountTypeNature = 1
    GROUP BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic
    ORDER BY Acc_AccountType.AccountTypeId,
            Acc_AccountType.AccountTypeName,
            Acc_AccountType.AccountTypeNameArabic

-- params (name DbType): @FromBalanceDate DateTime, @ToBalanceDate DateTime, @JournalRevise Boolean, @JournalTypeList String, @CostCenterList String, @BranchList String
```
### 4c. ActivityIncomeTableAdapter (cost-center report, query C)
```sql
WITH    AccountBalance ( AccountId, BusinessActivityId, AccountTypeId, PeriodCredit, PeriodDebit, CostCenterId )
          AS ( SELECT   Acc_Account.AccountId ,
                        Balance.CostCenterId ,
                        Acc_Account.AccountTypeId ,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit ,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit ,
                        CostCenterId
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId ,
                                                    Credit ,
                                                    Debit ,
                                                    PeriodCredit ,
                                                    PeriodDebit ,
                                                    CostCenterId
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate,
                                                              @ToBalanceDate,
                                                              @JournalRevise,
                                                              @JournalTypeList,
                                                              @CostCenterList,
                                                              NULL, NULL, NULL)
                                                    AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId ,
                        Balance.CostCenterId ,
                        AccountTypeId
             )
    SELECT  Acc_CostCenter.CostCenterNo ,
            Acc_CostCenter.CostCenterName ,
            Acc_CostCenter.CostCenterId ,
            ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit ,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit ,
            Acc_AccountType.AccountTypeName ,
            Acc_AccountType.AccountTypeNameArabic ,
            AccountBalance_1.AccountTypeId ,
            CASE WHEN AccountBalance_1.AccountTypeId = 2
                 THEN ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)
                        - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) )
                 ELSE ( ABS(ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)
                            - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) )
            END AS SubItemBalance ,
            CASE WHEN AccountBalance_1.AccountTypeId = 2
                 THEN -1 * ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)
                             - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) )
                 ELSE ( ABS(ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)
                            - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) )
            END AS CalSubItemBalance
    FROM    AccountBalance AS AccountBalance_1
            INNER JOIN dbo.Acc_CostCenter ON Acc_CostCenter.CostCenterId = AccountBalance_1.CostCenterId
            INNER JOIN dbo.Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
    WHERE   AccountBalance_1.AccountTypeId IN ( 1, 2 )
    GROUP BY Acc_CostCenter.CostCenterNo ,
            Acc_CostCenter.CostCenterName ,
            Acc_AccountType.AccountTypeName ,
            Acc_CostCenter.CostCenterId ,
            AccountBalance_1.AccountTypeId ,
            Acc_AccountType.AccountTypeNameArabic
    ORDER BY Acc_CostCenter.CostCenterNo ,
            AccountBalance_1.AccountTypeId;

-- params (name DbType): @FromBalanceDate DateTime, @ToBalanceDate DateTime, @JournalRevise Boolean, @JournalTypeList String, @CostCenterList String
```
### 4d. BranchIncomeStateTableAdapter (branch report, query D)
```sql
WITH    AccountBalance ( AccountId, BusinessActivityId, AccountTypeId, PeriodCredit, PeriodDebit, BranchId )
          AS ( SELECT   Acc_Account.AccountId ,
                        Balance.BranchId ,
                        Acc_Account.AccountTypeId ,
                        ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit ,
                        ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit ,
                        Balance.BranchId
               FROM     Acc_Account
                        LEFT OUTER JOIN ( SELECT    AccountId ,
                                                    Credit ,
                                                    Debit ,
                                                    PeriodCredit ,
                                                    PeriodDebit ,
                                                    BranchId
                                          FROM      dbo.Acc_GetAccountJournalActionsBetweenDates(@FromBalanceDate,
                                                              @ToBalanceDate,
                                                              @JournalRevise,
                                                              @JournalTypeList,
                                                              NULL, NULL, NULL,
                                                              @BranchList) AS Acc_GetAccountJournalActionsBetweenDates_1
                                        ) AS Balance ON Acc_Account.AccountId = Balance.AccountId
               WHERE    ( Acc_Account.AccountId NOT IN (
                          SELECT    ParentAccountId
                          FROM      Acc_Account AS Acc_Account_2
                          WHERE     ( ParentAccountId IS NOT NULL ) ) )
               GROUP BY Acc_Account.AccountId ,
                        Balance.BranchId ,
                        AccountTypeId
             )
    SELECT  Acc_Branch.BranchCode ,
            Acc_Branch.BranchName ,
            Acc_Branch.BranchId ,
            ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit ,
            ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit ,
            Acc_AccountType.AccountTypeName ,
            Acc_AccountType.AccountTypeNameArabic ,
            AccountBalance_1.AccountTypeId ,
           CASE WHEN AccountBalance_1.AccountTypeId = 2
                 THEN ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)
                        - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) )
                 ELSE ( ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)
                            - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) )
            END AS SubItemBalance ,
            CASE WHEN AccountBalance_1.AccountTypeId = 2
                 THEN ( -1 * ( ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)
                               - ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) ) )
                 ELSE ( ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)
                            - ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) )
            END AS CalSubItemBalance
    FROM    AccountBalance AS AccountBalance_1
            INNER JOIN dbo.Acc_Branch ON Acc_Branch.BranchId = AccountBalance_1.BranchId
            INNER JOIN dbo.Acc_AccountType ON AccountBalance_1.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
    WHERE   AccountBalance_1.AccountTypeId IN ( 1, 2 )
    GROUP BY Acc_Branch.BranchCode ,
            Acc_Branch.BranchName ,
            Acc_AccountType.AccountTypeName ,
            Acc_Branch.BranchId ,
            AccountBalance_1.AccountTypeId ,
            Acc_AccountType.AccountTypeNameArabic
    ORDER BY Acc_Branch.BranchCode ,
            AccountBalance_1.AccountTypeId

-- params (name DbType): @FromBalanceDate DateTime, @ToBalanceDate DateTime, @JournalRevise Boolean, @JournalTypeList String, @BranchList String
```
### 4e. Helpers (Helper\ApiLoggedUser.cs)
```sql
SELECT  CostCenterName FROM dbo.Acc_CostCenter WHERE (@Ids is null or CostCenterId IN ( SELECT * FROM dbo.Acc_ConvertIntListToTable(@Ids)) );
SELECT  BranchName FROM dbo.Acc_Branch WHERE (@Ids is null or BranchId IN ( SELECT * FROM dbo.Acc_ConvertIntListToTable(@Ids) ));
SELECT Acc_SystemConfiguration.* FROM Acc_SystemConfiguration   -- header: CompanyName, Address, Telephone, Fax, Email
```

## 5. Dependencies and cloud existence
Cloud DB project: D:\Hadaf\worktrees\cr125289\AccFlex_Cloud_Database (branch cr125289), ...State\dbo\.
| Object | Exists | Build Include |
|---|---|---|
| dbo.Acc_GetAccountJournalActionsBetweenDates (TVF) | yes, Functions\ | yes (listed twice: lines 2221, 3547) |
| dbo.Acc_ConvertIntListToTable | yes | yes (x2) |
| dbo.Acc_Account | yes | yes |
| dbo.Acc_AccountType (AccountTypeNature INT NULL) | yes | yes (x2) |
| dbo.Acc_CostCenter, dbo.Acc_Branch, dbo.Acc_SystemConfiguration | yes | yes |
| dbo.Acc_JournalAction, dbo.Acc_Journal (inside TVF) | yes | yes |
MISSING: none.
Cloud TVF (read): returns AccountId, CostCenterId, Credit(0), Debit(0), PeriodCredit=ISNULL(CreditLocal,0), PeriodDebit=ISNULL(DebitLocal,0), CreatedDate, BranchId, JournalTypeId; WHERE j.CreatedDate BETWEEN from AND to, ja.Void=0, j.Void=0, (@JournalRevise IS NULL OR ja.Revised=@JournalRevise), list filters via Acc_ConvertIntListToTable (NULL list = no filter). Legacy TVF body unavailable, so equality of semantics (local currency, Revised on action, date column) is UNVERIFIED.
Settings screen (brief-income-statment-settings; income-accounts-list / income-types-form / income-types-list / settings-shell): maintains Acc_IncomeStatmentMainItem / Acc_IncomeStatmentSubItem and Acc_Account.IncomeStatment (seen only in the non-brief rptIncomeStatemet xsd). None of the three reports in scope read them; all use Acc_AccountType.AccountTypeId directly. Not relevant to this port.

## 6. Layout structure
- rptBriefIncomeStatmentReport: ReportHeader (title "Brief Income Statement", From/To Date, company block, lblRevised, lblCostCenter); column header "Describtion | Partial | Total"; single fixed table, no detail band/grouping: Operating income, Operating expenses, Gross profit, Other income, Administrative/General Expenses, Other expenses, Net Profit (Before Taxes), Taxes, Net Profit. All values set from code (clm* cells). PageFooter "Powered by: www.AccFlex.com", "PC: machine".
- rptIncomeStatmentActivity ("Cost Center Income Statement") / rptIncomeStatmentBranch ("Branch Income Statement"): GroupHeader1 (CostCenterName / BranchName); Detail rows AccountTypeName (Arabic variant when Arabic) + SubItemBalance (n2); group footer "GOP" (Sum CalSubItemBalance) + percentage; report-end rows: Other income, Administrative/General Expenses, Other expenses, Net Profit (Before Taxes), Taxes, Net Profit, clmTotalProfit. Columns "Description | Partial Balance | Total".

## 7. Quirks a faithful port must reproduce
1. Brief: one row per AccountType; leaf accounts only (AccountId NOT IN parents); accounts without journals contribute 0 (LEFT JOIN); no nature filter.
2. Brief: displayed income/expense are ABS; totalProfit = D(1)+D(2) signed; netProfit = netBeforeTax + ROUNDED tax text. Parentheses when net >= 0 and plain when < 0; zero shows "(0.000)".
3. Cost-center: CalSubItemBalance = ABS(debit-credit) for all types except 2; type 2 = -(debit-credit). SubItemBalance type 2 = debit-credit, else ABS(debit-credit). Branch: CalSubItemBalance = credit-debit (signed, no ABS) except type 2 = -(debit-credit); SubItemBalance type 2 = debit-credit else credit-debit. The two queries differ here.
4. NULL CostCenterId / BranchId rows are dropped by INNER JOIN to Acc_CostCenter / Acc_Branch in C and D; a cost center or branch with no journal activity gets no group.
5. Activity/branch reports list only types 1 and 2 per group; other income / expenses / taxes are report-wide (not per group); net profit is the grand total across groups plus report-wide items, one number at report end.
6. Cost-center route: other/general expenses un-ABS'd D; branch route: other income ABS'd for display but RAW signed in the net formula.
7. Cost-center and branch net values are computed from re-parsed formatted text (rounded to approx, culture dependent).
8. Percentage cell is share over the whole report, not per group. Branch layout has bindings to non-existent ActivityIncome.* fields (copy/paste leftover; percent cell and one GOP cell).
9. Dates inclusive to 23:59:59.997; revised null = both. Empty-string -> null only in the branch route; brief/cost-center pass the raw string (empty string would give an empty list to the TVF).
10. Cost-center CTE column names mismatched (BusinessActivityId holds CostCenterId); harmless.
11. Query B throws (FindByAccountTypeId null) if a type 3/4/5/13 row is missing because of the AccountTypeNature=1 filter (nature data not verified).
12. Params are static fields (shared across concurrent requests); ignore in port.
