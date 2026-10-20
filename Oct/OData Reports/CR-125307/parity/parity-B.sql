-- CR-125307 phase 2 number check: prints 5 (advance), 6 (purchase), 7a (salary exchange), 8 (accruals).
-- Legacy side: the .xsd CommandText copied verbatim (generated), run with sp_executesql, then the C# steps.
-- New side: the TVF body copied verbatim from dbo\Functions (generated), run with sp_executesql.
-- Read-only on the tenant: only session #temp tables in tempdb, no CREATE on the database.
-- Language mapping applied to legacy for comparison (D10): one display column chosen by @IsArabic.
SET NOCOUNT ON;
GO
-- ################ UNP-Ali ################
USE [UNP-Ali];
GO
DROP TABLE IF EXISTS #P;
DROP TABLE IF EXISTS #ADV_LH;
DROP TABLE IF EXISTS #ADV_LR;
DROP TABLE IF EXISTS #ADV_N;
DROP TABLE IF EXISTS #PUR_LH;
DROP TABLE IF EXISTS #PUR_LR;
DROP TABLE IF EXISTS #PUR_N;
DROP TABLE IF EXISTS #PAY_L;
DROP TABLE IF EXISTS #PAY_N;
DROP TABLE IF EXISTS #ACC_LH;
DROP TABLE IF EXISTS #ACC_LD;
DROP TABLE IF EXISTS #ACC_N;
DROP TABLE IF EXISTS #MD;
DROP TABLE IF EXISTS #ADV_L;
DROP TABLE IF EXISTS #PUR_L;
DROP TABLE IF EXISTS #PAY_LX;
DROP TABLE IF EXISTS #ACC_L;
DROP TABLE IF EXISTS #ADV_NX;
DROP TABLE IF EXISTS #PUR_NX;
DROP TABLE IF EXISTS #PAY_NX;
DROP TABLE IF EXISTS #ACC_NX;
GO
CREATE TABLE #P (Print_ VARCHAR(10), Id INT, IsArabic BIT);
-- every header id on the tenant plus -1 (no data), x IsArabic 0/1
INSERT INTO #P
SELECT h.Print_, h.Id, l.IsArabic
FROM (SELECT 'ADV' AS Print_, AdvanceId AS Id FROM dbo.PR_Advance
      UNION SELECT 'PUR', PurchaseId FROM dbo.PR_Purchase
      UNION SELECT 'PAY', PayingSalariesId FROM dbo.Pr_PayingSalaries
      UNION SELECT DISTINCT 'ACC', EmployeeId FROM dbo.PR_EmployeeTransactions
      UNION SELECT p, -1 FROM (VALUES ('ADV'), ('PUR'), ('PAY'), ('ACC')) v(p)) h
    CROSS JOIN (VALUES (CAST(0 AS BIT)), (CAST(1 AS BIT))) l(IsArabic);
GO
-- ===== shape + fill: each #X gets P_Id, P_IsArabic, P_Cur and the query's own columns =====
-- (#tables are created here, in the outer scope, so the dynamic ALTER/INSERT below keep them)
CREATE TABLE #ADV_LH (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ADV_LR (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ADV_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PUR_LH (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PUR_LR (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PUR_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PAY_L (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PAY_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ACC_LH (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ACC_LD (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ACC_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
DECLARE @q NVARCHAR(MAX), @prm NVARCHAR(MAX), @cols NVARCHAR(MAX), @names NVARCHAR(MAX), @run NVARCHAR(MAX);
DECLARE @t TABLE (Ord INT IDENTITY(1, 1), Tbl SYSNAME, Q NVARCHAR(MAX), Prm NVARCHAR(MAX), Print_ VARCHAR(10), Call NVARCHAR(400));
INSERT INTO @t (Tbl, Q, Prm, Print_, Call) VALUES
 ('#ADV_LH', N'SELECT  PR_Employee.EmployeeId ,
        CASE WHEN @IsArabic = 1
                 THEN CASE WHEN ( LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) ) = ''''
                           THEN PR_Employee.EmployeeName
                           ELSE PR_Employee.EmployeeArabicName
                      END
                 ELSE PR_Employee.EmployeeName
            END EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Advance.AdvanceAmount ,
        Acc_Currency.EnglishLetter ,
        PR_Advance.AdvanceAmountCurrency ,
        PR_Advance.Discription ,
        PR_Advance.NoRepayment ,
        PR_Advance.Approved ,
        PR_Advance.ApplayingStartDate ,
        PR_Advance.ApproxEndDate ,
        PR_Advance.Returned ,
        PR_Advance.IsAdvance ,
        PR_Advance.AdvanceId ,
        dbo.PR_Employee.Age ,
        RequestDate ,
        dbo.PR_Department.DepartmentName ,
        dbo.PR_Branch.BranchName ,
        EmployeeArabicName
FROM    Acc_Currency
        INNER JOIN PR_Advance ON Acc_Currency.CurrencyId = PR_Advance.AdvanceAmountCurrency
        INNER JOIN PR_Employee ON PR_Advance.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
WHERE   AdvanceId = @AdvanceId AND (@IsArabic = @IsArabic);', N'@AdvanceId INT, @IsArabic BIT', 'ADV', N'@AdvanceId = @id, @IsArabic = @ar')
,('#ADV_N',  N'    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_AdvanceRepayment.RepaymentId) AS RowNo
        , PR_Advance.AdvanceId
        , PR_Employee.EmployeeId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) = '''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Employee.EmployeeNumber
        , PR_Employee.Age
        , PR_Department.DepartmentName
        , PR_Branch.BranchName
        , PR_Advance.AdvanceAmount
        , PR_Advance.AdvanceAmountCurrency
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.ArabicLetter ELSE Acc_Currency.EnglishLetter END AS CurrencyLetter
        , PR_Advance.Discription
        , PR_Advance.NoRepayment
        , PR_Advance.Approved
        , PR_Advance.ApplayingStartDate
        , PR_Advance.ApproxEndDate
        , PR_Advance.Returned
        , PR_Advance.IsAdvance
        , PR_Advance.RequestDate
        , PR_AdvanceRepayment.RepaymentId
        , PR_AdvanceRepayment.PaymentDate
        , PR_AdvanceRepayment.Amount
        , PR_AdvanceRepayment.PaidDate
        , PR_AdvanceRepayment.Paid
        -- legacy print shows the scheduled Amount as the paid amount
        , PR_AdvanceRepayment.Amount AS PaiedAmount
        , PR_AdvanceRepayment.PaidInSalaryMainId
    FROM dbo.Acc_Currency
        INNER JOIN dbo.PR_Advance
            ON Acc_Currency.CurrencyId = PR_Advance.AdvanceAmountCurrency
        INNER JOIN dbo.PR_Employee
            ON PR_Advance.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department
            ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch
            ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT OUTER JOIN dbo.PR_AdvanceRepayment
            ON PR_AdvanceRepayment.AdvanceId = PR_Advance.AdvanceId
    WHERE PR_Advance.AdvanceId = @HeaderId',  N'@HeaderId INT, @IsArabic BIT',  'ADV', N'@HeaderId = @id, @IsArabic = @ar')
,('#PUR_LH', N'SELECT  PR_Employee.EmployeeId ,
						CASE WHEN @IsArabic = 1
						THEN CASE WHEN ( LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) ) = ''''
						THEN PR_Employee.EmployeeName
						ELSE PR_Employee.EmployeeArabicName
						END
						ELSE PR_Employee.EmployeeName
						END EmployeeName ,
						PR_Projects.ProjectName ,
						PR_Department.DepartmentName ,
						PR_Job.JobName ,
						PR_Branch.BranchName ,
						PR_Purchase.PurchaseAmount ,
						Acc_Currency.EnglishLetter ,
						Acc_Currency.ArabicLetter ,
						PR_Purchase.RequestDate ,
						PR_Purchase.PurchaseAmountCurrency ,
						PR_Purchase.Discription ,
						PR_Purchase.NoRepayment ,
						PR_Purchase.Accepted ,
						PR_Purchase.ApplayingStartDate ,
						PR_Purchase.ApproxEndDate ,
						PR_Purchase.Returned ,
						PR_Purchase.PurchaseId
						FROM    PR_Employee
						LEFT JOIN PR_Purchase ON PR_Purchase.EmployeeId = PR_Employee.EmployeeId
						LEFT OUTER JOIN Acc_Currency ON PR_Purchase.PurchaseAmountCurrency = Acc_Currency.CurrencyId
						LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
						LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
						LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
						LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
						WHERE   ( PR_Purchase.PurchaseId = @PurchaseId )
						AND @IsArabic = @IsArabic;', N'@PurchaseId INT, @IsArabic BIT', 'PUR', N'@PurchaseId = @id, @IsArabic = @ar')
,('#PUR_LR', N'SELECT  RepaymentId ,
        PurchaseId ,
        PaymentDate ,
        Amount ,
        PaidDate ,
        Paid ,
        PaiedAmount ,
        PaidInSalaryMainId
FROM    dbo.PR_PurchaseRepayment
WHERE   ( @PurchaseId IS NULL )
        OR ( PurchaseId IN (
             SELECT number
             FROM   dbo.iter$simple_intlist_to_tbl(@PurchaseId) ) )', N'@PurchaseId VARCHAR(1024)',      'PUR', N'@PurchaseId = @ids')
,('#PUR_N',  N'    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_PurchaseRepayment.RepaymentId) AS RowNo
        , PR_Purchase.PurchaseId
        , PR_Employee.EmployeeId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) = '''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Projects.ProjectName
        , PR_Department.DepartmentName
        , PR_Job.JobName
        , PR_Branch.BranchName
        , PR_Purchase.PurchaseAmount
        , PR_Purchase.PurchaseAmountCurrency
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.ArabicLetter ELSE Acc_Currency.EnglishLetter END AS CurrencyLetter
        , PR_Purchase.RequestDate
        , PR_Purchase.Discription
        , PR_Purchase.NoRepayment
        , PR_Purchase.Accepted
        , PR_Purchase.ApplayingStartDate
        , PR_Purchase.ApproxEndDate
        , PR_Purchase.Returned
        , PR_PurchaseRepayment.RepaymentId
        , PR_PurchaseRepayment.PaymentDate
        , PR_PurchaseRepayment.Amount
        , PR_PurchaseRepayment.PaidDate
        , PR_PurchaseRepayment.Paid
        , PR_PurchaseRepayment.PaiedAmount
        , PR_PurchaseRepayment.PaidInSalaryMainId
    FROM dbo.PR_Employee
        LEFT JOIN dbo.PR_Purchase
            ON PR_Purchase.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN dbo.Acc_Currency
            ON PR_Purchase.PurchaseAmountCurrency = Acc_Currency.CurrencyId
        LEFT JOIN dbo.PR_Projects
            ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Department
            ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT JOIN dbo.PR_Job
            ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Branch
            ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_PurchaseRepayment
            ON PR_PurchaseRepayment.PurchaseId = PR_Purchase.PurchaseId
    WHERE PR_Purchase.PurchaseId = @HeaderId',  N'@HeaderId INT, @IsArabic BIT',  'PUR', N'@HeaderId = @id, @IsArabic = @ar')
,('#PAY_L',  N'WITH defaultBank
AS (SELECT ROW_NUMBER() OVER (PARTITION BY EmployeeId ORDER BY EmployeeBankId) num,
           CurrencyId,
           EmployeeId,
           BankId,
           EmployeeBankId,
           dbo.PR_EmployeeBank.AccountNo,
           dbo.PR_EmployeeBank.IdentityNumber,
           dbo.PR_EmployeeBank.Description,
           dbo.PR_EmployeeBank.Address,
           dbo.PR_EmployeeBank.Branch,
           dbo.PR_EmployeeBank.Country,
           dbo.PR_EmployeeBank.AccountOwner,
           dbo.PR_EmployeeBank.SwiftCode
    FROM dbo.PR_EmployeeBank)
SELECT Pr_PayingSalaries.PayingSalariesId,
       PR_Bank.BankName,
       PR_TransactionType.TypeName,
       PR_TransactionType.TypeNameSecondLanguage,
       Pr_PayingSalaries.Serial,
       Pr_PayingSalaries.Description,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       TotalSalaries,
       PayingSalariesMonth,
       PayingSalaryYear,
       PayingSalariesDetailId,
       CASE
           WHEN @IsArabic = 1 THEN
               CASE
                   WHEN (LTRIM(RTRIM(PR_Employee.EmployeeArabicName))) = '''' THEN
                       PR_Employee.EmployeeName
                   ELSE
                       PR_Employee.EmployeeArabicName
               END
           ELSE
               PR_Employee.EmployeeName
       END EmployeeName,
       EmployeeSalary,
       PayingSalariesDate,
       PR_Employee.EmployeeArabicName,
       PR_Employee.EmployeeNumber,
       CAST(EmployeeNumber AS BIGINT) AS EmployeeNumberInt,
	   defaultBank.AccountNo
FROM Pr_PayingSalaries
    LEFT JOIN dbo.PR_Bank
        ON PR_Bank.BankId = Pr_PayingSalaries.BankId
    LEFT JOIN dbo.Acc_Currency
        ON Acc_Currency.CurrencyId = Pr_PayingSalaries.CurrencyId
    INNER JOIN Pr_PayingSalariesDetail
        ON Pr_PayingSalariesDetail.PayingSalariesId = Pr_PayingSalaries.PayingSalariesId
    LEFT JOIN dbo.PR_Employee
        ON PR_Employee.EmployeeId = Pr_PayingSalariesDetail.EmployeeId
    LEFT JOIN dbo.PR_TransactionType
        ON PR_TransactionType.TransactionTypeId = Pr_PayingSalaries.TransactionTypeId
    LEFT JOIN defaultBank
        ON defaultBank.EmployeeId = PR_Employee.EmployeeId
           AND defaultBank.num = 1
WHERE Pr_PayingSalaries.PayingSalariesId = @PayingSalariesId
      AND @IsArabic = @IsArabic;',  N'@PayingSalariesId INT, @IsArabic BIT', 'PAY', N'@PayingSalariesId = @id, @IsArabic = @ar')
,('#PAY_N',  N'    WITH defaultBank AS
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY EmployeeId ORDER BY EmployeeBankId) AS num
             , EmployeeId
             , AccountNo
        FROM dbo.PR_EmployeeBank
    )
    SELECT
          ROW_NUMBER() OVER (ORDER BY Pr_PayingSalariesDetail.PayingSalariesDetailId) AS RowNo
        , Pr_PayingSalaries.PayingSalariesId
        , PR_Bank.BankName
        , CASE WHEN @IsArabic = 1 THEN PR_TransactionType.TypeName ELSE PR_TransactionType.TypeNameSecondLanguage END AS TypeName
        , Pr_PayingSalaries.Serial
        , Pr_PayingSalaries.Description
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , Pr_PayingSalaries.TotalSalaries
        , Pr_PayingSalaries.PayingSalariesMonth
        , Pr_PayingSalaries.PayingSalaryYear
        , Pr_PayingSalaries.PayingSalariesDate
        , Pr_PayingSalariesDetail.PayingSalariesDetailId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) = '''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Employee.EmployeeNumber
        , Pr_PayingSalariesDetail.EmployeeSalary
        , defaultBank.AccountNo
    FROM dbo.Pr_PayingSalaries
        LEFT JOIN dbo.PR_Bank
            ON PR_Bank.BankId = Pr_PayingSalaries.BankId
        LEFT JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = Pr_PayingSalaries.CurrencyId
        INNER JOIN dbo.Pr_PayingSalariesDetail
            ON Pr_PayingSalariesDetail.PayingSalariesId = Pr_PayingSalaries.PayingSalariesId
        LEFT JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = Pr_PayingSalariesDetail.EmployeeId
        LEFT JOIN dbo.PR_TransactionType
            ON PR_TransactionType.TransactionTypeId = Pr_PayingSalaries.TransactionTypeId
        LEFT JOIN defaultBank
            ON defaultBank.EmployeeId = PR_Employee.EmployeeId
            AND defaultBank.num = 1
    WHERE Pr_PayingSalaries.PayingSalariesId = @HeaderId',  N'@HeaderId INT, @IsArabic BIT',  'PAY', N'@HeaderId = @id, @IsArabic = @ar')
,('#ACC_LH', N'				
						WITH    EmployeeContract
						AS ( SELECT   EmployeeId ,
						ContractStartDate
						FROM     dbo.PR_EmployeeContract
						WHERE    EmployeeId = @EmployeeId
						AND ContractEndDate IS NULL
						)
						SELECT  DISTINCT
						PR_Employee.EmployeeId ,
						Nationality ,
						CASE
						WHEN @isEnglish=0 THEN
						IIF(ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), '''') = ''''
						,  PR_Employee.EmployeeName, PR_Employee.EmployeeArabicName)
						ELSE  PR_Employee.EmployeeName END as EmployeeName  ,
						main.CurrencyId ,
						CASE WHEN @isEnglish = 0 THEN CurrencyNameArabic
						ELSE CurrencyName
						END CurrencyName ,
						0 AS WorkLengthInDays ,
						0 AS WorkLengthInMonthes ,
						0 AS WorkLengthInYear ,
						ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 4, 10, 11, 14 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalSalary ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalPaid ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId = 1
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalPreviousAccrued ,
						ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 2, 6, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalSeverancePackage ,
						ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 3, 5, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalVacationProvisioning ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId = 1
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 4, 10, 11, 14 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 3, 5, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 2, 6, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalAccural ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId = 1
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 4, 10, 11, 14 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 3, 5, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 2, 6, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						- ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS NetAccrual ,
						ISNULL(EmployeeContract.ContractStartDate,DateOfWork) AS StartDate
						FROM    dbo.PR_EmployeeTransactions main
						INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = main.EmployeeId
						INNER JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = main.CurrencyId
						LEFT JOIN dbo.PR_Nationality ON PR_Nationality.NationalityId = PR_Employee.NationalityId
						LEFT JOIN EmployeeContract ON EmployeeContract.EmployeeId = PR_Employee.EmployeeId
						WHERE   PR_Employee.EmployeeId = @EmployeeId
						AND @isEnglish = @isEnglish', N'@EmployeeId INT, @isEnglish BIT', 'ACC', N'@EmployeeId = @id, @isEnglish = @en')
,('#ACC_N',  N'    WITH EmployeeContract AS
    (
        SELECT EmployeeId
             , ContractStartDate
        FROM dbo.PR_EmployeeContract
        WHERE EmployeeId = @HeaderId
            AND ContractEndDate IS NULL
    ),
    CurrencyHeader AS
    (
        SELECT DISTINCT
              PR_Employee.EmployeeId
            , Nationality
            , CASE
                  WHEN @IsArabic = 1 THEN
                      IIF(ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), '''') = ''''
                          , PR_Employee.EmployeeName, PR_Employee.EmployeeArabicName)
                  ELSE PR_Employee.EmployeeName
              END AS EmployeeName
            , main.CurrencyId
            , CASE WHEN @IsArabic = 1 THEN CurrencyNameArabic ELSE CurrencyName END AS CurrencyName
            , ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 4, 10, 11, 14 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalSalary
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalPaid
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId = 1
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalPreviousAccrued
            , ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 2, 6, 10, 11 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalSeverancePackage
            , ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 3, 5, 10, 11 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalVacationProvisioning
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId = 1
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 4, 10, 11, 14 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 3, 5, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 2, 6, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0) AS TotalAccural
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId = 1
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 4, 10, 11, 14 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 3, 5, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 2, 6, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              - ISNULL(( SELECT SUM(TransactionAmount)
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0) AS NetAccrual
            , ISNULL(EmployeeContract.ContractStartDate, DateOfWork) AS StartDate
        FROM dbo.PR_EmployeeTransactions main
            INNER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = main.EmployeeId
            INNER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = main.CurrencyId
            LEFT JOIN dbo.PR_Nationality
                ON PR_Nationality.NationalityId = PR_Employee.NationalityId
            LEFT JOIN EmployeeContract
                ON EmployeeContract.EmployeeId = PR_Employee.EmployeeId
        WHERE PR_Employee.EmployeeId = @HeaderId
    ),
    Accruals AS
    (
        SELECT PR_EmployeeTransactions.EmployeeTransactionId
             , PR_EmployeeTransactions.TransactionTypeId
             , PR_EmployeeTransactions.CurrencyId
             , CASE
                   WHEN PR_EmployeeTransactions.IsAccrual = 1 THEN
                       CASE WHEN @IsArabic = 0 THEN N''Accrual'' ELSE N''مستحق'' END
                   ELSE
                       CASE WHEN @IsArabic = 0 THEN N''Paid'' ELSE N''صرف'' END
               END AS Accrual
             , PR_EmployeeTransactions.TransactionAmount
             , PR_EmployeeTransactions.TransactionDate
             , PR_EmployeeTransactions.Description
             , JournalSerial
             , PR_EmployeeTransactions.EmployeeId
             , CASE WHEN @IsArabic = 1 THEN TypeName ELSE TypeNameSecondLanguage END AS TypeName
        FROM dbo.PR_EmployeeTransactions
            INNER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_EmployeeTransactions.CurrencyId
            LEFT JOIN dbo.Acc_Journal
                ON Acc_Journal.GuidNumber = PR_EmployeeTransactions.JournalGuidNumber COLLATE DATABASE_DEFAULT
            INNER JOIN dbo.PR_TransactionType
                ON PR_TransactionType.TransactionTypeId = PR_EmployeeTransactions.TransactionTypeId
        WHERE PR_EmployeeTransactions.EmployeeId = @HeaderId
    )
    SELECT
          ROW_NUMBER() OVER (ORDER BY CurrencyHeader.CurrencyId, CurrencyHeader.StartDate
                                    , CONVERT(DATE, Accruals.TransactionDate) DESC, Accruals.EmployeeTransactionId DESC) AS RowNo
        , CurrencyHeader.EmployeeId
        , CurrencyHeader.Nationality
        , CurrencyHeader.EmployeeName
        , CurrencyHeader.CurrencyId
        , CurrencyHeader.CurrencyName
        , CurrencyHeader.StartDate
        , WorkLength.WorkLengthInYear
        , WorkLength.WorkLengthInMonthes
        , WorkLength.WorkLengthInDays
        , CurrencyHeader.TotalSalary
        , CurrencyHeader.TotalPaid
        , CurrencyHeader.TotalPreviousAccrued
        , CurrencyHeader.TotalSeverancePackage
        , CurrencyHeader.TotalVacationProvisioning
        , CurrencyHeader.TotalAccural
        , CurrencyHeader.NetAccrual
        , Accruals.EmployeeTransactionId
        , Accruals.TransactionTypeId
        , Accruals.TypeName
        , Accruals.Accrual
        , Accruals.TransactionAmount
        , Accruals.TransactionDate
        , Accruals.Description
        , Accruals.JournalSerial
    FROM CurrencyHeader
        LEFT JOIN Accruals
            ON Accruals.EmployeeId = CurrencyHeader.EmployeeId
            AND Accruals.CurrencyId = CurrencyHeader.CurrencyId
        -- Working period = legacy DateDifference(StartDate, now): day borrow uses the
        -- length of the earlier date''s month, then a month borrow, then years.
        CROSS APPLY
        (
            SELECT CASE WHEN CurrencyHeader.StartDate > GETDATE() THEN GETDATE() ELSE CurrencyHeader.StartDate END AS FromDate
                 , CASE WHEN CurrencyHeader.StartDate > GETDATE() THEN CurrencyHeader.StartDate ELSE GETDATE() END AS ToDate
        ) AS Period
        CROSS APPLY
        (
            SELECT CASE WHEN DAY(Period.FromDate) > DAY(Period.ToDate) THEN 1 ELSE 0 END AS DayBorrow
        ) AS DayStep
        CROSS APPLY
        (
            SELECT CASE WHEN MONTH(Period.FromDate) + DayStep.DayBorrow > MONTH(Period.ToDate) THEN 1 ELSE 0 END AS MonthBorrow
        ) AS MonthStep
        CROSS APPLY
        (
            SELECT YEAR(Period.ToDate) - (YEAR(Period.FromDate) + MonthStep.MonthBorrow) AS WorkLengthInYear
                 , MONTH(Period.ToDate) + 12 * MonthStep.MonthBorrow - (MONTH(Period.FromDate) + DayStep.DayBorrow) AS WorkLengthInMonthes
                 , DAY(Period.ToDate) + DayStep.DayBorrow * DAY(EOMONTH(Period.FromDate)) - DAY(Period.FromDate) AS WorkLengthInDays
        ) AS WorkLength',  N'@HeaderId INT, @IsArabic BIT',  'ACC', N'@HeaderId = @id, @IsArabic = @ar');
-- legacy repayment Fill() has no parameter: run once, the dataset relation filters by AdvanceId
DECLARE @advRepay NVARCHAR(MAX) = N'SELECT RepaymentId ,
       AdvanceId ,
       PaymentDate ,
       Amount ,
       PaidDate ,
       Paid ,
       Amount AS  PaiedAmount ,
       PaidInSalaryMainId FROM dbo.PR_AdvanceRepayment
	   LEFT OUTER JOIN dbo.PR_SalaryMain ON SalaryMainId=PaidInSalaryMainId';
DECLARE @accDetail NVARCHAR(MAX) = N'SELECT  PR_EmployeeTransactions.EmployeeTransactionId ,
        PR_EmployeeTransactions.TransactionTypeId ,
        PR_EmployeeTransactions.CurrencyId ,
        CASE WHEN PR_EmployeeTransactions.IsAccrual = 1
             THEN CASE WHEN @isEnglish = 1 THEN N''Accrual''
                       ELSE N''مستحق''
                  END
             ELSE CASE WHEN @isEnglish = 1 THEN N''Paid''
                       ELSE N''صرف''
                  END
        END AS Accrual ,
        PR_EmployeeTransactions.TransactionAmount ,
        PR_EmployeeTransactions.TransactionDate ,
        PR_EmployeeTransactions.Description ,
        PR_EmployeeTransactions.CreatedById ,
        PR_EmployeeTransactions.LastModifiedById ,
        PR_EmployeeTransactions.CreatedOn ,
        PR_EmployeeTransactions.LastModifiedOn ,
        CASE WHEN @isEnglish = 0 THEN CurrencyName
             ELSE CurrencyNameArabic
        END CurrencyName ,
        JournalSerial ,
        PR_EmployeeTransactions.EmployeeId ,
        CASE WHEN @isEnglish = 0 THEN TypeName
             ELSE TypeNameSecondLanguage
        END TypeName
FROM    dbo.PR_EmployeeTransactions
        INNER JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = PR_EmployeeTransactions.CurrencyId
        LEFT JOIN dbo.Acc_Journal ON Acc_Journal.GuidNumber = PR_EmployeeTransactions.JournalGuidNumber COLLATE DATABASE_DEFAULT
        INNER JOIN dbo.PR_TransactionType ON PR_TransactionType.TransactionTypeId = PR_EmployeeTransactions.TransactionTypeId
WHERE   PR_EmployeeTransactions.EmployeeId = @EmployeeId
        AND @isEnglish = @isEnglish
        AND PR_EmployeeTransactions.CurrencyId = @CurrencyId
ORDER BY CONVERT(DATE, TransactionDate) DESC ,
        EmployeeTransactionId DESC';
INSERT INTO @t (Tbl, Q, Prm, Print_, Call) VALUES ('#ADV_LR', @advRepay, N'', 'ADV1', N''), ('#ACC_LD', @accDetail, N'@EmployeeId INT, @isEnglish BIT, @CurrencyId INT', 'ACCD', N'@EmployeeId = @id, @isEnglish = @en, @CurrencyId = @cur');

DECLARE @tbl SYSNAME, @pr VARCHAR(10), @call NVARCHAR(400);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Tbl, Q, Prm, Print_, Call FROM @t ORDER BY Ord;
OPEN c; FETCH NEXT FROM c INTO @tbl, @q, @prm, @pr, @call;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @cols = STRING_AGG(CAST(QUOTENAME(name) + N' ' + system_type_name + N' NULL' AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY column_ordinal)
         , @names = STRING_AGG(CAST(QUOTENAME(name) AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY column_ordinal)
    FROM sys.dm_exec_describe_first_result_set(@q, NULLIF(@prm, N''), 0);
    EXEC (N'ALTER TABLE ' + @tbl + N' ADD ' + @cols);
    SET @run = N'INSERT INTO ' + @tbl + N' (' + @names + N') EXEC sp_executesql @q, @prm' + IIF(@call = N'', N'', N', ' + @call) + N';'
             + N' UPDATE ' + @tbl + N' SET P_Id = @id, P_IsArabic = @ar, P_Cur = @cur WHERE P_Id IS NULL;';
    IF @pr = 'ADV1'
        EXEC sp_executesql @run, N'@q NVARCHAR(MAX), @prm NVARCHAR(MAX), @id INT, @ar BIT, @cur INT', @q, N'', 0, 0, NULL;
    ELSE IF @pr = 'ACCD'
    BEGIN
        DECLARE @id INT, @ar BIT, @cur INT;
        DECLARE d CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT P_Id, P_IsArabic, CurrencyId FROM #ACC_LH;
        OPEN d; FETCH NEXT FROM d INTO @id, @ar, @cur;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @en2 BIT = IIF(@ar = 1, 0, 1);
            EXEC sp_executesql @run, N'@q NVARCHAR(MAX), @prm NVARCHAR(MAX), @id INT, @ar BIT, @en BIT, @cur INT', @q, @prm, @id, @ar, @en2, @cur;
            FETCH NEXT FROM d INTO @id, @ar, @cur;
        END
        CLOSE d; DEALLOCATE d;
    END
    ELSE
    BEGIN
        DECLARE @pid INT, @par BIT;
        DECLARE p CURSOR LOCAL FAST_FORWARD FOR SELECT Id, IsArabic FROM #P WHERE Print_ = @pr;
        OPEN p; FETCH NEXT FROM p INTO @pid, @par;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- @en = NOT IsArabic: the legacy accrual adapters take !isArabic
            DECLARE @en BIT = IIF(@par = 1, 0, 1), @ids VARCHAR(1024) = CAST(@pid AS VARCHAR(20));
            EXEC sp_executesql @run, N'@q NVARCHAR(MAX), @prm NVARCHAR(MAX), @id INT, @ar BIT, @en BIT, @ids VARCHAR(1024), @cur INT', @q, @prm, @pid, @par, @en, @ids, NULL;
            FETCH NEXT FROM p INTO @pid, @par;
        END
        CLOSE p; DEALLOCATE p;
    END
    FETCH NEXT FROM c INTO @tbl, @q, @prm, @pr, @call;
END
CLOSE c; DEALLOCATE c;
GO
-- ===== C# step for print 8: DateDifference(StartDate, DateTime.Now), independent port (monthDay[] + IsLeapYear) =====
DECLARE @now DATETIME = GETDATE();
CREATE TABLE #MD (m INT, d INT);
INSERT INTO #MD VALUES (1,31),(2,-1),(3,31),(4,30),(5,31),(6,30),(7,31),(8,31),(9,30),(10,31),(11,30),(12,31);
UPDATE h SET WorkLengthInDays = e.dd, WorkLengthInMonthes = g.mm, WorkLengthInYear = k.yy
FROM #ACC_LH h
    CROSS APPLY (SELECT IIF(h.StartDate > @now, @now, h.StartDate) AS f, IIF(h.StartDate > @now, h.StartDate, @now) AS t) a
    CROSS APPLY (SELECT CASE WHEN DAY(a.f) > DAY(a.t) THEN (SELECT d FROM #MD WHERE m = MONTH(a.f)) ELSE 0 END AS inc0) b
    CROSS APPLY (SELECT CASE WHEN b.inc0 = -1 THEN CASE WHEN (YEAR(a.f) % 4 = 0 AND YEAR(a.f) % 100 <> 0) OR YEAR(a.f) % 400 = 0 THEN 29 ELSE 28 END ELSE b.inc0 END AS inc) c2
    CROSS APPLY (SELECT CASE WHEN c2.inc <> 0 THEN DAY(a.t) + c2.inc - DAY(a.f) ELSE DAY(a.t) - DAY(a.f) END AS dd, IIF(c2.inc <> 0, 1, 0) AS i1) e
    CROSS APPLY (SELECT CASE WHEN MONTH(a.f) + e.i1 > MONTH(a.t) THEN MONTH(a.t) + 12 - (MONTH(a.f) + e.i1) ELSE MONTH(a.t) - (MONTH(a.f) + e.i1) END AS mm
                      , IIF(MONTH(a.f) + e.i1 > MONTH(a.t), 1, 0) AS i2) g
    CROSS APPLY (SELECT YEAR(a.t) - (YEAR(a.f) + g.i2) AS yy) k;
GO
-- ===== legacy (C# applied) vs new, per print =====
SELECT * INTO #ADV_L FROM (
    SELECT h.P_Id, h.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY h.P_Id, h.P_IsArabic ORDER BY r.RepaymentId) AS RowNo
         , h.AdvanceId, h.EmployeeId, h.EmployeeName, h.EmployeeNumber, h.Age, h.DepartmentName, h.BranchName
         , h.AdvanceAmount, h.AdvanceAmountCurrency
         , IIF(h.P_IsArabic = 1, cu.ArabicLetter, h.EnglishLetter) AS CurrencyLetter
         , h.Discription, h.NoRepayment, h.Approved, h.ApplayingStartDate, h.ApproxEndDate, h.Returned, h.IsAdvance, h.RequestDate
         , r.RepaymentId, r.PaymentDate, r.Amount, r.PaidDate, r.Paid, r.PaiedAmount, r.PaidInSalaryMainId
    FROM #ADV_LH h
        LEFT JOIN dbo.Acc_Currency cu ON cu.CurrencyId = h.AdvanceAmountCurrency
        LEFT JOIN #ADV_LR r ON r.AdvanceId = h.AdvanceId) x;
SELECT * INTO #PUR_L FROM (
    SELECT h.P_Id, h.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY h.P_Id, h.P_IsArabic ORDER BY r.RepaymentId) AS RowNo
         , h.PurchaseId, h.EmployeeId, h.EmployeeName, h.ProjectName, h.DepartmentName, h.JobName, h.BranchName
         , h.PurchaseAmount, h.PurchaseAmountCurrency
         , IIF(h.P_IsArabic = 1, h.ArabicLetter, h.EnglishLetter) AS CurrencyLetter
         , h.RequestDate, h.Discription, h.NoRepayment, h.Accepted, h.ApplayingStartDate, h.ApproxEndDate, h.Returned
         , r.RepaymentId, r.PaymentDate, r.Amount, r.PaidDate, r.Paid, r.PaiedAmount, r.PaidInSalaryMainId
    FROM #PUR_LH h
        LEFT JOIN #PUR_LR r ON r.PurchaseId = h.PurchaseId AND r.P_Id = h.P_Id AND r.P_IsArabic = h.P_IsArabic) x;
SELECT * INTO #PAY_LX FROM (
    SELECT l.P_Id, l.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY l.P_Id, l.P_IsArabic ORDER BY l.PayingSalariesDetailId) AS RowNo
         , l.PayingSalariesId, l.BankName
         , IIF(l.P_IsArabic = 1, l.TypeName, l.TypeNameSecondLanguage) AS TypeName
         , l.Serial, l.Description
         , IIF(l.P_IsArabic = 1, l.CurrencyNameArabic, l.CurrencyName) AS CurrencyName
         , l.TotalSalaries, l.PayingSalariesMonth, l.PayingSalaryYear, l.PayingSalariesDate, l.PayingSalariesDetailId
         , l.EmployeeName, l.EmployeeNumber, l.EmployeeSalary, l.AccountNo
    FROM #PAY_L l) x;
SELECT * INTO #ACC_L FROM (
    SELECT h.P_Id, h.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY h.P_Id, h.P_IsArabic ORDER BY h.CurrencyId, h.StartDate, CONVERT(DATE, d.TransactionDate) DESC, d.EmployeeTransactionId DESC) AS RowNo
         , h.EmployeeId, h.Nationality, h.EmployeeName, h.CurrencyId, h.CurrencyName, h.StartDate
         , h.WorkLengthInYear, h.WorkLengthInMonthes, h.WorkLengthInDays
         , h.TotalSalary, h.TotalPaid, h.TotalPreviousAccrued, h.TotalSeverancePackage, h.TotalVacationProvisioning, h.TotalAccural, h.NetAccrual
         , d.EmployeeTransactionId, d.TransactionTypeId, d.TypeName, d.Accrual, d.TransactionAmount, d.TransactionDate, d.Description, d.JournalSerial
    FROM #ACC_LH h
        LEFT JOIN #ACC_LD d ON d.P_Id = h.P_Id AND d.P_IsArabic = h.P_IsArabic AND d.EmployeeId = h.EmployeeId AND d.CurrencyId = h.CurrencyId) x;

-- the new side, same column order (P_Cur dropped)
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.AdvanceId, n.EmployeeId, n.EmployeeName, n.EmployeeNumber, n.Age, n.DepartmentName, n.BranchName, n.AdvanceAmount, n.AdvanceAmountCurrency, n.CurrencyLetter, n.Discription, n.NoRepayment, n.Approved, n.ApplayingStartDate, n.ApproxEndDate, n.Returned, n.IsAdvance, n.RequestDate, n.RepaymentId, n.PaymentDate, n.Amount, n.PaidDate, n.Paid, n.PaiedAmount, n.PaidInSalaryMainId
INTO #ADV_NX FROM #ADV_N n;
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.PurchaseId, n.EmployeeId, n.EmployeeName, n.ProjectName, n.DepartmentName, n.JobName, n.BranchName, n.PurchaseAmount, n.PurchaseAmountCurrency, n.CurrencyLetter, n.RequestDate, n.Discription, n.NoRepayment, n.Accepted, n.ApplayingStartDate, n.ApproxEndDate, n.Returned, n.RepaymentId, n.PaymentDate, n.Amount, n.PaidDate, n.Paid, n.PaiedAmount, n.PaidInSalaryMainId
INTO #PUR_NX FROM #PUR_N n;
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.PayingSalariesId, n.BankName, n.TypeName, n.Serial, n.Description, n.CurrencyName, n.TotalSalaries, n.PayingSalariesMonth, n.PayingSalaryYear, n.PayingSalariesDate, n.PayingSalariesDetailId, n.EmployeeName, n.EmployeeNumber, n.EmployeeSalary, n.AccountNo
INTO #PAY_NX FROM #PAY_N n;
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.EmployeeId, n.Nationality, n.EmployeeName, n.CurrencyId, n.CurrencyName, n.StartDate, n.WorkLengthInYear, n.WorkLengthInMonthes, n.WorkLengthInDays, n.TotalSalary, n.TotalPaid, n.TotalPreviousAccrued, n.TotalSeverancePackage, n.TotalVacationProvisioning, n.TotalAccural, n.NetAccrual, n.EmployeeTransactionId, n.TransactionTypeId, n.TypeName, n.Accrual, n.TransactionAmount, n.TransactionDate, n.Description, n.JournalSerial
INTO #ACC_NX FROM #ACC_N n;
GO
SELECT x.Print_, x.Id, x.IsArabic
     , LegacyRows = CASE x.Print_ WHEN 'ADV' THEN (SELECT COUNT(*) FROM #ADV_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                                  WHEN 'PUR' THEN (SELECT COUNT(*) FROM #PUR_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                                  WHEN 'PAY' THEN (SELECT COUNT(*) FROM #PAY_LX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                                  ELSE (SELECT COUNT(*) FROM #ACC_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic) END
     , NewRows = CASE x.Print_ WHEN 'ADV' THEN (SELECT COUNT(*) FROM #ADV_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                               WHEN 'PUR' THEN (SELECT COUNT(*) FROM #PUR_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                               WHEN 'PAY' THEN (SELECT COUNT(*) FROM #PAY_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                               ELSE (SELECT COUNT(*) FROM #ACC_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic) END
     , LegacyNotInNew = CASE x.Print_
           WHEN 'ADV' THEN (SELECT COUNT(*) FROM (SELECT * FROM #ADV_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ADV_NX) e)
           WHEN 'PUR' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PUR_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PUR_NX) e)
           WHEN 'PAY' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PAY_LX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PAY_NX) e)
           ELSE (SELECT COUNT(*) FROM (SELECT * FROM #ACC_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ACC_NX) e) END
     , NewNotInLegacy = CASE x.Print_
           WHEN 'ADV' THEN (SELECT COUNT(*) FROM (SELECT * FROM #ADV_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ADV_L) e)
           WHEN 'PUR' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PUR_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PUR_L) e)
           WHEN 'PAY' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PAY_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PAY_LX) e)
           ELSE (SELECT COUNT(*) FROM (SELECT * FROM #ACC_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ACC_L) e) END
FROM #P x
ORDER BY x.Print_, x.Id, x.IsArabic;

-- advance: legacy prints EnglishLetter in both languages; rows where the D10 CurrencyLetter differs from it
SELECT 'ADV CurrencyLetter vs legacy EnglishLetter' AS Info, n.P_Id, n.P_IsArabic, COUNT(*) AS RowsDiffering
FROM #ADV_NX n JOIN #ADV_LH h ON h.P_Id = n.P_Id AND h.P_IsArabic = n.P_IsArabic
WHERE ISNULL(n.CurrencyLetter, N'') <> ISNULL(h.EnglishLetter, N'')
GROUP BY n.P_Id, n.P_IsArabic;

-- 7a: legacy shows CurrencyNameArabic when English and CurrencyName when Arabic (inverted, D10 fixes it)
SELECT TOP 2 'PAY legacy inverted currency' AS Info, P_IsArabic, CurrencyName, CurrencyNameArabic FROM #PAY_L;

-- 8: totals vs the Payroll screen (GetEmployeeTransactionHeaderQuery: separate sums per currency)
SELECT 'ACC screen totals' AS Info, h.P_Id, h.CurrencyId
     , h.TotalSalary, s.TotalSalary AS ScreenTotalSalary
     , h.TotalPaid, s.TotalPaid AS ScreenTotalPaid
     , h.TotalPreviousAccrued, s.TotalPreviousAccrued AS ScreenTotalPreviousAccrued
     , h.TotalSeverancePackage, s.TotalSeverancePackage AS ScreenTotalSeverancePackage
     , h.TotalVacationProvisioning, s.TotalVacationProvisioning AS ScreenTotalVacationProvisioning
     , h.TotalAccural, s.TotalPreviousAccrued + s.TotalSalary + s.TotalVacationProvisioning + s.TotalSeverancePackage AS ScreenTotalAccural
     , h.NetAccrual, s.TotalPreviousAccrued + s.TotalSalary + s.TotalVacationProvisioning + s.TotalSeverancePackage - s.TotalPaid AS ScreenNetAccrual
     , Mismatch = IIF(h.TotalSalary = s.TotalSalary AND h.TotalPaid = s.TotalPaid AND h.TotalPreviousAccrued = s.TotalPreviousAccrued
                      AND h.TotalSeverancePackage = s.TotalSeverancePackage AND h.TotalVacationProvisioning = s.TotalVacationProvisioning, 0, 1)
FROM (SELECT DISTINCT P_Id, CurrencyId, TotalSalary, TotalPaid, TotalPreviousAccrued, TotalSeverancePackage, TotalVacationProvisioning, TotalAccural, NetAccrual FROM #ACC_NX WHERE P_IsArabic = 0) h
    CROSS APPLY (
        SELECT SUM(IIF(t.TransactionTypeId IN (4, 14), t.TransactionAmount, 0)) + SUM(IIF(t.TransactionTypeId IN (10, 11), ISNULL(t.SalaryAmount, 0), 0)) AS TotalSalary
             , SUM(IIF(t.TransactionTypeId IN (7, 8, 9, 12, 13, 15), t.TransactionAmount, 0)) AS TotalPaid
             , SUM(IIF(t.TransactionTypeId = 1, t.TransactionAmount, 0)) AS TotalPreviousAccrued
             , SUM(IIF(t.TransactionTypeId IN (2, 6), t.TransactionAmount, 0)) + SUM(IIF(t.TransactionTypeId IN (10, 11), ISNULL(t.SeverancePackageAmount, 0), 0)) AS TotalSeverancePackage
             , SUM(IIF(t.TransactionTypeId IN (3, 5), t.TransactionAmount, 0)) + SUM(IIF(t.TransactionTypeId IN (10, 11), ISNULL(t.VacationAllowanceAmount, 0), 0)) AS TotalVacationProvisioning
        FROM dbo.PR_EmployeeTransactions t
        WHERE t.EmployeeId = h.P_Id AND t.CurrencyId = h.CurrencyId) s;

-- 8: working-period formula from the TVF (extracted text) vs the independent DateDifference port, synthetic dates
;WITH Starts AS (SELECT DATEADD(DAY, n, CAST('2019-12-25T08:30:00' AS DATETIME)) AS StartDate
                 FROM (SELECT TOP (2600) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) - 1 AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b) z),
     Nows AS (SELECT CAST(v AS DATETIME) AS NowDate FROM (VALUES ('2024-02-29T10:00:00'), ('2024-03-01T00:00:00'), ('2025-02-28T23:00:00'), ('2025-03-31T09:00:00'), ('2026-01-01T12:00:00'), ('2026-10-15T12:00:00'), ('2026-12-31T08:00:00')) v(v)),
     S AS (SELECT StartDate, NowDate FROM Starts CROSS JOIN Nows),
     NewWL AS (
        SELECT S.StartDate, S.NowDate, WorkLength.WorkLengthInYear, WorkLength.WorkLengthInMonthes, WorkLength.WorkLengthInDays
        FROM S
        CROSS APPLY
        (
            SELECT CASE WHEN S.StartDate > S.NowDate THEN S.NowDate ELSE S.StartDate END AS FromDate
                 , CASE WHEN S.StartDate > S.NowDate THEN S.StartDate ELSE S.NowDate END AS ToDate
        ) AS Period
        CROSS APPLY
        (
            SELECT CASE WHEN DAY(Period.FromDate) > DAY(Period.ToDate) THEN 1 ELSE 0 END AS DayBorrow
        ) AS DayStep
        CROSS APPLY
        (
            SELECT CASE WHEN MONTH(Period.FromDate) + DayStep.DayBorrow > MONTH(Period.ToDate) THEN 1 ELSE 0 END AS MonthBorrow
        ) AS MonthStep
        CROSS APPLY
        (
            SELECT YEAR(Period.ToDate) - (YEAR(Period.FromDate) + MonthStep.MonthBorrow) AS WorkLengthInYear
                 , MONTH(Period.ToDate) + 12 * MonthStep.MonthBorrow - (MONTH(Period.FromDate) + DayStep.DayBorrow) AS WorkLengthInMonthes
                 , DAY(Period.ToDate) + DayStep.DayBorrow * DAY(EOMONTH(Period.FromDate)) - DAY(Period.FromDate) AS WorkLengthInDays
        ) AS WorkLength
     ),
     LegacyWL AS (
        SELECT S.StartDate, S.NowDate, k.yy, g.mm, e.dd
        FROM S
            CROSS APPLY (SELECT IIF(S.StartDate > S.NowDate, S.NowDate, S.StartDate) AS f, IIF(S.StartDate > S.NowDate, S.StartDate, S.NowDate) AS t) a
            CROSS APPLY (SELECT CASE WHEN DAY(a.f) > DAY(a.t) THEN (SELECT d FROM #MD WHERE m = MONTH(a.f)) ELSE 0 END AS inc0) b
            CROSS APPLY (SELECT CASE WHEN b.inc0 = -1 THEN CASE WHEN (YEAR(a.f) % 4 = 0 AND YEAR(a.f) % 100 <> 0) OR YEAR(a.f) % 400 = 0 THEN 29 ELSE 28 END ELSE b.inc0 END AS inc) c2
            CROSS APPLY (SELECT CASE WHEN c2.inc <> 0 THEN DAY(a.t) + c2.inc - DAY(a.f) ELSE DAY(a.t) - DAY(a.f) END AS dd, IIF(c2.inc <> 0, 1, 0) AS i1) e
            CROSS APPLY (SELECT CASE WHEN MONTH(a.f) + e.i1 > MONTH(a.t) THEN MONTH(a.t) + 12 - (MONTH(a.f) + e.i1) ELSE MONTH(a.t) - (MONTH(a.f) + e.i1) END AS mm
                              , IIF(MONTH(a.f) + e.i1 > MONTH(a.t), 1, 0) AS i2) g
            CROSS APPLY (SELECT YEAR(a.t) - (YEAR(a.f) + g.i2) AS yy) k
     )
SELECT 'WorkLength synthetic' AS Info
     , (SELECT COUNT(*) FROM S) AS Cases
     , (SELECT COUNT(*) FROM (SELECT * FROM NewWL EXCEPT SELECT * FROM LegacyWL) x) AS NewNotInLegacy
     , (SELECT COUNT(*) FROM (SELECT * FROM LegacyWL EXCEPT SELECT * FROM NewWL) x) AS LegacyNotInNew;
GO
-- ################ ERP_MainDB-Ali ################
USE [ERP_MainDB-Ali];
GO
DROP TABLE IF EXISTS #P;
DROP TABLE IF EXISTS #ADV_LH;
DROP TABLE IF EXISTS #ADV_LR;
DROP TABLE IF EXISTS #ADV_N;
DROP TABLE IF EXISTS #PUR_LH;
DROP TABLE IF EXISTS #PUR_LR;
DROP TABLE IF EXISTS #PUR_N;
DROP TABLE IF EXISTS #PAY_L;
DROP TABLE IF EXISTS #PAY_N;
DROP TABLE IF EXISTS #ACC_LH;
DROP TABLE IF EXISTS #ACC_LD;
DROP TABLE IF EXISTS #ACC_N;
DROP TABLE IF EXISTS #MD;
DROP TABLE IF EXISTS #ADV_L;
DROP TABLE IF EXISTS #PUR_L;
DROP TABLE IF EXISTS #PAY_LX;
DROP TABLE IF EXISTS #ACC_L;
DROP TABLE IF EXISTS #ADV_NX;
DROP TABLE IF EXISTS #PUR_NX;
DROP TABLE IF EXISTS #PAY_NX;
DROP TABLE IF EXISTS #ACC_NX;
GO
CREATE TABLE #P (Print_ VARCHAR(10), Id INT, IsArabic BIT);
-- every header id on the tenant plus -1 (no data), x IsArabic 0/1
INSERT INTO #P
SELECT h.Print_, h.Id, l.IsArabic
FROM (SELECT 'ADV' AS Print_, AdvanceId AS Id FROM dbo.PR_Advance
      UNION SELECT 'PUR', PurchaseId FROM dbo.PR_Purchase
      UNION SELECT 'PAY', PayingSalariesId FROM dbo.Pr_PayingSalaries
      UNION SELECT DISTINCT 'ACC', EmployeeId FROM dbo.PR_EmployeeTransactions
      UNION SELECT p, -1 FROM (VALUES ('ADV'), ('PUR'), ('PAY'), ('ACC')) v(p)) h
    CROSS JOIN (VALUES (CAST(0 AS BIT)), (CAST(1 AS BIT))) l(IsArabic);
GO
-- ===== shape + fill: each #X gets P_Id, P_IsArabic, P_Cur and the query's own columns =====
-- (#tables are created here, in the outer scope, so the dynamic ALTER/INSERT below keep them)
CREATE TABLE #ADV_LH (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ADV_LR (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ADV_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PUR_LH (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PUR_LR (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PUR_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PAY_L (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #PAY_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ACC_LH (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ACC_LD (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
CREATE TABLE #ACC_N (P_Id INT NULL, P_IsArabic BIT NULL, P_Cur INT NULL);
DECLARE @q NVARCHAR(MAX), @prm NVARCHAR(MAX), @cols NVARCHAR(MAX), @names NVARCHAR(MAX), @run NVARCHAR(MAX);
DECLARE @t TABLE (Ord INT IDENTITY(1, 1), Tbl SYSNAME, Q NVARCHAR(MAX), Prm NVARCHAR(MAX), Print_ VARCHAR(10), Call NVARCHAR(400));
INSERT INTO @t (Tbl, Q, Prm, Print_, Call) VALUES
 ('#ADV_LH', N'SELECT  PR_Employee.EmployeeId ,
        CASE WHEN @IsArabic = 1
                 THEN CASE WHEN ( LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) ) = ''''
                           THEN PR_Employee.EmployeeName
                           ELSE PR_Employee.EmployeeArabicName
                      END
                 ELSE PR_Employee.EmployeeName
            END EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Advance.AdvanceAmount ,
        Acc_Currency.EnglishLetter ,
        PR_Advance.AdvanceAmountCurrency ,
        PR_Advance.Discription ,
        PR_Advance.NoRepayment ,
        PR_Advance.Approved ,
        PR_Advance.ApplayingStartDate ,
        PR_Advance.ApproxEndDate ,
        PR_Advance.Returned ,
        PR_Advance.IsAdvance ,
        PR_Advance.AdvanceId ,
        dbo.PR_Employee.Age ,
        RequestDate ,
        dbo.PR_Department.DepartmentName ,
        dbo.PR_Branch.BranchName ,
        EmployeeArabicName
FROM    Acc_Currency
        INNER JOIN PR_Advance ON Acc_Currency.CurrencyId = PR_Advance.AdvanceAmountCurrency
        INNER JOIN PR_Employee ON PR_Advance.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
WHERE   AdvanceId = @AdvanceId AND (@IsArabic = @IsArabic);', N'@AdvanceId INT, @IsArabic BIT', 'ADV', N'@AdvanceId = @id, @IsArabic = @ar')
,('#ADV_N',  N'    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_AdvanceRepayment.RepaymentId) AS RowNo
        , PR_Advance.AdvanceId
        , PR_Employee.EmployeeId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) = '''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Employee.EmployeeNumber
        , PR_Employee.Age
        , PR_Department.DepartmentName
        , PR_Branch.BranchName
        , PR_Advance.AdvanceAmount
        , PR_Advance.AdvanceAmountCurrency
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.ArabicLetter ELSE Acc_Currency.EnglishLetter END AS CurrencyLetter
        , PR_Advance.Discription
        , PR_Advance.NoRepayment
        , PR_Advance.Approved
        , PR_Advance.ApplayingStartDate
        , PR_Advance.ApproxEndDate
        , PR_Advance.Returned
        , PR_Advance.IsAdvance
        , PR_Advance.RequestDate
        , PR_AdvanceRepayment.RepaymentId
        , PR_AdvanceRepayment.PaymentDate
        , PR_AdvanceRepayment.Amount
        , PR_AdvanceRepayment.PaidDate
        , PR_AdvanceRepayment.Paid
        -- legacy print shows the scheduled Amount as the paid amount
        , PR_AdvanceRepayment.Amount AS PaiedAmount
        , PR_AdvanceRepayment.PaidInSalaryMainId
    FROM dbo.Acc_Currency
        INNER JOIN dbo.PR_Advance
            ON Acc_Currency.CurrencyId = PR_Advance.AdvanceAmountCurrency
        INNER JOIN dbo.PR_Employee
            ON PR_Advance.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN dbo.PR_Department
            ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT OUTER JOIN dbo.PR_Branch
            ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT OUTER JOIN dbo.PR_AdvanceRepayment
            ON PR_AdvanceRepayment.AdvanceId = PR_Advance.AdvanceId
    WHERE PR_Advance.AdvanceId = @HeaderId',  N'@HeaderId INT, @IsArabic BIT',  'ADV', N'@HeaderId = @id, @IsArabic = @ar')
,('#PUR_LH', N'SELECT  PR_Employee.EmployeeId ,
						CASE WHEN @IsArabic = 1
						THEN CASE WHEN ( LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) ) = ''''
						THEN PR_Employee.EmployeeName
						ELSE PR_Employee.EmployeeArabicName
						END
						ELSE PR_Employee.EmployeeName
						END EmployeeName ,
						PR_Projects.ProjectName ,
						PR_Department.DepartmentName ,
						PR_Job.JobName ,
						PR_Branch.BranchName ,
						PR_Purchase.PurchaseAmount ,
						Acc_Currency.EnglishLetter ,
						Acc_Currency.ArabicLetter ,
						PR_Purchase.RequestDate ,
						PR_Purchase.PurchaseAmountCurrency ,
						PR_Purchase.Discription ,
						PR_Purchase.NoRepayment ,
						PR_Purchase.Accepted ,
						PR_Purchase.ApplayingStartDate ,
						PR_Purchase.ApproxEndDate ,
						PR_Purchase.Returned ,
						PR_Purchase.PurchaseId
						FROM    PR_Employee
						LEFT JOIN PR_Purchase ON PR_Purchase.EmployeeId = PR_Employee.EmployeeId
						LEFT OUTER JOIN Acc_Currency ON PR_Purchase.PurchaseAmountCurrency = Acc_Currency.CurrencyId
						LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
						LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
						LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
						LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
						WHERE   ( PR_Purchase.PurchaseId = @PurchaseId )
						AND @IsArabic = @IsArabic;', N'@PurchaseId INT, @IsArabic BIT', 'PUR', N'@PurchaseId = @id, @IsArabic = @ar')
,('#PUR_LR', N'SELECT  RepaymentId ,
        PurchaseId ,
        PaymentDate ,
        Amount ,
        PaidDate ,
        Paid ,
        PaiedAmount ,
        PaidInSalaryMainId
FROM    dbo.PR_PurchaseRepayment
WHERE   ( @PurchaseId IS NULL )
        OR ( PurchaseId IN (
             SELECT number
             FROM   dbo.iter$simple_intlist_to_tbl(@PurchaseId) ) )', N'@PurchaseId VARCHAR(1024)',      'PUR', N'@PurchaseId = @ids')
,('#PUR_N',  N'    SELECT
          ROW_NUMBER() OVER (ORDER BY PR_PurchaseRepayment.RepaymentId) AS RowNo
        , PR_Purchase.PurchaseId
        , PR_Employee.EmployeeId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) = '''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Projects.ProjectName
        , PR_Department.DepartmentName
        , PR_Job.JobName
        , PR_Branch.BranchName
        , PR_Purchase.PurchaseAmount
        , PR_Purchase.PurchaseAmountCurrency
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.ArabicLetter ELSE Acc_Currency.EnglishLetter END AS CurrencyLetter
        , PR_Purchase.RequestDate
        , PR_Purchase.Discription
        , PR_Purchase.NoRepayment
        , PR_Purchase.Accepted
        , PR_Purchase.ApplayingStartDate
        , PR_Purchase.ApproxEndDate
        , PR_Purchase.Returned
        , PR_PurchaseRepayment.RepaymentId
        , PR_PurchaseRepayment.PaymentDate
        , PR_PurchaseRepayment.Amount
        , PR_PurchaseRepayment.PaidDate
        , PR_PurchaseRepayment.Paid
        , PR_PurchaseRepayment.PaiedAmount
        , PR_PurchaseRepayment.PaidInSalaryMainId
    FROM dbo.PR_Employee
        LEFT JOIN dbo.PR_Purchase
            ON PR_Purchase.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN dbo.Acc_Currency
            ON PR_Purchase.PurchaseAmountCurrency = Acc_Currency.CurrencyId
        LEFT JOIN dbo.PR_Projects
            ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Department
            ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT JOIN dbo.PR_Job
            ON PR_Job.JobId = PR_Employee.JobId
        LEFT JOIN dbo.PR_Branch
            ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_PurchaseRepayment
            ON PR_PurchaseRepayment.PurchaseId = PR_Purchase.PurchaseId
    WHERE PR_Purchase.PurchaseId = @HeaderId',  N'@HeaderId INT, @IsArabic BIT',  'PUR', N'@HeaderId = @id, @IsArabic = @ar')
,('#PAY_L',  N'WITH defaultBank
AS (SELECT ROW_NUMBER() OVER (PARTITION BY EmployeeId ORDER BY EmployeeBankId) num,
           CurrencyId,
           EmployeeId,
           BankId,
           EmployeeBankId,
           dbo.PR_EmployeeBank.AccountNo,
           dbo.PR_EmployeeBank.IdentityNumber,
           dbo.PR_EmployeeBank.Description,
           dbo.PR_EmployeeBank.Address,
           dbo.PR_EmployeeBank.Branch,
           dbo.PR_EmployeeBank.Country,
           dbo.PR_EmployeeBank.AccountOwner,
           dbo.PR_EmployeeBank.SwiftCode
    FROM dbo.PR_EmployeeBank)
SELECT Pr_PayingSalaries.PayingSalariesId,
       PR_Bank.BankName,
       PR_TransactionType.TypeName,
       PR_TransactionType.TypeNameSecondLanguage,
       Pr_PayingSalaries.Serial,
       Pr_PayingSalaries.Description,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       TotalSalaries,
       PayingSalariesMonth,
       PayingSalaryYear,
       PayingSalariesDetailId,
       CASE
           WHEN @IsArabic = 1 THEN
               CASE
                   WHEN (LTRIM(RTRIM(PR_Employee.EmployeeArabicName))) = '''' THEN
                       PR_Employee.EmployeeName
                   ELSE
                       PR_Employee.EmployeeArabicName
               END
           ELSE
               PR_Employee.EmployeeName
       END EmployeeName,
       EmployeeSalary,
       PayingSalariesDate,
       PR_Employee.EmployeeArabicName,
       PR_Employee.EmployeeNumber,
       CAST(EmployeeNumber AS BIGINT) AS EmployeeNumberInt,
	   defaultBank.AccountNo
FROM Pr_PayingSalaries
    LEFT JOIN dbo.PR_Bank
        ON PR_Bank.BankId = Pr_PayingSalaries.BankId
    LEFT JOIN dbo.Acc_Currency
        ON Acc_Currency.CurrencyId = Pr_PayingSalaries.CurrencyId
    INNER JOIN Pr_PayingSalariesDetail
        ON Pr_PayingSalariesDetail.PayingSalariesId = Pr_PayingSalaries.PayingSalariesId
    LEFT JOIN dbo.PR_Employee
        ON PR_Employee.EmployeeId = Pr_PayingSalariesDetail.EmployeeId
    LEFT JOIN dbo.PR_TransactionType
        ON PR_TransactionType.TransactionTypeId = Pr_PayingSalaries.TransactionTypeId
    LEFT JOIN defaultBank
        ON defaultBank.EmployeeId = PR_Employee.EmployeeId
           AND defaultBank.num = 1
WHERE Pr_PayingSalaries.PayingSalariesId = @PayingSalariesId
      AND @IsArabic = @IsArabic;',  N'@PayingSalariesId INT, @IsArabic BIT', 'PAY', N'@PayingSalariesId = @id, @IsArabic = @ar')
,('#PAY_N',  N'    WITH defaultBank AS
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY EmployeeId ORDER BY EmployeeBankId) AS num
             , EmployeeId
             , AccountNo
        FROM dbo.PR_EmployeeBank
    )
    SELECT
          ROW_NUMBER() OVER (ORDER BY Pr_PayingSalariesDetail.PayingSalariesDetailId) AS RowNo
        , Pr_PayingSalaries.PayingSalariesId
        , PR_Bank.BankName
        , CASE WHEN @IsArabic = 1 THEN PR_TransactionType.TypeName ELSE PR_TransactionType.TypeNameSecondLanguage END AS TypeName
        , Pr_PayingSalaries.Serial
        , Pr_PayingSalaries.Description
        , CASE WHEN @IsArabic = 1 THEN Acc_Currency.CurrencyNameArabic ELSE Acc_Currency.CurrencyName END AS CurrencyName
        , Pr_PayingSalaries.TotalSalaries
        , Pr_PayingSalaries.PayingSalariesMonth
        , Pr_PayingSalaries.PayingSalaryYear
        , Pr_PayingSalaries.PayingSalariesDate
        , Pr_PayingSalariesDetail.PayingSalariesDetailId
        , CASE
              WHEN @IsArabic = 1 THEN
                  CASE
                      WHEN LTRIM(RTRIM(PR_Employee.EmployeeArabicName)) = '''' THEN PR_Employee.EmployeeName
                      ELSE PR_Employee.EmployeeArabicName
                  END
              ELSE PR_Employee.EmployeeName
          END AS EmployeeName
        , PR_Employee.EmployeeNumber
        , Pr_PayingSalariesDetail.EmployeeSalary
        , defaultBank.AccountNo
    FROM dbo.Pr_PayingSalaries
        LEFT JOIN dbo.PR_Bank
            ON PR_Bank.BankId = Pr_PayingSalaries.BankId
        LEFT JOIN dbo.Acc_Currency
            ON Acc_Currency.CurrencyId = Pr_PayingSalaries.CurrencyId
        INNER JOIN dbo.Pr_PayingSalariesDetail
            ON Pr_PayingSalariesDetail.PayingSalariesId = Pr_PayingSalaries.PayingSalariesId
        LEFT JOIN dbo.PR_Employee
            ON PR_Employee.EmployeeId = Pr_PayingSalariesDetail.EmployeeId
        LEFT JOIN dbo.PR_TransactionType
            ON PR_TransactionType.TransactionTypeId = Pr_PayingSalaries.TransactionTypeId
        LEFT JOIN defaultBank
            ON defaultBank.EmployeeId = PR_Employee.EmployeeId
            AND defaultBank.num = 1
    WHERE Pr_PayingSalaries.PayingSalariesId = @HeaderId',  N'@HeaderId INT, @IsArabic BIT',  'PAY', N'@HeaderId = @id, @IsArabic = @ar')
,('#ACC_LH', N'				
						WITH    EmployeeContract
						AS ( SELECT   EmployeeId ,
						ContractStartDate
						FROM     dbo.PR_EmployeeContract
						WHERE    EmployeeId = @EmployeeId
						AND ContractEndDate IS NULL
						)
						SELECT  DISTINCT
						PR_Employee.EmployeeId ,
						Nationality ,
						CASE
						WHEN @isEnglish=0 THEN
						IIF(ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), '''') = ''''
						,  PR_Employee.EmployeeName, PR_Employee.EmployeeArabicName)
						ELSE  PR_Employee.EmployeeName END as EmployeeName  ,
						main.CurrencyId ,
						CASE WHEN @isEnglish = 0 THEN CurrencyNameArabic
						ELSE CurrencyName
						END CurrencyName ,
						0 AS WorkLengthInDays ,
						0 AS WorkLengthInMonthes ,
						0 AS WorkLengthInYear ,
						ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 4, 10, 11, 14 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalSalary ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalPaid ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId = 1
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalPreviousAccrued ,
						ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 2, 6, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalSeverancePackage ,
						ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 3, 5, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalVacationProvisioning ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId = 1
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 4, 10, 11, 14 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 3, 5, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 2, 6, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS TotalAccural ,
						ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId = 1
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 4, 10, 11, 14 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 3, 5, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						+ ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 2, 6, 10, 11 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0)
						- ISNULL(( SELECT SUM(TransactionAmount)
						FROM   PR_EmployeeTransactions
						WHERE  TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
						AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
						AND EmployeeId = @EmployeeId
						), 0) AS NetAccrual ,
						ISNULL(EmployeeContract.ContractStartDate,DateOfWork) AS StartDate
						FROM    dbo.PR_EmployeeTransactions main
						INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = main.EmployeeId
						INNER JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = main.CurrencyId
						LEFT JOIN dbo.PR_Nationality ON PR_Nationality.NationalityId = PR_Employee.NationalityId
						LEFT JOIN EmployeeContract ON EmployeeContract.EmployeeId = PR_Employee.EmployeeId
						WHERE   PR_Employee.EmployeeId = @EmployeeId
						AND @isEnglish = @isEnglish', N'@EmployeeId INT, @isEnglish BIT', 'ACC', N'@EmployeeId = @id, @isEnglish = @en')
,('#ACC_N',  N'    WITH EmployeeContract AS
    (
        SELECT EmployeeId
             , ContractStartDate
        FROM dbo.PR_EmployeeContract
        WHERE EmployeeId = @HeaderId
            AND ContractEndDate IS NULL
    ),
    CurrencyHeader AS
    (
        SELECT DISTINCT
              PR_Employee.EmployeeId
            , Nationality
            , CASE
                  WHEN @IsArabic = 1 THEN
                      IIF(ISNULL(LTRIM(RTRIM(PR_Employee.EmployeeArabicName)), '''') = ''''
                          , PR_Employee.EmployeeName, PR_Employee.EmployeeArabicName)
                  ELSE PR_Employee.EmployeeName
              END AS EmployeeName
            , main.CurrencyId
            , CASE WHEN @IsArabic = 1 THEN CurrencyNameArabic ELSE CurrencyName END AS CurrencyName
            , ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 4, 10, 11, 14 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalSalary
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalPaid
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId = 1
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalPreviousAccrued
            , ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 2, 6, 10, 11 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalSeverancePackage
            , ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId IN ( 3, 5, 10, 11 )
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0) AS TotalVacationProvisioning
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId = 1
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 4, 10, 11, 14 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 3, 5, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 2, 6, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0) AS TotalAccural
            , ISNULL(( SELECT SUM(TransactionAmount)
                       FROM PR_EmployeeTransactions
                       WHERE TransactionTypeId = 1
                           AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                           AND EmployeeId = @HeaderId
                     ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 4, 14 ), TransactionAmount, SalaryAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 4, 10, 11, 14 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 3, 5 ), TransactionAmount, VacationAllowanceAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 3, 5, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              + ISNULL(( SELECT SUM(IIF(TransactionTypeId IN ( 2, 6 ), TransactionAmount, SeverancePackageAmount))
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 2, 6, 10, 11 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0)
              - ISNULL(( SELECT SUM(TransactionAmount)
                         FROM PR_EmployeeTransactions
                         WHERE TransactionTypeId IN ( 7, 8, 9, 12, 13, 15 )
                             AND PR_EmployeeTransactions.CurrencyId = main.CurrencyId
                             AND EmployeeId = @HeaderId
                       ), 0) AS NetAccrual
            , ISNULL(EmployeeContract.ContractStartDate, DateOfWork) AS StartDate
        FROM dbo.PR_EmployeeTransactions main
            INNER JOIN dbo.PR_Employee
                ON PR_Employee.EmployeeId = main.EmployeeId
            INNER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = main.CurrencyId
            LEFT JOIN dbo.PR_Nationality
                ON PR_Nationality.NationalityId = PR_Employee.NationalityId
            LEFT JOIN EmployeeContract
                ON EmployeeContract.EmployeeId = PR_Employee.EmployeeId
        WHERE PR_Employee.EmployeeId = @HeaderId
    ),
    Accruals AS
    (
        SELECT PR_EmployeeTransactions.EmployeeTransactionId
             , PR_EmployeeTransactions.TransactionTypeId
             , PR_EmployeeTransactions.CurrencyId
             , CASE
                   WHEN PR_EmployeeTransactions.IsAccrual = 1 THEN
                       CASE WHEN @IsArabic = 0 THEN N''Accrual'' ELSE N''مستحق'' END
                   ELSE
                       CASE WHEN @IsArabic = 0 THEN N''Paid'' ELSE N''صرف'' END
               END AS Accrual
             , PR_EmployeeTransactions.TransactionAmount
             , PR_EmployeeTransactions.TransactionDate
             , PR_EmployeeTransactions.Description
             , JournalSerial
             , PR_EmployeeTransactions.EmployeeId
             , CASE WHEN @IsArabic = 1 THEN TypeName ELSE TypeNameSecondLanguage END AS TypeName
        FROM dbo.PR_EmployeeTransactions
            INNER JOIN dbo.Acc_Currency
                ON Acc_Currency.CurrencyId = PR_EmployeeTransactions.CurrencyId
            LEFT JOIN dbo.Acc_Journal
                ON Acc_Journal.GuidNumber = PR_EmployeeTransactions.JournalGuidNumber COLLATE DATABASE_DEFAULT
            INNER JOIN dbo.PR_TransactionType
                ON PR_TransactionType.TransactionTypeId = PR_EmployeeTransactions.TransactionTypeId
        WHERE PR_EmployeeTransactions.EmployeeId = @HeaderId
    )
    SELECT
          ROW_NUMBER() OVER (ORDER BY CurrencyHeader.CurrencyId, CurrencyHeader.StartDate
                                    , CONVERT(DATE, Accruals.TransactionDate) DESC, Accruals.EmployeeTransactionId DESC) AS RowNo
        , CurrencyHeader.EmployeeId
        , CurrencyHeader.Nationality
        , CurrencyHeader.EmployeeName
        , CurrencyHeader.CurrencyId
        , CurrencyHeader.CurrencyName
        , CurrencyHeader.StartDate
        , WorkLength.WorkLengthInYear
        , WorkLength.WorkLengthInMonthes
        , WorkLength.WorkLengthInDays
        , CurrencyHeader.TotalSalary
        , CurrencyHeader.TotalPaid
        , CurrencyHeader.TotalPreviousAccrued
        , CurrencyHeader.TotalSeverancePackage
        , CurrencyHeader.TotalVacationProvisioning
        , CurrencyHeader.TotalAccural
        , CurrencyHeader.NetAccrual
        , Accruals.EmployeeTransactionId
        , Accruals.TransactionTypeId
        , Accruals.TypeName
        , Accruals.Accrual
        , Accruals.TransactionAmount
        , Accruals.TransactionDate
        , Accruals.Description
        , Accruals.JournalSerial
    FROM CurrencyHeader
        LEFT JOIN Accruals
            ON Accruals.EmployeeId = CurrencyHeader.EmployeeId
            AND Accruals.CurrencyId = CurrencyHeader.CurrencyId
        -- Working period = legacy DateDifference(StartDate, now): day borrow uses the
        -- length of the earlier date''s month, then a month borrow, then years.
        CROSS APPLY
        (
            SELECT CASE WHEN CurrencyHeader.StartDate > GETDATE() THEN GETDATE() ELSE CurrencyHeader.StartDate END AS FromDate
                 , CASE WHEN CurrencyHeader.StartDate > GETDATE() THEN CurrencyHeader.StartDate ELSE GETDATE() END AS ToDate
        ) AS Period
        CROSS APPLY
        (
            SELECT CASE WHEN DAY(Period.FromDate) > DAY(Period.ToDate) THEN 1 ELSE 0 END AS DayBorrow
        ) AS DayStep
        CROSS APPLY
        (
            SELECT CASE WHEN MONTH(Period.FromDate) + DayStep.DayBorrow > MONTH(Period.ToDate) THEN 1 ELSE 0 END AS MonthBorrow
        ) AS MonthStep
        CROSS APPLY
        (
            SELECT YEAR(Period.ToDate) - (YEAR(Period.FromDate) + MonthStep.MonthBorrow) AS WorkLengthInYear
                 , MONTH(Period.ToDate) + 12 * MonthStep.MonthBorrow - (MONTH(Period.FromDate) + DayStep.DayBorrow) AS WorkLengthInMonthes
                 , DAY(Period.ToDate) + DayStep.DayBorrow * DAY(EOMONTH(Period.FromDate)) - DAY(Period.FromDate) AS WorkLengthInDays
        ) AS WorkLength',  N'@HeaderId INT, @IsArabic BIT',  'ACC', N'@HeaderId = @id, @IsArabic = @ar');
-- legacy repayment Fill() has no parameter: run once, the dataset relation filters by AdvanceId
DECLARE @advRepay NVARCHAR(MAX) = N'SELECT RepaymentId ,
       AdvanceId ,
       PaymentDate ,
       Amount ,
       PaidDate ,
       Paid ,
       Amount AS  PaiedAmount ,
       PaidInSalaryMainId FROM dbo.PR_AdvanceRepayment
	   LEFT OUTER JOIN dbo.PR_SalaryMain ON SalaryMainId=PaidInSalaryMainId';
DECLARE @accDetail NVARCHAR(MAX) = N'SELECT  PR_EmployeeTransactions.EmployeeTransactionId ,
        PR_EmployeeTransactions.TransactionTypeId ,
        PR_EmployeeTransactions.CurrencyId ,
        CASE WHEN PR_EmployeeTransactions.IsAccrual = 1
             THEN CASE WHEN @isEnglish = 1 THEN N''Accrual''
                       ELSE N''مستحق''
                  END
             ELSE CASE WHEN @isEnglish = 1 THEN N''Paid''
                       ELSE N''صرف''
                  END
        END AS Accrual ,
        PR_EmployeeTransactions.TransactionAmount ,
        PR_EmployeeTransactions.TransactionDate ,
        PR_EmployeeTransactions.Description ,
        PR_EmployeeTransactions.CreatedById ,
        PR_EmployeeTransactions.LastModifiedById ,
        PR_EmployeeTransactions.CreatedOn ,
        PR_EmployeeTransactions.LastModifiedOn ,
        CASE WHEN @isEnglish = 0 THEN CurrencyName
             ELSE CurrencyNameArabic
        END CurrencyName ,
        JournalSerial ,
        PR_EmployeeTransactions.EmployeeId ,
        CASE WHEN @isEnglish = 0 THEN TypeName
             ELSE TypeNameSecondLanguage
        END TypeName
FROM    dbo.PR_EmployeeTransactions
        INNER JOIN dbo.Acc_Currency ON Acc_Currency.CurrencyId = PR_EmployeeTransactions.CurrencyId
        LEFT JOIN dbo.Acc_Journal ON Acc_Journal.GuidNumber = PR_EmployeeTransactions.JournalGuidNumber COLLATE DATABASE_DEFAULT
        INNER JOIN dbo.PR_TransactionType ON PR_TransactionType.TransactionTypeId = PR_EmployeeTransactions.TransactionTypeId
WHERE   PR_EmployeeTransactions.EmployeeId = @EmployeeId
        AND @isEnglish = @isEnglish
        AND PR_EmployeeTransactions.CurrencyId = @CurrencyId
ORDER BY CONVERT(DATE, TransactionDate) DESC ,
        EmployeeTransactionId DESC';
INSERT INTO @t (Tbl, Q, Prm, Print_, Call) VALUES ('#ADV_LR', @advRepay, N'', 'ADV1', N''), ('#ACC_LD', @accDetail, N'@EmployeeId INT, @isEnglish BIT, @CurrencyId INT', 'ACCD', N'@EmployeeId = @id, @isEnglish = @en, @CurrencyId = @cur');

DECLARE @tbl SYSNAME, @pr VARCHAR(10), @call NVARCHAR(400);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Tbl, Q, Prm, Print_, Call FROM @t ORDER BY Ord;
OPEN c; FETCH NEXT FROM c INTO @tbl, @q, @prm, @pr, @call;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @cols = STRING_AGG(CAST(QUOTENAME(name) + N' ' + system_type_name + N' NULL' AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY column_ordinal)
         , @names = STRING_AGG(CAST(QUOTENAME(name) AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY column_ordinal)
    FROM sys.dm_exec_describe_first_result_set(@q, NULLIF(@prm, N''), 0);
    EXEC (N'ALTER TABLE ' + @tbl + N' ADD ' + @cols);
    SET @run = N'INSERT INTO ' + @tbl + N' (' + @names + N') EXEC sp_executesql @q, @prm' + IIF(@call = N'', N'', N', ' + @call) + N';'
             + N' UPDATE ' + @tbl + N' SET P_Id = @id, P_IsArabic = @ar, P_Cur = @cur WHERE P_Id IS NULL;';
    IF @pr = 'ADV1'
        EXEC sp_executesql @run, N'@q NVARCHAR(MAX), @prm NVARCHAR(MAX), @id INT, @ar BIT, @cur INT', @q, N'', 0, 0, NULL;
    ELSE IF @pr = 'ACCD'
    BEGIN
        DECLARE @id INT, @ar BIT, @cur INT;
        DECLARE d CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT P_Id, P_IsArabic, CurrencyId FROM #ACC_LH;
        OPEN d; FETCH NEXT FROM d INTO @id, @ar, @cur;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @en2 BIT = IIF(@ar = 1, 0, 1);
            EXEC sp_executesql @run, N'@q NVARCHAR(MAX), @prm NVARCHAR(MAX), @id INT, @ar BIT, @en BIT, @cur INT', @q, @prm, @id, @ar, @en2, @cur;
            FETCH NEXT FROM d INTO @id, @ar, @cur;
        END
        CLOSE d; DEALLOCATE d;
    END
    ELSE
    BEGIN
        DECLARE @pid INT, @par BIT;
        DECLARE p CURSOR LOCAL FAST_FORWARD FOR SELECT Id, IsArabic FROM #P WHERE Print_ = @pr;
        OPEN p; FETCH NEXT FROM p INTO @pid, @par;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- @en = NOT IsArabic: the legacy accrual adapters take !isArabic
            DECLARE @en BIT = IIF(@par = 1, 0, 1), @ids VARCHAR(1024) = CAST(@pid AS VARCHAR(20));
            EXEC sp_executesql @run, N'@q NVARCHAR(MAX), @prm NVARCHAR(MAX), @id INT, @ar BIT, @en BIT, @ids VARCHAR(1024), @cur INT', @q, @prm, @pid, @par, @en, @ids, NULL;
            FETCH NEXT FROM p INTO @pid, @par;
        END
        CLOSE p; DEALLOCATE p;
    END
    FETCH NEXT FROM c INTO @tbl, @q, @prm, @pr, @call;
END
CLOSE c; DEALLOCATE c;
GO
-- ===== C# step for print 8: DateDifference(StartDate, DateTime.Now), independent port (monthDay[] + IsLeapYear) =====
DECLARE @now DATETIME = GETDATE();
CREATE TABLE #MD (m INT, d INT);
INSERT INTO #MD VALUES (1,31),(2,-1),(3,31),(4,30),(5,31),(6,30),(7,31),(8,31),(9,30),(10,31),(11,30),(12,31);
UPDATE h SET WorkLengthInDays = e.dd, WorkLengthInMonthes = g.mm, WorkLengthInYear = k.yy
FROM #ACC_LH h
    CROSS APPLY (SELECT IIF(h.StartDate > @now, @now, h.StartDate) AS f, IIF(h.StartDate > @now, h.StartDate, @now) AS t) a
    CROSS APPLY (SELECT CASE WHEN DAY(a.f) > DAY(a.t) THEN (SELECT d FROM #MD WHERE m = MONTH(a.f)) ELSE 0 END AS inc0) b
    CROSS APPLY (SELECT CASE WHEN b.inc0 = -1 THEN CASE WHEN (YEAR(a.f) % 4 = 0 AND YEAR(a.f) % 100 <> 0) OR YEAR(a.f) % 400 = 0 THEN 29 ELSE 28 END ELSE b.inc0 END AS inc) c2
    CROSS APPLY (SELECT CASE WHEN c2.inc <> 0 THEN DAY(a.t) + c2.inc - DAY(a.f) ELSE DAY(a.t) - DAY(a.f) END AS dd, IIF(c2.inc <> 0, 1, 0) AS i1) e
    CROSS APPLY (SELECT CASE WHEN MONTH(a.f) + e.i1 > MONTH(a.t) THEN MONTH(a.t) + 12 - (MONTH(a.f) + e.i1) ELSE MONTH(a.t) - (MONTH(a.f) + e.i1) END AS mm
                      , IIF(MONTH(a.f) + e.i1 > MONTH(a.t), 1, 0) AS i2) g
    CROSS APPLY (SELECT YEAR(a.t) - (YEAR(a.f) + g.i2) AS yy) k;
GO
-- ===== legacy (C# applied) vs new, per print =====
SELECT * INTO #ADV_L FROM (
    SELECT h.P_Id, h.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY h.P_Id, h.P_IsArabic ORDER BY r.RepaymentId) AS RowNo
         , h.AdvanceId, h.EmployeeId, h.EmployeeName, h.EmployeeNumber, h.Age, h.DepartmentName, h.BranchName
         , h.AdvanceAmount, h.AdvanceAmountCurrency
         , IIF(h.P_IsArabic = 1, cu.ArabicLetter, h.EnglishLetter) AS CurrencyLetter
         , h.Discription, h.NoRepayment, h.Approved, h.ApplayingStartDate, h.ApproxEndDate, h.Returned, h.IsAdvance, h.RequestDate
         , r.RepaymentId, r.PaymentDate, r.Amount, r.PaidDate, r.Paid, r.PaiedAmount, r.PaidInSalaryMainId
    FROM #ADV_LH h
        LEFT JOIN dbo.Acc_Currency cu ON cu.CurrencyId = h.AdvanceAmountCurrency
        LEFT JOIN #ADV_LR r ON r.AdvanceId = h.AdvanceId) x;
SELECT * INTO #PUR_L FROM (
    SELECT h.P_Id, h.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY h.P_Id, h.P_IsArabic ORDER BY r.RepaymentId) AS RowNo
         , h.PurchaseId, h.EmployeeId, h.EmployeeName, h.ProjectName, h.DepartmentName, h.JobName, h.BranchName
         , h.PurchaseAmount, h.PurchaseAmountCurrency
         , IIF(h.P_IsArabic = 1, h.ArabicLetter, h.EnglishLetter) AS CurrencyLetter
         , h.RequestDate, h.Discription, h.NoRepayment, h.Accepted, h.ApplayingStartDate, h.ApproxEndDate, h.Returned
         , r.RepaymentId, r.PaymentDate, r.Amount, r.PaidDate, r.Paid, r.PaiedAmount, r.PaidInSalaryMainId
    FROM #PUR_LH h
        LEFT JOIN #PUR_LR r ON r.PurchaseId = h.PurchaseId AND r.P_Id = h.P_Id AND r.P_IsArabic = h.P_IsArabic) x;
SELECT * INTO #PAY_LX FROM (
    SELECT l.P_Id, l.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY l.P_Id, l.P_IsArabic ORDER BY l.PayingSalariesDetailId) AS RowNo
         , l.PayingSalariesId, l.BankName
         , IIF(l.P_IsArabic = 1, l.TypeName, l.TypeNameSecondLanguage) AS TypeName
         , l.Serial, l.Description
         , IIF(l.P_IsArabic = 1, l.CurrencyNameArabic, l.CurrencyName) AS CurrencyName
         , l.TotalSalaries, l.PayingSalariesMonth, l.PayingSalaryYear, l.PayingSalariesDate, l.PayingSalariesDetailId
         , l.EmployeeName, l.EmployeeNumber, l.EmployeeSalary, l.AccountNo
    FROM #PAY_L l) x;
SELECT * INTO #ACC_L FROM (
    SELECT h.P_Id, h.P_IsArabic
         , ROW_NUMBER() OVER (PARTITION BY h.P_Id, h.P_IsArabic ORDER BY h.CurrencyId, h.StartDate, CONVERT(DATE, d.TransactionDate) DESC, d.EmployeeTransactionId DESC) AS RowNo
         , h.EmployeeId, h.Nationality, h.EmployeeName, h.CurrencyId, h.CurrencyName, h.StartDate
         , h.WorkLengthInYear, h.WorkLengthInMonthes, h.WorkLengthInDays
         , h.TotalSalary, h.TotalPaid, h.TotalPreviousAccrued, h.TotalSeverancePackage, h.TotalVacationProvisioning, h.TotalAccural, h.NetAccrual
         , d.EmployeeTransactionId, d.TransactionTypeId, d.TypeName, d.Accrual, d.TransactionAmount, d.TransactionDate, d.Description, d.JournalSerial
    FROM #ACC_LH h
        LEFT JOIN #ACC_LD d ON d.P_Id = h.P_Id AND d.P_IsArabic = h.P_IsArabic AND d.EmployeeId = h.EmployeeId AND d.CurrencyId = h.CurrencyId) x;

-- the new side, same column order (P_Cur dropped)
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.AdvanceId, n.EmployeeId, n.EmployeeName, n.EmployeeNumber, n.Age, n.DepartmentName, n.BranchName, n.AdvanceAmount, n.AdvanceAmountCurrency, n.CurrencyLetter, n.Discription, n.NoRepayment, n.Approved, n.ApplayingStartDate, n.ApproxEndDate, n.Returned, n.IsAdvance, n.RequestDate, n.RepaymentId, n.PaymentDate, n.Amount, n.PaidDate, n.Paid, n.PaiedAmount, n.PaidInSalaryMainId
INTO #ADV_NX FROM #ADV_N n;
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.PurchaseId, n.EmployeeId, n.EmployeeName, n.ProjectName, n.DepartmentName, n.JobName, n.BranchName, n.PurchaseAmount, n.PurchaseAmountCurrency, n.CurrencyLetter, n.RequestDate, n.Discription, n.NoRepayment, n.Accepted, n.ApplayingStartDate, n.ApproxEndDate, n.Returned, n.RepaymentId, n.PaymentDate, n.Amount, n.PaidDate, n.Paid, n.PaiedAmount, n.PaidInSalaryMainId
INTO #PUR_NX FROM #PUR_N n;
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.PayingSalariesId, n.BankName, n.TypeName, n.Serial, n.Description, n.CurrencyName, n.TotalSalaries, n.PayingSalariesMonth, n.PayingSalaryYear, n.PayingSalariesDate, n.PayingSalariesDetailId, n.EmployeeName, n.EmployeeNumber, n.EmployeeSalary, n.AccountNo
INTO #PAY_NX FROM #PAY_N n;
SELECT n.P_Id, n.P_IsArabic, n.RowNo, n.EmployeeId, n.Nationality, n.EmployeeName, n.CurrencyId, n.CurrencyName, n.StartDate, n.WorkLengthInYear, n.WorkLengthInMonthes, n.WorkLengthInDays, n.TotalSalary, n.TotalPaid, n.TotalPreviousAccrued, n.TotalSeverancePackage, n.TotalVacationProvisioning, n.TotalAccural, n.NetAccrual, n.EmployeeTransactionId, n.TransactionTypeId, n.TypeName, n.Accrual, n.TransactionAmount, n.TransactionDate, n.Description, n.JournalSerial
INTO #ACC_NX FROM #ACC_N n;
GO
SELECT x.Print_, x.Id, x.IsArabic
     , LegacyRows = CASE x.Print_ WHEN 'ADV' THEN (SELECT COUNT(*) FROM #ADV_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                                  WHEN 'PUR' THEN (SELECT COUNT(*) FROM #PUR_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                                  WHEN 'PAY' THEN (SELECT COUNT(*) FROM #PAY_LX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                                  ELSE (SELECT COUNT(*) FROM #ACC_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic) END
     , NewRows = CASE x.Print_ WHEN 'ADV' THEN (SELECT COUNT(*) FROM #ADV_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                               WHEN 'PUR' THEN (SELECT COUNT(*) FROM #PUR_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                               WHEN 'PAY' THEN (SELECT COUNT(*) FROM #PAY_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic)
                               ELSE (SELECT COUNT(*) FROM #ACC_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic) END
     , LegacyNotInNew = CASE x.Print_
           WHEN 'ADV' THEN (SELECT COUNT(*) FROM (SELECT * FROM #ADV_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ADV_NX) e)
           WHEN 'PUR' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PUR_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PUR_NX) e)
           WHEN 'PAY' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PAY_LX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PAY_NX) e)
           ELSE (SELECT COUNT(*) FROM (SELECT * FROM #ACC_L WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ACC_NX) e) END
     , NewNotInLegacy = CASE x.Print_
           WHEN 'ADV' THEN (SELECT COUNT(*) FROM (SELECT * FROM #ADV_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ADV_L) e)
           WHEN 'PUR' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PUR_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PUR_L) e)
           WHEN 'PAY' THEN (SELECT COUNT(*) FROM (SELECT * FROM #PAY_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #PAY_LX) e)
           ELSE (SELECT COUNT(*) FROM (SELECT * FROM #ACC_NX WHERE P_Id = x.Id AND P_IsArabic = x.IsArabic EXCEPT SELECT * FROM #ACC_L) e) END
FROM #P x
ORDER BY x.Print_, x.Id, x.IsArabic;

-- advance: legacy prints EnglishLetter in both languages; rows where the D10 CurrencyLetter differs from it
SELECT 'ADV CurrencyLetter vs legacy EnglishLetter' AS Info, n.P_Id, n.P_IsArabic, COUNT(*) AS RowsDiffering
FROM #ADV_NX n JOIN #ADV_LH h ON h.P_Id = n.P_Id AND h.P_IsArabic = n.P_IsArabic
WHERE ISNULL(n.CurrencyLetter, N'') <> ISNULL(h.EnglishLetter, N'')
GROUP BY n.P_Id, n.P_IsArabic;

-- 7a: legacy shows CurrencyNameArabic when English and CurrencyName when Arabic (inverted, D10 fixes it)
SELECT TOP 2 'PAY legacy inverted currency' AS Info, P_IsArabic, CurrencyName, CurrencyNameArabic FROM #PAY_L;

-- 8: totals vs the Payroll screen (GetEmployeeTransactionHeaderQuery: separate sums per currency)
SELECT 'ACC screen totals' AS Info, h.P_Id, h.CurrencyId
     , h.TotalSalary, s.TotalSalary AS ScreenTotalSalary
     , h.TotalPaid, s.TotalPaid AS ScreenTotalPaid
     , h.TotalPreviousAccrued, s.TotalPreviousAccrued AS ScreenTotalPreviousAccrued
     , h.TotalSeverancePackage, s.TotalSeverancePackage AS ScreenTotalSeverancePackage
     , h.TotalVacationProvisioning, s.TotalVacationProvisioning AS ScreenTotalVacationProvisioning
     , h.TotalAccural, s.TotalPreviousAccrued + s.TotalSalary + s.TotalVacationProvisioning + s.TotalSeverancePackage AS ScreenTotalAccural
     , h.NetAccrual, s.TotalPreviousAccrued + s.TotalSalary + s.TotalVacationProvisioning + s.TotalSeverancePackage - s.TotalPaid AS ScreenNetAccrual
     , Mismatch = IIF(h.TotalSalary = s.TotalSalary AND h.TotalPaid = s.TotalPaid AND h.TotalPreviousAccrued = s.TotalPreviousAccrued
                      AND h.TotalSeverancePackage = s.TotalSeverancePackage AND h.TotalVacationProvisioning = s.TotalVacationProvisioning, 0, 1)
FROM (SELECT DISTINCT P_Id, CurrencyId, TotalSalary, TotalPaid, TotalPreviousAccrued, TotalSeverancePackage, TotalVacationProvisioning, TotalAccural, NetAccrual FROM #ACC_NX WHERE P_IsArabic = 0) h
    CROSS APPLY (
        SELECT SUM(IIF(t.TransactionTypeId IN (4, 14), t.TransactionAmount, 0)) + SUM(IIF(t.TransactionTypeId IN (10, 11), ISNULL(t.SalaryAmount, 0), 0)) AS TotalSalary
             , SUM(IIF(t.TransactionTypeId IN (7, 8, 9, 12, 13, 15), t.TransactionAmount, 0)) AS TotalPaid
             , SUM(IIF(t.TransactionTypeId = 1, t.TransactionAmount, 0)) AS TotalPreviousAccrued
             , SUM(IIF(t.TransactionTypeId IN (2, 6), t.TransactionAmount, 0)) + SUM(IIF(t.TransactionTypeId IN (10, 11), ISNULL(t.SeverancePackageAmount, 0), 0)) AS TotalSeverancePackage
             , SUM(IIF(t.TransactionTypeId IN (3, 5), t.TransactionAmount, 0)) + SUM(IIF(t.TransactionTypeId IN (10, 11), ISNULL(t.VacationAllowanceAmount, 0), 0)) AS TotalVacationProvisioning
        FROM dbo.PR_EmployeeTransactions t
        WHERE t.EmployeeId = h.P_Id AND t.CurrencyId = h.CurrencyId) s;

-- 8: working-period formula from the TVF (extracted text) vs the independent DateDifference port, synthetic dates
;WITH Starts AS (SELECT DATEADD(DAY, n, CAST('2019-12-25T08:30:00' AS DATETIME)) AS StartDate
                 FROM (SELECT TOP (2600) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) - 1 AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b) z),
     Nows AS (SELECT CAST(v AS DATETIME) AS NowDate FROM (VALUES ('2024-02-29T10:00:00'), ('2024-03-01T00:00:00'), ('2025-02-28T23:00:00'), ('2025-03-31T09:00:00'), ('2026-01-01T12:00:00'), ('2026-10-15T12:00:00'), ('2026-12-31T08:00:00')) v(v)),
     S AS (SELECT StartDate, NowDate FROM Starts CROSS JOIN Nows),
     NewWL AS (
        SELECT S.StartDate, S.NowDate, WorkLength.WorkLengthInYear, WorkLength.WorkLengthInMonthes, WorkLength.WorkLengthInDays
        FROM S
        CROSS APPLY
        (
            SELECT CASE WHEN S.StartDate > S.NowDate THEN S.NowDate ELSE S.StartDate END AS FromDate
                 , CASE WHEN S.StartDate > S.NowDate THEN S.StartDate ELSE S.NowDate END AS ToDate
        ) AS Period
        CROSS APPLY
        (
            SELECT CASE WHEN DAY(Period.FromDate) > DAY(Period.ToDate) THEN 1 ELSE 0 END AS DayBorrow
        ) AS DayStep
        CROSS APPLY
        (
            SELECT CASE WHEN MONTH(Period.FromDate) + DayStep.DayBorrow > MONTH(Period.ToDate) THEN 1 ELSE 0 END AS MonthBorrow
        ) AS MonthStep
        CROSS APPLY
        (
            SELECT YEAR(Period.ToDate) - (YEAR(Period.FromDate) + MonthStep.MonthBorrow) AS WorkLengthInYear
                 , MONTH(Period.ToDate) + 12 * MonthStep.MonthBorrow - (MONTH(Period.FromDate) + DayStep.DayBorrow) AS WorkLengthInMonthes
                 , DAY(Period.ToDate) + DayStep.DayBorrow * DAY(EOMONTH(Period.FromDate)) - DAY(Period.FromDate) AS WorkLengthInDays
        ) AS WorkLength
     ),
     LegacyWL AS (
        SELECT S.StartDate, S.NowDate, k.yy, g.mm, e.dd
        FROM S
            CROSS APPLY (SELECT IIF(S.StartDate > S.NowDate, S.NowDate, S.StartDate) AS f, IIF(S.StartDate > S.NowDate, S.StartDate, S.NowDate) AS t) a
            CROSS APPLY (SELECT CASE WHEN DAY(a.f) > DAY(a.t) THEN (SELECT d FROM #MD WHERE m = MONTH(a.f)) ELSE 0 END AS inc0) b
            CROSS APPLY (SELECT CASE WHEN b.inc0 = -1 THEN CASE WHEN (YEAR(a.f) % 4 = 0 AND YEAR(a.f) % 100 <> 0) OR YEAR(a.f) % 400 = 0 THEN 29 ELSE 28 END ELSE b.inc0 END AS inc) c2
            CROSS APPLY (SELECT CASE WHEN c2.inc <> 0 THEN DAY(a.t) + c2.inc - DAY(a.f) ELSE DAY(a.t) - DAY(a.f) END AS dd, IIF(c2.inc <> 0, 1, 0) AS i1) e
            CROSS APPLY (SELECT CASE WHEN MONTH(a.f) + e.i1 > MONTH(a.t) THEN MONTH(a.t) + 12 - (MONTH(a.f) + e.i1) ELSE MONTH(a.t) - (MONTH(a.f) + e.i1) END AS mm
                              , IIF(MONTH(a.f) + e.i1 > MONTH(a.t), 1, 0) AS i2) g
            CROSS APPLY (SELECT YEAR(a.t) - (YEAR(a.f) + g.i2) AS yy) k
     )
SELECT 'WorkLength synthetic' AS Info
     , (SELECT COUNT(*) FROM S) AS Cases
     , (SELECT COUNT(*) FROM (SELECT * FROM NewWL EXCEPT SELECT * FROM LegacyWL) x) AS NewNotInLegacy
     , (SELECT COUNT(*) FROM (SELECT * FROM LegacyWL EXCEPT SELECT * FROM NewWL) x) AS LegacyNotInNew;
GO
