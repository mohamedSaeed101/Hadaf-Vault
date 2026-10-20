-- R8 parity: dbo.PR_PostedSalariesReport (TVF body verbatim from origin/cr125292)
-- vs legacy dsDepartmentSalary.xsd FillPosted (verbatim from AccFlex_ERP origin/Master_Stable).
-- Read-only: temp tables and variables only. Run with: sqlcmd -v Y=2026 M=8 P=1 L=5 IDS=ALL  (ALL = front's "nothing selected"; explicit ids as 1_4_113)
SET NOCOUNT ON;
DECLARE @ids NVARCHAR(MAX) = ISNULL(REPLACE(NULLIF(N'$(IDS)', N'ALL'), N'_', N','), N'');  -- IDS=ALL or ids joined by _
-- NEW parameters (TVF): '' / NULL = all employees
DECLARE @Month INT = $(M), @Year INT = $(Y), @SecurityLevel INT = $(L), @IsPost BIT = $(P), @EmployeeIds NVARCHAR(MAX) = NULLIF(@ids, N'');
-- LEGACY SqlParameters as generated: Decimal, Decimal, VarChar(1024) (ADO truncates silently), Bit (non-nullable), Int.
-- Front emulation: nothing selected -> CSV of every EmployeeId in pay-shared-employee-list (inServiceOnly=false) = all PR_Employee ids.
DECLARE @allIds NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(MAX)), ',') FROM dbo.PR_Employee);
DECLARE @SalaryMonth DECIMAL(18,0) = $(M), @SalaryYear DECIMAL(18,0) = $(Y), @IsPosted BIT = $(P), @UserSecurityLevel INT = $(L);
DECLARE @EmployeeIdList VARCHAR(1024) = LEFT(CASE WHEN @ids = N'' THEN @allIds ELSE @ids END, 1024);
SELECT 'idlist' k, LEN(CASE WHEN @ids = N'' THEN @allIds ELSE @ids END) AS csv_len, CASE WHEN LEN(CASE WHEN @ids = N'' THEN @allIds ELSE @ids END) > 1024 THEN 'TRUNCATED' ELSE 'fits' END AS legacy_1024;

-- NEW
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
        WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0
              AND MONTH(LastWorkingDay) = @Month
              AND YEAR(LastWorkingDay) = @Year),
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
               END AS SalarySourceEng,
               PR_Employee.IDNumber
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
        WHERE (
                  (
                      MONTH(EndWorkDetailsCTE.LastWorkingDay) = @Month
                      AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @Year
                  )
                  OR
                  (
                      PR_SalaryMain.SalaryMonth = @Month
                      AND PR_SalaryMain.SalaryYear = @Year
                  )
              )
              AND
              (
                  (ISNULL(@EmployeeIds, '') = '')
                  OR (PR_Employee.EmployeeId IN
                      (
                          SELECT number
                          FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
                      )
                     )
              )
              AND
              (
                  (@IsPost IS NULL)
                  OR (PR_Salaries.Posted = @IsPost)
              )
              AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel)
    SELECT ROW_NUMBER() OVER (ORDER BY Report.EmployeeId, Report.SalaryYear, Report.SalaryMonth,
                                       Report.SalarySourceEng, Report.CurrencyName, Report.InsuranceCompany,
                                       Report.TotalSalary) AS RowNo,
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
           Report.SalarySourceEng,
           Report.IDNumber
    INTO #new
    FROM Report
;
-- OLD
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
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0
	AND MONTH(LastWorkingDay)=
	@SalaryMonth AND YEAR(LastWorkingDay)=@SalaryYear),
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
       END AS SalarySourceEng,
	   PR_Employee.IDNumber
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
WHERE (
          (
              MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
          )
          OR
          (
              PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (@EmployeeIdList = '')
          OR (PR_Employee.EmployeeId IN
              (
                  SELECT number
                  FROM dbo.Acc_ConvertStringListToTable(@EmployeeIdList) AS Acc_ConvertStringListToTable_1
              )
             )
      )
      AND
      (
          (@IsPosted IS NULL)
          OR (PR_Salaries.Posted = @IsPosted)
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel;

SELECT 'R8 Y=$(Y) M=$(M) IsPost=$(P) L=$(L) IDS=[$(IDS)]' AS [case], (SELECT COUNT(*) FROM #old) AS rows_old, (SELECT COUNT(*) FROM #new) AS rows_new,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #old EXCEPT SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #new) d) AS old_minus_new,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #new EXCEPT SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #old) d) AS new_minus_old,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber, COUNT(*) c FROM #old GROUP BY EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber EXCEPT SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber, COUNT(*) FROM #new GROUP BY EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber) d) AS grp_old_minus_new,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber, COUNT(*) c FROM #new GROUP BY EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber EXCEPT SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber, COUNT(*) FROM #old GROUP BY EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber) d) AS grp_new_minus_old;
SELECT 'sums' k, 'old' src, SUM(InsuranceCompany) InsuranceCompany, SUM(TotalAdditions) TotalAdditions, SUM(TotalDeductions) TotalDeductions, SUM(TotalSalary) TotalSalary FROM #old
UNION ALL SELECT 'sums', 'new', SUM(InsuranceCompany), SUM(TotalAdditions), SUM(TotalDeductions), SUM(TotalSalary) FROM #new;
SELECT 'by_source' k, SalarySourceEng, (SELECT COUNT(*) FROM #old o WHERE o.SalarySourceEng = s.SalarySourceEng) old_n, (SELECT COUNT(*) FROM #new n WHERE n.SalarySourceEng = s.SalarySourceEng) new_n
FROM (SELECT SalarySourceEng FROM #old UNION SELECT SalarySourceEng FROM #new) s;
SELECT TOP 10 'old-new' k, EmployeeId, EmployeeNumber, SalaryMonth, SalaryYear, SalarySourceEng, TotalAdditions, TotalDeductions, TotalSalary FROM (SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #old EXCEPT SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #new) d;
SELECT TOP 10 'new-old' k, EmployeeId, EmployeeNumber, SalaryMonth, SalaryYear, SalarySourceEng, TotalAdditions, TotalDeductions, TotalSalary FROM (SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #new EXCEPT SELECT EmployeeId,EmployeeNumber,EmployeeName,JobName,InsuranceCompany,DepartmentName,DepartmentId,BranchName,BranchId,TotalSalary,TotalDeductions,CurrencyName,CurrencyNameArabic,TotalAdditions,SalaryMonth,SalaryYear,SalarySource,SalarySourceEng,IDNumber FROM #old) d;
SELECT 'rowno_unique' k, COUNT(*) n, COUNT(DISTINCT RowNo) distinct_rowno FROM #new;
-- end-of-work coverage (legacy join defect kept per D4)
SELECT 'endwork_in_month' k, COUNT(*) n FROM dbo.PR_EmployeeEndWork WHERE MONTH(LastWorkingDay) = @Month AND YEAR(LastWorkingDay) = @Year;
DROP TABLE #new; DROP TABLE #old;
