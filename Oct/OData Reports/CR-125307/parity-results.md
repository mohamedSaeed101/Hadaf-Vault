---
type: parity-results
cr: 125307
updated: 2026-10-15
---

# CR-125307 — Number check results

## Phase 1 (prints 1–4)
Script: `parity\parity-A.sql` (run with `CR-125292\parity\run.sh`, db-all, read-only: temp tables only; TVF bodies copied verbatim from the 4 `.sql` files and run through `sp_executesql`; legacy `.xsd` CommandText verbatim + the C# step). Every header id on the tenant plus -1, × IsArabic 0 and 1. Run 2026-10-15.

UNP-Ali has no Employee Allowance (`PR_EmployeeAllowance`) or Allowance (`PR_Allowance`) rows, so the same section also ran on **ERP_MainDB-Ali** (same server; 2 allowance docs, 29 allowance serials of which 10 percentage lines).

| Print | Tenant | Ids with rows | Legacy rows | TVF rows | Legacy∖TVF | TVF∖Legacy | Count-diff groups | Bad RowNo groups |
|---|---|---|---|---|---|---|---|---|
| 1 EmployeeIncomePrint | UNP-Ali | 88 (ids 1–120) | 572 | 572 | 0 | 0 | 0 | 0 |
| 1 EmployeeIncomePrint | ERP_MainDB-Ali | 17 | 68 | 68 | 0 | 0 | 0 | 0 |
| 2 EmployeeAllowancePrint | UNP-Ali | no data | – | – | – | – | – | – |
| 2 EmployeeAllowancePrint | ERP_MainDB-Ali | 2 (ids 1, 3) | 40 | 40 | 0 | 0 | 0 | 0 |
| 3 AllowanceSerialPrint | UNP-Ali | no data | – | – | – | – | – | – |
| 3 AllowanceSerialPrint | ERP_MainDB-Ali | 29 (ids 1–30) | 58 | 58 | 0 | 0 | 0 | 0 |
| 4 EmployeeBonusPrint | UNP-Ali | 8 (ids 3–10) | 16 | 16 | 0 | 0 | 0 | 0 |
| 4 EmployeeBonusPrint | ERP_MainDB-Ali | 22 | 44 | 44 | 0 | 0 | 0 | 0 |

Legacy-side adjustments applied before comparing (decisions, not data fixes):
- C# steps: print 3 currency rebind (CurrencyName / CurrencyNameArabic) and `AllowancePercentage / 100` when IsPercentage (D15: divided in SQL; the layout must not format it as a percent of 100 again); print 4 BonusTypeName / BonusTypeNameSecondLanguage and currency rebind.
- D10 language: print 1 currency name in Arabic = `CurrencyNameArabic` (legacy printed the English name; 286 rows UNP-Ali / 34 ERP_MainDB-Ali changed); print 4 employee name in Arabic = Arabic name (legacy English only; 8 / 22 rows changed); D15 Arabic-name fallback to EmployeeName when blank (print 2 detail had no fallback in legacy; 0 rows affected, no blank Arabic names on either tenant).
- Print 2 `EmployeeId` (id column not in the legacy detail query) filled from `PR_EmployeeAllowanceDetail` by detail id.

Not exercised by the data: a header with no detail lines (prints 2 and 3; the TVFs LEFT JOIN from the header so it still returns one row), an employee missing Branch/Department/Job (print 1: income rows still returned with blank employee fields, as the legacy RIGHT JOIN does).

Syntax: `SET PARSEONLY ON` over the 4 files on UNP-Ali: no errors; 0 of the 4 objects exist on the tenant afterwards.

## Phase 2 (prints 5, 6, 7a, 8)
Script: `parity\parity-B.sql` (run with `CR-125292\parity\run.sh`, db-all, read-only: session #temp tables only, no CREATE on the tenant). Both sides are generated text, not retyped: the TVF bodies are copied from the 4 `.sql` files and run through `sp_executesql`; the legacy `.xsd` CommandText is copied verbatim and run the same way, then the C# steps are applied (dataset relation join, purchase currency rebind, accrual `DateDifference`). Every header id on the tenant plus -1, × IsArabic 0 and 1, on **UNP-Ali** and **ERP_MainDB-Ali** (UNP-Ali has one paying-salary doc, no terminated employee with transactions, no multi-currency or multi-bank employee). Run 2026-10-15. RowNo is compared too (legacy order).

| Print | Tenant | Ids with rows | Legacy rows | TVF rows | Legacy∖TVF | TVF∖Legacy |
|---|---|---|---|---|---|---|
| 5 EmployeeAdvancePrint | UNP-Ali | 11 | 256 | 256 | 0 | 0 |
| 5 EmployeeAdvancePrint | ERP_MainDB-Ali | 10 | 88 | 88 | 0 | 0 |
| 6 EmployeePurchasePrint | UNP-Ali | 2 | 10 | 10 | 0 | 0 |
| 6 EmployeePurchasePrint | ERP_MainDB-Ali | 3 | 20 | 20 | 0 | 0 |
| 7a SalaryExchangePrint | UNP-Ali | 1 (id 2, 75 lines) | 150 | 150 | 0 | 0 |
| 7a SalaryExchangePrint | ERP_MainDB-Ali | 7 | 20 | 20 | 0 | 0 |
| 8 EmployeeAccrualPrint | UNP-Ali | 78 employees | 312 | 312 | 0 | 0 |
| 8 EmployeeAccrualPrint | ERP_MainDB-Ali | 11 employees (incl. terminated 3, 4, 8; two currencies for 16) | 92 | 92 | 0 | 0 |

Rows counted over both languages. Ids of -1 return 0 rows on both sides.

Working period (print 8): the TVF's CROSS APPLY block (extracted from the file) vs an independent port of `Payroll.Reports\Helper\DateDiffrence.cs` (monthDay[] table + IsLeapYear) on 18 200 synthetic start/now pairs (2600 start days from 2019-12-25 × 7 "now" values incl. 2024-02-29, month ends, year end): 0 differences both ways. On real rows it is part of the table above (both sides use GETDATE()).

Accrual totals vs the Payroll screen (`GetEmployeeTransactionHeaderQuery`, its separate per-type sums recomputed in SQL): 0 mismatches on all 78 + 12 employee/currency groups (TotalSalary, TotalPaid, TotalPreviousAccrued, TotalSeverancePackage, TotalVacationProvisioning, TotalAccural, NetAccrual). Finding only (not compared numerically): the screen's working period differs by design from the print's: it uses `DateTimeSpan.CompareDates` to tomorrow, the latest open contract (`OrderByDescending(ContractStartDate)`), and for EndWork employees DateOfWork → EndWorkingDate; the legacy print (and the TVF, D17-4) runs StartDate → now for everybody and repeats the header per open contract.

Legacy-side adjustments applied before comparing (D10, language only):
- 5 Advance: `CurrencyLetter` = ArabicLetter in Arabic, EnglishLetter in English. Legacy printed EnglishLetter in both: differs on ERP_MainDB-Ali Arabic prints (10 advances, 44 rows), none on UNP-Ali (letters equal there).
- 6 Purchase: `CurrencyLetter` per language as the C# BeforePrint intends. Note: that rebind uses the path `EmployeePurchase.EnglishLetter/ArabicLetter` while the report's DataMember is `PR_Purchase`, so the legacy cell most likely printed blank; the TVF prints the letter.
- 7a SalaryExchange: `CurrencyName` = CurrencyNameArabic in Arabic, CurrencyName in English (legacy layout inverted it); `TypeName` = TypeName (Arabic) / TypeNameSecondLanguage (English), not on the legacy layout.
- 8 Accruals: language flags exactly as legacy (`@isEnglish` = NOT @IsArabic); header names already per language in legacy.

Columns dropped from the legacy result sets (not on the legacy layouts): raw `EmployeeArabicName` (5, 7a), `EnglishLetter`/`ArabicLetter` (5, 6 → `CurrencyLetter`), `TypeNameSecondLanguage`/`CurrencyNameArabic` (7a), `EmployeeNumberInt` (7a: `CAST(EmployeeNumber AS BIGINT)` throws on a non-numeric number), detail `CurrencyName` (8: inverted in legacy, the group header carries the currency), audit columns CreatedById/LastModifiedById/CreatedOn/LastModifiedOn (8).

Not exercised by the data: an advance or purchase with no repayments (none on either tenant; the TVFs LEFT JOIN from the header so it returns one row with NULL repayment columns), a re-hired employee with transactions (no employee on either tenant has more than one contract and transactions), an employee with more than one open contract (would repeat each currency header per contract, as legacy).

## Phase 3 (print 7b BankSalaryPrint)
Script: `parity\parity-C.sql` (run with `CR-125292\parity\run.sh`, db-all, read-only: temp tables only). Legacy `dsBankSalaryPrint.xsd` FillBy **and** Fill CommandText verbatim, run through `sp_executesql` with the TableAdapter parameter list (so `#L.ord` is the row order the C# `RowNumber = index + 1` loop saw); `PR_BankSalaryPrint` body inline, params renamed `@t_*`. Cases derived per `Pr_PayingSalaries` with a BankId as the front does from `SalaryExchangeDto` (month = PayingSalariesDate, currency = CurrencyId, employeeIds = detail EmployeeIds joined by `,`), plus variants: employeeIds NULL, currency NULL, security level 1, next month, a fixed 3-employee list. Security level = tenant max (5). Run 2026-10-15.

UNP-Ali has only **one** paying-salary document with a bank (id 2, 75 lines), so the script also ran on **ERP_MainDB-Ali** (7 documents) via a `USE` prefix.

| Tenant | Docs | Cases | Cases with rows | Legacy FillBy rows | TVF rows | TVF∖Legacy | Legacy∖TVF | Fill vs FillBy diff | RowNo ≠ legacy order | ar diff (name/currency per D10/D15) |
|---|---|---|---|---|---|---|---|---|---|---|
| UNP-Ali | 1 (id 2) | 6 | 6 | 380 | 380 | 0 | 0 | 0 | 0 | 0 |
| ERP_MainDB-Ali | 7 (ids 1–7) | 42 | 27 | per case 1–4, = TVF | = legacy | 0 | 0 | 0 | 0 | 0 |

Notes:
- **Legacy action**: the old front called `mvc/AccountingReports/BankSalaryPrint` with `payingsalaryid` as an extra query value; that action has no such parameter, so the old print ran **Fill**, not FillBy. The TVF follows D12 (FillBy). They differ only when the document's own BankId ≠ the bankId passed (never, the front passes the document's BankId) or is NULL; Fill vs FillBy diff = 0 in every case above.
- **RowNo order**: legacy DISTINCT has no ORDER BY; the cached plan on UNP-Ali is a Distinct Sort on CurrencyNameArabic, AccountNo, Description, Total, …, EmployeeId. TVF: `ROW_NUMBER() OVER (ORDER BY CurrencyNameArabic, AccountNo, Description, Total, EmployeeId)`. First try (AccountNo, EmployeeId, Total) mismatched where 3 employees share one AccountNo; the plan order matches 100 %. Legacy order is plan-dependent, so this is the observed order, not a guaranteed one.
- D10/D15: Arabic → EmployeeName = EmployeeArabicName (blank → EmployeeName; column is NOT NULL), CurrencyName = CurrencyNameArabic; English → EmployeeName, `Acc_Currency.CurrencyName` (never NULL in any case). Raw `EmployeeArabicName` and `CurrencyNameArabic` still returned.
