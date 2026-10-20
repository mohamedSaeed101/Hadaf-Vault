                    


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
