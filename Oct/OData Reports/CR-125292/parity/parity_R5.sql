SET NOCOUNT ON;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @IncomeId INT = 3, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = NULL;
DECLARE @typeId INT = 3, @L_employeeIds NVARCHAR(MAX) = NULL, @L_month INT = 8, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/08 grp3 all (legacy NULL)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @IncomeId INT = 3, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = NULL;
DECLARE @typeId INT = 3, @L_employeeIds NVARCHAR(MAX) = (SELECT STUFF((SELECT ',' + CAST(EmployeeId AS varchar(12)) FROM dbo.PR_Employee WHERE DateOfWork <= GETDATE() FOR XML PATH('')),1,1,'')), @L_month INT = 8, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/08 grp3 all (legacy front CSV)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @IncomeId INT = 1, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = NULL;
DECLARE @typeId INT = 1, @L_employeeIds NVARCHAR(MAX) = (SELECT STUFF((SELECT ',' + CAST(EmployeeId AS varchar(12)) FROM dbo.PR_Employee WHERE DateOfWork <= GETDATE() FOR XML PATH('')),1,1,'')), @L_month INT = 8, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/08 grp1 all (legacy front CSV)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @IncomeId INT = 3, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = N'4,9,113';
DECLARE @typeId INT = 3, @L_employeeIds NVARCHAR(MAX) = N'4,9,113', @L_month INT = 8, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/08 grp3 emps 4,9,113' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 7, @Year INT = 2026, @IncomeId INT = 3, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = NULL;
DECLARE @typeId INT = 3, @L_employeeIds NVARCHAR(MAX) = NULL, @L_month INT = 7, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/07 grp3 all (legacy NULL)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 7, @Year INT = 2026, @IncomeId INT = 3, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = NULL;
DECLARE @typeId INT = 3, @L_employeeIds NVARCHAR(MAX) = (SELECT STUFF((SELECT ',' + CAST(EmployeeId AS varchar(12)) FROM dbo.PR_Employee WHERE DateOfWork <= GETDATE() FOR XML PATH('')),1,1,'')), @L_month INT = 7, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/07 grp3 all (legacy front CSV)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 7, @Year INT = 2026, @IncomeId INT = 1, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = NULL;
DECLARE @typeId INT = 1, @L_employeeIds NVARCHAR(MAX) = (SELECT STUFF((SELECT ',' + CAST(EmployeeId AS varchar(12)) FROM dbo.PR_Employee WHERE DateOfWork <= GETDATE() FOR XML PATH('')),1,1,'')), @L_month INT = 7, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/07 grp1 all (legacy front CSV)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 7, @Year INT = 2026, @IncomeId INT = 3, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = N'4,9,113';
DECLARE @typeId INT = 3, @L_employeeIds NVARCHAR(MAX) = N'4,9,113', @L_month INT = 7, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/07 grp3 emps 4,9,113' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 7, @Year INT = 2026, @IncomeId INT = 6, @SecurityLevel INT = 5, @EmployeeIds NVARCHAR(MAX) = N'4,9,113';
DECLARE @typeId INT = 6, @L_employeeIds NVARCHAR(MAX) = N'4,9,113', @L_month INT = 7, @L_year INT = 2026;
    WITH Report
      AS ( SELECT   PR_SalaryDetail.SalaryDetailId ,
                    PR_SalaryDetail.IncomeAmount ,
                    PR_SalaryDetail.Suspend ,
                    PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.EmployeeNumber ,
                    PR_Projects.ProjectName ,
                    PR_Branch.BranchName ,
                    PR_Department.DepartmentName ,
                    PR_IncomeGroup.IncomeTypeId ,
                    PR_Income.IncomeName ,
                    PR_IncomeGroup.IncomeType ,
                    PR_Income.Deduction ,
                    PR_SalaryMain.SalaryMonth ,
                    PR_SalaryMain.SalaryYear
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
                    INNER JOIN dbo.PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                    INNER JOIN dbo.PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                    INNER JOIN dbo.PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
           WHERE    ( PR_IncomeGroup.IncomeTypeId = @IncomeId )
                    AND ( ISNULL(@EmployeeIds, '') = ''
                          OR PR_Employee.EmployeeId IN (
                             SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                        )
                    AND PR_SalaryMain.SalaryMonth = @Month
                    AND PR_SalaryMain.SalaryYear = @Year
                    AND PR_Salaries.Posted = 1
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY Report.EmployeeId, Report.SalaryDetailId ) AS RowNo
           , Report.SalaryDetailId
           , Report.IncomeAmount
           , Report.Suspend
           , Report.EmployeeId
           , Report.EmployeeName
           , Report.EmployeeArabicName
           , Report.EmployeeNumber
           , Report.ProjectName
           , Report.BranchName
           , Report.DepartmentName
           , Report.IncomeTypeId
           , Report.IncomeName
           , Report.IncomeType
           , Report.Deduction
           , Report.SalaryMonth
           , Report.SalaryYear
    INTO #new FROM     Report
;
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
INTO #old
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @L_employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@L_employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @L_month
        AND PR_SalaryMain.SalaryYear = @L_year
        AND PR_Salaries.Posted = 1;

SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear, ROW_NUMBER() OVER (PARTITION BY IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT IncomeAmount, Suspend, EmployeeId, EmployeeName, EmployeeNumber, ProjectName, BranchName, DepartmentName, IncomeTypeId, IncomeName, IncomeType, Deduction, SalaryMonth, SalaryYear FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026/07 grp6 emps 4,9,113' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(IncomeAmount) FROM #old) AS OldSumAmt, (SELECT SUM(IncomeAmount) FROM #new) AS NewSumAmt,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
