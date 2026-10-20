-- CR-125294 test data for UNP-Ali (db-all): paid advances and purchases, so the Unpaid Advance
-- Payments and Employee Purchase reports have rows. Every row is tagged in Discription; remove with
-- the block at the end. Employees 10/31/64/70 have security level 1 (visible to every user).
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @tag NVARCHAR(100) = N'CR-125294 test data';

IF EXISTS (SELECT 1 FROM dbo.PR_Advance WHERE Discription = @tag)
   OR EXISTS (SELECT 1 FROM dbo.PR_Purchase WHERE Discription = @tag)
BEGIN
    PRINT 'Test data already present - nothing done.';
    RETURN;
END

BEGIN TRAN;

DECLARE @advSerial INT = (SELECT ISNULL(MAX(SerialNumber), 0) FROM dbo.PR_Advance);
DECLARE @purSerial INT = (SELECT ISNULL(MAX(SerialNumber), 0) FROM dbo.PR_Purchase);
DECLARE @id INT;

-- A1: employee 10, disbursed before the period (start 30/03/2026), 4 x 1,000; the first installment
-- deducted, 3 still open -> Unpaid "before date" balance 3,000 for a period starting 01/06/2026.
INSERT INTO dbo.PR_Advance (EmployeeId, RequestDate, AdvanceAmountCurrency, AdvanceAmount, NoRepayment, Approved,
                            ApplayingStartDate, ApproxEndDate, Returned, IsAdvance, Discription, IsPaid, SerialNumber, Confirmed)
VALUES (10, '2026-03-01', 1, 4000, 4, 1, '2026-03-30', '2026-06-30', 0, 1, @tag, 1, @advSerial + 1, 1);
SET @id = SCOPE_IDENTITY();
INSERT INTO dbo.PR_AdvanceRepayment (AdvanceId, PaymentDate, Amount, PaidDate, Paid, PaiedAmount)
VALUES (@id, '2026-03-30', 1000, '2026-03-30', 1, 1000),
       (@id, '2026-04-30', 1000, NULL, 0, NULL),
       (@id, '2026-05-30', 1000, NULL, 0, NULL),
       (@id, '2026-06-30', 1000, NULL, 0, NULL);

-- A2: employee 31, disbursed inside the period (start 30/07/2026), 6 x 500 = 3,000; 2 deducted
-- -> Unpaid period advance 3,000, period payment 1,000.
INSERT INTO dbo.PR_Advance (EmployeeId, RequestDate, AdvanceAmountCurrency, AdvanceAmount, NoRepayment, Approved,
                            ApplayingStartDate, ApproxEndDate, Returned, IsAdvance, Discription, IsPaid, SerialNumber, Confirmed)
VALUES (31, '2026-07-01', 1, 3000, 6, 1, '2026-07-30', '2026-12-30', 0, 1, @tag, 1, @advSerial + 2, 1);
SET @id = SCOPE_IDENTITY();
INSERT INTO dbo.PR_AdvanceRepayment (AdvanceId, PaymentDate, Amount, PaidDate, Paid, PaiedAmount)
VALUES (@id, '2026-07-30', 500, '2026-07-30', 1, 500),
       (@id, '2026-08-30', 500, '2026-08-30', 1, 500),
       (@id, '2026-09-30', 500, NULL, 0, NULL),
       (@id, '2026-10-30', 500, NULL, 0, NULL),
       (@id, '2026-11-30', 500, NULL, 0, NULL),
       (@id, '2026-12-30', 500, NULL, 0, NULL);

-- P1: employee 64, 3 x 800 = 2,400 from 30/07/2026, first installment deducted.
INSERT INTO dbo.PR_Purchase (EmployeeId, RequestDate, PurchaseAmountCurrency, PurchaseAmount, NoRepayment, Accepted,
                             ApplayingStartDate, ApproxEndDate, Returned, EndDate, Discription, IsPaid, SerialNumber)
VALUES (64, '2026-07-01', 1, 2400, 3, 1, '2026-07-30', '2026-09-30', 0, NULL, @tag, 1, @purSerial + 1);
SET @id = SCOPE_IDENTITY();
INSERT INTO dbo.PR_PurchaseRepayment (PurchaseId, PaymentDate, Amount, PaidDate, Paid, PaiedAmount)
VALUES (@id, '2026-07-30', 800, '2026-07-30', 1, 800),
       (@id, '2026-08-30', 800, NULL, 0, NULL),
       (@id, '2026-09-30', 800, NULL, 0, NULL);

-- P2: employee 70, 2 x 1,250 = 2,500 from 30/08/2026, nothing deducted yet.
INSERT INTO dbo.PR_Purchase (EmployeeId, RequestDate, PurchaseAmountCurrency, PurchaseAmount, NoRepayment, Accepted,
                             ApplayingStartDate, ApproxEndDate, Returned, EndDate, Discription, IsPaid, SerialNumber)
VALUES (70, '2026-08-01', 1, 2500, 2, 1, '2026-08-30', '2026-09-30', 0, NULL, @tag, 1, @purSerial + 2);
SET @id = SCOPE_IDENTITY();
INSERT INTO dbo.PR_PurchaseRepayment (PurchaseId, PaymentDate, Amount, PaidDate, Paid, PaiedAmount)
VALUES (@id, '2026-08-30', 1250, NULL, 0, NULL),
       (@id, '2026-09-30', 1250, NULL, 0, NULL);

COMMIT;
PRINT 'Inserted 2 advances (10 installments) and 2 purchases (5 installments).';

/* Remove:
DELETE r FROM dbo.PR_AdvanceRepayment r JOIN dbo.PR_Advance a ON a.AdvanceId = r.AdvanceId WHERE a.Discription = N'CR-125294 test data';
DELETE FROM dbo.PR_Advance WHERE Discription = N'CR-125294 test data';
DELETE r FROM dbo.PR_PurchaseRepayment r JOIN dbo.PR_Purchase p ON p.PurchaseId = r.PurchaseId WHERE p.Discription = N'CR-125294 test data';
DELETE FROM dbo.PR_Purchase WHERE Discription = N'CR-125294 test data';
*/
