-- legacy EmployeeInsurance with only the approved Fix (EndWorkingDate < GETDATE() -> >= CAST(GETDATE() AS DATE))
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
