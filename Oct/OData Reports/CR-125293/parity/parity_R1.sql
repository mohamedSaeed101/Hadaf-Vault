-- CR 125293 parity, R1: legacy PR_Emp_Income (dsEmployeeFinance.xsd) vs TVF dbo.PR_EmployeesSalariesItemsReport on UNP-Ali. Read-only: temp tables and variables only.
-- Legacy SQL = legacy_r1.sql (verbatim), run through sp_executesql with the TableAdapter parameter types.
SET NOCOUNT ON;
DECLARE @Legacy NVARCHAR(MAX) = N'SELECT PR_EmployeeIncome.EmployeeIncomeId,
       PR_EmployeeIncome.EmployeeId,
       PR_EmployeeIncome.IncomeId,
       PR_EmployeeIncome.IncomeCurrency,
       PR_EmployeeIncome.IncomeAmount,
       PR_EmployeeIncome.IncomeStartDate,
       PR_EmployeeIncome.IncomeTaxRoleId,
       PR_EmployeeIncome.SocialInsuranceRoleId,
       PR_EmployeeIncome.EmployeeInsuranceAmount,
       PR_EmployeeIncome.CompanyInsuranceAmount,
       Acc_Currency.CurrencyName,
       PR_Income.IncomeName,
       PR_Income.Deduction,
       CASE
           WHEN @IsArabic = 1 THEN
               CASE
                   WHEN (LTRIM(RTRIM(PR_Employee.EmployeeArabicName))) = '''' THEN
                       PR_Employee.EmployeeName
                   ELSE
                       PR_Employee.EmployeeArabicName
               END
           ELSE
               PR_Employee.EmployeeName
       END EmployeeName,
       PR_SocialInsurance.SocialInsuranceRole,
       PR_Department.DepartmentName,
       PR_Job.JobName,
       PR_Branch.BranchName,
       PR_Employee.DateOfWork,
       PR_Employee.EmployeeNumber,
       PR_Employee.IDNumber,
       ProjectName
FROM PR_Branch
    INNER JOIN PR_Employee
        ON PR_Branch.BranchId = PR_Employee.BranchId
    INNER JOIN PR_Department
        ON PR_Employee.DepartmentId = PR_Department.DepartmentId
    INNER JOIN PR_Job
        ON PR_Employee.JobId = PR_Job.JobId
    RIGHT OUTER JOIN PR_EmployeeIncome
        LEFT OUTER JOIN PR_SocialInsurance
            ON PR_EmployeeIncome.SocialInsuranceRoleId = PR_SocialInsurance.SocialInsuranceRoleId
        ON PR_Employee.EmployeeId = PR_EmployeeIncome.EmployeeId
    LEFT OUTER JOIN PR_Income
        ON PR_EmployeeIncome.IncomeId = PR_Income.IncomeId
    LEFT JOIN Acc_Currency
        ON PR_EmployeeIncome.IncomeCurrency = Acc_Currency.CurrencyId
    LEFT JOIN dbo.PR_Projects
        ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE (
          @empIds = ''All''
          OR
          (
              @empIds = ''AllInService''
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 0
                  )
          )
          OR
          (
              @empIds = ''AllTerminated''
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 1
                  )
          )
          OR
          (
              @empIds NOT IN ( ''All'', ''AllInService'', ''AllTerminated'' )
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@empIds)
                  )
          )
      )
      AND (@IsArabic = @IsArabic)
      AND IncomeEndDate IS NULL';
DECLARE @LegacyParams NVARCHAR(MAX) = N'@empIds VARCHAR(8000), @IsArabic BIT';
DECLARE @rpt VARCHAR(10) = 'R1', @Case VARCHAR(60), @Params NVARCHAR(400), @Extra NVARCHAR(400), @i INT = 1, @n INT, @sql NVARCHAR(MAX), @cols NVARCHAR(MAX), @clN NVARCHAR(MAX), @clO NVARCHAR(MAX), @smN NVARCHAR(MAX), @smO NVARCHAR(MAX);

DECLARE @empIds VARCHAR(8000), @IsArabic BIT, @EmployeeIds NVARCHAR(MAX), @InServiceFilter NVARCHAR(20);
-- three real employees with open income lines, one of them the security-level-5 employee
DECLARE @Ids3 NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(20)), ',') WITHIN GROUP (ORDER BY EmployeeId) FROM (SELECT DISTINCT TOP 3 EmployeeId FROM PR_EmployeeIncome WHERE IncomeEndDate IS NULL AND EmployeeId IN (4, 9, 10)) x);
SELECT @Ids3 AS Ids3, (SELECT COUNT(*) FROM PR_Employee WHERE EndWork = 1) AS terminatedEmployees, (SELECT COUNT(*) FROM PR_EmployeeIncome WHERE IncomeEndDate IS NULL) AS openIncomeLines;
CREATE TABLE #map (newName SYSNAME COLLATE DATABASE_DEFAULT, oldName SYSNAME COLLATE DATABASE_DEFAULT);
CREATE TABLE #money (newName SYSNAME COLLATE DATABASE_DEFAULT);
INSERT #money VALUES ('IncomeAmount'), ('EmployeeInsuranceAmount'), ('CompanyInsuranceAmount');
SELECT TOP 0 * INTO #new FROM dbo.PR_EmployeesSalariesItemsReport(NULL, NULL, 0);
CREATE TABLE #cases (i INT, c VARCHAR(60), empIds VARCHAR(8000), isAr BIT, ids NVARCHAR(MAX), flt NVARCHAR(20));
INSERT #cases VALUES
 (1, 'a1 All, en',            'All',           0, NULL,  NULL),
 (2, 'a2 All, ar',            'All',           1, NULL,  NULL),
 (3, 'a3 All via filter All', 'All',           0, NULL,  'All'),
 (4, 'b1 AllInService, en',   'AllInService',  0, NULL,  'AllInService'),
 (5, 'b2 AllInService, ar',   'AllInService',  1, NULL,  'AllInService'),
 (6, 'c1 AllTerminated, en',  'AllTerminated', 0, NULL,  'AllTerminated'),
 (7, 'c2 AllTerminated, ar',  'AllTerminated', 1, NULL,  'AllTerminated'),
 (8, 'd1 3 ids, en',          @Ids3,           0, @Ids3, NULL),
 (9, 'd2 3 ids, ar',          @Ids3,           1, @Ids3, NULL);

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
    SELECT @Case = c, @empIds = empIds, @IsArabic = isAr, @EmployeeIds = ids, @InServiceFilter = flt FROM #cases WHERE i = @i;
    SET @Params = CONCAT('legacy(@empIds=', @empIds, ', @IsArabic=', @IsArabic, ') new(', ISNULL(@EmployeeIds, 'NULL'), ', ', ISNULL(@InServiceFilter, 'NULL'), ', ', @IsArabic, ')');
    SET @Extra = NULL;
    TRUNCATE TABLE #old; TRUNCATE TABLE #new;
    INSERT #old EXEC sp_executesql @Legacy, @LegacyParams, @empIds = @empIds, @IsArabic = @IsArabic;
    INSERT #new SELECT * FROM dbo.PR_EmployeesSalariesItemsReport(@EmployeeIds, @InServiceFilter, @IsArabic);

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
