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
        AND ( @employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @month
        AND PR_SalaryMain.SalaryYear = @year
        AND PR_Salaries.Posted = 1;
