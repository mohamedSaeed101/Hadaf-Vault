    WITH Salary
      AS ( SELECT DISTINCT
                    dbo.PR_Employee.EmployeeName ,
                    dbo.PR_Employee.EmployeeArabicName ,
                    dbo.PR_Bank.BankName ,
                    dbo.PR_EmployeeBank.AccountNo ,
                    dbo.Acc_Currency.CurrencyName ,
                    dbo.Acc_Currency.CurrencyNameArabic ,
                    dbo.PR_Branch.BranchName ,
                    dbo.PR_Department.DepartmentName ,
                    dbo.PR_SalaryMain.SalaryMonth ,
                    dbo.PR_SalaryMain.SalaryYear ,
                    PR_Projects.ProjectName ,
                    dbo.PR_Salaries.InsuranceCompany ,
                    PR_Salaries.EmployeeId ,
                    PR_Salaries.SalaryId
           FROM     dbo.PR_SalaryDetail
                    INNER JOIN dbo.PR_Income ON dbo.PR_Income.IncomeId = dbo.PR_SalaryDetail.EmployeeIncomeId
                    INNER JOIN dbo.PR_Salaries ON dbo.PR_Salaries.SalaryId = dbo.PR_SalaryDetail.SalaryId
                    INNER JOIN dbo.PR_Employee ON dbo.PR_Employee.EmployeeId = dbo.PR_Salaries.EmployeeId
                    INNER JOIN dbo.PR_SalaryMain ON dbo.PR_SalaryMain.SalaryMainId = dbo.PR_Salaries.SalaryMainId
                    INNER JOIN dbo.Acc_Currency ON dbo.Acc_Currency.CurrencyId = dbo.PR_Salaries.CurrencyId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
                    LEFT OUTER JOIN dbo.PR_Department ON dbo.PR_Employee.DepartmentId = dbo.PR_Department.DepartmentId
                    LEFT OUTER JOIN dbo.PR_Branch ON dbo.PR_Employee.BranchId = dbo.PR_Branch.BranchId
                    LEFT OUTER JOIN dbo.PR_EmployeeBank ON dbo.PR_EmployeeBank.EmployeeId = dbo.PR_Employee.EmployeeId
                                                           AND dbo.PR_EmployeeBank.CurrencyId = dbo.PR_Salaries.CurrencyId
                    LEFT OUTER JOIN dbo.PR_Bank ON dbo.PR_Bank.BankId = dbo.PR_EmployeeBank.BankId
           WHERE    ( ISNULL(@EmployeeIds, '') = ''
                      OR PR_Salaries.EmployeeId IN (
                         SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds) )
                    )
                    AND dbo.PR_SalaryMain.SalaryMonth = @Month
                    AND dbo.PR_SalaryMain.SalaryYear = @Year
                    AND dbo.PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT  ROW_NUMBER() OVER ( ORDER BY Salary.SalaryId, Salary.BankName, Salary.AccountNo ) AS RowNo ,
            Salary.SalaryId ,
            Salary.EmployeeId ,
            Salary.EmployeeName ,
            Salary.EmployeeArabicName ,
            Salary.BankName ,
            Salary.AccountNo ,
            Salary.CurrencyName ,
            Salary.CurrencyNameArabic ,
            Salary.BranchName ,
            Salary.DepartmentName ,
            Salary.ProjectName ,
            Salary.SalaryMonth ,
            Salary.SalaryYear ,
            Salary.InsuranceCompany
    INTO #newH
    FROM    Salary;
    SELECT  ROW_NUMBER() OVER ( ORDER BY PR_SalaryDetail.SalaryId, PR_SalaryDetail.SalaryDetailId ) AS RowNo ,
            PR_SalaryDetail.SalaryDetailId ,
            PR_SalaryDetail.SalaryId ,
            dbo.PR_Income.IncomeId ,
            dbo.PR_Income.IncomeName ,
            dbo.PR_IncomeGroup.IncomeType ,
            PR_SalaryDetail.IncomeAmount ,
            CASE WHEN dbo.PR_Income.IncomeId = 10 THEN PR_SalaryDetail.IncomeAmount
                 ELSE 0
            END AS EmployeeInsuranceAmount
    INTO #newL
    FROM    dbo.PR_SalaryDetail
            INNER JOIN dbo.PR_Income ON dbo.PR_Income.IncomeId = dbo.PR_SalaryDetail.EmployeeIncomeId
            INNER JOIN dbo.PR_IncomeGroup ON dbo.PR_IncomeGroup.IncomeTypeId = dbo.PR_Income.IncomeTypeId
    WHERE   PR_SalaryDetail.SalaryId IN (
            SELECT  SalaryId
            FROM    #newH /* emulates dbo.PR_EmployeesDetailedSalariesReport(@Month, @Year, @SecurityLevel, @EmployeeIds): not deployed here */ );
