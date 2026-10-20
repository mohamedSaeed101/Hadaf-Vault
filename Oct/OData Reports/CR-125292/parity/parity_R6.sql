SET NOCOUNT ON;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @SecurityLevel INT = 5, @DepartmentIds NVARCHAR(MAX) = NULL, @BranchIds NVARCHAR(MAX) = NULL;
DECLARE @SalaryMonth DECIMAL = 8, @SalaryYear DECIMAL = 2026, @DepartmentId VARCHAR(1024) = '', @BranchId VARCHAR(1024) = '', @UserSecurityLevel INT = 5;
;
    WITH PrepaidVacationDetails
    AS (SELECT PR_SalaryDetail.SalaryId,
               SUM(   CASE
                          WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                               AND PR_SalaryDetail.Deduction = 0 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalIncome,
               SUM(   CASE
                          WHEN PR_SalaryDetail.Deduction = 1 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalDeductions
        FROM dbo.PR_SalaryDetail
        GROUP BY PR_SalaryDetail.SalaryId),
         EndWorkDetailsCTE
    AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
               PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
               PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
               PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
               PR_EmployeeEndWorkDetail.TotalBouns,
               PR_EmployeeEndWorkDetail.TotalPenalty,
               PR_EmployeeEndWorkDetail.TotalAdvance,
               PR_EmployeeEndWorkDetail.TotalPurchase,
               PR_EmployeeEndWork.EmployeeId,
               PR_EmployeeEndWork.LastWorkingDay,
               PR_EmployeeEndWorkDetail.CurrencyId
        FROM dbo.PR_EmployeeEndWorkDetail
            INNER JOIN dbo.PR_EmployeeEndWork
                ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
        WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
         PrepaidVacationsCTE
    AS (SELECT SalaryMainId,
               IsVacationSalary,
               SalaryMonth
        FROM dbo.PR_SalaryMain
        WHERE IsVacationSalary = 1),
         Report
    AS (SELECT DISTINCT
               PR_Employee.EmployeeId,
               PR_Employee.EmployeeNumber,
               PR_Employee.EmployeeName,
               PR_Employee.EmployeeArabicName,
               PR_Job.JobName,
               PR_Salaries.InsuranceCompany,
               PR_Department.DepartmentName,
               PR_Department.DepartmentId,
               PR_Branch_1.BranchName,
               PR_Branch_1.BranchId,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalIncome - TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
                   ELSE
                       PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
               END AS TotalSalary,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                                   + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalDeductions
               END AS TotalDeductions,
               Acc_Currency.CurrencyName,
               Acc_Currency.CurrencyNameArabic,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT SUM(   CASE
                                             WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                                  AND PR_SalaryDetail.Deduction = 0 THEN
                                                 PR_SalaryDetail.IncomeAmount
                                             ELSE
                                                 0
                                         END
                                     )
                           FROM dbo.PR_SalaryDetail
                           WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                                   + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalAdditions
               END AS TotalAdditions,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryMonth
               END AS SalaryMonth,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryYear
               END AS SalaryYear,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       N'إجازة مدفوعة مقدماً'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       N'اخلاء طرف'
                   ELSE
                       N'راتب شهري'
               END AS SalarySource,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       'Prepaid Vacation'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       'End of Work'
                   ELSE
                       'Monthly Salary'
               END AS SalarySourceEng
        FROM dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain
                ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Job
                ON PR_Job.JobId = PR_Employee.JobId
            LEFT OUTER JOIN dbo.PR_Department
                ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch AS PR_Branch_1
                ON PR_Branch_1.BranchId = PR_Employee.BranchId
            LEFT OUTER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
            LEFT OUTER JOIN PrepaidVacationsCTE
                ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN EndWorkDetailsCTE
                ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
                AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @Month
                      AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @Year
        WHERE (
                  (
                      EndWorkDetailsCTE.EmployeeId IS NOT NULL
                  )
                  OR
                  (
                      EndWorkDetailsCTE.EmployeeId IS NULL
                      AND PR_SalaryMain.SalaryMonth = @Month
                      AND PR_SalaryMain.SalaryYear = @Year
                  )
              )
              AND
              (
                  (
                      ISNULL(@DepartmentIds, '') = ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT DepartmentId FROM dbo.PR_Department
                          )
                  )
                  OR
                  (
                      ISNULL(@DepartmentIds, '') <> ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@DepartmentIds)
                          )
                  )
              )
              AND
              (
                  (
                      ISNULL(@BranchIds, '') = ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT BranchId FROM dbo.PR_Branch
                          )
                  )
                  OR
                  (
                      ISNULL(@BranchIds, '') <> ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@BranchIds)
                          )
                  )
              )
              AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel)
    SELECT ROW_NUMBER() OVER (ORDER BY Report.BranchId, Report.DepartmentId, Report.EmployeeId,
                                       Report.SalaryYear, Report.SalaryMonth, Report.SalarySourceEng,
                                       Report.CurrencyName, Report.InsuranceCompany, Report.TotalSalary) AS RowNo,
           Report.EmployeeId,
           Report.EmployeeNumber,
           Report.EmployeeName,
           Report.EmployeeArabicName,
           Report.JobName,
           Report.InsuranceCompany,
           Report.DepartmentName,
           Report.DepartmentId,
           Report.BranchName,
           Report.BranchId,
           Report.TotalSalary,
           Report.TotalDeductions,
           Report.CurrencyName,
           Report.CurrencyNameArabic,
           Report.TotalAdditions,
           Report.SalaryMonth,
           Report.SalaryYear,
           Report.SalarySource,
           Report.SalarySourceEng
    INTO #new FROM Report
;
WITH PrepaidVacationDetails
AS (SELECT PR_SalaryDetail.SalaryId,
           SUM(   CASE
                      WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                           AND PR_SalaryDetail.Deduction = 0 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalIncome,
           SUM(   CASE
                      WHEN PR_SalaryDetail.Deduction = 1 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalDeductions
    FROM PR_SalaryDetail
    GROUP BY PR_SalaryDetail.SalaryId),
     EndWorkDetailsCTE
AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
           PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
           PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
           PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
           PR_EmployeeEndWorkDetail.TotalBouns,
           PR_EmployeeEndWorkDetail.TotalPenalty,
           PR_EmployeeEndWorkDetail.TotalAdvance,
           PR_EmployeeEndWorkDetail.TotalPurchase,
           PR_EmployeeEndWork.EmployeeId,
           PR_EmployeeEndWork.LastWorkingDay,
           PR_EmployeeEndWorkDetail.CurrencyId
    FROM PR_EmployeeEndWorkDetail
        INNER JOIN PR_EmployeeEndWork
            ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
     PrepaidVacationsCTE
AS (SELECT SalaryMainId,
           IsVacationSalary,
           SalaryMonth
    FROM PR_SalaryMain
    WHERE IsVacationSalary = 1)
SELECT DISTINCT
       PR_Employee.EmployeeId,
       PR_Employee.EmployeeNumber,
       PR_Employee.EmployeeName,
       PR_Job.JobName,
       PR_Salaries.InsuranceCompany,
       PR_Department.DepartmentName,
       PR_Department.DepartmentId,
       PR_Branch_1.BranchName,
       PR_Branch_1.BranchId,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalIncome - TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
           ELSE
               PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
       END AS TotalSalary,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                           + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalDeductions
       END AS TotalDeductions,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT SUM(   CASE
                                     WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                          AND PR_SalaryDetail.Deduction = 0 THEN
                                         PR_SalaryDetail.IncomeAmount
                                     ELSE
                                         0
                                 END
                             )
                   FROM PR_SalaryDetail
                   WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                           + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalAdditions
       END AS TotalAdditions,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryMonth
       END AS SalaryMonth,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryYear
       END AS SalaryYear,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               N'إجازة مدفوعة مقدماً'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               N'اخلاء طرف'
           ELSE
               N'راتب شهري'
       END AS SalarySource,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               'Prepaid Vacation'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               'End of Work'
           ELSE
               'Monthly Salary'
       END AS SalarySourceEng
INTO #old
FROM PR_Salaries
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT OUTER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    LEFT OUTER JOIN PR_Department
        ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN PR_Branch AS PR_Branch_1
        ON PR_Branch_1.BranchId = PR_Employee.BranchId
    LEFT OUTER JOIN Acc_Currency
        ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
    LEFT OUTER JOIN PrepaidVacationsCTE
        ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN EndWorkDetailsCTE
        ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
        AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
WHERE (
          (
              EndWorkDetailsCTE.EmployeeId IS NOT NULL
          )
          OR
          (
              EndWorkDetailsCTE.EmployeeId IS NULL
              AND PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (
              @DepartmentId = ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT DepartmentId FROM PR_Department
                  )
          )
          OR
          (
              @DepartmentId <> ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@DepartmentId)
                  )
          )
      )
      AND
      (
          (
              @BranchId = ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT BranchId FROM PR_Branch
                  )
          )
          OR
          (
              @BranchId <> ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@BranchId)
                  )
          )
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel
;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R6 2026/08 all (new NULL)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(InsuranceCompany) FROM #old) OldIns, (SELECT SUM(InsuranceCompany) FROM #new) NewIns, (SELECT SUM(TotalAdditions) FROM #old) OldAdd, (SELECT SUM(TotalAdditions) FROM #new) NewAdd, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(TotalSalary) FROM #old) OldNet, (SELECT SUM(TotalSalary) FROM #new) NewNet,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @SecurityLevel INT = 5, @DepartmentIds NVARCHAR(MAX) = N'', @BranchIds NVARCHAR(MAX) = N'';
DECLARE @SalaryMonth DECIMAL = 8, @SalaryYear DECIMAL = 2026, @DepartmentId VARCHAR(1024) = '', @BranchId VARCHAR(1024) = '', @UserSecurityLevel INT = 5;
;
    WITH PrepaidVacationDetails
    AS (SELECT PR_SalaryDetail.SalaryId,
               SUM(   CASE
                          WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                               AND PR_SalaryDetail.Deduction = 0 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalIncome,
               SUM(   CASE
                          WHEN PR_SalaryDetail.Deduction = 1 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalDeductions
        FROM dbo.PR_SalaryDetail
        GROUP BY PR_SalaryDetail.SalaryId),
         EndWorkDetailsCTE
    AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
               PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
               PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
               PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
               PR_EmployeeEndWorkDetail.TotalBouns,
               PR_EmployeeEndWorkDetail.TotalPenalty,
               PR_EmployeeEndWorkDetail.TotalAdvance,
               PR_EmployeeEndWorkDetail.TotalPurchase,
               PR_EmployeeEndWork.EmployeeId,
               PR_EmployeeEndWork.LastWorkingDay,
               PR_EmployeeEndWorkDetail.CurrencyId
        FROM dbo.PR_EmployeeEndWorkDetail
            INNER JOIN dbo.PR_EmployeeEndWork
                ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
        WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
         PrepaidVacationsCTE
    AS (SELECT SalaryMainId,
               IsVacationSalary,
               SalaryMonth
        FROM dbo.PR_SalaryMain
        WHERE IsVacationSalary = 1),
         Report
    AS (SELECT DISTINCT
               PR_Employee.EmployeeId,
               PR_Employee.EmployeeNumber,
               PR_Employee.EmployeeName,
               PR_Employee.EmployeeArabicName,
               PR_Job.JobName,
               PR_Salaries.InsuranceCompany,
               PR_Department.DepartmentName,
               PR_Department.DepartmentId,
               PR_Branch_1.BranchName,
               PR_Branch_1.BranchId,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalIncome - TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
                   ELSE
                       PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
               END AS TotalSalary,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                                   + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalDeductions
               END AS TotalDeductions,
               Acc_Currency.CurrencyName,
               Acc_Currency.CurrencyNameArabic,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT SUM(   CASE
                                             WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                                  AND PR_SalaryDetail.Deduction = 0 THEN
                                                 PR_SalaryDetail.IncomeAmount
                                             ELSE
                                                 0
                                         END
                                     )
                           FROM dbo.PR_SalaryDetail
                           WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                                   + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalAdditions
               END AS TotalAdditions,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryMonth
               END AS SalaryMonth,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryYear
               END AS SalaryYear,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       N'إجازة مدفوعة مقدماً'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       N'اخلاء طرف'
                   ELSE
                       N'راتب شهري'
               END AS SalarySource,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       'Prepaid Vacation'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       'End of Work'
                   ELSE
                       'Monthly Salary'
               END AS SalarySourceEng
        FROM dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain
                ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Job
                ON PR_Job.JobId = PR_Employee.JobId
            LEFT OUTER JOIN dbo.PR_Department
                ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch AS PR_Branch_1
                ON PR_Branch_1.BranchId = PR_Employee.BranchId
            LEFT OUTER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
            LEFT OUTER JOIN PrepaidVacationsCTE
                ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN EndWorkDetailsCTE
                ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
                AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @Month
                      AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @Year
        WHERE (
                  (
                      EndWorkDetailsCTE.EmployeeId IS NOT NULL
                  )
                  OR
                  (
                      EndWorkDetailsCTE.EmployeeId IS NULL
                      AND PR_SalaryMain.SalaryMonth = @Month
                      AND PR_SalaryMain.SalaryYear = @Year
                  )
              )
              AND
              (
                  (
                      ISNULL(@DepartmentIds, '') = ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT DepartmentId FROM dbo.PR_Department
                          )
                  )
                  OR
                  (
                      ISNULL(@DepartmentIds, '') <> ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@DepartmentIds)
                          )
                  )
              )
              AND
              (
                  (
                      ISNULL(@BranchIds, '') = ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT BranchId FROM dbo.PR_Branch
                          )
                  )
                  OR
                  (
                      ISNULL(@BranchIds, '') <> ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@BranchIds)
                          )
                  )
              )
              AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel)
    SELECT ROW_NUMBER() OVER (ORDER BY Report.BranchId, Report.DepartmentId, Report.EmployeeId,
                                       Report.SalaryYear, Report.SalaryMonth, Report.SalarySourceEng,
                                       Report.CurrencyName, Report.InsuranceCompany, Report.TotalSalary) AS RowNo,
           Report.EmployeeId,
           Report.EmployeeNumber,
           Report.EmployeeName,
           Report.EmployeeArabicName,
           Report.JobName,
           Report.InsuranceCompany,
           Report.DepartmentName,
           Report.DepartmentId,
           Report.BranchName,
           Report.BranchId,
           Report.TotalSalary,
           Report.TotalDeductions,
           Report.CurrencyName,
           Report.CurrencyNameArabic,
           Report.TotalAdditions,
           Report.SalaryMonth,
           Report.SalaryYear,
           Report.SalarySource,
           Report.SalarySourceEng
    INTO #new FROM Report
;
WITH PrepaidVacationDetails
AS (SELECT PR_SalaryDetail.SalaryId,
           SUM(   CASE
                      WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                           AND PR_SalaryDetail.Deduction = 0 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalIncome,
           SUM(   CASE
                      WHEN PR_SalaryDetail.Deduction = 1 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalDeductions
    FROM PR_SalaryDetail
    GROUP BY PR_SalaryDetail.SalaryId),
     EndWorkDetailsCTE
AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
           PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
           PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
           PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
           PR_EmployeeEndWorkDetail.TotalBouns,
           PR_EmployeeEndWorkDetail.TotalPenalty,
           PR_EmployeeEndWorkDetail.TotalAdvance,
           PR_EmployeeEndWorkDetail.TotalPurchase,
           PR_EmployeeEndWork.EmployeeId,
           PR_EmployeeEndWork.LastWorkingDay,
           PR_EmployeeEndWorkDetail.CurrencyId
    FROM PR_EmployeeEndWorkDetail
        INNER JOIN PR_EmployeeEndWork
            ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
     PrepaidVacationsCTE
AS (SELECT SalaryMainId,
           IsVacationSalary,
           SalaryMonth
    FROM PR_SalaryMain
    WHERE IsVacationSalary = 1)
SELECT DISTINCT
       PR_Employee.EmployeeId,
       PR_Employee.EmployeeNumber,
       PR_Employee.EmployeeName,
       PR_Job.JobName,
       PR_Salaries.InsuranceCompany,
       PR_Department.DepartmentName,
       PR_Department.DepartmentId,
       PR_Branch_1.BranchName,
       PR_Branch_1.BranchId,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalIncome - TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
           ELSE
               PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
       END AS TotalSalary,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                           + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalDeductions
       END AS TotalDeductions,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT SUM(   CASE
                                     WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                          AND PR_SalaryDetail.Deduction = 0 THEN
                                         PR_SalaryDetail.IncomeAmount
                                     ELSE
                                         0
                                 END
                             )
                   FROM PR_SalaryDetail
                   WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                           + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalAdditions
       END AS TotalAdditions,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryMonth
       END AS SalaryMonth,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryYear
       END AS SalaryYear,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               N'إجازة مدفوعة مقدماً'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               N'اخلاء طرف'
           ELSE
               N'راتب شهري'
       END AS SalarySource,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               'Prepaid Vacation'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               'End of Work'
           ELSE
               'Monthly Salary'
       END AS SalarySourceEng
INTO #old
FROM PR_Salaries
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT OUTER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    LEFT OUTER JOIN PR_Department
        ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN PR_Branch AS PR_Branch_1
        ON PR_Branch_1.BranchId = PR_Employee.BranchId
    LEFT OUTER JOIN Acc_Currency
        ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
    LEFT OUTER JOIN PrepaidVacationsCTE
        ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN EndWorkDetailsCTE
        ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
        AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
WHERE (
          (
              EndWorkDetailsCTE.EmployeeId IS NOT NULL
          )
          OR
          (
              EndWorkDetailsCTE.EmployeeId IS NULL
              AND PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (
              @DepartmentId = ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT DepartmentId FROM PR_Department
                  )
          )
          OR
          (
              @DepartmentId <> ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@DepartmentId)
                  )
          )
      )
      AND
      (
          (
              @BranchId = ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT BranchId FROM PR_Branch
                  )
          )
          OR
          (
              @BranchId <> ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@BranchId)
                  )
          )
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel
;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R6 2026/08 all (new '')' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(InsuranceCompany) FROM #old) OldIns, (SELECT SUM(InsuranceCompany) FROM #new) NewIns, (SELECT SUM(TotalAdditions) FROM #old) OldAdd, (SELECT SUM(TotalAdditions) FROM #new) NewAdd, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(TotalSalary) FROM #old) OldNet, (SELECT SUM(TotalSalary) FROM #new) NewNet,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @SecurityLevel INT = 5, @DepartmentIds NVARCHAR(MAX) = NULL, @BranchIds NVARCHAR(MAX) = N'1';
DECLARE @SalaryMonth DECIMAL = 8, @SalaryYear DECIMAL = 2026, @DepartmentId VARCHAR(1024) = '', @BranchId VARCHAR(1024) = '1', @UserSecurityLevel INT = 5;
;
    WITH PrepaidVacationDetails
    AS (SELECT PR_SalaryDetail.SalaryId,
               SUM(   CASE
                          WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                               AND PR_SalaryDetail.Deduction = 0 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalIncome,
               SUM(   CASE
                          WHEN PR_SalaryDetail.Deduction = 1 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalDeductions
        FROM dbo.PR_SalaryDetail
        GROUP BY PR_SalaryDetail.SalaryId),
         EndWorkDetailsCTE
    AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
               PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
               PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
               PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
               PR_EmployeeEndWorkDetail.TotalBouns,
               PR_EmployeeEndWorkDetail.TotalPenalty,
               PR_EmployeeEndWorkDetail.TotalAdvance,
               PR_EmployeeEndWorkDetail.TotalPurchase,
               PR_EmployeeEndWork.EmployeeId,
               PR_EmployeeEndWork.LastWorkingDay,
               PR_EmployeeEndWorkDetail.CurrencyId
        FROM dbo.PR_EmployeeEndWorkDetail
            INNER JOIN dbo.PR_EmployeeEndWork
                ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
        WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
         PrepaidVacationsCTE
    AS (SELECT SalaryMainId,
               IsVacationSalary,
               SalaryMonth
        FROM dbo.PR_SalaryMain
        WHERE IsVacationSalary = 1),
         Report
    AS (SELECT DISTINCT
               PR_Employee.EmployeeId,
               PR_Employee.EmployeeNumber,
               PR_Employee.EmployeeName,
               PR_Employee.EmployeeArabicName,
               PR_Job.JobName,
               PR_Salaries.InsuranceCompany,
               PR_Department.DepartmentName,
               PR_Department.DepartmentId,
               PR_Branch_1.BranchName,
               PR_Branch_1.BranchId,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalIncome - TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
                   ELSE
                       PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
               END AS TotalSalary,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                                   + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalDeductions
               END AS TotalDeductions,
               Acc_Currency.CurrencyName,
               Acc_Currency.CurrencyNameArabic,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT SUM(   CASE
                                             WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                                  AND PR_SalaryDetail.Deduction = 0 THEN
                                                 PR_SalaryDetail.IncomeAmount
                                             ELSE
                                                 0
                                         END
                                     )
                           FROM dbo.PR_SalaryDetail
                           WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                                   + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalAdditions
               END AS TotalAdditions,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryMonth
               END AS SalaryMonth,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryYear
               END AS SalaryYear,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       N'إجازة مدفوعة مقدماً'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       N'اخلاء طرف'
                   ELSE
                       N'راتب شهري'
               END AS SalarySource,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       'Prepaid Vacation'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       'End of Work'
                   ELSE
                       'Monthly Salary'
               END AS SalarySourceEng
        FROM dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain
                ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Job
                ON PR_Job.JobId = PR_Employee.JobId
            LEFT OUTER JOIN dbo.PR_Department
                ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch AS PR_Branch_1
                ON PR_Branch_1.BranchId = PR_Employee.BranchId
            LEFT OUTER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
            LEFT OUTER JOIN PrepaidVacationsCTE
                ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN EndWorkDetailsCTE
                ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
                AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @Month
                      AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @Year
        WHERE (
                  (
                      EndWorkDetailsCTE.EmployeeId IS NOT NULL
                  )
                  OR
                  (
                      EndWorkDetailsCTE.EmployeeId IS NULL
                      AND PR_SalaryMain.SalaryMonth = @Month
                      AND PR_SalaryMain.SalaryYear = @Year
                  )
              )
              AND
              (
                  (
                      ISNULL(@DepartmentIds, '') = ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT DepartmentId FROM dbo.PR_Department
                          )
                  )
                  OR
                  (
                      ISNULL(@DepartmentIds, '') <> ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@DepartmentIds)
                          )
                  )
              )
              AND
              (
                  (
                      ISNULL(@BranchIds, '') = ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT BranchId FROM dbo.PR_Branch
                          )
                  )
                  OR
                  (
                      ISNULL(@BranchIds, '') <> ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@BranchIds)
                          )
                  )
              )
              AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel)
    SELECT ROW_NUMBER() OVER (ORDER BY Report.BranchId, Report.DepartmentId, Report.EmployeeId,
                                       Report.SalaryYear, Report.SalaryMonth, Report.SalarySourceEng,
                                       Report.CurrencyName, Report.InsuranceCompany, Report.TotalSalary) AS RowNo,
           Report.EmployeeId,
           Report.EmployeeNumber,
           Report.EmployeeName,
           Report.EmployeeArabicName,
           Report.JobName,
           Report.InsuranceCompany,
           Report.DepartmentName,
           Report.DepartmentId,
           Report.BranchName,
           Report.BranchId,
           Report.TotalSalary,
           Report.TotalDeductions,
           Report.CurrencyName,
           Report.CurrencyNameArabic,
           Report.TotalAdditions,
           Report.SalaryMonth,
           Report.SalaryYear,
           Report.SalarySource,
           Report.SalarySourceEng
    INTO #new FROM Report
;
WITH PrepaidVacationDetails
AS (SELECT PR_SalaryDetail.SalaryId,
           SUM(   CASE
                      WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                           AND PR_SalaryDetail.Deduction = 0 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalIncome,
           SUM(   CASE
                      WHEN PR_SalaryDetail.Deduction = 1 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalDeductions
    FROM PR_SalaryDetail
    GROUP BY PR_SalaryDetail.SalaryId),
     EndWorkDetailsCTE
AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
           PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
           PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
           PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
           PR_EmployeeEndWorkDetail.TotalBouns,
           PR_EmployeeEndWorkDetail.TotalPenalty,
           PR_EmployeeEndWorkDetail.TotalAdvance,
           PR_EmployeeEndWorkDetail.TotalPurchase,
           PR_EmployeeEndWork.EmployeeId,
           PR_EmployeeEndWork.LastWorkingDay,
           PR_EmployeeEndWorkDetail.CurrencyId
    FROM PR_EmployeeEndWorkDetail
        INNER JOIN PR_EmployeeEndWork
            ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
     PrepaidVacationsCTE
AS (SELECT SalaryMainId,
           IsVacationSalary,
           SalaryMonth
    FROM PR_SalaryMain
    WHERE IsVacationSalary = 1)
SELECT DISTINCT
       PR_Employee.EmployeeId,
       PR_Employee.EmployeeNumber,
       PR_Employee.EmployeeName,
       PR_Job.JobName,
       PR_Salaries.InsuranceCompany,
       PR_Department.DepartmentName,
       PR_Department.DepartmentId,
       PR_Branch_1.BranchName,
       PR_Branch_1.BranchId,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalIncome - TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
           ELSE
               PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
       END AS TotalSalary,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                           + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalDeductions
       END AS TotalDeductions,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT SUM(   CASE
                                     WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                          AND PR_SalaryDetail.Deduction = 0 THEN
                                         PR_SalaryDetail.IncomeAmount
                                     ELSE
                                         0
                                 END
                             )
                   FROM PR_SalaryDetail
                   WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                           + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalAdditions
       END AS TotalAdditions,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryMonth
       END AS SalaryMonth,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryYear
       END AS SalaryYear,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               N'إجازة مدفوعة مقدماً'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               N'اخلاء طرف'
           ELSE
               N'راتب شهري'
       END AS SalarySource,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               'Prepaid Vacation'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               'End of Work'
           ELSE
               'Monthly Salary'
       END AS SalarySourceEng
INTO #old
FROM PR_Salaries
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT OUTER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    LEFT OUTER JOIN PR_Department
        ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN PR_Branch AS PR_Branch_1
        ON PR_Branch_1.BranchId = PR_Employee.BranchId
    LEFT OUTER JOIN Acc_Currency
        ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
    LEFT OUTER JOIN PrepaidVacationsCTE
        ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN EndWorkDetailsCTE
        ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
        AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
WHERE (
          (
              EndWorkDetailsCTE.EmployeeId IS NOT NULL
          )
          OR
          (
              EndWorkDetailsCTE.EmployeeId IS NULL
              AND PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (
              @DepartmentId = ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT DepartmentId FROM PR_Department
                  )
          )
          OR
          (
              @DepartmentId <> ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@DepartmentId)
                  )
          )
      )
      AND
      (
          (
              @BranchId = ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT BranchId FROM PR_Branch
                  )
          )
          OR
          (
              @BranchId <> ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@BranchId)
                  )
          )
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel
;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R6 2026/08 branch 1 explicit' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(InsuranceCompany) FROM #old) OldIns, (SELECT SUM(InsuranceCompany) FROM #new) NewIns, (SELECT SUM(TotalAdditions) FROM #old) OldAdd, (SELECT SUM(TotalAdditions) FROM #new) NewAdd, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(TotalSalary) FROM #old) OldNet, (SELECT SUM(TotalSalary) FROM #new) NewNet,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 8, @Year INT = 2026, @SecurityLevel INT = 5, @DepartmentIds NVARCHAR(MAX) = N'3,4', @BranchIds NVARCHAR(MAX) = NULL;
DECLARE @SalaryMonth DECIMAL = 8, @SalaryYear DECIMAL = 2026, @DepartmentId VARCHAR(1024) = '3,4', @BranchId VARCHAR(1024) = '', @UserSecurityLevel INT = 5;
;
    WITH PrepaidVacationDetails
    AS (SELECT PR_SalaryDetail.SalaryId,
               SUM(   CASE
                          WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                               AND PR_SalaryDetail.Deduction = 0 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalIncome,
               SUM(   CASE
                          WHEN PR_SalaryDetail.Deduction = 1 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalDeductions
        FROM dbo.PR_SalaryDetail
        GROUP BY PR_SalaryDetail.SalaryId),
         EndWorkDetailsCTE
    AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
               PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
               PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
               PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
               PR_EmployeeEndWorkDetail.TotalBouns,
               PR_EmployeeEndWorkDetail.TotalPenalty,
               PR_EmployeeEndWorkDetail.TotalAdvance,
               PR_EmployeeEndWorkDetail.TotalPurchase,
               PR_EmployeeEndWork.EmployeeId,
               PR_EmployeeEndWork.LastWorkingDay,
               PR_EmployeeEndWorkDetail.CurrencyId
        FROM dbo.PR_EmployeeEndWorkDetail
            INNER JOIN dbo.PR_EmployeeEndWork
                ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
        WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
         PrepaidVacationsCTE
    AS (SELECT SalaryMainId,
               IsVacationSalary,
               SalaryMonth
        FROM dbo.PR_SalaryMain
        WHERE IsVacationSalary = 1),
         Report
    AS (SELECT DISTINCT
               PR_Employee.EmployeeId,
               PR_Employee.EmployeeNumber,
               PR_Employee.EmployeeName,
               PR_Employee.EmployeeArabicName,
               PR_Job.JobName,
               PR_Salaries.InsuranceCompany,
               PR_Department.DepartmentName,
               PR_Department.DepartmentId,
               PR_Branch_1.BranchName,
               PR_Branch_1.BranchId,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalIncome - TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
                   ELSE
                       PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
               END AS TotalSalary,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                                   + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalDeductions
               END AS TotalDeductions,
               Acc_Currency.CurrencyName,
               Acc_Currency.CurrencyNameArabic,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT SUM(   CASE
                                             WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                                  AND PR_SalaryDetail.Deduction = 0 THEN
                                                 PR_SalaryDetail.IncomeAmount
                                             ELSE
                                                 0
                                         END
                                     )
                           FROM dbo.PR_SalaryDetail
                           WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                                   + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalAdditions
               END AS TotalAdditions,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryMonth
               END AS SalaryMonth,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryYear
               END AS SalaryYear,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       N'إجازة مدفوعة مقدماً'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       N'اخلاء طرف'
                   ELSE
                       N'راتب شهري'
               END AS SalarySource,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       'Prepaid Vacation'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       'End of Work'
                   ELSE
                       'Monthly Salary'
               END AS SalarySourceEng
        FROM dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain
                ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Job
                ON PR_Job.JobId = PR_Employee.JobId
            LEFT OUTER JOIN dbo.PR_Department
                ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch AS PR_Branch_1
                ON PR_Branch_1.BranchId = PR_Employee.BranchId
            LEFT OUTER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
            LEFT OUTER JOIN PrepaidVacationsCTE
                ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN EndWorkDetailsCTE
                ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
                AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @Month
                      AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @Year
        WHERE (
                  (
                      EndWorkDetailsCTE.EmployeeId IS NOT NULL
                  )
                  OR
                  (
                      EndWorkDetailsCTE.EmployeeId IS NULL
                      AND PR_SalaryMain.SalaryMonth = @Month
                      AND PR_SalaryMain.SalaryYear = @Year
                  )
              )
              AND
              (
                  (
                      ISNULL(@DepartmentIds, '') = ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT DepartmentId FROM dbo.PR_Department
                          )
                  )
                  OR
                  (
                      ISNULL(@DepartmentIds, '') <> ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@DepartmentIds)
                          )
                  )
              )
              AND
              (
                  (
                      ISNULL(@BranchIds, '') = ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT BranchId FROM dbo.PR_Branch
                          )
                  )
                  OR
                  (
                      ISNULL(@BranchIds, '') <> ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@BranchIds)
                          )
                  )
              )
              AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel)
    SELECT ROW_NUMBER() OVER (ORDER BY Report.BranchId, Report.DepartmentId, Report.EmployeeId,
                                       Report.SalaryYear, Report.SalaryMonth, Report.SalarySourceEng,
                                       Report.CurrencyName, Report.InsuranceCompany, Report.TotalSalary) AS RowNo,
           Report.EmployeeId,
           Report.EmployeeNumber,
           Report.EmployeeName,
           Report.EmployeeArabicName,
           Report.JobName,
           Report.InsuranceCompany,
           Report.DepartmentName,
           Report.DepartmentId,
           Report.BranchName,
           Report.BranchId,
           Report.TotalSalary,
           Report.TotalDeductions,
           Report.CurrencyName,
           Report.CurrencyNameArabic,
           Report.TotalAdditions,
           Report.SalaryMonth,
           Report.SalaryYear,
           Report.SalarySource,
           Report.SalarySourceEng
    INTO #new FROM Report
;
WITH PrepaidVacationDetails
AS (SELECT PR_SalaryDetail.SalaryId,
           SUM(   CASE
                      WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                           AND PR_SalaryDetail.Deduction = 0 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalIncome,
           SUM(   CASE
                      WHEN PR_SalaryDetail.Deduction = 1 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalDeductions
    FROM PR_SalaryDetail
    GROUP BY PR_SalaryDetail.SalaryId),
     EndWorkDetailsCTE
AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
           PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
           PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
           PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
           PR_EmployeeEndWorkDetail.TotalBouns,
           PR_EmployeeEndWorkDetail.TotalPenalty,
           PR_EmployeeEndWorkDetail.TotalAdvance,
           PR_EmployeeEndWorkDetail.TotalPurchase,
           PR_EmployeeEndWork.EmployeeId,
           PR_EmployeeEndWork.LastWorkingDay,
           PR_EmployeeEndWorkDetail.CurrencyId
    FROM PR_EmployeeEndWorkDetail
        INNER JOIN PR_EmployeeEndWork
            ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
     PrepaidVacationsCTE
AS (SELECT SalaryMainId,
           IsVacationSalary,
           SalaryMonth
    FROM PR_SalaryMain
    WHERE IsVacationSalary = 1)
SELECT DISTINCT
       PR_Employee.EmployeeId,
       PR_Employee.EmployeeNumber,
       PR_Employee.EmployeeName,
       PR_Job.JobName,
       PR_Salaries.InsuranceCompany,
       PR_Department.DepartmentName,
       PR_Department.DepartmentId,
       PR_Branch_1.BranchName,
       PR_Branch_1.BranchId,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalIncome - TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
           ELSE
               PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
       END AS TotalSalary,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                           + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalDeductions
       END AS TotalDeductions,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT SUM(   CASE
                                     WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                          AND PR_SalaryDetail.Deduction = 0 THEN
                                         PR_SalaryDetail.IncomeAmount
                                     ELSE
                                         0
                                 END
                             )
                   FROM PR_SalaryDetail
                   WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                           + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalAdditions
       END AS TotalAdditions,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryMonth
       END AS SalaryMonth,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryYear
       END AS SalaryYear,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               N'إجازة مدفوعة مقدماً'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               N'اخلاء طرف'
           ELSE
               N'راتب شهري'
       END AS SalarySource,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               'Prepaid Vacation'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               'End of Work'
           ELSE
               'Monthly Salary'
       END AS SalarySourceEng
INTO #old
FROM PR_Salaries
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT OUTER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    LEFT OUTER JOIN PR_Department
        ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN PR_Branch AS PR_Branch_1
        ON PR_Branch_1.BranchId = PR_Employee.BranchId
    LEFT OUTER JOIN Acc_Currency
        ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
    LEFT OUTER JOIN PrepaidVacationsCTE
        ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN EndWorkDetailsCTE
        ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
        AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
WHERE (
          (
              EndWorkDetailsCTE.EmployeeId IS NOT NULL
          )
          OR
          (
              EndWorkDetailsCTE.EmployeeId IS NULL
              AND PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (
              @DepartmentId = ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT DepartmentId FROM PR_Department
                  )
          )
          OR
          (
              @DepartmentId <> ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@DepartmentId)
                  )
          )
      )
      AND
      (
          (
              @BranchId = ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT BranchId FROM PR_Branch
                  )
          )
          OR
          (
              @BranchId <> ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@BranchId)
                  )
          )
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel
;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R6 2026/08 depts 3,4' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(InsuranceCompany) FROM #old) OldIns, (SELECT SUM(InsuranceCompany) FROM #new) NewIns, (SELECT SUM(TotalAdditions) FROM #old) OldAdd, (SELECT SUM(TotalAdditions) FROM #new) NewAdd, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(TotalSalary) FROM #old) OldNet, (SELECT SUM(TotalSalary) FROM #new) NewNet,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 7, @Year INT = 2026, @SecurityLevel INT = 5, @DepartmentIds NVARCHAR(MAX) = NULL, @BranchIds NVARCHAR(MAX) = NULL;
DECLARE @SalaryMonth DECIMAL = 7, @SalaryYear DECIMAL = 2026, @DepartmentId VARCHAR(1024) = '', @BranchId VARCHAR(1024) = '', @UserSecurityLevel INT = 5;
;
    WITH PrepaidVacationDetails
    AS (SELECT PR_SalaryDetail.SalaryId,
               SUM(   CASE
                          WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                               AND PR_SalaryDetail.Deduction = 0 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalIncome,
               SUM(   CASE
                          WHEN PR_SalaryDetail.Deduction = 1 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalDeductions
        FROM dbo.PR_SalaryDetail
        GROUP BY PR_SalaryDetail.SalaryId),
         EndWorkDetailsCTE
    AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
               PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
               PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
               PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
               PR_EmployeeEndWorkDetail.TotalBouns,
               PR_EmployeeEndWorkDetail.TotalPenalty,
               PR_EmployeeEndWorkDetail.TotalAdvance,
               PR_EmployeeEndWorkDetail.TotalPurchase,
               PR_EmployeeEndWork.EmployeeId,
               PR_EmployeeEndWork.LastWorkingDay,
               PR_EmployeeEndWorkDetail.CurrencyId
        FROM dbo.PR_EmployeeEndWorkDetail
            INNER JOIN dbo.PR_EmployeeEndWork
                ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
        WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
         PrepaidVacationsCTE
    AS (SELECT SalaryMainId,
               IsVacationSalary,
               SalaryMonth
        FROM dbo.PR_SalaryMain
        WHERE IsVacationSalary = 1),
         Report
    AS (SELECT DISTINCT
               PR_Employee.EmployeeId,
               PR_Employee.EmployeeNumber,
               PR_Employee.EmployeeName,
               PR_Employee.EmployeeArabicName,
               PR_Job.JobName,
               PR_Salaries.InsuranceCompany,
               PR_Department.DepartmentName,
               PR_Department.DepartmentId,
               PR_Branch_1.BranchName,
               PR_Branch_1.BranchId,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalIncome - TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
                   ELSE
                       PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
               END AS TotalSalary,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                                   + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalDeductions
               END AS TotalDeductions,
               Acc_Currency.CurrencyName,
               Acc_Currency.CurrencyNameArabic,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT SUM(   CASE
                                             WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                                  AND PR_SalaryDetail.Deduction = 0 THEN
                                                 PR_SalaryDetail.IncomeAmount
                                             ELSE
                                                 0
                                         END
                                     )
                           FROM dbo.PR_SalaryDetail
                           WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                                   + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalAdditions
               END AS TotalAdditions,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryMonth
               END AS SalaryMonth,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryYear
               END AS SalaryYear,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       N'إجازة مدفوعة مقدماً'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       N'اخلاء طرف'
                   ELSE
                       N'راتب شهري'
               END AS SalarySource,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       'Prepaid Vacation'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       'End of Work'
                   ELSE
                       'Monthly Salary'
               END AS SalarySourceEng
        FROM dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain
                ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Job
                ON PR_Job.JobId = PR_Employee.JobId
            LEFT OUTER JOIN dbo.PR_Department
                ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch AS PR_Branch_1
                ON PR_Branch_1.BranchId = PR_Employee.BranchId
            LEFT OUTER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
            LEFT OUTER JOIN PrepaidVacationsCTE
                ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN EndWorkDetailsCTE
                ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
                AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @Month
                      AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @Year
        WHERE (
                  (
                      EndWorkDetailsCTE.EmployeeId IS NOT NULL
                  )
                  OR
                  (
                      EndWorkDetailsCTE.EmployeeId IS NULL
                      AND PR_SalaryMain.SalaryMonth = @Month
                      AND PR_SalaryMain.SalaryYear = @Year
                  )
              )
              AND
              (
                  (
                      ISNULL(@DepartmentIds, '') = ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT DepartmentId FROM dbo.PR_Department
                          )
                  )
                  OR
                  (
                      ISNULL(@DepartmentIds, '') <> ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@DepartmentIds)
                          )
                  )
              )
              AND
              (
                  (
                      ISNULL(@BranchIds, '') = ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT BranchId FROM dbo.PR_Branch
                          )
                  )
                  OR
                  (
                      ISNULL(@BranchIds, '') <> ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@BranchIds)
                          )
                  )
              )
              AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel)
    SELECT ROW_NUMBER() OVER (ORDER BY Report.BranchId, Report.DepartmentId, Report.EmployeeId,
                                       Report.SalaryYear, Report.SalaryMonth, Report.SalarySourceEng,
                                       Report.CurrencyName, Report.InsuranceCompany, Report.TotalSalary) AS RowNo,
           Report.EmployeeId,
           Report.EmployeeNumber,
           Report.EmployeeName,
           Report.EmployeeArabicName,
           Report.JobName,
           Report.InsuranceCompany,
           Report.DepartmentName,
           Report.DepartmentId,
           Report.BranchName,
           Report.BranchId,
           Report.TotalSalary,
           Report.TotalDeductions,
           Report.CurrencyName,
           Report.CurrencyNameArabic,
           Report.TotalAdditions,
           Report.SalaryMonth,
           Report.SalaryYear,
           Report.SalarySource,
           Report.SalarySourceEng
    INTO #new FROM Report
;
WITH PrepaidVacationDetails
AS (SELECT PR_SalaryDetail.SalaryId,
           SUM(   CASE
                      WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                           AND PR_SalaryDetail.Deduction = 0 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalIncome,
           SUM(   CASE
                      WHEN PR_SalaryDetail.Deduction = 1 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalDeductions
    FROM PR_SalaryDetail
    GROUP BY PR_SalaryDetail.SalaryId),
     EndWorkDetailsCTE
AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
           PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
           PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
           PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
           PR_EmployeeEndWorkDetail.TotalBouns,
           PR_EmployeeEndWorkDetail.TotalPenalty,
           PR_EmployeeEndWorkDetail.TotalAdvance,
           PR_EmployeeEndWorkDetail.TotalPurchase,
           PR_EmployeeEndWork.EmployeeId,
           PR_EmployeeEndWork.LastWorkingDay,
           PR_EmployeeEndWorkDetail.CurrencyId
    FROM PR_EmployeeEndWorkDetail
        INNER JOIN PR_EmployeeEndWork
            ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
     PrepaidVacationsCTE
AS (SELECT SalaryMainId,
           IsVacationSalary,
           SalaryMonth
    FROM PR_SalaryMain
    WHERE IsVacationSalary = 1)
SELECT DISTINCT
       PR_Employee.EmployeeId,
       PR_Employee.EmployeeNumber,
       PR_Employee.EmployeeName,
       PR_Job.JobName,
       PR_Salaries.InsuranceCompany,
       PR_Department.DepartmentName,
       PR_Department.DepartmentId,
       PR_Branch_1.BranchName,
       PR_Branch_1.BranchId,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalIncome - TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
           ELSE
               PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
       END AS TotalSalary,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                           + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalDeductions
       END AS TotalDeductions,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT SUM(   CASE
                                     WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                          AND PR_SalaryDetail.Deduction = 0 THEN
                                         PR_SalaryDetail.IncomeAmount
                                     ELSE
                                         0
                                 END
                             )
                   FROM PR_SalaryDetail
                   WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                           + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalAdditions
       END AS TotalAdditions,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryMonth
       END AS SalaryMonth,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryYear
       END AS SalaryYear,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               N'إجازة مدفوعة مقدماً'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               N'اخلاء طرف'
           ELSE
               N'راتب شهري'
       END AS SalarySource,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               'Prepaid Vacation'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               'End of Work'
           ELSE
               'Monthly Salary'
       END AS SalarySourceEng
INTO #old
FROM PR_Salaries
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT OUTER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    LEFT OUTER JOIN PR_Department
        ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN PR_Branch AS PR_Branch_1
        ON PR_Branch_1.BranchId = PR_Employee.BranchId
    LEFT OUTER JOIN Acc_Currency
        ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
    LEFT OUTER JOIN PrepaidVacationsCTE
        ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN EndWorkDetailsCTE
        ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
        AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
WHERE (
          (
              EndWorkDetailsCTE.EmployeeId IS NOT NULL
          )
          OR
          (
              EndWorkDetailsCTE.EmployeeId IS NULL
              AND PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (
              @DepartmentId = ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT DepartmentId FROM PR_Department
                  )
          )
          OR
          (
              @DepartmentId <> ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@DepartmentId)
                  )
          )
      )
      AND
      (
          (
              @BranchId = ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT BranchId FROM PR_Branch
                  )
          )
          OR
          (
              @BranchId <> ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@BranchId)
                  )
          )
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel
;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R6 2026/07 all' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(InsuranceCompany) FROM #old) OldIns, (SELECT SUM(InsuranceCompany) FROM #new) NewIns, (SELECT SUM(TotalAdditions) FROM #old) OldAdd, (SELECT SUM(TotalAdditions) FROM #new) NewAdd, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(TotalSalary) FROM #old) OldNet, (SELECT SUM(TotalSalary) FROM #new) NewNet,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
DECLARE @Month INT = 5, @Year INT = 2026, @SecurityLevel INT = 5, @DepartmentIds NVARCHAR(MAX) = NULL, @BranchIds NVARCHAR(MAX) = NULL;
DECLARE @SalaryMonth DECIMAL = 5, @SalaryYear DECIMAL = 2026, @DepartmentId VARCHAR(1024) = '', @BranchId VARCHAR(1024) = '', @UserSecurityLevel INT = 5;
;
    WITH PrepaidVacationDetails
    AS (SELECT PR_SalaryDetail.SalaryId,
               SUM(   CASE
                          WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                               AND PR_SalaryDetail.Deduction = 0 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalIncome,
               SUM(   CASE
                          WHEN PR_SalaryDetail.Deduction = 1 THEN
                              PR_SalaryDetail.UserAmount
                          ELSE
                              0
                      END
                  ) AS TotalDeductions
        FROM dbo.PR_SalaryDetail
        GROUP BY PR_SalaryDetail.SalaryId),
         EndWorkDetailsCTE
    AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
               PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
               PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
               PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
               PR_EmployeeEndWorkDetail.TotalBouns,
               PR_EmployeeEndWorkDetail.TotalPenalty,
               PR_EmployeeEndWorkDetail.TotalAdvance,
               PR_EmployeeEndWorkDetail.TotalPurchase,
               PR_EmployeeEndWork.EmployeeId,
               PR_EmployeeEndWork.LastWorkingDay,
               PR_EmployeeEndWorkDetail.CurrencyId
        FROM dbo.PR_EmployeeEndWorkDetail
            INNER JOIN dbo.PR_EmployeeEndWork
                ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
        WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
         PrepaidVacationsCTE
    AS (SELECT SalaryMainId,
               IsVacationSalary,
               SalaryMonth
        FROM dbo.PR_SalaryMain
        WHERE IsVacationSalary = 1),
         Report
    AS (SELECT DISTINCT
               PR_Employee.EmployeeId,
               PR_Employee.EmployeeNumber,
               PR_Employee.EmployeeName,
               PR_Employee.EmployeeArabicName,
               PR_Job.JobName,
               PR_Salaries.InsuranceCompany,
               PR_Department.DepartmentName,
               PR_Department.DepartmentId,
               PR_Branch_1.BranchName,
               PR_Branch_1.BranchId,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalIncome - TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
                   ELSE
                       PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
               END AS TotalSalary,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT TotalDeductions
                           FROM PrepaidVacationDetails
                           WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                                   + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalDeductions
               END AS TotalDeductions,
               Acc_Currency.CurrencyName,
               Acc_Currency.CurrencyNameArabic,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       COALESCE(
                       (
                           SELECT SUM(   CASE
                                             WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                                  AND PR_SalaryDetail.Deduction = 0 THEN
                                                 PR_SalaryDetail.IncomeAmount
                                             ELSE
                                                 0
                                         END
                                     )
                           FROM dbo.PR_SalaryDetail
                           WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
                       ),
                       0
                               )
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(
                                   EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                                   + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                                   0
                               )
                   ELSE
                       PR_Salaries.TotalAdditions
               END AS TotalAdditions,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryMonth
               END AS SalaryMonth,
               CASE
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
                   ELSE
                       PR_SalaryMain.SalaryYear
               END AS SalaryYear,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       N'إجازة مدفوعة مقدماً'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       N'اخلاء طرف'
                   ELSE
                       N'راتب شهري'
               END AS SalarySource,
               CASE
                   WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
                       'Prepaid Vacation'
                   WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
                       'End of Work'
                   ELSE
                       'Monthly Salary'
               END AS SalarySourceEng
        FROM dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain
                ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Job
                ON PR_Job.JobId = PR_Employee.JobId
            LEFT OUTER JOIN dbo.PR_Department
                ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch AS PR_Branch_1
                ON PR_Branch_1.BranchId = PR_Employee.BranchId
            LEFT OUTER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
            LEFT OUTER JOIN PrepaidVacationsCTE
                ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
            LEFT OUTER JOIN EndWorkDetailsCTE
                ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
                AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @Month
                      AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @Year
        WHERE (
                  (
                      EndWorkDetailsCTE.EmployeeId IS NOT NULL
                  )
                  OR
                  (
                      EndWorkDetailsCTE.EmployeeId IS NULL
                      AND PR_SalaryMain.SalaryMonth = @Month
                      AND PR_SalaryMain.SalaryYear = @Year
                  )
              )
              AND
              (
                  (
                      ISNULL(@DepartmentIds, '') = ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT DepartmentId FROM dbo.PR_Department
                          )
                  )
                  OR
                  (
                      ISNULL(@DepartmentIds, '') <> ''
                      AND PR_Department.DepartmentId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@DepartmentIds)
                          )
                  )
              )
              AND
              (
                  (
                      ISNULL(@BranchIds, '') = ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT BranchId FROM dbo.PR_Branch
                          )
                  )
                  OR
                  (
                      ISNULL(@BranchIds, '') <> ''
                      AND PR_Branch_1.BranchId IN
                          (
                              SELECT number FROM dbo.Acc_ConvertIntListToTable(@BranchIds)
                          )
                  )
              )
              AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel)
    SELECT ROW_NUMBER() OVER (ORDER BY Report.BranchId, Report.DepartmentId, Report.EmployeeId,
                                       Report.SalaryYear, Report.SalaryMonth, Report.SalarySourceEng,
                                       Report.CurrencyName, Report.InsuranceCompany, Report.TotalSalary) AS RowNo,
           Report.EmployeeId,
           Report.EmployeeNumber,
           Report.EmployeeName,
           Report.EmployeeArabicName,
           Report.JobName,
           Report.InsuranceCompany,
           Report.DepartmentName,
           Report.DepartmentId,
           Report.BranchName,
           Report.BranchId,
           Report.TotalSalary,
           Report.TotalDeductions,
           Report.CurrencyName,
           Report.CurrencyNameArabic,
           Report.TotalAdditions,
           Report.SalaryMonth,
           Report.SalaryYear,
           Report.SalarySource,
           Report.SalarySourceEng
    INTO #new FROM Report
;
WITH PrepaidVacationDetails
AS (SELECT PR_SalaryDetail.SalaryId,
           SUM(   CASE
                      WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                           AND PR_SalaryDetail.Deduction = 0 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalIncome,
           SUM(   CASE
                      WHEN PR_SalaryDetail.Deduction = 1 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalDeductions
    FROM PR_SalaryDetail
    GROUP BY PR_SalaryDetail.SalaryId),
     EndWorkDetailsCTE
AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
           PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
           PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
           PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
           PR_EmployeeEndWorkDetail.TotalBouns,
           PR_EmployeeEndWorkDetail.TotalPenalty,
           PR_EmployeeEndWorkDetail.TotalAdvance,
           PR_EmployeeEndWorkDetail.TotalPurchase,
           PR_EmployeeEndWork.EmployeeId,
           PR_EmployeeEndWork.LastWorkingDay,
           PR_EmployeeEndWorkDetail.CurrencyId
    FROM PR_EmployeeEndWorkDetail
        INNER JOIN PR_EmployeeEndWork
            ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
     PrepaidVacationsCTE
AS (SELECT SalaryMainId,
           IsVacationSalary,
           SalaryMonth
    FROM PR_SalaryMain
    WHERE IsVacationSalary = 1)
SELECT DISTINCT
       PR_Employee.EmployeeId,
       PR_Employee.EmployeeNumber,
       PR_Employee.EmployeeName,
       PR_Job.JobName,
       PR_Salaries.InsuranceCompany,
       PR_Department.DepartmentName,
       PR_Department.DepartmentId,
       PR_Branch_1.BranchName,
       PR_Branch_1.BranchId,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalIncome - TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
           ELSE
               PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
       END AS TotalSalary,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                           + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalDeductions
       END AS TotalDeductions,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT SUM(   CASE
                                     WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                          AND PR_SalaryDetail.Deduction = 0 THEN
                                         PR_SalaryDetail.IncomeAmount
                                     ELSE
                                         0
                                 END
                             )
                   FROM PR_SalaryDetail
                   WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                           + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalAdditions
       END AS TotalAdditions,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryMonth
       END AS SalaryMonth,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryYear
       END AS SalaryYear,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               N'إجازة مدفوعة مقدماً'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               N'اخلاء طرف'
           ELSE
               N'راتب شهري'
       END AS SalarySource,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               'Prepaid Vacation'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               'End of Work'
           ELSE
               'Monthly Salary'
       END AS SalarySourceEng
INTO #old
FROM PR_Salaries
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT OUTER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    LEFT OUTER JOIN PR_Department
        ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN PR_Branch AS PR_Branch_1
        ON PR_Branch_1.BranchId = PR_Employee.BranchId
    LEFT OUTER JOIN Acc_Currency
        ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
    LEFT OUTER JOIN PrepaidVacationsCTE
        ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN EndWorkDetailsCTE
        ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
        AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
WHERE (
          (
              EndWorkDetailsCTE.EmployeeId IS NOT NULL
          )
          OR
          (
              EndWorkDetailsCTE.EmployeeId IS NULL
              AND PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (
              @DepartmentId = ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT DepartmentId FROM PR_Department
                  )
          )
          OR
          (
              @DepartmentId <> ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@DepartmentId)
                  )
          )
      )
      AND
      (
          (
              @BranchId = ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT BranchId FROM PR_Branch
                  )
          )
          OR
          (
              @BranchId <> ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@BranchId)
                  )
          )
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel
;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #o FROM #old;
SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng, ROW_NUMBER() OVER (PARTITION BY EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng ORDER BY (SELECT 0)) AS dup INTO #n FROM (SELECT EmployeeId, EmployeeNumber, EmployeeName, JobName, InsuranceCompany, DepartmentName, DepartmentId, BranchName, BranchId, TotalSalary, TotalDeductions, CurrencyName, CurrencyNameArabic, TotalAdditions, SalaryMonth, SalaryYear, SalarySource, SalarySourceEng FROM #new) x;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R6 2026/05 all (PV runs)' AS TestCase, (SELECT COUNT(*) FROM #old) AS OldRows, (SELECT COUNT(*) FROM #new) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(InsuranceCompany) FROM #old) OldIns, (SELECT SUM(InsuranceCompany) FROM #new) NewIns, (SELECT SUM(TotalAdditions) FROM #old) OldAdd, (SELECT SUM(TotalAdditions) FROM #new) NewAdd, (SELECT SUM(TotalDeductions) FROM #old) OldDed, (SELECT SUM(TotalDeductions) FROM #new) NewDed, (SELECT SUM(TotalSalary) FROM #old) OldNet, (SELECT SUM(TotalSalary) FROM #new) NewNet,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #old)=(SELECT COUNT(*) FROM #new) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no; DROP TABLE #old; DROP TABLE #new;
GO
