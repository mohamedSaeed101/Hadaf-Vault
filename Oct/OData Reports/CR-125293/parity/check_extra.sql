SET NOCOUNT ON;
-- R1: does IsArabic change any EmployeeName? (proves the ar cases are not vacuous)
SELECT COUNT(*) rowsWhereArDiffersFromEn FROM dbo.PR_EmployeesSalariesItemsReport(NULL, NULL, 0) e JOIN dbo.PR_EmployeesSalariesItemsReport(NULL, NULL, 1) a ON a.EmployeeIncomeId = e.EmployeeIncomeId WHERE a.EmployeeName <> e.EmployeeName;
-- R3: suspend flags present in the data (the renamed columns carry values)
SELECT SUM(CASE WHEN Suspend = 1 THEN 1 ELSE 0 END) salarySuspended, SUM(CASE WHEN SalaryDetailSuspend = 1 THEN 1 ELSE 0 END) detailSuspended, SUM(CASE WHEN Suspend <> SalaryDetailSuspend THEN 1 ELSE 0 END) suspendFlagsDiffer FROM dbo.PR_EmployeeSalaryReceiptReport(8, 2026, NULL, 5);
