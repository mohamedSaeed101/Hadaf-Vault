-- CR-125307 phase 3 parity: legacy dsBankSalaryPrint.xsd FillBy (and Fill, the action the old front URL actually hit)
-- vs the PR_BankSalaryPrint TVF body run inline. Read-only: temp tables only, nothing is created on the tenant.
-- Legacy texts are copied verbatim from the .xsd and run through sp_executesql with the TableAdapter's parameter list,
-- so the row order captured in #L.ord is the order the C# RowNumber loop saw.
-- Cases are derived from Pr_PayingSalaries as the front derives them from SalaryExchangeDto:
-- month = PayingSalariesDate, currency = CurrencyId, employeeIds = detail EmployeeIds joined by ',' (empty -> NULL).
SET NOCOUNT ON;

DECLARE @legacyFillBy NVARCHAR(MAX) = N'WITH    allEmpsIncome
          AS ( SELECT   EmployeeId ,
                        IncomeId ,
                        IncomeCurrency ,
						IncomeAmount
               FROM     PR_EmployeeIncome
               WHERE    ( @EmployeeIds IS NULL
                          OR EmployeeId IN (
                          SELECT    number
                          FROM      dbo.Acc_ConvertStringListToTable(@EmployeeIds) )
                        )
                        AND ( IncomeEndDate IS  NULL )
						AND	((SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration) = 0 OR SocialInsuranceRoleId IS NULL)
             )
    SELECT DISTINCT
            SalaryHeader.EmployeeName ,
            SalaryHeader.Mobile ,
            SalaryHeader.CurrencyNameArabic ,
            SalaryHeader.AccountNo ,
            SalaryHeader.Description ,
            SalaryHeader.BankName ,
            SalaryHeader.Total ,
            DATEFROMPARTS(SalaryYear, SalaryMonth, 1) AS SalaryDate ,
            SalaryHeader.SalaryMonth ,
            SalaryHeader.SalaryYear ,
            SalaryHeader.DepartmentName ,
            SalaryHeader.BranchName ,
            SalaryHeader.Suspend ,
            SalaryHeader.EmployeeArabicName ,
            SalaryHeader.IdentityNumber ,
            SalaryHeader.Age ,
            ProjectName ,
            SalaryHeader.EmployeeNumber ,
            JobName ,
            SalaryHeader.IdNumber ,
            CAST(0 AS INT) AS RowNumber ,
            SalaryHeader.EmployeeId ,
            SalaryHeader.TotalDeductions ,
            ( SELECT    allEmpsIncome.IncomeAmount
              FROM      allEmpsIncome
              WHERE     allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                        AND allEmpsIncome.IncomeId = 1
                        AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId
            ) AS BasicSalaryIncome ,
            ( SELECT    allEmpsIncome.IncomeAmount
              FROM      allEmpsIncome
              WHERE     allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                        AND allEmpsIncome.IncomeId = 3
                        AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId
            ) AS HousingAllowanceIncome ,
            ( SELECT    SUM(ISNULL(allEmpsIncome.IncomeAmount, 0))
              FROM      allEmpsIncome
              WHERE     allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                        AND allEmpsIncome.IncomeId NOT IN ( 1, 3 )
                        AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId
            ) AS OtherIncome ,
            PR_Employee.Address EmployeeAddress
    FROM    Vw_SalaryHeader AS SalaryHeader
            LEFT JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = SalaryHeader.EmployeeId
			INNER JOIN dbo.Pr_PayingSalaries ON Pr_PayingSalaries.BankId = SalaryHeader.BankId
    WHERE   ( SalaryHeader.Suspend = 0 )
		    AND Pr_PayingSalaries.PayingSalariesId=@PayingsalaryId
            AND SalaryHeader.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND ( SalaryHeader.BankId = @bankId )
            AND ( SalaryHeader.SalaryMonth = @month )
            AND ( SalaryHeader.SalaryYear = @year )
            AND ( @CurrencyId IS NULL
                  OR SalaryHeader.CurrencyId = @CurrencyId
                )
            AND ( @EmployeeIds IS NULL
                  OR SalaryHeader.EmployeeId IN (
                  SELECT    number
                  FROM      dbo.Acc_ConvertStringListToTable(@EmployeeIds) )
                )';

DECLARE @legacyFill NVARCHAR(MAX) = N'WITH    allEmpsIncome
          AS ( SELECT   EmployeeId ,
                        IncomeId ,
                        IncomeCurrency ,
						IncomeAmount
               FROM     PR_EmployeeIncome
               WHERE    ( @EmployeeIds IS NULL
                          OR EmployeeId IN (
                          SELECT    number
                          FROM      dbo.Acc_ConvertStringListToTable(@EmployeeIds) )
                        )
                        AND ( IncomeEndDate IS  NULL )
						AND	((SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration) = 0 OR SocialInsuranceRoleId IS NULL)
             )
    SELECT DISTINCT
            SalaryHeader.EmployeeName ,
            SalaryHeader.Mobile ,
            SalaryHeader.CurrencyNameArabic ,
            SalaryHeader.AccountNo ,
            SalaryHeader.Description ,
            SalaryHeader.BankName ,
            SalaryHeader.Total ,
            DATEFROMPARTS(SalaryYear, SalaryMonth, 1) AS SalaryDate ,
            SalaryHeader.SalaryMonth ,
            SalaryHeader.SalaryYear ,
            SalaryHeader.DepartmentName ,
            SalaryHeader.BranchName ,
            SalaryHeader.Suspend ,
            SalaryHeader.EmployeeArabicName ,
            SalaryHeader.IdentityNumber ,
            SalaryHeader.Age ,
            ProjectName ,
            SalaryHeader.EmployeeNumber ,
            JobName ,
            SalaryHeader.IdNumber ,
            CAST(0 AS INT) AS RowNumber ,
            SalaryHeader.EmployeeId ,
            SalaryHeader.TotalDeductions ,
            ( SELECT    allEmpsIncome.IncomeAmount
              FROM      allEmpsIncome
              WHERE     allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                        AND allEmpsIncome.IncomeId = 1
                        AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId
            ) AS BasicSalaryIncome ,
            ( SELECT    allEmpsIncome.IncomeAmount
              FROM      allEmpsIncome
              WHERE     allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                        AND allEmpsIncome.IncomeId = 3
                        AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId
            ) AS HousingAllowanceIncome ,
            ( SELECT    SUM(ISNULL(allEmpsIncome.IncomeAmount, 0))
              FROM      allEmpsIncome
              WHERE     allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                        AND allEmpsIncome.IncomeId NOT IN ( 1, 3 )
                        AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId
            ) AS OtherIncome ,
            PR_Employee.Address EmployeeAddress
    FROM    Vw_SalaryHeader AS SalaryHeader
            LEFT JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = SalaryHeader.EmployeeId
    WHERE   ( SalaryHeader.Suspend = 0 )
            AND SalaryHeader.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND ( SalaryHeader.BankId = @bankId )
            AND ( SalaryHeader.SalaryMonth = @month )
            AND ( SalaryHeader.SalaryYear = @year )
            AND ( @CurrencyId IS NULL
                  OR SalaryHeader.CurrencyId = @CurrencyId
                )
            AND ( @EmployeeIds IS NULL
                  OR SalaryHeader.EmployeeId IN (
                  SELECT    number
                  FROM      dbo.Acc_ConvertStringListToTable(@EmployeeIds) )
                )';

DECLARE @maxSec INT = (SELECT MAX(EmployeeSecurityLevel) FROM dbo.PR_Employee);

DROP TABLE IF EXISTS #cases;
CREATE TABLE #cases (caseNo INT IDENTITY(1,1), label NVARCHAR(200), psId INT, bankId INT, monthDate DATE, currencyId INT, employeeIds NVARCHAR(MAX), sec INT);

WITH docs AS
(
    SELECT p.PayingSalariesId, p.BankId, CAST(p.PayingSalariesDate AS DATE) AS monthDate, p.CurrencyId
         , NULLIF((SELECT STRING_AGG(CAST(ISNULL(d.EmployeeId, 0) AS NVARCHAR(MAX)), ',') FROM dbo.Pr_PayingSalariesDetail d WHERE d.PayingSalariesId = p.PayingSalariesId), '') AS employeeIds
    FROM dbo.Pr_PayingSalaries p
    WHERE p.BankId IS NOT NULL AND p.PayingSalariesDate IS NOT NULL
)
INSERT INTO #cases (label, psId, bankId, monthDate, currencyId, employeeIds, sec)
SELECT v.label, docs.PayingSalariesId, docs.BankId, v.m, v.c, v.e, v.s
FROM docs
CROSS APPLY (VALUES
      (CONCAT('doc ', docs.PayingSalariesId, ' as front, max sec'), docs.monthDate, docs.CurrencyId, docs.employeeIds, @maxSec)
    , (CONCAT('doc ', docs.PayingSalariesId, ' employeeIds NULL'), docs.monthDate, docs.CurrencyId, NULL, @maxSec)
    , (CONCAT('doc ', docs.PayingSalariesId, ' currency NULL'), docs.monthDate, NULL, docs.employeeIds, @maxSec)
    , (CONCAT('doc ', docs.PayingSalariesId, ' sec 1'), docs.monthDate, docs.CurrencyId, docs.employeeIds, 1)
    , (CONCAT('doc ', docs.PayingSalariesId, ' next month, employeeIds NULL'), DATEADD(MONTH, 1, docs.monthDate), docs.CurrencyId, NULL, @maxSec)
    , (CONCAT('doc ', docs.PayingSalariesId, ' 3 employees'), docs.monthDate, docs.CurrencyId, N'1,45,77', @maxSec)
) v(label, m, c, e, s);

DROP TABLE IF EXISTS #results;
CREATE TABLE #results (caseNo INT, label NVARCHAR(200), nFillBy INT, nFill INT, nTvf INT, tvfExceptFillBy INT, fillByExceptTvf INT, fillExceptFillBy INT, fillByExceptFill INT, rowNoMismatch INT, nTvfAr INT, arDiff INT, enCurrencyNull INT);

DECLARE @i INT = 1, @n INT = (SELECT COUNT(*) FROM #cases);
DECLARE @t_PayingSalariesId INT, @t_BankId INT, @t_Month DATE, @t_CurrencyId INT, @t_EmployeeIds NVARCHAR(MAX), @t_SecurityLevel INT, @t_IsArabic BIT;
DECLARE @params NVARCHAR(500) = N'@PayingsalaryId int, @EmployeeSecurityLevel int, @bankId int, @month int, @year int, @CurrencyId int, @EmployeeIds nvarchar(max)';
DECLARE @mo INT, @yr INT;

WHILE @i <= @n
BEGIN
    SELECT @t_PayingSalariesId = psId, @t_BankId = bankId, @t_Month = monthDate, @t_CurrencyId = currencyId, @t_EmployeeIds = employeeIds, @t_SecurityLevel = sec
    FROM #cases WHERE caseNo = @i;
    SELECT @mo = MONTH(@t_Month), @yr = YEAR(@t_Month);

    DROP TABLE IF EXISTS #L, #F, #N, #NA;
    CREATE TABLE #L (ord INT IDENTITY(1,1), EmployeeName NVARCHAR(1000), Mobile NVARCHAR(50), CurrencyNameArabic NVARCHAR(50), AccountNo NVARCHAR(500), Description NVARCHAR(1000), BankName NVARCHAR(100), Total MONEY, SalaryDate DATE, SalaryMonth INT, SalaryYear INT, DepartmentName NVARCHAR(50), BranchName NVARCHAR(1000), Suspend BIT, EmployeeArabicName NVARCHAR(1000), IdentityNumber NVARCHAR(100), Age INT, ProjectName NVARCHAR(500), EmployeeNumber NVARCHAR(100), JobName NVARCHAR(50), IdNumber NVARCHAR(50), RowNumber INT, EmployeeId INT, TotalDeductions MONEY, BasicSalaryIncome MONEY, HousingAllowanceIncome MONEY, OtherIncome MONEY, EmployeeAddress NVARCHAR(150));
    CREATE TABLE #F (ord INT IDENTITY(1,1), EmployeeName NVARCHAR(1000), Mobile NVARCHAR(50), CurrencyNameArabic NVARCHAR(50), AccountNo NVARCHAR(500), Description NVARCHAR(1000), BankName NVARCHAR(100), Total MONEY, SalaryDate DATE, SalaryMonth INT, SalaryYear INT, DepartmentName NVARCHAR(50), BranchName NVARCHAR(1000), Suspend BIT, EmployeeArabicName NVARCHAR(1000), IdentityNumber NVARCHAR(100), Age INT, ProjectName NVARCHAR(500), EmployeeNumber NVARCHAR(100), JobName NVARCHAR(50), IdNumber NVARCHAR(50), RowNumber INT, EmployeeId INT, TotalDeductions MONEY, BasicSalaryIncome MONEY, HousingAllowanceIncome MONEY, OtherIncome MONEY, EmployeeAddress NVARCHAR(150));

    INSERT INTO #L (EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, RowNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress)
    EXEC sp_executesql @legacyFillBy, @params, @t_PayingSalariesId, @t_SecurityLevel, @t_BankId, @mo, @yr, @t_CurrencyId, @t_EmployeeIds;

    INSERT INTO #F (EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, RowNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress)
    EXEC sp_executesql @legacyFill, N'@EmployeeSecurityLevel int, @bankId int, @month int, @year int, @CurrencyId int, @EmployeeIds nvarchar(max)', @t_SecurityLevel, @t_BankId, @mo, @yr, @t_CurrencyId, @t_EmployeeIds;

    SET @t_IsArabic = 0;
    WITH allEmpsIncome AS
    (
        SELECT EmployeeId
             , IncomeId
             , IncomeCurrency
             , IncomeAmount
        FROM dbo.PR_EmployeeIncome
        WHERE (@t_EmployeeIds IS NULL
                OR EmployeeId IN (SELECT number FROM dbo.Acc_ConvertStringListToTable(@t_EmployeeIds)))
            AND (IncomeEndDate IS NULL)
            AND ((SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration) = 0 OR SocialInsuranceRoleId IS NULL)
    ),
    bankSalary AS
    (
        SELECT DISTINCT
              CASE
                  WHEN @t_IsArabic = 1 THEN ISNULL(NULLIF(LTRIM(RTRIM(SalaryHeader.EmployeeArabicName)), ''), SalaryHeader.EmployeeName)
                  ELSE SalaryHeader.EmployeeName
              END AS EmployeeName
            , SalaryHeader.Mobile
            , CASE WHEN @t_IsArabic = 1 THEN SalaryHeader.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
            , SalaryHeader.CurrencyNameArabic
            , SalaryHeader.AccountNo
            , SalaryHeader.Description
            , SalaryHeader.BankName
            , SalaryHeader.Total
            , DATEFROMPARTS(SalaryHeader.SalaryYear, SalaryHeader.SalaryMonth, 1) AS SalaryDate
            , SalaryHeader.SalaryMonth
            , SalaryHeader.SalaryYear
            , SalaryHeader.DepartmentName
            , SalaryHeader.BranchName
            , SalaryHeader.Suspend
            , SalaryHeader.EmployeeArabicName
            , SalaryHeader.IdentityNumber
            , SalaryHeader.Age
            , SalaryHeader.ProjectName
            , SalaryHeader.EmployeeNumber
            , SalaryHeader.JobName
            , SalaryHeader.IdNumber
            , SalaryHeader.EmployeeId
            , SalaryHeader.TotalDeductions
            , (SELECT allEmpsIncome.IncomeAmount
               FROM allEmpsIncome
               WHERE allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                   AND allEmpsIncome.IncomeId = 1
                   AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId) AS BasicSalaryIncome
            , (SELECT allEmpsIncome.IncomeAmount
               FROM allEmpsIncome
               WHERE allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                   AND allEmpsIncome.IncomeId = 3
                   AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId) AS HousingAllowanceIncome
            , (SELECT SUM(ISNULL(allEmpsIncome.IncomeAmount, 0))
               FROM allEmpsIncome
               WHERE allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                   AND allEmpsIncome.IncomeId NOT IN (1, 3)
                   AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId) AS OtherIncome
            , PR_Employee.Address AS EmployeeAddress
        FROM dbo.Vw_SalaryHeader AS SalaryHeader
            LEFT JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = SalaryHeader.EmployeeId
            INNER JOIN dbo.Pr_PayingSalaries
                ON Pr_PayingSalaries.BankId = SalaryHeader.BankId
            LEFT JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = SalaryHeader.CurrencyId
        WHERE (SalaryHeader.Suspend = 0)
            AND Pr_PayingSalaries.PayingSalariesId = @t_PayingSalariesId
            AND SalaryHeader.EmployeeSecurityLevel <= @t_SecurityLevel
            AND (SalaryHeader.BankId = @t_BankId)
            AND (SalaryHeader.SalaryMonth = MONTH(@t_Month))
            AND (SalaryHeader.SalaryYear = YEAR(@t_Month))
            AND (@t_CurrencyId IS NULL OR SalaryHeader.CurrencyId = @t_CurrencyId)
            AND (@t_EmployeeIds IS NULL
                OR SalaryHeader.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertStringListToTable(@t_EmployeeIds)))
    )
    -- Legacy numbered rows in the order its DISTINCT sort returned them: currency, account, description, total.
    SELECT CAST(ROW_NUMBER() OVER (ORDER BY CurrencyNameArabic, AccountNo, Description, Total, EmployeeId) AS BIGINT) AS RowNo
         , *
    INTO #N
    FROM bankSalary;

    SET @t_IsArabic = 1;
    WITH allEmpsIncome AS
    (
        SELECT EmployeeId
             , IncomeId
             , IncomeCurrency
             , IncomeAmount
        FROM dbo.PR_EmployeeIncome
        WHERE (@t_EmployeeIds IS NULL
                OR EmployeeId IN (SELECT number FROM dbo.Acc_ConvertStringListToTable(@t_EmployeeIds)))
            AND (IncomeEndDate IS NULL)
            AND ((SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration) = 0 OR SocialInsuranceRoleId IS NULL)
    ),
    bankSalary AS
    (
        SELECT DISTINCT
              CASE
                  WHEN @t_IsArabic = 1 THEN ISNULL(NULLIF(LTRIM(RTRIM(SalaryHeader.EmployeeArabicName)), ''), SalaryHeader.EmployeeName)
                  ELSE SalaryHeader.EmployeeName
              END AS EmployeeName
            , SalaryHeader.Mobile
            , CASE WHEN @t_IsArabic = 1 THEN SalaryHeader.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
            , SalaryHeader.CurrencyNameArabic
            , SalaryHeader.AccountNo
            , SalaryHeader.Description
            , SalaryHeader.BankName
            , SalaryHeader.Total
            , DATEFROMPARTS(SalaryHeader.SalaryYear, SalaryHeader.SalaryMonth, 1) AS SalaryDate
            , SalaryHeader.SalaryMonth
            , SalaryHeader.SalaryYear
            , SalaryHeader.DepartmentName
            , SalaryHeader.BranchName
            , SalaryHeader.Suspend
            , SalaryHeader.EmployeeArabicName
            , SalaryHeader.IdentityNumber
            , SalaryHeader.Age
            , SalaryHeader.ProjectName
            , SalaryHeader.EmployeeNumber
            , SalaryHeader.JobName
            , SalaryHeader.IdNumber
            , SalaryHeader.EmployeeId
            , SalaryHeader.TotalDeductions
            , (SELECT allEmpsIncome.IncomeAmount
               FROM allEmpsIncome
               WHERE allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                   AND allEmpsIncome.IncomeId = 1
                   AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId) AS BasicSalaryIncome
            , (SELECT allEmpsIncome.IncomeAmount
               FROM allEmpsIncome
               WHERE allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                   AND allEmpsIncome.IncomeId = 3
                   AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId) AS HousingAllowanceIncome
            , (SELECT SUM(ISNULL(allEmpsIncome.IncomeAmount, 0))
               FROM allEmpsIncome
               WHERE allEmpsIncome.EmployeeId = SalaryHeader.EmployeeId
                   AND allEmpsIncome.IncomeId NOT IN (1, 3)
                   AND allEmpsIncome.IncomeCurrency = SalaryHeader.CurrencyId) AS OtherIncome
            , PR_Employee.Address AS EmployeeAddress
        FROM dbo.Vw_SalaryHeader AS SalaryHeader
            LEFT JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = SalaryHeader.EmployeeId
            INNER JOIN dbo.Pr_PayingSalaries
                ON Pr_PayingSalaries.BankId = SalaryHeader.BankId
            LEFT JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = SalaryHeader.CurrencyId
        WHERE (SalaryHeader.Suspend = 0)
            AND Pr_PayingSalaries.PayingSalariesId = @t_PayingSalariesId
            AND SalaryHeader.EmployeeSecurityLevel <= @t_SecurityLevel
            AND (SalaryHeader.BankId = @t_BankId)
            AND (SalaryHeader.SalaryMonth = MONTH(@t_Month))
            AND (SalaryHeader.SalaryYear = YEAR(@t_Month))
            AND (@t_CurrencyId IS NULL OR SalaryHeader.CurrencyId = @t_CurrencyId)
            AND (@t_EmployeeIds IS NULL
                OR SalaryHeader.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertStringListToTable(@t_EmployeeIds)))
    )
    -- Legacy numbered rows in the order its DISTINCT sort returned them: currency, account, description, total.
    SELECT CAST(ROW_NUMBER() OVER (ORDER BY CurrencyNameArabic, AccountNo, Description, Total, EmployeeId) AS BIGINT) AS RowNo
         , *
    INTO #NA
    FROM bankSalary;

    INSERT INTO #results
    SELECT @i, (SELECT label FROM #cases WHERE caseNo = @i)
         , (SELECT COUNT(*) FROM #L), (SELECT COUNT(*) FROM #F), (SELECT COUNT(*) FROM #N)
         , (SELECT COUNT(*) FROM (SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #N EXCEPT SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #L) x)
         , (SELECT COUNT(*) FROM (SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #L EXCEPT SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #N) x)
         , (SELECT COUNT(*) FROM (SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #F EXCEPT SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #L) x)
         , (SELECT COUNT(*) FROM (SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #L EXCEPT SELECT EmployeeName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, EmployeeArabicName, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress FROM #F) x)
         , (SELECT COUNT(*) FROM #N n JOIN #L l
                ON l.EmployeeId = n.EmployeeId AND l.Total = n.Total AND l.CurrencyNameArabic = n.CurrencyNameArabic
                AND ISNULL(l.AccountNo, N'<null>') = ISNULL(n.AccountNo, N'<null>')
            WHERE n.RowNo <> l.ord)
         , (SELECT COUNT(*) FROM #NA)
         , (SELECT COUNT(*) FROM (SELECT EmployeeName, CurrencyName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress, EmployeeArabicName FROM #NA
                                  EXCEPT SELECT CASE WHEN LTRIM(RTRIM(EmployeeArabicName)) = '' THEN EmployeeName ELSE EmployeeArabicName END AS EmployeeName, CurrencyNameArabic AS CurrencyName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress, EmployeeArabicName FROM #L) x)
           + (SELECT COUNT(*) FROM (SELECT CASE WHEN LTRIM(RTRIM(EmployeeArabicName)) = '' THEN EmployeeName ELSE EmployeeArabicName END AS EmployeeName, CurrencyNameArabic AS CurrencyName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress, EmployeeArabicName FROM #L
                                  EXCEPT SELECT EmployeeName, CurrencyName, Mobile, CurrencyNameArabic, AccountNo, Description, BankName, Total, SalaryDate, SalaryMonth, SalaryYear, DepartmentName, BranchName, Suspend, IdentityNumber, Age, ProjectName, EmployeeNumber, JobName, IdNumber, EmployeeId, TotalDeductions, BasicSalaryIncome, HousingAllowanceIncome, OtherIncome, EmployeeAddress, EmployeeArabicName FROM #NA) x)
         , (SELECT COUNT(*) FROM #N WHERE CurrencyName IS NULL);

    SET @i += 1;
END

SELECT * FROM #results ORDER BY caseNo;
SELECT COUNT(*) AS payingSalariesWithBank FROM dbo.Pr_PayingSalaries WHERE BankId IS NOT NULL;
