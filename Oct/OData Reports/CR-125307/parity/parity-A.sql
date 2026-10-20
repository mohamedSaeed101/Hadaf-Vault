-- CR 125307 phase 1 parity: prints 1-4, legacy .xsd SQL (+ C# step) vs new TVF body, run inline. Read-only: temp tables and variables only, nothing created on the tenant.
-- Generated: the TVF bodies below are copied verbatim from AccFlex_Cloud_Database dbo\Functions\PR_{EmployeeIncome,EmployeeAllowance,AllowanceSerial,EmployeeBonus}Print.sql.
-- Every header id on the tenant (plus -1) x IsArabic 0/1. Prints 1, 4 have data on UNP-Ali; 2, 3 have none there, so the same section also runs on ERP_MainDB-Ali (same server db-all).
SET NOCOUNT ON;
CREATE TABLE #N1 (RowNo BIGINT, EmployeeIncomeId INT, EmployeeId INT, EmployeeNumber NVARCHAR(4000), EmployeeName NVARCHAR(4000), JobName NVARCHAR(4000), DepartmentName NVARCHAR(4000), BranchName NVARCHAR(4000), DateOfWork DATETIME2, IncomeId INT, IncomeName NVARCHAR(4000), IncomeAmount DECIMAL(38,10), IncomeCurrency INT, CurrencyName NVARCHAR(4000), IncomeStartDate DATETIME2, SocialInsuranceRoleId INT, SocialInsuranceRole NVARCHAR(4000), EmployeeInsuranceAmount DECIMAL(38,10), Db SYSNAME NULL, HeaderId INT NULL, IsArabic BIT NULL);
CREATE TABLE #L1 (Db SYSNAME, HeaderId INT, IsArabic BIT, EmployeeIncomeId INT, EmployeeId INT, EmployeeNumber NVARCHAR(4000), EmployeeName NVARCHAR(4000), JobName NVARCHAR(4000), DepartmentName NVARCHAR(4000), BranchName NVARCHAR(4000), DateOfWork DATETIME2, IncomeId INT, IncomeName NVARCHAR(4000), IncomeAmount DECIMAL(38,10), IncomeCurrency INT, CurrencyName NVARCHAR(4000), IncomeStartDate DATETIME2, SocialInsuranceRoleId INT, SocialInsuranceRole NVARCHAR(4000), EmployeeInsuranceAmount DECIMAL(38,10));
CREATE TABLE #N2 (RowNo BIGINT, EmployeeAllowanceId INT, SerialNumber NVARCHAR(4000), TypeName NVARCHAR(4000), CurrencyName NVARCHAR(4000), AllowanceDate DATETIME2, CreatedBy NVARCHAR(4000), CreatedOn DATETIME2, ModifiedBy NVARCHAR(4000), LastModifiedOn DATETIME2, HistoricalSeverancePackage NVARCHAR(10), EmployeeAllowanceDetailId INT, DetailSerialNumber NVARCHAR(4000), EmployeeId INT, EmployeeName NVARCHAR(4000), WorkDate DATETIME2, DateOfWork DATETIME2, LastTransactionDate DATETIME2, AccrualAmount DECIMAL(38,10), AllowanceDays DECIMAL(38,10), AccumulatedBalance DECIMAL(38,10), ApprovedAmount DECIMAL(38,10), TransactionDate DATETIME2, Db SYSNAME NULL, HeaderId INT NULL, IsArabic BIT NULL);
CREATE TABLE #L2 (Db SYSNAME, HeaderId INT, IsArabic BIT, EmployeeAllowanceId INT, SerialNumber NVARCHAR(4000), TypeName NVARCHAR(4000), CurrencyName NVARCHAR(4000), AllowanceDate DATETIME2, CreatedBy NVARCHAR(4000), CreatedOn DATETIME2, ModifiedBy NVARCHAR(4000), LastModifiedOn DATETIME2, HistoricalSeverancePackage NVARCHAR(10), EmployeeAllowanceDetailId INT, DetailSerialNumber NVARCHAR(4000), EmployeeId INT, EmployeeName NVARCHAR(4000), WorkDate DATETIME2, DateOfWork DATETIME2, LastTransactionDate DATETIME2, AccrualAmount DECIMAL(38,10), AllowanceDays DECIMAL(38,10), AccumulatedBalance DECIMAL(38,10), ApprovedAmount DECIMAL(38,10), TransactionDate DATETIME2);
CREATE TABLE #N3 (RowNo BIGINT, AllowanceId INT, Serial INT, JournalSerial INT, AllowanceDate DATETIME2, CurrencyId INT, CurrencyFactor DECIMAL(38,10), CurrencyName NVARCHAR(4000), EmployeeId INT, EmployeeName NVARCHAR(4000), Description NVARCHAR(MAX), ReceivedToEmployee NVARCHAR(10), AllowanceDetailId INT, AllowanceTypeId INT, AllowanceTypeName NVARCHAR(4000), AllowanceValue DECIMAL(38,10), DetailDescription NVARCHAR(MAX), IsPercentage BIT, AllowancePercentage DECIMAL(38,10), Incomes NVARCHAR(MAX), Db SYSNAME NULL, HeaderId INT NULL, IsArabic BIT NULL);
CREATE TABLE #L3 (Db SYSNAME, HeaderId INT, IsArabic BIT, AllowanceId INT, Serial INT, JournalSerial INT, AllowanceDate DATETIME2, CurrencyId INT, CurrencyFactor DECIMAL(38,10), CurrencyName NVARCHAR(4000), EmployeeId INT, EmployeeName NVARCHAR(4000), Description NVARCHAR(MAX), ReceivedToEmployee NVARCHAR(10), AllowanceDetailId INT, AllowanceTypeId INT, AllowanceTypeName NVARCHAR(4000), AllowanceValue DECIMAL(38,10), DetailDescription NVARCHAR(MAX), IsPercentage BIT, AllowancePercentage DECIMAL(38,10), Incomes NVARCHAR(MAX));
CREATE TABLE #N4 (RowNo BIGINT, EmployeeBonusId INT, SerialNumber NVARCHAR(4000), EmployeeId INT, EmployeeNumber NVARCHAR(4000), EmployeeName NVARCHAR(4000), BonusId INT, BonusName NVARCHAR(4000), BonusDate DATETIME2, BonusTypeName NVARCHAR(4000), BonusAmount DECIMAL(38,10), BonusCurrencyId INT, CurrencyName NVARCHAR(4000), Paid BIT, Db SYSNAME NULL, HeaderId INT NULL, IsArabic BIT NULL);
CREATE TABLE #L4 (Db SYSNAME, HeaderId INT, IsArabic BIT, EmployeeBonusId INT, SerialNumber NVARCHAR(4000), EmployeeId INT, EmployeeNumber NVARCHAR(4000), EmployeeName NVARCHAR(4000), BonusId INT, BonusName NVARCHAR(4000), BonusDate DATETIME2, BonusTypeName NVARCHAR(4000), BonusAmount DECIMAL(38,10), BonusCurrencyId INT, CurrencyName NVARCHAR(4000), Paid BIT);
CREATE TABLE #L2H (EmployeeAllowanceId INT, TypeName NVARCHAR(4000), CurrencyName NVARCHAR(4000), SerialNumber NVARCHAR(4000), AllowanceDate DATETIME2, CreatedBy NVARCHAR(4000), CreatedOn DATETIME2, ModifiedBy NVARCHAR(4000), LastModifiedOn DATETIME2, HistoricalSeverancePackage NVARCHAR(10));
CREATE TABLE #L2D (EmployeeAllowanceDetailId INT, EmployeeAllowanceId INT, SerialNumber NVARCHAR(4000), EmployeeName NVARCHAR(4000), WorkDate DATETIME2, AccrualAmount DECIMAL(38,10), AllowanceDays DECIMAL(38,10), ApprovedAmount DECIMAL(38,10), TransactionDate DATETIME2, LastTransactionDate DATETIME2, AccumulatedBalance DECIMAL(38,10), DateOfWork DATETIME2);
CREATE TABLE #Adj (Db SYSNAME, Print_ CHAR(2), RowsChanged INT);
GO
USE [UNP-Ali];
GO
SET NOCOUNT ON;
DECLARE @HeaderId INT, @IsArabic BIT, @empIds VARCHAR(1024), @EmployeeAllowanceId INT, @AllowanceId INT, @EmployeeBonusId INT;
DECLARE @Ids TABLE (Print_ CHAR(2), Id INT);
INSERT @Ids SELECT 'P1', EmployeeId FROM dbo.PR_Employee UNION SELECT 'P1', EmployeeId FROM dbo.PR_EmployeeIncome UNION SELECT 'P1', -1;
INSERT @Ids SELECT 'P2', EmployeeAllowanceId FROM dbo.PR_EmployeeAllowance UNION SELECT 'P2', -1;
INSERT @Ids SELECT 'P3', AllowanceId FROM dbo.PR_Allowance UNION SELECT 'P3', -1;
INSERT @Ids SELECT 'P4', EmployeeBonusId FROM dbo.PR_EmployeeBonus UNION SELECT 'P4', -1;

DECLARE @B1 NVARCHAR(MAX) = N'
    -- The INNER joins to Branch/Department/Job sit on the outer side of the RIGHT join, as in the
    -- legacy print: an employee missing one of them still prints the income rows with blank employee fields.
    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_EmployeeIncome.EmployeeIncomeId) AS RowNo
        , PR_EmployeeIncome.EmployeeIncomeId
        , PR_EmployeeIncome.EmployeeId
        , PR_Employee.EmployeeNumber
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Job.JobName
        , PR_Department.DepartmentName
        , PR_Branch.BranchName
        , PR_Employee.DateOfWork
        , PR_EmployeeIncome.IncomeId
        , PR_Income.IncomeName
        , PR_EmployeeIncome.IncomeAmount
        , PR_EmployeeIncome.IncomeCurrency
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_EmployeeIncome.IncomeStartDate
        , PR_EmployeeIncome.SocialInsuranceRoleId
        , PR_SocialInsurance.SocialInsuranceRole
        , PR_EmployeeIncome.EmployeeInsuranceAmount
    FROM dbo.PR_Branch
        INNER JOIN dbo.PR_Employee
            ON PR_Branch.BranchId = PR_Employee.BranchId
        INNER JOIN dbo.PR_Department
            ON PR_Employee.DepartmentId = PR_Department.DepartmentId
        INNER JOIN dbo.PR_Job
            ON PR_Employee.JobId = PR_Job.JobId
        RIGHT OUTER JOIN dbo.PR_EmployeeIncome
            LEFT OUTER JOIN dbo.PR_SocialInsurance
                ON PR_EmployeeIncome.SocialInsuranceRoleId = PR_SocialInsurance.SocialInsuranceRoleId
            ON PR_Employee.EmployeeId = PR_EmployeeIncome.EmployeeId
        LEFT OUTER JOIN dbo.PR_Income
            ON PR_EmployeeIncome.IncomeId = PR_Income.IncomeId
        LEFT JOIN dbo.Acc_Currency
            ON PR_EmployeeIncome.IncomeCurrency = Acc_Currency.CurrencyId
    WHERE PR_EmployeeIncome.EmployeeId = @HeaderId
        AND PR_EmployeeIncome.IncomeEndDate IS NULL
';
DECLARE @B2 NVARCHAR(MAX) = N'
    WITH EmployeeDetails AS
    (
        SELECT detail.EmployeeAllowanceDetailId
             , detail.EmployeeAllowanceId
             , detail.EmployeeId
             , detail.SerialNumber
             , detail.AccrualAmount
             , detail.AllowanceDays
             , detail.ApprovedAmount
             , detail.TransactionDate
             , PR_Employee.WorkDate
             , CASE
                   WHEN @IsArabic = 1 THEN
                       CASE
                           WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                           ELSE PR_Employee.EmployeeArabicName
                       END
                   ELSE PR_Employee.EmployeeName
               END AS EmployeeName
             , PR_Employee.DateOfWork
        FROM dbo.PR_EmployeeAllowanceDetail AS detail
            JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = detail.EmployeeId
        WHERE detail.EmployeeAllowanceId = @HeaderId
    ),
    LastTransactionDate AS
    (
        SELECT d.EmployeeId
             , MAX(h.AllowanceDate) AS LastTransactionDate
        FROM dbo.PR_EmployeeAllowanceDetail AS d
            JOIN dbo.PR_EmployeeAllowance AS h
                ON d.EmployeeAllowanceId = h.EmployeeAllowanceId
            CROSS JOIN (
                SELECT AllowanceDate, EmployeeAllowanceTypeId, CurrencyId
                FROM dbo.PR_EmployeeAllowance
                WHERE EmployeeAllowanceId = @HeaderId
            ) AS CurrentAllowance
        WHERE h.EmployeeAllowanceId <> @HeaderId
            AND h.AllowanceDate <= CurrentAllowance.AllowanceDate
            AND h.EmployeeAllowanceTypeId = CurrentAllowance.EmployeeAllowanceTypeId
            AND h.CurrencyId = CurrentAllowance.CurrencyId
        GROUP BY d.EmployeeId
    ),
    -- Legacy print sums every earlier allowance document of the employee, whatever its type or currency.
    AccumulatedBalances AS
    (
        SELECT currentAndPreviousAllowances.EmployeeId
             , SUM(currentAndPreviousAllowances.ApprovedAmount) AS AccumulatedBalance
        FROM dbo.PR_EmployeeAllowanceDetail AS currentAndPreviousAllowances
            INNER JOIN dbo.PR_EmployeeAllowance
                ON currentAndPreviousAllowances.EmployeeAllowanceId = PR_EmployeeAllowance.EmployeeAllowanceId
        WHERE PR_EmployeeAllowance.AllowanceDate <=
        (
            SELECT PR_EmployeeAllowance.AllowanceDate
            FROM dbo.PR_EmployeeAllowance
            WHERE PR_EmployeeAllowance.EmployeeAllowanceId = @HeaderId
        )
        GROUP BY currentAndPreviousAllowances.EmployeeId
    )
    SELECT
          ROW_NUMBER() OVER (ORDER BY e.EmployeeAllowanceDetailId) AS RowNo
        , PR_EmployeeAllowance.EmployeeAllowanceId
        , PR_EmployeeAllowance.SerialNumber
        , CASE WHEN @IsArabic = 1 THEN PR_EmployeeAllowanceType.TypeName ELSE PR_EmployeeAllowanceType.TypeNameSecondLanguage END AS TypeName
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_EmployeeAllowance.AllowanceDate
        , CreatedBy.UserName AS CreatedBy
        , PR_EmployeeAllowance.CreatedOn
        , ModifiedBy.UserName AS ModifiedBy
        , PR_EmployeeAllowance.LastModifiedOn
        , CASE WHEN PR_EmployeeAllowance.HistoricalSeverancePackage = 1 THEN NCHAR(10003) ELSE N''X'' END AS HistoricalSeverancePackage
        , e.EmployeeAllowanceDetailId
        , e.SerialNumber AS DetailSerialNumber
        , e.EmployeeId
        , e.EmployeeName
        , e.WorkDate
        , e.DateOfWork
        , ltd.LastTransactionDate
        , e.AccrualAmount
        , e.AllowanceDays
        , ab.AccumulatedBalance
        , e.ApprovedAmount
        , e.TransactionDate
    FROM dbo.PR_EmployeeAllowance
        JOIN dbo.PR_EmployeeAllowanceType
            ON PR_EmployeeAllowanceType.EmployeeAllowanceTypeId = PR_EmployeeAllowance.EmployeeAllowanceTypeId
        JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = PR_EmployeeAllowance.CurrencyId
        JOIN dbo.Acc_User AS CreatedBy
            ON CreatedBy.UserId = PR_EmployeeAllowance.CreatedById
        LEFT JOIN dbo.Acc_User AS ModifiedBy
            ON ModifiedBy.UserId = PR_EmployeeAllowance.LastModifiedById
        LEFT JOIN EmployeeDetails AS e
            ON e.EmployeeAllowanceId = PR_EmployeeAllowance.EmployeeAllowanceId
        LEFT JOIN LastTransactionDate AS ltd
            ON e.EmployeeId = ltd.EmployeeId
        LEFT JOIN AccumulatedBalances AS ab
            ON e.EmployeeId = ab.EmployeeId
    WHERE PR_EmployeeAllowance.EmployeeAllowanceId = @HeaderId
';
DECLARE @B3 NVARCHAR(MAX) = N'
    SELECT
          ROW_NUMBER() OVER (ORDER BY AllowanceDetails.AllowanceDetailId) AS RowNo
        , PR_Allowance.AllowanceId
        , PR_Allowance.Serial
        , PR_Allowance.JournalSerial
        , PR_Allowance.AllowanceDate
        , PR_Allowance.CurrencyId
        , PR_Allowance.CurrencyFactor
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_Allowance.EmployeeId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Allowance.Description
        , CASE WHEN PR_Allowance.IsReceivedToEmployee = 1 THEN NCHAR(10003) ELSE N'''' END AS ReceivedToEmployee
        , AllowanceDetails.AllowanceDetailId
        , AllowanceDetails.AllowanceTypeId
        , PR_AllowanceType.AllowanceTypeName
        , AllowanceDetails.AllowanceValue
        , AllowanceDetails.Description AS DetailDescription
        , AllowanceDetails.IsPercentage
        -- Stored as a whole percent; returned as a fraction (12.5 -> 0.125), the value the legacy print showed.
        , CASE
              WHEN AllowanceDetails.IsPercentage = 1 THEN AllowanceDetails.AllowancePercentage / 100
              ELSE AllowanceDetails.AllowancePercentage
          END AS AllowancePercentage
        , (
              SELECT STUFF(
                     (
                         SELECT '' - '' + PR_Income.IncomeName
                         FROM dbo.PR_AllowanceIncomeDetail
                             LEFT JOIN dbo.PR_Income
                                 ON PR_Income.IncomeId = PR_AllowanceIncomeDetail.IncomeId
                         WHERE PR_AllowanceIncomeDetail.AllowanceDetailId = AllowanceDetails.AllowanceDetailId
                         FOR XML PATH('''')
                     ), 1, 2, '''')
          ) AS Incomes
    FROM dbo.PR_Allowance
        INNER JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = PR_Allowance.EmployeeId
        INNER JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = PR_Allowance.CurrencyId
        LEFT JOIN dbo.PR_AllowanceDetails AS AllowanceDetails
            INNER JOIN dbo.PR_AllowanceType
                ON PR_AllowanceType.AllowanceTypeId = AllowanceDetails.AllowanceTypeId
            ON AllowanceDetails.AllowanceId = PR_Allowance.AllowanceId
    WHERE PR_Allowance.AllowanceId = @HeaderId
';
DECLARE @B4 NVARCHAR(MAX) = N'
    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_EmployeeBonus.EmployeeBonusId) AS RowNo
        , PR_EmployeeBonus.EmployeeBonusId
        , PR_EmployeeBonus.SerialNumber
        , PR_Employee.EmployeeId
        , PR_Employee.EmployeeNumber
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Bonus.BonusId
        , PR_Bonus.BonusName
        , PR_EmployeeBonus.BonusDate
        , CASE WHEN @IsArabic = 1 THEN PR_EmployeeBonusType.BonusTypeName ELSE PR_EmployeeBonusType.BonusTypeNameSecondLanguage END AS BonusTypeName
        , PR_EmployeeBonus.BonusAmount
        , PR_EmployeeBonus.BonusCurrencyId
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_EmployeeBonus.Paid
    FROM dbo.PR_EmployeeBonus
        INNER JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = PR_EmployeeBonus.EmployeeId
        INNER JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = PR_EmployeeBonus.BonusCurrencyId
        INNER JOIN dbo.PR_Bonus
            ON PR_Bonus.BonusId = PR_EmployeeBonus.BonusId
        LEFT JOIN dbo.PR_EmployeeBonusType
            ON PR_EmployeeBonusType.BonusTypeId = PR_EmployeeBonus.BonusTypeId
    WHERE PR_EmployeeBonus.EmployeeBonusId = @HeaderId
';
DECLARE @P NVARCHAR(100) = N'@HeaderId INT, @IsArabic BIT';
DECLARE @Print CHAR(2);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT i.Print_, i.Id, l.IsArabic FROM @Ids i CROSS JOIN (VALUES (CAST(0 AS BIT)), (CAST(1 AS BIT))) l (IsArabic);
OPEN c;
FETCH NEXT FROM c INTO @Print, @HeaderId, @IsArabic;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @empIds = CAST(@HeaderId AS VARCHAR(20)), @EmployeeAllowanceId = @HeaderId, @AllowanceId = @HeaderId, @EmployeeBonusId = @HeaderId;

    IF @Print = 'P1'
    BEGIN
        INSERT #N1 (RowNo, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount)
        EXEC sp_executesql @B1, @P, @HeaderId, @IsArabic;
        UPDATE #N1 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        -- legacy dsEmployeeFinance.xsd PR_Emp_Income, verbatim (trailing ';' dropped to use it as a derived table)
        INSERT #L1 (Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount)
        SELECT DB_NAME(), @HeaderId, @IsArabic, x.EmployeeIncomeId, x.EmployeeId, x.EmployeeNumber, x.EmployeeName, x.JobName, x.DepartmentName, x.BranchName, x.DateOfWork, x.IncomeId, x.IncomeName, x.IncomeAmount, x.IncomeCurrency, x.CurrencyName, x.IncomeStartDate, x.SocialInsuranceRoleId, x.SocialInsuranceRole, x.EmployeeInsuranceAmount
        FROM (
SELECT PR_EmployeeIncome.EmployeeIncomeId,
       PR_EmployeeIncome.EmployeeId,
       PR_EmployeeIncome.IncomeId,
       PR_EmployeeIncome.IncomeCurrency,
       PR_EmployeeIncome.IncomeAmount,
       PR_EmployeeIncome.IncomeStartDate,
       PR_EmployeeIncome.IncomeTaxRoleId,
       PR_EmployeeIncome.SocialInsuranceRoleId,
       PR_EmployeeIncome.EmployeeInsuranceAmount,
       PR_EmployeeIncome.CompanyInsuranceAmount,
       Acc_Currency.CurrencyName,
       PR_Income.IncomeName,
       PR_Income.Deduction,
       CASE
           WHEN @IsArabic = 1 THEN
               CASE
                   WHEN (LTRIM(RTRIM(PR_Employee.EmployeeArabicName))) = '' THEN
                       PR_Employee.EmployeeName
                   ELSE
                       PR_Employee.EmployeeArabicName
               END
           ELSE
               PR_Employee.EmployeeName
       END EmployeeName,
       PR_SocialInsurance.SocialInsuranceRole,
       PR_Department.DepartmentName,
       PR_Job.JobName,
       PR_Branch.BranchName,
       PR_Employee.DateOfWork,
       PR_Employee.EmployeeNumber,
       PR_Employee.IDNumber,
       ProjectName
FROM PR_Branch
    INNER JOIN PR_Employee
        ON PR_Branch.BranchId = PR_Employee.BranchId
    INNER JOIN PR_Department
        ON PR_Employee.DepartmentId = PR_Department.DepartmentId
    INNER JOIN PR_Job
        ON PR_Employee.JobId = PR_Job.JobId
    RIGHT OUTER JOIN PR_EmployeeIncome
        LEFT OUTER JOIN PR_SocialInsurance
            ON PR_EmployeeIncome.SocialInsuranceRoleId = PR_SocialInsurance.SocialInsuranceRoleId
        ON PR_Employee.EmployeeId = PR_EmployeeIncome.EmployeeId
    LEFT OUTER JOIN PR_Income
        ON PR_EmployeeIncome.IncomeId = PR_Income.IncomeId
    LEFT JOIN Acc_Currency
        ON PR_EmployeeIncome.IncomeCurrency = Acc_Currency.CurrencyId
    LEFT JOIN dbo.PR_Projects
        ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE (
          @empIds = 'All'
          OR
          (
              @empIds = 'AllInService'
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 0
                  )
          )
          OR
          (
              @empIds = 'AllTerminated'
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 1
                  )
          )
          OR
          (
              @empIds NOT IN ( 'All', 'AllInService', 'AllTerminated' )
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@empIds)
                  )
          )
      )
      AND (@IsArabic = @IsArabic)
      AND IncomeEndDate IS NULL
        ) AS x;
    END

    IF @Print = 'P2'
    BEGIN
        INSERT #N2 (RowNo, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate)
        EXEC sp_executesql @B2, @P, @HeaderId, @IsArabic;
        UPDATE #N2 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        TRUNCATE TABLE #L2H; TRUNCATE TABLE #L2D;
        -- legacy dsEmployeeAllowance.xsd FillEmployeeAllowance, verbatim
        INSERT #L2H
SELECT  PR_EmployeeAllowance.EmployeeAllowanceId ,
        ( CASE WHEN @IsArabic = 1
               THEN PR_EmployeeAllowanceType.TypeName
               ELSE PR_EmployeeAllowanceType.TypeNameSecondLanguage
          END ) AS TypeName ,
        ( CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic
               ELSE Acc_Currency.CurrencyName
          END ) AS CurrencyName ,
        PR_EmployeeAllowance.SerialNumber ,
        PR_EmployeeAllowance.AllowanceDate ,
        CreatedBy.UserName AS CreatedBy ,
        PR_EmployeeAllowance.CreatedOn ,
        ModifiedBy.UserName AS ModifiedBy ,
        PR_EmployeeAllowance.LastModifiedOn,
        CASE WHEN PR_EmployeeAllowance.HistoricalSeverancePackage = 1 THEN N'✓' ELSE N'X' END AS HistoricalSeverancePackage
FROM    dbo.PR_EmployeeAllowance
        JOIN dbo.PR_EmployeeAllowanceType ON PR_EmployeeAllowanceType.EmployeeAllowanceTypeId = PR_EmployeeAllowance.EmployeeAllowanceTypeId
        JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = PR_EmployeeAllowance.CurrencyId
        JOIN dbo.Acc_User AS CreatedBy ON CreatedBy.UserId = PR_EmployeeAllowance.CreatedById
        LEFT JOIN dbo.Acc_User AS ModifiedBy ON ModifiedBy.UserId = PR_EmployeeAllowance.LastModifiedById
WHERE   EmployeeAllowanceId = @EmployeeAllowanceId
        AND @IsArabic = @IsArabic;
        -- legacy dsEmployeeAllowance.xsd FillEmployeeAllowanceDetail, verbatim except the INSERT before the final SELECT
WITH EmployeeDetails
AS (SELECT detail.EmployeeAllowanceDetailId,
           detail.EmployeeAllowanceId,
           detail.EmployeeId,
           detail.SerialNumber,
           detail.AccrualAmount,
           detail.AllowanceDays,
           detail.ApprovedAmount,
           detail.TransactionDate,
           PR_Employee.WorkDate,
           CASE
               WHEN @IsArabic = 1 THEN
                   PR_Employee.EmployeeArabicName
               ELSE
                   PR_Employee.EmployeeName
           END AS EmployeeName,
           PR_Employee.DateOfWork
    FROM dbo.PR_EmployeeAllowanceDetail AS detail
        JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = detail.EmployeeId
    WHERE detail.EmployeeAllowanceId = @EmployeeAllowanceId),
     LastTransactionDate AS (
    SELECT
        d.EmployeeId,
        MAX(h.AllowanceDate) AS LastTransactionDate
    FROM dbo.PR_EmployeeAllowanceDetail AS d
        JOIN dbo.PR_EmployeeAllowance AS h
            ON d.EmployeeAllowanceId = h.EmployeeAllowanceId
        CROSS JOIN (
            SELECT AllowanceDate, EmployeeAllowanceTypeId, CurrencyId
            FROM dbo.PR_EmployeeAllowance
            WHERE EmployeeAllowanceId = @EmployeeAllowanceId
        ) AS CurrentAllowance
    WHERE h.EmployeeAllowanceId <> @EmployeeAllowanceId
      AND h.AllowanceDate <= CurrentAllowance.AllowanceDate
      AND h.EmployeeAllowanceTypeId = CurrentAllowance.EmployeeAllowanceTypeId
      AND h.CurrencyId = CurrentAllowance.CurrencyId
    GROUP BY d.EmployeeId
),
     AccumulatedBalances
AS (SELECT currentAndPreviousAllowances.EmployeeId,
           SUM(currentAndPreviousAllowances.ApprovedAmount) AS AccumulatedBalance
    FROM dbo.PR_EmployeeAllowanceDetail AS currentAndPreviousAllowances
        INNER JOIN dbo.PR_EmployeeAllowance
            ON currentAndPreviousAllowances.EmployeeAllowanceId = PR_EmployeeAllowance.EmployeeAllowanceId
    WHERE PR_EmployeeAllowance.AllowanceDate <=
    (
        SELECT PR_EmployeeAllowance.AllowanceDate
        FROM dbo.PR_EmployeeAllowance
        WHERE PR_EmployeeAllowance.EmployeeAllowanceId = @EmployeeAllowanceId
    )
    GROUP BY currentAndPreviousAllowances.EmployeeId)
INSERT #L2D
SELECT e.EmployeeAllowanceDetailId,
       e.EmployeeAllowanceId,
       e.SerialNumber,
       e.EmployeeName,
       e.WorkDate,
       e.AccrualAmount,
       e.AllowanceDays,
       e.ApprovedAmount,
       e.TransactionDate,
       ltd.LastTransactionDate,
       ab.AccumulatedBalance,
       e.DateOfWork
FROM EmployeeDetails e
    LEFT JOIN LastTransactionDate ltd
        ON e.EmployeeId = ltd.EmployeeId
    LEFT JOIN AccumulatedBalances ab
        ON e.EmployeeId = ab.EmployeeId
WHERE @IsArabic = @IsArabic;

        -- report relation EmployeeAllowance_EmployeeAllowanceDetail: header row, its detail rows under it
        INSERT #L2 (Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate)
        SELECT DB_NAME(), @HeaderId, @IsArabic, h.EmployeeAllowanceId, h.SerialNumber, h.TypeName, h.CurrencyName, h.AllowanceDate, h.CreatedBy, h.CreatedOn, h.ModifiedBy, h.LastModifiedOn, h.HistoricalSeverancePackage,
               d.EmployeeAllowanceDetailId, d.SerialNumber,
               (SELECT dd.EmployeeId FROM dbo.PR_EmployeeAllowanceDetail dd WHERE dd.EmployeeAllowanceDetailId = d.EmployeeAllowanceDetailId),
               d.EmployeeName, d.WorkDate, d.DateOfWork, d.LastTransactionDate, d.AccrualAmount, d.AllowanceDays, d.AccumulatedBalance, d.ApprovedAmount, d.TransactionDate
        FROM #L2H h LEFT JOIN #L2D d ON d.EmployeeAllowanceId = h.EmployeeAllowanceId;
    END

    IF @Print = 'P3'
    BEGIN
        INSERT #N3 (RowNo, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes)
        EXEC sp_executesql @B3, @P, @HeaderId, @IsArabic;
        UPDATE #N3 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        -- legacy dsAllowanceSerial.xsd Allowance and AllowanceDetails, verbatim; the C# step (currency rebind, % / 100) applied when flattening
        INSERT #L3
        SELECT DB_NAME(), @HeaderId, @IsArabic, h.AllowanceId, h.Serial, h.JournalSerial, h.AllowanceDate, h.CurrencyId, h.CurrencyFactor,
               CASE WHEN @IsArabic = 1 THEN h.CurrencyNameArabic ELSE h.CurrencyName END,
               h.EmployeeId, h.EmployeeName, h.Description, h.ReceivedToEmployee,
               d.AllowanceDetailId, d.AllowanceTypeId, d.AllowanceTypeName, d.AllowanceValue, d.Description, d.IsPercentage,
               CASE WHEN d.IsPercentage = 1 THEN d.AllowancePercentage / 100 ELSE d.AllowancePercentage END,
               d.Incomes
        FROM (
SELECT  PR_Allowance.* ,
         CASE WHEN @IsArabic = 1
                 THEN CASE WHEN ( LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) ) = ''
                           THEN PR_Employee.EmployeeName
                           ELSE PR_Employee.EmployeeArabicName
                      END
                 ELSE PR_Employee.EmployeeName
            END EmployeeName ,
		EmployeeArabicName,
        CurrencyName ,
        CurrencyNameArabic ,
        CASE WHEN IsReceivedToEmployee = 1 THEN N'✓'
             ELSE N''
        END AS ReceivedToEmployee
FROM    dbo.PR_Allowance
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Allowance.EmployeeId
        INNER JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = PR_Allowance.CurrencyId
WHERE   AllowanceId = @AllowanceId AND   (@IsArabic = @IsArabic)
        ) AS h
        LEFT JOIN (
SELECT AllowanceDetails.AllowanceDetailId,
       AllowanceDetails.AllowanceId,
       AllowanceDetails.AllowanceTypeId,
       AllowanceDetails.AllowanceValue,
       AllowanceDetails.Description,
       AllowanceDetails.IsPercentage,
       AllowanceDetails.AllowancePercentage,
       (
           SELECT STUFF(
                  (
                      SELECT ' - ' + PR_Income.IncomeName
                      FROM PR_AllowanceIncomeDetail
                          LEFT JOIN dbo.PR_Income
                              ON PR_Income.IncomeId = PR_AllowanceIncomeDetail.IncomeId
                      WHERE PR_AllowanceIncomeDetail.AllowanceDetailId = AllowanceDetails.AllowanceDetailId
                      FOR XML PATH('')
                  ),
                  1,
                  2,
                  ''
                       )
       ) AS Incomes,
       AllowanceTypeName
FROM dbo.PR_AllowanceDetails AS AllowanceDetails
    INNER JOIN dbo.PR_AllowanceType
        ON PR_AllowanceType.AllowanceTypeId = AllowanceDetails.AllowanceTypeId
WHERE AllowanceId = @AllowanceId
        ) AS d ON d.AllowanceId = h.AllowanceId;
    END

    IF @Print = 'P4'
    BEGIN
        INSERT #N4 (RowNo, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid)
        EXEC sp_executesql @B4, @P, @HeaderId, @IsArabic;
        UPDATE #N4 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        -- legacy dsEmployeeBonus.xsd (HR), verbatim; the C# step rebinds type and currency by language
        INSERT #L4
        SELECT DB_NAME(), @HeaderId, @IsArabic, x.EmployeeBonusId, x.SerialNumber, x.EmployeeId, x.EmployeeNumber, x.EmployeeName, x.BonusId, x.BonusName, x.BonusDate,
               CASE WHEN @IsArabic = 1 THEN x.BonusTypeName ELSE x.BonusTypeNameSecondLanguage END,
               x.BonusAmount, x.BonusCurrencyId,
               CASE WHEN @IsArabic = 1 THEN x.CurrencyNameArabic ELSE x.CurrencyName END,
               x.Paid
        FROM (
SELECT  EmployeeBonusId ,
        SerialNumber ,
        PR_Employee.EmployeeNumber ,
        PR_Employee.EmployeeName ,
        PR_Bonus.BonusName ,
        BonusDate ,
        PR_EmployeeBonusType.BonusTypeName ,
        PR_EmployeeBonusType.BonusTypeNameSecondLanguage ,
        BonusAmount ,
        Acc_Currency.CurrencyName ,
        Acc_Currency.CurrencyNameArabic ,
        Paid ,
        BounsTotalValue AS BonusTotalLocal ,
        PR_Bonus.BonusId ,
        PR_Employee.EmployeeId ,
        BonusCurrencyId ,
        PaidInSalaryMainId ,
        BounsTotalValue ,
        PR_EmployeeBonus.Description ,
        PR_Employee.IDNumber ,
        PR_Nationality.Nationality,managner.EmployeeName AS ManagnerName
FROM    dbo.PR_EmployeeBonus
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_EmployeeBonus.EmployeeId
        INNER JOIN dbo.Acc_Currency ON dbo.Acc_Currency.CurrencyId = PR_EmployeeBonus.BonusCurrencyId
        INNER JOIN PR_Bonus ON PR_Bonus.BonusId = PR_EmployeeBonus.BonusId
        LEFT JOIN dbo.PR_EmployeeBonusType ON PR_EmployeeBonusType.BonusTypeId = PR_EmployeeBonus.BonusTypeId
        LEFT JOIN dbo.PR_Nationality ON PR_Nationality.NationalityId = PR_Employee.NationalityId
		LEFT JOIN dbo.PR_Employee managner ON managner.EmployeeId = PR_Employee.ManagerId
WHERE   PR_EmployeeBonus.EmployeeBonusId = @EmployeeBonusId
        ) AS x;
    END

    FETCH NEXT FROM c INTO @Print, @HeaderId, @IsArabic;
END
CLOSE c; DEALLOCATE c;

-- D10 decisions applied to the legacy side (recorded in #Adj before the change):
-- P1 currency name and P4 employee name follow the print language; P2 detail employee name falls back to EmployeeName when the Arabic name is blank (D15).
INSERT #Adj SELECT DB_NAME(), 'P1', COUNT(*) FROM #L1 l JOIN dbo.Acc_Currency c ON c.CurrencyId = l.IncomeCurrency WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(l.CurrencyName, N'') <> c.CurrencyNameArabic;
UPDATE l SET CurrencyName = c.CurrencyNameArabic FROM #L1 l JOIN dbo.Acc_Currency c ON c.CurrencyId = l.IncomeCurrency WHERE l.Db = DB_NAME() AND l.IsArabic = 1;
INSERT #Adj SELECT DB_NAME(), 'P2', COUNT(*) FROM #L2 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') = N'';
UPDATE l SET EmployeeName = e.EmployeeName FROM #L2 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') = N'';
INSERT #Adj SELECT DB_NAME(), 'P4', COUNT(*) FROM #L4 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') <> N'' AND e.EmployeeArabicName <> l.EmployeeName;
UPDATE l SET EmployeeName = CASE WHEN ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') = N'' THEN e.EmployeeName ELSE e.EmployeeArabicName END FROM #L4 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1;
GO
USE [ERP_MainDB-Ali];
GO
SET NOCOUNT ON;
DECLARE @HeaderId INT, @IsArabic BIT, @empIds VARCHAR(1024), @EmployeeAllowanceId INT, @AllowanceId INT, @EmployeeBonusId INT;
DECLARE @Ids TABLE (Print_ CHAR(2), Id INT);
INSERT @Ids SELECT 'P1', EmployeeId FROM dbo.PR_Employee UNION SELECT 'P1', EmployeeId FROM dbo.PR_EmployeeIncome UNION SELECT 'P1', -1;
INSERT @Ids SELECT 'P2', EmployeeAllowanceId FROM dbo.PR_EmployeeAllowance UNION SELECT 'P2', -1;
INSERT @Ids SELECT 'P3', AllowanceId FROM dbo.PR_Allowance UNION SELECT 'P3', -1;
INSERT @Ids SELECT 'P4', EmployeeBonusId FROM dbo.PR_EmployeeBonus UNION SELECT 'P4', -1;

DECLARE @B1 NVARCHAR(MAX) = N'
    -- The INNER joins to Branch/Department/Job sit on the outer side of the RIGHT join, as in the
    -- legacy print: an employee missing one of them still prints the income rows with blank employee fields.
    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_EmployeeIncome.EmployeeIncomeId) AS RowNo
        , PR_EmployeeIncome.EmployeeIncomeId
        , PR_EmployeeIncome.EmployeeId
        , PR_Employee.EmployeeNumber
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Job.JobName
        , PR_Department.DepartmentName
        , PR_Branch.BranchName
        , PR_Employee.DateOfWork
        , PR_EmployeeIncome.IncomeId
        , PR_Income.IncomeName
        , PR_EmployeeIncome.IncomeAmount
        , PR_EmployeeIncome.IncomeCurrency
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_EmployeeIncome.IncomeStartDate
        , PR_EmployeeIncome.SocialInsuranceRoleId
        , PR_SocialInsurance.SocialInsuranceRole
        , PR_EmployeeIncome.EmployeeInsuranceAmount
    FROM dbo.PR_Branch
        INNER JOIN dbo.PR_Employee
            ON PR_Branch.BranchId = PR_Employee.BranchId
        INNER JOIN dbo.PR_Department
            ON PR_Employee.DepartmentId = PR_Department.DepartmentId
        INNER JOIN dbo.PR_Job
            ON PR_Employee.JobId = PR_Job.JobId
        RIGHT OUTER JOIN dbo.PR_EmployeeIncome
            LEFT OUTER JOIN dbo.PR_SocialInsurance
                ON PR_EmployeeIncome.SocialInsuranceRoleId = PR_SocialInsurance.SocialInsuranceRoleId
            ON PR_Employee.EmployeeId = PR_EmployeeIncome.EmployeeId
        LEFT OUTER JOIN dbo.PR_Income
            ON PR_EmployeeIncome.IncomeId = PR_Income.IncomeId
        LEFT JOIN dbo.Acc_Currency
            ON PR_EmployeeIncome.IncomeCurrency = Acc_Currency.CurrencyId
    WHERE PR_EmployeeIncome.EmployeeId = @HeaderId
        AND PR_EmployeeIncome.IncomeEndDate IS NULL
';
DECLARE @B2 NVARCHAR(MAX) = N'
    WITH EmployeeDetails AS
    (
        SELECT detail.EmployeeAllowanceDetailId
             , detail.EmployeeAllowanceId
             , detail.EmployeeId
             , detail.SerialNumber
             , detail.AccrualAmount
             , detail.AllowanceDays
             , detail.ApprovedAmount
             , detail.TransactionDate
             , PR_Employee.WorkDate
             , CASE
                   WHEN @IsArabic = 1 THEN
                       CASE
                           WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                           ELSE PR_Employee.EmployeeArabicName
                       END
                   ELSE PR_Employee.EmployeeName
               END AS EmployeeName
             , PR_Employee.DateOfWork
        FROM dbo.PR_EmployeeAllowanceDetail AS detail
            JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = detail.EmployeeId
        WHERE detail.EmployeeAllowanceId = @HeaderId
    ),
    LastTransactionDate AS
    (
        SELECT d.EmployeeId
             , MAX(h.AllowanceDate) AS LastTransactionDate
        FROM dbo.PR_EmployeeAllowanceDetail AS d
            JOIN dbo.PR_EmployeeAllowance AS h
                ON d.EmployeeAllowanceId = h.EmployeeAllowanceId
            CROSS JOIN (
                SELECT AllowanceDate, EmployeeAllowanceTypeId, CurrencyId
                FROM dbo.PR_EmployeeAllowance
                WHERE EmployeeAllowanceId = @HeaderId
            ) AS CurrentAllowance
        WHERE h.EmployeeAllowanceId <> @HeaderId
            AND h.AllowanceDate <= CurrentAllowance.AllowanceDate
            AND h.EmployeeAllowanceTypeId = CurrentAllowance.EmployeeAllowanceTypeId
            AND h.CurrencyId = CurrentAllowance.CurrencyId
        GROUP BY d.EmployeeId
    ),
    -- Legacy print sums every earlier allowance document of the employee, whatever its type or currency.
    AccumulatedBalances AS
    (
        SELECT currentAndPreviousAllowances.EmployeeId
             , SUM(currentAndPreviousAllowances.ApprovedAmount) AS AccumulatedBalance
        FROM dbo.PR_EmployeeAllowanceDetail AS currentAndPreviousAllowances
            INNER JOIN dbo.PR_EmployeeAllowance
                ON currentAndPreviousAllowances.EmployeeAllowanceId = PR_EmployeeAllowance.EmployeeAllowanceId
        WHERE PR_EmployeeAllowance.AllowanceDate <=
        (
            SELECT PR_EmployeeAllowance.AllowanceDate
            FROM dbo.PR_EmployeeAllowance
            WHERE PR_EmployeeAllowance.EmployeeAllowanceId = @HeaderId
        )
        GROUP BY currentAndPreviousAllowances.EmployeeId
    )
    SELECT
          ROW_NUMBER() OVER (ORDER BY e.EmployeeAllowanceDetailId) AS RowNo
        , PR_EmployeeAllowance.EmployeeAllowanceId
        , PR_EmployeeAllowance.SerialNumber
        , CASE WHEN @IsArabic = 1 THEN PR_EmployeeAllowanceType.TypeName ELSE PR_EmployeeAllowanceType.TypeNameSecondLanguage END AS TypeName
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_EmployeeAllowance.AllowanceDate
        , CreatedBy.UserName AS CreatedBy
        , PR_EmployeeAllowance.CreatedOn
        , ModifiedBy.UserName AS ModifiedBy
        , PR_EmployeeAllowance.LastModifiedOn
        , CASE WHEN PR_EmployeeAllowance.HistoricalSeverancePackage = 1 THEN NCHAR(10003) ELSE N''X'' END AS HistoricalSeverancePackage
        , e.EmployeeAllowanceDetailId
        , e.SerialNumber AS DetailSerialNumber
        , e.EmployeeId
        , e.EmployeeName
        , e.WorkDate
        , e.DateOfWork
        , ltd.LastTransactionDate
        , e.AccrualAmount
        , e.AllowanceDays
        , ab.AccumulatedBalance
        , e.ApprovedAmount
        , e.TransactionDate
    FROM dbo.PR_EmployeeAllowance
        JOIN dbo.PR_EmployeeAllowanceType
            ON PR_EmployeeAllowanceType.EmployeeAllowanceTypeId = PR_EmployeeAllowance.EmployeeAllowanceTypeId
        JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = PR_EmployeeAllowance.CurrencyId
        JOIN dbo.Acc_User AS CreatedBy
            ON CreatedBy.UserId = PR_EmployeeAllowance.CreatedById
        LEFT JOIN dbo.Acc_User AS ModifiedBy
            ON ModifiedBy.UserId = PR_EmployeeAllowance.LastModifiedById
        LEFT JOIN EmployeeDetails AS e
            ON e.EmployeeAllowanceId = PR_EmployeeAllowance.EmployeeAllowanceId
        LEFT JOIN LastTransactionDate AS ltd
            ON e.EmployeeId = ltd.EmployeeId
        LEFT JOIN AccumulatedBalances AS ab
            ON e.EmployeeId = ab.EmployeeId
    WHERE PR_EmployeeAllowance.EmployeeAllowanceId = @HeaderId
';
DECLARE @B3 NVARCHAR(MAX) = N'
    SELECT
          ROW_NUMBER() OVER (ORDER BY AllowanceDetails.AllowanceDetailId) AS RowNo
        , PR_Allowance.AllowanceId
        , PR_Allowance.Serial
        , PR_Allowance.JournalSerial
        , PR_Allowance.AllowanceDate
        , PR_Allowance.CurrencyId
        , PR_Allowance.CurrencyFactor
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_Allowance.EmployeeId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Allowance.Description
        , CASE WHEN PR_Allowance.IsReceivedToEmployee = 1 THEN NCHAR(10003) ELSE N'''' END AS ReceivedToEmployee
        , AllowanceDetails.AllowanceDetailId
        , AllowanceDetails.AllowanceTypeId
        , PR_AllowanceType.AllowanceTypeName
        , AllowanceDetails.AllowanceValue
        , AllowanceDetails.Description AS DetailDescription
        , AllowanceDetails.IsPercentage
        -- Stored as a whole percent; returned as a fraction (12.5 -> 0.125), the value the legacy print showed.
        , CASE
              WHEN AllowanceDetails.IsPercentage = 1 THEN AllowanceDetails.AllowancePercentage / 100
              ELSE AllowanceDetails.AllowancePercentage
          END AS AllowancePercentage
        , (
              SELECT STUFF(
                     (
                         SELECT '' - '' + PR_Income.IncomeName
                         FROM dbo.PR_AllowanceIncomeDetail
                             LEFT JOIN dbo.PR_Income
                                 ON PR_Income.IncomeId = PR_AllowanceIncomeDetail.IncomeId
                         WHERE PR_AllowanceIncomeDetail.AllowanceDetailId = AllowanceDetails.AllowanceDetailId
                         FOR XML PATH('''')
                     ), 1, 2, '''')
          ) AS Incomes
    FROM dbo.PR_Allowance
        INNER JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = PR_Allowance.EmployeeId
        INNER JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = PR_Allowance.CurrencyId
        LEFT JOIN dbo.PR_AllowanceDetails AS AllowanceDetails
            INNER JOIN dbo.PR_AllowanceType
                ON PR_AllowanceType.AllowanceTypeId = AllowanceDetails.AllowanceTypeId
            ON AllowanceDetails.AllowanceId = PR_Allowance.AllowanceId
    WHERE PR_Allowance.AllowanceId = @HeaderId
';
DECLARE @B4 NVARCHAR(MAX) = N'
    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_EmployeeBonus.EmployeeBonusId) AS RowNo
        , PR_EmployeeBonus.EmployeeBonusId
        , PR_EmployeeBonus.SerialNumber
        , PR_Employee.EmployeeId
        , PR_Employee.EmployeeNumber
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), N'''') = N'''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Bonus.BonusId
        , PR_Bonus.BonusName
        , PR_EmployeeBonus.BonusDate
        , CASE WHEN @IsArabic = 1 THEN PR_EmployeeBonusType.BonusTypeName ELSE PR_EmployeeBonusType.BonusTypeNameSecondLanguage END AS BonusTypeName
        , PR_EmployeeBonus.BonusAmount
        , PR_EmployeeBonus.BonusCurrencyId
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , PR_EmployeeBonus.Paid
    FROM dbo.PR_EmployeeBonus
        INNER JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = PR_EmployeeBonus.EmployeeId
        INNER JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = PR_EmployeeBonus.BonusCurrencyId
        INNER JOIN dbo.PR_Bonus
            ON PR_Bonus.BonusId = PR_EmployeeBonus.BonusId
        LEFT JOIN dbo.PR_EmployeeBonusType
            ON PR_EmployeeBonusType.BonusTypeId = PR_EmployeeBonus.BonusTypeId
    WHERE PR_EmployeeBonus.EmployeeBonusId = @HeaderId
';
DECLARE @P NVARCHAR(100) = N'@HeaderId INT, @IsArabic BIT';
DECLARE @Print CHAR(2);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT i.Print_, i.Id, l.IsArabic FROM @Ids i CROSS JOIN (VALUES (CAST(0 AS BIT)), (CAST(1 AS BIT))) l (IsArabic);
OPEN c;
FETCH NEXT FROM c INTO @Print, @HeaderId, @IsArabic;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @empIds = CAST(@HeaderId AS VARCHAR(20)), @EmployeeAllowanceId = @HeaderId, @AllowanceId = @HeaderId, @EmployeeBonusId = @HeaderId;

    IF @Print = 'P1'
    BEGIN
        INSERT #N1 (RowNo, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount)
        EXEC sp_executesql @B1, @P, @HeaderId, @IsArabic;
        UPDATE #N1 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        -- legacy dsEmployeeFinance.xsd PR_Emp_Income, verbatim (trailing ';' dropped to use it as a derived table)
        INSERT #L1 (Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount)
        SELECT DB_NAME(), @HeaderId, @IsArabic, x.EmployeeIncomeId, x.EmployeeId, x.EmployeeNumber, x.EmployeeName, x.JobName, x.DepartmentName, x.BranchName, x.DateOfWork, x.IncomeId, x.IncomeName, x.IncomeAmount, x.IncomeCurrency, x.CurrencyName, x.IncomeStartDate, x.SocialInsuranceRoleId, x.SocialInsuranceRole, x.EmployeeInsuranceAmount
        FROM (
SELECT PR_EmployeeIncome.EmployeeIncomeId,
       PR_EmployeeIncome.EmployeeId,
       PR_EmployeeIncome.IncomeId,
       PR_EmployeeIncome.IncomeCurrency,
       PR_EmployeeIncome.IncomeAmount,
       PR_EmployeeIncome.IncomeStartDate,
       PR_EmployeeIncome.IncomeTaxRoleId,
       PR_EmployeeIncome.SocialInsuranceRoleId,
       PR_EmployeeIncome.EmployeeInsuranceAmount,
       PR_EmployeeIncome.CompanyInsuranceAmount,
       Acc_Currency.CurrencyName,
       PR_Income.IncomeName,
       PR_Income.Deduction,
       CASE
           WHEN @IsArabic = 1 THEN
               CASE
                   WHEN (LTRIM(RTRIM(PR_Employee.EmployeeArabicName))) = '' THEN
                       PR_Employee.EmployeeName
                   ELSE
                       PR_Employee.EmployeeArabicName
               END
           ELSE
               PR_Employee.EmployeeName
       END EmployeeName,
       PR_SocialInsurance.SocialInsuranceRole,
       PR_Department.DepartmentName,
       PR_Job.JobName,
       PR_Branch.BranchName,
       PR_Employee.DateOfWork,
       PR_Employee.EmployeeNumber,
       PR_Employee.IDNumber,
       ProjectName
FROM PR_Branch
    INNER JOIN PR_Employee
        ON PR_Branch.BranchId = PR_Employee.BranchId
    INNER JOIN PR_Department
        ON PR_Employee.DepartmentId = PR_Department.DepartmentId
    INNER JOIN PR_Job
        ON PR_Employee.JobId = PR_Job.JobId
    RIGHT OUTER JOIN PR_EmployeeIncome
        LEFT OUTER JOIN PR_SocialInsurance
            ON PR_EmployeeIncome.SocialInsuranceRoleId = PR_SocialInsurance.SocialInsuranceRoleId
        ON PR_Employee.EmployeeId = PR_EmployeeIncome.EmployeeId
    LEFT OUTER JOIN PR_Income
        ON PR_EmployeeIncome.IncomeId = PR_Income.IncomeId
    LEFT JOIN Acc_Currency
        ON PR_EmployeeIncome.IncomeCurrency = Acc_Currency.CurrencyId
    LEFT JOIN dbo.PR_Projects
        ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE (
          @empIds = 'All'
          OR
          (
              @empIds = 'AllInService'
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 0
                  )
          )
          OR
          (
              @empIds = 'AllTerminated'
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT EmployeeId FROM dbo.PR_Employee WHERE EndWork = 1
                  )
          )
          OR
          (
              @empIds NOT IN ( 'All', 'AllInService', 'AllTerminated' )
              AND PR_EmployeeIncome.EmployeeId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@empIds)
                  )
          )
      )
      AND (@IsArabic = @IsArabic)
      AND IncomeEndDate IS NULL
        ) AS x;
    END

    IF @Print = 'P2'
    BEGIN
        INSERT #N2 (RowNo, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate)
        EXEC sp_executesql @B2, @P, @HeaderId, @IsArabic;
        UPDATE #N2 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        TRUNCATE TABLE #L2H; TRUNCATE TABLE #L2D;
        -- legacy dsEmployeeAllowance.xsd FillEmployeeAllowance, verbatim
        INSERT #L2H
SELECT  PR_EmployeeAllowance.EmployeeAllowanceId ,
        ( CASE WHEN @IsArabic = 1
               THEN PR_EmployeeAllowanceType.TypeName
               ELSE PR_EmployeeAllowanceType.TypeNameSecondLanguage
          END ) AS TypeName ,
        ( CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic
               ELSE Acc_Currency.CurrencyName
          END ) AS CurrencyName ,
        PR_EmployeeAllowance.SerialNumber ,
        PR_EmployeeAllowance.AllowanceDate ,
        CreatedBy.UserName AS CreatedBy ,
        PR_EmployeeAllowance.CreatedOn ,
        ModifiedBy.UserName AS ModifiedBy ,
        PR_EmployeeAllowance.LastModifiedOn,
        CASE WHEN PR_EmployeeAllowance.HistoricalSeverancePackage = 1 THEN N'✓' ELSE N'X' END AS HistoricalSeverancePackage
FROM    dbo.PR_EmployeeAllowance
        JOIN dbo.PR_EmployeeAllowanceType ON PR_EmployeeAllowanceType.EmployeeAllowanceTypeId = PR_EmployeeAllowance.EmployeeAllowanceTypeId
        JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = PR_EmployeeAllowance.CurrencyId
        JOIN dbo.Acc_User AS CreatedBy ON CreatedBy.UserId = PR_EmployeeAllowance.CreatedById
        LEFT JOIN dbo.Acc_User AS ModifiedBy ON ModifiedBy.UserId = PR_EmployeeAllowance.LastModifiedById
WHERE   EmployeeAllowanceId = @EmployeeAllowanceId
        AND @IsArabic = @IsArabic;
        -- legacy dsEmployeeAllowance.xsd FillEmployeeAllowanceDetail, verbatim except the INSERT before the final SELECT
WITH EmployeeDetails
AS (SELECT detail.EmployeeAllowanceDetailId,
           detail.EmployeeAllowanceId,
           detail.EmployeeId,
           detail.SerialNumber,
           detail.AccrualAmount,
           detail.AllowanceDays,
           detail.ApprovedAmount,
           detail.TransactionDate,
           PR_Employee.WorkDate,
           CASE
               WHEN @IsArabic = 1 THEN
                   PR_Employee.EmployeeArabicName
               ELSE
                   PR_Employee.EmployeeName
           END AS EmployeeName,
           PR_Employee.DateOfWork
    FROM dbo.PR_EmployeeAllowanceDetail AS detail
        JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = detail.EmployeeId
    WHERE detail.EmployeeAllowanceId = @EmployeeAllowanceId),
     LastTransactionDate AS (
    SELECT
        d.EmployeeId,
        MAX(h.AllowanceDate) AS LastTransactionDate
    FROM dbo.PR_EmployeeAllowanceDetail AS d
        JOIN dbo.PR_EmployeeAllowance AS h
            ON d.EmployeeAllowanceId = h.EmployeeAllowanceId
        CROSS JOIN (
            SELECT AllowanceDate, EmployeeAllowanceTypeId, CurrencyId
            FROM dbo.PR_EmployeeAllowance
            WHERE EmployeeAllowanceId = @EmployeeAllowanceId
        ) AS CurrentAllowance
    WHERE h.EmployeeAllowanceId <> @EmployeeAllowanceId
      AND h.AllowanceDate <= CurrentAllowance.AllowanceDate
      AND h.EmployeeAllowanceTypeId = CurrentAllowance.EmployeeAllowanceTypeId
      AND h.CurrencyId = CurrentAllowance.CurrencyId
    GROUP BY d.EmployeeId
),
     AccumulatedBalances
AS (SELECT currentAndPreviousAllowances.EmployeeId,
           SUM(currentAndPreviousAllowances.ApprovedAmount) AS AccumulatedBalance
    FROM dbo.PR_EmployeeAllowanceDetail AS currentAndPreviousAllowances
        INNER JOIN dbo.PR_EmployeeAllowance
            ON currentAndPreviousAllowances.EmployeeAllowanceId = PR_EmployeeAllowance.EmployeeAllowanceId
    WHERE PR_EmployeeAllowance.AllowanceDate <=
    (
        SELECT PR_EmployeeAllowance.AllowanceDate
        FROM dbo.PR_EmployeeAllowance
        WHERE PR_EmployeeAllowance.EmployeeAllowanceId = @EmployeeAllowanceId
    )
    GROUP BY currentAndPreviousAllowances.EmployeeId)
INSERT #L2D
SELECT e.EmployeeAllowanceDetailId,
       e.EmployeeAllowanceId,
       e.SerialNumber,
       e.EmployeeName,
       e.WorkDate,
       e.AccrualAmount,
       e.AllowanceDays,
       e.ApprovedAmount,
       e.TransactionDate,
       ltd.LastTransactionDate,
       ab.AccumulatedBalance,
       e.DateOfWork
FROM EmployeeDetails e
    LEFT JOIN LastTransactionDate ltd
        ON e.EmployeeId = ltd.EmployeeId
    LEFT JOIN AccumulatedBalances ab
        ON e.EmployeeId = ab.EmployeeId
WHERE @IsArabic = @IsArabic;

        -- report relation EmployeeAllowance_EmployeeAllowanceDetail: header row, its detail rows under it
        INSERT #L2 (Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate)
        SELECT DB_NAME(), @HeaderId, @IsArabic, h.EmployeeAllowanceId, h.SerialNumber, h.TypeName, h.CurrencyName, h.AllowanceDate, h.CreatedBy, h.CreatedOn, h.ModifiedBy, h.LastModifiedOn, h.HistoricalSeverancePackage,
               d.EmployeeAllowanceDetailId, d.SerialNumber,
               (SELECT dd.EmployeeId FROM dbo.PR_EmployeeAllowanceDetail dd WHERE dd.EmployeeAllowanceDetailId = d.EmployeeAllowanceDetailId),
               d.EmployeeName, d.WorkDate, d.DateOfWork, d.LastTransactionDate, d.AccrualAmount, d.AllowanceDays, d.AccumulatedBalance, d.ApprovedAmount, d.TransactionDate
        FROM #L2H h LEFT JOIN #L2D d ON d.EmployeeAllowanceId = h.EmployeeAllowanceId;
    END

    IF @Print = 'P3'
    BEGIN
        INSERT #N3 (RowNo, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes)
        EXEC sp_executesql @B3, @P, @HeaderId, @IsArabic;
        UPDATE #N3 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        -- legacy dsAllowanceSerial.xsd Allowance and AllowanceDetails, verbatim; the C# step (currency rebind, % / 100) applied when flattening
        INSERT #L3
        SELECT DB_NAME(), @HeaderId, @IsArabic, h.AllowanceId, h.Serial, h.JournalSerial, h.AllowanceDate, h.CurrencyId, h.CurrencyFactor,
               CASE WHEN @IsArabic = 1 THEN h.CurrencyNameArabic ELSE h.CurrencyName END,
               h.EmployeeId, h.EmployeeName, h.Description, h.ReceivedToEmployee,
               d.AllowanceDetailId, d.AllowanceTypeId, d.AllowanceTypeName, d.AllowanceValue, d.Description, d.IsPercentage,
               CASE WHEN d.IsPercentage = 1 THEN d.AllowancePercentage / 100 ELSE d.AllowancePercentage END,
               d.Incomes
        FROM (
SELECT  PR_Allowance.* ,
         CASE WHEN @IsArabic = 1
                 THEN CASE WHEN ( LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) ) = ''
                           THEN PR_Employee.EmployeeName
                           ELSE PR_Employee.EmployeeArabicName
                      END
                 ELSE PR_Employee.EmployeeName
            END EmployeeName ,
		EmployeeArabicName,
        CurrencyName ,
        CurrencyNameArabic ,
        CASE WHEN IsReceivedToEmployee = 1 THEN N'✓'
             ELSE N''
        END AS ReceivedToEmployee
FROM    dbo.PR_Allowance
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Allowance.EmployeeId
        INNER JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = PR_Allowance.CurrencyId
WHERE   AllowanceId = @AllowanceId AND   (@IsArabic = @IsArabic)
        ) AS h
        LEFT JOIN (
SELECT AllowanceDetails.AllowanceDetailId,
       AllowanceDetails.AllowanceId,
       AllowanceDetails.AllowanceTypeId,
       AllowanceDetails.AllowanceValue,
       AllowanceDetails.Description,
       AllowanceDetails.IsPercentage,
       AllowanceDetails.AllowancePercentage,
       (
           SELECT STUFF(
                  (
                      SELECT ' - ' + PR_Income.IncomeName
                      FROM PR_AllowanceIncomeDetail
                          LEFT JOIN dbo.PR_Income
                              ON PR_Income.IncomeId = PR_AllowanceIncomeDetail.IncomeId
                      WHERE PR_AllowanceIncomeDetail.AllowanceDetailId = AllowanceDetails.AllowanceDetailId
                      FOR XML PATH('')
                  ),
                  1,
                  2,
                  ''
                       )
       ) AS Incomes,
       AllowanceTypeName
FROM dbo.PR_AllowanceDetails AS AllowanceDetails
    INNER JOIN dbo.PR_AllowanceType
        ON PR_AllowanceType.AllowanceTypeId = AllowanceDetails.AllowanceTypeId
WHERE AllowanceId = @AllowanceId
        ) AS d ON d.AllowanceId = h.AllowanceId;
    END

    IF @Print = 'P4'
    BEGIN
        INSERT #N4 (RowNo, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid)
        EXEC sp_executesql @B4, @P, @HeaderId, @IsArabic;
        UPDATE #N4 SET Db = DB_NAME(), HeaderId = @HeaderId, IsArabic = @IsArabic WHERE Db IS NULL;

        -- legacy dsEmployeeBonus.xsd (HR), verbatim; the C# step rebinds type and currency by language
        INSERT #L4
        SELECT DB_NAME(), @HeaderId, @IsArabic, x.EmployeeBonusId, x.SerialNumber, x.EmployeeId, x.EmployeeNumber, x.EmployeeName, x.BonusId, x.BonusName, x.BonusDate,
               CASE WHEN @IsArabic = 1 THEN x.BonusTypeName ELSE x.BonusTypeNameSecondLanguage END,
               x.BonusAmount, x.BonusCurrencyId,
               CASE WHEN @IsArabic = 1 THEN x.CurrencyNameArabic ELSE x.CurrencyName END,
               x.Paid
        FROM (
SELECT  EmployeeBonusId ,
        SerialNumber ,
        PR_Employee.EmployeeNumber ,
        PR_Employee.EmployeeName ,
        PR_Bonus.BonusName ,
        BonusDate ,
        PR_EmployeeBonusType.BonusTypeName ,
        PR_EmployeeBonusType.BonusTypeNameSecondLanguage ,
        BonusAmount ,
        Acc_Currency.CurrencyName ,
        Acc_Currency.CurrencyNameArabic ,
        Paid ,
        BounsTotalValue AS BonusTotalLocal ,
        PR_Bonus.BonusId ,
        PR_Employee.EmployeeId ,
        BonusCurrencyId ,
        PaidInSalaryMainId ,
        BounsTotalValue ,
        PR_EmployeeBonus.Description ,
        PR_Employee.IDNumber ,
        PR_Nationality.Nationality,managner.EmployeeName AS ManagnerName
FROM    dbo.PR_EmployeeBonus
        INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_EmployeeBonus.EmployeeId
        INNER JOIN dbo.Acc_Currency ON dbo.Acc_Currency.CurrencyId = PR_EmployeeBonus.BonusCurrencyId
        INNER JOIN PR_Bonus ON PR_Bonus.BonusId = PR_EmployeeBonus.BonusId
        LEFT JOIN dbo.PR_EmployeeBonusType ON PR_EmployeeBonusType.BonusTypeId = PR_EmployeeBonus.BonusTypeId
        LEFT JOIN dbo.PR_Nationality ON PR_Nationality.NationalityId = PR_Employee.NationalityId
		LEFT JOIN dbo.PR_Employee managner ON managner.EmployeeId = PR_Employee.ManagerId
WHERE   PR_EmployeeBonus.EmployeeBonusId = @EmployeeBonusId
        ) AS x;
    END

    FETCH NEXT FROM c INTO @Print, @HeaderId, @IsArabic;
END
CLOSE c; DEALLOCATE c;

-- D10 decisions applied to the legacy side (recorded in #Adj before the change):
-- P1 currency name and P4 employee name follow the print language; P2 detail employee name falls back to EmployeeName when the Arabic name is blank (D15).
INSERT #Adj SELECT DB_NAME(), 'P1', COUNT(*) FROM #L1 l JOIN dbo.Acc_Currency c ON c.CurrencyId = l.IncomeCurrency WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(l.CurrencyName, N'') <> c.CurrencyNameArabic;
UPDATE l SET CurrencyName = c.CurrencyNameArabic FROM #L1 l JOIN dbo.Acc_Currency c ON c.CurrencyId = l.IncomeCurrency WHERE l.Db = DB_NAME() AND l.IsArabic = 1;
INSERT #Adj SELECT DB_NAME(), 'P2', COUNT(*) FROM #L2 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') = N'';
UPDATE l SET EmployeeName = e.EmployeeName FROM #L2 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') = N'';
INSERT #Adj SELECT DB_NAME(), 'P4', COUNT(*) FROM #L4 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1 AND ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') <> N'' AND e.EmployeeArabicName <> l.EmployeeName;
UPDATE l SET EmployeeName = CASE WHEN ISNULL(LTRIM(RTRIM(e.EmployeeArabicName)), N'') = N'' THEN e.EmployeeName ELSE e.EmployeeArabicName END FROM #L4 l JOIN dbo.PR_Employee e ON e.EmployeeId = l.EmployeeId WHERE l.Db = DB_NAME() AND l.IsArabic = 1;
GO
SET NOCOUNT ON;
-- P1: groups = (Db, HeaderId, IsArabic); RowNo must be 1..n per group
SELECT 'P1' AS Print_, g.Db, COUNT(DISTINCT g.HeaderId) AS Ids, SUM(CASE WHEN g.L > 0 THEN 1 ELSE 0 END) AS GroupsWithRows, SUM(g.L) AS LegacyRows, SUM(g.N) AS TvfRows, SUM(CASE WHEN g.L <> g.N THEN 1 ELSE 0 END) AS GroupsCountDiff,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #L1 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #N1) x WHERE x.Db = g.Db) AS LegacyNotInTvf,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #N1 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #L1) x WHERE x.Db = g.Db) AS TvfNotInLegacy,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic FROM #N1 GROUP BY Db, HeaderId, IsArabic HAVING MIN(RowNo) <> 1 OR MAX(RowNo) <> COUNT(*) OR COUNT(DISTINCT RowNo) <> COUNT(*)) r WHERE r.Db = g.Db) AS BadRowNoGroups
FROM (SELECT ISNULL(l.Db, n.Db) Db, ISNULL(l.HeaderId, n.HeaderId) HeaderId, ISNULL(l.IsArabic, n.IsArabic) IsArabic, ISNULL(l.c, 0) L, ISNULL(n.c, 0) N
      FROM (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #L1 GROUP BY Db, HeaderId, IsArabic) l
      FULL JOIN (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #N1 GROUP BY Db, HeaderId, IsArabic) n ON n.Db = l.Db AND n.HeaderId = l.HeaderId AND n.IsArabic = l.IsArabic) g
GROUP BY g.Db ORDER BY g.Db;
SELECT TOP 10 'L-N' AS Side, * FROM (SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #L1 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #N1) x
UNION ALL SELECT TOP 10 'N-L', * FROM (SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #N1 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeIncomeId, EmployeeId, EmployeeNumber, EmployeeName, JobName, DepartmentName, BranchName, DateOfWork, IncomeId, IncomeName, IncomeAmount, IncomeCurrency, CurrencyName, IncomeStartDate, SocialInsuranceRoleId, SocialInsuranceRole, EmployeeInsuranceAmount FROM #L1) y;
-- P2: groups = (Db, HeaderId, IsArabic); RowNo must be 1..n per group
SELECT 'P2' AS Print_, g.Db, COUNT(DISTINCT g.HeaderId) AS Ids, SUM(CASE WHEN g.L > 0 THEN 1 ELSE 0 END) AS GroupsWithRows, SUM(g.L) AS LegacyRows, SUM(g.N) AS TvfRows, SUM(CASE WHEN g.L <> g.N THEN 1 ELSE 0 END) AS GroupsCountDiff,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #L2 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #N2) x WHERE x.Db = g.Db) AS LegacyNotInTvf,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #N2 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #L2) x WHERE x.Db = g.Db) AS TvfNotInLegacy,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic FROM #N2 GROUP BY Db, HeaderId, IsArabic HAVING MIN(RowNo) <> 1 OR MAX(RowNo) <> COUNT(*) OR COUNT(DISTINCT RowNo) <> COUNT(*)) r WHERE r.Db = g.Db) AS BadRowNoGroups
FROM (SELECT ISNULL(l.Db, n.Db) Db, ISNULL(l.HeaderId, n.HeaderId) HeaderId, ISNULL(l.IsArabic, n.IsArabic) IsArabic, ISNULL(l.c, 0) L, ISNULL(n.c, 0) N
      FROM (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #L2 GROUP BY Db, HeaderId, IsArabic) l
      FULL JOIN (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #N2 GROUP BY Db, HeaderId, IsArabic) n ON n.Db = l.Db AND n.HeaderId = l.HeaderId AND n.IsArabic = l.IsArabic) g
GROUP BY g.Db ORDER BY g.Db;
SELECT TOP 10 'L-N' AS Side, * FROM (SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #L2 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #N2) x
UNION ALL SELECT TOP 10 'N-L', * FROM (SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #N2 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeAllowanceId, SerialNumber, TypeName, CurrencyName, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage, EmployeeAllowanceDetailId, DetailSerialNumber, EmployeeId, EmployeeName, WorkDate, DateOfWork, LastTransactionDate, AccrualAmount, AllowanceDays, AccumulatedBalance, ApprovedAmount, TransactionDate FROM #L2) y;
-- P3: groups = (Db, HeaderId, IsArabic); RowNo must be 1..n per group
SELECT 'P3' AS Print_, g.Db, COUNT(DISTINCT g.HeaderId) AS Ids, SUM(CASE WHEN g.L > 0 THEN 1 ELSE 0 END) AS GroupsWithRows, SUM(g.L) AS LegacyRows, SUM(g.N) AS TvfRows, SUM(CASE WHEN g.L <> g.N THEN 1 ELSE 0 END) AS GroupsCountDiff,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #L3 EXCEPT SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #N3) x WHERE x.Db = g.Db) AS LegacyNotInTvf,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #N3 EXCEPT SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #L3) x WHERE x.Db = g.Db) AS TvfNotInLegacy,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic FROM #N3 GROUP BY Db, HeaderId, IsArabic HAVING MIN(RowNo) <> 1 OR MAX(RowNo) <> COUNT(*) OR COUNT(DISTINCT RowNo) <> COUNT(*)) r WHERE r.Db = g.Db) AS BadRowNoGroups
FROM (SELECT ISNULL(l.Db, n.Db) Db, ISNULL(l.HeaderId, n.HeaderId) HeaderId, ISNULL(l.IsArabic, n.IsArabic) IsArabic, ISNULL(l.c, 0) L, ISNULL(n.c, 0) N
      FROM (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #L3 GROUP BY Db, HeaderId, IsArabic) l
      FULL JOIN (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #N3 GROUP BY Db, HeaderId, IsArabic) n ON n.Db = l.Db AND n.HeaderId = l.HeaderId AND n.IsArabic = l.IsArabic) g
GROUP BY g.Db ORDER BY g.Db;
SELECT TOP 10 'L-N' AS Side, * FROM (SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #L3 EXCEPT SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #N3) x
UNION ALL SELECT TOP 10 'N-L', * FROM (SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #N3 EXCEPT SELECT Db, HeaderId, IsArabic, AllowanceId, Serial, JournalSerial, AllowanceDate, CurrencyId, CurrencyFactor, CurrencyName, EmployeeId, EmployeeName, Description, ReceivedToEmployee, AllowanceDetailId, AllowanceTypeId, AllowanceTypeName, AllowanceValue, DetailDescription, IsPercentage, AllowancePercentage, Incomes FROM #L3) y;
-- P4: groups = (Db, HeaderId, IsArabic); RowNo must be 1..n per group
SELECT 'P4' AS Print_, g.Db, COUNT(DISTINCT g.HeaderId) AS Ids, SUM(CASE WHEN g.L > 0 THEN 1 ELSE 0 END) AS GroupsWithRows, SUM(g.L) AS LegacyRows, SUM(g.N) AS TvfRows, SUM(CASE WHEN g.L <> g.N THEN 1 ELSE 0 END) AS GroupsCountDiff,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #L4 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #N4) x WHERE x.Db = g.Db) AS LegacyNotInTvf,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #N4 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #L4) x WHERE x.Db = g.Db) AS TvfNotInLegacy,
       (SELECT COUNT(*) FROM (SELECT Db, HeaderId, IsArabic FROM #N4 GROUP BY Db, HeaderId, IsArabic HAVING MIN(RowNo) <> 1 OR MAX(RowNo) <> COUNT(*) OR COUNT(DISTINCT RowNo) <> COUNT(*)) r WHERE r.Db = g.Db) AS BadRowNoGroups
FROM (SELECT ISNULL(l.Db, n.Db) Db, ISNULL(l.HeaderId, n.HeaderId) HeaderId, ISNULL(l.IsArabic, n.IsArabic) IsArabic, ISNULL(l.c, 0) L, ISNULL(n.c, 0) N
      FROM (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #L4 GROUP BY Db, HeaderId, IsArabic) l
      FULL JOIN (SELECT Db, HeaderId, IsArabic, COUNT(*) c FROM #N4 GROUP BY Db, HeaderId, IsArabic) n ON n.Db = l.Db AND n.HeaderId = l.HeaderId AND n.IsArabic = l.IsArabic) g
GROUP BY g.Db ORDER BY g.Db;
SELECT TOP 10 'L-N' AS Side, * FROM (SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #L4 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #N4) x
UNION ALL SELECT TOP 10 'N-L', * FROM (SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #N4 EXCEPT SELECT Db, HeaderId, IsArabic, EmployeeBonusId, SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, BonusId, BonusName, BonusDate, BonusTypeName, BonusAmount, BonusCurrencyId, CurrencyName, Paid FROM #L4) y;
SELECT 'D10/D15 legacy-side name adjustments' AS Note, * FROM #Adj ORDER BY Db, Print_;
SELECT 'P1' AS Print_, Db, COUNT(DISTINCT HeaderId) AS IdsWithRows, MIN(HeaderId) AS MinId, MAX(HeaderId) AS MaxId FROM #N1 GROUP BY Db;
SELECT 'P2' AS Print_, Db, COUNT(DISTINCT HeaderId) AS IdsWithRows, MIN(HeaderId) AS MinId, MAX(HeaderId) AS MaxId FROM #N2 GROUP BY Db;
SELECT 'P3' AS Print_, Db, COUNT(DISTINCT HeaderId) AS IdsWithRows, MIN(HeaderId) AS MinId, MAX(HeaderId) AS MaxId FROM #N3 GROUP BY Db;
SELECT 'P4' AS Print_, Db, COUNT(DISTINCT HeaderId) AS IdsWithRows, MIN(HeaderId) AS MinId, MAX(HeaderId) AS MaxId FROM #N4 GROUP BY Db;
