SET NOCOUNT ON;
GO
PRINT '== R5 2026-01-01..2026-10-14 all ids sec5 ar0';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-14T23:59:59', @employeeIds NVARCHAR(MAX) = NULL, @userSecurityLevel INT = 5, @isArabic BIT = 0;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-14T23:59:59.997', NULL, 5, 0);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-14 all ids sec5 ar0' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
PRINT '== R5 2026-01-01..2026-10-14 all ids sec1 ar0';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-14T23:59:59', @employeeIds NVARCHAR(MAX) = NULL, @userSecurityLevel INT = 1, @isArabic BIT = 0;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-14T23:59:59.997', NULL, 1, 0);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-14 all ids sec1 ar0' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
PRINT '== R5 2026-01-01..2026-10-14 ids 4,14,113 sec5 ar0';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-14T23:59:59', @employeeIds NVARCHAR(MAX) = '4,14,113', @userSecurityLevel INT = 5, @isArabic BIT = 0;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-14T23:59:59.997', '4,14,113', 5, 0);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-14 ids 4,14,113 sec5 ar0' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
PRINT '== R5 2026-01-01..2026-10-14 all ids sec5 ar1';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-14T23:59:59', @employeeIds NVARCHAR(MAX) = NULL, @userSecurityLevel INT = 5, @isArabic BIT = 1;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-14T23:59:59.997', NULL, 5, 1);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-14 all ids sec5 ar1' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
PRINT '== R5 2026-01-01..2026-10-14 all ids sec1 ar1';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-14T23:59:59', @employeeIds NVARCHAR(MAX) = NULL, @userSecurityLevel INT = 1, @isArabic BIT = 1;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-14T23:59:59.997', NULL, 1, 1);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-14 all ids sec1 ar1' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
PRINT '== R5 2026-01-01..2026-10-14 ids 4,14,113 sec5 ar1';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-14T23:59:59', @employeeIds NVARCHAR(MAX) = '4,14,113', @userSecurityLevel INT = 5, @isArabic BIT = 1;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-14T23:59:59.997', '4,14,113', 5, 1);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-14 ids 4,14,113 sec5 ar1' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
PRINT '== R5 2026-01-01..2026-10-13 (before the bonus day) sec5 ar0';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-13T23:59:59', @employeeIds NVARCHAR(MAX) = NULL, @userSecurityLevel INT = 5, @isArabic BIT = 0;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-13T23:59:59.997', NULL, 5, 0);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-13 (before the bonus day) sec5 ar0' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
PRINT '== R5 2026-01-01..2026-10-14 ids 4,9,113 (no bonus) sec5 ar1';
DECLARE @fromDate DATETIME = '2026-01-01', @toDate DATETIME = '2026-10-14T23:59:59', @employeeIds NVARCHAR(MAX) = '4,9,113', @userSecurityLevel INT = 5, @isArabic BIT = 1;
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
INTO #L
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
SELECT * INTO #TVF FROM dbo.PR_EmployeeBonusReport('2026-01-01', '2026-10-14T23:59:59.997', '4,9,113', 5, 1);

SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #o FROM #L;
SELECT SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr, ROW_NUMBER() OVER (PARTITION BY SerialNumber, EmployeeId, EmployeeNumber, EmployeeName, JobName, EmployeeBonusId, BonusId, BonusName, BonusTypeId, BonusDate, BonusValueTypeName, BonusCurrencyId, CurrencyName, CurrencyEnglishLetter, CurrencyArabicLetter, BonusAmount, BounsTotalValue, Description, IsPaid, IsPaidStr ORDER BY (SELECT 0)) AS dup INTO #n FROM #TVF;
SELECT * INTO #on FROM (SELECT * FROM #o EXCEPT SELECT * FROM #n) a;
SELECT * INTO #no FROM (SELECT * FROM #n EXCEPT SELECT * FROM #o) b;
SELECT 'R5 2026-01-01..2026-10-14 ids 4,9,113 (no bonus) sec5 ar1' AS TestCase, (SELECT COUNT(*) FROM #L) AS OldRows, (SELECT COUNT(*) FROM #TVF) AS NewRows,
  (SELECT COUNT(*) FROM #on) AS OldMinusNew, (SELECT COUNT(*) FROM #no) AS NewMinusOld, (SELECT SUM(BonusAmount) FROM #L) AS Old_BonusAmount, (SELECT SUM(BonusAmount) FROM #TVF) AS New_BonusAmount, (SELECT SUM(BounsTotalValue) FROM #L) AS Old_BounsTotalValue, (SELECT SUM(BounsTotalValue) FROM #TVF) AS New_BounsTotalValue,
  CASE WHEN ISNULL((SELECT SUM(BonusAmount) FROM #L),0)=ISNULL((SELECT SUM(BonusAmount) FROM #TVF),0) AND ISNULL((SELECT SUM(BounsTotalValue) FROM #L),0)=ISNULL((SELECT SUM(BounsTotalValue) FROM #TVF),0) THEN 'Y' ELSE 'N' END AS SumsEqual,
  CASE WHEN (SELECT COUNT(*) FROM #on)=0 AND (SELECT COUNT(*) FROM #no)=0 AND (SELECT COUNT(*) FROM #L)=(SELECT COUNT(*) FROM #TVF) THEN 'PASS' ELSE 'FAIL' END AS Result;
IF EXISTS (SELECT 1 FROM #on) SELECT TOP 10 'old-new' side, * FROM #on;
IF EXISTS (SELECT 1 FROM #no) SELECT TOP 10 'new-old' side, * FROM #no;
DROP TABLE #o; DROP TABLE #n; DROP TABLE #on; DROP TABLE #no;

DROP TABLE #L; DROP TABLE #TVF;
GO
