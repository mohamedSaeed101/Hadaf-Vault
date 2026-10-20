---
type: parity-results
cr: 125294
updated: 2026-10-14
---

# CR-125294 — Number check results (before / after)

**Before** = the legacy MVC report SQL (the typed-DataSet queries from `Payroll.Reports\HR\*.xsd`, run verbatim). **After** = the new OData TVFs from `origin/cr125294` (db `a2a2ac3aa`).

Tenant **UNP-Ali** on **db-all**. The 5 TVFs were created there directly with sqlcmd at 16:37 server time; none of them existed before. The 0413 layout seed was applied later for the in-app check (6 `InsertLayout` rows). Script: [[parity-125294.sql]], `@SecurityLevel = 5`, `2026-01-01 … 2026-12-31`, `@EmployeeIds = 4,10,31,64,67,68,70,78,79`.

## Run 2 — with test data (current)

Between the runs, `CR-125294 test data` was added to UNP-Ali: paid advances 10 (emp 10, 4,000, 2026-03-30) and 11 (emp 31, 3,000, 2026-07-30), purchases 1 (emp 64, 2,400) and 2 (emp 70, 2,500), and 3 paid repayments.

| Report | Before (legacy) | After (OData) | Differences |
|---|---|---|---|
| Unpaid advance payments | 2 rows | 2 rows | none in either direction |
| Employees advance | 11 rows, 139,436.23 | 11 rows, 139,436.23 | none in either direction |
| Advance repayments | — | — | none |
| Employee purchase | 2 rows, 4,900.00 | 2 rows, 4,900.00 | none in either direction |
| Purchase repayments | — | — | none |

**Verdict: pass on all three reports.**

## Run 1 — before the test data

| Report | Before | After | Differences |
|---|---|---|---|
| Unpaid advance payments | 0 | 0 | none (no paid advances yet) |
| Employees advance | 9 rows, 132,436.23 | 9 rows, 132,436.23 | none |
| Employee purchase | 0 | 0 | none (no purchases yet) |
