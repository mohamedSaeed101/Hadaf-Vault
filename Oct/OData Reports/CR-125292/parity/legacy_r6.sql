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
