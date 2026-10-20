-- CR 125562 (Q14): test tenant only. Widen Pm_ServiceItem.AnnualPrice 18,4 -> 19,4 (no data loss). Idempotent.
SET NOCOUNT ON;
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Pm_ServiceItem') AND name = N'AnnualPrice' AND precision = 18)
BEGIN
    EXEC(N'ALTER TABLE dbo.Pm_ServiceItem ALTER COLUMN AnnualPrice DECIMAL(19,4) NOT NULL;');
    PRINT 'AnnualPrice altered to 19,4';
END
ELSE PRINT 'AnnualPrice already 19,4 (or table missing)';
SELECT name, precision, scale FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.Pm_ServiceItem') AND name = N'AnnualPrice';
SELECT Id, Code, AnnualPrice FROM dbo.Pm_ServiceItem;
