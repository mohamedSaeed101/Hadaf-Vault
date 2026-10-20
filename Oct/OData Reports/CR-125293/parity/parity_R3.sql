-- CR 125293 parity, R3: legacy FillByEmployeeId (dsEmployeeReceipt.xsd) vs TVF dbo.PR_EmployeeSalaryReceiptReport on UNP-Ali. Read-only: temp tables and variables only.
-- Legacy SQL = legacy_r3.sql (verbatim), run through sp_executesql with the TableAdapter parameter types.
SET NOCOUNT ON;
DECLARE @Legacy NVARCHAR(MAX) = N'WITH employeeBank
AS (SELECT ROW_NUMBER() OVER (PARTITION BY EmployeeId, CurrencyId ORDER BY EmployeeBankId) AS rowNo,
           PR_Bank.BankId,
           PR_Bank.BankName,
           EmployeeId,
           CurrencyId,
           SEPA,
           Address,
           Branch,
           Country,
           AccountOwner,
           SwiftCode
    FROM PR_EmployeeBank
        INNER JOIN PR_Bank
            ON PR_Bank.BankId = PR_EmployeeBank.BankId)
SELECT PR_Salaries.EmployeeId,
       PR_Employee.EmployeeName,
       PR_Employee.EmployeeNumber,
       PR_Branch.BranchName,
       PR_Projects.ProjectName,
       PR_Job.JobName,
       PR_SalaryDetail.SalaryId,
       PR_SalaryDetail.SalaryDetailId,
       PR_SalaryDetail.EmployeeIncomeId,
       PR_SalaryDetail.IncomeAmount,
       PR_Income.IncomeName,
       PR_Income.Deduction,
       Acc_Currency.EnglishLetter,
       PR_Salaries.SalaryId,
       PR_Salaries.SalaryMainId,
       PR_Salaries.Total,
       PR_Salaries.Remarks,
       PR_Salaries.InsuranceCompany,
       PR_Salaries.TotalAdditions,
       PR_Salaries.TotalDeductions,
       PR_Salaries.PostDate,
       PR_Salaries.Posted,
       PR_SalaryMain.SalaryYear,
       PR_SalaryMain.SalaryMonth,
       PR_SalaryMain.SalaryDate,
       PR_Salaries.Suspend,
       PR_SalaryDetail.Suspend,
       employeeBank.BankId,
       employeeBank.BankName,
       employeeBank.SEPA AS BankSEPA,
       employeeBank.Address AS BankAddress,
       employeeBank.Branch AS BankBranch,
       employeeBank.Country AS BankCountry,
       employeeBank.AccountOwner AS BankAccountOwner,
       employeeBank.SwiftCode AS BankSwiftCode
FROM PR_Salaries
    INNER JOIN PR_SalaryDetail
        ON PR_Salaries.SalaryId = PR_SalaryDetail.SalaryId
    INNER JOIN PR_Income
        ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
    INNER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT JOIN dbo.PR_Projects
        ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    LEFT JOIN dbo.PR_Branch
        ON PR_Branch.BranchId = PR_Employee.BranchId
    INNER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    INNER JOIN Acc_Currency
        ON PR_Salaries.CurrencyId = Acc_Currency.CurrencyId
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT JOIN employeeBank
        ON PR_Employee.EmployeeId = employeeBank.EmployeeId
           AND employeeBank.CurrencyId = PR_Salaries.CurrencyId
           AND employeeBank.rowNo = 1
WHERE (
          @EmployeeId IS NULL
          OR PR_Salaries.EmployeeId IN
             (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeId)
             )
      )
      AND PR_SalaryMain.SalaryMonth = @SalaryMonth
      AND PR_SalaryMain.SalaryYear = @SalaryYear
      AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel';
DECLARE @LegacyParams NVARCHAR(MAX) = N'@SalaryMonth INT, @SalaryYear INT, @EmployeeSecurityLevel INT, @EmployeeId NVARCHAR(MAX)';
DECLARE @rpt VARCHAR(10) = 'R3', @Case VARCHAR(60), @Params NVARCHAR(400), @Extra NVARCHAR(400), @i INT = 1, @n INT, @sql NVARCHAR(MAX), @cols NVARCHAR(MAX), @clN NVARCHAR(MAX), @clO NVARCHAR(MAX), @smN NVARCHAR(MAX), @smO NVARCHAR(MAX);

DECLARE @Month INT, @Year INT, @EmployeeIds NVARCHAR(MAX), @Lvl INT;
DECLARE @M1 INT, @Y1 INT, @M2 INT, @Y2 INT;
SELECT @Y1 = SalaryYear, @M1 = SalaryMonth FROM (SELECT SalaryYear, SalaryMonth, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) rn FROM PR_SalaryDetail d JOIN PR_Salaries s ON s.SalaryId = d.SalaryId JOIN PR_SalaryMain m ON m.SalaryMainId = s.SalaryMainId GROUP BY SalaryYear, SalaryMonth) x WHERE rn = 1;
SELECT @Y2 = SalaryYear, @M2 = SalaryMonth FROM (SELECT SalaryYear, SalaryMonth, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) rn FROM PR_SalaryDetail d JOIN PR_Salaries s ON s.SalaryId = d.SalaryId JOIN PR_SalaryMain m ON m.SalaryMainId = s.SalaryMainId GROUP BY SalaryYear, SalaryMonth) x WHERE rn = 2;
DECLARE @Hi INT = (SELECT MAX(EmployeeSecurityLevel) FROM PR_Employee), @Lo INT = (SELECT MIN(EmployeeSecurityLevel) FROM PR_Employee);
DECLARE @Ids3 NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(20)), ',') WITHIN GROUP (ORDER BY EmployeeId) FROM (SELECT TOP 3 s.EmployeeId FROM PR_Salaries s JOIN PR_SalaryMain m ON m.SalaryMainId = s.SalaryMainId JOIN PR_Employee e ON e.EmployeeId = s.EmployeeId WHERE m.SalaryYear = @Y1 AND m.SalaryMonth = @M1 GROUP BY s.EmployeeId ORDER BY MAX(e.EmployeeSecurityLevel) DESC, s.EmployeeId) x);
SELECT @Y1 AS busiestYear, @M1 AS busiestMonth, @Y2 AS secondYear, @M2 AS secondMonth, @Hi AS hiLvl, @Lo AS loLvl, @Ids3 AS Ids3,
       (SELECT COUNT(*) FROM PR_SalaryMain WHERE SalaryYear = @Y1 AND SalaryMonth = @M1) AS salaryMains, (SELECT SUM(CAST(IsDeleted AS INT)) FROM PR_SalaryMain WHERE SalaryYear = @Y1 AND SalaryMonth = @M1) AS deletedMains;
-- renamed columns: legacy 2nd Suspend (PR_SalaryDetail.Suspend, DataSet column Suspend1) = TVF SalaryDetailSuspend; legacy 2nd SalaryId (PR_Salaries.SalaryId) dropped in the TVF
CREATE TABLE #map (newName SYSNAME COLLATE DATABASE_DEFAULT, oldName SYSNAME COLLATE DATABASE_DEFAULT);
INSERT #map VALUES ('SalaryDetailSuspend', 'Suspend_2');
CREATE TABLE #money (newName SYSNAME COLLATE DATABASE_DEFAULT);
INSERT #money VALUES ('IncomeAmount'), ('Total'), ('InsuranceCompany'), ('TotalAdditions'), ('TotalDeductions');
SELECT TOP 0 * INTO #new FROM dbo.PR_EmployeeSalaryReceiptReport(1, 1, NULL, 0);
CREATE TABLE #cases (i INT, c VARCHAR(60), y INT, m INT, ids NVARCHAR(MAX), lvl INT);
INSERT #cases VALUES
 (1, 'a1 busiest month all, hi lvl', @Y1, @M1, NULL,  @Hi),
 (2, 'a2 busiest month all, lo lvl', @Y1, @M1, NULL,  @Lo),
 (3, 'b1 busiest month 3 ids, hi',   @Y1, @M1, @Ids3, @Hi),
 (4, 'b2 busiest month 3 ids, lo',   @Y1, @M1, @Ids3, @Lo),
 (5, 'c1 2nd month all, hi lvl',     @Y2, @M2, NULL,  @Hi);

-- #old: shape of the legacy result set (duplicate names get _<n>, e.g. Suspend_2); text columns in the database collation
CREATE TABLE #old (dummy_ INT);
SELECT @cols = STRING_AGG(CAST(QUOTENAME(name + CASE WHEN rn > 1 THEN '_' + CAST(rn AS VARCHAR(5)) ELSE '' END) + ' ' + system_type_name
             + CASE WHEN system_type_name LIKE '%char%' THEN ' COLLATE DATABASE_DEFAULT' ELSE '' END + ' NULL' AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY column_ordinal)
FROM (SELECT name, column_ordinal, system_type_name, ROW_NUMBER() OVER (PARTITION BY name ORDER BY column_ordinal) rn
      FROM sys.dm_exec_describe_first_result_set(@Legacy, @LegacyParams, 0)) d;
EXEC (N'ALTER TABLE #old ADD ' + @cols); ALTER TABLE #old DROP COLUMN dummy_;
-- shared columns: every TVF column but RowNo whose (mapped) name exists in the legacy result, in TVF order
SELECT @clN = STRING_AGG(CAST(QUOTENAME(n.name) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY n.column_id),
       @clO = STRING_AGG(CAST(QUOTENAME(ISNULL(m.oldName, n.name COLLATE DATABASE_DEFAULT)) AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY n.column_id)
FROM tempdb.sys.columns n LEFT JOIN #map m ON m.newName = n.name COLLATE DATABASE_DEFAULT
WHERE n.object_id = OBJECT_ID('tempdb..#new') AND n.name <> 'RowNo'
  AND EXISTS (SELECT 1 FROM tempdb.sys.columns o WHERE o.object_id = OBJECT_ID('tempdb..#old') AND o.name COLLATE DATABASE_DEFAULT = ISNULL(m.oldName, n.name COLLATE DATABASE_DEFAULT));
SELECT @smN = STRING_AGG(CAST('ISNULL(CAST(SUM(CAST(' + QUOTENAME(c.newName) + ' AS DECIMAL(38,6))) AS VARCHAR(60)),''null'')' AS NVARCHAR(MAX)), '+''|''+'),
       @smO = STRING_AGG(CAST('ISNULL(CAST(SUM(CAST(' + QUOTENAME(ISNULL(m.oldName, c.newName)) + ' AS DECIMAL(38,6))) AS VARCHAR(60)),''null'')' AS NVARCHAR(MAX)), '+''|''+')
FROM #money c LEFT JOIN #map m ON m.newName = c.newName;
SELECT 'shared' AS kind, @clN AS columns_new, @clO AS columns_legacy
UNION ALL SELECT 'new only', STRING_AGG(CAST(name AS NVARCHAR(MAX)), ','), NULL FROM tempdb.sys.columns n WHERE n.object_id = OBJECT_ID('tempdb..#new') AND CHARINDEX(QUOTENAME(n.name), @clN) = 0
UNION ALL SELECT 'legacy only', NULL, STRING_AGG(CAST(name AS NVARCHAR(MAX)), ',') FROM tempdb.sys.columns o WHERE o.object_id = OBJECT_ID('tempdb..#old') AND CHARINDEX(QUOTENAME(o.name), @clO) = 0
UNION ALL SELECT 'money (new names)', (SELECT STRING_AGG(newName, ',') FROM #money), NULL;
CREATE TABLE #res (rpt VARCHAR(10), c VARCHAR(60), p NVARCHAR(400), oldRows INT, newRows INT, oldMinusNew INT, newMinusOld INT, grpDiff INT, sumsOld VARCHAR(400), sumsNew VARCHAR(400), extra NVARCHAR(400));

SELECT @n = MAX(i) FROM #cases;
WHILE @i <= @n
BEGIN
    SELECT @Case = c, @Year = y, @Month = m, @EmployeeIds = ids, @Lvl = lvl FROM #cases WHERE i = @i;
    SET @Params = CONCAT(@Month, '/', @Year, ' ids=', ISNULL(@EmployeeIds, 'NULL'), ' lvl=', @Lvl);
    TRUNCATE TABLE #old; TRUNCATE TABLE #new;
    INSERT #old EXEC sp_executesql @Legacy, @LegacyParams, @SalaryMonth = @Month, @SalaryYear = @Year, @EmployeeSecurityLevel = @Lvl, @EmployeeId = @EmployeeIds;
    INSERT #new SELECT * FROM dbo.PR_EmployeeSalaryReceiptReport(@Month, @Year, @EmployeeIds, @Lvl);
    SET @Extra = CONCAT('legacy SalaryId<>SalaryId_2 rows: ', (SELECT COUNT(*) FROM #old WHERE NOT EXISTS (SELECT SalaryId INTERSECT SELECT SalaryId_2)));

    SET @sql = N'INSERT #res (rpt, c, p, oldRows, newRows, oldMinusNew, newMinusOld, grpDiff, sumsOld, sumsNew, extra) SELECT @rpt, @c, @p,
        (SELECT COUNT(*) FROM #old), (SELECT COUNT(*) FROM #new),
        (SELECT COUNT(*) FROM (SELECT ' + @clO + N' FROM #old EXCEPT SELECT ' + @clN + N' FROM #new) x),
        (SELECT COUNT(*) FROM (SELECT ' + @clN + N' FROM #new EXCEPT SELECT ' + @clO + N' FROM #old) x),
        (SELECT COUNT(*) FROM ((SELECT ' + @clO + N', COUNT(*) n FROM #old GROUP BY ' + @clO + N' EXCEPT SELECT ' + @clN + N', COUNT(*) FROM #new GROUP BY ' + @clN + N')
                         UNION ALL (SELECT ' + @clN + N', COUNT(*) n FROM #new GROUP BY ' + @clN + N' EXCEPT SELECT ' + @clO + N', COUNT(*) FROM #old GROUP BY ' + @clO + N')) x),
        (SELECT ' + @smO + N' FROM #old), (SELECT ' + @smN + N' FROM #new), @extra;
    IF EXISTS (SELECT ' + @clO + N' FROM #old EXCEPT SELECT ' + @clN + N' FROM #new) SELECT TOP 10 ''L-N'' AS diff, @c AS c, * FROM (SELECT ' + @clO + N' FROM #old EXCEPT SELECT ' + @clN + N' FROM #new) x;
    IF EXISTS (SELECT ' + @clN + N' FROM #new EXCEPT SELECT ' + @clO + N' FROM #old) SELECT TOP 10 ''N-L'' AS diff, @c AS c, * FROM (SELECT ' + @clN + N' FROM #new EXCEPT SELECT ' + @clO + N' FROM #old) x;';
    EXEC sp_executesql @sql, N'@rpt VARCHAR(10), @c VARCHAR(60), @p NVARCHAR(400), @extra NVARCHAR(400)', @rpt, @Case, @Params, @Extra;

    SET @i += 1;
END

SELECT rpt, c, p, oldRows, newRows, oldMinusNew, newMinusOld, grpDiff, CASE WHEN sumsOld = sumsNew THEN 'yes' ELSE 'NO' END AS sumsEqual, sumsOld, sumsNew, extra,
       CASE WHEN oldRows = newRows AND oldMinusNew = 0 AND newMinusOld = 0 AND grpDiff = 0 AND sumsOld = sumsNew THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM #res ORDER BY c;
