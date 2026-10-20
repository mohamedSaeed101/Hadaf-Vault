SET NOCOUNT ON;
SELECT name, system_type_name, is_nullable FROM sys.dm_exec_describe_first_result_set(N'SELECT * FROM dbo.PR_EmployeeStatisticsReport(N''1'', ''20200101'', ''20201231'')', NULL, 0) ORDER BY column_ordinal;
SELECT name, system_type_name, is_nullable FROM sys.dm_exec_describe_first_result_set(N'SELECT * FROM dbo.PR_EmployeeVacationStatisticsReport(N''1'', ''20201231'')', NULL, 0) ORDER BY column_ordinal;
SELECT COUNT(*) total, SUM(CASE WHEN EndWork = 0 THEN 1 ELSE 0 END) active FROM dbo.PR_Employee;
SELECT 'Vac' t, MIN(DateFrom) mn, MAX(DateFrom) mx, COUNT(*) c FROM dbo.PR_Vacations
UNION ALL SELECT 'Adv', MIN(ApplayingStartDate), MAX(ApplayingStartDate), COUNT(*) FROM dbo.PR_Advance
UNION ALL SELECT 'Pen', MIN(PenaltyDate), MAX(PenaltyDate), COUNT(*) FROM dbo.PR_Penalty
UNION ALL SELECT 'Pur', MIN(ApplayingStartDate), MAX(ApplayingStartDate), COUNT(*) FROM dbo.PR_Purchase
UNION ALL SELECT 'Bon', MIN(BonusDate), MAX(BonusDate), COUNT(*) FROM dbo.PR_EmployeeBonus
UNION ALL SELECT 'Acc', MIN(ValidFromDate), MAX(ValidFromDate), COUNT(*) FROM dbo.PR_EmployeeAccruedvacation;
SELECT YEAR(DateFrom) y, MONTH(DateFrom) m, COUNT(*) c FROM dbo.PR_Vacations GROUP BY YEAR(DateFrom), MONTH(DateFrom) ORDER BY c DESC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
