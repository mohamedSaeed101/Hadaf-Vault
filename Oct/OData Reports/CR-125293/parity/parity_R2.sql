-- CR 125293 parity, R2: legacy Salaries (dsSalariesReport.xsd) vs TVF dbo.PR_PayCheckReport on UNP-Ali. Read-only: temp tables and variables only.
-- Legacy SQL = legacy_r2.sql (verbatim), run through sp_executesql with the TableAdapter parameter types.
SET NOCOUNT ON;
DECLARE @Legacy NVARCHAR(MAX) = N'SELECT  Pr_PayingSalariesDetail.EmployeeSalary ,
        Acc_Currency.CurrencyName ,
        Acc_Currency.CurrencyNameArabic ,
        EmployeeName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_Projects.ProjectName ,
        PR_Job.JobName ,
        EmployeeNumber ,
        BankName,
		EmployeeArabicName
FROM    dbo.Pr_PayingSalariesDetail
		LEFT JOIN dbo.Pr_PayingSalaries ON Pr_PayingSalaries.PayingSalariesId = Pr_PayingSalariesDetail.PayingSalariesId
        INNER JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = Pr_PayingSalaries.CurrencyId
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = Pr_PayingSalariesDetail.EmployeeId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Bank ON PR_Bank.BankId = Pr_PayingSalaries.BankId
WHERE    PayingSalariesMonth = @MONTH
        AND PayingSalaryYear = @YEAR
        AND ( @EmployeeId IS NULL
              OR ( Pr_PayingSalariesDetail.EmployeeId IN (
                   SELECT   number
                   FROM     dbo.Acc_ConvertIntListToTable(@EmployeeId) ) )
            )
        AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
        AND ( @BankList IS NULL
              OR Pr_PayingSalaries.BankId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@BankList) )
            ) ORDER BY PR_Employee.EmployeeId';
DECLARE @LegacyParams NVARCHAR(MAX) = N'@MONTH INT, @YEAR INT, @EmployeeId NVARCHAR(MAX), @EmployeeSecurityLevel INT, @BankList NVARCHAR(MAX)';
DECLARE @rpt VARCHAR(10) = 'R2', @Case VARCHAR(60), @Params NVARCHAR(400), @Extra NVARCHAR(400), @i INT = 1, @n INT, @sql NVARCHAR(MAX), @cols NVARCHAR(MAX), @clN NVARCHAR(MAX), @clO NVARCHAR(MAX), @smN NVARCHAR(MAX), @smO NVARCHAR(MAX);

DECLARE @Month INT, @Year INT, @EmployeeIds NVARCHAR(MAX), @BankIds NVARCHAR(MAX), @Lvl INT;
-- busiest pay month
SELECT TOP 1 @Year = p.PayingSalaryYear, @Month = p.PayingSalariesMonth FROM Pr_PayingSalariesDetail d JOIN Pr_PayingSalaries p ON p.PayingSalariesId = d.PayingSalariesId GROUP BY p.PayingSalaryYear, p.PayingSalariesMonth ORDER BY COUNT(*) DESC;
DECLARE @Hi INT = (SELECT MAX(EmployeeSecurityLevel) FROM PR_Employee), @Lo INT = (SELECT MIN(EmployeeSecurityLevel) FROM PR_Employee);
-- 3 employees paid that month, preferring the ones above the low security level
DECLARE @Ids3 NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(20)), ',') WITHIN GROUP (ORDER BY EmployeeId) FROM (SELECT TOP 3 d.EmployeeId FROM Pr_PayingSalariesDetail d JOIN Pr_PayingSalaries p ON p.PayingSalariesId = d.PayingSalariesId JOIN PR_Employee e ON e.EmployeeId = d.EmployeeId WHERE p.PayingSalaryYear = @Year AND p.PayingSalariesMonth = @Month GROUP BY d.EmployeeId ORDER BY MAX(e.EmployeeSecurityLevel) DESC, d.EmployeeId) x);
DECLARE @Bank1 NVARCHAR(20) = (SELECT TOP 1 CAST(p.BankId AS NVARCHAR(20)) FROM Pr_PayingSalaries p WHERE p.PayingSalaryYear = @Year AND p.PayingSalariesMonth = @Month GROUP BY p.BankId ORDER BY COUNT(*) DESC);
DECLARE @BankNone NVARCHAR(20) = (SELECT TOP 1 CAST(BankId AS NVARCHAR(20)) FROM PR_Bank WHERE BankId NOT IN (SELECT ISNULL(BankId, -1) FROM Pr_PayingSalaries WHERE PayingSalaryYear = @Year AND PayingSalariesMonth = @Month) ORDER BY BankId);
SELECT @Year AS yr, @Month AS mo, @Hi AS hiLvl, @Lo AS loLvl, @Ids3 AS Ids3, @Bank1 AS bankWithRows, @BankNone AS bankWithoutRows,
       (SELECT COUNT(*) FROM Pr_PayingSalaries WHERE PayingSalaryYear = @Year AND PayingSalariesMonth = @Month) AS headers,
       (SELECT COUNT(*) FROM Pr_PayingSalaries WHERE PayingSalaryYear = @Year AND PayingSalariesMonth = @Month AND IsPaid = 0) AS unpaidHeaders,
       (SELECT COUNT(*) FROM Pr_PayingSalaries WHERE IsPaid = 0) AS unpaidHeadersAnyMonth;
CREATE TABLE #map (newName SYSNAME COLLATE DATABASE_DEFAULT, oldName SYSNAME COLLATE DATABASE_DEFAULT);
CREATE TABLE #money (newName SYSNAME COLLATE DATABASE_DEFAULT);
INSERT #money VALUES ('EmployeeSalary');
SELECT TOP 0 * INTO #new FROM dbo.PR_PayCheckReport(1, 1, NULL, NULL, NULL, 0);
CREATE TABLE #cases (i INT, c VARCHAR(60), ids NVARCHAR(MAX), banks NVARCHAR(MAX), lvl INT);
INSERT #cases VALUES
 (1, 'a1 all, hi lvl',                     NULL,  NULL,                       @Hi),
 (2, 'a2 all, lo lvl',                     NULL,  NULL,                       @Lo),
 (3, 'b1 3 ids + bank, hi lvl',            @Ids3, @Bank1,                     @Hi),
 (4, 'b2 3 ids + bank, lo lvl',            @Ids3, @Bank1,                     @Lo),
 (5, 'c1 all + 2-bank list, hi lvl',       NULL,  @Bank1 + ',' + @BankNone,   @Hi),
 (6, 'c2 bank without rows, hi lvl',       NULL,  @BankNone,                  @Hi);

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

CREATE TABLE #fix (c VARCHAR(60), nullRows INT, paidRows INT, unpaidRows INT, paidPlusUnpaidMinusNull INT, nullMinusPaidPlusUnpaid INT, paidSubsetWrongFlag INT, unpaidSubsetWrongFlag INT, paidRowsInNull INT, unpaidRowsInNull INT, sumNull DECIMAL(38,6), sumPaidPlusUnpaid DECIMAL(38,6));
SELECT TOP 0 * INTO #p1 FROM #new; SELECT TOP 0 * INTO #p0 FROM #new;
SELECT @n = MAX(i) FROM #cases;
WHILE @i <= @n
BEGIN
    SELECT @Case = c, @EmployeeIds = ids, @BankIds = banks, @Lvl = lvl FROM #cases WHERE i = @i;
    SET @Params = CONCAT(@Month, '/', @Year, ' ids=', ISNULL(@EmployeeIds, 'NULL'), ' banks=', ISNULL(@BankIds, 'NULL'), ' lvl=', @Lvl, ' new IsPaid=NULL');
    SET @Extra = NULL;
    TRUNCATE TABLE #old; TRUNCATE TABLE #new; TRUNCATE TABLE #p1; TRUNCATE TABLE #p0;
    INSERT #old EXEC sp_executesql @Legacy, @LegacyParams, @MONTH = @Month, @YEAR = @Year, @EmployeeId = @EmployeeIds, @EmployeeSecurityLevel = @Lvl, @BankList = @BankIds;
    INSERT #new SELECT * FROM dbo.PR_PayCheckReport(@Month, @Year, @EmployeeIds, @BankIds, NULL, @Lvl);

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

    -- approved Fix: IsPaid filter. IsPaid=1 rows + IsPaid=0 rows must equal the IsPaid NULL result (as a multiset, RowNo excluded)
    INSERT #p1 SELECT * FROM dbo.PR_PayCheckReport(@Month, @Year, @EmployeeIds, @BankIds, 1, @Lvl);
    INSERT #p0 SELECT * FROM dbo.PR_PayCheckReport(@Month, @Year, @EmployeeIds, @BankIds, 0, @Lvl);
    SET @sql = N'INSERT #fix SELECT @c, (SELECT COUNT(*) FROM #new), (SELECT COUNT(*) FROM #p1), (SELECT COUNT(*) FROM #p0),
        (SELECT COUNT(*) FROM (SELECT ' + @clN + N', IsPaid, COUNT(*) n FROM (SELECT * FROM #p1 UNION ALL SELECT * FROM #p0) u GROUP BY ' + @clN + N', IsPaid
                               EXCEPT SELECT ' + @clN + N', IsPaid, COUNT(*) FROM #new GROUP BY ' + @clN + N', IsPaid) x),
        (SELECT COUNT(*) FROM (SELECT ' + @clN + N', IsPaid, COUNT(*) n FROM #new GROUP BY ' + @clN + N', IsPaid
                               EXCEPT SELECT ' + @clN + N', IsPaid, COUNT(*) FROM (SELECT * FROM #p1 UNION ALL SELECT * FROM #p0) u GROUP BY ' + @clN + N', IsPaid) x),
        (SELECT COUNT(*) FROM #p1 WHERE ISNULL(IsPaid, 0) <> 1), (SELECT COUNT(*) FROM #p0 WHERE ISNULL(IsPaid, 1) <> 0),
        (SELECT COUNT(*) FROM #new WHERE IsPaid = 1), (SELECT COUNT(*) FROM #new WHERE IsPaid = 0),
        (SELECT SUM(CAST(EmployeeSalary AS DECIMAL(38,6))) FROM #new), (SELECT SUM(CAST(EmployeeSalary AS DECIMAL(38,6))) FROM (SELECT EmployeeSalary FROM #p1 UNION ALL SELECT EmployeeSalary FROM #p0) u);';
    EXEC sp_executesql @sql, N'@c VARCHAR(60)', @Case;
    SET @i += 1;
END

SELECT rpt, c, p, oldRows, newRows, oldMinusNew, newMinusOld, grpDiff, CASE WHEN sumsOld = sumsNew THEN 'yes' ELSE 'NO' END AS sumsEqual, sumsOld, sumsNew, extra,
       CASE WHEN oldRows = newRows AND oldMinusNew = 0 AND newMinusOld = 0 AND grpDiff = 0 AND sumsOld = sumsNew THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM #res ORDER BY c;

SELECT c, nullRows, paidRows, unpaidRows, paidPlusUnpaidMinusNull, nullMinusPaidPlusUnpaid, paidSubsetWrongFlag, unpaidSubsetWrongFlag, paidRowsInNull, unpaidRowsInNull, sumNull, sumPaidPlusUnpaid,
       CASE WHEN paidRows + unpaidRows = nullRows AND paidPlusUnpaidMinusNull = 0 AND nullMinusPaidPlusUnpaid = 0 AND paidSubsetWrongFlag = 0 AND unpaidSubsetWrongFlag = 0
                 AND paidRows = paidRowsInNull AND unpaidRows = unpaidRowsInNull AND ISNULL(sumNull, 0) = ISNULL(sumPaidPlusUnpaid, 0) THEN 'PASS' ELSE 'FAIL' END AS fixVerdict
FROM #fix ORDER BY c;
-- Pr_PayingSalaries.IsPaid as stored, to show the subsets carry the header flag
SELECT p.PayingSalariesId, p.BankId, p.IsPaid, COUNT(d.EmployeeId) detailRows FROM Pr_PayingSalaries p LEFT JOIN Pr_PayingSalariesDetail d ON d.PayingSalariesId = p.PayingSalariesId WHERE p.PayingSalaryYear = @Year AND p.PayingSalariesMonth = @Month GROUP BY p.PayingSalariesId, p.BankId, p.IsPaid;
