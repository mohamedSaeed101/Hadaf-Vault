-- CR 125299 P2 parity, Employee Statistics: legacy procs Pr_GetEmployee_Statistics +
-- Pr_GetEmployee_Vacation_Statistics (+ rptEmployeeStatistics C# rollup) vs TVFs
-- PR_EmployeeStatisticsReport / PR_EmployeeVacationStatisticsReport. Read-only: temp tables only.
-- Legacy gets the dates as the C# constructor normalises them (from 00:00:00, to 23:59:59.997);
-- the TVFs get the raw dates (some with a time part) and must normalise themselves.
SET NOCOUNT ON;

DECLARE @Ids NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(MAX)), ',') FROM dbo.PR_Employee WHERE EndWork = 0);

DECLARE @Ranges TABLE (Id INT, Label NVARCHAR(60), RawFrom DATETIME, RawTo DATETIME);
INSERT @Ranges VALUES
 (1, N'wide 2000-01-01..2026-12-31',            '20000101',             '20261231'),
 (2, N'narrow 2026-05-01..2026-06-30',          '20260501',             '20260630'),
 (3, N'raw times 2026-06-30 15:00..09-21 08:00', '20260630 15:00',       '20260921 08:00'),
 (4, N'narrow 2026-09-21..2026-09-28',          '20260921',             '20260928'),
 (5, N'before data 2024-01-01..2024-12-31',     '20240101',             '20241231');

CREATE TABLE #Res (RangeId INT, Label NVARCHAR(60), LegacyMaster INT, TvfMaster INT, MasterLegacyNotTvf INT, MasterTvfNotLegacy INT,
                   LegacyDetail INT, TvfDetail INT, DetailLegacyNotTvf INT, DetailTvfNotLegacy INT, SplitTypeRows INT,
                   TvfRowNoDistinct INT, SumVacationBalance NUMERIC(38, 9), SumCounts INT);

CREATE TABLE #M (EmployeeId INT, EmployeeNameSecondLanguage NVARCHAR(1000), EmployeeName NVARCHAR(1000),
                 PurchaseCount INT, VacationCount INT, BounsCount INT, AdvanceCount INT, PenalityCount INT);
CREATE TABLE #D (EmployeeId INT, AnnualVacationTypeId INT, AnnualVacationTypeNameSecondLanguage NVARCHAR(100),
                 AnnualVacationTypeName NVARCHAR(100), NumberOfDays NUMERIC(38, 9), VacationDays MONEY, VacationBalance NUMERIC(38, 9));

DECLARE @i INT = 1, @Label NVARCHAR(60), @RawFrom DATETIME, @RawTo DATETIME, @From DATETIME, @To DATETIME;
WHILE @i <= (SELECT MAX(Id) FROM @Ranges)
BEGIN
    SELECT @Label = Label, @RawFrom = RawFrom, @RawTo = RawTo FROM @Ranges WHERE Id = @i;
    -- rptEmployeeStatistics(string, DateTime, DateTime) constructor
    SET @From = CAST(CAST(@RawFrom AS DATE) AS DATETIME);
    SET @To = DATEADD(MILLISECOND, 997, DATEADD(SECOND, 59, DATEADD(MINUTE, 59, DATEADD(HOUR, 23, CAST(CAST(@RawTo AS DATE) AS DATETIME)))));

    TRUNCATE TABLE #M; TRUNCATE TABLE #D;
    INSERT #M EXEC dbo.Pr_GetEmployee_Statistics @employeeIds = @Ids, @dateFrom = @From, @dateTo = @To;
    INSERT #D EXEC dbo.Pr_GetEmployee_Vacation_Statistics @employeeIds = @Ids, @dateTo = @To;

    -- C# BeforePrint: row.VacationBalance = child rows (relation on EmployeeId) .Sum(VacationBalance)
    SELECT m.*, ISNULL((SELECT SUM(d.VacationBalance) FROM #D d WHERE d.EmployeeId = m.EmployeeId), 0) AS VacationBalance
    INTO #LM FROM #M m;
    SELECT EmployeeId, EmployeeNameSecondLanguage, EmployeeName, PurchaseCount, VacationCount, BounsCount, AdvanceCount,
           PenalityCount, VacationBalance
    INTO #TM FROM dbo.PR_EmployeeStatisticsReport(@Ids, @RawFrom, @RawTo);

    -- detail compared with multiplicity (the GROUP BY VacationDays quirk can repeat a row)
    SELECT *, ROW_NUMBER() OVER (PARTITION BY EmployeeId, AnnualVacationTypeId, AnnualVacationTypeNameSecondLanguage,
               AnnualVacationTypeName, NumberOfDays, VacationDays, VacationBalance ORDER BY (SELECT 0)) AS Dup
    INTO #LD FROM #D;
    SELECT EmployeeId, AnnualVacationTypeId, AnnualVacationTypeNameSecondLanguage, AnnualVacationTypeName, NumberOfDays,
           VacationDays, VacationBalance,
           ROW_NUMBER() OVER (PARTITION BY EmployeeId, AnnualVacationTypeId, AnnualVacationTypeNameSecondLanguage,
               AnnualVacationTypeName, NumberOfDays, VacationDays, VacationBalance ORDER BY (SELECT 0)) AS Dup
    INTO #TD FROM dbo.PR_EmployeeVacationStatisticsReport(@Ids, @RawTo);

    INSERT #Res
    SELECT @i, @Label,
           (SELECT COUNT(*) FROM #LM), (SELECT COUNT(*) FROM #TM),
           (SELECT COUNT(*) FROM (SELECT * FROM #LM EXCEPT SELECT * FROM #TM) x),
           (SELECT COUNT(*) FROM (SELECT * FROM #TM EXCEPT SELECT * FROM #LM) x),
           (SELECT COUNT(*) FROM #LD), (SELECT COUNT(*) FROM #TD),
           (SELECT COUNT(*) FROM (SELECT * FROM #LD EXCEPT SELECT * FROM #TD) x),
           (SELECT COUNT(*) FROM (SELECT * FROM #TD EXCEPT SELECT * FROM #LD) x),
           (SELECT COUNT(*) FROM (SELECT EmployeeId, AnnualVacationTypeId FROM #D GROUP BY EmployeeId, AnnualVacationTypeId HAVING COUNT(*) > 1) x),
           (SELECT COUNT(DISTINCT RowNo) FROM dbo.PR_EmployeeVacationStatisticsReport(@Ids, @RawTo)),
           (SELECT SUM(VacationBalance) FROM #TM),
           (SELECT SUM(PurchaseCount + VacationCount + BounsCount + AdvanceCount + PenalityCount) FROM #TM);

    DROP TABLE #LM, #TM, #LD, #TD;
    SET @i += 1;
END;

SELECT (SELECT COUNT(*) FROM dbo.PR_Employee WHERE EndWork = 0) AS ActiveEmployees;
SELECT * FROM #Res ORDER BY RangeId;
-- master RowNo must be unique and dense too
SELECT COUNT(*) AS TvfMasterRows, COUNT(DISTINCT RowNo) AS DistinctRowNo, MIN(RowNo) AS MinRowNo, MAX(RowNo) AS MaxRowNo
FROM dbo.PR_EmployeeStatisticsReport(@Ids, '20000101', '20261231');
