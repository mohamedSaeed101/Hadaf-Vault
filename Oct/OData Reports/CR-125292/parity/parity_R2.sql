-- CR 125292 P4 parity, R2 Employee Summarized Salaries: legacy rptEmployeeSalaryDetails vs TVFs PR_EmployeeSummarizedSalariesReport + ...Lines. Read-only: temp tables and variables only.
SET NOCOUNT ON;
-- Legacy base SELECTs, verbatim from AccFlex_ERP origin/Master_Stable HRManagement/Payroll.Reports/Accounting/Salary/dsSalary.xsd
DECLARE @LegacyBase NVARCHAR(MAX) = N'SELECT  PR_Salaries.SalaryId ,
        PR_Salaries.SalaryMainId ,
        PR_Salaries.EmployeeId ,
        PR_Salaries.Suspend ,
        PR_Salaries.Total ,
        PR_Salaries.Remarks ,
        PR_Salaries.InsuranceCompany ,
        PR_Salaries.Posted ,
        PR_Salaries.TotalAdditions ,
        PR_Salaries.TotalDeductions ,
        PR_Salaries.CurrencyId ,
        PR_Salaries.PostDate ,
        Acc_Currencies.CurrencyName ,
        PR_Job.JobName ,
        dbo.PR_EmployeeGroup.EmployeeGroupName AS CategoryName ,
        dbo.PR_EmployeeGroup.EmployeeGroupNameSecondLanguage AS CategoryNameSecondLanguage ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EduDegreeId ,
        PR_Employee.GenderId ,
        PR_Employee.JobId ,
        PR_Employee.MaritalStatusId ,
        PR_Employee.BranchId ,
        PR_Employee.DepartmentId ,
        PR_Employee.DateOfBirth ,
        PR_Employee.BankAccountNum ,
        PR_Employee.InsuranceNum ,
        PR_Employee.DateOfWork ,
        PR_Employee.GraduationDate ,
        PR_Employee.EndWorkingDate ,
        PR_Employee.EmployeeDegree ,
        PR_Employee.Address ,
        PR_Employee.IDNumber ,
        PR_Employee.PerImage ,
        PR_Employee.Telephone ,
        PR_Employee.Mobile ,
        PR_Employee.VacationDays ,
        PR_Employee.Remarks ,
        PR_Employee.IncentivesPolicyId ,
        PR_Employee.OverTimePolicyId ,
        PR_Employee.LatenessPolicyId ,
        PR_Employee.AbsencePolicyId ,
        PR_Employee.EarlyQuitPolicyId ,
        PR_Employee.BankId ,
        PR_Employee.SalaryPerAttend ,
        PR_Employee.DeductionLimit ,
        PR_Employee.DeductionLimit AS PurchaseLimit,
        PR_Employee.PenaltyLimit ,
        PR_Employee.AdvanceLimit ,
        PR_Employee.MedicalInsurance ,
        PR_Employee.MedicalInsuranceValue ,
        PR_Employee.FridayWork ,
        PR_Employee.SaturdayWork ,
        PR_Employee.SundayWork ,
        PR_Employee.MondayWork ,
        PR_Employee.TuesdayWork ,
        PR_Employee.WednesdayWork ,
        PR_Employee.ThursdayWork ,
        PR_Employee.SearchName ,
        PR_Employee.EndWork ,
        PR_Employee.NationalityId ,
        PR_Employee.Email ,
        PR_Employee.CostCenterId ,
        PR_Employee.AccountId ,
        PR_Employee.ManagerId ,
        PR_Employee.OfficalHolidaysBalance ,
        PR_Employee.EmployeeArabicName ,
        PR_Employee.OfficailVacationDays ,
        PR_Employee.VacationRuleTypeId ,
        PR_Employee.InningsVacationId ,
        PR_Employee.InningsVacationBalance ,
        PR_Employee.FingerPrintCode ,
        PR_Employee.RelegionId ,
        PR_Employee.EmployeeNumber ,
        PR_Employee.Age ,
        PR_Employee.JobGrade ,
        PR_Employee.Bonus ,
        PR_Employee.Disapility ,
        PR_Employee.ChronicDisease ,
        PR_Employee.IDPlaceOfExtraction ,
        PR_Employee.CanUseComputer ,
        PR_Employee.IncomeTaxId ,
        PR_Employee.EndServicePolicyId ,
        PR_Employee.VacationWorkPolicyId ,
        PR_Employee.EmployeeSecurityLevel ,
        PR_Employee.AnnualVacationSystemId ,
        PR_Employee.AttachmentGuidNumber ,
        PR_Employee.UserGuidNumber ,
        PR_Employee.WorkDate ,
        PR_Employee.IsCompanyPayEmployeeTax ,
        PR_Employee.EmployeeGroupId ,
        PR_Employee.LeavePermissionPolicyId ,
        PR_Employee.SocialInsuranceStartDate ,
        PR_Employee.DefaultProjectId ,
        PR_Projects.ProjectName ,
        empManger.EmployeeName AS MangerName ,
        PR_EduDegree.EduDegreeName ,
        PR_Department.DepartmentName ,
        PR_Branch.BranchName ,
        ( SELECT    STUFF(( SELECT  '' ,  '' + QualifationName
                            FROM    dbo.Pr_Qualifications
                                    LEFT JOIN dbo.PR_Employee AS emp ON emp.EmployeeId = Pr_Qualifications.EmployeeId
                            WHERE   emp.EmployeeId = PR_Employee.EmployeeId
                          FOR
                            XML PATH('''')
                          ), 1, 2, '''')
        ) AS Qualifations ,
        ROW_NUMBER() OVER ( PARTITION BY PR_Salaries.SalaryMainId ORDER BY empManger.EmployeeId ) AS roeNum
FROM    PR_Salaries
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN PR_Job ON PR_Employee.JobId = PR_Job.JobId
        LEFT OUTER JOIN Acc_Currencies ON PR_Salaries.CurrencyId = Acc_Currencies.CurrencyId
        LEFT OUTER JOIN dbo.PR_EmployeeGroup ON PR_EmployeeGroup.EmployeeGroupId = PR_Employee.EmployeeGroupId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Employee AS empManger ON empManger.EmployeeId = PR_Employee.ManagerId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_EduDegree ON PR_EduDegree.EduDegreeId = PR_Employee.EduDegreeId';
DECLARE @LegacyDetailBase NVARCHAR(MAX) = N'SELECT        PR_SalaryDetail.SalaryDetailId, PR_SalaryDetail.SalaryId, PR_SalaryDetail.EmployeeIncomeId, PR_SalaryDetail.IncomeAmount, PR_SalaryDetail.Suspend, 
                         PR_Income.IncomeName, PR_Income.Deduction
FROM            PR_SalaryDetail INNER JOIN
                         PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId LEFT OUTER JOIN
                         PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                         LEFT JOIN PR_Salaries ON PR_Salaries.SalaryId = PR_SalaryDetail.SalaryId
WHERE        PR_SalaryDetail.IncomeAmount > 0';
DECLARE @Month INT, @Year INT, @SecurityLevel INT, @EmployeeIds NVARCHAR(MAX), @LegacyIds NVARCHAR(MAX), @Case VARCHAR(40), @i INT = 1, @sql NVARCHAR(MAX), @cols NVARCHAR(MAX);
-- legacy "no selection" = every employee of the picker: GET Employee/false/WorkingDate/{today} -> HiringDate(DateOfWork) <= today end-of-day
DECLARE @AllPickerIds NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY EmployeeId) FROM PR_Employee WHERE DateOfWork <= '2026-10-14T23:59:59');
DECLARE @M8Ids NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(MAX)), ',') FROM (SELECT DISTINCT TOP 3 s.EmployeeId FROM PR_Salaries s JOIN PR_SalaryMain m ON m.SalaryMainId=s.SalaryMainId WHERE m.SalaryYear=2026 AND m.SalaryMonth=8 AND m.IsDeleted=0 ORDER BY s.EmployeeId) x);
DECLARE @M5Ids NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(MAX)), ',') FROM (SELECT DISTINCT TOP 3 s.EmployeeId FROM PR_Salaries s JOIN PR_SalaryMain m ON m.SalaryMainId=s.SalaryMainId WHERE m.SalaryYear=2026 AND m.SalaryMonth=5 AND m.IsDeleted=0 AND s.Posted=1 ORDER BY s.EmployeeId) x);
SELECT LEN(@AllPickerIds) AS AllPickerCsvLen, @M8Ids AS M8Ids, @M5Ids AS M5Ids;
CREATE TABLE #cases (i INT, c VARCHAR(40), y INT, m INT, lvl INT, ids NVARCHAR(MAX), legacyIds NVARCHAR(MAX));
INSERT #cases VALUES (1,'a: 2026-08 all',2026,8,5,NULL,@AllPickerIds),(2,'b: 2026-05 all',2026,5,5,NULL,@AllPickerIds),(3,'c: 2026-08 3 ids',2026,8,5,@M8Ids,@M8Ids),(4,'d: 2026-05 3 posted ids',2026,5,5,@M5Ids,@M5Ids);
-- #oldraw: same shape as the legacy result set (duplicate names EmployeeId/Remarks get an ordinal suffix)
CREATE TABLE #oldraw (dummy_ INT);
SET @sql = @LegacyBase;
SELECT @cols = STRING_AGG(CAST(QUOTENAME(name + CASE WHEN rn > 1 THEN '_' + CAST(column_ordinal AS VARCHAR(5)) ELSE '' END) + ' ' + system_type_name + ' NULL' AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY column_ordinal)
FROM (SELECT name, column_ordinal, system_type_name, ROW_NUMBER() OVER (PARTITION BY name ORDER BY column_ordinal) rn FROM sys.dm_exec_describe_first_result_set(@sql, NULL, 0)) d;
EXEC (N'ALTER TABLE #oldraw ADD ' + @cols); ALTER TABLE #oldraw DROP COLUMN dummy_;
CREATE TABLE #res (rpt VARCHAR(20), c VARCHAR(40), oldRows INT, newRows INT, oldMinusNew INT, newMinusOld INT, grpDiff INT, dupSalaryIdOld INT, sumsOld NVARCHAR(200), sumsNew NVARCHAR(200));
-- #oldlinesraw typed from the legacy detail SELECT itself
CREATE TABLE #oldlinesraw (dummy_ INT);
SET @sql = @LegacyDetailBase;
SELECT @cols = STRING_AGG(CAST(QUOTENAME(name) + ' ' + system_type_name + ' NULL' AS NVARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY column_ordinal) FROM sys.dm_exec_describe_first_result_set(@sql, NULL, 0);
EXEC (N'ALTER TABLE #oldlinesraw ADD ' + @cols); ALTER TABLE #oldlinesraw DROP COLUMN dummy_;
DECLARE @salaryIds NVARCHAR(MAX), @detailQuery NVARCHAR(MAX);
WHILE @i <= 4
BEGIN
    SELECT @Case = c, @Year = y, @Month = m, @SecurityLevel = lvl, @EmployeeIds = ids, @LegacyIds = legacyIds FROM #cases WHERE i = @i;
    TRUNCATE TABLE #oldraw; TRUNCATE TABLE #oldlinesraw;
    -- legacy rptEmployeeSalaryDetails_BeforePrint, header: verbatim string.Format clause via FillByWhere; empty ids -> Fill()
    IF ISNULL(@LegacyIds, '') <> ''
        SET @sql = @LegacyBase + REPLACE(REPLACE(REPLACE(N' INNER JOIN PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId Where PR_Salaries.EmployeeId IN ({0}) AND PR_SalaryMain.IsDeleted = 0 AND PR_SalaryMain.SalaryYear = {1} AND PR_SalaryMain.SalaryMonth = {2} AND Posted = 1 ', N'{0}', @LegacyIds), N'{1}', CAST(@Year AS NVARCHAR(10))), N'{2}', CAST(@Month AS NVARCHAR(10)));
    ELSE
        SET @sql = @LegacyBase;
    INSERT #oldraw EXEC (@sql);
    DROP TABLE IF EXISTS #old; DROP TABLE IF EXISTS #new; DROP TABLE IF EXISTS #oldlines; DROP TABLE IF EXISTS #newlines;
    SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total INTO #old FROM #oldraw;
    -- legacy lines: salaryIds = string.Join of header SalaryIds; detailQuery = AND ... IN (...) or empty when no header rows
    SET @salaryIds = ISNULL((SELECT STRING_AGG(CAST(SalaryId AS NVARCHAR(MAX)), ',') FROM #old), N'');
    SET @detailQuery = CASE WHEN @salaryIds <> N'' THEN REPLACE(N' AND PR_SalaryDetail.SalaryId IN ({0})', N'{0}', @salaryIds) ELSE N'' END;
    SET @sql = @LegacyDetailBase + @detailQuery;
    INSERT #oldlinesraw EXEC (@sql);
    -- printed lines = nested band via relation FK_PR_SalaryDetail_PR_Salaries (only lines of printed headers)
    SELECT l.* INTO #oldlines FROM #oldlinesraw l WHERE l.SalaryId IN (SELECT SalaryId FROM #old);

    -- new header: PR_EmployeeSummarizedSalariesReport body (origin/cr125292), verbatim, INTO #new
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_Salaries.SalaryId ) AS RowNo ,
            PR_Salaries.SalaryId ,
            PR_Salaries.SalaryMainId ,
            PR_Salaries.EmployeeId ,
            PR_Employee.EmployeeNumber ,
            PR_Employee.EmployeeName ,
            PR_Employee.EmployeeArabicName ,
            PR_Job.JobName ,
            PR_Salaries.CurrencyId ,
            Acc_Currencies.CurrencyName ,
            PR_SalaryMain.SalaryMonth ,
            PR_SalaryMain.SalaryYear ,
            PR_Salaries.TotalAdditions ,
            PR_Salaries.TotalDeductions ,
            PR_Salaries.Total
    INTO #new
    FROM    PR_Salaries
            INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
            LEFT OUTER JOIN PR_Job ON PR_Employee.JobId = PR_Job.JobId
            LEFT OUTER JOIN Acc_Currencies ON PR_Salaries.CurrencyId = Acc_Currencies.CurrencyId
            LEFT OUTER JOIN dbo.PR_EmployeeGroup ON PR_EmployeeGroup.EmployeeGroupId = PR_Employee.EmployeeGroupId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
            LEFT JOIN dbo.PR_Employee AS empManger ON empManger.EmployeeId = PR_Employee.ManagerId
            LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_EduDegree ON PR_EduDegree.EduDegreeId = PR_Employee.EduDegreeId
            INNER JOIN PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    WHERE   ( ISNULL(@EmployeeIds, '') = ''
              OR PR_Salaries.EmployeeId IN (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
            )
            AND PR_SalaryMain.IsDeleted = 0
            AND PR_SalaryMain.SalaryYear = @Year
            AND PR_SalaryMain.SalaryMonth = @Month
            AND PR_Salaries.Posted = 1
            AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel;

    -- new lines: PR_EmployeeSummarizedSalariesReportLines body verbatim; its call to the header TVF (not deployed on this DB) is replaced by #new = that TVF body for the same params
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_SalaryDetail.SalaryId, PR_SalaryDetail.SalaryDetailId ) AS RowNo ,
            PR_SalaryDetail.SalaryDetailId ,
            PR_SalaryDetail.SalaryId ,
            PR_SalaryDetail.EmployeeIncomeId ,
            PR_SalaryDetail.IncomeAmount ,
            PR_SalaryDetail.Suspend ,
            PR_Income.IncomeName ,
            PR_Income.Deduction
    INTO #newlines
    FROM    PR_SalaryDetail
            INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
            LEFT OUTER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
            LEFT JOIN PR_Salaries ON PR_Salaries.SalaryId = PR_SalaryDetail.SalaryId
    WHERE   PR_SalaryDetail.IncomeAmount > 0
            AND PR_SalaryDetail.SalaryId IN (
                SELECT SalaryId
                FROM   #new );

    INSERT #res (rpt, c, oldRows, newRows, oldMinusNew, newMinusOld, grpDiff, dupSalaryIdOld, sumsOld, sumsNew)
    SELECT 'R2-hdr', @Case, (SELECT COUNT(*) FROM #old), (SELECT COUNT(*) FROM #new),
        (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #new) x),
        (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #old) x),
        (SELECT COUNT(*) FROM ((SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total, COUNT(*) n FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total, COUNT(*) FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total)
            UNION ALL (SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total, COUNT(*) n FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total, COUNT(*) FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total)) x),
        (SELECT COUNT(*) - COUNT(DISTINCT SalaryId) FROM #old),
        (SELECT CONCAT(CAST(SUM(TotalAdditions) AS DECIMAL(38,6)),'/',CAST(SUM(TotalDeductions) AS DECIMAL(38,6)),'/',CAST(SUM(Total) AS DECIMAL(38,6))) FROM #old), (SELECT CONCAT(CAST(SUM(TotalAdditions) AS DECIMAL(38,6)),'/',CAST(SUM(TotalDeductions) AS DECIMAL(38,6)),'/',CAST(SUM(Total) AS DECIMAL(38,6))) FROM #new);
    IF EXISTS (SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #new)
        SELECT TOP 10 'R2-hdr old-new' AS diff, @Case AS c, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #new) x;
    IF EXISTS (SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #old)
        SELECT TOP 10 'R2-hdr new-old' AS diff, @Case AS c, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, EmployeeNumber, EmployeeName, JobName, CurrencyId, CurrencyName, TotalAdditions, TotalDeductions, Total FROM #old) x;
    INSERT #res (rpt, c, oldRows, newRows, oldMinusNew, newMinusOld, grpDiff, dupSalaryIdOld, sumsOld, sumsNew)
    SELECT 'R2-lines', @Case, (SELECT COUNT(*) FROM #oldlines), (SELECT COUNT(*) FROM #newlines),
        (SELECT COUNT(*) FROM (SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #oldlines EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #newlines) x),
        (SELECT COUNT(*) FROM (SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #newlines EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #oldlines) x),
        (SELECT COUNT(*) FROM ((SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction, COUNT(*) n FROM #oldlines GROUP BY SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction, COUNT(*) FROM #newlines GROUP BY SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction)
            UNION ALL (SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction, COUNT(*) n FROM #newlines GROUP BY SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction, COUNT(*) FROM #oldlines GROUP BY SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction)) x),
        (SELECT COUNT(*) - COUNT(DISTINCT SalaryDetailId) FROM #oldlines),
        (SELECT CONCAT(CAST(SUM(IncomeAmount) AS DECIMAL(38,6)),'') FROM #oldlines), (SELECT CONCAT(CAST(SUM(IncomeAmount) AS DECIMAL(38,6)),'') FROM #newlines);
    IF EXISTS (SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #oldlines EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #newlines)
        SELECT TOP 10 'R2-lines old-new' AS diff, @Case AS c, * FROM (SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #oldlines EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #newlines) x;
    IF EXISTS (SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #newlines EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #oldlines)
        SELECT TOP 10 'R2-lines new-old' AS diff, @Case AS c, * FROM (SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #newlines EXCEPT SELECT SalaryDetailId, SalaryId, EmployeeIncomeId, IncomeAmount, Suspend, IncomeName, Deduction FROM #oldlines) x;
    INSERT #res (rpt, c, oldRows) SELECT 'R2-lines-raw', @Case, (SELECT COUNT(*) FROM #oldlinesraw);
    SET @i += 1;
END
SELECT rpt, c, oldRows, newRows, oldMinusNew, newMinusOld, grpDiff, dupSalaryIdOld AS dupKeyOld, sumsOld, sumsNew,
       CASE WHEN rpt LIKE '%raw' THEN 'info' WHEN oldRows = newRows AND oldMinusNew = 0 AND newMinusOld = 0 AND grpDiff = 0 AND ISNULL(sumsOld,'') = ISNULL(sumsNew,'') THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM #res ORDER BY c, rpt;
