-- CR 125293 seeded parity R4 InsuranceRegistration (legacy dsInsuranceRegistration.xsd EmployeeInsurance vs dbo.PR_InsuranceRegistrationReport) on db-all / UNP-Ali.
-- ROLLBACK-ONLY: one transaction, ends with ROLLBACK TRAN. On 2 EndWork = 0 employees with a SocialInsuranceStartDate (5 and 6) sets EndWorkingDate:
-- employee 5 = 2026-01-31 (past), employee 6 = 2027-12-31 (future). No triggers on PR_Employee (sys.triggers). Results go to table variables.
-- src U = legacy_r4.sql (untouched), src F = legacy_r4_fixed.sql (only the approved Fix line). TVF compared on the 22 legacy columns. Run: bash run.sh seeded_R4.sql
SET XACT_ABORT ON; SET NOCOUNT ON;
DECLARE @LegacyU NVARCHAR(MAX) = N'WITH empIncome
AS (SELECT InsuranceNum,
           EmployeeName,
           EmployeeArabicName,
           IDNumber,
           WorkDate,
           DAY(WorkDate) AS WorkDateDay,
           MONTH(WorkDate) AS WorkDateMonth,
           YEAR(WorkDate) AS WorkDateYear,
           DateOfWork,
           DAY(DateOfWork) AS DateOfWorkDay,
           MONTH(DateOfWork) AS DateOfWorkMonth,
           YEAR(DateOfWork) AS DateOfWorkYear,
           CASE
               WHEN
               (
               (
                   SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration
               )   = 0
               OR  SocialInsuranceRoleId IS NULL
               ) THEN
                   ISNULL((PR_EmployeeIncome.IncomeAmount), 0)
               ELSE
                   0
           END AS Income,
           CASE
               WHEN
               (
               (
                   SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration
               )   = 0
               OR  SocialInsuranceRoleId IS NULL
               ) THEN
                   ISNULL((PR_EmployeeIncome.IncomeAmount), 0)
                   * ISNULL(
                     (
                         SELECT TOP (1)
                                Factor
                         FROM dbo.Acc_CurrencyFactor
                         WHERE CurrencyId = PR_EmployeeIncome.IncomeCurrency
                               AND ChangeDate <= PR_EmployeeIncome.IncomeStartDate
                         ORDER BY ChangeDate DESC
                     ),
                     0
                           )
               ELSE
                   0
           END AS IncomeLocal,
           CASE
               WHEN
               (
               (
                   SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration
               )   = 0
               OR  SocialInsuranceRoleId IS NOT NULL
               ) THEN
                   ISNULL((PR_EmployeeIncome.IncomeAmount), 0)
                   * ISNULL(
                     (
                         SELECT TOP (1)
                                Factor
                         FROM dbo.Acc_CurrencyFactor
                         WHERE CurrencyId = PR_EmployeeIncome.IncomeCurrency
                               AND ChangeDate <= PR_EmployeeIncome.IncomeStartDate
                         ORDER BY ChangeDate DESC
                     ),
                     0
                           )
               ELSE
                   0
           END AS InsuranceSubscriptionFee,
           ISNULL(((EmployeeInsuranceAmount)), 0) AS Insurance,
           ISNULL((PR_EmployeeIncome.EmployeeInsuranceAmount), 0)
           * ISNULL(
             (
                 SELECT TOP (1)
                        Factor
                 FROM dbo.Acc_CurrencyFactor
                 WHERE CurrencyId = PR_EmployeeIncome.IncomeCurrency
                       AND ChangeDate <= PR_EmployeeIncome.IncomeStartDate
                 ORDER BY ChangeDate DESC
             ),
             0
                   ) AS InsuranceLocal,
           (
               SELECT STUFF(
                      (
                          SELECT ''  '' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('''')
                      ),
                      1,
                      2,
                      ''''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT ''  '' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('''')
                      ),
                      1,
                      2,
                      ''''
                           )
           ) AS StringIDNumber,
           SocialInsuranceStartDate,
           DAY(SocialInsuranceStartDate) AS SocialInsuranceStartDateDay,
           MONTH(SocialInsuranceStartDate) AS SocialInsuranceStartDateMonth,
           YEAR(SocialInsuranceStartDate) AS SocialInsuranceStartDateYear,
           PR_Gender.Gender
    FROM dbo.PR_Employee AS emps
        LEFT JOIN dbo.PR_EmployeeIncome
            ON PR_EmployeeIncome.EmployeeId = emps.EmployeeId
        LEFT JOIN dbo.PR_Gender
            ON PR_Gender.GenderId = emps.GenderId
    WHERE emps.EndWork = 0
          AND
          (
              emps.EndWorkingDate IS NULL
              OR emps.EndWorkingDate = ''''
              OR emps.EndWorkingDate <
              (
                  SELECT GETDATE()
              )
          )
          AND (emps.SocialInsuranceStartDate
          BETWEEN @fromDate AND @toDate
              )
          AND
          (
              (
                  @employeesIds IS NULL
                  AND (emps.EmployeeId IN
                       (
                           SELECT EmployeeId FROM dbo.PR_Employee
                       )
                      )
              )
              OR
              (
                  @employeesIds = ''''
                  AND (emps.EmployeeId IN
                       (
                           SELECT EmployeeId FROM dbo.PR_Employee
                       )
                      )
              )
              OR (emps.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@employeesIds)
                  )
                 )
          )
          AND emps.EmployeeSecurityLevel <= @SecurityLevel)
SELECT empIncome.InsuranceNum,
       empIncome.EmployeeName,
       empIncome.EmployeeArabicName,
       empIncome.IDNumber,
       empIncome.WorkDate,
       empIncome.WorkDateDay,
       empIncome.WorkDateMonth,
       empIncome.WorkDateYear,
       empIncome.DateOfWork,
       empIncome.DateOfWorkDay,
       empIncome.DateOfWorkMonth,
       empIncome.DateOfWorkYear,
       SUM(empIncome.IncomeLocal) AS TotalIncomeLocal,
       SUM(empIncome.InsuranceLocal) AS TotalInsuranceLocal,
       SUM(empIncome.InsuranceSubscriptionFee) AS InsuranceSubscriptionFee,
       empIncome.StringInsuranceNum,
       empIncome.StringIDNumber,
       empIncome.SocialInsuranceStartDate,
       empIncome.SocialInsuranceStartDateDay,
       empIncome.SocialInsuranceStartDateMonth,
       empIncome.SocialInsuranceStartDateYear,
       empIncome.Gender
FROM empIncome
GROUP BY empIncome.InsuranceNum,
         empIncome.EmployeeName,
         empIncome.EmployeeArabicName,
         empIncome.IDNumber,
         empIncome.WorkDate,
         empIncome.WorkDateDay,
         empIncome.WorkDateMonth,
         empIncome.WorkDateYear,
         empIncome.DateOfWork,
         empIncome.DateOfWorkDay,
         empIncome.DateOfWorkMonth,
         empIncome.DateOfWorkYear,
         empIncome.StringInsuranceNum,
         empIncome.StringIDNumber,
         empIncome.SocialInsuranceStartDate,
         empIncome.SocialInsuranceStartDateDay,
         empIncome.SocialInsuranceStartDateMonth,
         empIncome.SocialInsuranceStartDateYear,
         empIncome.Gender;
';
DECLARE @LegacyF NVARCHAR(MAX) = N'WITH empIncome
AS (SELECT InsuranceNum,
           EmployeeName,
           EmployeeArabicName,
           IDNumber,
           WorkDate,
           DAY(WorkDate) AS WorkDateDay,
           MONTH(WorkDate) AS WorkDateMonth,
           YEAR(WorkDate) AS WorkDateYear,
           DateOfWork,
           DAY(DateOfWork) AS DateOfWorkDay,
           MONTH(DateOfWork) AS DateOfWorkMonth,
           YEAR(DateOfWork) AS DateOfWorkYear,
           CASE
               WHEN
               (
               (
                   SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration
               )   = 0
               OR  SocialInsuranceRoleId IS NULL
               ) THEN
                   ISNULL((PR_EmployeeIncome.IncomeAmount), 0)
               ELSE
                   0
           END AS Income,
           CASE
               WHEN
               (
               (
                   SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration
               )   = 0
               OR  SocialInsuranceRoleId IS NULL
               ) THEN
                   ISNULL((PR_EmployeeIncome.IncomeAmount), 0)
                   * ISNULL(
                     (
                         SELECT TOP (1)
                                Factor
                         FROM dbo.Acc_CurrencyFactor
                         WHERE CurrencyId = PR_EmployeeIncome.IncomeCurrency
                               AND ChangeDate <= PR_EmployeeIncome.IncomeStartDate
                         ORDER BY ChangeDate DESC
                     ),
                     0
                           )
               ELSE
                   0
           END AS IncomeLocal,
           CASE
               WHEN
               (
               (
                   SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration
               )   = 0
               OR  SocialInsuranceRoleId IS NOT NULL
               ) THEN
                   ISNULL((PR_EmployeeIncome.IncomeAmount), 0)
                   * ISNULL(
                     (
                         SELECT TOP (1)
                                Factor
                         FROM dbo.Acc_CurrencyFactor
                         WHERE CurrencyId = PR_EmployeeIncome.IncomeCurrency
                               AND ChangeDate <= PR_EmployeeIncome.IncomeStartDate
                         ORDER BY ChangeDate DESC
                     ),
                     0
                           )
               ELSE
                   0
           END AS InsuranceSubscriptionFee,
           ISNULL(((EmployeeInsuranceAmount)), 0) AS Insurance,
           ISNULL((PR_EmployeeIncome.EmployeeInsuranceAmount), 0)
           * ISNULL(
             (
                 SELECT TOP (1)
                        Factor
                 FROM dbo.Acc_CurrencyFactor
                 WHERE CurrencyId = PR_EmployeeIncome.IncomeCurrency
                       AND ChangeDate <= PR_EmployeeIncome.IncomeStartDate
                 ORDER BY ChangeDate DESC
             ),
             0
                   ) AS InsuranceLocal,
           (
               SELECT STUFF(
                      (
                          SELECT ''  '' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('''')
                      ),
                      1,
                      2,
                      ''''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT ''  '' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('''')
                      ),
                      1,
                      2,
                      ''''
                           )
           ) AS StringIDNumber,
           SocialInsuranceStartDate,
           DAY(SocialInsuranceStartDate) AS SocialInsuranceStartDateDay,
           MONTH(SocialInsuranceStartDate) AS SocialInsuranceStartDateMonth,
           YEAR(SocialInsuranceStartDate) AS SocialInsuranceStartDateYear,
           PR_Gender.Gender
    FROM dbo.PR_Employee AS emps
        LEFT JOIN dbo.PR_EmployeeIncome
            ON PR_EmployeeIncome.EmployeeId = emps.EmployeeId
        LEFT JOIN dbo.PR_Gender
            ON PR_Gender.GenderId = emps.GenderId
    WHERE emps.EndWork = 0
          AND
          (
              emps.EndWorkingDate IS NULL
              OR emps.EndWorkingDate = ''''
              OR emps.EndWorkingDate >= CAST(GETDATE() AS DATE)
          )
          AND (emps.SocialInsuranceStartDate
          BETWEEN @fromDate AND @toDate
              )
          AND
          (
              (
                  @employeesIds IS NULL
                  AND (emps.EmployeeId IN
                       (
                           SELECT EmployeeId FROM dbo.PR_Employee
                       )
                      )
              )
              OR
              (
                  @employeesIds = ''''
                  AND (emps.EmployeeId IN
                       (
                           SELECT EmployeeId FROM dbo.PR_Employee
                       )
                      )
              )
              OR (emps.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@employeesIds)
                  )
                 )
          )
          AND emps.EmployeeSecurityLevel <= @SecurityLevel)
SELECT empIncome.InsuranceNum,
       empIncome.EmployeeName,
       empIncome.EmployeeArabicName,
       empIncome.IDNumber,
       empIncome.WorkDate,
       empIncome.WorkDateDay,
       empIncome.WorkDateMonth,
       empIncome.WorkDateYear,
       empIncome.DateOfWork,
       empIncome.DateOfWorkDay,
       empIncome.DateOfWorkMonth,
       empIncome.DateOfWorkYear,
       SUM(empIncome.IncomeLocal) AS TotalIncomeLocal,
       SUM(empIncome.InsuranceLocal) AS TotalInsuranceLocal,
       SUM(empIncome.InsuranceSubscriptionFee) AS InsuranceSubscriptionFee,
       empIncome.StringInsuranceNum,
       empIncome.StringIDNumber,
       empIncome.SocialInsuranceStartDate,
       empIncome.SocialInsuranceStartDateDay,
       empIncome.SocialInsuranceStartDateMonth,
       empIncome.SocialInsuranceStartDateYear,
       empIncome.Gender
FROM empIncome
GROUP BY empIncome.InsuranceNum,
         empIncome.EmployeeName,
         empIncome.EmployeeArabicName,
         empIncome.IDNumber,
         empIncome.WorkDate,
         empIncome.WorkDateDay,
         empIncome.WorkDateMonth,
         empIncome.WorkDateYear,
         empIncome.DateOfWork,
         empIncome.DateOfWorkDay,
         empIncome.DateOfWorkMonth,
         empIncome.DateOfWorkYear,
         empIncome.StringInsuranceNum,
         empIncome.StringIDNumber,
         empIncome.SocialInsuranceStartDate,
         empIncome.SocialInsuranceStartDateDay,
         empIncome.SocialInsuranceStartDateMonth,
         empIncome.SocialInsuranceStartDateYear,
         empIncome.Gender;
';
DECLARE @LP NVARCHAR(MAX) = N'@fromDate DATETIME, @toDate DATETIME, @employeesIds NVARCHAR(MAX), @SecurityLevel INT';
DECLARE @EPast INT = 5, @EFuture INT = 6;
DECLARE @t0 DATETIME2 = SYSDATETIME(), @ms INT;
DECLARE @L TABLE (c VARCHAR(40), src CHAR(1), InsuranceNum NVARCHAR(50) COLLATE DATABASE_DEFAULT, EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, EmployeeArabicName NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
    IDNumber NVARCHAR(50) COLLATE DATABASE_DEFAULT, WorkDate DATETIME, WorkDateDay INT, WorkDateMonth INT, WorkDateYear INT, DateOfWork DATETIME, DateOfWorkDay INT, DateOfWorkMonth INT, DateOfWorkYear INT,
    TotalIncomeLocal DECIMAL(38,13), TotalInsuranceLocal DECIMAL(38,13), InsuranceSubscriptionFee DECIMAL(38,13), StringInsuranceNum NVARCHAR(MAX) COLLATE DATABASE_DEFAULT, StringIDNumber NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    SocialInsuranceStartDate DATETIME, SocialInsuranceStartDateDay INT, SocialInsuranceStartDateMonth INT, SocialInsuranceStartDateYear INT, Gender NVARCHAR(50) COLLATE DATABASE_DEFAULT);
DECLARE @N TABLE (c VARCHAR(40), InsuranceNum NVARCHAR(50) COLLATE DATABASE_DEFAULT, EmployeeName NVARCHAR(1000) COLLATE DATABASE_DEFAULT, EmployeeArabicName NVARCHAR(1000) COLLATE DATABASE_DEFAULT,
    IDNumber NVARCHAR(50) COLLATE DATABASE_DEFAULT, WorkDate DATETIME, WorkDateDay INT, WorkDateMonth INT, WorkDateYear INT, DateOfWork DATETIME, DateOfWorkDay INT, DateOfWorkMonth INT, DateOfWorkYear INT,
    TotalIncomeLocal DECIMAL(38,13), TotalInsuranceLocal DECIMAL(38,13), InsuranceSubscriptionFee DECIMAL(38,13), StringInsuranceNum NVARCHAR(MAX) COLLATE DATABASE_DEFAULT, StringIDNumber NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
    SocialInsuranceStartDate DATETIME, SocialInsuranceStartDateDay INT, SocialInsuranceStartDateMonth INT, SocialInsuranceStartDateYear INT, Gender NVARCHAR(50) COLLATE DATABASE_DEFAULT,
    TotalIncomeInt BIGINT, TotalIncomeFraction NVARCHAR(2) COLLATE DATABASE_DEFAULT, InsuranceInt BIGINT, InsuranceFraction NVARCHAR(2) COLLATE DATABASE_DEFAULT);
DECLARE @Seed TABLE (stage VARCHAR(20), EmployeeId INT, EmployeeName NVARCHAR(1000), EndWork BIT, EndWorkingDate DATETIME, SocialInsuranceStartDate DATETIME, EmployeeSecurityLevel INT);
DECLARE @K TABLE (i INT, c VARCHAR(40), p NVARCHAR(200), fromD DATETIME, toD DATETIME, legIds NVARCHAR(MAX), newIds NVARCHAR(MAX), lvl INT);
DECLARE @i INT = 1, @maxI INT, @c VARCHAR(40), @f DATETIME, @t DATETIME, @lids NVARCHAR(MAX), @nids NVARCHAR(MAX), @lvl INT;
INSERT @K VALUES
 (1, 'wide all, sec 5',        N'1900-01-01..2100-01-01, legacy '''' / new NULL, sec 5', '1900-01-01', '2100-01-01', N'', NULL, 5),
 (2, 'wide all, sec 1',        N'1900-01-01..2100-01-01, legacy '''' / new NULL, sec 1', '1900-01-01', '2100-01-01', N'', NULL, 1),
 (3, 'wide ids 5,6,9, sec 5',  N'1900-01-01..2100-01-01, ''5,6,9'', sec 5',              '1900-01-01', '2100-01-01', N'5,6,9', N'5,6,9', 5),
 (4, 'narrow 2014, sec 5',     N'2014-01-01..2014-12-31 (midnight), legacy '''' / new NULL, sec 5', '2014-01-01', '2014-12-31', N'', NULL, 5);
INSERT @Seed SELECT 'before', EmployeeId, EmployeeName, EndWork, EndWorkingDate, SocialInsuranceStartDate, EmployeeSecurityLevel FROM dbo.PR_Employee WHERE EmployeeId IN (@EPast, @EFuture);

BEGIN TRAN;
UPDATE dbo.PR_Employee SET EndWorkingDate = '2026-01-31' WHERE EmployeeId = @EPast AND EndWork = 0;
UPDATE dbo.PR_Employee SET EndWorkingDate = '2027-12-31' WHERE EmployeeId = @EFuture AND EndWork = 0;
INSERT @Seed SELECT 'inside tran', EmployeeId, EmployeeName, EndWork, EndWorkingDate, SocialInsuranceStartDate, EmployeeSecurityLevel FROM dbo.PR_Employee WHERE EmployeeId IN (@EPast, @EFuture);
SELECT @maxI = MAX(i) FROM @K;
WHILE @i <= @maxI
BEGIN
    SELECT @c = c, @f = fromD, @t = toD, @lids = legIds, @nids = newIds, @lvl = lvl FROM @K WHERE i = @i;
    INSERT @L (InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal,
               InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender)
        EXEC sp_executesql @LegacyU, @LP, @fromDate = @f, @toDate = @t, @employeesIds = @lids, @SecurityLevel = @lvl;
    UPDATE @L SET c = @c, src = 'U' WHERE c IS NULL;
    INSERT @L (InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal,
               InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender)
        EXEC sp_executesql @LegacyF, @LP, @fromDate = @f, @toDate = @t, @employeesIds = @lids, @SecurityLevel = @lvl;
    UPDATE @L SET c = @c, src = 'F' WHERE c IS NULL;
    INSERT @N SELECT @c, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, TotalIncomeFraction, InsuranceInt, InsuranceFraction FROM dbo.PR_InsuranceRegistrationReport(@f, @t, @nids, @lvl);
    SET @i += 1;
END
ROLLBACK TRAN;
SET @ms = DATEDIFF(MILLISECOND, @t0, SYSDATETIME());
INSERT @Seed SELECT 'after rollback', EmployeeId, EmployeeName, EndWork, EndWorkingDate, SocialInsuranceStartDate, EmployeeSecurityLevel FROM dbo.PR_Employee WHERE EmployeeId IN (@EPast, @EFuture);
SELECT @ms AS tran_ms, @@TRANCOUNT AS trancount_after_rollback, CAST(GETDATE() AS DATE) AS today;

SELECT 'R4 (a) legacy_r4_fixed.sql vs TVF (22 legacy columns)' AS check_;
SELECT x.*, CASE WHEN x.sumsLegacy = x.sumsNew THEN 'yes' ELSE 'NO' END AS sumsEqual,
       CASE WHEN x.legacyRows = x.newRows AND x.L_N = 0 AND x.N_L = 0 AND x.multisetDiff = 0 AND x.sumsLegacy = x.sumsNew THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (SELECT k.c AS [case], k.p AS params,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND src = 'F') AS legacyRows,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND 1=1) AS newRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @L WHERE c = k.c AND src = 'F' EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @N WHERE c = k.c AND 1=1) q) AS L_N,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @N WHERE c = k.c AND 1=1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @L WHERE c = k.c AND src = 'F') q) AS N_L,
  (SELECT COUNT(*) FROM ((SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) AS cnt FROM @L WHERE c = k.c AND src = 'F' GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) FROM @N WHERE c = k.c AND 1=1 GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender)
                    UNION ALL (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) AS cnt FROM @N WHERE c = k.c AND 1=1 GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) FROM @L WHERE c = k.c AND src = 'F' GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender)) q) AS multisetDiff,
  (SELECT ISNULL(CAST(SUM(CAST(TotalIncomeLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalInsuranceLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(InsuranceSubscriptionFee AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @L WHERE c = k.c AND src = 'F') AS sumsLegacy,
  (SELECT ISNULL(CAST(SUM(CAST(TotalIncomeLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalInsuranceLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(InsuranceSubscriptionFee AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @N WHERE c = k.c AND 1=1) AS sumsNew
 FROM @K k) x ORDER BY x.[case];
SELECT 'R4 (b) untouched legacy (as "legacy") vs fixed legacy (as "new"): the Fix effect' AS check_;
SELECT x.*, CASE WHEN x.sumsLegacy = x.sumsNew THEN 'yes' ELSE 'NO' END AS sumsEqual,
       CASE WHEN x.legacyRows = x.newRows AND x.L_N = 0 AND x.N_L = 0 AND x.multisetDiff = 0 AND x.sumsLegacy = x.sumsNew THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM (SELECT k.c AS [case], k.p AS params,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND src = 'U') AS legacyRows,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND src = 'F') AS newRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @L WHERE c = k.c AND src = 'U' EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @L WHERE c = k.c AND src = 'F') q) AS L_N,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @L WHERE c = k.c AND src = 'F' EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM @L WHERE c = k.c AND src = 'U') q) AS N_L,
  (SELECT COUNT(*) FROM ((SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) AS cnt FROM @L WHERE c = k.c AND src = 'U' GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) FROM @L WHERE c = k.c AND src = 'F' GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender)
                    UNION ALL (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) AS cnt FROM @L WHERE c = k.c AND src = 'F' GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, COUNT(*) FROM @L WHERE c = k.c AND src = 'U' GROUP BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender)) q) AS multisetDiff,
  (SELECT ISNULL(CAST(SUM(CAST(TotalIncomeLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalInsuranceLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(InsuranceSubscriptionFee AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @L WHERE c = k.c AND src = 'U') AS sumsLegacy,
  (SELECT ISNULL(CAST(SUM(CAST(TotalIncomeLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(TotalInsuranceLocal AS DECIMAL(38,6))) AS VARCHAR(60)),'null')+'|'+ISNULL(CAST(SUM(CAST(InsuranceSubscriptionFee AS DECIMAL(38,6))) AS VARCHAR(60)),'null') FROM @L WHERE c = k.c AND src = 'F') AS sumsNew
 FROM @K k) x ORDER BY x.[case];
SELECT 'R4 (b) employees added / removed by the Fix (fixed vs untouched legacy), with the seeded EndWorkingDate' AS check_;
SELECT k.c AS [case], d.change, d.EmployeeName, s.EmployeeId, s.EndWorkingDate,
       CASE WHEN s.EndWorkingDate < CAST(GETDATE() AS DATE) THEN 'end date passed' ELSE 'end date not reached' END AS why
FROM @K k
CROSS APPLY (SELECT 'added by Fix' AS change, EmployeeName FROM (SELECT EmployeeName FROM @L WHERE c = k.c AND src = 'F' EXCEPT SELECT EmployeeName FROM @L WHERE c = k.c AND src = 'U') a
             UNION ALL SELECT 'removed by Fix', EmployeeName FROM (SELECT EmployeeName FROM @L WHERE c = k.c AND src = 'U' EXCEPT SELECT EmployeeName FROM @L WHERE c = k.c AND src = 'F') r) d
LEFT JOIN @Seed s ON s.stage = 'inside tran' AND s.EmployeeName = d.EmployeeName COLLATE DATABASE_DEFAULT
ORDER BY k.c, d.change;
SELECT 'R4 seeded employees per case (1 = present)' AS check_, k.c AS [case],
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND src = 'U' AND EmployeeName = (SELECT EmployeeName FROM @Seed WHERE stage = 'before' AND EmployeeId = @EPast)) AS past_inUntouched,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND src = 'F' AND EmployeeName = (SELECT EmployeeName FROM @Seed WHERE stage = 'before' AND EmployeeId = @EPast)) AS past_inFixed,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND EmployeeName = (SELECT EmployeeName FROM @Seed WHERE stage = 'before' AND EmployeeId = @EPast)) AS past_inTVF,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND src = 'U' AND EmployeeName = (SELECT EmployeeName FROM @Seed WHERE stage = 'before' AND EmployeeId = @EFuture)) AS future_inUntouched,
  (SELECT COUNT(*) FROM @L WHERE c = k.c AND src = 'F' AND EmployeeName = (SELECT EmployeeName FROM @Seed WHERE stage = 'before' AND EmployeeId = @EFuture)) AS future_inFixed,
  (SELECT COUNT(*) FROM @N WHERE c = k.c AND EmployeeName = (SELECT EmployeeName FROM @Seed WHERE stage = 'before' AND EmployeeId = @EFuture)) AS future_inTVF
FROM @K k ORDER BY k.c;
SELECT * FROM @Seed ORDER BY stage, EmployeeId;
GO
-- post-run re-query, outside any transaction
SELECT 'post-run' AS what, @@TRANCOUNT AS trancount, (SELECT COUNT(*) FROM dbo.PR_Employee WHERE EndWorkingDate IS NOT NULL) AS employeesWithEndWorkingDate,
       (SELECT STRING_AGG(CONCAT(EmployeeId, ':', ISNULL(CONVERT(VARCHAR(10), EndWorkingDate, 120), 'NULL')), ',') FROM dbo.PR_Employee WHERE EmployeeId IN (5, 6)) AS seededEmployeesEndWorkingDate;
