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
