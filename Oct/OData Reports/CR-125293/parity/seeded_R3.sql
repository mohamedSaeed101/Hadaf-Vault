-- CR 125293 seeded parity R3 EmployeeSalaryReceipt (legacy dsEmployeeReceipt.xsd FillByEmployeeId vs dbo.PR_EmployeeSalaryReceiptReport) on db-all / UNP-Ali.
-- ROLLBACK-ONLY: one transaction, ends with ROLLBACK TRAN. Salary month 8/2026: PR_Salaries.Suspend = 1 for employee 3, PR_SalaryDetail.Suspend = 1 on ONE of its lines only.
-- No triggers on PR_Salaries / PR_SalaryDetail (sys.triggers). Results go to table variables, which survive the rollback. Run: bash run.sh seeded_R3.sql
-- Legacy columns are captured by position: the 1st Suspend (PR_Salaries, DataSet Suspend) lands in Suspend, the 2nd (PR_SalaryDetail, DataSet Suspend1) in SalaryDetailSuspend,
-- the 2nd SalaryId (PR_Salaries) in SalaryId2 (dropped by the TVF; checked equal to SalaryId).
SET XACT_ABORT ON; SET NOCOUNT ON;
DECLARE @Legacy NVARCHAR(MAX) = N'WITH employeeBank
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
';
DECLARE @LP NVARCHAR(MAX) = N'@SalaryMonth INT, @SalaryYear INT, @EmployeeSecurityLevel INT, @EmployeeId NVARCHAR(MAX)';
DECLARE @Month INT = 8, @Year INT = 2026, @Emp INT = 3, @SalaryId INT, @DetailId INT;
DECLARE @t0 DATETIME2 = SYSDATETIME(), @ms INT;
SELECT @SalaryId = s.SalaryId FROM dbo.PR_Salaries s JOIN dbo.PR_SalaryMain m ON m.SalaryMainId = s.SalaryMainId WHERE m.SalaryMonth = @Month AND m.SalaryYear = @Year AND s.EmployeeId = @Emp;
-- a line the report shows (legacy joins PR_Income ON EmployeeIncomeId = IncomeId)
SELECT @DetailId = MIN(d.SalaryDetailId) FROM dbo.PR_SalaryDetail d WHERE d.SalaryId = @SalaryId AND EXISTS (SELECT 1 FROM dbo.PR_Income i WHERE i.IncomeId = d.EmployeeIncomeId);
DECLARE @L TABLE (c VARCHAR(40), EmployeeId INT, EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, EmployeeNumber NVARCHAR(100) COLLATE DATABASE_DEFAULT, BranchName NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
    ProjectName NVARCHAR(500) COLLATE DATABASE_DEFAULT, JobName NVARCHAR(50) COLLATE DATABASE_DEFAULT, SalaryId INT, SalaryDetailId INT, EmployeeIncomeId INT, IncomeAmount MONEY,
    IncomeName NVARCHAR(200) COLLATE DATABASE_DEFAULT, Deduction BIT, EnglishLetter NVARCHAR(5) COLLATE DATABASE_DEFAULT, SalaryId2 INT, SalaryMainId INT, Total MONEY, Remarks NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    InsuranceCompany MONEY, TotalAdditions MONEY, TotalDeductions MONEY, PostDate DATETIME, Posted BIT, SalaryYear INT, SalaryMonth INT, SalaryDate DATETIME, Suspend BIT, SalaryDetailSuspend BIT,
    BankId INT, BankName NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankSEPA BIT, BankAddress NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankBranch NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    BankCountry NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankAccountOwner NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankSwiftCode NVARCHAR(100) COLLATE DATABASE_DEFAULT);
DECLARE @N TABLE (c VARCHAR(40), EmployeeId INT, EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, EmployeeNumber NVARCHAR(100) COLLATE DATABASE_DEFAULT, BranchName NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
    ProjectName NVARCHAR(500) COLLATE DATABASE_DEFAULT, JobName NVARCHAR(50) COLLATE DATABASE_DEFAULT, SalaryId INT, SalaryDetailId INT, EmployeeIncomeId INT, IncomeAmount MONEY,
    IncomeName NVARCHAR(200) COLLATE DATABASE_DEFAULT, Deduction BIT, EnglishLetter NVARCHAR(5) COLLATE DATABASE_DEFAULT, SalaryMainId INT, Total MONEY, Remarks NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    InsuranceCompany MONEY, TotalAdditions MONEY, TotalDeductions MONEY, PostDate DATETIME, Posted BIT, SalaryYear INT, SalaryMonth INT, SalaryDate DATETIME, Suspend BIT, SalaryDetailSuspend BIT,
    BankId INT, BankName NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankSEPA BIT, BankAddress NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankBranch NVARCHAR(100) COLLATE DATABASE_DEFAULT,
    BankCountry NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankAccountOwner NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankSwiftCode NVARCHAR(100) COLLATE DATABASE_DEFAULT);
DECLARE @Seed TABLE (stage VARCHAR(20), tbl VARCHAR(20), id INT, Suspend BIT);
DECLARE @K TABLE (i INT, c VARCHAR(40), p NVARCHAR(200), ids NVARCHAR(MAX), lvl INT);
DECLARE @i INT = 1, @maxI INT, @c VARCHAR(40), @ids NVARCHAR(MAX), @lvl INT;
INSERT @K VALUES
 (1, 'a1 8/2026 all, lvl 5',   N'8/2026 ids NULL lvl 5', NULL, 5),
 (2, 'a2 8/2026 all, lvl 1',   N'8/2026 ids NULL lvl 1', NULL, 1),
 (3, 'b1 8/2026 ids 3, lvl 5', N'8/2026 ids 3 lvl 5',    N'3', 5);
INSERT @Seed SELECT 'before', 'PR_Salaries', SalaryId, Suspend FROM dbo.PR_Salaries WHERE SalaryId = @SalaryId
UNION ALL SELECT 'before', 'PR_SalaryDetail', SalaryDetailId, Suspend FROM dbo.PR_SalaryDetail WHERE SalaryDetailId = @DetailId;

BEGIN TRAN;
UPDATE dbo.PR_Salaries SET Suspend = 1 WHERE SalaryId = @SalaryId;
UPDATE dbo.PR_SalaryDetail SET Suspend = 1 WHERE SalaryDetailId = @DetailId;
INSERT @Seed SELECT 'inside tran', 'PR_Salaries', SalaryId, Suspend FROM dbo.PR_Salaries WHERE SalaryId = @SalaryId
UNION ALL SELECT 'inside tran', 'PR_SalaryDetail', SalaryDetailId, Suspend FROM dbo.PR_SalaryDetail WHERE SalaryDetailId = @DetailId;
SELECT @maxI = MAX(i) FROM @K;
WHILE @i <= @maxI
BEGIN
    SELECT @c = c, @ids = ids, @lvl = lvl FROM @K WHERE i = @i;
    INSERT @L (EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryId2, SalaryMainId, Total, Remarks,
               InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode)
        EXEC sp_executesql @Legacy, @LP, @SalaryMonth = @Month, @SalaryYear = @Year, @EmployeeSecurityLevel = @lvl, @EmployeeId = @ids;
    UPDATE @L SET c = @c WHERE c IS NULL;
    INSERT @N SELECT @c, EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode FROM dbo.PR_EmployeeSalaryReceiptReport(@Month, @Year, @ids, @lvl);
    SET @i += 1;
END
ROLLBACK TRAN;
SET @ms = DATEDIFF(MILLISECOND, @t0, SYSDATETIME());
INSERT @Seed SELECT 'after rollback', 'PR_Salaries', SalaryId, Suspend FROM dbo.PR_Salaries WHERE SalaryId = @SalaryId
UNION ALL SELECT 'after rollback', 'PR_SalaryDetail', SalaryDetailId, Suspend FROM dbo.PR_SalaryDetail WHERE SalaryDetailId = @DetailId;
SELECT @ms AS tran_ms, @@TRANCOUNT AS trancount_after_rollback, @SalaryId AS seededSalaryId, @DetailId AS seededSalaryDetailId;

SELECT 'R3 legacy vs TVF (legacy Suspend -> Suspend, legacy Suspend1 -> SalaryDetailSuspend)' AS check_;
SELECT x.*, CASE WHEN x.sumsLegacy = x.sumsNew THEN 'yes' ELSE 'NO' END AS sumsEqual,
       CASE WHEN x.legacyRows = x.newRows AND x.L_N = 0 AND x.N_L = 0 AND x.multisetDiff = 0 AND x.sumsLegacy = x.sumsNew THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (SELECT k.c AS [case], k.p AS params,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND 1=1) AS legacyRows,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND 1=1) AS newRows,
  (SELECT COUNT(*) FROM (SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode FROM @L WHERE c = k.c AND 1=1 EXCEPT SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode FROM @N WHERE c = k.c AND 1=1) q) AS L_N,
  (SELECT COUNT(*) FROM (SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode FROM @N WHERE c = k.c AND 1=1 EXCEPT SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode FROM @L WHERE c = k.c AND 1=1) q) AS N_L,
  (SELECT COUNT(*) FROM ((SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode, COUNT(*) AS cnt FROM @L WHERE c = k.c AND 1=1 GROUP BY EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode EXCEPT SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode, COUNT(*) FROM @N WHERE c = k.c AND 1=1 GROUP BY EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode)
                    UNION ALL (SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode, COUNT(*) AS cnt FROM @N WHERE c = k.c AND 1=1 GROUP BY EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode EXCEPT SELECT EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode, COUNT(*) FROM @L WHERE c = k.c AND 1=1 GROUP BY EmployeeId, EmployeeName, EmployeeNumber, BranchName, ProjectName, JobName, SalaryId, SalaryDetailId, EmployeeIncomeId, IncomeAmount, IncomeName, Deduction, EnglishLetter, SalaryMainId, Total, Remarks, InsuranceCompany, TotalAdditions, TotalDeductions, PostDate, Posted, SalaryYear, SalaryMonth, SalaryDate, Suspend, SalaryDetailSuspend, BankId, BankName, BankSEPA, BankAddress, BankBranch, BankCountry, BankAccountOwner, BankSwiftCode)) q) AS multisetDiff,
  (SELECT ISNULL(CAST(SUM(CAST(IncomeAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(Total AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(InsuranceCompany AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalAdditions AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalDeductions AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @L WHERE c = k.c AND 1=1) AS sumsLegacy,
  (SELECT ISNULL(CAST(SUM(CAST(IncomeAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(Total AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(InsuranceCompany AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalAdditions AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalDeductions AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @N WHERE c = k.c AND 1=1) AS sumsNew
 FROM @K k) x ORDER BY x.[case];
SELECT 'R3 Suspend mapping: flagged rows per column, legacy vs TVF, and the swapped mapping' AS check_;
SELECT x.*, CASE WHEN legSuspend1 = newSuspend1 AND legSuspend1 = linesOfSalary AND legDetail1 = 1 AND newDetail1 = 1 AND legDetailId = @DetailId AND newDetailId = @DetailId
                      AND salaryIdMismatch = 0 AND (linesOfSalary = 0 OR swappedL_N > 0) THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (SELECT k.c AS [case],
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND SalaryId = @SalaryId) AS linesOfSalary,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND Suspend = 1) AS legSuspend1,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND Suspend = 1) AS newSuspend1,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND SalaryDetailSuspend = 1) AS legDetail1,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND SalaryDetailSuspend = 1) AS newDetail1,
  (SELECT MAX(SalaryDetailId) FROM @L WHERE c = k.c AND SalaryDetailSuspend = 1) AS legDetailId,
  (SELECT MAX(SalaryDetailId) FROM @N WHERE c = k.c AND SalaryDetailSuspend = 1) AS newDetailId,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND ISNULL(SalaryId2, -1) <> ISNULL(SalaryId, -1)) AS salaryIdMismatch,
  (SELECT COUNT(*) FROM (SELECT SalaryDetailId, SalaryDetailSuspend AS s1, Suspend AS s2 FROM @L WHERE c = k.c EXCEPT SELECT SalaryDetailId, Suspend, SalaryDetailSuspend FROM @N WHERE c = k.c) q) AS swappedL_N
 FROM @K k) x ORDER BY x.[case];
SELECT * FROM @Seed ORDER BY tbl, stage;
GO
-- post-run re-query, outside any transaction
SELECT 'post-run' AS what, @@TRANCOUNT AS trancount,
       (SELECT COUNT(*) FROM dbo.PR_Salaries WHERE Suspend = 1) AS salariesSuspend1, (SELECT COUNT(*) FROM dbo.PR_SalaryDetail WHERE Suspend = 1) AS salaryDetailSuspend1,
       (SELECT COUNT(*) FROM dbo.PR_Salaries s JOIN dbo.PR_SalaryMain m ON m.SalaryMainId = s.SalaryMainId WHERE m.SalaryMonth = 8 AND m.SalaryYear = 2026 AND s.EmployeeId = 3 AND s.Suspend = 0) AS emp3SalaryUnsuspended;
