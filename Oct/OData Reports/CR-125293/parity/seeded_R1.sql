-- CR 125293 seeded parity R1 EmployeesSalariesItems (legacy dsEmployeeFinance.xsd PR_Emp_Income vs dbo.PR_EmployeesSalariesItemsReport) on db-all / UNP-Ali.
-- ROLLBACK-ONLY: one transaction, ends with ROLLBACK TRAN. Sets EndWork = 1 on 2 employees that have open PR_EmployeeIncome rows (employees 1 and 2).
-- No triggers on PR_Employee (sys.triggers). Results go to table variables, which survive the rollback. Run: bash run.sh seeded_R1.sql
SET XACT_ABORT ON; SET NOCOUNT ON;
DECLARE @Legacy NVARCHAR(MAX) = N'SELECT PR_EmployeeIncome.EmployeeIncomeId,
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
                   WHEN (LTRIM(RTRIM(PR_Employee.EmployeeArabicName))) = '''' THEN
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
          @empIds = ''All''
          OR
          (
              @empIds = ''AllInService''
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 0
                  )
          )
          OR
          (
              @empIds = ''AllTerminated''
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 1
                  )
          )
          OR
          (
              @empIds NOT IN ( ''All'', ''AllInService'', ''AllTerminated'' )
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@empIds)
                  )
          )
      )
      AND (@IsArabic = @IsArabic)
      AND IncomeEndDate IS NULL;
';
DECLARE @LP NVARCHAR(MAX) = N'@empIds VARCHAR(8000), @IsArabic BIT';
DECLARE @E1 INT = 1, @E2 INT = 2;
DECLARE @t0 DATETIME2 = SYSDATETIME(), @ms INT;
DECLARE @L TABLE (c VARCHAR(40), EmployeeIncomeId INT, EmployeeId INT, IncomeId INT, IncomeCurrency INT, IncomeAmount MONEY, IncomeStartDate DATE, IncomeTaxRoleId INT, SocialInsuranceRoleId INT,
    EmployeeInsuranceAmount MONEY, CompanyInsuranceAmount MONEY, CurrencyName NVARCHAR(50) COLLATE DATABASE_DEFAULT, IncomeName NVARCHAR(200) COLLATE DATABASE_DEFAULT, Deduction BIT,
    EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, SocialInsuranceRole NVARCHAR(100) COLLATE DATABASE_DEFAULT, DepartmentName NVARCHAR(50) COLLATE DATABASE_DEFAULT, JobName NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    BranchName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, DateOfWork DATETIME, EmployeeNumber NVARCHAR(100) COLLATE DATABASE_DEFAULT, IDNumber NVARCHAR(50) COLLATE DATABASE_DEFAULT, ProjectName NVARCHAR(500) COLLATE DATABASE_DEFAULT);
DECLARE @N TABLE (c VARCHAR(40), EmployeeIncomeId INT, EmployeeId INT, IncomeId INT, IncomeCurrency INT, IncomeAmount MONEY, IncomeStartDate DATE, IncomeTaxRoleId INT, SocialInsuranceRoleId INT,
    EmployeeInsuranceAmount MONEY, CompanyInsuranceAmount MONEY, CurrencyName NVARCHAR(50) COLLATE DATABASE_DEFAULT, IncomeName NVARCHAR(200) COLLATE DATABASE_DEFAULT, Deduction BIT,
    EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, SocialInsuranceRole NVARCHAR(100) COLLATE DATABASE_DEFAULT, DepartmentName NVARCHAR(50) COLLATE DATABASE_DEFAULT, JobName NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    BranchName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, DateOfWork DATETIME, EmployeeNumber NVARCHAR(100) COLLATE DATABASE_DEFAULT, IDNumber NVARCHAR(50) COLLATE DATABASE_DEFAULT, ProjectName NVARCHAR(500) COLLATE DATABASE_DEFAULT);
DECLARE @Seed TABLE (stage VARCHAR(20), EmployeeId INT, EndWork BIT, openIncomeRows INT);
DECLARE @K TABLE (i INT, c VARCHAR(40), p NVARCHAR(200), legacyArg VARCHAR(8000), ids NVARCHAR(MAX), flt NVARCHAR(20), isAr BIT);
DECLARE @i INT = 1, @maxI INT, @c VARCHAR(40), @arg VARCHAR(8000), @ids NVARCHAR(MAX), @flt NVARCHAR(20), @isAr BIT;
INSERT @K VALUES
 (1, 'a0 All ar0 (new filter NULL)',  N'legacy ''All'',0 -> new (NULL,NULL,0)',                     'All',           NULL, NULL,            0),
 (2, 'a1 All ar0',                    N'legacy ''All'',0 -> new (NULL,''All'',0)',                  'All',           NULL, 'All',           0),
 (3, 'a2 All ar1',                    N'legacy ''All'',1 -> new (NULL,''All'',1)',                  'All',           NULL, 'All',           1),
 (4, 'b1 AllInService ar0',           N'legacy ''AllInService'',0 -> new (NULL,''AllInService'',0)', 'AllInService', NULL, 'AllInService',  0),
 (5, 'b2 AllInService ar1',           N'legacy ''AllInService'',1 -> new (NULL,''AllInService'',1)', 'AllInService', NULL, 'AllInService',  1),
 (6, 'c1 AllTerminated ar0',          N'legacy ''AllTerminated'',0 -> new (NULL,''AllTerminated'',0)', 'AllTerminated', NULL, 'AllTerminated', 0),
 (7, 'c2 AllTerminated ar1',          N'legacy ''AllTerminated'',1 -> new (NULL,''AllTerminated'',1)', 'AllTerminated', NULL, 'AllTerminated', 1),
 (8, 'd1 ids 1,9 (one terminated)',   N'legacy ''1,9'',0 -> new (''1,9'',NULL,0)',                  '1,9',           N'1,9', NULL,          0);
INSERT @Seed SELECT 'before', e.EmployeeId, e.EndWork, (SELECT COUNT(*) FROM dbo.PR_EmployeeIncome i WHERE i.EmployeeId = e.EmployeeId AND i.IncomeEndDate IS NULL) FROM dbo.PR_Employee e WHERE e.EmployeeId IN (@E1, @E2);

BEGIN TRAN;
UPDATE dbo.PR_Employee SET EndWork = 1 WHERE EmployeeId IN (@E1, @E2);
INSERT @Seed SELECT 'inside tran', e.EmployeeId, e.EndWork, (SELECT COUNT(*) FROM dbo.PR_EmployeeIncome i WHERE i.EmployeeId = e.EmployeeId AND i.IncomeEndDate IS NULL) FROM dbo.PR_Employee e WHERE e.EmployeeId IN (@E1, @E2);
SELECT @maxI = MAX(i) FROM @K;
WHILE @i <= @maxI
BEGIN
    SELECT @c = c, @arg = legacyArg, @ids = ids, @flt = flt, @isAr = isAr FROM @K WHERE i = @i;
    INSERT @L (EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName)
        EXEC sp_executesql @Legacy, @LP, @empIds = @arg, @IsArabic = @isAr;
    UPDATE @L SET c = @c WHERE c IS NULL;
    INSERT @N SELECT @c, EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName FROM dbo.PR_EmployeesSalariesItemsReport(@ids, @flt, @isAr);
    SET @i += 1;
END
ROLLBACK TRAN;
SET @ms = DATEDIFF(MILLISECOND, @t0, SYSDATETIME());
INSERT @Seed SELECT 'after rollback', e.EmployeeId, e.EndWork, (SELECT COUNT(*) FROM dbo.PR_EmployeeIncome i WHERE i.EmployeeId = e.EmployeeId AND i.IncomeEndDate IS NULL) FROM dbo.PR_Employee e WHERE e.EmployeeId IN (@E1, @E2);
SELECT @ms AS tran_ms, @@TRANCOUNT AS trancount_after_rollback;

SELECT 'R1 legacy vs TVF' AS check_;
SELECT x.*, CASE WHEN x.sumsLegacy = x.sumsNew THEN 'yes' ELSE 'NO' END AS sumsEqual,
       CASE WHEN x.legacyRows = x.newRows AND x.L_N = 0 AND x.N_L = 0 AND x.multisetDiff = 0 AND x.sumsLegacy = x.sumsNew THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (SELECT k.c AS [case], k.p AS params,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND 1=1) AS legacyRows,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND 1=1) AS newRows,
  (SELECT COUNT(*) FROM (SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName FROM @L WHERE c = k.c AND 1=1 EXCEPT SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName FROM @N WHERE c = k.c AND 1=1) q) AS L_N,
  (SELECT COUNT(*) FROM (SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName FROM @N WHERE c = k.c AND 1=1 EXCEPT SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName FROM @L WHERE c = k.c AND 1=1) q) AS N_L,
  (SELECT COUNT(*) FROM ((SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName, COUNT(*) AS cnt FROM @L WHERE c = k.c AND 1=1 GROUP BY EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName EXCEPT SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName, COUNT(*) FROM @N WHERE c = k.c AND 1=1 GROUP BY EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName)
                    UNION ALL (SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName, COUNT(*) AS cnt FROM @N WHERE c = k.c AND 1=1 GROUP BY EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName EXCEPT SELECT EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName, COUNT(*) FROM @L WHERE c = k.c AND 1=1 GROUP BY EmployeeIncomeId, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount, CurrencyName, IncomeName, Deduction, EmployeeName, SocialInsuranceRole, DepartmentName, JobName, BranchName, DateOfWork, EmployeeNumber, IDNumber, ProjectName)) q) AS multisetDiff,
  (SELECT ISNULL(CAST(SUM(CAST(IncomeAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(EmployeeInsuranceAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(CompanyInsuranceAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @L WHERE c = k.c AND 1=1) AS sumsLegacy,
  (SELECT ISNULL(CAST(SUM(CAST(IncomeAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(EmployeeInsuranceAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(CompanyInsuranceAmount AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @N WHERE c = k.c AND 1=1) AS sumsNew
 FROM @K k) x ORDER BY x.[case];
SELECT 'R1 AllTerminated returns only the 2 seeded employees, all their open income rows' AS check_;
SELECT k.c AS [case],
  (SELECT STRING_AGG(CAST(EmployeeId AS VARCHAR(10)), ',') WITHIN GROUP (ORDER BY EmployeeId) FROM (SELECT DISTINCT EmployeeId FROM @N WHERE c = k.c) d) AS newEmployees,
  (SELECT STRING_AGG(CAST(EmployeeId AS VARCHAR(10)), ',') WITHIN GROUP (ORDER BY EmployeeId) FROM (SELECT DISTINCT EmployeeId FROM @L WHERE c = k.c) d) AS legacyEmployees,
  (SELECT COUNT(*) FROM @N WHERE c = k.c) AS newRows,
  (SELECT SUM(openIncomeRows) FROM @Seed WHERE stage = 'inside tran') AS expectedRows,
  CASE WHEN (SELECT COUNT(*) FROM @N WHERE c = k.c AND EmployeeId NOT IN (@E1, @E2)) = 0
        AND (SELECT COUNT(DISTINCT EmployeeId) FROM @N WHERE c = k.c) = 2
        AND (SELECT COUNT(*) FROM @N WHERE c = k.c) = (SELECT SUM(openIncomeRows) FROM @Seed WHERE stage = 'inside tran') THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM @K k WHERE k.flt = 'AllTerminated';
SELECT 'R1 All = AllInService + AllTerminated (TVF, ar0)' AS check_,
  (SELECT COUNT(*) FROM @N WHERE c = 'a1 All ar0') AS allRows, (SELECT COUNT(*) FROM @N WHERE c = 'b1 AllInService ar0') AS inServiceRows, (SELECT COUNT(*) FROM @N WHERE c = 'c1 AllTerminated ar0') AS terminatedRows,
  (SELECT COUNT(*) FROM @N WHERE c = 'b1 AllInService ar0' AND EmployeeId IN (@E1, @E2)) AS terminatedInInService;
SELECT * FROM @Seed ORDER BY stage, EmployeeId;
GO
-- post-run re-query, outside any transaction
SELECT 'post-run' AS what, @@TRANCOUNT AS trancount, (SELECT COUNT(*) FROM dbo.PR_Employee WHERE EndWork = 1) AS employeesEndWork1,
       (SELECT STRING_AGG(CONCAT(EmployeeId, ':', CAST(EndWork AS INT)), ',') FROM dbo.PR_Employee WHERE EmployeeId IN (1, 2)) AS seededEmployeesEndWork;
