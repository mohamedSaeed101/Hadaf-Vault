SET NOCOUNT ON;
GO
PRINT '== R4 wide 1900..2100 all ids sec5 (legacy '' / new NULL)';
DECLARE @fromDate DATETIME = '1900-01-01', @toDate DATETIME = '2100-01-01', @employeesIds NVARCHAR(MAX) = '', @SecurityLevel INT = 5;
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L0
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
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L1
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
SELECT RowNo, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt INTO #TVF FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', NULL, 5);
SELECT 'R4 wide 1900..2100 all ids sec5 (legacy '' / new NULL) | TVF fraction columns' AS Probe, (SELECT COUNT(*) FROM #TVF) AS TvfRows; BEGIN TRY SELECT TotalIncomeFraction, InsuranceFraction INTO #FR FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', NULL, 5); SELECT 'fraction columns selectable' AS FractionSelect; DROP TABLE #FR; END TRY BEGIN CATCH SELECT 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() AS FractionSelect; END CATCH;

SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #o FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R4 wide 1900..2100 all ids sec5 (legacy '' / new NULL) | (a) fixed-legacy vs TVF' AS TestCase, (SELECT COUNT(*) FROM #L1) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(TotalIncomeLocal) FROM #L1) AS Old_TotalIncomeLocal, (SELECT SUM(TotalIncomeLocal) FROM #TVF) AS New_TotalIncomeLocal, (SELECT SUM(TotalInsuranceLocal) FROM #L1) AS Old_TotalInsuranceLocal, (SELECT SUM(TotalInsuranceLocal) FROM #TVF) AS New_TotalInsuranceLocal, (SELECT SUM(InsuranceSubscriptionFee) FROM #L1) AS Old_InsuranceSubscriptionFee, (SELECT SUM(InsuranceSubscriptionFee) FROM #TVF) AS New_InsuranceSubscriptionFee,
  CASE WHEN ISNULL((SELECT SUM(TotalIncomeLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalIncomeLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #L1),0)=ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L1)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

SELECT 'R4 wide 1900..2100 all ids sec5 (legacy '' / new NULL) | (b) Fix effect' AS TestCase, (SELECT COUNT(*) FROM #L0) AS UntouchedLegacyRows, (SELECT COUNT(*) FROM #L1) AS FixedLegacyRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) x) AS AddedByFix, (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) x) AS RemovedByFix;
SELECT d.side, d.EmployeeName, e.EmployeeId, e.EndWork, e.EndWorkingDate FROM (
  SELECT 'added' side, EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) a
  UNION ALL SELECT 'removed', EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) r) d
  LEFT JOIN dbo.PR_Employee e ON e.EmployeeName = d.EmployeeName AND ISNULL(e.IDNumber,'') = ISNULL(d.IDNumber,'') ORDER BY d.side, d.EmployeeName;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CASE WHEN TotalIncomeLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) - 1) END AS TotalIncomeInt, CASE WHEN TotalIncomeLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) + 1, 2) END AS TotalIncomeFraction, CASE WHEN TotalIncomeLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalIncomeLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) < 2) THEN 1 ELSE 0 END AS TotalIncomeCrash, CASE WHEN TotalInsuranceLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) - 1) END AS InsuranceInt, CASE WHEN TotalInsuranceLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) + 1, 2) END AS InsuranceFraction, CASE WHEN TotalInsuranceLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalInsuranceLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) < 2) THEN 1 ELSE 0 END AS InsuranceCrash,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalInsuranceLocal - FLOOR(TotalInsuranceLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfInsFrac,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalIncomeLocal * 100) - FLOOR(TotalIncomeLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalInsuranceLocal * 100) - FLOOR(TotalInsuranceLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandInsFrac
  INTO #E FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CAST(TotalIncomeInt AS VARCHAR(40)) AS TotalIncomeInt, CAST(InsuranceInt AS VARCHAR(40)) AS InsuranceInt INTO #TVFE FROM #TVF;
SELECT 'R4 wide 1900..2100 all ids sec5 (legacy '' / new NULL) | Int/Fraction' AS TestCase, (SELECT COUNT(*) FROM #E) AS LegacyRows,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0) AS IncomePos, (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0) AS InsurancePos,
  (SELECT ISNULL(SUM(TotalIncomeCrash + InsuranceCrash),0) FROM #E) AS LegacyCrashCells,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E EXCEPT SELECT * FROM #TVFE) x) AS IntLegacyMinusNew,
  (SELECT COUNT(*) FROM (SELECT * FROM #TVFE EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E) x) AS IntNewMinusLegacy,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0 AND TvfIncFrac IS NULL) + (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0 AND TvfInsFrac IS NULL) AS TvfFracErrorCells,
  (SELECT COUNT(*) FROM #E WHERE TvfIncFrac IS NOT NULL AND TvfIncFrac <> TotalIncomeFraction) + (SELECT COUNT(*) FROM #E WHERE TvfInsFrac IS NOT NULL AND TvfInsFrac <> InsuranceFraction) AS TvfFracWrongCells,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(TvfIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(TvfInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS TvfFracRowsOk,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(CandIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(CandInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS CandidateFracRowsOk,
  (SELECT TOP 1 CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') AS VARCHAR(20)) + '(' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') AS VARCHAR(5)) + ',' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') AS VARCHAR(5)) + ')' FROM #L1) AS LegacyTotalType;
SELECT TOP 20 EmployeeName, CONVERT(VARCHAR(60), TotalIncomeLocal) AS TotalIncomeLocal, TotalIncomeInt AS LegacyInt, TotalIncomeFraction AS LegacyFrac, ISNULL(TvfIncFrac, 'ERR') AS TvfFrac, CandIncFrac FROM #E
  WHERE TotalIncomeLocal > 0 AND ISNULL(TvfIncFrac,'ERR') <> TotalIncomeFraction ORDER BY EmployeeName;
DROP TABLE #E; DROP TABLE #TVFE; DROP TABLE #L0; DROP TABLE #L1; DROP TABLE #TVF;
GO
PRINT '== R4 wide 1900..2100 all ids sec1';
DECLARE @fromDate DATETIME = '1900-01-01', @toDate DATETIME = '2100-01-01', @employeesIds NVARCHAR(MAX) = '', @SecurityLevel INT = 1;
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L0
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
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L1
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
SELECT RowNo, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt INTO #TVF FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', NULL, 1);
SELECT 'R4 wide 1900..2100 all ids sec1 | TVF fraction columns' AS Probe, (SELECT COUNT(*) FROM #TVF) AS TvfRows; BEGIN TRY SELECT TotalIncomeFraction, InsuranceFraction INTO #FR FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', NULL, 1); SELECT 'fraction columns selectable' AS FractionSelect; DROP TABLE #FR; END TRY BEGIN CATCH SELECT 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() AS FractionSelect; END CATCH;

SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #o FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R4 wide 1900..2100 all ids sec1 | (a) fixed-legacy vs TVF' AS TestCase, (SELECT COUNT(*) FROM #L1) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(TotalIncomeLocal) FROM #L1) AS Old_TotalIncomeLocal, (SELECT SUM(TotalIncomeLocal) FROM #TVF) AS New_TotalIncomeLocal, (SELECT SUM(TotalInsuranceLocal) FROM #L1) AS Old_TotalInsuranceLocal, (SELECT SUM(TotalInsuranceLocal) FROM #TVF) AS New_TotalInsuranceLocal, (SELECT SUM(InsuranceSubscriptionFee) FROM #L1) AS Old_InsuranceSubscriptionFee, (SELECT SUM(InsuranceSubscriptionFee) FROM #TVF) AS New_InsuranceSubscriptionFee,
  CASE WHEN ISNULL((SELECT SUM(TotalIncomeLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalIncomeLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #L1),0)=ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L1)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

SELECT 'R4 wide 1900..2100 all ids sec1 | (b) Fix effect' AS TestCase, (SELECT COUNT(*) FROM #L0) AS UntouchedLegacyRows, (SELECT COUNT(*) FROM #L1) AS FixedLegacyRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) x) AS AddedByFix, (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) x) AS RemovedByFix;
SELECT d.side, d.EmployeeName, e.EmployeeId, e.EndWork, e.EndWorkingDate FROM (
  SELECT 'added' side, EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) a
  UNION ALL SELECT 'removed', EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) r) d
  LEFT JOIN dbo.PR_Employee e ON e.EmployeeName = d.EmployeeName AND ISNULL(e.IDNumber,'') = ISNULL(d.IDNumber,'') ORDER BY d.side, d.EmployeeName;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CASE WHEN TotalIncomeLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) - 1) END AS TotalIncomeInt, CASE WHEN TotalIncomeLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) + 1, 2) END AS TotalIncomeFraction, CASE WHEN TotalIncomeLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalIncomeLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) < 2) THEN 1 ELSE 0 END AS TotalIncomeCrash, CASE WHEN TotalInsuranceLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) - 1) END AS InsuranceInt, CASE WHEN TotalInsuranceLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) + 1, 2) END AS InsuranceFraction, CASE WHEN TotalInsuranceLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalInsuranceLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) < 2) THEN 1 ELSE 0 END AS InsuranceCrash,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalInsuranceLocal - FLOOR(TotalInsuranceLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfInsFrac,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalIncomeLocal * 100) - FLOOR(TotalIncomeLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalInsuranceLocal * 100) - FLOOR(TotalInsuranceLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandInsFrac
  INTO #E FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CAST(TotalIncomeInt AS VARCHAR(40)) AS TotalIncomeInt, CAST(InsuranceInt AS VARCHAR(40)) AS InsuranceInt INTO #TVFE FROM #TVF;
SELECT 'R4 wide 1900..2100 all ids sec1 | Int/Fraction' AS TestCase, (SELECT COUNT(*) FROM #E) AS LegacyRows,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0) AS IncomePos, (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0) AS InsurancePos,
  (SELECT ISNULL(SUM(TotalIncomeCrash + InsuranceCrash),0) FROM #E) AS LegacyCrashCells,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E EXCEPT SELECT * FROM #TVFE) x) AS IntLegacyMinusNew,
  (SELECT COUNT(*) FROM (SELECT * FROM #TVFE EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E) x) AS IntNewMinusLegacy,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0 AND TvfIncFrac IS NULL) + (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0 AND TvfInsFrac IS NULL) AS TvfFracErrorCells,
  (SELECT COUNT(*) FROM #E WHERE TvfIncFrac IS NOT NULL AND TvfIncFrac <> TotalIncomeFraction) + (SELECT COUNT(*) FROM #E WHERE TvfInsFrac IS NOT NULL AND TvfInsFrac <> InsuranceFraction) AS TvfFracWrongCells,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(TvfIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(TvfInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS TvfFracRowsOk,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(CandIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(CandInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS CandidateFracRowsOk,
  (SELECT TOP 1 CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') AS VARCHAR(20)) + '(' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') AS VARCHAR(5)) + ',' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') AS VARCHAR(5)) + ')' FROM #L1) AS LegacyTotalType;
SELECT TOP 20 EmployeeName, CONVERT(VARCHAR(60), TotalIncomeLocal) AS TotalIncomeLocal, TotalIncomeInt AS LegacyInt, TotalIncomeFraction AS LegacyFrac, ISNULL(TvfIncFrac, 'ERR') AS TvfFrac, CandIncFrac FROM #E
  WHERE TotalIncomeLocal > 0 AND ISNULL(TvfIncFrac,'ERR') <> TotalIncomeFraction ORDER BY EmployeeName;
DROP TABLE #E; DROP TABLE #TVFE; DROP TABLE #L0; DROP TABLE #L1; DROP TABLE #TVF;
GO
PRINT '== R4 narrow 2026-01-01..2026-09-27 midnight sec5';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-09-27', @employeesIds NVARCHAR(MAX) = '', @SecurityLevel INT = 5;
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L0
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
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L1
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
SELECT RowNo, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt INTO #TVF FROM dbo.PR_InsuranceRegistrationReport('2026-01-01', '2026-09-27', NULL, 5);
SELECT 'R4 narrow 2026-01-01..2026-09-27 midnight sec5 | TVF fraction columns' AS Probe, (SELECT COUNT(*) FROM #TVF) AS TvfRows; BEGIN TRY SELECT TotalIncomeFraction, InsuranceFraction INTO #FR FROM dbo.PR_InsuranceRegistrationReport('2026-01-01', '2026-09-27', NULL, 5); SELECT 'fraction columns selectable' AS FractionSelect; DROP TABLE #FR; END TRY BEGIN CATCH SELECT 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() AS FractionSelect; END CATCH;

SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #o FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R4 narrow 2026-01-01..2026-09-27 midnight sec5 | (a) fixed-legacy vs TVF' AS TestCase, (SELECT COUNT(*) FROM #L1) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(TotalIncomeLocal) FROM #L1) AS Old_TotalIncomeLocal, (SELECT SUM(TotalIncomeLocal) FROM #TVF) AS New_TotalIncomeLocal, (SELECT SUM(TotalInsuranceLocal) FROM #L1) AS Old_TotalInsuranceLocal, (SELECT SUM(TotalInsuranceLocal) FROM #TVF) AS New_TotalInsuranceLocal, (SELECT SUM(InsuranceSubscriptionFee) FROM #L1) AS Old_InsuranceSubscriptionFee, (SELECT SUM(InsuranceSubscriptionFee) FROM #TVF) AS New_InsuranceSubscriptionFee,
  CASE WHEN ISNULL((SELECT SUM(TotalIncomeLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalIncomeLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #L1),0)=ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L1)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

SELECT 'R4 narrow 2026-01-01..2026-09-27 midnight sec5 | (b) Fix effect' AS TestCase, (SELECT COUNT(*) FROM #L0) AS UntouchedLegacyRows, (SELECT COUNT(*) FROM #L1) AS FixedLegacyRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) x) AS AddedByFix, (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) x) AS RemovedByFix;
SELECT d.side, d.EmployeeName, e.EmployeeId, e.EndWork, e.EndWorkingDate FROM (
  SELECT 'added' side, EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) a
  UNION ALL SELECT 'removed', EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) r) d
  LEFT JOIN dbo.PR_Employee e ON e.EmployeeName = d.EmployeeName AND ISNULL(e.IDNumber,'') = ISNULL(d.IDNumber,'') ORDER BY d.side, d.EmployeeName;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CASE WHEN TotalIncomeLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) - 1) END AS TotalIncomeInt, CASE WHEN TotalIncomeLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) + 1, 2) END AS TotalIncomeFraction, CASE WHEN TotalIncomeLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalIncomeLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) < 2) THEN 1 ELSE 0 END AS TotalIncomeCrash, CASE WHEN TotalInsuranceLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) - 1) END AS InsuranceInt, CASE WHEN TotalInsuranceLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) + 1, 2) END AS InsuranceFraction, CASE WHEN TotalInsuranceLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalInsuranceLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) < 2) THEN 1 ELSE 0 END AS InsuranceCrash,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalInsuranceLocal - FLOOR(TotalInsuranceLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfInsFrac,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalIncomeLocal * 100) - FLOOR(TotalIncomeLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalInsuranceLocal * 100) - FLOOR(TotalInsuranceLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandInsFrac
  INTO #E FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CAST(TotalIncomeInt AS VARCHAR(40)) AS TotalIncomeInt, CAST(InsuranceInt AS VARCHAR(40)) AS InsuranceInt INTO #TVFE FROM #TVF;
SELECT 'R4 narrow 2026-01-01..2026-09-27 midnight sec5 | Int/Fraction' AS TestCase, (SELECT COUNT(*) FROM #E) AS LegacyRows,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0) AS IncomePos, (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0) AS InsurancePos,
  (SELECT ISNULL(SUM(TotalIncomeCrash + InsuranceCrash),0) FROM #E) AS LegacyCrashCells,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E EXCEPT SELECT * FROM #TVFE) x) AS IntLegacyMinusNew,
  (SELECT COUNT(*) FROM (SELECT * FROM #TVFE EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E) x) AS IntNewMinusLegacy,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0 AND TvfIncFrac IS NULL) + (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0 AND TvfInsFrac IS NULL) AS TvfFracErrorCells,
  (SELECT COUNT(*) FROM #E WHERE TvfIncFrac IS NOT NULL AND TvfIncFrac <> TotalIncomeFraction) + (SELECT COUNT(*) FROM #E WHERE TvfInsFrac IS NOT NULL AND TvfInsFrac <> InsuranceFraction) AS TvfFracWrongCells,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(TvfIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(TvfInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS TvfFracRowsOk,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(CandIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(CandInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS CandidateFracRowsOk,
  (SELECT TOP 1 CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') AS VARCHAR(20)) + '(' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') AS VARCHAR(5)) + ',' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') AS VARCHAR(5)) + ')' FROM #L1) AS LegacyTotalType;
SELECT TOP 20 EmployeeName, CONVERT(VARCHAR(60), TotalIncomeLocal) AS TotalIncomeLocal, TotalIncomeInt AS LegacyInt, TotalIncomeFraction AS LegacyFrac, ISNULL(TvfIncFrac, 'ERR') AS TvfFrac, CandIncFrac FROM #E
  WHERE TotalIncomeLocal > 0 AND ISNULL(TvfIncFrac,'ERR') <> TotalIncomeFraction ORDER BY EmployeeName;
DROP TABLE #E; DROP TABLE #TVFE; DROP TABLE #L0; DROP TABLE #L1; DROP TABLE #TVF;
GO
PRINT '== R4 wide ids 4,9,113 sec5';
DECLARE @fromDate DATETIME = '1900-01-01', @toDate DATETIME = '2100-01-01', @employeesIds NVARCHAR(MAX) = '4,9,113', @SecurityLevel INT = 5;
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L0
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
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L1
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
SELECT RowNo, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt INTO #TVF FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', '4,9,113', 5);
SELECT 'R4 wide ids 4,9,113 sec5 | TVF fraction columns' AS Probe, (SELECT COUNT(*) FROM #TVF) AS TvfRows; BEGIN TRY SELECT TotalIncomeFraction, InsuranceFraction INTO #FR FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', '4,9,113', 5); SELECT 'fraction columns selectable' AS FractionSelect; DROP TABLE #FR; END TRY BEGIN CATCH SELECT 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() AS FractionSelect; END CATCH;

SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #o FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R4 wide ids 4,9,113 sec5 | (a) fixed-legacy vs TVF' AS TestCase, (SELECT COUNT(*) FROM #L1) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(TotalIncomeLocal) FROM #L1) AS Old_TotalIncomeLocal, (SELECT SUM(TotalIncomeLocal) FROM #TVF) AS New_TotalIncomeLocal, (SELECT SUM(TotalInsuranceLocal) FROM #L1) AS Old_TotalInsuranceLocal, (SELECT SUM(TotalInsuranceLocal) FROM #TVF) AS New_TotalInsuranceLocal, (SELECT SUM(InsuranceSubscriptionFee) FROM #L1) AS Old_InsuranceSubscriptionFee, (SELECT SUM(InsuranceSubscriptionFee) FROM #TVF) AS New_InsuranceSubscriptionFee,
  CASE WHEN ISNULL((SELECT SUM(TotalIncomeLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalIncomeLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #L1),0)=ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L1)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

SELECT 'R4 wide ids 4,9,113 sec5 | (b) Fix effect' AS TestCase, (SELECT COUNT(*) FROM #L0) AS UntouchedLegacyRows, (SELECT COUNT(*) FROM #L1) AS FixedLegacyRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) x) AS AddedByFix, (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) x) AS RemovedByFix;
SELECT d.side, d.EmployeeName, e.EmployeeId, e.EndWork, e.EndWorkingDate FROM (
  SELECT 'added' side, EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) a
  UNION ALL SELECT 'removed', EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) r) d
  LEFT JOIN dbo.PR_Employee e ON e.EmployeeName = d.EmployeeName AND ISNULL(e.IDNumber,'') = ISNULL(d.IDNumber,'') ORDER BY d.side, d.EmployeeName;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CASE WHEN TotalIncomeLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) - 1) END AS TotalIncomeInt, CASE WHEN TotalIncomeLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) + 1, 2) END AS TotalIncomeFraction, CASE WHEN TotalIncomeLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalIncomeLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) < 2) THEN 1 ELSE 0 END AS TotalIncomeCrash, CASE WHEN TotalInsuranceLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) - 1) END AS InsuranceInt, CASE WHEN TotalInsuranceLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) + 1, 2) END AS InsuranceFraction, CASE WHEN TotalInsuranceLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalInsuranceLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) < 2) THEN 1 ELSE 0 END AS InsuranceCrash,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalInsuranceLocal - FLOOR(TotalInsuranceLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfInsFrac,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalIncomeLocal * 100) - FLOOR(TotalIncomeLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalInsuranceLocal * 100) - FLOOR(TotalInsuranceLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandInsFrac
  INTO #E FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CAST(TotalIncomeInt AS VARCHAR(40)) AS TotalIncomeInt, CAST(InsuranceInt AS VARCHAR(40)) AS InsuranceInt INTO #TVFE FROM #TVF;
SELECT 'R4 wide ids 4,9,113 sec5 | Int/Fraction' AS TestCase, (SELECT COUNT(*) FROM #E) AS LegacyRows,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0) AS IncomePos, (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0) AS InsurancePos,
  (SELECT ISNULL(SUM(TotalIncomeCrash + InsuranceCrash),0) FROM #E) AS LegacyCrashCells,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E EXCEPT SELECT * FROM #TVFE) x) AS IntLegacyMinusNew,
  (SELECT COUNT(*) FROM (SELECT * FROM #TVFE EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E) x) AS IntNewMinusLegacy,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0 AND TvfIncFrac IS NULL) + (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0 AND TvfInsFrac IS NULL) AS TvfFracErrorCells,
  (SELECT COUNT(*) FROM #E WHERE TvfIncFrac IS NOT NULL AND TvfIncFrac <> TotalIncomeFraction) + (SELECT COUNT(*) FROM #E WHERE TvfInsFrac IS NOT NULL AND TvfInsFrac <> InsuranceFraction) AS TvfFracWrongCells,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(TvfIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(TvfInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS TvfFracRowsOk,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(CandIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(CandInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS CandidateFracRowsOk,
  (SELECT TOP 1 CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') AS VARCHAR(20)) + '(' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') AS VARCHAR(5)) + ',' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') AS VARCHAR(5)) + ')' FROM #L1) AS LegacyTotalType;
SELECT TOP 20 EmployeeName, CONVERT(VARCHAR(60), TotalIncomeLocal) AS TotalIncomeLocal, TotalIncomeInt AS LegacyInt, TotalIncomeFraction AS LegacyFrac, ISNULL(TvfIncFrac, 'ERR') AS TvfFrac, CandIncFrac FROM #E
  WHERE TotalIncomeLocal > 0 AND ISNULL(TvfIncFrac,'ERR') <> TotalIncomeFraction ORDER BY EmployeeName;
DROP TABLE #E; DROP TABLE #TVFE; DROP TABLE #L0; DROP TABLE #L1; DROP TABLE #TVF;
GO
PRINT '== R4 wide ids 4,9,113 sec1';
DECLARE @fromDate DATETIME = '1900-01-01', @toDate DATETIME = '2100-01-01', @employeesIds NVARCHAR(MAX) = '4,9,113', @SecurityLevel INT = 1;
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L0
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
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L1
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
SELECT RowNo, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt INTO #TVF FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', '4,9,113', 1);
SELECT 'R4 wide ids 4,9,113 sec1 | TVF fraction columns' AS Probe, (SELECT COUNT(*) FROM #TVF) AS TvfRows; BEGIN TRY SELECT TotalIncomeFraction, InsuranceFraction INTO #FR FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', '4,9,113', 1); SELECT 'fraction columns selectable' AS FractionSelect; DROP TABLE #FR; END TRY BEGIN CATCH SELECT 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() AS FractionSelect; END CATCH;

SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #o FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R4 wide ids 4,9,113 sec1 | (a) fixed-legacy vs TVF' AS TestCase, (SELECT COUNT(*) FROM #L1) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(TotalIncomeLocal) FROM #L1) AS Old_TotalIncomeLocal, (SELECT SUM(TotalIncomeLocal) FROM #TVF) AS New_TotalIncomeLocal, (SELECT SUM(TotalInsuranceLocal) FROM #L1) AS Old_TotalInsuranceLocal, (SELECT SUM(TotalInsuranceLocal) FROM #TVF) AS New_TotalInsuranceLocal, (SELECT SUM(InsuranceSubscriptionFee) FROM #L1) AS Old_InsuranceSubscriptionFee, (SELECT SUM(InsuranceSubscriptionFee) FROM #TVF) AS New_InsuranceSubscriptionFee,
  CASE WHEN ISNULL((SELECT SUM(TotalIncomeLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalIncomeLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #L1),0)=ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L1)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

SELECT 'R4 wide ids 4,9,113 sec1 | (b) Fix effect' AS TestCase, (SELECT COUNT(*) FROM #L0) AS UntouchedLegacyRows, (SELECT COUNT(*) FROM #L1) AS FixedLegacyRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) x) AS AddedByFix, (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) x) AS RemovedByFix;
SELECT d.side, d.EmployeeName, e.EmployeeId, e.EndWork, e.EndWorkingDate FROM (
  SELECT 'added' side, EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) a
  UNION ALL SELECT 'removed', EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) r) d
  LEFT JOIN dbo.PR_Employee e ON e.EmployeeName = d.EmployeeName AND ISNULL(e.IDNumber,'') = ISNULL(d.IDNumber,'') ORDER BY d.side, d.EmployeeName;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CASE WHEN TotalIncomeLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) - 1) END AS TotalIncomeInt, CASE WHEN TotalIncomeLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) + 1, 2) END AS TotalIncomeFraction, CASE WHEN TotalIncomeLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalIncomeLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) < 2) THEN 1 ELSE 0 END AS TotalIncomeCrash, CASE WHEN TotalInsuranceLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) - 1) END AS InsuranceInt, CASE WHEN TotalInsuranceLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) + 1, 2) END AS InsuranceFraction, CASE WHEN TotalInsuranceLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalInsuranceLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) < 2) THEN 1 ELSE 0 END AS InsuranceCrash,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalInsuranceLocal - FLOOR(TotalInsuranceLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfInsFrac,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalIncomeLocal * 100) - FLOOR(TotalIncomeLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalInsuranceLocal * 100) - FLOOR(TotalInsuranceLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandInsFrac
  INTO #E FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CAST(TotalIncomeInt AS VARCHAR(40)) AS TotalIncomeInt, CAST(InsuranceInt AS VARCHAR(40)) AS InsuranceInt INTO #TVFE FROM #TVF;
SELECT 'R4 wide ids 4,9,113 sec1 | Int/Fraction' AS TestCase, (SELECT COUNT(*) FROM #E) AS LegacyRows,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0) AS IncomePos, (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0) AS InsurancePos,
  (SELECT ISNULL(SUM(TotalIncomeCrash + InsuranceCrash),0) FROM #E) AS LegacyCrashCells,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E EXCEPT SELECT * FROM #TVFE) x) AS IntLegacyMinusNew,
  (SELECT COUNT(*) FROM (SELECT * FROM #TVFE EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E) x) AS IntNewMinusLegacy,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0 AND TvfIncFrac IS NULL) + (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0 AND TvfInsFrac IS NULL) AS TvfFracErrorCells,
  (SELECT COUNT(*) FROM #E WHERE TvfIncFrac IS NOT NULL AND TvfIncFrac <> TotalIncomeFraction) + (SELECT COUNT(*) FROM #E WHERE TvfInsFrac IS NOT NULL AND TvfInsFrac <> InsuranceFraction) AS TvfFracWrongCells,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(TvfIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(TvfInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS TvfFracRowsOk,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(CandIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(CandInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS CandidateFracRowsOk,
  (SELECT TOP 1 CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') AS VARCHAR(20)) + '(' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') AS VARCHAR(5)) + ',' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') AS VARCHAR(5)) + ')' FROM #L1) AS LegacyTotalType;
SELECT TOP 20 EmployeeName, CONVERT(VARCHAR(60), TotalIncomeLocal) AS TotalIncomeLocal, TotalIncomeInt AS LegacyInt, TotalIncomeFraction AS LegacyFrac, ISNULL(TvfIncFrac, 'ERR') AS TvfFrac, CandIncFrac FROM #E
  WHERE TotalIncomeLocal > 0 AND ISNULL(TvfIncFrac,'ERR') <> TotalIncomeFraction ORDER BY EmployeeName;
DROP TABLE #E; DROP TABLE #TVFE; DROP TABLE #L0; DROP TABLE #L1; DROP TABLE #TVF;
GO
PRINT '== R4 wide all ids sec5 new '' (empty string)';
DECLARE @fromDate DATETIME = '1900-01-01', @toDate DATETIME = '2100-01-01', @employeesIds NVARCHAR(MAX) = '', @SecurityLevel INT = 5;
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L0
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
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L1
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
SELECT RowNo, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt INTO #TVF FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', '', 5);
SELECT 'R4 wide all ids sec5 new '' (empty string) | TVF fraction columns' AS Probe, (SELECT COUNT(*) FROM #TVF) AS TvfRows; BEGIN TRY SELECT TotalIncomeFraction, InsuranceFraction INTO #FR FROM dbo.PR_InsuranceRegistrationReport('1900-01-01', '2100-01-01', '', 5); SELECT 'fraction columns selectable' AS FractionSelect; DROP TABLE #FR; END TRY BEGIN CATCH SELECT 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() AS FractionSelect; END CATCH;

SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #o FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R4 wide all ids sec5 new '' (empty string) | (a) fixed-legacy vs TVF' AS TestCase, (SELECT COUNT(*) FROM #L1) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(TotalIncomeLocal) FROM #L1) AS Old_TotalIncomeLocal, (SELECT SUM(TotalIncomeLocal) FROM #TVF) AS New_TotalIncomeLocal, (SELECT SUM(TotalInsuranceLocal) FROM #L1) AS Old_TotalInsuranceLocal, (SELECT SUM(TotalInsuranceLocal) FROM #TVF) AS New_TotalInsuranceLocal, (SELECT SUM(InsuranceSubscriptionFee) FROM #L1) AS Old_InsuranceSubscriptionFee, (SELECT SUM(InsuranceSubscriptionFee) FROM #TVF) AS New_InsuranceSubscriptionFee,
  CASE WHEN ISNULL((SELECT SUM(TotalIncomeLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalIncomeLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #L1),0)=ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L1)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

SELECT 'R4 wide all ids sec5 new '' (empty string) | (b) Fix effect' AS TestCase, (SELECT COUNT(*) FROM #L0) AS UntouchedLegacyRows, (SELECT COUNT(*) FROM #L1) AS FixedLegacyRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) x) AS AddedByFix, (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) x) AS RemovedByFix;
SELECT d.side, d.EmployeeName, e.EmployeeId, e.EndWork, e.EndWorkingDate FROM (
  SELECT 'added' side, EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) a
  UNION ALL SELECT 'removed', EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) r) d
  LEFT JOIN dbo.PR_Employee e ON e.EmployeeName = d.EmployeeName AND ISNULL(e.IDNumber,'') = ISNULL(d.IDNumber,'') ORDER BY d.side, d.EmployeeName;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CASE WHEN TotalIncomeLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) - 1) END AS TotalIncomeInt, CASE WHEN TotalIncomeLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) + 1, 2) END AS TotalIncomeFraction, CASE WHEN TotalIncomeLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalIncomeLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) < 2) THEN 1 ELSE 0 END AS TotalIncomeCrash, CASE WHEN TotalInsuranceLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) - 1) END AS InsuranceInt, CASE WHEN TotalInsuranceLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) + 1, 2) END AS InsuranceFraction, CASE WHEN TotalInsuranceLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalInsuranceLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) < 2) THEN 1 ELSE 0 END AS InsuranceCrash,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalInsuranceLocal - FLOOR(TotalInsuranceLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfInsFrac,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalIncomeLocal * 100) - FLOOR(TotalIncomeLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalInsuranceLocal * 100) - FLOOR(TotalInsuranceLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandInsFrac
  INTO #E FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CAST(TotalIncomeInt AS VARCHAR(40)) AS TotalIncomeInt, CAST(InsuranceInt AS VARCHAR(40)) AS InsuranceInt INTO #TVFE FROM #TVF;
SELECT 'R4 wide all ids sec5 new '' (empty string) | Int/Fraction' AS TestCase, (SELECT COUNT(*) FROM #E) AS LegacyRows,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0) AS IncomePos, (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0) AS InsurancePos,
  (SELECT ISNULL(SUM(TotalIncomeCrash + InsuranceCrash),0) FROM #E) AS LegacyCrashCells,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E EXCEPT SELECT * FROM #TVFE) x) AS IntLegacyMinusNew,
  (SELECT COUNT(*) FROM (SELECT * FROM #TVFE EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E) x) AS IntNewMinusLegacy,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0 AND TvfIncFrac IS NULL) + (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0 AND TvfInsFrac IS NULL) AS TvfFracErrorCells,
  (SELECT COUNT(*) FROM #E WHERE TvfIncFrac IS NOT NULL AND TvfIncFrac <> TotalIncomeFraction) + (SELECT COUNT(*) FROM #E WHERE TvfInsFrac IS NOT NULL AND TvfInsFrac <> InsuranceFraction) AS TvfFracWrongCells,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(TvfIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(TvfInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS TvfFracRowsOk,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(CandIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(CandInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS CandidateFracRowsOk,
  (SELECT TOP 1 CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') AS VARCHAR(20)) + '(' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') AS VARCHAR(5)) + ',' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') AS VARCHAR(5)) + ')' FROM #L1) AS LegacyTotalType;
SELECT TOP 20 EmployeeName, CONVERT(VARCHAR(60), TotalIncomeLocal) AS TotalIncomeLocal, TotalIncomeInt AS LegacyInt, TotalIncomeFraction AS LegacyFrac, ISNULL(TvfIncFrac, 'ERR') AS TvfFrac, CandIncFrac FROM #E
  WHERE TotalIncomeLocal > 0 AND ISNULL(TvfIncFrac,'ERR') <> TotalIncomeFraction ORDER BY EmployeeName;
DROP TABLE #E; DROP TABLE #TVFE; DROP TABLE #L0; DROP TABLE #L1; DROP TABLE #TVF;
GO
PRINT '== R4 BACKEND narrow new toDate GetDayEnd 2026-09-27 23:59:59.997 vs legacy midnight';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-09-27', @employeesIds NVARCHAR(MAX) = '', @SecurityLevel INT = 5;
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L0
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
WITH empIncome
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
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.InsuranceNum))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
                           )
           ) AS StringInsuranceNum,
           (
               SELECT STUFF(
                      (
                          SELECT '  ' + number
                          FROM dbo.Acc_ConvertStringToCharTable(CONVERT(NVARCHAR(MAX), emps.IDNumber))
                          FOR XML PATH('')
                      ),
                      1,
                      2,
                      ''
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
              OR emps.EndWorkingDate = ''
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
                  @employeesIds = ''
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
INTO #L1
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
SELECT RowNo, InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt INTO #TVF FROM dbo.PR_InsuranceRegistrationReport('2026-01-01', '2026-09-27T23:59:59.997', NULL, 5);
SELECT 'R4 BACKEND narrow new toDate GetDayEnd 2026-09-27 23:59:59.997 vs legacy midnight | TVF fraction columns' AS Probe, (SELECT COUNT(*) FROM #TVF) AS TvfRows; BEGIN TRY SELECT TotalIncomeFraction, InsuranceFraction INTO #FR FROM dbo.PR_InsuranceRegistrationReport('2026-01-01', '2026-09-27T23:59:59.997', NULL, 5); SELECT 'fraction columns selectable' AS FractionSelect; DROP TABLE #FR; END TRY BEGIN CATCH SELECT 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() AS FractionSelect; END CATCH;

SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #o FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, ROW_NUMBER() OVER (PARTITION BY InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R4 BACKEND narrow new toDate GetDayEnd 2026-09-27 23:59:59.997 vs legacy midnight | (a) fixed-legacy vs TVF' AS TestCase, (SELECT COUNT(*) FROM #L1) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(TotalIncomeLocal) FROM #L1) AS Old_TotalIncomeLocal, (SELECT SUM(TotalIncomeLocal) FROM #TVF) AS New_TotalIncomeLocal, (SELECT SUM(TotalInsuranceLocal) FROM #L1) AS Old_TotalInsuranceLocal, (SELECT SUM(TotalInsuranceLocal) FROM #TVF) AS New_TotalInsuranceLocal, (SELECT SUM(InsuranceSubscriptionFee) FROM #L1) AS Old_InsuranceSubscriptionFee, (SELECT SUM(InsuranceSubscriptionFee) FROM #TVF) AS New_InsuranceSubscriptionFee,
  CASE WHEN ISNULL((SELECT SUM(TotalIncomeLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalIncomeLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #L1),0)=ISNULL((SELECT SUM(TotalInsuranceLocal) FROM #TVF),0) AND ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #L1),0)=ISNULL((SELECT SUM(InsuranceSubscriptionFee) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L1)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

SELECT 'R4 BACKEND narrow new toDate GetDayEnd 2026-09-27 23:59:59.997 vs legacy midnight | (b) Fix effect' AS TestCase, (SELECT COUNT(*) FROM #L0) AS UntouchedLegacyRows, (SELECT COUNT(*) FROM #L1) AS FixedLegacyRows,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) x) AS AddedByFix, (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) x) AS RemovedByFix;
SELECT d.side, d.EmployeeName, e.EmployeeId, e.EndWork, e.EndWorkingDate FROM (
  SELECT 'added' side, EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0) a
  UNION ALL SELECT 'removed', EmployeeName, IDNumber FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L0 EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender FROM #L1) r) d
  LEFT JOIN dbo.PR_Employee e ON e.EmployeeName = d.EmployeeName AND ISNULL(e.IDNumber,'') = ISNULL(d.IDNumber,'') ORDER BY d.side, d.EmployeeName;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CASE WHEN TotalIncomeLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) - 1) END AS TotalIncomeInt, CASE WHEN TotalIncomeLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalIncomeLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) + 1, 2) END AS TotalIncomeFraction, CASE WHEN TotalIncomeLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalIncomeLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalIncomeLocal)) < 2) THEN 1 ELSE 0 END AS TotalIncomeCrash, CASE WHEN TotalInsuranceLocal > 0 THEN LEFT(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) - 1) END AS InsuranceInt, CASE WHEN TotalInsuranceLocal > 0 THEN SUBSTRING(CONVERT(VARCHAR(60), TotalInsuranceLocal), CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) + 1, 2) END AS InsuranceFraction, CASE WHEN TotalInsuranceLocal > 0 AND (CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) = 0 OR LEN(CONVERT(VARCHAR(60), TotalInsuranceLocal)) - CHARINDEX('.', CONVERT(VARCHAR(60), TotalInsuranceLocal)) < 2) THEN 1 ELSE 0 END AS InsuranceCrash,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalIncomeLocal - FLOOR(TotalIncomeLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + TRY_CAST(FLOOR((TotalInsuranceLocal - FLOOR(TotalInsuranceLocal)) * 100) AS VARCHAR(2)), 2) END AS TvfInsFrac,
  CASE WHEN TotalIncomeLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalIncomeLocal * 100) - FLOOR(TotalIncomeLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandIncFrac, CASE WHEN TotalInsuranceLocal > 0 THEN RIGHT('0' + CAST(CAST(FLOOR(TotalInsuranceLocal * 100) - FLOOR(TotalInsuranceLocal) * 100 AS INT) AS VARCHAR(2)), 2) END AS CandInsFrac
  INTO #E FROM #L1;
SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, CAST(TotalIncomeInt AS VARCHAR(40)) AS TotalIncomeInt, CAST(InsuranceInt AS VARCHAR(40)) AS InsuranceInt INTO #TVFE FROM #TVF;
SELECT 'R4 BACKEND narrow new toDate GetDayEnd 2026-09-27 23:59:59.997 vs legacy midnight | Int/Fraction' AS TestCase, (SELECT COUNT(*) FROM #E) AS LegacyRows,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0) AS IncomePos, (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0) AS InsurancePos,
  (SELECT ISNULL(SUM(TotalIncomeCrash + InsuranceCrash),0) FROM #E) AS LegacyCrashCells,
  (SELECT COUNT(*) FROM (SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E EXCEPT SELECT * FROM #TVFE) x) AS IntLegacyMinusNew,
  (SELECT COUNT(*) FROM (SELECT * FROM #TVFE EXCEPT SELECT InsuranceNum, EmployeeName, EmployeeArabicName, IDNumber, WorkDate, WorkDateDay, WorkDateMonth, WorkDateYear, DateOfWork, DateOfWorkDay, DateOfWorkMonth, DateOfWorkYear, TotalIncomeLocal, TotalInsuranceLocal, InsuranceSubscriptionFee, StringInsuranceNum, StringIDNumber, SocialInsuranceStartDate, SocialInsuranceStartDateDay, SocialInsuranceStartDateMonth, SocialInsuranceStartDateYear, Gender, TotalIncomeInt, InsuranceInt FROM #E) x) AS IntNewMinusLegacy,
  (SELECT COUNT(*) FROM #E WHERE TotalIncomeLocal > 0 AND TvfIncFrac IS NULL) + (SELECT COUNT(*) FROM #E WHERE TotalInsuranceLocal > 0 AND TvfInsFrac IS NULL) AS TvfFracErrorCells,
  (SELECT COUNT(*) FROM #E WHERE TvfIncFrac IS NOT NULL AND TvfIncFrac <> TotalIncomeFraction) + (SELECT COUNT(*) FROM #E WHERE TvfInsFrac IS NOT NULL AND TvfInsFrac <> InsuranceFraction) AS TvfFracWrongCells,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(TvfIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(TvfInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS TvfFracRowsOk,
  (SELECT COUNT(*) FROM #E WHERE ISNULL(CandIncFrac,'#') = ISNULL(TotalIncomeFraction,'#') AND ISNULL(CandInsFrac,'#') = ISNULL(InsuranceFraction,'#')) AS CandidateFracRowsOk,
  (SELECT TOP 1 CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') AS VARCHAR(20)) + '(' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') AS VARCHAR(5)) + ',' + CAST(SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') AS VARCHAR(5)) + ')' FROM #L1) AS LegacyTotalType;
SELECT TOP 20 EmployeeName, CONVERT(VARCHAR(60), TotalIncomeLocal) AS TotalIncomeLocal, TotalIncomeInt AS LegacyInt, TotalIncomeFraction AS LegacyFrac, ISNULL(TvfIncFrac, 'ERR') AS TvfFrac, CandIncFrac FROM #E
  WHERE TotalIncomeLocal > 0 AND ISNULL(TvfIncFrac,'ERR') <> TotalIncomeFraction ORDER BY EmployeeName;
DROP TABLE #E; DROP TABLE #TVFE; DROP TABLE #L0; DROP TABLE #L1; DROP TABLE #TVF;
GO
PRINT '== R4 Fix effect, all EndWork = 0 employees (no date/id/security filter)';
SELECT EmployeeId, EmployeeName, EndWork, EndWorkingDate, CASE WHEN EndWorkingDate IS NULL OR EndWorkingDate = '' OR EndWorkingDate < GETDATE() THEN 1 ELSE 0 END AS LegacyKeeps, CASE WHEN EndWorkingDate IS NULL OR EndWorkingDate = '' OR EndWorkingDate >= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS FixKeeps
FROM dbo.PR_Employee WHERE EndWork = 0 AND (CASE WHEN EndWorkingDate IS NULL OR EndWorkingDate = '' OR EndWorkingDate < GETDATE() THEN 1 ELSE 0 END) <> (CASE WHEN EndWorkingDate IS NULL OR EndWorkingDate = '' OR EndWorkingDate >= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END);
SELECT COUNT(*) AS EmployeesWithEndWorkingDate FROM dbo.PR_Employee WHERE EndWorkingDate IS NOT NULL;
GO
