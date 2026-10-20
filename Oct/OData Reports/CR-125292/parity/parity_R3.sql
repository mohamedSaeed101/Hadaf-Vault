SET NOCOUNT ON;
-- PARITY R3 Employees Detailed Salaries (CR 125292 P4): legacy dsEmployeesSalariesDetails.xsd (Payroll.Reports, origin/Master_Stable) vs TVF bodies from origin/cr125292. Read-only: temp tables only.
-------------------- R3 case a --------------------
DROP TABLE IF EXISTS #oldH; DROP TABLE IF EXISTS #oldL; DROP TABLE IF EXISTS #newH; DROP TABLE IF EXISTS #newL;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @SecurityLevel INT = 5, @SalaryId NVARCHAR(1024);
DECLARE @EmployeeIds NVARCHAR(MAX) = NULL;          -- new API value (NULL = all)
DECLARE @EmployeeIds_legacy NVARCHAR(MAX) = NULL;   -- legacy: shell sends no key when all selected -> NULL
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
SELECT 'R3-a' AS CaseId, 'header' AS Part,
  (SELECT COUNT(*) FROM #oldH) AS OldRows, (SELECT COUNT(*) FROM #newH) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) c FROM #oldH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) FROM #newH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) c FROM #newH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) FROM #oldH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #oldH) OldTotInsCompany, (SELECT SUM(InsuranceCompany) FROM #newH) NewTotInsCompany, (SELECT COUNT(DISTINCT EmployeeId) FROM #newH) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH) x;
SELECT 'R3-a' AS CaseId, 'lines' AS Part,
  (SELECT COUNT(*) FROM #oldL) AS OldRows, (SELECT COUNT(*) FROM #newL) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) c FROM #oldL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) FROM #newL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) c FROM #newL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) FROM #oldL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId) x) AS GrpNewMinusOld,
  (SELECT SUM(IncomeAmount) FROM #oldL) OldSumAmt, (SELECT SUM(IncomeAmount) FROM #newL) NewSumAmt, (SELECT SUM(IncomeAmount) FROM #oldL WHERE IncomeId = 10) OldTotEmpIns_CSharp, (SELECT SUM(EmployeeInsuranceAmount) FROM #newL) NewTotEmpIns;
SELECT TOP 10 'old-new' d, * FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL) x;
GO
-------------------- R3 case b --------------------
DROP TABLE IF EXISTS #oldH; DROP TABLE IF EXISTS #oldL; DROP TABLE IF EXISTS #newH; DROP TABLE IF EXISTS #newL;
GO
DECLARE @Month INT = 5, @Year INT = 2026, @SecurityLevel INT = 5, @SalaryId NVARCHAR(1024);
DECLARE @EmployeeIds NVARCHAR(MAX) = NULL;          -- new API value (NULL = all)
DECLARE @EmployeeIds_legacy NVARCHAR(MAX) = NULL;   -- legacy: shell sends no key when all selected -> NULL
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
SELECT 'R3-b' AS CaseId, 'header' AS Part,
  (SELECT COUNT(*) FROM #oldH) AS OldRows, (SELECT COUNT(*) FROM #newH) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) c FROM #oldH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) FROM #newH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) c FROM #newH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) FROM #oldH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #oldH) OldTotInsCompany, (SELECT SUM(InsuranceCompany) FROM #newH) NewTotInsCompany, (SELECT COUNT(DISTINCT EmployeeId) FROM #newH) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH) x;
SELECT 'R3-b' AS CaseId, 'lines' AS Part,
  (SELECT COUNT(*) FROM #oldL) AS OldRows, (SELECT COUNT(*) FROM #newL) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) c FROM #oldL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) FROM #newL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) c FROM #newL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) FROM #oldL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId) x) AS GrpNewMinusOld,
  (SELECT SUM(IncomeAmount) FROM #oldL) OldSumAmt, (SELECT SUM(IncomeAmount) FROM #newL) NewSumAmt, (SELECT SUM(IncomeAmount) FROM #oldL WHERE IncomeId = 10) OldTotEmpIns_CSharp, (SELECT SUM(EmployeeInsuranceAmount) FROM #newL) NewTotEmpIns;
SELECT TOP 10 'old-new' d, * FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL) x;
GO
-------------------- R3 case c --------------------
DROP TABLE IF EXISTS #oldH; DROP TABLE IF EXISTS #oldL; DROP TABLE IF EXISTS #newH; DROP TABLE IF EXISTS #newL;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @SecurityLevel INT = 5, @SalaryId NVARCHAR(1024);
DECLARE @EmployeeIds NVARCHAR(MAX) = N'110,111,113';          -- new API value (NULL = all)
DECLARE @EmployeeIds_legacy NVARCHAR(MAX) = N'110,111,113';   -- legacy: shell sends no key when all selected -> NULL
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
SELECT 'R3-c' AS CaseId, 'header' AS Part,
  (SELECT COUNT(*) FROM #oldH) AS OldRows, (SELECT COUNT(*) FROM #newH) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) c FROM #oldH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) FROM #newH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) c FROM #newH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId, COUNT(*) FROM #oldH GROUP BY EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId) x) AS GrpNewMinusOld,
  (SELECT SUM(InsuranceCompany) FROM #oldH) OldTotInsCompany, (SELECT SUM(InsuranceCompany) FROM #newH) NewTotInsCompany, (SELECT COUNT(DISTINCT EmployeeId) FROM #newH) NewEmps;
SELECT TOP 10 'old-new' d, * FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #newH EXCEPT SELECT EmployeeName, EmployeeArabicName, BankName, AccountNo, CurrencyName, BranchName, DepartmentName, SalaryMonth, SalaryYear, ProjectName, InsuranceCompany, EmployeeId, SalaryId FROM #oldH) x;
SELECT 'R3-c' AS CaseId, 'lines' AS Part,
  (SELECT COUNT(*) FROM #oldL) AS OldRows, (SELECT COUNT(*) FROM #newL) AS NewRows,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL) x) AS OldMinusNew,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL) x) AS NewMinusOld,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) c FROM #oldL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) FROM #newL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId) x) AS GrpOldMinusNew,
  (SELECT COUNT(*) FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) c FROM #newL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId, COUNT(*) FROM #oldL GROUP BY IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId) x) AS GrpNewMinusOld,
  (SELECT SUM(IncomeAmount) FROM #oldL) OldSumAmt, (SELECT SUM(IncomeAmount) FROM #newL) NewSumAmt, (SELECT SUM(IncomeAmount) FROM #oldL WHERE IncomeId = 10) OldTotEmpIns_CSharp, (SELECT SUM(EmployeeInsuranceAmount) FROM #newL) NewTotEmpIns;
SELECT TOP 10 'old-new' d, * FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL) x;
SELECT TOP 10 'new-old' d, * FROM (SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #newL EXCEPT SELECT IncomeName, IncomeType, IncomeId, IncomeAmount, SalaryId FROM #oldL) x;
GO
