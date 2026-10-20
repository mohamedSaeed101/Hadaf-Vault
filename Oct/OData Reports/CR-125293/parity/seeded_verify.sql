-- CR 125293 seeded parity: snapshot of every table the seeded_R*.sql scripts touch. Read-only. Run before and after; the outputs must be identical.
SET NOCOUNT ON;
SELECT 'Pr_PayingSalaries' AS tbl, COUNT(*) AS rows_, CHECKSUM_AGG(BINARY_CHECKSUM(*)) AS chk, MIN(PayingSalariesId) AS minId, MAX(PayingSalariesId) AS maxId, SUM(CASE WHEN IsPaid = 0 THEN 1 ELSE 0 END) AS unpaid, CAST(IDENT_CURRENT('Pr_PayingSalaries') AS INT) AS identCurrent FROM Pr_PayingSalaries
UNION ALL SELECT 'Pr_PayingSalariesDetail', COUNT(*), CHECKSUM_AGG(BINARY_CHECKSUM(*)), MIN(PayingSalariesDetailId), MAX(PayingSalariesDetailId), SUM(CASE WHEN PayingSalariesId < 0 THEN 1 ELSE 0 END), CAST(IDENT_CURRENT('Pr_PayingSalariesDetail') AS INT) FROM Pr_PayingSalariesDetail
UNION ALL SELECT 'PR_Employee', COUNT(*), CHECKSUM_AGG(BINARY_CHECKSUM(EmployeeId, EndWork, EndWorkingDate)), SUM(CAST(EndWork AS INT)), SUM(CASE WHEN EndWorkingDate IS NOT NULL THEN 1 ELSE 0 END), NULL, NULL FROM PR_Employee
UNION ALL SELECT 'PR_Salaries', COUNT(*), CHECKSUM_AGG(BINARY_CHECKSUM(*)), SUM(CAST(ISNULL(Suspend, 0) AS INT)), NULL, NULL, NULL FROM PR_Salaries
UNION ALL SELECT 'PR_SalaryDetail', COUNT(*), CHECKSUM_AGG(BINARY_CHECKSUM(*)), SUM(CAST(ISNULL(Suspend, 0) AS INT)), NULL, NULL, NULL FROM PR_SalaryDetail;
-- PR_Employee: minId = employees with EndWork = 1, maxId = employees with an EndWorkingDate; PR_Salaries / PR_SalaryDetail: minId = rows with Suspend = 1
SELECT @@TRANCOUNT AS trancount;
