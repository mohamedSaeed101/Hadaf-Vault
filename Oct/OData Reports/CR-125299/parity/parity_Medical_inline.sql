-- Inline variant of parity_Medical.sql: the TVF body (dbo\Functions\PR_EmployeesMedicalInsuranceReport.sql at HEAD) is pasted
-- in place of the function call, so it runs read-only on a tenant without creating the function (ERP_MainDB-Ali).
-- CR-125299 parity: legacy dsEmployeeMedicalInsurance.xsd (Employees + PR_MedicalInsurance, joined on the
-- dataset relation EmployeeId = employeeId) with the card filter rptEmployeesMedicalInsurance.Detail_BeforePrint
-- applied (controller map: 0 -> null = all, 1 -> true, 2 -> false, other -> true) vs dbo.PR_EmployeesMedicalInsuranceReport.
-- Serial/RowNo are compared separately: legacy Serial counted every fetched line before the card filter
-- (gaps when rows are hidden); the TVF numbers the filtered rows 1..n (decision D2).
SET NOCOUNT ON;

DECLARE @cases TABLE (CaseName NVARCHAR(50), LegacyIds NVARCHAR(MAX), TvfIds NVARCHAR(MAX), CardReceive INT);
INSERT @cases VALUES
 (N'all NULL ids, card 0', NULL, NULL, 0),
 (N'all NULL ids, card 1', NULL, NULL, 1),
 (N'all NULL ids, card 2', NULL, NULL, 2),
 (N'all empty ids, card 0', NULL, N'', 0),
 (N'all, card 3 (default)', NULL, NULL, 3),
 (N'ids 31,30,17, card 0', N'31,30,17', N'31,30,17', 0),
 (N'ids 31,30,17, card 1', N'31,30,17', N'31,30,17', 1),
 (N'ids 31,30,17, card 2', N'31,30,17', N'31,30,17', 2);

WITH legacy AS
(
    SELECT c.CaseName, e.EmployeeId, e.EmployeeName, e.EmployeeNumber, e.DepartmentName, e.BranchName, e.JobName,
           m.MedicalInsuranceId, m.MedicalInsuranceType, m.Name, m.Age, m.InsuranceAmount, m.RelativeRelation,
           m.CardRecieved, m.InsurancePercentage, m.ChildId, m.InsuranceCompanyName, m.InsuranceEndDate, m.CardNumber
    FROM @cases c
    CROSS APPLY
    (
        SELECT  PR_Employee.* ,
                PR_Department.DepartmentName ,
                PR_Branch.BranchName ,
                PR_Job.JobName ,
                PR_Projects.ProjectName
        FROM    PR_Employee
                INNER JOIN PR_Department ON PR_Employee.DepartmentId = PR_Department.DepartmentId
                LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
                LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
                LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        WHERE   ( c.LegacyIds IS NULL
                  OR EmployeeId IN ( SELECT *
                                     FROM   dbo.Acc_ConvertIntListToTable(c.LegacyIds) )
                )
    ) e
    INNER JOIN
    (
        SELECT  PR_MedicalInsurance.MedicalInsuranceId ,
                PR_MedicalInsurance.MedicalInsuranceType ,
                PR_MedicalInsurance.Name ,
                PR_MedicalInsurance.Age ,
                PR_MedicalInsurance.InsuranceAmount ,
                PR_MedicalInsurance.RelativeRelation ,
                PR_MedicalInsurance.CardRecieved ,
                PR_MedicalInsurance.InsurancePercentage ,
                PR_MedicalInsurance.employeeId ,
                PR_MedicalInsurance.ChildId ,
                PR_MedicalInsurance.InsuranceCompanyName ,
                PR_MedicalInsurance.InsuranceEndDate ,
                PR_MedicalInsurance.CardNumber
        FROM    PR_MedicalInsurance
                INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_MedicalInsurance.employeeId
        WHERE   ( InsuranceEndDate IS NULL
                  OR InsuranceEndDate > GETDATE()
                )
    ) m ON m.employeeId = e.EmployeeId
    CROSS APPLY (SELECT CASE c.CardReceive WHEN 0 THEN NULL WHEN 2 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS CardFilter) f
    WHERE f.CardFilter IS NULL OR m.CardRecieved = f.CardFilter
),
tvf AS
(
    SELECT c.CaseName, t.EmployeeId, t.EmployeeName, t.EmployeeNumber, t.DepartmentName, t.BranchName, t.JobName,
           t.MedicalInsuranceId, t.MedicalInsuranceType, t.Name, t.Age, t.InsuranceAmount, t.RelativeRelation,
           t.CardRecieved, t.InsurancePercentage, t.ChildId, t.InsuranceCompanyName, t.InsuranceEndDate, t.CardNumber
    FROM @cases c
    CROSS APPLY (
    SELECT ROW_NUMBER() OVER (ORDER BY pe.EmployeeId, mi.MedicalInsuranceId) AS RowNo,
           CAST(ROW_NUMBER() OVER (ORDER BY pe.EmployeeId, mi.MedicalInsuranceId) AS INT) AS Serial,
           pe.EmployeeId,
           pe.EmployeeName,
           pe.EmployeeNumber,
           pd.DepartmentName,
           pb.BranchName,
           pj.JobName,
           mi.MedicalInsuranceId,
           mi.MedicalInsuranceType,
           mi.Name,
           mi.Age,
           mi.InsuranceAmount,
           mi.RelativeRelation,
           mi.CardRecieved,
           mi.InsurancePercentage,
           mi.ChildId,
           mi.InsuranceCompanyName,
           mi.InsuranceEndDate,
           mi.CardNumber
    FROM dbo.PR_MedicalInsurance mi
        INNER JOIN dbo.PR_Employee pe
            ON pe.EmployeeId = mi.employeeId
        INNER JOIN dbo.PR_Department pd
            ON pd.DepartmentId = pe.DepartmentId
        LEFT JOIN dbo.PR_Branch pb
            ON pb.BranchId = pe.BranchId
        LEFT JOIN dbo.PR_Job pj
            ON pj.JobId = pe.JobId
    WHERE (
              mi.InsuranceEndDate IS NULL
              OR mi.InsuranceEndDate > GETDATE()
          )
          AND
          (
              ISNULL(c.CardReceive, 0) = 0
              OR mi.CardRecieved = CASE
                                       WHEN c.CardReceive = 2 THEN 0
                                       ELSE 1
                                   END
          )
          AND
          (
              ISNULL(c.TvfIds, '') = ''
              OR pe.EmployeeId IN
                 (
                     SELECT number FROM dbo.Acc_ConvertIntListToTable(c.TvfIds)
                 )
          )
) t
),
serialCheck AS
(
    SELECT c.CaseName, COUNT(*) AS BadSerial
    FROM @cases c
    CROSS APPLY (
    SELECT ROW_NUMBER() OVER (ORDER BY pe.EmployeeId, mi.MedicalInsuranceId) AS RowNo,
           CAST(ROW_NUMBER() OVER (ORDER BY pe.EmployeeId, mi.MedicalInsuranceId) AS INT) AS Serial,
           pe.EmployeeId,
           pe.EmployeeName,
           pe.EmployeeNumber,
           pd.DepartmentName,
           pb.BranchName,
           pj.JobName,
           mi.MedicalInsuranceId,
           mi.MedicalInsuranceType,
           mi.Name,
           mi.Age,
           mi.InsuranceAmount,
           mi.RelativeRelation,
           mi.CardRecieved,
           mi.InsurancePercentage,
           mi.ChildId,
           mi.InsuranceCompanyName,
           mi.InsuranceEndDate,
           mi.CardNumber
    FROM dbo.PR_MedicalInsurance mi
        INNER JOIN dbo.PR_Employee pe
            ON pe.EmployeeId = mi.employeeId
        INNER JOIN dbo.PR_Department pd
            ON pd.DepartmentId = pe.DepartmentId
        LEFT JOIN dbo.PR_Branch pb
            ON pb.BranchId = pe.BranchId
        LEFT JOIN dbo.PR_Job pj
            ON pj.JobId = pe.JobId
    WHERE (
              mi.InsuranceEndDate IS NULL
              OR mi.InsuranceEndDate > GETDATE()
          )
          AND
          (
              ISNULL(c.CardReceive, 0) = 0
              OR mi.CardRecieved = CASE
                                       WHEN c.CardReceive = 2 THEN 0
                                       ELSE 1
                                   END
          )
          AND
          (
              ISNULL(c.TvfIds, '') = ''
              OR pe.EmployeeId IN
                 (
                     SELECT number FROM dbo.Acc_ConvertIntListToTable(c.TvfIds)
                 )
          )
) t
    CROSS APPLY (SELECT ROW_NUMBER() OVER (ORDER BY t2.EmployeeId, t2.MedicalInsuranceId) AS Expected, t2.MedicalInsuranceId
                 FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY pe.EmployeeId, mi.MedicalInsuranceId) AS RowNo,
           CAST(ROW_NUMBER() OVER (ORDER BY pe.EmployeeId, mi.MedicalInsuranceId) AS INT) AS Serial,
           pe.EmployeeId,
           pe.EmployeeName,
           pe.EmployeeNumber,
           pd.DepartmentName,
           pb.BranchName,
           pj.JobName,
           mi.MedicalInsuranceId,
           mi.MedicalInsuranceType,
           mi.Name,
           mi.Age,
           mi.InsuranceAmount,
           mi.RelativeRelation,
           mi.CardRecieved,
           mi.InsurancePercentage,
           mi.ChildId,
           mi.InsuranceCompanyName,
           mi.InsuranceEndDate,
           mi.CardNumber
    FROM dbo.PR_MedicalInsurance mi
        INNER JOIN dbo.PR_Employee pe
            ON pe.EmployeeId = mi.employeeId
        INNER JOIN dbo.PR_Department pd
            ON pd.DepartmentId = pe.DepartmentId
        LEFT JOIN dbo.PR_Branch pb
            ON pb.BranchId = pe.BranchId
        LEFT JOIN dbo.PR_Job pj
            ON pj.JobId = pe.JobId
    WHERE (
              mi.InsuranceEndDate IS NULL
              OR mi.InsuranceEndDate > GETDATE()
          )
          AND
          (
              ISNULL(c.CardReceive, 0) = 0
              OR mi.CardRecieved = CASE
                                       WHEN c.CardReceive = 2 THEN 0
                                       ELSE 1
                                   END
          )
          AND
          (
              ISNULL(c.TvfIds, '') = ''
              OR pe.EmployeeId IN
                 (
                     SELECT number FROM dbo.Acc_ConvertIntListToTable(c.TvfIds)
                 )
          )
) t2) x
    WHERE x.MedicalInsuranceId = t.MedicalInsuranceId AND (t.Serial <> x.Expected OR t.RowNo <> x.Expected)
    GROUP BY c.CaseName
),
l_minus_t AS (SELECT * FROM legacy EXCEPT SELECT * FROM tvf),
t_minus_l AS (SELECT * FROM tvf EXCEPT SELECT * FROM legacy)
SELECT c.CaseName, c.CardReceive,
       (SELECT COUNT(*) FROM legacy x WHERE x.CaseName = c.CaseName) AS LegacyRows,
       (SELECT COUNT(*) FROM tvf x WHERE x.CaseName = c.CaseName) AS TvfRows,
       (SELECT COUNT(*) FROM l_minus_t x WHERE x.CaseName = c.CaseName) AS LegacyNotInTvf,
       (SELECT COUNT(*) FROM t_minus_l x WHERE x.CaseName = c.CaseName) AS TvfNotInLegacy,
       ISNULL((SELECT BadSerial FROM serialCheck x WHERE x.CaseName = c.CaseName), 0) AS BadSerial
FROM @cases c;

SELECT COUNT(*) AS MedicalRowsTotal,
       SUM(CASE WHEN InsuranceEndDate IS NULL OR InsuranceEndDate > GETDATE() THEN 1 ELSE 0 END) AS MedicalRowsActive
FROM dbo.PR_MedicalInsurance;
