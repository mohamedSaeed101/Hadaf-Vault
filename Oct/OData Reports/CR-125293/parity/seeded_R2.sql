-- CR 125293 seeded parity R2 PayCheck (legacy dsSalariesReport.xsd Salaries vs dbo.PR_PayCheckReport) on db-all / UNP-Ali.
-- ROLLBACK-ONLY: one transaction, ends with ROLLBACK TRAN. Seeds one UNPAID Pr_PayingSalaries header (7/2026) with 5 lines copied from the paid header 2.
-- Explicit negative identity values (SET IDENTITY_INSERT, a session option, not DDL) so the rolled-back insert cannot advance the identity seed
-- (a normal insert would leave a persistent identity gap). No triggers on Pr_PayingSalaries / Pr_PayingSalariesDetail (sys.triggers).
-- Results go to table variables, which survive the rollback. Run: bash run.sh seeded_R2.sql
SET XACT_ABORT ON; SET NOCOUNT ON;
DECLARE @Legacy NVARCHAR(MAX) = N'SELECT  Pr_PayingSalariesDetail.EmployeeSalary ,
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
';
DECLARE @LP NVARCHAR(MAX) = N'@MONTH INT, @YEAR INT, @EmployeeId NVARCHAR(MAX), @EmployeeSecurityLevel INT, @BankList NVARCHAR(MAX)';
DECLARE @Month INT = 7, @Year INT = 2026, @PaidHeader INT = 2, @NewHeader INT = -1;
DECLARE @t0 DATETIME2 = SYSDATETIME(), @ms INT;
DECLARE @L TABLE (c VARCHAR(40), EmployeeSalary MONEY, CurrencyName NVARCHAR(50) COLLATE DATABASE_DEFAULT, CurrencyNameArabic NVARCHAR(50) COLLATE DATABASE_DEFAULT, EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
    BranchName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, DepartmentName NVARCHAR(50) COLLATE DATABASE_DEFAULT, ProjectName NVARCHAR(500) COLLATE DATABASE_DEFAULT, JobName NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    EmployeeNumber NVARCHAR(100) COLLATE DATABASE_DEFAULT, BankName NVARCHAR(100) COLLATE DATABASE_DEFAULT, EmployeeArabicName NVARCHAR(1000) COLLATE DATABASE_DEFAULT);
DECLARE @N TABLE (c VARCHAR(40), pf CHAR(1), EmployeeId INT, EmployeeNumber NVARCHAR(100) COLLATE DATABASE_DEFAULT, EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, EmployeeArabicName NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
    BranchName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, DepartmentName NVARCHAR(50) COLLATE DATABASE_DEFAULT, ProjectName NVARCHAR(500) COLLATE DATABASE_DEFAULT, JobName NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    BankName NVARCHAR(100) COLLATE DATABASE_DEFAULT, CurrencyName NVARCHAR(50) COLLATE DATABASE_DEFAULT, CurrencyNameArabic NVARCHAR(50) COLLATE DATABASE_DEFAULT, EmployeeSalary MONEY, IsPaid BIT);
DECLARE @Exp TABLE (c VARCHAR(40), IsPaid BIT, EmployeeId INT, EmployeeSalary MONEY);
DECLARE @Seed TABLE (PayingSalariesDetailId INT, PayingSalariesId INT, EmployeeId INT, EmployeeSalary MONEY, EmployeeSecurityLevel INT, HeaderIsPaid BIT);
DECLARE @Ident TABLE (stage VARCHAR(20), identHeader INT, identDetail INT, headerRows INT, detailRows INT);
DECLARE @K TABLE (i INT, c VARCHAR(40), p NVARCHAR(200), ids NVARCHAR(MAX), banks NVARCHAR(MAX), lvl INT);
DECLARE @i INT = 1, @maxI INT, @c VARCHAR(40), @ids NVARCHAR(MAX), @banks NVARCHAR(MAX), @lvl INT;
INSERT @K VALUES
 (1, 'a1 all, lvl 5',                N'7/2026 ids NULL banks NULL lvl 5', NULL, NULL, 5),
 (2, 'a2 all, lvl 1',                N'7/2026 ids NULL banks NULL lvl 1', NULL, NULL, 1),
 (3, 'b1 ids 1,4,9 + bank 1, lvl 5', N'7/2026 ids 1,4,9 banks 1 lvl 5',   N'1,4,9', N'1', 5),
 (4, 'b2 ids 1,4,9 + bank 1, lvl 1', N'7/2026 ids 1,4,9 banks 1 lvl 1',   N'1,4,9', N'1', 1);
INSERT @Ident SELECT 'before', CAST(IDENT_CURRENT('Pr_PayingSalaries') AS INT), CAST(IDENT_CURRENT('Pr_PayingSalariesDetail') AS INT), (SELECT COUNT(*) FROM Pr_PayingSalaries), (SELECT COUNT(*) FROM Pr_PayingSalariesDetail);

BEGIN TRAN;
SET IDENTITY_INSERT dbo.Pr_PayingSalaries ON;
INSERT dbo.Pr_PayingSalaries (PayingSalariesId, BankId, CurrencyId, TotalSalaries, PayingSalariesMonth, PayingSalaryYear, PayingSalariesDate, IsPaid, IsPaidFromStore, TransactionTypeId, Description, Serial, IncomeCategoryId, IncludePreviousPeriods)
SELECT @NewHeader, BankId, CurrencyId, NULL, PayingSalariesMonth, PayingSalaryYear, PayingSalariesDate, 0, IsPaidFromStore, TransactionTypeId, N'CR125293 seeded parity (rolled back)', Serial + 1, IncomeCategoryId, IncludePreviousPeriods
FROM dbo.Pr_PayingSalaries WHERE PayingSalariesId = @PaidHeader;
SET IDENTITY_INSERT dbo.Pr_PayingSalaries OFF;
SET IDENTITY_INSERT dbo.Pr_PayingSalariesDetail ON;
-- 5 lines copied from the paid header: its 5 lowest EmployeeIds (employee 4 is security level 5, so the lvl-1 cases drop one unpaid line)
INSERT dbo.Pr_PayingSalariesDetail (PayingSalariesDetailId, PayingSalariesId, EmployeeId, EmployeeSalary, SalaryId, EmployeeTransactionId, SalaryAmount, VacationAllowanceAmount, SeverancePackageAmount)
SELECT -ROW_NUMBER() OVER (ORDER BY d.EmployeeId), @NewHeader, d.EmployeeId, d.EmployeeSalary, d.SalaryId, d.EmployeeTransactionId, d.SalaryAmount, d.VacationAllowanceAmount, d.SeverancePackageAmount
FROM (SELECT TOP 5 * FROM dbo.Pr_PayingSalariesDetail WHERE PayingSalariesId = @PaidHeader ORDER BY EmployeeId) d;
SET IDENTITY_INSERT dbo.Pr_PayingSalariesDetail OFF;
UPDATE dbo.Pr_PayingSalaries SET TotalSalaries = (SELECT SUM(EmployeeSalary) FROM dbo.Pr_PayingSalariesDetail WHERE PayingSalariesId = @NewHeader) WHERE PayingSalariesId = @NewHeader;
INSERT @Seed SELECT d.PayingSalariesDetailId, d.PayingSalariesId, d.EmployeeId, d.EmployeeSalary, e.EmployeeSecurityLevel, h.IsPaid
FROM dbo.Pr_PayingSalariesDetail d JOIN dbo.Pr_PayingSalaries h ON h.PayingSalariesId = d.PayingSalariesId JOIN dbo.PR_Employee e ON e.EmployeeId = d.EmployeeId WHERE d.PayingSalariesId = @NewHeader;
INSERT @Ident SELECT 'inside tran', CAST(IDENT_CURRENT('Pr_PayingSalaries') AS INT), CAST(IDENT_CURRENT('Pr_PayingSalariesDetail') AS INT), (SELECT COUNT(*) FROM Pr_PayingSalaries), (SELECT COUNT(*) FROM Pr_PayingSalariesDetail);

SELECT @maxI = MAX(i) FROM @K;
WHILE @i <= @maxI
BEGIN
    SELECT @c = c, @ids = ids, @banks = banks, @lvl = lvl FROM @K WHERE i = @i;
    INSERT @L (EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName)
        EXEC sp_executesql @Legacy, @LP, @MONTH = @Month, @YEAR = @Year, @EmployeeId = @ids, @EmployeeSecurityLevel = @lvl, @BankList = @banks;
    UPDATE @L SET c = @c WHERE c IS NULL;
    INSERT @N SELECT @c, 'N', EmployeeId, EmployeeNumber, EmployeeName, EmployeeArabicName, BranchName, DepartmentName, ProjectName, JobName, BankName, CurrencyName, CurrencyNameArabic, EmployeeSalary, IsPaid FROM dbo.PR_PayCheckReport(@Month, @Year, @ids, @banks, NULL, @lvl);
    INSERT @N SELECT @c, '0', EmployeeId, EmployeeNumber, EmployeeName, EmployeeArabicName, BranchName, DepartmentName, ProjectName, JobName, BankName, CurrencyName, CurrencyNameArabic, EmployeeSalary, IsPaid FROM dbo.PR_PayCheckReport(@Month, @Year, @ids, @banks, 0, @lvl);
    INSERT @N SELECT @c, '1', EmployeeId, EmployeeNumber, EmployeeName, EmployeeArabicName, BranchName, DepartmentName, ProjectName, JobName, BankName, CurrencyName, CurrencyNameArabic, EmployeeSalary, IsPaid FROM dbo.PR_PayCheckReport(@Month, @Year, @ids, @banks, 1, @lvl);
    -- expected subsets straight from the base tables, split by the header flag
    INSERT @Exp SELECT @c, h.IsPaid, d.EmployeeId, d.EmployeeSalary
    FROM dbo.Pr_PayingSalariesDetail d JOIN dbo.Pr_PayingSalaries h ON h.PayingSalariesId = d.PayingSalariesId JOIN dbo.PR_Employee e ON e.EmployeeId = d.EmployeeId
    WHERE h.PayingSalariesMonth = @Month AND h.PayingSalaryYear = @Year AND e.EmployeeSecurityLevel <= @lvl
      AND (@ids IS NULL OR d.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@ids)))
      AND (@banks IS NULL OR h.BankId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@banks)));
    SET @i += 1;
END
ROLLBACK TRAN;
SET @ms = DATEDIFF(MILLISECOND, @t0, SYSDATETIME());
INSERT @Ident SELECT 'after rollback', CAST(IDENT_CURRENT('Pr_PayingSalaries') AS INT), CAST(IDENT_CURRENT('Pr_PayingSalariesDetail') AS INT), (SELECT COUNT(*) FROM Pr_PayingSalaries), (SELECT COUNT(*) FROM Pr_PayingSalariesDetail);
SELECT @ms AS tran_ms, @@TRANCOUNT AS trancount_after_rollback;

SELECT 'seeded unpaid line' AS what, * FROM @Seed ORDER BY EmployeeId;
SELECT 'R2 legacy (no paid filter) vs TVF @IsPaid NULL' AS check_;
SELECT x.*, CASE WHEN x.sumsLegacy = x.sumsNew THEN 'yes' ELSE 'NO' END AS sumsEqual,
       CASE WHEN x.legacyRows = x.newRows AND x.L_N = 0 AND x.N_L = 0 AND x.multisetDiff = 0 AND x.sumsLegacy = x.sumsNew THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (SELECT k.c AS [case], k.p AS params,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND 1=1) AS legacyRows,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND pf = 'N') AS newRows,
  (SELECT COUNT(*) FROM (SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName FROM @L WHERE c = k.c AND 1=1 EXCEPT SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName FROM @N WHERE c = k.c AND pf = 'N') q) AS L_N,
  (SELECT COUNT(*) FROM (SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName FROM @N WHERE c = k.c AND pf = 'N' EXCEPT SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName FROM @L WHERE c = k.c AND 1=1) q) AS N_L,
  (SELECT COUNT(*) FROM ((SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, COUNT(*) AS cnt FROM @L WHERE c = k.c AND 1=1 GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName EXCEPT SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, COUNT(*) FROM @N WHERE c = k.c AND pf = 'N' GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName)
                    UNION ALL (SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, COUNT(*) AS cnt FROM @N WHERE c = k.c AND pf = 'N' GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName EXCEPT SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, COUNT(*) FROM @L WHERE c = k.c AND 1=1 GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName)) q) AS multisetDiff,
  (SELECT ISNULL(CAST(SUM(CAST(EmployeeSalary AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @L WHERE c = k.c AND 1=1) AS sumsLegacy,
  (SELECT ISNULL(CAST(SUM(CAST(EmployeeSalary AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @N WHERE c = k.c AND pf = 'N') AS sumsNew
 FROM @K k) x ORDER BY x.[case];
SELECT 'R2 Fix: TVF @IsPaid 0 / 1 vs base-table rows by header flag, and (0 UNION ALL 1) vs NULL' AS check_;
SELECT x.*, CASE WHEN unpaidRows = expUnpaid AND paidRows = expPaid AND unpaidVsExpDiff = 0 AND paidVsExpDiff = 0 AND wrongFlag = 0 AND unionVsNullDiff = 0
                      AND unpaidRows + paidRows = nullRows AND sumNull = sumUnion THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (SELECT k.c AS [case],
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND pf = 'N') AS nullRows,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND pf = '0') AS unpaidRows,
  (SELECT COUNT(*) FROM @Exp WHERE c = k.c AND IsPaid = 0) AS expUnpaid,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND pf = '1') AS paidRows,
  (SELECT COUNT(*) FROM @Exp WHERE c = k.c AND IsPaid = 1) AS expPaid,
  (SELECT COUNT(*) FROM ((SELECT EmployeeId, EmployeeSalary, COUNT(*) n FROM @N WHERE c = k.c AND pf = '0' GROUP BY EmployeeId, EmployeeSalary EXCEPT SELECT EmployeeId, EmployeeSalary, COUNT(*) FROM @Exp WHERE c = k.c AND IsPaid = 0 GROUP BY EmployeeId, EmployeeSalary)
              UNION ALL (SELECT EmployeeId, EmployeeSalary, COUNT(*) n FROM @Exp WHERE c = k.c AND IsPaid = 0 GROUP BY EmployeeId, EmployeeSalary EXCEPT SELECT EmployeeId, EmployeeSalary, COUNT(*) FROM @N WHERE c = k.c AND pf = '0' GROUP BY EmployeeId, EmployeeSalary)) q) AS unpaidVsExpDiff,
  (SELECT COUNT(*) FROM ((SELECT EmployeeId, EmployeeSalary, COUNT(*) n FROM @N WHERE c = k.c AND pf = '1' GROUP BY EmployeeId, EmployeeSalary EXCEPT SELECT EmployeeId, EmployeeSalary, COUNT(*) FROM @Exp WHERE c = k.c AND IsPaid = 1 GROUP BY EmployeeId, EmployeeSalary)
              UNION ALL (SELECT EmployeeId, EmployeeSalary, COUNT(*) n FROM @Exp WHERE c = k.c AND IsPaid = 1 GROUP BY EmployeeId, EmployeeSalary EXCEPT SELECT EmployeeId, EmployeeSalary, COUNT(*) FROM @N WHERE c = k.c AND pf = '1' GROUP BY EmployeeId, EmployeeSalary)) q) AS paidVsExpDiff,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND pf = '0' AND ISNULL(IsPaid, 1) <> 0) + (SELECT COUNT(*) FROM @N WHERE c = k.c AND pf = '1' AND ISNULL(IsPaid, 0) <> 1) AS wrongFlag,
  (SELECT COUNT(*) FROM ((SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid, COUNT(*) n FROM @N WHERE c = k.c AND pf IN ('0', '1') GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid EXCEPT SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid, COUNT(*) FROM @N WHERE c = k.c AND pf = 'N' GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid)
              UNION ALL (SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid, COUNT(*) n FROM @N WHERE c = k.c AND pf = 'N' GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid EXCEPT SELECT EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid, COUNT(*) FROM @N WHERE c = k.c AND pf IN ('0', '1') GROUP BY EmployeeSalary, CurrencyName, CurrencyNameArabic, EmployeeName, BranchName, DepartmentName, ProjectName, JobName, EmployeeNumber, BankName, EmployeeArabicName, EmployeeId, IsPaid)) q) AS unionVsNullDiff,
  (SELECT ISNULL(SUM(EmployeeSalary), 0) FROM @N WHERE c = k.c AND pf = 'N') AS sumNull,
  (SELECT ISNULL(SUM(EmployeeSalary), 0) FROM @N WHERE c = k.c AND pf IN ('0', '1')) AS sumUnion,
  (SELECT SUM(EmployeeSalary) FROM @N WHERE c = k.c AND pf = '0') AS sumUnpaid,
  (SELECT SUM(EmployeeSalary) FROM @N WHERE c = k.c AND pf = '1') AS sumPaid
 FROM @K k) x ORDER BY x.[case];
SELECT 'unpaid subset rows (TVF @IsPaid = 0)' AS what, c, EmployeeId, EmployeeSalary, IsPaid FROM @N WHERE pf = '0' ORDER BY c, EmployeeId;
SELECT * FROM @Ident;
GO
-- post-run re-query, outside any transaction
SELECT 'post-run' AS what, @@TRANCOUNT AS trancount,
       (SELECT COUNT(*) FROM dbo.Pr_PayingSalaries) AS headers, (SELECT COUNT(*) FROM dbo.Pr_PayingSalaries WHERE IsPaid = 0 OR PayingSalariesId < 0) AS unpaidOrSeededHeaders,
       (SELECT COUNT(*) FROM dbo.Pr_PayingSalariesDetail) AS detailRows, (SELECT COUNT(*) FROM dbo.Pr_PayingSalariesDetail WHERE PayingSalariesId < 0 OR PayingSalariesDetailId < 0) AS seededDetailRows,
       CAST(IDENT_CURRENT('Pr_PayingSalaries') AS INT) AS identHeader, CAST(IDENT_CURRENT('Pr_PayingSalariesDetail') AS INT) AS identDetail;
