-- Legacy CommandText, verbatim (XML-unescaped) from AccFlex_ERP HRManagement/Payroll.Reports/HR/EmpolyeeReceipt/dsEmployeeReceipt.xsd (dtEmployeeReceipt (FillByEmployeeId)); identical on origin/Master_Stable.
-- Parameters: @SalaryMonth INT, @SalaryYear INT, @EmployeeSecurityLevel INT, @EmployeeId NVARCHAR
WITH employeeBank
AS (SELECT ROW_NUMBER() OVER (PARTITION BY EmployeeId, CurrencyId ORDER BY EmployeeBankId) AS rowNo,
           PR_Bank.BankId,
           PR_Bank.BankName,
           EmployeeId,
           CurrencyId,
           SEPA,
           Address,
           Branch,
           Country,
           AccountOwner,
           SwiftCode
    FROM PR_EmployeeBank
        INNER JOIN PR_Bank
            ON PR_Bank.BankId = PR_EmployeeBank.BankId)
SELECT PR_Salaries.EmployeeId,
       PR_Employee.EmployeeName,
       PR_Employee.EmployeeNumber,
       PR_Branch.BranchName,
       PR_Projects.ProjectName,
       PR_Job.JobName,
       PR_SalaryDetail.SalaryId,
       PR_SalaryDetail.SalaryDetailId,
       PR_SalaryDetail.EmployeeIncomeId,
       PR_SalaryDetail.IncomeAmount,
       PR_Income.IncomeName,
       PR_Income.Deduction,
       Acc_Currency.EnglishLetter,
       PR_Salaries.SalaryId,
       PR_Salaries.SalaryMainId,
       PR_Salaries.Total,
       PR_Salaries.Remarks,
       PR_Salaries.InsuranceCompany,
       PR_Salaries.TotalAdditions,
       PR_Salaries.TotalDeductions,
       PR_Salaries.PostDate,
       PR_Salaries.Posted,
       PR_SalaryMain.SalaryYear,
       PR_SalaryMain.SalaryMonth,
       PR_SalaryMain.SalaryDate,
       PR_Salaries.Suspend,
       PR_SalaryDetail.Suspend,
       employeeBank.BankId,
       employeeBank.BankName,
       employeeBank.SEPA AS BankSEPA,
       employeeBank.Address AS BankAddress,
       employeeBank.Branch AS BankBranch,
       employeeBank.Country AS BankCountry,
       employeeBank.AccountOwner AS BankAccountOwner,
       employeeBank.SwiftCode AS BankSwiftCode
FROM PR_Salaries
    INNER JOIN PR_SalaryDetail
        ON PR_Salaries.SalaryId = PR_SalaryDetail.SalaryId
    INNER JOIN PR_Income
        ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
    INNER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT JOIN dbo.PR_Projects
        ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    LEFT JOIN dbo.PR_Branch
        ON PR_Branch.BranchId = PR_Employee.BranchId
    INNER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    INNER JOIN Acc_Currency
        ON PR_Salaries.CurrencyId = Acc_Currency.CurrencyId
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT JOIN employeeBank
        ON PR_Employee.EmployeeId = employeeBank.EmployeeId
           AND employeeBank.CurrencyId = PR_Salaries.CurrencyId
           AND employeeBank.rowNo = 1
WHERE (
          @EmployeeId IS NULL
          OR PR_Salaries.EmployeeId IN
             (
                 SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeId)
             )
      )
      AND PR_SalaryMain.SalaryMonth = @SalaryMonth
      AND PR_SalaryMain.SalaryYear = @SalaryYear
      AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel;
