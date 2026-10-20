SET NOCOUNT ON;
-- PARITY R4 Employees Salaries In Period (CR 125292 P4): legacy dsEmployeesSalaryBetweenPeriod.xsd FillEnglish/FillArabic (Payroll.Reports, origin/Master_Stable) vs TVF body PR_EmployeesSalariesInPeriodReport from origin/cr125292. Read-only: temp tables only.
-------------------- R4 case a --------------------
DROP TABLE IF EXISTS #old; DROP TABLE IF EXISTS #oldAr; DROP TABLE IF EXISTS #new;
GO
-- legacy batch: raw date-only values from the MVC model binder; shell always sends an explicit CSV
DECLARE @fromDate DATETIME = '2026-04-01', @toDate DATETIME = '2026-08-31', @EmployeeSecurityLevel INT = 5;
DECLARE @employees NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS nvarchar(max)), ',') FROM dbo.PR_Employee);
SELECT 'a' CaseId, LEN(@employees) LegacyCsvLen;
                    


   SELECT   PR_Salaries.* ,
            EmployeeName ,
            EmployeeNumber ,
            DateOfWork ,
            BranchName ,
            DepartmentName ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN SalaryMonth = 1
                 THEN 'Jan ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 2
                 THEN 'Feb ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 3
                 THEN 'Mar ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 4
                 THEN 'Apr ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 5
                 THEN 'May ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 6
                 THEN 'Jun ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 7
                 THEN 'Jul ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 8
                 THEN 'Aug ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 9
                 THEN 'Sep ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 10
                 THEN 'Oct ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 11
                 THEN 'Nov ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 12
                 THEN 'Dec ' + CAST(SalaryYear AS VARCHAR(4))
            END AS Mnth
   INTO #old
   FROM     dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
   WHERE    ( @employees IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@employees) )
            )
            AND PeriodFrom BETWEEN @fromDate AND @toDate
            AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND Posted = 1
   ORDER BY PR_Employee.EmployeeId ,
            PeriodFrom;
;
                    
SELECT  PR_Salaries.* ,
        EmployeeName ,
        EmployeeNumber ,
        DateOfWork ,
        BranchName ,
        DepartmentName ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        TaxIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS TaxAmount ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        EmployeeInsuranceIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS InsuranceAmount ,
        CASE WHEN SalaryMonth = 1
             THEN N'يناير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 2
             THEN N'فبراير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 3
             THEN N'مارس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 4
             THEN N'أبريل ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 5
             THEN N'مايو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 6
             THEN N'يونيو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 7
             THEN N'يوليو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 8
             THEN N'أغسطس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 9
             THEN N'سبتمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 10
             THEN N'أكتوبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 11
             THEN N'نوفمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 12
             THEN N'ديسمبر ' + CAST(SalaryYear AS VARCHAR(4))
        END AS Mnth
INTO #oldAr
FROM    dbo.PR_Salaries
        INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   ( @employees IS NULL
          OR PR_Employee.EmployeeId IN (
          SELECT    *
          FROM      dbo.Acc_ConvertIntListToTable(@employees) )
        )
        AND PeriodFrom BETWEEN @fromDate AND @toDate
        AND Posted = 1
        AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
ORDER BY PR_Employee.EmployeeId ,
        PeriodFrom;
;
GO
-- new batch: API passes from = start of day, to = end of day
DECLARE @FromDate DATETIME = '2026-04-01T00:00:00', @ToDate DATETIME = '2026-08-31T23:59:59.997', @SecurityLevel INT = 5;
DECLARE @EmployeeIds NVARCHAR(MAX) = NULL;
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_Employee.EmployeeId, PR_SalaryMain.PeriodFrom, PR_Salaries.SalaryId ) AS RowNo ,
            PR_Salaries.SalaryId ,
            PR_Salaries.SalaryMainId ,
            PR_Salaries.EmployeeId ,
            PR_Employee.EmployeeName ,
            PR_Employee.EmployeeArabicName ,
            PR_Employee.EmployeeNumber ,
            PR_Employee.DateOfWork ,
            PR_Branch.BranchName ,
            PR_Department.DepartmentName ,
            PR_Salaries.CurrencyId ,
            PR_SalaryMain.PeriodFrom ,
            PR_SalaryMain.SalaryMonth ,
            PR_SalaryMain.SalaryYear ,
            PR_Salaries.InsuranceCompany ,
            PR_Salaries.BasicSalary ,
            PR_Salaries.TotalAdditions ,
            PR_Salaries.TotalDeductions ,
            PR_Salaries.TotalTax ,
            PR_Salaries.Total ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN 'Jan ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN 'Feb ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN 'Mar ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN 'Apr ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN 'May ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN 'Jun ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN 'Jul ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN 'Aug ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN 'Sep ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN 'Oct ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN 'Nov ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN 'Dec ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS Mnth ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN N'يناير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN N'فبراير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN N'مارس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN N'أبريل ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN N'مايو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN N'يونيو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN N'يوليو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN N'أغسطس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN N'سبتمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN N'أكتوبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN N'نوفمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN N'ديسمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS MnthArabic
    INTO #new
    FROM    dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    WHERE   ( ISNULL(@EmployeeIds, '') = ''
              OR PR_Employee.EmployeeId IN (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
            )
            AND PR_SalaryMain.PeriodFrom BETWEEN @FromDate AND @ToDate
            AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
            AND PR_Salaries.Posted = 1
;
SELECT 'R4-a' AS CaseId, 'salary' AS Part,
  (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #old) OldMainSal_InsCo, (SELECT SUM(InsuranceCompany) FROM #new) NewMainSal_InsCo, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(InsuranceAmount) FROM #old) OldIns, (SELECT SUM(InsuranceAmount) FROM #new) NewIns, (SELECT SUM(TaxAmount) FROM #old) OldTax, (SELECT SUM(TaxAmount) FROM #new) NewTax, (SELECT SUM(Total) FROM #old) OldTotal, (SELECT SUM(Total) FROM #new) NewTotal, (SELECT COUNT(DISTINCT EmployeeId) FROM #new) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x;
SELECT 'a' CaseId, 'arabic-month' Part, (SELECT COUNT(*) FROM (SELECT SalaryId, Mnth FROM #oldAr EXCEPT SELECT SalaryId, MnthArabic FROM #new) x) OldArMinusNew, (SELECT COUNT(*) FROM (SELECT SalaryId, MnthArabic FROM #new EXCEPT SELECT SalaryId, Mnth FROM #oldAr) x) NewMinusOldAr;
SELECT 'a' CaseId, 'order' Part, COUNT(*) OrderMismatch FROM (SELECT o.SalaryId, ROW_NUMBER() OVER (ORDER BY o.EmployeeId, p.PeriodFrom, o.SalaryId) rn FROM #old o JOIN dbo.PR_SalaryMain p ON p.SalaryMainId = o.SalaryMainId) o JOIN #new n ON n.SalaryId = o.SalaryId WHERE n.RowNo <> o.rn;
GO
-------------------- R4 case a-null --------------------
DROP TABLE IF EXISTS #old; DROP TABLE IF EXISTS #oldAr; DROP TABLE IF EXISTS #new;
GO
-- legacy batch: raw date-only values from the MVC model binder; shell always sends an explicit CSV
DECLARE @fromDate DATETIME = '2026-04-01', @toDate DATETIME = '2026-08-31', @EmployeeSecurityLevel INT = 5;
DECLARE @employees NVARCHAR(MAX) = NULL;
SELECT 'a-null' CaseId, LEN(@employees) LegacyCsvLen;
                    


   SELECT   PR_Salaries.* ,
            EmployeeName ,
            EmployeeNumber ,
            DateOfWork ,
            BranchName ,
            DepartmentName ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN SalaryMonth = 1
                 THEN 'Jan ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 2
                 THEN 'Feb ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 3
                 THEN 'Mar ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 4
                 THEN 'Apr ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 5
                 THEN 'May ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 6
                 THEN 'Jun ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 7
                 THEN 'Jul ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 8
                 THEN 'Aug ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 9
                 THEN 'Sep ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 10
                 THEN 'Oct ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 11
                 THEN 'Nov ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 12
                 THEN 'Dec ' + CAST(SalaryYear AS VARCHAR(4))
            END AS Mnth
   INTO #old
   FROM     dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
   WHERE    ( @employees IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@employees) )
            )
            AND PeriodFrom BETWEEN @fromDate AND @toDate
            AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND Posted = 1
   ORDER BY PR_Employee.EmployeeId ,
            PeriodFrom;
;
                    
SELECT  PR_Salaries.* ,
        EmployeeName ,
        EmployeeNumber ,
        DateOfWork ,
        BranchName ,
        DepartmentName ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        TaxIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS TaxAmount ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        EmployeeInsuranceIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS InsuranceAmount ,
        CASE WHEN SalaryMonth = 1
             THEN N'يناير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 2
             THEN N'فبراير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 3
             THEN N'مارس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 4
             THEN N'أبريل ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 5
             THEN N'مايو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 6
             THEN N'يونيو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 7
             THEN N'يوليو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 8
             THEN N'أغسطس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 9
             THEN N'سبتمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 10
             THEN N'أكتوبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 11
             THEN N'نوفمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 12
             THEN N'ديسمبر ' + CAST(SalaryYear AS VARCHAR(4))
        END AS Mnth
INTO #oldAr
FROM    dbo.PR_Salaries
        INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   ( @employees IS NULL
          OR PR_Employee.EmployeeId IN (
          SELECT    *
          FROM      dbo.Acc_ConvertIntListToTable(@employees) )
        )
        AND PeriodFrom BETWEEN @fromDate AND @toDate
        AND Posted = 1
        AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
ORDER BY PR_Employee.EmployeeId ,
        PeriodFrom;
;
GO
-- new batch: API passes from = start of day, to = end of day
DECLARE @FromDate DATETIME = '2026-04-01T00:00:00', @ToDate DATETIME = '2026-08-31T23:59:59.997', @SecurityLevel INT = 5;
DECLARE @EmployeeIds NVARCHAR(MAX) = NULL;
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_Employee.EmployeeId, PR_SalaryMain.PeriodFrom, PR_Salaries.SalaryId ) AS RowNo ,
            PR_Salaries.SalaryId ,
            PR_Salaries.SalaryMainId ,
            PR_Salaries.EmployeeId ,
            PR_Employee.EmployeeName ,
            PR_Employee.EmployeeArabicName ,
            PR_Employee.EmployeeNumber ,
            PR_Employee.DateOfWork ,
            PR_Branch.BranchName ,
            PR_Department.DepartmentName ,
            PR_Salaries.CurrencyId ,
            PR_SalaryMain.PeriodFrom ,
            PR_SalaryMain.SalaryMonth ,
            PR_SalaryMain.SalaryYear ,
            PR_Salaries.InsuranceCompany ,
            PR_Salaries.BasicSalary ,
            PR_Salaries.TotalAdditions ,
            PR_Salaries.TotalDeductions ,
            PR_Salaries.TotalTax ,
            PR_Salaries.Total ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN 'Jan ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN 'Feb ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN 'Mar ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN 'Apr ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN 'May ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN 'Jun ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN 'Jul ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN 'Aug ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN 'Sep ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN 'Oct ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN 'Nov ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN 'Dec ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS Mnth ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN N'يناير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN N'فبراير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN N'مارس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN N'أبريل ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN N'مايو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN N'يونيو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN N'يوليو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN N'أغسطس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN N'سبتمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN N'أكتوبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN N'نوفمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN N'ديسمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS MnthArabic
    INTO #new
    FROM    dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    WHERE   ( ISNULL(@EmployeeIds, '') = ''
              OR PR_Employee.EmployeeId IN (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
            )
            AND PR_SalaryMain.PeriodFrom BETWEEN @FromDate AND @ToDate
            AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
            AND PR_Salaries.Posted = 1
;
SELECT 'R4-a-null' AS CaseId, 'salary' AS Part,
  (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #old) OldMainSal_InsCo, (SELECT SUM(InsuranceCompany) FROM #new) NewMainSal_InsCo, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(InsuranceAmount) FROM #old) OldIns, (SELECT SUM(InsuranceAmount) FROM #new) NewIns, (SELECT SUM(TaxAmount) FROM #old) OldTax, (SELECT SUM(TaxAmount) FROM #new) NewTax, (SELECT SUM(Total) FROM #old) OldTotal, (SELECT SUM(Total) FROM #new) NewTotal, (SELECT COUNT(DISTINCT EmployeeId) FROM #new) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x;
SELECT 'a-null' CaseId, 'arabic-month' Part, (SELECT COUNT(*) FROM (SELECT SalaryId, Mnth FROM #oldAr EXCEPT SELECT SalaryId, MnthArabic FROM #new) x) OldArMinusNew, (SELECT COUNT(*) FROM (SELECT SalaryId, MnthArabic FROM #new EXCEPT SELECT SalaryId, Mnth FROM #oldAr) x) NewMinusOldAr;
SELECT 'a-null' CaseId, 'order' Part, COUNT(*) OrderMismatch FROM (SELECT o.SalaryId, ROW_NUMBER() OVER (ORDER BY o.EmployeeId, p.PeriodFrom, o.SalaryId) rn FROM #old o JOIN dbo.PR_SalaryMain p ON p.SalaryMainId = o.SalaryMainId) o JOIN #new n ON n.SalaryId = o.SalaryId WHERE n.RowNo <> o.rn;
GO
-------------------- R4 case b --------------------
DROP TABLE IF EXISTS #old; DROP TABLE IF EXISTS #oldAr; DROP TABLE IF EXISTS #new;
GO
-- legacy batch: raw date-only values from the MVC model binder; shell always sends an explicit CSV
DECLARE @fromDate DATETIME = '2026-04-01', @toDate DATETIME = '2026-08-31', @EmployeeSecurityLevel INT = 5;
DECLARE @employees NVARCHAR(MAX) = N'14,21,37';
SELECT 'b' CaseId, LEN(@employees) LegacyCsvLen;
                    


   SELECT   PR_Salaries.* ,
            EmployeeName ,
            EmployeeNumber ,
            DateOfWork ,
            BranchName ,
            DepartmentName ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN SalaryMonth = 1
                 THEN 'Jan ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 2
                 THEN 'Feb ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 3
                 THEN 'Mar ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 4
                 THEN 'Apr ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 5
                 THEN 'May ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 6
                 THEN 'Jun ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 7
                 THEN 'Jul ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 8
                 THEN 'Aug ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 9
                 THEN 'Sep ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 10
                 THEN 'Oct ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 11
                 THEN 'Nov ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 12
                 THEN 'Dec ' + CAST(SalaryYear AS VARCHAR(4))
            END AS Mnth
   INTO #old
   FROM     dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
   WHERE    ( @employees IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@employees) )
            )
            AND PeriodFrom BETWEEN @fromDate AND @toDate
            AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND Posted = 1
   ORDER BY PR_Employee.EmployeeId ,
            PeriodFrom;
;
                    
SELECT  PR_Salaries.* ,
        EmployeeName ,
        EmployeeNumber ,
        DateOfWork ,
        BranchName ,
        DepartmentName ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        TaxIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS TaxAmount ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        EmployeeInsuranceIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS InsuranceAmount ,
        CASE WHEN SalaryMonth = 1
             THEN N'يناير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 2
             THEN N'فبراير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 3
             THEN N'مارس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 4
             THEN N'أبريل ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 5
             THEN N'مايو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 6
             THEN N'يونيو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 7
             THEN N'يوليو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 8
             THEN N'أغسطس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 9
             THEN N'سبتمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 10
             THEN N'أكتوبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 11
             THEN N'نوفمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 12
             THEN N'ديسمبر ' + CAST(SalaryYear AS VARCHAR(4))
        END AS Mnth
INTO #oldAr
FROM    dbo.PR_Salaries
        INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   ( @employees IS NULL
          OR PR_Employee.EmployeeId IN (
          SELECT    *
          FROM      dbo.Acc_ConvertIntListToTable(@employees) )
        )
        AND PeriodFrom BETWEEN @fromDate AND @toDate
        AND Posted = 1
        AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
ORDER BY PR_Employee.EmployeeId ,
        PeriodFrom;
;
GO
-- new batch: API passes from = start of day, to = end of day
DECLARE @FromDate DATETIME = '2026-04-01T00:00:00', @ToDate DATETIME = '2026-08-31T23:59:59.997', @SecurityLevel INT = 5;
DECLARE @EmployeeIds NVARCHAR(MAX) = N'14,21,37';
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_Employee.EmployeeId, PR_SalaryMain.PeriodFrom, PR_Salaries.SalaryId ) AS RowNo ,
            PR_Salaries.SalaryId ,
            PR_Salaries.SalaryMainId ,
            PR_Salaries.EmployeeId ,
            PR_Employee.EmployeeName ,
            PR_Employee.EmployeeArabicName ,
            PR_Employee.EmployeeNumber ,
            PR_Employee.DateOfWork ,
            PR_Branch.BranchName ,
            PR_Department.DepartmentName ,
            PR_Salaries.CurrencyId ,
            PR_SalaryMain.PeriodFrom ,
            PR_SalaryMain.SalaryMonth ,
            PR_SalaryMain.SalaryYear ,
            PR_Salaries.InsuranceCompany ,
            PR_Salaries.BasicSalary ,
            PR_Salaries.TotalAdditions ,
            PR_Salaries.TotalDeductions ,
            PR_Salaries.TotalTax ,
            PR_Salaries.Total ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN 'Jan ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN 'Feb ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN 'Mar ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN 'Apr ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN 'May ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN 'Jun ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN 'Jul ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN 'Aug ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN 'Sep ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN 'Oct ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN 'Nov ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN 'Dec ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS Mnth ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN N'يناير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN N'فبراير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN N'مارس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN N'أبريل ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN N'مايو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN N'يونيو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN N'يوليو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN N'أغسطس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN N'سبتمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN N'أكتوبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN N'نوفمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN N'ديسمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS MnthArabic
    INTO #new
    FROM    dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    WHERE   ( ISNULL(@EmployeeIds, '') = ''
              OR PR_Employee.EmployeeId IN (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
            )
            AND PR_SalaryMain.PeriodFrom BETWEEN @FromDate AND @ToDate
            AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
            AND PR_Salaries.Posted = 1
;
SELECT 'R4-b' AS CaseId, 'salary' AS Part,
  (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #old) OldMainSal_InsCo, (SELECT SUM(InsuranceCompany) FROM #new) NewMainSal_InsCo, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(InsuranceAmount) FROM #old) OldIns, (SELECT SUM(InsuranceAmount) FROM #new) NewIns, (SELECT SUM(TaxAmount) FROM #old) OldTax, (SELECT SUM(TaxAmount) FROM #new) NewTax, (SELECT SUM(Total) FROM #old) OldTotal, (SELECT SUM(Total) FROM #new) NewTotal, (SELECT COUNT(DISTINCT EmployeeId) FROM #new) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x;
SELECT 'b' CaseId, 'arabic-month' Part, (SELECT COUNT(*) FROM (SELECT SalaryId, Mnth FROM #oldAr EXCEPT SELECT SalaryId, MnthArabic FROM #new) x) OldArMinusNew, (SELECT COUNT(*) FROM (SELECT SalaryId, MnthArabic FROM #new EXCEPT SELECT SalaryId, Mnth FROM #oldAr) x) NewMinusOldAr;
SELECT 'b' CaseId, 'order' Part, COUNT(*) OrderMismatch FROM (SELECT o.SalaryId, ROW_NUMBER() OVER (ORDER BY o.EmployeeId, p.PeriodFrom, o.SalaryId) rn FROM #old o JOIN dbo.PR_SalaryMain p ON p.SalaryMainId = o.SalaryMainId) o JOIN #new n ON n.SalaryId = o.SalaryId WHERE n.RowNo <> o.rn;
GO
-------------------- R4 case c --------------------
DROP TABLE IF EXISTS #old; DROP TABLE IF EXISTS #oldAr; DROP TABLE IF EXISTS #new;
GO
-- legacy batch: raw date-only values from the MVC model binder; shell always sends an explicit CSV
DECLARE @fromDate DATETIME = '2026-08-01', @toDate DATETIME = '2026-08-31', @EmployeeSecurityLevel INT = 5;
DECLARE @employees NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS nvarchar(max)), ',') FROM dbo.PR_Employee);
SELECT 'c' CaseId, LEN(@employees) LegacyCsvLen;
                    


   SELECT   PR_Salaries.* ,
            EmployeeName ,
            EmployeeNumber ,
            DateOfWork ,
            BranchName ,
            DepartmentName ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN SalaryMonth = 1
                 THEN 'Jan ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 2
                 THEN 'Feb ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 3
                 THEN 'Mar ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 4
                 THEN 'Apr ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 5
                 THEN 'May ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 6
                 THEN 'Jun ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 7
                 THEN 'Jul ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 8
                 THEN 'Aug ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 9
                 THEN 'Sep ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 10
                 THEN 'Oct ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 11
                 THEN 'Nov ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 12
                 THEN 'Dec ' + CAST(SalaryYear AS VARCHAR(4))
            END AS Mnth
   INTO #old
   FROM     dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
   WHERE    ( @employees IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@employees) )
            )
            AND PeriodFrom BETWEEN @fromDate AND @toDate
            AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND Posted = 1
   ORDER BY PR_Employee.EmployeeId ,
            PeriodFrom;
;
                    
SELECT  PR_Salaries.* ,
        EmployeeName ,
        EmployeeNumber ,
        DateOfWork ,
        BranchName ,
        DepartmentName ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        TaxIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS TaxAmount ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        EmployeeInsuranceIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS InsuranceAmount ,
        CASE WHEN SalaryMonth = 1
             THEN N'يناير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 2
             THEN N'فبراير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 3
             THEN N'مارس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 4
             THEN N'أبريل ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 5
             THEN N'مايو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 6
             THEN N'يونيو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 7
             THEN N'يوليو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 8
             THEN N'أغسطس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 9
             THEN N'سبتمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 10
             THEN N'أكتوبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 11
             THEN N'نوفمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 12
             THEN N'ديسمبر ' + CAST(SalaryYear AS VARCHAR(4))
        END AS Mnth
INTO #oldAr
FROM    dbo.PR_Salaries
        INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   ( @employees IS NULL
          OR PR_Employee.EmployeeId IN (
          SELECT    *
          FROM      dbo.Acc_ConvertIntListToTable(@employees) )
        )
        AND PeriodFrom BETWEEN @fromDate AND @toDate
        AND Posted = 1
        AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
ORDER BY PR_Employee.EmployeeId ,
        PeriodFrom;
;
GO
-- new batch: API passes from = start of day, to = end of day
DECLARE @FromDate DATETIME = '2026-08-01T00:00:00', @ToDate DATETIME = '2026-08-31T23:59:59.997', @SecurityLevel INT = 5;
DECLARE @EmployeeIds NVARCHAR(MAX) = NULL;
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_Employee.EmployeeId, PR_SalaryMain.PeriodFrom, PR_Salaries.SalaryId ) AS RowNo ,
            PR_Salaries.SalaryId ,
            PR_Salaries.SalaryMainId ,
            PR_Salaries.EmployeeId ,
            PR_Employee.EmployeeName ,
            PR_Employee.EmployeeArabicName ,
            PR_Employee.EmployeeNumber ,
            PR_Employee.DateOfWork ,
            PR_Branch.BranchName ,
            PR_Department.DepartmentName ,
            PR_Salaries.CurrencyId ,
            PR_SalaryMain.PeriodFrom ,
            PR_SalaryMain.SalaryMonth ,
            PR_SalaryMain.SalaryYear ,
            PR_Salaries.InsuranceCompany ,
            PR_Salaries.BasicSalary ,
            PR_Salaries.TotalAdditions ,
            PR_Salaries.TotalDeductions ,
            PR_Salaries.TotalTax ,
            PR_Salaries.Total ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN 'Jan ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN 'Feb ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN 'Mar ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN 'Apr ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN 'May ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN 'Jun ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN 'Jul ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN 'Aug ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN 'Sep ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN 'Oct ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN 'Nov ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN 'Dec ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS Mnth ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN N'يناير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN N'فبراير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN N'مارس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN N'أبريل ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN N'مايو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN N'يونيو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN N'يوليو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN N'أغسطس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN N'سبتمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN N'أكتوبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN N'نوفمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN N'ديسمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS MnthArabic
    INTO #new
    FROM    dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    WHERE   ( ISNULL(@EmployeeIds, '') = ''
              OR PR_Employee.EmployeeId IN (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
            )
            AND PR_SalaryMain.PeriodFrom BETWEEN @FromDate AND @ToDate
            AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
            AND PR_Salaries.Posted = 1
;
SELECT 'R4-c' AS CaseId, 'salary' AS Part,
  (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #old) OldMainSal_InsCo, (SELECT SUM(InsuranceCompany) FROM #new) NewMainSal_InsCo, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(InsuranceAmount) FROM #old) OldIns, (SELECT SUM(InsuranceAmount) FROM #new) NewIns, (SELECT SUM(TaxAmount) FROM #old) OldTax, (SELECT SUM(TaxAmount) FROM #new) NewTax, (SELECT SUM(Total) FROM #old) OldTotal, (SELECT SUM(Total) FROM #new) NewTotal, (SELECT COUNT(DISTINCT EmployeeId) FROM #new) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x;
SELECT 'c' CaseId, 'arabic-month' Part, (SELECT COUNT(*) FROM (SELECT SalaryId, Mnth FROM #oldAr EXCEPT SELECT SalaryId, MnthArabic FROM #new) x) OldArMinusNew, (SELECT COUNT(*) FROM (SELECT SalaryId, MnthArabic FROM #new EXCEPT SELECT SalaryId, Mnth FROM #oldAr) x) NewMinusOldAr;
SELECT 'c' CaseId, 'order' Part, COUNT(*) OrderMismatch FROM (SELECT o.SalaryId, ROW_NUMBER() OVER (ORDER BY o.EmployeeId, p.PeriodFrom, o.SalaryId) rn FROM #old o JOIN dbo.PR_SalaryMain p ON p.SalaryMainId = o.SalaryMainId) o JOIN #new n ON n.SalaryId = o.SalaryId WHERE n.RowNo <> o.rn;
GO
-------------------- R4 case d-jul --------------------
DROP TABLE IF EXISTS #old; DROP TABLE IF EXISTS #oldAr; DROP TABLE IF EXISTS #new;
GO
-- legacy batch: raw date-only values from the MVC model binder; shell always sends an explicit CSV
DECLARE @fromDate DATETIME = '2026-07-01', @toDate DATETIME = '2026-07-31', @EmployeeSecurityLevel INT = 5;
DECLARE @employees NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS nvarchar(max)), ',') FROM dbo.PR_Employee);
SELECT 'd-jul' CaseId, LEN(@employees) LegacyCsvLen;
                    


   SELECT   PR_Salaries.* ,
            EmployeeName ,
            EmployeeNumber ,
            DateOfWork ,
            BranchName ,
            DepartmentName ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN SalaryMonth = 1
                 THEN 'Jan ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 2
                 THEN 'Feb ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 3
                 THEN 'Mar ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 4
                 THEN 'Apr ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 5
                 THEN 'May ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 6
                 THEN 'Jun ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 7
                 THEN 'Jul ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 8
                 THEN 'Aug ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 9
                 THEN 'Sep ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 10
                 THEN 'Oct ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 11
                 THEN 'Nov ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 12
                 THEN 'Dec ' + CAST(SalaryYear AS VARCHAR(4))
            END AS Mnth
   INTO #old
   FROM     dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
   WHERE    ( @employees IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@employees) )
            )
            AND PeriodFrom BETWEEN @fromDate AND @toDate
            AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND Posted = 1
   ORDER BY PR_Employee.EmployeeId ,
            PeriodFrom;
;
                    
SELECT  PR_Salaries.* ,
        EmployeeName ,
        EmployeeNumber ,
        DateOfWork ,
        BranchName ,
        DepartmentName ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        TaxIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS TaxAmount ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        EmployeeInsuranceIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS InsuranceAmount ,
        CASE WHEN SalaryMonth = 1
             THEN N'يناير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 2
             THEN N'فبراير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 3
             THEN N'مارس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 4
             THEN N'أبريل ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 5
             THEN N'مايو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 6
             THEN N'يونيو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 7
             THEN N'يوليو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 8
             THEN N'أغسطس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 9
             THEN N'سبتمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 10
             THEN N'أكتوبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 11
             THEN N'نوفمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 12
             THEN N'ديسمبر ' + CAST(SalaryYear AS VARCHAR(4))
        END AS Mnth
INTO #oldAr
FROM    dbo.PR_Salaries
        INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   ( @employees IS NULL
          OR PR_Employee.EmployeeId IN (
          SELECT    *
          FROM      dbo.Acc_ConvertIntListToTable(@employees) )
        )
        AND PeriodFrom BETWEEN @fromDate AND @toDate
        AND Posted = 1
        AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
ORDER BY PR_Employee.EmployeeId ,
        PeriodFrom;
;
GO
-- new batch: API passes from = start of day, to = end of day
DECLARE @FromDate DATETIME = '2026-07-01T00:00:00', @ToDate DATETIME = '2026-07-31T23:59:59.997', @SecurityLevel INT = 5;
DECLARE @EmployeeIds NVARCHAR(MAX) = NULL;
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_Employee.EmployeeId, PR_SalaryMain.PeriodFrom, PR_Salaries.SalaryId ) AS RowNo ,
            PR_Salaries.SalaryId ,
            PR_Salaries.SalaryMainId ,
            PR_Salaries.EmployeeId ,
            PR_Employee.EmployeeName ,
            PR_Employee.EmployeeArabicName ,
            PR_Employee.EmployeeNumber ,
            PR_Employee.DateOfWork ,
            PR_Branch.BranchName ,
            PR_Department.DepartmentName ,
            PR_Salaries.CurrencyId ,
            PR_SalaryMain.PeriodFrom ,
            PR_SalaryMain.SalaryMonth ,
            PR_SalaryMain.SalaryYear ,
            PR_Salaries.InsuranceCompany ,
            PR_Salaries.BasicSalary ,
            PR_Salaries.TotalAdditions ,
            PR_Salaries.TotalDeductions ,
            PR_Salaries.TotalTax ,
            PR_Salaries.Total ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN 'Jan ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN 'Feb ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN 'Mar ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN 'Apr ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN 'May ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN 'Jun ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN 'Jul ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN 'Aug ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN 'Sep ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN 'Oct ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN 'Nov ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN 'Dec ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS Mnth ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN N'يناير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN N'فبراير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN N'مارس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN N'أبريل ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN N'مايو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN N'يونيو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN N'يوليو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN N'أغسطس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN N'سبتمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN N'أكتوبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN N'نوفمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN N'ديسمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS MnthArabic
    INTO #new
    FROM    dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    WHERE   ( ISNULL(@EmployeeIds, '') = ''
              OR PR_Employee.EmployeeId IN (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
            )
            AND PR_SalaryMain.PeriodFrom BETWEEN @FromDate AND @ToDate
            AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
            AND PR_Salaries.Posted = 1
;
SELECT 'R4-d-jul' AS CaseId, 'salary' AS Part,
  (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #old) OldMainSal_InsCo, (SELECT SUM(InsuranceCompany) FROM #new) NewMainSal_InsCo, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(InsuranceAmount) FROM #old) OldIns, (SELECT SUM(InsuranceAmount) FROM #new) NewIns, (SELECT SUM(TaxAmount) FROM #old) OldTax, (SELECT SUM(TaxAmount) FROM #new) NewTax, (SELECT SUM(Total) FROM #old) OldTotal, (SELECT SUM(Total) FROM #new) NewTotal, (SELECT COUNT(DISTINCT EmployeeId) FROM #new) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x;
SELECT 'd-jul' CaseId, 'arabic-month' Part, (SELECT COUNT(*) FROM (SELECT SalaryId, Mnth FROM #oldAr EXCEPT SELECT SalaryId, MnthArabic FROM #new) x) OldArMinusNew, (SELECT COUNT(*) FROM (SELECT SalaryId, MnthArabic FROM #new EXCEPT SELECT SalaryId, Mnth FROM #oldAr) x) NewMinusOldAr;
SELECT 'd-jul' CaseId, 'order' Part, COUNT(*) OrderMismatch FROM (SELECT o.SalaryId, ROW_NUMBER() OVER (ORDER BY o.EmployeeId, p.PeriodFrom, o.SalaryId) rn FROM #old o JOIN dbo.PR_SalaryMain p ON p.SalaryMainId = o.SalaryMainId) o JOIN #new n ON n.SalaryId = o.SalaryId WHERE n.RowNo <> o.rn;
GO
-------------------- R4 case e-bound --------------------
DROP TABLE IF EXISTS #old; DROP TABLE IF EXISTS #oldAr; DROP TABLE IF EXISTS #new;
GO
-- legacy batch: raw date-only values from the MVC model binder; shell always sends an explicit CSV
DECLARE @fromDate DATETIME = '2026-07-01T10:22:31', @toDate DATETIME = '2026-08-14T10:22:31', @EmployeeSecurityLevel INT = 5;
DECLARE @employees NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS nvarchar(max)), ',') FROM dbo.PR_Employee);
SELECT 'e-bound' CaseId, LEN(@employees) LegacyCsvLen;
                    


   SELECT   PR_Salaries.* ,
            EmployeeName ,
            EmployeeNumber ,
            DateOfWork ,
            BranchName ,
            DepartmentName ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN SalaryMonth = 1
                 THEN 'Jan ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 2
                 THEN 'Feb ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 3
                 THEN 'Mar ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 4
                 THEN 'Apr ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 5
                 THEN 'May ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 6
                 THEN 'Jun ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 7
                 THEN 'Jul ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 8
                 THEN 'Aug ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 9
                 THEN 'Sep ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 10
                 THEN 'Oct ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 11
                 THEN 'Nov ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 12
                 THEN 'Dec ' + CAST(SalaryYear AS VARCHAR(4))
            END AS Mnth
   INTO #old
   FROM     dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
   WHERE    ( @employees IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@employees) )
            )
            AND PeriodFrom BETWEEN @fromDate AND @toDate
            AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND Posted = 1
   ORDER BY PR_Employee.EmployeeId ,
            PeriodFrom;
;
                    
SELECT  PR_Salaries.* ,
        EmployeeName ,
        EmployeeNumber ,
        DateOfWork ,
        BranchName ,
        DepartmentName ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        TaxIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS TaxAmount ,
        ISNULL(( SELECT SUM(IncomeAmount)
                 FROM   dbo.PR_SalaryDetail
                 WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                        AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                        EmployeeInsuranceIncomeId
                                                 FROM   dbo.PR_SystemConfiguration
                                               )
               ), 0) AS InsuranceAmount ,
        CASE WHEN SalaryMonth = 1
             THEN N'يناير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 2
             THEN N'فبراير ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 3
             THEN N'مارس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 4
             THEN N'أبريل ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 5
             THEN N'مايو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 6
             THEN N'يونيو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 7
             THEN N'يوليو ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 8
             THEN N'أغسطس ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 9
             THEN N'سبتمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 10
             THEN N'أكتوبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 11
             THEN N'نوفمبر ' + CAST(SalaryYear AS VARCHAR(4))
             WHEN SalaryMonth = 12
             THEN N'ديسمبر ' + CAST(SalaryYear AS VARCHAR(4))
        END AS Mnth
INTO #oldAr
FROM    dbo.PR_Salaries
        INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   ( @employees IS NULL
          OR PR_Employee.EmployeeId IN (
          SELECT    *
          FROM      dbo.Acc_ConvertIntListToTable(@employees) )
        )
        AND PeriodFrom BETWEEN @fromDate AND @toDate
        AND Posted = 1
        AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
ORDER BY PR_Employee.EmployeeId ,
        PeriodFrom;
;
GO
-- new batch: API passes from = start of day, to = end of day
DECLARE @FromDate DATETIME = '2026-07-01T00:00:00', @ToDate DATETIME = '2026-08-14T23:59:59.997', @SecurityLevel INT = 5;
DECLARE @EmployeeIds NVARCHAR(MAX) = NULL;
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_Employee.EmployeeId, PR_SalaryMain.PeriodFrom, PR_Salaries.SalaryId ) AS RowNo ,
            PR_Salaries.SalaryId ,
            PR_Salaries.SalaryMainId ,
            PR_Salaries.EmployeeId ,
            PR_Employee.EmployeeName ,
            PR_Employee.EmployeeArabicName ,
            PR_Employee.EmployeeNumber ,
            PR_Employee.DateOfWork ,
            PR_Branch.BranchName ,
            PR_Department.DepartmentName ,
            PR_Salaries.CurrencyId ,
            PR_SalaryMain.PeriodFrom ,
            PR_SalaryMain.SalaryMonth ,
            PR_SalaryMain.SalaryYear ,
            PR_Salaries.InsuranceCompany ,
            PR_Salaries.BasicSalary ,
            PR_Salaries.TotalAdditions ,
            PR_Salaries.TotalDeductions ,
            PR_Salaries.TotalTax ,
            PR_Salaries.Total ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN 'Jan ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN 'Feb ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN 'Mar ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN 'Apr ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN 'May ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN 'Jun ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN 'Jul ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN 'Aug ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN 'Sep ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN 'Oct ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN 'Nov ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN 'Dec ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS Mnth ,
            CASE WHEN PR_SalaryMain.SalaryMonth = 1
                 THEN N'يناير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 2
                 THEN N'فبراير ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 3
                 THEN N'مارس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 4
                 THEN N'أبريل ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 5
                 THEN N'مايو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 6
                 THEN N'يونيو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 7
                 THEN N'يوليو ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 8
                 THEN N'أغسطس ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 9
                 THEN N'سبتمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 10
                 THEN N'أكتوبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 11
                 THEN N'نوفمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
                 WHEN PR_SalaryMain.SalaryMonth = 12
                 THEN N'ديسمبر ' + CAST(PR_SalaryMain.SalaryYear AS VARCHAR(4))
            END AS MnthArabic
    INTO #new
    FROM    dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    WHERE   ( ISNULL(@EmployeeIds, '') = ''
              OR PR_Employee.EmployeeId IN (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
            )
            AND PR_SalaryMain.PeriodFrom BETWEEN @FromDate AND @ToDate
            AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
            AND PR_Salaries.Posted = 1
;
SELECT 'R4-e-bound' AS CaseId, 'salary' AS Part,
  (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) c FROM #new GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth, COUNT(*) FROM #old GROUP BY SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #old) OldMainSal_InsCo, (SELECT SUM(InsuranceCompany) FROM #new) NewMainSal_InsCo, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(InsuranceAmount) FROM #old) OldIns, (SELECT SUM(InsuranceAmount) FROM #new) NewIns, (SELECT SUM(TaxAmount) FROM #old) OldTax, (SELECT SUM(TaxAmount) FROM #new) NewTax, (SELECT SUM(Total) FROM #old) OldTotal, (SELECT SUM(Total) FROM #new) NewTotal, (SELECT COUNT(DISTINCT EmployeeId) FROM #new) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #new EXCEPT SELECT SalaryId, SalaryMainId, EmployeeId, CurrencyId, InsuranceCompany, BasicSalary, TotalAdditions, TotalDeductions, TotalTax, Total, EmployeeName, EmployeeNumber, DateOfWork, BranchName, DepartmentName, TaxAmount, InsuranceAmount, Mnth FROM #old) x;
SELECT 'e-bound' CaseId, 'arabic-month' Part, (SELECT COUNT(*) FROM (SELECT SalaryId, Mnth FROM #oldAr EXCEPT SELECT SalaryId, MnthArabic FROM #new) x) OldArMinusNew, (SELECT COUNT(*) FROM (SELECT SalaryId, MnthArabic FROM #new EXCEPT SELECT SalaryId, Mnth FROM #oldAr) x) NewMinusOldAr;
SELECT 'e-bound' CaseId, 'order' Part, COUNT(*) OrderMismatch FROM (SELECT o.SalaryId, ROW_NUMBER() OVER (ORDER BY o.EmployeeId, p.PeriodFrom, o.SalaryId) rn FROM #old o JOIN dbo.PR_SalaryMain p ON p.SalaryMainId = o.SalaryMainId) o JOIN #new n ON n.SalaryId = o.SalaryId WHERE n.RowNo <> o.rn;
GO
