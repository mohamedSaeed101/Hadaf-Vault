-- CR-125299 parity: legacy dsEmployeeSaveRpt.xsd query (verbatim, params from each case) vs dbo.PR_EmployeeSaveReport.
-- Pass = LegacyRows = TvfRows and both EXCEPT counts 0 on every case.
SET NOCOUNT ON;
DECLARE @maxLvl INT = (SELECT MAX(EmployeeSecurityLevel) FROM dbo.PR_Employee);

DECLARE @cases TABLE (CaseName NVARCHAR(50), LegacyIds NVARCHAR(MAX), TvfIds NVARCHAR(MAX), Lvl INT, IsArabic BIT);
INSERT @cases VALUES
 (N'all NULL ids, max lvl, ar', NULL, NULL, @maxLvl, 1),
 (N'all NULL ids, max lvl, en', NULL, NULL, @maxLvl, 0),
 (N'all empty ids, max lvl, ar', NULL, N'', @maxLvl, 1),
 (N'all empty ids, max lvl, en', NULL, N'', @maxLvl, 0),
 (N'all, lvl 3, ar', NULL, NULL, 3, 1),
 (N'all, lvl 3, en', NULL, NULL, 3, 0),
 (N'all, lvl 1, en', NULL, NULL, 1, 0),
 (N'ids 31,30,17, max lvl, ar', N'31,30,17', N'31,30,17', @maxLvl, 1),
 (N'ids 31,30,17, max lvl, en', N'31,30,17', N'31,30,17', @maxLvl, 0),
 (N'ids 31,30,17, lvl 3, en', N'31,30,17', N'31,30,17', 3, 0);

WITH legacy AS
(
    SELECT c.CaseName, l.*
    FROM @cases c
    CROSS APPLY
    (
        SELECT ROW_NUMBER() OVER (ORDER BY EmployeeSaveId) AS RowNo
             , empSave.EmployeeSaveId AS SaveId
             , empSave.SaveName
             , empSave.Description AS SaveDescription
             , empSave.SaveDate
             , empSave.IsReturned
             , CASE
                   WHEN c.IsArabic = 1 THEN CASE
                           WHEN empSave.IsReturned = 1 THEN N'نعم'
                           ELSE N'لا'
                       END
                   ELSE CASE
                           WHEN empSave.IsReturned = 1 THEN 'Yes'
                           ELSE 'NO'
                       END
               END AS IsReturnedStr
             , empSave.ReturnedDate
             , emp.EmployeeId
             , emp.EmployeeName
             , emp.EmployeeNumber
             , mgr.EmployeeId AS ManagerId
             , mgr.EmployeeName AS ManagerName
        FROM Pr_EmployeeSave AS empSave
            LEFT JOIN PR_Employee AS emp ON empSave.EmployeeId = emp.EmployeeId
            LEFT JOIN PR_Employee AS mgr ON empSave.ManagerId = mgr.EmployeeId
        WHERE emp.EndWork = 0
            AND emp.EmployeeSecurityLevel <= c.Lvl
            AND (c.LegacyIds IS NULL OR emp.EmployeeId IN (SELECT number FROM Acc_ConvertIntListToTable(c.LegacyIds)))
    ) l
),
tvf AS
(
    SELECT c.CaseName, t.*
    FROM @cases c
    CROSS APPLY dbo.PR_EmployeeSaveReport(c.TvfIds, c.Lvl, c.IsArabic) t
),
l_minus_t AS (SELECT * FROM legacy EXCEPT SELECT * FROM tvf),
t_minus_l AS (SELECT * FROM tvf EXCEPT SELECT * FROM legacy)
SELECT c.CaseName, c.Lvl, c.IsArabic,
       (SELECT COUNT(*) FROM legacy x WHERE x.CaseName = c.CaseName) AS LegacyRows,
       (SELECT COUNT(*) FROM tvf x WHERE x.CaseName = c.CaseName) AS TvfRows,
       (SELECT COUNT(*) FROM l_minus_t x WHERE x.CaseName = c.CaseName) AS LegacyNotInTvf,
       (SELECT COUNT(*) FROM t_minus_l x WHERE x.CaseName = c.CaseName) AS TvfNotInLegacy
FROM @cases c;
