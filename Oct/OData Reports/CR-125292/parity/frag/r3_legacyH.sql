    SELECT DISTINCT
            dbo.PR_Employee.EmployeeName ,
            dbo.PR_Employee.EmployeeArabicName ,
            dbo.PR_Bank.BankName ,
            dbo.PR_EmployeeBank.AccountNo ,
            dbo.Acc_Currency.CurrencyName ,
            dbo.PR_Branch.BranchName ,
            dbo.PR_Department.DepartmentName ,
            dbo.PR_SalaryMain.SalaryMonth ,
            dbo.PR_SalaryMain.SalaryYear ,
            PR_Projects.ProjectName ,
            dbo.PR_Salaries.InsuranceCompany ,
            PR_Salaries.EmployeeId ,
            PR_Salaries.SalaryId
    INTO #oldH
    FROM    dbo.PR_SalaryDetail
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
    WHERE   ( @EmployeeIds_legacy IS NULL
              OR PR_Salaries.EmployeeId IN (
              SELECT    number
              FROM      dbo.iter$simple_intlist_to_tbl(@EmployeeIds_legacy) AS iter$simple_intlist_to_tbl_1 )
            )
            AND SalaryMonth = @Month
            AND SalaryYear = @Year;
-- legacy C#: SalaryIds = string.Join(",", rows.SalaryId); SqlParameter nvarchar(1024) truncates
SELECT @SalaryId = LEFT(ISNULL(STRING_AGG(CAST(SalaryId AS nvarchar(max)), ','), N''), 1024) FROM #oldH;
SELECT LEN(@SalaryId) AS SalaryIdCsvLen;
SELECT  dbo.PR_Income.IncomeName ,
        dbo.PR_IncomeGroup.IncomeType ,IncomeId,
        IncomeAmount ,
        SalaryId
INTO #oldL
FROM    dbo.PR_SalaryDetail
        INNER JOIN dbo.PR_Income ON dbo.PR_Income.IncomeId = dbo.PR_SalaryDetail.EmployeeIncomeId
        INNER JOIN dbo.PR_IncomeGroup ON dbo.PR_IncomeGroup.IncomeTypeId = dbo.PR_Income.IncomeTypeId
WHERE   SalaryId IN (
        SELECT  number
        FROM    dbo.iter$simple_intlist_to_tbl(@SalaryId) AS iter$simple_intlist_to_tbl_1 )
ORDER BY SalaryId;
