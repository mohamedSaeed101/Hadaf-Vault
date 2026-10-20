# Legacy inventory: three MVC Balance Sheet reports (Brief / Comparative / Financial Position)

Read-only dissection, 2026-10-15. Front read from the CR set `D:\Hadaf\worktrees\cr125291\AccFlex_Cloud_Front\accflex-erp`
(branch `cr125291`); MVC/reports from the main checkout `D:\Hadaf\AccFlex_ERP` (it sits on branch `cr94062`, but
`git diff origin/Master_Stable HEAD` is empty for the three report folders and `FinancialReportsController.cs`, and the
working tree is clean there, so what is below equals `Master_Stable`). Cloud DB checked in
`D:\Hadaf\worktrees\cr125291\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\`.
Every TableAdapter query is copied verbatim in the **Appendix** (generated straight from the `.xsd` files); the sections
quote the shape and prove which queries are identical.

## 0. Common plumbing (applies to all three)

| Piece | Value |
|---|---|
| Module file | `...\projects\general-accounting\src\app\modules\financial-reports\financial-reports.module.ts` lines 168-191: `brief-general-balance`, `balance-sheet`, `compare-balance-sheet`, `financial-position-statement`, all `component: OneDateShellComponent`, `canActivate: [AccflexAuthGuard, CanActivateRouteGuard]`, **`data: { ModuleId: 75 }`** |
| Menu | `...\projects\general-accounting\src\app\core\routes.ts` lines 895-926, group 6_2 (Balance sheet): `6_2_2` "Brief Balance Sheet Report" / "تقرير الميزانية المختصر" `params: ''`; `6_2_3` "Balance Report" `params: { report: 'BalanceSheet' }` (already migrated in fx123513); `6_2_4` "Compared Balance Report" / "تقرير مقارنة الميزانية" `params: { report: 'CompareBalanceSheet' }`; `6_2_5` "Financial Position Statement Report" / "تقرير المركز المالي الإجمالي" `params: { report: 'FinancialPositionStatement' }` |
| Shell | `...\financial-reports\one-date-form\one-date-shell\one-date-shell.component.ts` (`OneDateShellComponent`). Reads `queryParams.report`: `'CompareBalanceSheet'` → `isHavingFilterByBranches = false`, anything else → `true`; `'FinancialPositionStatement'` → `isFinPositionLabel = true`; any other non-empty report → plain labels; no report → `isInDateLabel = true`. On submit: `report = this.report ?? 'BriefGeneralBalance'`; `obj.toDate = format(new Date(obj.toDate), 'yyyy-MM-dd')`; if `toDate` is empty, toast `COMMON._DataRequired_`; else `serialize(obj)` → `initializeIFrame(report, query)` → `<accflex-report-iframe>`. |
| Shell title | the `<h6>` is **always** `FINANCIALREPORTS._BriefGeneralBalanceReport_`, for all three routes (cosmetic bug). |
| Form | `...\one-date-form\one-date-form\one-date-form.component.ts/.html` (`OneDateFormComponent`). `FilterForm = fb.group({ toDate: [new Date(), Validators.required], branchesIds: [''], branchesNames: [''] })`; then `toDate` is patched to `SharedDataService.getReportConfigs().ReportingEndDate`. `dx-date-box displayFormat="dd/MM/yyyy"`, label `COMMON._InDate_` (brief) / `COMMON._BalanceSheetIn_` (compare) / `COMMON._FinPositionLabel_` (FPS). `app-branch-check-list` is shown only when `isHavingFilterByBranches` (`*ngIf`); `(whenBranchChange)` → `branchesIds`, `(getSeletedBranchesNames)` → `branchesNames`. |
| Branch checklist | `...\general-accounting\src\app\shared\components\branch-check-list\branch-check-list.component.ts`: `isSelectAll = true` by default, so `ngOnInit` emits **every branch id of the user's tree** (`getBranchListRelatedToCurrentUseTree`) into `branchesIds`, but **does not emit names**, so `branchesNames` stays `''` until the user touches the tree. User selection → ids array + names joined with `-`. "Select all" unticked → ids `[]`, names `null`. |
| URL builder | `...\financial-reports\shared\financial-reports-data.service.ts` `initializeIFrame(reportUrl, query)` = `` `${this.printUrl}FinancialReports/${reportUrl}?lang=${this.lang}&${query}` ``; `lang` = `ar-EG` (default / null) or `en-US`. |
| Serializer | `accflex-erp\src\app\shared\services\query-serialize\query-serialize.service.ts`: every `FilterForm.value` key → `encodeURIComponent(key)=encodeURIComponent(value)`. `toDate` is already a `yyyy-MM-dd` string. Arrays → `1,2,3` → `1%2C2%2C3`; `''` → empty; `null` → literal `null`. **All three keys are always sent**, including for Compare where the branch list is hidden. |
| MVC controller | `D:\Hadaf\AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\GeneralLedgerReports\FinancialReportsController.cs` lines 291-332, pattern `ChangeThreadCulture(lang); var report = new rpt…(…); return View(REPORTS_ROOT_VIEW, report);`. ASP.NET Core binds an empty query value to `null` for `string` params. |
| Report folder | `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\` — `General Balance\` (brief), `BalanceSheetStatment\` (compare, shares the folder with the already-migrated `rptBalanceSheet`), `FinancialPositionStatement\`. |
| Layout lookup | as in the CR-125290 note: `ReportView.cshtml` → legacy layout store by `Model.GetType().Name` + culture, otherwise the compiled `*.Designer.cs`. **No `.repx` on disk**: `D:\Hadaf\ReportLayout` does not exist and no `.repx` under `D:\Hadaf` names these reports. The Designer files are the layout source. |
| `.resx` | All three are boilerplate (`Name1/Color1/Bitmap1/Icon1`; compare also `xrPictureBox1.ImageSource`). Arabic captions live in the Designer `localizer1` (`itemTranslationN.Arabic`), applied by `localizer1.ApplyArabic()` when `ApiLoggedUser.IsArabic`. |
| Rounding | `moneyApproximate1.ApplyApproximate(ApiLoggedUser.GetApproximateNo())` rewrites the bound money cells' format to `{0:n<approx>}` (the Designer's `{0:n2}` is only the fallback). Code-computed totals use `ToString("N<approx>")`. |
| Company header | `ReportHeader` bound to `Acc_SystemConfiguration` (FPS: `Financial_Acc_SystemConfiguration`), query `SELECT Acc_SystemConfiguration.* FROM Acc_SystemConfiguration`: Logo, CompanyName, Address, Tel/Telephone, Fax, E-Mail. Page footer: page x of y, printed-on date, `PC: <MachineName>`, "Powered By: www.AccFlex.com". The OData port passes the six `CompanyInfo` parameters as fx123513 does. |
| Date semantics | All three end up "balance **as of the end of** `toDate`": they pass `toDate.Date + 1 day` to SQL, and both balance TVFs use `CreatedDate < @date` / `SubPeriodStart <= @date`. |
| Thread safety | brief: `private static DateTime toDate; private static string BranchIdListCommaSeparated;` compare: the ten totals are `private static decimal`. Shared across concurrent requests (legacy prints can mix filters under load). |

### Shared SQL building block (all three reports, and fx123513)

```
leaf accounts  (Acc_Account.AccountId NOT IN (SELECT ParentAccountId ... IS NOT NULL))
LEFT JOIN ( Acc_GetAccountBalanceBeforeDate(@date, NULL, @branches)            -- transferred opening balance row of the sub-period
            UNION ALL
            Acc_GetAccountJournalActionsBeforeDate(@date, NULL…, @branches) )   -- journals from that sub-period start up to < @date
```
Both functions return `Credit`/`Debit` (local currency) and `PeriodCredit = PeriodDebit = 0`. The CTE names its columns
`OpenningCredit/OpenningDebit` but they carry `SUM(Credit)/SUM(Debit)` of both sources, i.e. the **closing balance as of
@date**. Every `PeriodCredit/PeriodDebit` term in the outer queries is always 0. `@JournalRevise`, `@JournalTypeList`,
`@CostCenterList` are passed as NULL in all three reports.

Classification differs:
- **Brief** groups leaf accounts by **`Acc_Account.AccountTypeId`** (`Acc_AccountType.AccountTypeNature = 2`; types 6 Long-term assets, 7 Current Assets, 8 Current Liabilities, 9 Equity, 10 Long-term liabilities, 12 Profit/Loss; seeded in `Scripts\ReferenceDataScripts\0001_GL_ReferenceDate.sql` lines 63-69, all nature 2).
- **Compare** and **FPS** group by the balance-sheet mapping **`Acc_Account.GeneralBalance` → `Acc_BalanceSheetSubItems` → `Acc_BalanceSheetMainItems`** (MainItemId 1 LTA, 2 CA, 3 CL, 4 Equity, 5 LTL; seeded same file lines 379-383). Accounts with no `GeneralBalance` are excluded entirely, which is the same as `rptBalanceSheet` / fx123513.

### Input contract table

| Report | iframe `report` | form keys sent (in order) | branch list visible | required |
|---|---|---|---|---|
| 1 Brief | `BriefGeneralBalance` (hard-coded default, route has `params: ''`) | `toDate`, `branchesIds`, `branchesNames` | yes | `toDate` |
| 2 Compare | `CompareBalanceSheet` | `toDate`, `branchesIds` (always `''`), `branchesNames` (always `''`) | **no** | `toDate` |
| 3 FPS | `FinancialPositionStatement` | `toDate`, `branchesIds`, `branchesNames` | yes | `toDate` |

| Param | Type | Format | Default | Filled by |
|---|---|---|---|---|
| `lang` | string | `ar-EG` / `en-US` | `ar-EG` | `GlobalLanguageService` |
| `toDate` | date | `yyyy-MM-dd` (date-fns `format`) | `ReportingEndDate` from `getReportConfigs()`, before that `new Date()` | `dx-date-box` |
| `branchesIds` | CSV of int | `1,2,3` URL-encoded `1%2C2%2C3`; `''` when none | **all of the user's branches** (`isSelectAll = true`) | `app-branch-check-list (whenBranchChange)` |
| `branchesNames` | string | names joined with `-`; `''` on first load; literal `null` after "unselect all" | `''` | `app-branch-check-list (getSeletedBranchesNames)` |

---

## 1. Brief Balance Sheet (`financial-reports/brief-general-balance`)

### Angular
- Route: module line 169, `OneDateShellComponent`, `data: { ModuleId: 75 }`. Menu `6_2_2`, `params: ''` → `report` undefined → `'BriefGeneralBalance'`, label `COMMON._InDate_`, branch list shown.
- iframe URL: `{printUrl}FinancialReports/BriefGeneralBalance?lang=ar-EG&toDate=2026-10-15&branchesIds=1%2C2%2C3&branchesNames=`

### MVC (controller lines 291-299)
```csharp
[Route("mvc/FinancialReports/BriefGeneralBalance")]
public IActionResult BriefGeneralBalance(string lang, DateTime toDate,string branchesIds,string branchesNames)
{
    ChangeThreadCulture(lang);
    var report = new rptBreifGeneralBalance(toDate, branchesIds, branchesNames);
    return View(REPORTS_ROOT_VIEW, report);
}
```

### rpt: `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\General Balance\rptBreifGeneralBalance.cs`
- Ctor: `toDate = new DateTime(_DateTo.Year, _DateTo.Month, _DateTo.Day, 0, 0, 0)` (static), `BranchIdListCommaSeparated = branchIdList` (static), `SelectedBranchesName = selectedBranchesName`.
- Name for layout: `!IsArabic ? "rptBreifGeneralBalance" : "rptBreifGeneralBalanceAr"`; Arabic → `localizer1.ApplyArabic()`, RTL in BeforePrint.
- `rptBreifGeneralBalance_BeforePrint` (exact):
  ```csharp
  var searchDate = toDate.AddDays(1);
  acc_SystemConfigurationTableAdapter.Fill(dsBriefGeneralBalance1.Acc_SystemConfiguration);
  acc_GeneralBalanceTableAdapter.Fill(dsBriefGeneralBalance1.Acc_GeneralBalance,
       searchDate, BranchIdListCommaSeparated, null, null, null);   // @ToBalanceDate, @BranchIdList, @JournalRevise, @JournalTypeList, @CostCenterList
  BranchesParams.Text = SelectedBranchesName;
  if (string.IsNullOrEmpty(BranchIdListCommaSeparated)) BranchesParams.Text = IsArabic ? "الكل" : "All";
  int? approximate = ApiLoggedUser.GetApproximateNo();
  string format = $"{{0:n{ approximate.Value}}}";
  ```
  Then, with `T(n) = row(AccountTypeId = n).BalanceDebit − row(n).BalanceCredit` (via `FindByAccountTypeId`), and every value
  **written as formatted text and read back with `Convert.ToDecimal(cell.Text)`**:

  | Cell (layout column) | Formula (exact) |
  |---|---|
  | `clmLongTermAssets` (Subtotal+Total merged) | `format(T(6))` |
  | `clmCurrentAssets` (Subtotal) | `format(T(7))` |
  | `clmCurrentLiabilities` (Subtotal) | `format(T(8))` — normally **negative** (credit balance) |
  | `clmWorkingCapital` (merged) | `format(Math.Abs(ToDecimal(clmCurrentAssets.Text)) − Math.Abs(ToDecimal(clmCurrentLiabilities.Text)))` |
  | `clmInvestmentCapital1` "Invested Capital" (merged) | `format(Math.Round(ToDecimal(clmLongTermAssets.Text) + ToDecimal(clmWorkingCapital.Text), approximate ?? 0, MidpointRounding.AwayFromZero))` |
  | `clmEquity` "Total Owner's Equity" (merged) | `format(T(9) + T(12))` — Equity **plus Profit/Loss**, normally **negative** |
  | `clmLongTermLiabilities` "Long Term Loans" (merged) | `format(T(10))` — normally **negative** |
  | `clmInvestmentCapital2` "Capital Invested" (merged) | `format(Math.Round(ToDecimal(clmEquity.Text) + ToDecimal(clmLongTermLiabilities.Text), approximate ?? 0, MidpointRounding.AwayFromZero))` — normally **negative** |
  | `txtDateTo` | `string.Format("{0:dd/MM/yyyy}", toDate)` |

  `AccAccountTypeList` (`GeneralLedger.Reports\Helper\AccAccountTypeList.cs`): 6 Long_term_assets, 7 Current_Assets, 8 Current_Liabilities, 9 Equity_Owners_equity, 10 Long_term_liabilities, 12 Profit_Loss.

### ds: `...\General Balance\dsBriefGeneralBalance.xsd`
TableAdapters: `Acc_SystemConfiguration` and `Acc_GeneralBalance` (Fill). Params `@ToBalanceDate DateTime (not null), @BranchIdList String, @JournalRevise Boolean, @JournalTypeList String, @CostCenterList String` (all nullable except the date). Columns: `AccountTypeId` (table primary key → `FindByAccountTypeId`), `AccountTypeName`, `AccountTypeNameArabic`, `BalanceCredit`, `BalanceDebit`. Query (verbatim in Appendix A1): leaf-account CTE over the two BeforeDate TVFs with `@BranchIdList` on both, then
```sql
SELECT Acc_AccountType.AccountTypeId, Acc_AccountType.AccountTypeName, Acc_AccountType.AccountTypeNameArabic,
       ISNULL(SUM(AccountBalance.OpenningCredit), 0) AS BalanceCredit,
       ISNULL(SUM(AccountBalance.OpenningDebit), 0) AS BalanceDebit
FROM AccountBalance RIGHT OUTER JOIN dbo.Acc_Account ON ... RIGHT OUTER JOIN dbo.Acc_AccountType ON ...
WHERE Acc_AccountType.AccountTypeNature = 2
GROUP BY AccountTypeId, AccountTypeName, AccountTypeNameArabic
```
The `RIGHT JOIN Acc_AccountType` guarantees one row per nature-2 type (zero when unused), so `FindByAccountTypeId` never returns null on a seeded tenant.

### Layout (Designer `rptBreifGeneralBalance.Designer.cs`, A4 portrait 827×1169, margins 18)
- `ReportHeader`: company block. `PageHeader`: title "Brief Balance Sheet Report" / "تقرير الميزانية المختصر". `GroupHeader1`: "Balance Sheet On" / "الميزانية في " + `txtDateTo`, "Branches" / "الفروع" + `BranchesParams`.
- `Detail` (main DataMember `Acc_SystemConfiguration`, one row): **one fixed 9-row table**, no data binding; every number is set in code.
  | Row | Description (En / Ar) | Subtotal (w 0.5) | Total (w 0.5) |
  |---|---|---|---|
  | header | Description / التفاصيل | Subtotal / الاجمالي الفرعي | Total / الاجمالي |
  | 2 | Fixed Assets / الاصول الثابته | `clmLongTermAssets` spans both (w 1.0, centered) | |
  | 3 | Total Current Assets / الاصول المتداوله | `clmCurrentAssets` | (blank) |
  | 4 | Total Current Liabilities / الخصوم المتداوله | `clmCurrentLiabilities` | (blank) |
  | 5 | Working Capital / رأس المال العامل | `clmWorkingCapital` spans both | |
  | 6 | Invested Capital / رأس المال المستثمر | `clmInvestmentCapital1` spans both | |
  | 7 | Total Owner's Equity / اجمالي حقوق الملكيه | `clmEquity` spans both | |
  | 8 | Long Term Loans / قروض طويلة الأجل | `clmLongTermLiabilities` spans both | |
  | 9 | Capital Invested / رأس المال المستثمر | `clmInvestmentCapital2` spans both | |
- Arabic: rows 6 and 9 get the **same** Arabic caption "رأس المال المستثمر". No data-name rebinding (all captions are static).

### Cloud dependencies (report 1)
| Object | Cloud |
|---|---|
| `dbo.Acc_GetAccountBalanceBeforeDate(@FromBalanceDate, @CurrencyId, @BranchList)` | exists `Functions\Acc_GetAccountBalanceBeforeDate.sql` (sqlproj line 2212) |
| `dbo.Acc_GetAccountJournalActionsBeforeDate(@FromBalanceDate, @JournalRevise, @JournalTypeList, @CostCenterList, @AccountList, @CurrencyId, @BranchList)` | exists `Functions\Acc_GetAccountJournalActionsBeforeDate.sql` (line 2217) |
| `dbo.Acc_ConvertIntListToTable` (inside both) | exists `Functions\Acc_ConvertIntListToTable.sql` |
| `Acc_Account` (`ParentAccountId`, `AccountTypeId`), `Acc_AccountType` (`AccountTypeNature`), `Acc_SystemConfiguration`; inside the TVFs `Acc_AccountBalance`, `Acc_AccountingSubPeriod`, `Acc_JournalAction`, `Acc_Journal` | all exist under `Tables\` |

---

## 2. Comparative Balance Sheet (`financial-reports/compare-balance-sheet`)

### Angular
- Route: module line 181, `OneDateShellComponent`, `data: { ModuleId: 75 }`. Menu `6_2_4`, `params: { report: 'CompareBalanceSheet' }` → branch list hidden, label `COMMON._BalanceSheetIn_`.
- iframe URL: `{printUrl}FinancialReports/CompareBalanceSheet?lang=ar-EG&toDate=2026-10-15&branchesIds=&branchesNames=` (the two branch keys are sent empty and ignored).

### MVC (controller lines 313-321)
```csharp
[Route("mvc/FinancialReports/CompareBalanceSheet")]
public IActionResult CompareBalanceSheet(string lang, DateTime toDate)
{
    ChangeThreadCulture(lang);
    var report = new rptCompareBalanceSheet(toDate);
    return View(REPORTS_ROOT_VIEW, report);
}
```
**No branch filter at all**: every query passes `NULL` for branches.

### rpt: `...\BalanceSheetStatment\rptCompareBalanceSheet.cs`
- Ctor: `balnceDate = _balnceDate.Date.AddDays(1);` `approximate = ApiLoggedUser.GetApproximateNo()`. Name `rptCompareBalanceSheet` / `rptCompareBalanceSheetAr`.
- `rptCompareBalanceSheet_BeforePrint`:
  - Fills the 10 tables **twice** (the block is copy-pasted). `ClearBeforeFill` is the default `true`, so there are no duplicate rows. The cost is doubled.
    - `Compare{LongTermAssets,CurrentAssets,CurrentLiabilities,OwnersEquity,LongTermLiabilities}Items.Fill(balnceDate)`
    - `…ItemsBeforeDate.FillByBeforeDate(balnceDate)`: the SQL itself does `DATEADD(year, -1, @BalanceDate)`.
  - Prior-year value per detail row (exact, for each of the 5 categories):
    ```csharp
    row.BalanceBeforeDate = Convert.ToDecimal(<cat>ItemsBeforeDate.FirstOrDefault(x => x.SubItemName == row.SubItemName)?.Balance);
    ```
    The match is by **SubItemName** only (first hit). `Convert.ToDecimal(null)` = 0. Sub-items that exist only in the prior year get **no detail line**, but they **are** in the prior-year category total.
  - Totals (exact): `X = Σ Balance` over each current table; `XBeforeDate = Σ Balance` over each BeforeDate table. `format = "N" + approximate`.
    | Cell | Current | Prior year |
    |---|---|---|
    | `txtLongTermAssetsTotal` | `LTA` | `LTA_b` |
    | `txtCurrentAssets` | `CA` | `CA_b` |
    | `txtSummaryAssets` | `CA + LTA` | same with `_b` |
    | `txtCurrentLiabilities` | `CL` | `CL_b` |
    | `txtNetWorkingCapital` | `CA + CL` | … |
    | `txtContributedCapital` | `LTA + CA + CL` | … |
    | `txtEquity` | `EQ` | … |
    | `txtLongLiabilities` | `LTL` | … |
    | `txtSummeryOfLiabilities` | `CL + EQ + LTL` | … |
    All balances are **Debit − Credit**, so liabilities and equity print negative. There is **no ABS** anywhere; WC = CA + CL works only because CL is negative.
  - Captions: `txtBalanceDate.Text = txtBalanceDate1.Text = "{0:dd/MM/yyyy}"` of `balnceDate.AddSeconds(-1).Date` (= toDate); `txtBalanceBeforeDate.Text = "{0:dd/MM/yyyy}"` of `balnceDate.AddDays(-1).AddYears(-1).Date` (= toDate − 1 year).
  - Formulas are **identical to `rptBalanceSheet`** (lines 100-116 of `rptBalanceSheet.cs`), so they are identical to fx123513's TVF summary rows.

### ds: `...\BalanceSheetStatment\dsCompareBalanceSheet.xsd`
10 TableAdapters (+ `Acc_SystemConfiguration`), each with one param `@BalanceDate DateTime (not null)`. Columns: `SubItemName, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit, Balance, MainItemId, MainItemName` (+ C#-side `BalanceBeforeDate` on the 5 current tables).
**Script-verified (whitespace-normalized):** all 10 are byte-identical except `WHERE (Acc_BalanceSheetSubItems.MainItemId = N)` (1..5) and, in the 5 `*BeforeDate` tables, `@BalanceDate` → `DATEADD(year, -1, @BalanceDate)` in both TVF calls. The query is also identical to `dsBalanceSheet.xsd` `LongTermAssetsItems` (the fx123513 source) **except** that `@BranchIdList` is replaced by `NULL` in both TVF calls. Shape (A2 verbatim):
```sql
SELECT Acc_BalanceSheetSubItems.SubItemName, …,
       (ISNULL(SUM(OpenningDebit),0) + ISNULL(SUM(PeriodDebit),0)) - (ISNULL(SUM(OpenningCredit),0) + ISNULL(SUM(PeriodCredit),0)) AS Balance,
       Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName
FROM AccountBalance INNER JOIN Acc_Account ON … INNER JOIN Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = BalanceSheetSubItemId
     INNER JOIN Acc_BalanceSheetMainItems ON …
WHERE (Acc_BalanceSheetSubItems.MainItemId = N)
GROUP BY SubItemName, MainItemId, MainItemName, OrderInReport
ORDER BY OrderInReport
```

### Layout (Designer `rptCompareBalanceSheet.Designer.cs`)
- Bands: `ReportHeader` (company); `PageHeader`: "Compare Balance Sheet Report" / "تقرير مقارنة الميزانيه", "In :" / "في" + `txtBalanceDate`; root `Detail` (one row): the column header `Description | <toDate dd/MM/yyyy> | <toDate−1y dd/MM/yyyy>` (Designer placeholders "Partial Balance"/"Total" are overwritten).
- Then 5 `DetailReportBand`s in Level order, each `Detail` row = `"-"` | `SubItemName` | `Balance` | `BalanceBeforeDate` (both money cells re-formatted `n<approx>` by moneyApproximate):
  | Level | DataMember | GroupHeader (caption, current, prior) | GroupFooter(s) |
  |---|---|---|---|
  | 0 | `CompareLongTermAssetsItems` | "Long-term assets" / "الاصول طويلة الاجل", `txtLongTermAssetsTotal`, `…BeforeDate` | — |
  | 1 | `CompareCurrentAssetsItems` | "Current Assets" / "الاصول المتداولة" | `GroupFooter1` "Summary Assets" / "اجمالي الاصول" |
  | 2 | `CompareCurrentLiabilitiesItems` | "Current Liabilities" / "الخصوم المتداولة" | `GroupFooter3` "Net Working Capital" / "صافي رأس المال العامل"; `GroupFooter4` (Level 1) "Contributed Capital" / "رأس المال المستثمر" (row has an extra blank leading cell) |
  | 3 | `CompareOwnersEquityItems` | "Equity (Owners' equity)" / "حقوق الملكية" | — |
  | 4 | `CompareLongTermLiabilitiesItems` | "Long-Term Liabilities" / "الخصوم طويلة الاجل" | `GroupFooter2` "Summery Of  Liabilities" (sic) / "اجمالي الخصوم" |
- **`ReportPrintOptions.PrintOnEmptyDataSource` is not set** on any of the five (in `rptBalanceSheet` it is explicitly `false`). An empty category may therefore still print its header and footer rows (with `0.00` totals), unlike the plain balance sheet. Verify on a live print (open question 3).
- Arabic: RTL plus localizer only. Sub-item names are single-language (`SubItemName`), and so is `MainItemName`, which the layout does not print.

### Cloud dependencies (report 2)
Same functions and tables as report 1, plus `Acc_BalanceSheetSubItems` (`Tables\Acc_BalanceSheetSubItems.sql`, sqlproj line 536) and `Acc_BalanceSheetMainItems` (`Tables\Acc_BalanceSheetMainItems.sql`, line 535), plus `Acc_Account.GeneralBalance` (FK to sub-items). All exist. `dbo.Acc_BalanceSheetReport` (the fx123513 TVF) is **MISSING** in the `cr125291` base: it exists only on `origin/fx123513`.

---

## 3. Statement of Financial Position (`financial-reports/financial-position-statement`)

### Angular
- Route: module line 187, `OneDateShellComponent`, `data: { ModuleId: 75 }`. Menu `6_2_5`, `params: { report: 'FinancialPositionStatement' }` → `isFinPositionLabel`, label `COMMON._FinPositionLabel_`, branch list shown.
- iframe URL: `{printUrl}FinancialReports/FinancialPositionStatement?lang=ar-EG&toDate=2026-10-15&branchesIds=1%2C2%2C3&branchesNames=`

### MVC (controller lines 324-332)
```csharp
[Route("mvc/FinancialReports/FinancialPositionStatement")]
public IActionResult FinancialPositionStatement(string lang, DateTime toDate, string branchesIds, string branchesNames)
{
    ChangeThreadCulture(lang);
    var report = new rptFinancialPositionStatement(toDate, branchesIds, branchesNames);
    return View(REPORTS_ROOT_VIEW, report);
}
```

### rpt: `...\FinancialPositionStatement\rptFinancialPositionStatement.cs`
- Ctor: `_toDate = new DateTime(y, m, d, 23, 59, 59, 997)`; `txtDateTo.Text = _toDate.Date.ToShortDateString()` (**culture-dependent**: ar-EG `dd/MM/yyyy`, en-US `M/d/yyyy`). Name `rptFinancialPositionStatement` / `…Ar`.
- `rptFinancialPositionStatement_BeforePrint`:
  - `_searchDate = _toDate.Date.AddDays(1)`.
  - Arabic only: RTL, and the five category-level header cells are rebound from `<table>.MainItemNameEnglish` to `<table>.MainItemNameArabic` (`xrTableCell34` LTA, `xrTableCell36` CA, `xrTableCell4` CL, `xrTableCell43` Equity, `xrTableCell47` LTL). The data members contain a **non-breaking space** (`Financial_Current Assets\u00A0`, `Financial_Current Liabilities\u00A0`), and code, Designer and xsd all use it consistently, so the rebinding works.
  - `branchNames.Text = SelectedBranchesName`; empty `BranchIdList` → `"الكل"` / `"All"`.
  - Fills 11 tables with `(_searchDate, BranchIdList)`: 5 summary tables + **5 `*Accounts` tables, which nothing in the layout binds to** (dead queries) + system configuration.
  - Totals (exact):
    ```csharp
    _totalLongTermAssets        = Σ Financial_Long-term assets.Net              // Σ(D−C)
    _totalCurrentAssets         = Σ Financial_Current Assets .DepreciationTot   // Σ(D−C)
    _totalCurrentLiabilities    = Σ Financial_Current Liabilities .DepreciationTot // Σ(C−D)  ← sign flipped in SQL
    _totalEquity                = Σ Financial_Equity.DepreciationTot            // Σ(D−C)
    _totalLong_term_liabilities = Σ Financial_Long-term liabilities.DepreciationTot // Σ(D−C)
    _TotICapital  = _totalCurrentAssets - _totalCurrentLiabilities;   txtTotICapital       "Capital" / "رأس المال"
    _TotInvestment = _totalLongTermAssets + _TotICapital;             txtTotIInvestment    "Total Investment" / "اجمالي الاستثمار"
    txtInvestmentfinancing = _totalEquity + _totalLong_term_liabilities;  "Investment Financing" / "الاستثمار المالي"
    format = "N" + approximate
    ```
    Investment Financing is (D−C), so it normally prints **negative**, the mirror of Total Investment.

### ds: `...\FinancialPositionStatement\dsFinancialPositionStatement.xsd`
All data adapters take `@BalanceDate DateTime (not null), @BranchIdList String (nullable)`; branch goes to both TVFs. CTE = shared block plus `GeneralBalance` (and `AccountName` in the `*Accounts` variants), grouped by `AccountId, ParentAccountId, GeneralBalance[, AccountName]`. Outer selects (verbatim in A3):

| TableAdapter | MainItemId | Cost | DepreciationTot | Net | Group by |
|---|---|---|---|---|---|
| `Financial_Long-term assets` | 1 | `SUM(D)` | `SUM(C)` | `SUM(D) − SUM(C)` | SubItemName, MainItemNameArabic, OrderInReport, GeneralBalance, MainItemId, SubParentItemName, MainItemNameEnglish |
| `Financial_Current Assets\u00A0` | 2 | `0` | `SUM(D) − SUM(C)` | — | GeneralBalance, SubItemName, OrderInReport, SubParentItemName, MainItemNameEnglish, MainItemNameArabic, MainItemId |
| `Financial_Current Liabilities\u00A0` | 3 | `0` | **`SUM(C) − SUM(D)`** | — | same |
| `Financial_Equity` | 4 | `0` | `SUM(D) − SUM(C)` | — | same |
| `Financial_Long-term liabilities` | 5 | `0` | `SUM(D) − SUM(C)` | — | same |
| `…Accounts` ×5 (unused) | 1..5 | LTA/CA: `D`; others `0` | LTA/CA: `C`; CL/Eq/LTL: **`C` only** | LTA/CA: `D−C` | per account, `ORDER BY OrderInReport` |

All summary queries return `MainItemNameArabic, MainItemNameEnglish, MainItemId, OrderInReport, GeneralBalance, SubItemName, SubParentItemName`, `ORDER BY OrderInReport`. The LTA query joins `Acc_BalanceSheetSubItems INNER JOIN AccountBalance` (and keeps a commented-out `Acc_AssetType` join); the others join `AccountBalance INNER JOIN Acc_BalanceSheetSubItems`. The result is the same. The grain is one row per **sub-item** (`GeneralBalance` = `BalanceSheetSubItemId`).

### Layout (Designer `rptFinancialPositionStatement.Designer.cs`)
- Main `DataMember = Financial_Acc_SystemConfiguration`; root `Detail` invisible.
- `PageHeader`: "Financial Position Statement Report" / "المركز المالى الإجمالى ", "To Date" / "الي تاريخ" + `txtDateTo`, "Branches" / "الفروع" + `branchNames`, empty `lblRevised` / `lblCostCenter`, and the column header **Balance Type | Cost | Depreciation | Net** (weights 0.405 / 0.212 / 0.227 / 0.314). Arabic: "نوع الحساب | التكلفة | **التفاصيل** | الصافي". The Arabic caption for *Depreciation* reads "Details" (a language-only bug).
- Detail row in every category: `"-"` + `SubItemName` (together the Balance Type column) | `Cost` | `DepreciationTot` | 4th column. In LTA the 4th column is `Net`. In CA, CL, Equity and LTL the 4th column is **`DepreciationTot` again**, so their Depreciation and Net columns show the same number and Cost shows `0.00`.
- Group header rows = label spanning the first three columns (0.844) + `SUM` in the Net column (`SummaryRunning.Group`, Func default Sum, re-formatted `n<approx>`). The static captions ("Operating Income", "Operation Expenses", "Administrative / General Expenses") are placeholders overwritten by the binding.
  | Level | DetailReport (DataMember) | outer header (Level 1) | inner header (Level 0) | Detail sort | PrintOnEmpty |
  |---|---|---|---|---|---|
  | 0 | `DetailReport` (LTA) | `GroupHeader7`: MainItemNameEnglish (Ar: Arabic), group field `MainItemNameEnglish`, SUM(Net) | `GroupHeader1`: SubParentItemName, group field `SubParentItemName`, SUM(Net) | `OrderInReport` | false |
  | 1 | `DetailReport6` (CA) | `GroupHeader8`: MainItemName, SUM(DepreciationTot) | `GroupHeader6`: SubParentItemName, SUM(DepreciationTot) | `OrderInReport` | false |
  | 2 | `DetailReport3` (CL) | `GroupHeader9`: MainItemName, SUM | `GroupHeader3`: SubParentItemName, SUM | `OrderInReport` | false |
  | 3 | `DetailReport1` (no DataMember, `Detail2` invisible) | — | `GroupHeader2`: "Capital" `txtTotICapital`, "Total Investment" `txtTotIInvestment` | — | default |
  | 4 | `DetailReport2` (Equity) | `GroupHeader13`: **SubParentItemName, no group field** | `GroupHeader12`: **MainItemName**, group field `Financial_Equity.MainItemNameEnglish` | none | default (true) |
  | 5 | `DetailReport5` (LTL) | `GroupHeader5`: MainItemName, **no group field** | `GroupHeader4`: SubParentItemName, **no group field** | none | default (true) |
  | root | `GroupFooter1` | "Investment Financing" / "الاستثمار المالي" `txtInvestmentfinancing` | | | |
- Consequences:
  - For LTA, CA and CL the rows are regrouped by **SubParentItemName ascending** (DevExpress sorts by group fields) and then by `OrderInReport`, which differs from the SQL `ORDER BY OrderInReport`.
  - For Equity the nesting is inverted, and the outer SubParentItemName header prints **once**, with the first row's SubParentItemName and the category total.
  - For LTL both headers print once with the category total, and the SubParentItemName shown is the first row's.

### Cloud dependencies (report 3)
Same as report 2 (both BeforeDate TVFs, `Acc_ConvertIntListToTable`, `Acc_Account.GeneralBalance/AccountName`, `Acc_BalanceSheetSubItems` incl. `SubParentItemName`/`OrderInReport`, `Acc_BalanceSheetMainItems` incl. `MainItemNameArabic`/`MainItemNameEnglish`, `Acc_SystemConfiguration`). All exist; nothing MISSING except the not-yet-merged `Acc_BalanceSheetReport` if it is reused.

---

## 4. Reuse from fx123513 (plain Balance Sheet; on `origin/fx123513` only, not in `Master_Stable` / `cr125291`)

| Repo | Files (from `git show origin/fx123513 --stat`) |
|---|---|
| DB | `dbo\Functions\Acc_BalanceSheetReport.sql` (134 lines), `Scripts\ReferenceDataScripts\0408_BalanceSheetReportLayout.sql` (InsertLayout, ReportName `BalanceSheet`, ApplicationId 1, Ar RTL master + En mirror), `.sqlproj` +2 |
| ERP | `AnalyticsReader.Api\AngularReports\GeneralLedger\BasicReports\BalanceSheetReports\BalanceSheetReport.cs` (`IAngularReport`, `ReportName => "BalanceSheet"`, reads `toDate` + `branchesIds`, `''` → null, `branchFilter` via `_context.GetBranchesName`, `FromSqlInterpolated(... Acc_BalanceSheetReport({balanceDate},{branches},{isArabic}) ORDER BY SortOrder)`, params `branchFilter`, `toDate` (`dd/MM/yyyy`) + empty CompanyInfo keys); `ODataViews\GL\BalanceSheetReports\BalanceSheetReport.cs` (RowNo, SortOrder, RowType, MainItemId, Description, PartialBalance, TotalBalance; EntitySet `BalanceSheetReport`); `ODataViewsConfigurations\GL\BalanceSheetConfigurations\BalanceSheetReportConfigurations.cs` (`HasNoKey`); `Models\DataContext.cs` +DbSet |
| Front | new `balance-sheet-print-report\balance-sheet-print-report-shell` (reuses `app-one-date-form` with `[hideActions]="true"`, `report-grid [ApplicationId]="1" [ReportName]/[endpoint]="'BalanceSheet'" keyGrid="RowNo" [printOnlyMode]="true"`, query options `toDate` `yyyy-MM-dd` + `branchesIds` CSV rebuilt on `FilterForm.valueChanges`); module: `balance-sheet` → new shell, old OneDateShell kept as `balance-sheet-legacy`; **one-line `one-date-form` change**: `@Input() hideActions = false;` + `*ngIf="!hideActions"` on the Print button div (merge-overlap point); i18n `ODATAREPORTS.BalanceSheet`, `ODATAREPORTS.PartialBalance` (ar/en `shared.json`) |

TVF `Acc_BalanceSheetReport(@BalanceDate, @BranchList, @IsArabic)`:
- `AccountBalance` CTE = the shared block, with `DATEADD(DAY, 1, CAST(CAST(@BalanceDate AS DATE) AS DATETIME))` and `NULLIF(@BranchList, N'')`.
- `SubItemRows`: GeneralBalance → sub-item → main item 1..5, `Balance = D − C`, grouped `MainItemId, SubItemName, OrderInReport`.
- `CategoryTotals` → `Pivoted` (LTA, CA, CL, OE, LTL + `HasCurrentAssets`/`HasCurrentLiabilities`).
- RowType rows:
  - `CategoryHeader` (`MainItemId*1000`, TotalBalance), with hard-coded Ar/En category names
  - `SubItem` (`*1000+10+seq`, PartialBalance)
  - `SummaryAssets` 2900 = CA+LTA, emitted only if CA exists
  - `NetWorkingCapital` 3900 = CA+CL, emitted if CL exists
  - `ContributedCapital` 3910 = LTA+CA+CL, emitted if CL exists
  - `SummaryLiabilities` 9000 = CL+OE+LTL, always emitted
- Columns `RowNo, SortOrder, RowType, MainItemId, Description, PartialBalance, TotalBalance` (`DECIMAL(19,4)`).

How much each report can take:
- **Compare: almost everything.** The current-year column is exactly `Acc_BalanceSheetReport(@toDate, NULL)` (same CTE, same grouping, same 4 summary formulas). Needed changes:
  - a **second value column** (prior year) from the same CTE at `DATEADD(year,-1, toDate+1day)`. This is **not** `Acc_BalanceSheetReport(DATEADD(year,-1,@toDate))`, because that adds the day *after* subtracting the year and differs around 29 Feb (see Quirk C3).
  - a **join by SubItemName** to reproduce the legacy matching (prior-only sub-items dropped from lines but kept in totals).
  - **branch forced to NULL**.
  - the emptiness rules: Compare does not set PrintOnEmptyDataSource=false, so its headers and footers may print for empty categories, whereas fx123513 suppresses them (open question 3).
  - two-column header captions (`toDate`, `toDate−1y`) as report parameters.

  Best shape: either generalize `Acc_BalanceSheetReport` with an `@IncludePriorYear`/`@CompareDate` param, or write a sibling `Acc_CompareBalanceSheetReport` that reuses the CTE text twice.
- **FPS: the CTE and branch handling only.** Same CTE (plus `GeneralBalance`) and the same sub-item grain, but different columns (Cost / Depreciation / Net), different per-category sign conventions (CL flipped), two-level grouping by `MainItemName` → `SubParentItemName` (absent in fx123513), different totals (Capital, Total Investment, Investment Financing), and Ar/En main-item names from the table (`MainItemNameArabic/English`) instead of hard-coded strings. It needs its own TVF that reuses the CTE.
- **Brief: the CTE and the backend/front plumbing only.** It classifies by **AccountTypeId** (6, 7, 8, 9+12, 10), not by GeneralBalance, so it is not the same base query, and its totals can differ from the full balance sheet on the same date (accounts not mapped to a sub-item are included here, and P/L type 12 is folded into equity). It is a fixed 8-line statement with ABS and intermediate rounding. It needs its own small TVF (8 RowType rows, Subtotal/Total columns).
- **Common to all three**: the IAngularReport class pattern (`toDate`, `branchesIds`, `''`→null, `GetBranchesName` for `branchFilter`, `toDate` caption, CompanyInfo keys), the print-only shell that reuses `app-one-date-form` + `hideActions` (Compare passes `[isHavingFilterByBranches]="false"`, FPS `[isFinPositionLabel]="true"`), ModuleId 75 on each route, the InsertLayout seed pattern (Ar master + En mirror), and the `-legacy` route trick.
- **Merge risk**: fx123513 edits the same `one-date-form` files and `financial-reports.module.ts` region (lines 168-191) that this CR must touch. Whichever lands second must keep both edits. Do not cherry-pick fx123513's `balance-sheet` route change into this CR.

---

## 5. Quirks a faithful port must reproduce (or consciously drop)

**Brief (B)**
- B1. **Intermediate rounding through text.** CA, CL, LTA, Equity and LTL are formatted `n<approx>` and then **parsed back** (`Convert.ToDecimal(cell.Text)`) before WC / Invested Capital / Capital Invested are computed. So these totals are sums of already-rounded figures, and IC1/IC2 get a further `Math.Round(…, approx, AwayFromZero)`. SQL equivalent: `ROUND(x, @approx)` on each component first (SQL `ROUND` and .NET decimal `n` formatting both round half away from zero).
- B2. **Working Capital = |CA| − |CL|** (ABS on the rounded values), while CA and CL themselves print signed (CL normally negative).
- B3. **Invested Capital (row 6) = LTA + WC** (positive); **Capital Invested (row 9) = (Equity+P/L) + LTL** (normally **negative**, since D−C). The two "balancing" figures differ in sign.
- B4. Equity row = type 9 **plus type 12 Profit/Loss**. Current-year results still sitting in income-statement accounts (nature 1) are **not** included anywhere. The statement balances only after closing.
- B5. CA and CL sit in the *Subtotal* column; every other value spans Subtotal+Total.
- B6. Branch caption: `branchesNames` is `''` on first load (ids are pre-filled with all of the user's branches but names are not), so the caption prints **blank** unless the user touched the tree. "None selected" → `''` → null → caption "All" and **all** branches, including ones the user is not assigned to. The port should decide whether to compute names server-side as fx123513 does (`GetBranchesName`), which is a deliberate improvement.

**Compare (C)**
- C1. **No branch filter** (UI hides it, MVC ignores it, SQL passes NULL).
- C2. Prior-year lines are matched by **SubItemName** (`FirstOrDefault`). Prior-only sub-items are missing from lines but included in prior totals, so the prior column does not foot. Duplicate names within one category take the first match.
- C3. Prior-year date = `DATEADD(year, -1, toDate + 1 day)` (exclusive). For `toDate = 2024-02-28` the data cut-off is `< 2023-02-28`, while the header prints `28/02/2023`, so the prior column actually stops at 27/02/2023. Reproduce the exact expression.
- C4. All values D−C, no ABS; liabilities/equity totals negative; formulas identical to rptBalanceSheet.
- C5. Column headers are dates (`dd/MM/yyyy`), not "Partial/Total"; title row "In : <toDate>".
- C6. Fills run twice (performance only).

**Financial Position (F)**
- F1. **Per-category signs**: LTA Net = D−C, CA = D−C, **CL = C−D**, Equity = D−C, LTL = D−C. So Equity and LTL lines, their header sums and **Investment Financing print negative**, while CL prints positive.
- F2. Capital = CA − CL (with CL already C−D, i.e. normal working capital); Total Investment = LTA + Capital; Investment Financing = Equity + LTL.
- F3. For CA/CL/Equity/LTL the **Depreciation and Net columns repeat the same value** and **Cost is 0.00**; only LTA shows Cost = ΣDebit, Depreciation = ΣCredit, Net = D−C.
- F4. Row order inside LTA/CA/CL is SubParentItemName ASC (group sort), then OrderInReport. Equity and LTL keep SQL order. Rows with NULL SubParentItemName form one blank-titled group, which sorts first.
- F5. Equity: outer header = SubParentItemName of the **first** row (no group field) with the category total, and the inner header = main item name. LTL: both headers print once with the category total. The sub-parent subtotals the other categories show do **not** exist for Equity/LTL.
- F6. Equity and LTL keep `PrintOnEmptyDataSource` default (true) while LTA/CA/CL are false. An empty Equity/LTL may still print its header rows with blank/0.
- F7. `txtDateTo` uses `ToShortDateString()`, so the format differs by language (ar-EG `dd/MM/yyyy`, en-US `M/d/yyyy`).
- F8. Same blank-branch-caption behaviour as B6.
- F9. The 5 `*Accounts` queries are executed but never printed; drop them (no visible effect).

**All three**
- Q1. Balance "as of end of toDate" via `toDate.Date + 1` and `<` in the TVFs. Opening = the `Acc_AccountBalance` row of the latest sub-period with `SubPeriodStart <= date` (or the first non-transferred one), plus journals from that sub-period start. This comes for free by calling the same TVFs.
- Q2. Money formatting = tenant `ApproximateNo` decimals everywhere (Designer `{0:n2}` is overridden).
- Q3. Static fields make concurrent legacy prints unreliable. Use single-user prints for the SQL diff.

---

## 6. Open questions

1. **Brief: reproduce or fix?** The brief mixes signs: positive Invested Capital, negative Capital Invested, and |CA|−|CL| next to signed CA/CL. It also rounds intermediate values. The sibling-CR decision D2 says "exact numbers, English variant as reference", which implies reproducing it. Confirm that this covers the visible sign oddities (B2/B3) too.
2. **Compare prior-year matching (C2) and date edge (C3).** Reproduce the SubItemName match (prior-only items invisible but counted) or emit a full outer join of sub-items? The latter changes the visible lines but not the totals.
3. **Empty categories.** Compare (all five) and FPS (Equity/LTL) leave `PrintOnEmptyDataSource` at its default. Check a live MVC print on a tenant with an empty category before deciding whether the TVF must emit header/summary rows for empty categories. fx123513 suppresses them for the plain balance sheet.
4. **FPS sign of Investment Financing / Equity / LTL (F1)**: reproduce the negatives (fidelity) or align with Total Investment? Business call.
5. **FPS grouping (F4/F5)**: reproduce the DevExpress regrouping (SubParentItemName ASC, Equity inversion, LTL single headers) in SQL RowType rows, or render a uniform MainItem → SubParent → SubItem tree? Under D1 (full grid, not printOnlyMode) the grid will show flat rows anyway. Decide what the print layout mirrors.
6. **Branch caption (B6/F8)**: legacy prints blank on first load. Should the port print the computed branch names (fx123513 behaviour)? That is a visible but harmless deviation.
7. **Compare and branches**: keep the branch filter hidden and NULL (fidelity), or offer it (the same TVF supports it)?
8. **One shell or three?** fx123513 made a dedicated print shell per report. For the three remaining OneDateShell routes, decide between three thin shells and one parameterized shell keyed on `report`. In either case keep `ModuleId: 75`, and fix the always-"Brief" title.
9. **fx123513 ordering**: if fx123513 merges to `Master_Stable` before this CR, rebase-free reuse of `Acc_BalanceSheetReport` (extend it for Compare) becomes possible. If it does not, this CR must carry its own TVFs and must not depend on that function.
10. **Arabic Depreciation caption "التفاصيل"** (FPS) and the duplicate "رأس المال المستثمر" (brief rows 6 and 9) are layout bugs. Fix them in the new `.repx` (improvement), or keep them?

---

## Appendix: TableAdapter queries, verbatim

Generated from the `.xsd` files with a script (`DbCommand/CommandText` of each `MainSource/SelectCommand`), unmodified.
`Acc_SystemConfiguration` adapters are omitted after the first (always `SELECT Acc_SystemConfiguration.* FROM  Acc_SystemConfiguration`).
`[NBSP]` in an adapter name marks the U+00A0 character that is really in the name (see report 3).

### A1. Brief: `General Balance/dsBriefGeneralBalance.xsd`

**Acc_GeneralBalance**: `Fill`; params: @ToBalanceDate DateTime, @BranchIdList String (nullable), @JournalRevise Boolean (nullable), @JournalTypeList String (nullable), @CostCenterList String (nullable)

```sql
WITH AccountBalance (AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit)
AS (SELECT Acc_Account.AccountId,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@ToBalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(
                                                               @ToBalanceDate,
                                                               @JournalRevise,
                                                               @JournalTypeList,
                                                               @CostCenterList,
                                                               NULL,
                                                               NULL,
                                                               @BranchIdList
                                                           ) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE Acc_Account.AccountId NOT IN
          (
              SELECT ParentAccountId
              FROM dbo.Acc_Account
              WHERE ParentAccountId IS NOT NULL
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId)
SELECT Acc_AccountType.AccountTypeId,
       Acc_AccountType.AccountTypeName,
       Acc_AccountType.AccountTypeNameArabic,
       ISNULL(SUM(AccountBalance.OpenningCredit), 0) AS BalanceCredit,
       ISNULL(SUM(AccountBalance.OpenningDebit), 0) AS BalanceDebit
FROM AccountBalance
    RIGHT OUTER JOIN dbo.Acc_Account
        ON AccountBalance.AccountId = dbo.Acc_Account.AccountId
    RIGHT OUTER JOIN dbo.Acc_AccountType
        ON dbo.Acc_Account.AccountTypeId = dbo.Acc_AccountType.AccountTypeId
WHERE Acc_AccountType.AccountTypeNature = 2
GROUP BY Acc_AccountType.AccountTypeId,
         Acc_AccountType.AccountTypeName,
         Acc_AccountType.AccountTypeNameArabic
ORDER BY Acc_AccountType.AccountTypeId,
         Acc_AccountType.AccountTypeName,
         Acc_AccountType.AccountTypeNameArabic;
```

**Acc_SystemConfiguration**: `Fill`; params: none

```sql
SELECT Acc_SystemConfiguration.*
FROM  Acc_SystemConfiguration
```

### A2. Compare: `BalanceSheetStatment/dsCompareBalanceSheet.xsd`

**CompareLongTermAssetsItems**: `Fill`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 1)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareCurrentAssetsItems**: `Fill`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 2)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareCurrentLiabilitiesItems**: `Fill`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 3)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareOwnersEquityItems**: `Fill`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 4)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareLongTermLiabilitiesItems**: `Fill`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 5)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareLongTermAssetsItemsBeforeDate**: `FillByBeforeDate`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 1)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareCurrentAssetsItemsBeforeDate**: `FillByBeforeDate`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 2)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareCurrentLiabilitiesItemsBeforeDate**: `FillByBeforeDate`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 3)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareOwnersEquityItemsBeforeDate**: `FillByBeforeDate`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                           (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 4)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

**CompareLongTermLiabilitiesItemsBeforeDate**: `FillByBeforeDate`; params: @BalanceDate DateTime

```sql
WITH AccountBalance(AccountId, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit, PeriodDebit) AS (SELECT Acc_Account.AccountId, Acc_Account.ParentAccountId, ISNULL(SUM(Balance.Credit), 0) AS Credit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.Debit), 0) AS Debit, ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit, 
                                                                                                                                                                                                                                                       ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
                                                                                                                                                                                                                                     FROM      Acc_Account LEFT OUTER JOIN
                                                                                                                                                                                                                                                           (SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM      dbo.Acc_GetAccountBalanceBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL) 
                                                                                                                                                                                                                                                                              AS Acc_GetAccountBalanceBeforeDate_1
                                                                                                                                                                                                                                                            UNION ALL
                                                                                                                                                                                                                                                            SELECT AccountId, Credit, Debit, PeriodCredit, PeriodDebit
                                                                                                                                                                                                                                                            FROM     dbo.Acc_GetAccountJournalActionsBeforeDate(DATEADD(year, -1, @BalanceDate), NULL, NULL, NULL, NULL, NULL, NULL)
                                                                                                                                                                                                                                                                               AS Acc_GetAccountJournalActionsBeforeDate_1) AS Balance ON 
                                                                                                                                                                                                                                                       Acc_Account.AccountId = Balance.AccountId
                                                                                                                                                                                                                                     WHERE   (Acc_Account.AccountId NOT IN
                                                                                                                                                                                                                                                         (SELECT ParentAccountId
                                                                                                                                                                                                                                                            FROM      Acc_Account AS Acc_Account_2
                                                                                                                                                                                                                                                            WHERE   (ParentAccountId IS NOT NULL)))
                                                                                                                                                                                                                                     GROUP BY Acc_Account.AccountId, Acc_Account.ParentAccountId)
    SELECT Acc_BalanceSheetSubItems.SubItemName, ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) AS OpenningCredit, ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) AS OpenningDebit, 
                      ISNULL(SUM(AccountBalance_1.PeriodCredit), 0) AS PeriodCredit, ISNULL(SUM(AccountBalance_1.PeriodDebit), 0) AS PeriodDebit, (ISNULL(SUM(AccountBalance_1.OpenningDebit), 0) 
                      + ISNULL(SUM(AccountBalance_1.PeriodDebit), 0)) - (ISNULL(SUM(AccountBalance_1.OpenningCredit), 0) + ISNULL(SUM(AccountBalance_1.PeriodCredit), 0)) AS Balance, Acc_BalanceSheetSubItems.MainItemId, 
                      Acc_BalanceSheetMainItems.MainItemName
    FROM     AccountBalance AS AccountBalance_1 INNER JOIN
                      Acc_Account AS Acc_Account_1 ON AccountBalance_1.AccountId = Acc_Account_1.AccountId INNER JOIN
                      Acc_BalanceSheetSubItems ON Acc_Account_1.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId INNER JOIN
                      Acc_BalanceSheetMainItems ON Acc_BalanceSheetSubItems.MainItemId = Acc_BalanceSheetMainItems.MainItemId
    WHERE  (Acc_BalanceSheetSubItems.MainItemId = 5)
    GROUP BY Acc_BalanceSheetSubItems.SubItemName, Acc_BalanceSheetSubItems.MainItemId, Acc_BalanceSheetMainItems.MainItemName, Acc_BalanceSheetSubItems.OrderInReport
    ORDER BY Acc_BalanceSheetSubItems.OrderInReport
```

### A3. Financial Position: `FinancialPositionStatement/dsFinancialPositionStatement.xsd`

**Financial_Long-term assets**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance)
SELECT dbo.Acc_BalanceSheetMainItems.MainItemNameArabic,
       dbo.Acc_BalanceSheetMainItems.MainItemNameEnglish,
       Acc_BalanceSheetMainItems.MainItemId,
       OrderInReport,
       GeneralBalance,
       Acc_BalanceSheetSubItems.SubItemName,
       dbo.Acc_BalanceSheetSubItems.SubParentItemName,
       ISNULL(SUM(AccountBalance.OpenningDebit), 0) AS Cost,
       ISNULL(SUM(AccountBalance.OpenningCredit), 0) AS DepreciationTot,
       (ISNULL(SUM(AccountBalance.OpenningDebit), 0) - ISNULL(SUM(AccountBalance.OpenningCredit), 0)) AS Net
FROM dbo.Acc_BalanceSheetSubItems
    INNER JOIN AccountBalance
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    --LEFT OUTER JOIN dbo.Acc_AssetType ON Acc_AssetType.AccumulatedDepAccountId = --AccountBalance.AccountId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 1)
GROUP BY Acc_BalanceSheetSubItems.SubItemName,
         MainItemNameArabic,
         OrderInReport,
         GeneralBalance,
         Acc_BalanceSheetMainItems.MainItemId,
         SubParentItemName,
         Acc_BalanceSheetMainItems.MainItemNameEnglish
ORDER BY OrderInReport;
```

**Financial_Current Assets[NBSP]**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance)
SELECT MainItemNameArabic,
       MainItemNameEnglish,
       Acc_BalanceSheetMainItems.MainItemId,
       OrderInReport,
       GeneralBalance,
       Acc_BalanceSheetSubItems.SubItemName,
       dbo.Acc_BalanceSheetSubItems.SubParentItemName,
       0 AS Cost,
       ISNULL(SUM(AccountBalance.OpenningDebit), 0) - ISNULL(SUM(AccountBalance.OpenningCredit), 0) AS DepreciationTot
FROM AccountBalance
    INNER JOIN dbo.Acc_BalanceSheetSubItems
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 2)
GROUP BY GeneralBalance,
         Acc_BalanceSheetSubItems.SubItemName,
         OrderInReport,
         Acc_BalanceSheetSubItems.SubParentItemName,
         MainItemNameEnglish,
         Acc_BalanceSheetMainItems.MainItemNameArabic,
         Acc_BalanceSheetMainItems.MainItemId
ORDER BY OrderInReport;
```

**Financial_Current Liabilities[NBSP]**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance)
SELECT MainItemNameArabic,
       MainItemNameEnglish,
       Acc_BalanceSheetMainItems.MainItemId,
       OrderInReport,
       GeneralBalance,
       Acc_BalanceSheetSubItems.SubItemName,
       dbo.Acc_BalanceSheetSubItems.SubParentItemName,
       0 AS Cost,
       (ISNULL(SUM(AccountBalance.OpenningCredit), 0) - ISNULL(SUM(AccountBalance.OpenningDebit), 0)) AS DepreciationTot
FROM AccountBalance
    INNER JOIN dbo.Acc_BalanceSheetSubItems
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 3)
GROUP BY GeneralBalance,
         Acc_BalanceSheetSubItems.SubItemName,
         OrderInReport,
         Acc_BalanceSheetSubItems.SubParentItemName,
         MainItemNameEnglish,
         Acc_BalanceSheetMainItems.MainItemNameArabic,
         Acc_BalanceSheetMainItems.MainItemId
ORDER BY OrderInReport;
```

**Financial_Equity**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance)
SELECT MainItemNameArabic,
       MainItemNameEnglish,
       Acc_BalanceSheetMainItems.MainItemId,
       OrderInReport,
       GeneralBalance,
       Acc_BalanceSheetSubItems.SubItemName,
       dbo.Acc_BalanceSheetSubItems.SubParentItemName,
       0 AS Cost,
       ISNULL(SUM(AccountBalance.OpenningDebit), 0) - ISNULL(SUM(AccountBalance.OpenningCredit), 0) AS DepreciationTot
FROM AccountBalance
    INNER JOIN dbo.Acc_BalanceSheetSubItems
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 4)
GROUP BY GeneralBalance,
         Acc_BalanceSheetSubItems.SubItemName,
         OrderInReport,
         Acc_BalanceSheetSubItems.SubParentItemName,
         MainItemNameEnglish,
         Acc_BalanceSheetMainItems.MainItemNameArabic,
         Acc_BalanceSheetMainItems.MainItemId
ORDER BY OrderInReport;
```

**Financial_Long-term liabilities**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance)
SELECT MainItemNameArabic,
       MainItemNameEnglish,
       Acc_BalanceSheetMainItems.MainItemId,
       OrderInReport,
       GeneralBalance,
       Acc_BalanceSheetSubItems.SubItemName,
       dbo.Acc_BalanceSheetSubItems.SubParentItemName,
       0 AS Cost,
       ISNULL(SUM(AccountBalance.OpenningDebit), 0) - ISNULL(SUM(AccountBalance.OpenningCredit), 0) AS DepreciationTot
FROM AccountBalance
    INNER JOIN dbo.Acc_BalanceSheetSubItems
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 5)
GROUP BY GeneralBalance,
         Acc_BalanceSheetSubItems.SubItemName,
         OrderInReport,
         Acc_BalanceSheetSubItems.SubParentItemName,
         MainItemNameEnglish,
         Acc_BalanceSheetMainItems.MainItemNameArabic,
         Acc_BalanceSheetMainItems.MainItemId
ORDER BY OrderInReport;
```

**Financial_Long-term assets Accounts**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit, AccountName
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
           AccountName
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance,
             AccountName)
SELECT Acc_BalanceSheetMainItems.MainItemId,
       Acc_BalanceSheetSubItems.SubItemName,
       ISNULL((AccountBalance.OpenningDebit), 0) AS Cost,
       ISNULL((AccountBalance.OpenningCredit), 0) AS DepreciationTot,
       (ISNULL((AccountBalance.OpenningDebit), 0) - ISNULL((AccountBalance.OpenningCredit), 0)) AS Net,
       AccountBalance.GeneralBalance,
       AccountBalance.AccountName
FROM dbo.Acc_BalanceSheetSubItems
    INNER JOIN AccountBalance
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 1)
ORDER BY OrderInReport;
```

**Financial_Current Assets[NBSP] Accounts**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit, AccountName
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
           AccountName
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance,
             AccountName)
SELECT Acc_BalanceSheetMainItems.MainItemId,
       Acc_BalanceSheetSubItems.SubItemName,
       ISNULL((AccountBalance.OpenningDebit), 0) AS Cost,
       ISNULL((AccountBalance.OpenningCredit), 0) AS DepreciationTot,
       (ISNULL((AccountBalance.OpenningDebit), 0) - ISNULL((AccountBalance.OpenningCredit), 0)) AS Net,
       AccountBalance.GeneralBalance,
       AccountBalance.AccountName
FROM dbo.Acc_BalanceSheetSubItems
    INNER JOIN AccountBalance
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 2)
ORDER BY OrderInReport;
```

**Financial_Current Liabilities[NBSP]Accounts**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit, AccountName
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
           AccountName
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance,
             AccountName)
SELECT Acc_BalanceSheetMainItems.MainItemId,
       Acc_BalanceSheetSubItems.SubItemName,
       0 AS Cost,
       ISNULL((AccountBalance.OpenningCredit), 0) AS DepreciationTot,
       AccountBalance.AccountName,
       AccountBalance.GeneralBalance
FROM dbo.Acc_BalanceSheetSubItems
    INNER JOIN AccountBalance
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 3)
ORDER BY OrderInReport;
```

**Financial_Equity Accounts**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit, AccountName
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
           AccountName
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance,
             AccountName)
SELECT Acc_BalanceSheetMainItems.MainItemId,
       Acc_BalanceSheetSubItems.SubItemName,
       0 AS Cost,
       ISNULL((AccountBalance.OpenningCredit), 0) AS DepreciationTot,
       AccountBalance.AccountName,
       AccountBalance.GeneralBalance
FROM dbo.Acc_BalanceSheetSubItems
    INNER JOIN AccountBalance
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 4)
ORDER BY OrderInReport;
```

**Financial_Long-term liabilities Accounts**: `Fill`; params: @BalanceDate DateTime, @BranchIdList String (nullable)

```sql
WITH AccountBalance (AccountId, GeneralBalance, ParentAccountId, OpenningCredit, OpenningDebit, PeriodCredit,
                     PeriodDebit, AccountName
                    )
AS (SELECT Acc_Account.AccountId,
           GeneralBalance,
           Acc_Account.ParentAccountId,
           ISNULL(SUM(Balance.Credit), 0) AS Credit,
           ISNULL(SUM(Balance.Debit), 0) AS Debit,
           ISNULL(SUM(Balance.PeriodCredit), 0) AS PeriodCredit,
           ISNULL(SUM(Balance.PeriodDebit), 0) AS PeriodDebit,
           AccountName
    FROM Acc_Account
        LEFT OUTER JOIN
        (
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountBalanceBeforeDate(@BalanceDate, NULL, @BranchIdList) AS Acc_GetAccountBalanceBeforeDate_1
            UNION ALL
            SELECT AccountId,
                   Credit,
                   Debit,
                   PeriodCredit,
                   PeriodDebit
            FROM dbo.Acc_GetAccountJournalActionsBeforeDate(@BalanceDate, NULL, NULL, NULL, NULL, NULL, @BranchIdList) AS Acc_GetAccountJournalActionsBeforeDate_1
        ) AS Balance
            ON Acc_Account.AccountId = Balance.AccountId
    WHERE (Acc_Account.AccountId NOT IN
           (
               SELECT ParentAccountId
               FROM Acc_Account AS Acc_Account_2
               WHERE (ParentAccountId IS NOT NULL)
           )
          )
    GROUP BY Acc_Account.AccountId,
             Acc_Account.ParentAccountId,
             GeneralBalance,
             AccountName)
SELECT Acc_BalanceSheetMainItems.MainItemId,
       Acc_BalanceSheetSubItems.SubItemName,
       0 AS Cost,
       ISNULL((AccountBalance.OpenningCredit), 0) AS DepreciationTot,
       AccountBalance.AccountName,
       AccountBalance.GeneralBalance
FROM dbo.Acc_BalanceSheetSubItems
    INNER JOIN AccountBalance
        ON AccountBalance.GeneralBalance = Acc_BalanceSheetSubItems.BalanceSheetSubItemId
    INNER JOIN dbo.Acc_BalanceSheetMainItems
        ON Acc_BalanceSheetMainItems.MainItemId = Acc_BalanceSheetSubItems.MainItemId
WHERE (Acc_BalanceSheetSubItems.MainItemId = 5)
ORDER BY OrderInReport;
```
