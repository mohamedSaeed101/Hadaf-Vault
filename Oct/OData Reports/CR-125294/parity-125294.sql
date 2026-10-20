-- CR 125294 parity check: legacy MVC report SQL (Payroll.Reports\HR\*.xsd) vs the new OData TVFs.
-- Run on a test tenant (support-db2) AFTER the cr125294 dacpac functions are published there.
-- Pass condition: every "diff" result set is empty. @SecurityLevel = 5 (max) so the new
-- security filter removes nothing and the comparison is like for like.
-- Set the parameters to a real range with data; @EmployeeIds must be a non-empty list for the
-- Advance/Purchase sections (with an empty list the legacy SQL ignores the dates - fixed on purpose).
SET NOCOUNT ON;

DECLARE @EmployeeIds NVARCHAR(MAX) = N'1,2,3';
DECLARE @InServiceFilter NVARCHAR(50) = N'';
DECLARE @FromDay DATE = '2025-01-01';
DECLARE @ToDay DATE = '2025-12-31';
DECLARE @SecurityLevel INT = 5;

-- Legacy boundaries: from = 00:00:00, to = 23:59:59 (rpt*.cs BeforePrint)
DECLARE @from DATETIME = CAST(@FromDay AS DATETIME);
DECLARE @to DATETIME = DATEADD(SECOND, -1, CAST(DATEADD(DAY, 1, @ToDay) AS DATETIME));

------------------------------------------------------------------------------------------------
-- 1. Unpaid advance payments (dsEmployeeUnPaidAdvancesPayments.xsd, verbatim)
------------------------------------------------------------------------------------------------
DECLARE @employees NVARCHAR(MAX) = @EmployeeIds;
DECLARE @LegacyUnpaid TABLE (EmployeeId INT, BeforeDateAmount MONEY, PeriodAdvance MONEY, PeriodPayment MONEY, EndDateAmount MONEY, TotalEmployeeAmount MONEY);

WITH AdvancePayements
AS (SELECT EmployeeId, SUM(Amount) AS BeforeDateAmount, 0 AS AperiodAdvance, 0 AS periodPayment
    FROM PR_Advance INNER JOIN PR_AdvanceRepayment ON PR_Advance.AdvanceId = PR_AdvanceRepayment.AdvanceId
    WHERE IsAdvance = 1 AND IsPaid = 1 AND Paid = 0 AND Approved = 1 AND PR_Advance.ApplayingStartDate < @from
    GROUP BY EmployeeId
    UNION ALL
    SELECT EmployeeId, 0, 0, SUM(Amount)
    FROM PR_Advance INNER JOIN PR_AdvanceRepayment ON PR_Advance.AdvanceId = PR_AdvanceRepayment.AdvanceId
    WHERE IsAdvance = 1 AND IsPaid = 1 AND Paid = 1 AND Approved = 1
          AND (@from <= PR_Advance.ApplayingStartDate AND PR_Advance.ApplayingStartDate < @to)
    GROUP BY EmployeeId
    UNION ALL
    SELECT EmployeeId, 0, SUM(Amount), 0
    FROM PR_Advance INNER JOIN dbo.PR_AdvanceRepayment ON PR_AdvanceRepayment.AdvanceId = PR_Advance.AdvanceId
    WHERE IsAdvance = 1 AND Approved = 1 AND IsPaid = 1
          AND (@from <= PR_Advance.ApplayingStartDate AND PR_Advance.ApplayingStartDate < @to)
    GROUP BY EmployeeId),
     AllAdvances
AS (SELECT EmployeeId, SUM(BeforeDateAmount) AS BeforeDateAmount, SUM(AperiodAdvance) AS periodAdvance,
           SUM(periodPayment) AS periodPayment,
           SUM(BeforeDateAmount) + SUM(AperiodAdvance) - SUM(periodPayment) AS EndDateAmount
    FROM AdvancePayements GROUP BY EmployeeId),
     AllEmployeeAdvance
AS (SELECT SUM(AdvanceAmount) TotalAmount, EmployeeId FROM PR_Advance GROUP BY EmployeeId)
INSERT INTO @LegacyUnpaid
SELECT AllAdvances.EmployeeId, BeforeDateAmount, periodAdvance, periodPayment, EndDateAmount,
       ISNULL(AllEmployeeAdvance.TotalAmount, 0)
FROM AllAdvances
    INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = AllAdvances.EmployeeId
    LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    INNER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    INNER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
    LEFT JOIN AllEmployeeAdvance ON AllEmployeeAdvance.EmployeeId = PR_Employee.EmployeeId
WHERE ((@employees IS NULL) OR (@employees = '')
       OR AllAdvances.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employees)))
  AND (TRIM(@InServiceFilter) = '' OR @InServiceFilter IS NULL
       OR (@InServiceFilter = N'AllInService' AND PR_Employee.EndWork = 0)
       OR (@InServiceFilter = N'AllTerminated' AND PR_Employee.EndWork = 1));

DECLARE @NewUnpaid TABLE (EmployeeId INT, BeforeDateAmount MONEY, PeriodAdvance MONEY, PeriodPayment MONEY, EndDateAmount MONEY, TotalEmployeeAmount MONEY);
INSERT INTO @NewUnpaid
SELECT EmployeeId, BeforeDateAmount, PeriodAdvance, PeriodPayment, EndDateAmount, TotalEmployeeAmount
FROM dbo.PR_UnpaidAdvancePaymentsReport(@EmployeeIds, @InServiceFilter, @from, @to, @SecurityLevel);

SELECT 'unpaid rows' AS [check], (SELECT COUNT(*) FROM @LegacyUnpaid) AS legacy, (SELECT COUNT(*) FROM @NewUnpaid) AS new;
SELECT 'unpaid diff: legacy not in new' AS [check], * FROM (SELECT * FROM @LegacyUnpaid EXCEPT SELECT * FROM @NewUnpaid) d;
SELECT 'unpaid diff: new not in legacy' AS [check], * FROM (SELECT * FROM @NewUnpaid EXCEPT SELECT * FROM @LegacyUnpaid) d;

------------------------------------------------------------------------------------------------
-- 2. Employees advance (dsEmployeeAdvance2.xsd FillByEmployeeID, verbatim) + repayments
------------------------------------------------------------------------------------------------
DECLARE @EmployeeId NVARCHAR(MAX) = @EmployeeIds;
DECLARE @StartDate DATETIME = @from, @EndDate DATETIME = @to;
DECLARE @LegacyAdvance TABLE (AdvanceId INT, EmployeeId INT, AdvanceAmount MONEY, AdvanceAmountCurrency INT, NoRepayment INT,
                              ApplayingStartDate DATETIME, ApproxEndDate DATETIME, RequestDate DATETIME);
INSERT INTO @LegacyAdvance
SELECT PR_Advance.AdvanceId, PR_Employee.EmployeeId, PR_Advance.AdvanceAmount, PR_Advance.AdvanceAmountCurrency,
       PR_Advance.NoRepayment, PR_Advance.ApplayingStartDate, PR_Advance.ApproxEndDate, RequestDate
FROM Acc_Currency
    INNER JOIN PR_Advance ON Acc_Currency.CurrencyId = PR_Advance.AdvanceAmountCurrency
    INNER JOIN PR_Employee ON PR_Advance.EmployeeId = PR_Employee.EmployeeId
    LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE ((@EmployeeId IS NULL) OR (@EmployeeId = ''))
      OR (PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeId)))
      AND (PR_Advance.ApplayingStartDate BETWEEN @StartDate AND @EndDate)
      AND PR_Advance.IsAdvance = 1
      AND PR_Advance.Confirmed = 1;

DECLARE @NewAdvance TABLE (AdvanceId INT, EmployeeId INT, AdvanceAmount MONEY, AdvanceAmountCurrency INT, NoRepayment INT,
                           ApplayingStartDate DATETIME, ApproxEndDate DATETIME, RequestDate DATETIME);
INSERT INTO @NewAdvance
SELECT AdvanceId, EmployeeId, AdvanceAmount, AdvanceAmountCurrency, NoRepayment, ApplayingStartDate, ApproxEndDate, RequestDate
FROM dbo.PR_EmployeesAdvanceReport(@EmployeeIds, @from, @to, @SecurityLevel);

SELECT 'advance rows' AS [check], (SELECT COUNT(*) FROM @LegacyAdvance) AS legacy, (SELECT COUNT(*) FROM @NewAdvance) AS new,
       (SELECT SUM(AdvanceAmount) FROM @LegacyAdvance) AS legacyTotal, (SELECT SUM(AdvanceAmount) FROM @NewAdvance) AS newTotal;
SELECT 'advance diff: legacy not in new' AS [check], * FROM (SELECT * FROM @LegacyAdvance EXCEPT SELECT * FROM @NewAdvance) d;
SELECT 'advance diff: new not in legacy' AS [check], * FROM (SELECT * FROM @NewAdvance EXCEPT SELECT * FROM @LegacyAdvance) d;

-- Legacy repayments: every PR_AdvanceRepayment row, related to the advances above by the DataSet relation
SELECT 'advance repayment diff (legacy vs new)' AS [check], *
FROM (SELECT ar.RepaymentId, ar.AdvanceId, ar.PaymentDate, ar.Amount, ar.PaidDate, ar.Paid, ar.Amount AS PaiedAmount
      FROM dbo.PR_AdvanceRepayment ar WHERE ar.AdvanceId IN (SELECT AdvanceId FROM @LegacyAdvance)
      EXCEPT
      SELECT RepaymentId, AdvanceId, PaymentDate, Amount, PaidDate, Paid, PaiedAmount
      FROM dbo.PR_EmployeesAdvanceRepaymentReport(@EmployeeIds, @from, @to, @SecurityLevel)) d;

------------------------------------------------------------------------------------------------
-- 3. Employee purchase (dsEmployeeDecucations.xsd FillBy, verbatim) + repayments
------------------------------------------------------------------------------------------------
DECLARE @LegacyPurchase TABLE (PurchaseId INT, EmployeeId INT, PurchaseAmount MONEY, PurchaseAmountCurrency INT, NoRepayment INT,
                               ApplayingStartDate DATETIME, ApproxEndDate DATETIME, RequestDate DATETIME);
INSERT INTO @LegacyPurchase
SELECT PR_Purchase.PurchaseId, PR_Employee.EmployeeId, PR_Purchase.PurchaseAmount, PR_Purchase.PurchaseAmountCurrency,
       PR_Purchase.NoRepayment, PR_Purchase.ApplayingStartDate, PR_Purchase.ApproxEndDate, PR_Purchase.RequestDate
FROM PR_Employee
    LEFT JOIN PR_Purchase ON PR_Purchase.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN Acc_Currency ON PR_Purchase.PurchaseAmountCurrency = Acc_Currency.CurrencyId
    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
    LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
    LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
WHERE (@EmployeeId IS NULL)
      OR (@EmployeeId = '' AND PR_Purchase.PurchaseId IS NOT NULL)
      OR (PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@EmployeeId)))
      AND (PR_Purchase.ApplayingStartDate BETWEEN @StartDate AND @EndDate);

DECLARE @NewPurchase TABLE (PurchaseId INT, EmployeeId INT, PurchaseAmount MONEY, PurchaseAmountCurrency INT, NoRepayment INT,
                            ApplayingStartDate DATETIME, ApproxEndDate DATETIME, RequestDate DATETIME);
INSERT INTO @NewPurchase
SELECT PurchaseId, EmployeeId, PurchaseAmount, PurchaseAmountCurrency, NoRepayment, ApplayingStartDate, ApproxEndDate, RequestDate
FROM dbo.PR_EmployeePurchaseReport(@EmployeeIds, @from, @to, @SecurityLevel);

SELECT 'purchase rows' AS [check], (SELECT COUNT(*) FROM @LegacyPurchase) AS legacy, (SELECT COUNT(*) FROM @NewPurchase) AS new,
       (SELECT SUM(PurchaseAmount) FROM @LegacyPurchase) AS legacyTotal, (SELECT SUM(PurchaseAmount) FROM @NewPurchase) AS newTotal;
SELECT 'purchase diff: legacy not in new' AS [check], * FROM (SELECT * FROM @LegacyPurchase EXCEPT SELECT * FROM @NewPurchase) d;
SELECT 'purchase diff: new not in legacy' AS [check], * FROM (SELECT * FROM @NewPurchase EXCEPT SELECT * FROM @LegacyPurchase) d;

SELECT 'purchase repayment diff (legacy vs new)' AS [check], *
FROM (SELECT pr.RepaymentId, pr.PurchaseId, pr.PaymentDate, pr.Amount, pr.PaidDate, pr.Paid, pr.PaiedAmount
      FROM dbo.PR_PurchaseRepayment pr WHERE pr.PurchaseId IN (SELECT PurchaseId FROM @LegacyPurchase)
      EXCEPT
      SELECT RepaymentId, PurchaseId, PaymentDate, Amount, PaidDate, Paid, PaiedAmount
      FROM dbo.PR_EmployeePurchaseRepaymentReport(@EmployeeIds, @from, @to, @SecurityLevel)) d;
