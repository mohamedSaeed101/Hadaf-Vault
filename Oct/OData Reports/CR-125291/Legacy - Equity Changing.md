# Legacy inventory: Equity Changing Report (تقرير التغير في حقوق المساهمين)

Read-only dissection, 2026-10-15. Paths are absolute.
Repos: Front `D:\Hadaf\worktrees\cr125291\AccFlex_Cloud_Front\accflex-erp`, MVC/reports `D:\Hadaf\AccFlex_ERP` (main checkout),
DB `D:\Hadaf\worktrees\cr125291\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State`.

## 0. Plumbing

| Piece | Value |
|---|---|
| Module file | `...\projects\general-accounting\src\app\modules\financial-reports\financial-reports.module.ts` line 199-203: `path: 'equity-changing'`, `component: EquityChangingShellComponent`, `canActivate: [AccflexAuthGuard, CanActivateRouteGuard]`, **`data: { ModuleId: 364 }`** |
| Menu | `...\general-accounting\src\app\core\routes.ts` line 943-950, id `6_3_2`, text "Equity Changing", textAr "التغيير  في حقوق المساهمين" (double space), route `financial-reports/equity-changing`, `params: ''` |
| Title key | `FINANCIALREPORTS._EquityChangingReport_` (en "Equity Changing Report", ar "تقرير التغير في حقوق المساهمين"; lives in `src\assets\i18n\*\cash-control.json`) |
| iframe URL builder | `...\financial-reports\shared\financial-reports-data.service.ts` line 63 `initializeIFrame(reportUrl, query)` = `` `${printUrl}FinancialReports/${reportUrl}?lang=${lang}&${query}` `` (lang `ar-EG` default when null, else `en-US`) |
| Serializer | `src\app\shared\services\query-serialize\query-serialize.service.ts` (`key=encodeURIComponent(value)` for every form control; arrays → `1,2,3`) |
| MVC controller | `D:\Hadaf\AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\GeneralLedgerReports\FinancialReportsController.cs` line 347-355 |
| View | `REPORTS_ROOT_VIEW = "~/Views/Report/ReportView.cshtml"` (loads a tenant-saved layout by `Model.GetType().Name` + culture from the legacy layout store if one exists, else the compiled Designer layout) |
| `.repx` on disk | **None.** No `D:\Hadaf\ReportLayout` folder; no `.repx`/`.sql` under `D:\Hadaf` names `rptEquityChanging`. Only layout source = `rptEquityChanging.Designer.cs`. |
| `.resx` | `rptEquityChanging.resx` is boilerplate (`Name1/Color1/Bitmap1/Icon1`). Arabic captions are in the Designer's `localizer1` / `pivotLocalizer1`. |
| Desktop twin | `D:\Hadaf\AccFlex_ERP\GeneralAccounting\Accounting\Reports\EquityChanging\frmEquityChangingReport.cs` builds the same `rptEquityChanging(FromDate, ToDate.AddDays(1).AddSeconds(-1), GetEquityAccounts())`, **but refuses to run when the equity account list is empty** (message "Equity accounts should be adjusted in accounts form" / "يجب ضبط حسابات حقوق المالكين من شاشة الحسابات"). MVC has no such guard. |

## 1. Angular — input contract

- Shell: `...\financial-reports\equity-changing\equity-changing-shell\equity-changing-shell.component.ts/.html`.
  - Report name: `this.route.queryParams.report` if present, else `'EquityChanging'` (menu passes `params: ''` → always the default).
  - Reuses the **Cash Flow form**: `<app-cash-flow-form #FormRef [isShowAccount]="false" [isForSabreen]="true">` (`isForSabreen` is declared but unused by the form).
  - `whenSubmit`: `obj = FormRef.FilterForm.value`; `fromDate`/`toDate` → `format(new Date(x), 'yyyy-MM-dd')` (or `''`); `delete obj['branchsesIds']` (**typo** — the control is `branchesIds`, so nothing is deleted); if both dates present → serialize + iframe, else toast `COMMON._DataRequired_`.
- Form: `...\financial-reports\cash-flow\cash-flow-form\cash-flow-form.component.ts/.html`:
  - `FilterForm = { fromDate: [new Date(), required], toDate: [new Date(), required], branchesIds: [''] }`.
  - Defaults patched from `SharedDataService.getReportConfigs()` → `fromDate = ReportingStartDate`, `toDate = ReportingEndDate`.
  - `ngAfterViewInit` patches `revised: ' '` — no such control, so a no-op (not sent).
  - `filter()` validates required and `from <= to` (`COMMON._EndBeforeStartDateErr_`).
  - `app-branch-check-list` is rendered but hidden (`[class.hiddednCotent]="!isShowAccount"`); on init it still emits the user's branch tree ids (or `[]`) → `branchesIds` is filled and **sent**, but the MVC action does not bind it.
- **iframe URL template:**
  `{printUrl}FinancialReports/EquityChanging?lang=<ar-EG|en-US>&fromDate=<yyyy-MM-dd>&toDate=<yyyy-MM-dd>&branchesIds=<csv or empty>`

| Param | Type at MVC | Format | Default | Used? |
|---|---|---|---|---|
| `lang` | `string` | `ar-EG` / `en-US` | `ar-EG` | yes → `ChangeThreadCulture` → `ApiLoggedUser.IsArabic` picks Arabic query + layout |
| `fromDate` | `DateTime` | `yyyy-MM-dd` | `ReportingStartDate` | yes; rpt truncates to 00:00:00 |
| `toDate` | `DateTime` | `yyyy-MM-dd` | `ReportingEndDate` | yes; rpt sets 23:59:59.997 |
| `branchesIds` | — (not bound) | csv | user's branches | **ignored** (no branch filter in the report at all) |

## 2. MVC action

```csharp
[Route("mvc/FinancialReports/EquityChanging")]
public IActionResult EquityChanging(string lang, DateTime fromDate, DateTime toDate)
{
    ChangeThreadCulture(lang);
    var report = new rptEquityChanging(fromDate, toDate, ApiLoggedUser.GetEquityAccounts());
    return View(REPORTS_ROOT_VIEW, report);
}
```

`ApiLoggedUser.GetEquityAccounts()` (`D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Helper\ApiLoggedUser.cs` line 794):
```sql
select AccountId from Acc_Account where EquityType is not null  AND islastnode=1
```
→ `string.Join(",", ids)`. **Equity accounts are identified by `Acc_Account.EquityType` (FK to `Acc_EquityType`) on leaf accounts (`IsLastNode = 1`)** — not by account type. Empty string when none.

## 3. rpt: `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\EquityChanging\rptEquityChanging.cs`

- No subreports. One pivot (`xrPvtEquity`) inside `GroupHeader1`.
- Ctor `()`: `IsArabic = ApiLoggedUser.IsArabic`; `Name = !IsArabic ? "rptEquityChanging" : "rptEquityChangingAr"`; Arabic → `localizer1.ApplyArabic(); pivotLocalizer1.ApplyArabic();`; `approximateNo = ApiLoggedUser.GetApproximateNo()` (`SELECT TOP(1) ApproximateNo FROM dbo.Acc_SystemConfiguration`, 0 if null); `moneyApproximate1.ApplyApproximate(approximateNo)` (only touches the 3 header text labels, `IsMoney=false`).
- Ctor `(fromDate, toDate, accountsList)`:
  ```csharp
  this.fromDate = new DateTime(fromDate.Year, fromDate.Month, fromDate.Day, 0, 0, 0);
  this.toDate   = new DateTime(toDate.Year, toDate.Month, toDate.Day, 23, 59, 59, 997);
  this.accountList = accountsList;
  journalTypeList = string.Join(",", ApiLoggedUser.getArrayExpectJournalType(4));  // 4 is journalType قيود اقفال فتره
  ```
  `getArrayExpectJournalType(4)` = all `Acc_JournalType.JournalTypeId` except 4 ("End Period Journal" / قيود اقفال فتره). **The list is passed to the query as `@JournalTypeList` but the SQL never uses that parameter** → closing journals are NOT excluded.
- `rptEquityChanging_BeforePrint`:
  - Arabic: `RightToLeft = Yes; RightToLeftLayout = Yes; xrPivotGridField4.FieldName = "ArabicName";` (column headers switch from `EnglishName` to `ArabicName`).
  - `lblFrom.Text = fromDate.ToString("dd/MM/yyyy"); lblTo.Text = toDate.ToString("dd/MM/yyyy");`
  - `acc_SystemConfigurationTableAdapter.Fill(ds.Acc_SystemConfiguration)`
  - Arabic → `accountsBalancesTableAdapter.FillByArabic(ds.AccountsBalances, fromDate, toDate, accountList, journalTypeList)`; else `.Fill(...)` same args.
  - `xrPvtEquity.Fields.GetFieldByName("xrPivotGridField7").CellFormat.FormatString = string.Format("{{0:n{0}}}", approximateNo);` → data cells rounded to tenant decimals (Designer default `N2`).
- `xrPvtEquity_FieldValueDisplayText`: on `GrandTotal` values: column grand total header → "Total" / "اجمالى القيمه"; row grand total header → "Balance" / "الرصيد".
- `xrPvtEquity_CustomColumnWidth`: grand-total column width 100.
- No other C# math. All arithmetic is in SQL + the pivot's SUM and grand totals.

## 4. ds: `...\EquityChanging\dsEquityChanging.xsd`

TableAdapters: `Acc_SystemConfiguration` (table `SELECT ... FROM Acc_SystemConfiguration`, header only) and `AccountsBalances` (`Fill` + `FillByArabic`).
Parameters (both queries): `@fromdate datetime NOT NULL`, `@todate datetime NOT NULL`, `@accountslist nvarchar NULL`, `@JournalTypeList nvarchar NULL` (unused).
DataTable `AccountsBalances` columns: `EquityType int`, `OpeningBlance decimal`, `EnglishName string(50)`, `ArabicName string(50)`, `Type string MaxLength 13`, `num int`. DataSet `EnforceConstraints = false` (so the 13-char limit on `Type` is not enforced for the long Arabic labels).

### `AccountsBalances.Fill` (English, verbatim)
```sql
DECLARE @strAccount NVARCHAR(MAX) =
        (
            SELECT STUFF(
                   (
                       SELECT ',' + CONVERT(NVARCHAR(MAX), AccountId)
                       FROM Acc_Account
                           RIGHT OUTER JOIN dbo.Acc_AccountType
                               ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
                       WHERE Acc_Account.AccountId NOT IN
                             (
                                 SELECT ParentAccountId
                                 FROM dbo.Acc_Account
                                 WHERE ParentAccountId IS NOT NULL
                             )
                             AND Acc_AccountType.AccountTypeId = 12
                       FOR XML PATH('')
                   ),
                   1,
                   1,
                   ''
                        ) AS AccountId
        );

WITH OpeningBlance
AS (SELECT AccountId,
           OpenningDebit - OpenningCredit AS OpeningBlance,
           'OpeningBlance' AS Type,
           1 AS num
    FROM dbo.Acc_GetAccountsBalancePeriod(@fromdate, @todate, @accountslist, NULL, NULL, NULL, NULL) AS Acc_GetAccountsBalancePeriod_1 ),
     PeriodBalance
AS (SELECT AccountId,
           PeriodDebit - PeriodCredit AS PeriodBalance,
           'PeriodBalance' AS Type,
           2 AS num
    FROM dbo.Acc_GetAccountsBalancePeriod(@fromdate, @todate, @accountslist, NULL, NULL, NULL, NULL) AS Acc_GetAccountsBalancePeriod_1 ),
     EndBalance
AS (SELECT SUM(PeriodDebit - PeriodCredit) AS EndBalance,
           'EndBalance' AS Type,
           3 AS EquityType,
           3 AS num
    FROM dbo.Acc_GetAccountsBalancePeriod(@fromdate, @todate, @strAccount, NULL, NULL, NULL, NULL) AS Acc_GetAccountsBalancePeriod_1 )
SELECT Acc_Account.EquityType,
       CASE
           WHEN EquityTypeId IN ( 2, 3 ) THEN
       (SUM(OpeningBlance_1.OpeningBlance)) * -1
           ELSE
               ABS(SUM(OpeningBlance_1.OpeningBlance))
       END AS OpeningBlance,
       MIN(Type) AS Type,
       num,
       Acc_EquityType.EnglishName,
       Acc_EquityType.ArabicName
FROM Acc_EquityType
    RIGHT OUTER JOIN Acc_Account
        ON Acc_EquityType.EquityTypeId = Acc_Account.EquityType
    RIGHT OUTER JOIN OpeningBlance AS OpeningBlance_1
        ON Acc_Account.AccountId = OpeningBlance_1.AccountId
GROUP BY Acc_Account.EquityType,
         Acc_EquityType.EnglishName,
         Acc_EquityType.ArabicName,
         EquityTypeId,
         num
UNION ALL
SELECT Acc_Account.EquityType,
       CASE
           WHEN EquityTypeId IN ( 2, 3 ) THEN
       (SUM(PeriodBalance_1.PeriodBalance)) * -1
           ELSE
               ABS(SUM(PeriodBalance_1.PeriodBalance))
       END AS OpeningBlance,
       MIN(Type) AS Type,
       num,
       Acc_EquityType.EnglishName,
       Acc_EquityType.ArabicName
FROM Acc_EquityType
    RIGHT OUTER JOIN Acc_Account
        ON Acc_EquityType.EquityTypeId = Acc_Account.EquityType
    RIGHT OUTER JOIN PeriodBalance AS PeriodBalance_1
        ON Acc_Account.AccountId = PeriodBalance_1.AccountId
GROUP BY Acc_Account.EquityType,
         Acc_EquityType.EnglishName,
         Acc_EquityType.ArabicName,
         EquityTypeId,
         num
UNION ALL
SELECT Acc_EquityType.EquityTypeId,
       ABS(SUM(EndBalance_1.EndBalance)) AS EndBalance,
       MIN(Type) AS Type,
       num,
       Acc_EquityType.EnglishName,
       Acc_EquityType.ArabicName
FROM Acc_EquityType
    INNER JOIN EndBalance AS EndBalance_1
        ON EndBalance_1.EquityType = Acc_EquityType.EquityTypeId
GROUP BY Acc_EquityType.EquityTypeId,
         Acc_EquityType.EnglishName,
         Acc_EquityType.ArabicName,
         num
```

### `AccountsBalances.FillByArabic` (Arabic, verbatim)
```sql
DECLARE @strAccount NVARCHAR(MAX) =
        (
            SELECT STUFF(
                   (
                       SELECT ',' + CONVERT(NVARCHAR(MAX), AccountId)
                       FROM Acc_Account
                           RIGHT OUTER JOIN dbo.Acc_AccountType
                               ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
                       WHERE Acc_Account.AccountId NOT IN
                             (
                                 SELECT ParentAccountId
                                 FROM dbo.Acc_Account
                                 WHERE ParentAccountId IS NOT NULL
                             )
                             AND Acc_AccountType.AccountTypeId = 12
                       FOR XML PATH('')
                   ),
                   1,
                   1,
                   ''
                        ) AS AccountId
        );

WITH OpeningBlance
AS (SELECT AccountId,
           OpenningDebit - OpenningCredit AS OpeningBlance,
           N'رصيد أول المدة' AS Type,
           1 AS num
    FROM dbo.Acc_GetAccountsBalancePeriod(@fromdate, @todate, @accountslist, NULL, NULL, NULL, NULL) AS Acc_GetAccountsBalancePeriod_1 ),
     PeriodBalance
AS (SELECT AccountId,
           PeriodDebit - PeriodCredit AS PeriodBalance,
           N'التغير ف الاحتياطات وحقوق المساهمين' AS Type,
           2 AS num
    FROM dbo.Acc_GetAccountsBalancePeriod(@fromdate, @todate, @accountslist, NULL, NULL, NULL, NULL) AS Acc_GetAccountsBalancePeriod_1 ),
     EndBalance
AS (SELECT SUM(PeriodDebit - PeriodCredit) AS EndBalance,
           N'صافى أرباح/خسائر العام' AS Type,
           3 AS EquityType,
           3 AS num
    FROM dbo.Acc_GetAccountsBalancePeriod(@fromdate, @todate, @strAccount, NULL, NULL, NULL, NULL) AS Acc_GetAccountsBalancePeriod_1 )
SELECT Acc_Account.EquityType,
       CASE
           WHEN EquityTypeId IN ( 2, 3 ) THEN
       (SUM(OpeningBlance_1.OpeningBlance)) * -1
           ELSE
               ABS(SUM(OpeningBlance_1.OpeningBlance))
       END AS OpeningBlance,
       MIN(Type) AS Type,
       num,
       Acc_EquityType.EnglishName,
       Acc_EquityType.ArabicName
FROM Acc_EquityType
    RIGHT OUTER JOIN Acc_Account
        ON Acc_EquityType.EquityTypeId = Acc_Account.EquityType
    RIGHT OUTER JOIN OpeningBlance AS OpeningBlance_1
        ON Acc_Account.AccountId = OpeningBlance_1.AccountId
WHERE Acc_EquityType.EquityTypeId IS NOT NULL
GROUP BY Acc_Account.EquityType,
         Acc_EquityType.EnglishName,
         Acc_EquityType.ArabicName,
         EquityTypeId,
         num
UNION ALL
SELECT Acc_Account.EquityType,
       CASE
           WHEN EquityTypeId IN ( 2, 3 ) THEN
       (SUM(PeriodBalance_1.PeriodBalance)) * -1
           ELSE
               ABS(SUM(PeriodBalance_1.PeriodBalance))
       END AS OpeningBlance,
       MIN(Type) AS Type,
       num,
       Acc_EquityType.EnglishName,
       Acc_EquityType.ArabicName
FROM Acc_EquityType
    RIGHT OUTER JOIN Acc_Account
        ON Acc_EquityType.EquityTypeId = Acc_Account.EquityType
    RIGHT OUTER JOIN PeriodBalance AS PeriodBalance_1
        ON Acc_Account.AccountId = PeriodBalance_1.AccountId
WHERE Acc_EquityType.EquityTypeId IS NOT NULL
GROUP BY Acc_Account.EquityType,
         Acc_EquityType.EnglishName,
         Acc_EquityType.ArabicName,
         EquityTypeId,
         num
UNION ALL
SELECT Acc_EquityType.EquityTypeId,
       ABS(SUM(EndBalance_1.EndBalance)) AS EndBalance,
       MIN(Type) AS Type,
       num,
       Acc_EquityType.EnglishName,
       Acc_EquityType.ArabicName
FROM Acc_EquityType
    INNER JOIN EndBalance AS EndBalance_1
        ON EndBalance_1.EquityType = Acc_EquityType.EquityTypeId
WHERE Acc_EquityType.EquityTypeId IS NOT NULL
GROUP BY Acc_EquityType.EquityTypeId,
         Acc_EquityType.EnglishName,
         Acc_EquityType.ArabicName,
         num
```

### Diff Arabic vs English (data)
1. `Type` labels: `'OpeningBlance' / 'PeriodBalance' / 'EndBalance'` vs `N'رصيد أول المدة' / N'التغير ف الاحتياطات وحقوق المساهمين' / N'صافى أرباح/خسائر العام'`. English labels are raw tokens (typo "Blance"); Arabic "End" row is labelled "net profit/loss of the year".
2. Arabic adds `WHERE Acc_EquityType.EquityTypeId IS NOT NULL` to all three branches. In practice no difference: `@accountslist` only holds accounts with `EquityType IS NOT NULL` and `Acc_Account.EquityType` has an FK to `Acc_EquityType`, so no NULL-type rows reach the English output either (only possible if `Acc_ConvertIntListToTable` yields ids not in `Acc_Account`).
3. Everything else (numbers) identical.

### What the query computes (in words)
- `Acc_GetAccountsBalancePeriod(@from, @to, list, NULL, NULL, NULL, NULL)` → per account in `list`: `OpenningDebit/Credit` = opening-balance table (`Acc_GetAccountBalanceBeforeDate`) + journals before `@from`; `PeriodDebit/Credit` = journals in `[@from, @to]`. JournalRevise NULL (both revised and not), **JournalTypeList NULL (all types, including closing journals type 4)**, no currency, **no branch filter**. Leaf rows only for a leaf-only list (the CTE is recursive and also emits parents, filtered out by the list).
- Row `num=1` (Opening) per equity type `T`: `T in (2,3) → -(Σ(OpenDr − OpenCr))` (credit-positive, signed); else `ABS(Σ(OpenDr − OpenCr))`.
- Row `num=2` (Change during the period) per `T`: `T in (2,3) → -(Σ(PerDr − PerCr))`; else `ABS(Σ(PerDr − PerCr))`.
- Row `num=3` (Net profit/loss), always in column `EquityType = 3` ("Year Profit/Loss" / "أرباح/خسائر العام"): `ABS(Σ(PerDr − PerCr))` over **leaf accounts of `AccountTypeId = 12` ("Profit / Loss" / "الارباح / الخسائر")** — independent of the equity-account list.
- Equity types (`Acc_EquityType`, reference data `Scripts\ReferenceDataScripts\0001_GL_ReferenceDate.sql` line 1089): 1 Equity Capital / رأس المال, 2 Profits/Loss Migrated / أرباح/خسائر مرحلة, 3 Year Profit/Loss / أرباح/خسائر العام, 4 Shareholders' Equity / حقوق المساهمين, 5 Reserves / الاحتياطيات, 6 Allocations / المخصصات.
- The Opening/Change rows only produce a column for equity types that have at least one leaf account flagged with that `EquityType` (rows exist even when the balance is 0, since the function returns every listed account). The Net-profit row always produces column 3 (one row even if no type-12 accounts, value NULL → empty cell → "0").

## 5. Layout (`rptEquityChanging.Designer.cs`) — it IS a pivot (cross-tab)

- Bands: `TopMargin` 15, `ReportHeader` (company: `MainLogo` ← `Acc_SystemConfiguration.Logo`, `MainCompanyName` ← `CompanyName`, `MainComapnyAddress` ← `Address`, `MainCompanyContact` ← `Email` only), `PageHeader` (height 202.9: title `xrLabel1` "Owners' Equity Changing Report" / Ar "تقرير التغيير في حقوق المساهمين"; "From"/"من" `lblFrom`; "To"/"الي" `lblTo`; `lblRevised` and `lblCurrency` — empty, never set), `GroupHeader1` (no group fields → printed once; holds `xrPvtEquity`), `Detail` (empty, height 25), `ReportFooter` (`MainPageNo` "Page {0} Of {1}", `MainPrintDate` "Printed On {0:dd/MM/yyyy hh:mm tt}", `mainPrintedFrom` "PC :", `lblHadaf` " www.AccFlex.com   "), `BottomMargin` 18. **No PageFooter** — page no./print date only on the last page. Margins (10, 14, 15, 18), portrait default paper.
- Report `DataMember = "AccountsBalances"` → the empty 25-px `Detail` band repeats once per data row (≈ 2×N+1 rows) → blank space under the pivot.
- `xrPvtEquity` (DataMember `AccountsBalances`, width 826):
  | Field | Area | FieldName | Caption (en / ar) | Notes |
  |---|---|---|---|---|
  | `colSubItemName2` | **Row** | `Type` | Type / النوع | `SortMode = Custom`, no `CustomFieldSort` handler; width 110 |
  | `xrPivotGridField4` | **Column** | `EnglishName` (→ `ArabicName` in Arabic) | English Name / الاسم | `SortMode = Custom`, no handler; `Options.ShowValues = false`; width 80 |
  | `xrPivotGridField7` | **Data** | `OpeningBlance` | Opening Blance / الفعلي | SUM; format `{0:n<ApproximateNo>}`; `EmptyCellText = EmptyValueText = "0"`; width 77 |
  | `xrPivotGridField1` | Data, `Visible=false` | `BudgetValue` (column does not exist) | Budget Value / التقديري | dead |
  - `ShowColumnHeaders/ShowDataHeaders/ShowRowHeaders = false`, `PrintColumnHeaders/PrintDataHeaders = False` → no field-header buttons, only values.
  - Grand totals left at defaults (shown): a **"Total" / "اجمالى القيمه"** column (row sum across all equity types, width 100) and a **"Balance" / "الرصيد"** row (column sum of Opening + Change + Net profit = closing balance per equity type).
- **Printed statement shape:** columns = equity types (one per `Acc_EquityType` present) + "Total"; rows = Opening balance, Change in reserves/equity, Net profit/loss of the year (only filled under "Year Profit/Loss"), then "Balance" (closing) grand-total row.
- Arabic: RTL + RTL layout, column values from `ArabicName`.

## 6. SQL objects → cloud DB (`...\AccFlex_Cloud_Database_State\dbo\`)

| Object | Cloud | Registered in .sqlproj |
|---|---|---|
| `Acc_GetAccountsBalancePeriod` (7 params: from, to, AccountList, JournalRevise, JournalTypeList, CurrencyId, BranchList) | `Functions\Acc_GetAccountsBalancePeriod.sql` — exists | yes |
| `Acc_GetAccountBalanceBeforeDate` (nested) | `Functions\Acc_GetAccountBalanceBeforeDate.sql` — exists | yes |
| `Acc_GetAccountJournalActionsBeforeDate` (nested) | `Functions\Acc_GetAccountJournalActionsBeforeDate.sql` — exists | yes |
| `Acc_GetAccountJournalActionsBetweenDates` (nested) | `Functions\Acc_GetAccountJournalActionsBetweenDates.sql` — exists | yes |
| `Acc_ConvertIntListToTable` (nested) | `Functions\Acc_ConvertIntListToTable.sql` — exists | yes |
| `Acc_Account` (`EquityType INT NULL` FK → `Acc_EquityType`, `IsLastNode BIT`) | `Tables\Acc_Account.sql` — exists | yes |
| `Acc_EquityType` (EquityTypeId identity, EnglishName/ArabicName nvarchar(50)) | `Tables\Acc_EquityType.sql` — exists; seeded 1-6 in `Scripts\ReferenceDataScripts\0001_GL_ReferenceDate.sql` | yes |
| `Acc_AccountType` (type 12 = Profit / Loss) | `Tables\Acc_AccountType.sql` — exists | yes |
| `Acc_JournalType` (C# only, type 4 = End Period Journal) | `Tables\Acc_JournalType.sql` — exists | yes |
| `Acc_SystemConfiguration` (header, ApproximateNo) | `Tables\Acc_SystemConfiguration.sql` — exists | yes |

**Nothing MISSING.** The port can call `Acc_GetAccountsBalancePeriod` directly and reproduce the account list from `Acc_Account` (`EquityType IS NOT NULL AND IsLastNode = 1`).

## 7. Quirks a faithful port must reproduce (or consciously drop)

1. **Closing journals are included.** C# builds a "all types except 4" list but the SQL ignores `@JournalTypeList` and passes `NULL` to the function. MVC numbers include End-Period journals.
2. **Sign rule by equity type:** types 2 (migrated P/L) and 3 (year P/L) are signed credit-positive (`-(Dr−Cr)`); types 1, 4, 5, 6 are `ABS(Dr−Cr)` — a debit-balance capital/reserve prints positive, and a **decrease** during the period prints as a positive change, so the "Balance" row adds it instead of subtracting.
3. **Net-profit row is `ABS`** of the period movement of type-12 leaf accounts → a loss prints and is added as a positive amount into the type-3 closing.
4. Net-profit uses **`PeriodDebit − PeriodCredit` of type-12 accounts**, not the income statement; and it lands in column `EquityType 3` *in addition to* any opening/change rows of accounts flagged `EquityType = 3` (possible double count if the type-12 P/L account is also flagged `EquityType = 3`).
5. If no leaf account has `AccountTypeId = 12`, `@strAccount` is NULL → the function returns **all accounts incl. rolled-up parents** (its `@AccountList IS NULL` branch) and the net-profit row = ABS of the whole-ledger period movement (≈ 0 if journals balance, but with parents counted multiple times).
6. If no equity accounts are flagged, MVC passes `''` → no Opening/Change rows; only the Net-profit row/column 3 prints (desktop refuses with an error instead).
7. "Balance" row and "Total" column are **pivot grand totals** (pure SUMs of the printed cells, after the ABS/sign rules) — the closing balance is never read from the ledger.
8. Opening balance = opening-balance table + all journals before `fromDate` (all years, all branches, revised and not revised). No branch filter even though the front sends `branchesIds`.
9. Rounding: data cells `{0:n<ApproximateNo>}`; empty cells print "0". Grand-total cells use the pivot's default total format (not explicitly set) — verify on a live print.
10. Row order = pivot default value sort of the `Type` string (custom sort with no handler): English `EndBalance`, `OpeningBlance`, `PeriodBalance` (net profit first!); Arabic `التغير…`, `رصيد أول المدة`, `صافى…` (change first, opening second). The `num` column (intended 1/2/3 order) is not used by the pivot. Column order = alphabetical by `EnglishName` / `ArabicName` (so it differs between languages too).
11. Dates: from 00:00:00, to 23:59:59.997 (MVC); desktop uses `ToDate.AddDays(1).AddSeconds(-1)` then the rpt re-normalises to .997 — same window.
12. Header: no revised/currency/branch caption (labels exist but are empty). Contact = Email only. Page number and print date only on the last page (in ReportFooter). Blank detail rows under the pivot.

### Language-only differences
- Row labels (English raw tokens with typo vs proper Arabic captions) and row/column ordering (quirk 10).
- Arabic adds `EquityTypeId IS NOT NULL` filters — no practical numeric effect (FK).
- Arabic switches column field to `ArabicName` and RTL. Data caption localisation `pivotLocalizer1` (headers are not printed anyway).
- Grand-total captions from C#: "Total"/"Balance" vs "اجمالى القيمه"/"الرصيد".

## 8. Open questions

1. Keep closing journals (type 4) in, as MVC does, or apply the clearly intended exclusion? (Including them moves the year's P/L into migrated P/L inside the period.)
2. Keep the `ABS` on types 1/4/5/6 and on net profit (losses and decreases print positive and add up), or sign them properly? Fidelity says keep; accounting says fix.
3. Row order: replicate the alphabetical (language-dependent) order, or use `num` (Opening → Change → Net profit → Balance) in both languages? Need a live MVC print to confirm what DevExpress actually does with `SortMode.Custom` and no handler.
4. Possible double count in "Year Profit/Loss" column when the type-12 account is also flagged `EquityType = 3` — check tenant data.
5. Should the port add the desktop's "no equity accounts configured" guard?
6. `branchesIds` is sent but ignored — keep the report branch-agnostic (fidelity) or add a branch filter (the function supports `@BranchList`)?
7. Any tenant-saved layout in the legacy MVC layout store for `rptEquityChanging` / `rptEquityChangingAr`? Not inspectable from the repo.
8. Grand-total cell number format (decimals) — confirm on a live print.
