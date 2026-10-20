-- Web OData port of dbo.Pr_GetEmployee_Vacation_Statistics (desktop report rptEmployeeStatistics,
-- detail band). Same logic as the procedure, including the taken_Vacations GROUP BY VacationDays,
-- which splits one employee/vacation type into several rows when vacations have different lengths;
-- the legacy report shows those rows and sums them, so the numbers are kept. @ToDate is moved to
-- 23:59:59.997 of its day, as the legacy report did before calling the procedure.
CREATE OR ALTER FUNCTION dbo.PR_EmployeeVacationStatisticsReport
(
    @EmployeeIds NVARCHAR(MAX),
    @ToDate DATETIME
)
RETURNS TABLE
AS
RETURN
(
    WITH prm
    AS (SELECT DATEADD(MILLISECOND, -3, CAST(DATEADD(DAY, 1, CAST(@ToDate AS DATE)) AS DATETIME)) AS RangeTo),
         empsAndTypes
    AS (SELECT EmployeeId,
               AnnualVacationTypeId,
               PR_AnnualVacationType.Name,
               PR_AnnualVacationType.ArabicName
        FROM dbo.PR_Employee
            CROSS JOIN dbo.PR_AnnualVacationType
        WHERE PR_Employee.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )),
         taken_Vacations
    AS (SELECT empsAndTypes.EmployeeId,
               empsAndTypes.AnnualVacationTypeId,
               ISNULL(SUM(PR_Vacations.VacationDays), 0) VacationDays,
               empsAndTypes.Name,
               empsAndTypes.ArabicName
        FROM empsAndTypes
            CROSS JOIN prm
            LEFT JOIN dbo.PR_Vacations
                ON PR_Vacations.EmployeeId = empsAndTypes.EmployeeId
                   AND PR_Vacations.AnnualVacationTypeId = empsAndTypes.AnnualVacationTypeId
                   AND HrApproved = 1
                   AND ManagerApproved = 1
                   AND DateFrom <= prm.RangeTo
                   AND VacationTypeId = 1
        WHERE empsAndTypes.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
        GROUP BY empsAndTypes.EmployeeId,
                 empsAndTypes.AnnualVacationTypeId,
                 VacationDays,
                 empsAndTypes.Name,
                 empsAndTypes.ArabicName),
         accuredVacatons
    AS (SELECT PR_EmployeeAccruedvacation.EmployeeId,
               SUM(ISNULL(PR_EmployeeAccruedvacation.NumberOfDays, 0)) NumberOfDays,
               dbo.PR_EmployeeAccruedvacation.AnnualVacationTypeId
        FROM dbo.PR_EmployeeAccruedvacation
            CROSS JOIN prm
        WHERE PR_EmployeeAccruedvacation.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND ValidFromDate <= prm.RangeTo
        GROUP BY PR_EmployeeAccruedvacation.EmployeeId,
                 PR_EmployeeAccruedvacation.AnnualVacationTypeId),
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
              AND DateFrom <= prm.RangeTo
              AND PR_Employee.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
                  )
        GROUP BY PR_Employee.EmployeeId),
         AnnualVacations
    AS (SELECT dbo.PR_Employee.EmployeeId,
               PR_AnnualVacationSystemDetail.AnnualVacationTypeId,
               ISNULL(
                         SUM(   CASE
                                    WHEN PR_AnnualVacationSystemDetail.AnnualVacationStartingCalculationId = 1 THEN
                                (DATEDIFF(DAY, WorkDate, prm.RangeTo) - ISNULL(UnPaidVacations.AllUnPaidExcessDays, 0))
                                / 365.0 * NumberOfDays
                                    ELSE
                                (DATEDIFF(DAY, ISNULL(SeniortyStartDate, prm.RangeTo), prm.RangeTo)
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
        WHERE IsSicknessLeave = 0
        GROUP BY PR_Employee.EmployeeId,
                 PR_AnnualVacationSystemDetail.AnnualVacationTypeId)
    SELECT ROW_NUMBER() OVER (ORDER BY taken_Vacations.EmployeeId,
                                       taken_Vacations.AnnualVacationTypeId,
                                       taken_Vacations.VacationDays
                             ) AS RowNo,
           taken_Vacations.EmployeeId,
           taken_Vacations.AnnualVacationTypeId,
           taken_Vacations.Name AS AnnualVacationTypeNameSecondLanguage,
           taken_Vacations.ArabicName AS AnnualVacationTypeName,
           ISNULL(accuredVacatons.NumberOfDays, 0) + ISNULL(AnnualVacations.balance, 0) NumberOfDays,
           ISNULL(taken_Vacations.VacationDays, 0) VacationDays,
           ISNULL(accuredVacatons.NumberOfDays, 0) + ISNULL(AnnualVacations.balance, 0)
           - ISNULL(taken_Vacations.VacationDays, 0) AS VacationBalance
    FROM taken_Vacations
        LEFT JOIN accuredVacatons
            ON taken_Vacations.EmployeeId = accuredVacatons.EmployeeId
               AND taken_Vacations.AnnualVacationTypeId = accuredVacatons.AnnualVacationTypeId
        LEFT JOIN AnnualVacations
            ON AnnualVacations.EmployeeId = taken_Vacations.EmployeeId
               AND AnnualVacations.AnnualVacationTypeId = taken_Vacations.AnnualVacationTypeId
);
GO

-- Web OData port of dbo.Pr_GetEmployee_Statistics (desktop report rptEmployeeStatistics, master
-- band). VacationBalance is the sum of the employee's PR_EmployeeVacationStatisticsReport rows,
-- which the legacy report computed in C#; 0 when the employee has none. The range runs from
-- 00:00:00 of @FromDate to 23:59:59.997 of @ToDate, as the legacy report normalised it.
CREATE OR ALTER FUNCTION dbo.PR_EmployeeStatisticsReport
(
    @EmployeeIds NVARCHAR(MAX),
    @FromDate DATETIME,
    @ToDate DATETIME
)
RETURNS TABLE
AS
RETURN
(
    WITH prm
    AS (SELECT CAST(CAST(@FromDate AS DATE) AS DATETIME) AS RangeFrom,
               DATEADD(MILLISECOND, -3, CAST(DATEADD(DAY, 1, CAST(@ToDate AS DATE)) AS DATETIME)) AS RangeTo),
         advance
    AS (SELECT COUNT(AdvanceId) AS AdvanceCount,
               EmployeeId
        FROM dbo.PR_Advance
            CROSS JOIN prm
        WHERE PR_Advance.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND
              (
                  PR_Advance.Confirmed = 1
                  AND PR_Advance.IsAdvance = 1
              )
              AND (PR_Advance.ApplayingStartDate BETWEEN prm.RangeFrom AND prm.RangeTo)
        GROUP BY EmployeeId),
         purches
    AS (SELECT COUNT(PurchaseId) AS PurchaseCount,
               EmployeeId
        FROM dbo.PR_Purchase
            CROSS JOIN prm
        WHERE PR_Purchase.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND (PR_Purchase.Accepted = 1)
              AND (PR_Purchase.ApplayingStartDate BETWEEN prm.RangeFrom AND prm.RangeTo)
        GROUP BY EmployeeId),
         bouns
    AS (SELECT COUNT(EmployeeBonusId) AS BounsCount,
               EmployeeId
        FROM dbo.PR_EmployeeBonus
            CROSS JOIN prm
        WHERE PR_EmployeeBonus.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND (PR_EmployeeBonus.BonusDate BETWEEN prm.RangeFrom AND prm.RangeTo)
        GROUP BY EmployeeId),
         vacation
    AS (SELECT COUNT(VacationId) AS VacationCount,
               EmployeeId
        FROM dbo.PR_Vacations
            CROSS JOIN prm
        WHERE PR_Vacations.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND HrApproved = 1
              AND ManagerApproved = 1
              AND (PR_Vacations.DateFrom BETWEEN prm.RangeFrom AND prm.RangeTo)
        GROUP BY EmployeeId),
         penality
    AS (SELECT COUNT(PenaltyId) AS PenalityCount,
               EmployeeId
        FROM dbo.PR_Penalty
            CROSS JOIN prm
        WHERE PR_Penalty.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
              AND PR_Penalty.Confirmed = 1
              AND (PR_Penalty.PenaltyDate BETWEEN prm.RangeFrom AND prm.RangeTo)
        GROUP BY EmployeeId),
         vacationBalance
    AS (SELECT EmployeeId,
               SUM(VacationBalance) AS VacationBalance
        FROM dbo.PR_EmployeeVacationStatisticsReport(@EmployeeIds, @ToDate)
        GROUP BY EmployeeId),
         stats
    AS (SELECT PR_Employee.EmployeeId,
               PR_Employee.EmployeeName AS EmployeeNameSecondLanguage,
               EmployeeArabicName AS EmployeeName,
               ISNULL(purches.PurchaseCount, 0) AS PurchaseCount,
               ISNULL(vacation.VacationCount, 0) AS VacationCount,
               ISNULL(bouns.BounsCount, 0) AS BounsCount,
               ISNULL(advance.AdvanceCount, 0) AS AdvanceCount,
               ISNULL(penality.PenalityCount, 0) AS PenalityCount
        FROM dbo.PR_Employee
            LEFT JOIN advance
                ON advance.EmployeeId = PR_Employee.EmployeeId
            LEFT JOIN purches
                ON purches.EmployeeId = PR_Employee.EmployeeId
            LEFT JOIN bouns
                ON bouns.EmployeeId = PR_Employee.EmployeeId
            LEFT JOIN vacation
                ON vacation.EmployeeId = PR_Employee.EmployeeId
            LEFT JOIN penality
                ON penality.EmployeeId = PR_Employee.EmployeeId
        WHERE PR_Employee.EmployeeId IN
              (
                  SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeIds)
              )
        GROUP BY PR_Employee.EmployeeId,
                 EmployeeName,
                 EmployeeArabicName,
                 purches.PurchaseCount,
                 vacation.VacationCount,
                 bouns.BounsCount,
                 advance.AdvanceCount,
                 penality.PenalityCount)
    SELECT ROW_NUMBER() OVER (ORDER BY stats.EmployeeId) AS RowNo,
           stats.EmployeeId,
           stats.EmployeeNameSecondLanguage,
           stats.EmployeeName,
           stats.PurchaseCount,
           stats.VacationCount,
           stats.BounsCount,
           stats.AdvanceCount,
           stats.PenalityCount,
           ISNULL(vacationBalance.VacationBalance, 0) AS VacationBalance
    FROM stats
        LEFT JOIN vacationBalance
            ON vacationBalance.EmployeeId = stats.EmployeeId
);
GO
