-- Web OData port of the legacy MVC report HrReports/RiskAnalysis (rptRiskAnalysis.BeforePrint over
-- dsRiskAnalysis.xsd): one row per employee and income currency.
-- * Deliberate deviation from legacy (CR 125299 decision D6): salary (Risk, Vacations) and the
--   policy-band salary (Compensation) sum only the row's own employee's incomes in the row's currency,
--   started on or before @RiskDate. Legacy summed the incomes of every listed employee (its C# filters
--   had no EmployeeId), a calculation bug.
-- The other legacy C# rules are kept as they were:
-- * more than 90 days of service means the end of the @RiskDate day minus the date of work is > 90 days;
-- * the policy band is chosen and Compensation multiplied with the calendar years (PR_CalendarDateDifference);
-- * the vacation figures are dbo.Pr_VacationBalance at the last day of the month before @RiskDate
--   (paid filter NULL); an employee the procedure returns no row for counts as 0 taken and 0 balance;
-- * Math.Round(decimal) rounds half to even, so each rounding below does the same (decision D8: legacy
--   could land a Vacations .xx5 tie 0.01 off through System.Decimal division error; not emulated);
-- * Others is never set, so it keeps its DefaultValue 0 and Total = RiskAmount + Compensation + Vacations.
-- Empty or NULL @EmployeeIds returns no rows, as legacy (decision D9); callers always send ids.
CREATE OR ALTER FUNCTION dbo.PR_RiskAnalysisReport
(
    @EmployeeIds NVARCHAR(MAX),
    @RiskDate DATETIME,
    @IsArabic BIT
)
RETURNS TABLE
AS
RETURN
(
    WITH prm
    AS (SELECT CAST(CAST(@RiskDate AS DATE) AS DATETIME) AS RiskDay,
               CAST(EOMONTH(DATEADD(MONTH, -1, @RiskDate)) AS DATETIME) AS VacDate),
         EmployeeCurrencies
    AS (SELECT DISTINCT IncomeCurrency, EmployeeId FROM dbo.PR_EmployeeIncome),
         employee
    AS (SELECT PR_Employee.EmployeeId,
               CurrencyId,
               CASE WHEN @IsArabic = 1 THEN EmployeeArabicName ELSE PR_Employee.EmployeeName END AS EmployeeName,
               CASE WHEN @IsArabic = 1 THEN CurrencyNameArabic ELSE CurrencyName END AS CurrencyName,
               PR_Employee.DateOfWork,
               PR_Employee.EmployeeNumber,
               PR_Job.JobName,
               PR_Employee.EndServicePolicyId
        FROM PR_Employee
            INNER JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            INNER JOIN EmployeeCurrencies ON EmployeeCurrencies.EmployeeId = PR_Employee.EmployeeId
            INNER JOIN dbo.Acc_Currency ON EmployeeCurrencies.IncomeCurrency = CurrencyId
        WHERE PR_Employee.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )),
         income
    AS (SELECT EmployeeId,
               IncomeId,
               IncomeCurrency,
               IncomeAmount
        FROM dbo.PR_EmployeeIncome
        WHERE EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND ((SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration) = 0 OR SocialInsuranceRoleId IS NULL)
              AND IncomeStartDate <= @RiskDate),
         salary
    AS (SELECT EmployeeId,
               IncomeCurrency,
               SUM(IncomeAmount) AS Salary
        FROM income
        GROUP BY EmployeeId,
                 IncomeCurrency),
         -- dbo.Pr_VacationBalance, @atDate = prm.VacDate, @PaidVacation = NULL
         empsAndTypes
    AS (SELECT EmployeeId,
               AnnualVacationTypeId
        FROM dbo.PR_Employee
            CROSS JOIN dbo.PR_AnnualVacationType
        WHERE PR_Employee.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND IsSicknessLeave = 0),
         taken_Vacations
    AS (SELECT empsAndTypes.EmployeeId,
               ISNULL(SUM(PR_Vacations.VacationDays), 0) VacationDays
        FROM empsAndTypes
            CROSS JOIN prm
            LEFT JOIN dbo.PR_Vacations
                ON PR_Vacations.EmployeeId = empsAndTypes.EmployeeId
                   AND PR_Vacations.AnnualVacationTypeId = empsAndTypes.AnnualVacationTypeId
                   AND HrApproved = 1
                   AND ManagerApproved = 1
                   AND DateFrom <= prm.VacDate
                   AND VacationTypeId = 1
        GROUP BY empsAndTypes.EmployeeId),
         accuredVacatons
    AS (SELECT PR_EmployeeAccruedvacation.EmployeeId,
               SUM(ISNULL(PR_EmployeeAccruedvacation.NumberOfDays, 0)) NumberOfDays
        FROM dbo.PR_EmployeeAccruedvacation
            CROSS JOIN prm
        WHERE PR_EmployeeAccruedvacation.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND ValidFromDate <= prm.VacDate
        GROUP BY PR_EmployeeAccruedvacation.EmployeeId),
         UnPaidVacations
    AS (SELECT ISNULL(SUM(PR_Vacations.UnpaidExcessDays), 0) AllUnPaidExcessDays,
               ISNULL(SUM(CASE WHEN DateFrom > SeniortyStartDate THEN PR_Vacations.UnpaidExcessDays ELSE 0 END), 0) UnPaidExcessDaysAfterSeniority,
               PR_Employee.EmployeeId
        FROM dbo.PR_Employee
            CROSS JOIN prm
            LEFT JOIN dbo.PR_Vacations
                ON PR_Employee.EmployeeId = PR_Vacations.EmployeeId
        WHERE VacationTypeId = 5
              AND ManagerApproved = 1
              AND HrApproved = 1
              AND DateFrom <= prm.VacDate
              AND PR_Employee.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
                  )
        GROUP BY PR_Employee.EmployeeId),
         AnnualVacations
    AS (SELECT dbo.PR_Employee.EmployeeId,
               ISNULL(
                         SUM(   CASE
                                    WHEN PR_AnnualVacationSystemDetail.AnnualVacationStartingCalculationId = 1 THEN
                                (DATEDIFF(DAY, WorkDate, prm.VacDate) - ISNULL(UnPaidVacations.AllUnPaidExcessDays, 0))
                                / 365.0 * NumberOfDays
                                    ELSE
                                (DATEDIFF(DAY, ISNULL(SeniortyStartDate, prm.VacDate), prm.VacDate)
                                 - ISNULL(UnPaidVacations.UnPaidExcessDaysAfterSeniority, 0)
                                ) / 365.0 * NumberOfDays
                                END
                            ),
                         0
                     ) AS balance
        FROM dbo.PR_Employee
            CROSS JOIN prm
            LEFT JOIN dbo.PR_AnnualVacationSystemDetail
                ON PR_AnnualVacationSystemDetail.AnnualVacationSystemId = PR_Employee.AnnualVacationSystemId
            LEFT JOIN dbo.PR_AnnualVacationType
                ON PR_AnnualVacationType.AnnualVacationTypeId = PR_AnnualVacationSystemDetail.AnnualVacationTypeId
            LEFT JOIN UnPaidVacations
                ON UnPaidVacations.EmployeeId = PR_Employee.EmployeeId
        WHERE IsSicknessLeave = 0 AND IsOneTime = 0
        GROUP BY PR_Employee.EmployeeId),
         vacationBalance
    AS (SELECT PR_Employee.EmployeeId,
               ISNULL(taken_Vacations.VacationDays, 0) AS PaidVactions,
               ISNULL(accuredVacatons.NumberOfDays, 0) + ISNULL(AnnualVacations.balance, 0)
               - ISNULL(taken_Vacations.VacationDays, 0) AS VacationBalance
        FROM dbo.PR_Employee
            INNER JOIN dbo.PR_Department
                ON dbo.PR_Department.DepartmentId = dbo.PR_Employee.DepartmentId
            INNER JOIN dbo.PR_Branch
                ON dbo.PR_Branch.BranchId = dbo.PR_Employee.BranchId
            INNER JOIN dbo.PR_Job
                ON dbo.PR_Employee.JobId = dbo.PR_Job.JobId
            LEFT OUTER JOIN taken_Vacations
                ON taken_Vacations.EmployeeId = PR_Employee.EmployeeId
            LEFT OUTER JOIN accuredVacatons
                ON accuredVacatons.EmployeeId = PR_Employee.EmployeeId
            LEFT OUTER JOIN AnnualVacations
                ON AnnualVacations.EmployeeId = PR_Employee.EmployeeId
        WHERE PR_Employee.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )),
         calc
    AS (SELECT employee.EmployeeId,
               employee.CurrencyId,
               employee.CurrencyName,
               employee.EmployeeName,
               employee.EmployeeNumber,
               employee.JobName,
               employee.DateOfWork,
               diff.Days AS DaysOfWork,
               diff.Months AS MonthesOfWork,
               diff.Years AS YearsOfWork,
               diff.Years + CASE WHEN (diff.Days > 0 OR diff.Months > 0) AND span.Over90 = 1 THEN 1 ELSE 0 END AS NetYearsOfWork,
               span.Over90,
               CAST(ISNULL(salary.Salary, 0) AS DECIMAL(19, 4)) AS Salary,
               stage.BounsMonthesPerYear,
               stage.EndServicePolicyDetailId,
               CAST(ISNULL(policySalary.Salary, 0) AS DECIMAL(19, 4)) AS PolicySalary,
               CAST(1.75 * MONTH(prm.VacDate) AS DECIMAL(28, 9)) - ISNULL(vacationBalance.PaidVactions, 0)
               + CASE
                     WHEN CAST(ISNULL(vacationBalance.VacationBalance, 0) AS DECIMAL(28, 9)) > 21 THEN
                         CAST(vacationBalance.VacationBalance AS DECIMAL(28, 9)) - 21
                     ELSE
                         0
                 END AS VacationBalanceRaw
        FROM employee
            CROSS JOIN prm
            CROSS APPLY dbo.PR_CalendarDateDifference(prm.RiskDay, CAST(employee.DateOfWork AS DATE)) AS diff
            CROSS APPLY
        (
            SELECT CASE WHEN DATEDIFF(DAY, CAST(employee.DateOfWork AS DATE), prm.RiskDay) >= 90 THEN 1 ELSE 0 END AS Over90
        ) AS span
            LEFT JOIN salary
                ON salary.EmployeeId = employee.EmployeeId
                   AND salary.IncomeCurrency = employee.CurrencyId
            OUTER APPLY
        (
            SELECT TOP 1
                   Pr_EndServicePolicyDetail.EndServicePolicyDetailId,
                   Pr_EndServicePolicyDetail.BounsMonthesPerYear
            FROM dbo.Pr_EndServicePolicyDetail
            WHERE Pr_EndServicePolicyDetail.EndServicePolicyId = employee.EndServicePolicyId
                  AND Pr_EndServicePolicyDetail.WorkingYearsFrom <= diff.Years
                  AND Pr_EndServicePolicyDetail.WorkingYearsTo >= diff.Years
            ORDER BY Pr_EndServicePolicyDetail.WorkingYearsFrom DESC,
                     Pr_EndServicePolicyDetail.EndServicePolicyDetailId
        ) AS stage
            OUTER APPLY
        (
            SELECT SUM(income.IncomeAmount) AS Salary
            FROM income
            WHERE income.EmployeeId = employee.EmployeeId
                  AND income.IncomeCurrency = employee.CurrencyId
                  AND income.IncomeId IN
                      (
                          SELECT IncomeId
                          FROM dbo.Pr_IncomeEndServicePolicyDetail
                          WHERE EndServicePolicyDetailId = stage.EndServicePolicyDetailId
                      )
        ) AS policySalary
            LEFT JOIN vacationBalance
                ON vacationBalance.EmployeeId = employee.EmployeeId),
         amounts
    AS (SELECT calc.*,
               CASE WHEN calc.Over90 = 1 THEN calc.Salary * 2 ELSE 0 END AS RiskRaw,
               CASE
                   WHEN calc.EndServicePolicyDetailId IS NULL THEN
                       0
                   ELSE
                       calc.PolicySalary * CAST(calc.BounsMonthesPerYear AS DECIMAL(9, 4)) * CAST(calc.YearsOfWork AS DECIMAL(4, 0))
               END AS CompensationRaw,
               calc.Salary * CAST(calc.VacationBalanceRaw AS DECIMAL(18, 9)) / CAST(30 AS DECIMAL(2, 0)) AS VacationsRaw
        FROM calc),
         rounded
    AS (SELECT amounts.*,
               CAST(CASE
                        WHEN ABS(RiskRaw - ROUND(RiskRaw, 2, 1)) = 0.005 AND CAST(ROUND(RiskRaw, 2, 1) * 100 AS DECIMAL(38, 0)) % 2 = 0 THEN
                            ROUND(RiskRaw, 2, 1)
                        ELSE
                            ROUND(RiskRaw, 2)
                    END AS DECIMAL(19, 4)) AS RiskAmount,
               CAST(CASE
                        WHEN ABS(CompensationRaw - ROUND(CompensationRaw, 0, 1)) = 0.5 AND CAST(ROUND(CompensationRaw, 0, 1) AS DECIMAL(38, 0)) % 2 = 0 THEN
                            ROUND(CompensationRaw, 0, 1)
                        ELSE
                            ROUND(CompensationRaw, 0)
                    END AS DECIMAL(19, 4)) AS Compensation,
               CAST(CASE
                        WHEN ABS(VacationBalanceRaw - ROUND(VacationBalanceRaw, 2, 1)) = 0.005 AND CAST(ROUND(VacationBalanceRaw, 2, 1) * 100 AS DECIMAL(38, 0)) % 2 = 0 THEN
                            ROUND(VacationBalanceRaw, 2, 1)
                        ELSE
                            ROUND(VacationBalanceRaw, 2)
                    END AS DECIMAL(19, 4)) AS VacationBalance,
               CAST(CASE
                        WHEN ABS(VacationsRaw - ROUND(VacationsRaw, 2, 1)) = 0.005 AND CAST(ROUND(VacationsRaw, 2, 1) * 100 AS DECIMAL(38, 0)) % 2 = 0 THEN
                            ROUND(VacationsRaw, 2, 1)
                        ELSE
                            ROUND(VacationsRaw, 2)
                    END AS DECIMAL(19, 4)) AS Vacations
        FROM amounts)
    SELECT ROW_NUMBER() OVER (ORDER BY rounded.EmployeeId, rounded.CurrencyId) AS RowNo,
           rounded.EmployeeId,
           rounded.CurrencyId,
           rounded.CurrencyName,
           rounded.EmployeeName,
           rounded.EmployeeNumber,
           rounded.JobName,
           rounded.DateOfWork,
           rounded.DaysOfWork,
           rounded.MonthesOfWork,
           rounded.YearsOfWork,
           rounded.NetYearsOfWork,
           rounded.Compensation,
           rounded.RiskAmount,
           rounded.VacationBalance,
           rounded.Vacations,
           CAST(0 AS DECIMAL(19, 4)) AS Others,
           CAST(rounded.RiskAmount + rounded.Compensation + rounded.Vacations AS DECIMAL(19, 4)) AS Total
    FROM rounded
);
GO
