# Legacy — Period Balance (تقرير ارصدة اول المدة)

RPT = `D:\Hadaf\AccFlex_ERP\GeneralAccounting\GeneralLedger.Reports\Reports\PeriodBalanceReport`
FE = `AccFlex_Cloud_Front\accflex-erp\projects\general-accounting\src\app\modules\advanced-reports\period-balance\`

## Input contract
- Route `advanced-reports/period-balance`, `PeriodBalanceReportShellComponent`, **ModuleId 361** (`advanced-reports.module.ts:109-112`).
- Form `{ subPeriodId, branchesIds }`.
  - `subPeriodId`: dx-lookup over `accountingSubPeriodClient.getAllAccountingSubPeriods()`. It is required, and the shell toasts `COMMON._DataRequired_` when it is missing.
  - `branchesIds`: `app-branch-check-list`, defaulting to all of the user's branches. On submit, `filter()` copies `BranchLookupRef.BranchForm.BranchList` into it.
- iframe URL: `AdvancedReports/PeriodBalance?lang=..&subPeriodId=<id>&branchesIds=<csv>`.

## Controller
`AdvancedReportsController.cs:106-115`. The action reads `SubPeriodStart`/`SubPeriodEnd` from `Acc_AccountingSubPeriod`, then calls `new rptPeriodBalance(subPeriodId, start, end, branchesIds)`.

## Code-behind
`rptPeriodBalance.cs` does no C# math and has no drill-through.
- Name: `rptAraPeriodBalance` for Arabic, `rptPeriodBalance` otherwise.
- Money uses `{0:n2}` together with the tenant ApproximateNo.
- The period start/end are printed as `dd/MM/yyyy`.

## SQL (`dsPeriodBalanceReport.xsd`, adapter AccountBalance; params @AccountingSubPeriodId int, @BranchList nvarchar NULL)
```sql
SELECT Acc_AccountBalance.AccountBalanceId,Acc_Account.AccountNo, Acc_Account.AccountName,
       Acc_Currency.CurrencyName,Acc_AccountBalance.CurrencyFactor,
       Acc_AccountBalance.Credit, Acc_AccountBalance.Debit, Acc_AccountBalance.CreditLocal,
       Acc_AccountBalance.DebitLocal, Acc_AccountBalance.CreatedDate, Acc_AccountBalance.ModifiedDate
FROM  Acc_AccountBalance INNER JOIN
      Acc_Account ON Acc_AccountBalance.AccountId = Acc_Account.AccountId INNER JOIN
      Acc_Currency ON Acc_AccountBalance.CurrencyId = Acc_Currency.CurrencyId
WHERE AccountingSubPeriodId = @AccountingSubPeriodId AND (Acc_AccountBalance.Debit >0 OR Acc_AccountBalance.Credit>0)
  AND ( @BranchList IS NULL AND @BranchList IS NULL
        OR Acc_AccountBalance.BranchId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@BranchList)) )
```
Quirks to keep:
- There is no ORDER BY. The report groups by `AccountNo` ascending.
- A NULL list returns rows whose `BranchId` is NULL. A non-null list excludes them.
- The filter is on the foreign-currency `Debit`/`Credit`, not the local amounts.

## Layout (code-designed in `rptPeriodBalance.Designer.cs`; no .repx)
A4 landscape.
- **PageHeader:** logo, CompanyName, Address, Email, and the title "Period Balance Report" / "تقرير أرصدة أول المدة".
- **GroupHeader:** Period Start and Period End, as "تاريخ بداية الفترة" / "تاريخ نهاية الفترة".
- **Detail report on AccountBalance:**
  - Grouped by AccountNo.
  - Group header: Account No, Account Name, Created Date and Modified Date (`dd/MM/yyyy`), followed by a column-label row.
  - Detail columns: Debit, Credit, Debit Local, Credit Local, Currency, Factor.
  - Group footer "Totals": sums of DebitLocal and CreditLocal.
  - Report footer "Totals": grand sums of DebitLocal and CreditLocal.
- **Arabic labels:**

  | English | Arabic |
  |---|---|
  | Debit | مدين |
  | Credit | دائن |
  | Local | محلي |
  | Currency | عمله |
  | Factor | معامل |
  | Totals | الاجمالى |
  | Account No | رقم الحساب |
  | Account Name | اسم الحساب |
  | Created Date | تاريخ الانشاء |
  | Modified Date | تاريخ التعديل |
