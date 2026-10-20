-- Legacy CommandText, verbatim (XML-unescaped) from AccFlex_ERP HRManagement/Payroll.Reports/HR/EmployeesSalaries/dsSalariesReport.xsd (Salaries (Fill)); identical on origin/Master_Stable.
-- Parameters: @MONTH INT, @YEAR INT, @EmployeeId NVARCHAR, @EmployeeSecurityLevel INT, @BankList NVARCHAR
SELECT  Pr_PayingSalariesDetail.EmployeeSalary ,
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
            ) ORDER BY PR_Employee.EmployeeId;
