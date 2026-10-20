-- Legacy CommandText, verbatim (XML-unescaped) from AccFlex_ERP HRManagement/Payroll.Reports/HR/EmployeesFinancials/dsEmployeeFinance.xsd (PR_Emp_Income (Fill)); identical on origin/Master_Stable.
-- Parameters: @empIds VARCHAR (AnsiString), @IsArabic BIT
SELECT PR_EmployeeIncome.EmployeeIncomeId,
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
                   WHEN (LTRIM(RTRIM(PR_Employee.EmployeeArabicName))) = '' THEN
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
          @empIds = 'All'
          OR
          (
              @empIds = 'AllInService'
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 0
                  )
          )
          OR
          (
              @empIds = 'AllTerminated'
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 1
                  )
          )
          OR
          (
              @empIds NOT IN ( 'All', 'AllInService', 'AllTerminated' )
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@empIds)
                  )
          )
      )
      AND (@IsArabic = @IsArabic)
      AND IncomeEndDate IS NULL;
