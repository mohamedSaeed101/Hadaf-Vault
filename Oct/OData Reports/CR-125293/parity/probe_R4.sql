SET NOCOUNT ON;
DECLARE @x DECIMAL(38,13) = 1234.5678900000000;
SELECT SQL_VARIANT_PROPERTY(@x - FLOOR(@x),'Precision') p_sub, SQL_VARIANT_PROPERTY(@x - FLOOR(@x),'Scale') s_sub, @x - FLOOR(@x) v_sub,
       SQL_VARIANT_PROPERTY(FLOOR(@x),'Precision') p_floor, SQL_VARIANT_PROPERTY(FLOOR(@x),'Scale') s_floor;
GO
SELECT TOP 3 SQL_VARIANT_PROPERTY(TotalIncomeLocal,'BaseType') bt, SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Precision') p, SQL_VARIANT_PROPERTY(TotalIncomeLocal,'Scale') s, TotalIncomeLocal FROM dbo.PR_InsuranceRegistrationReport('1900-01-01','2100-01-01',NULL,5);
SELECT COUNT(*) n, SUM(CASE WHEN TotalIncomeLocal > 0 THEN 1 ELSE 0 END) incPos,
  SUM(CASE WHEN TotalIncomeLocal > 0 AND TotalIncomeLocal - FLOOR(TotalIncomeLocal) >= 0.5 THEN 1 ELSE 0 END) incFracGE05,
  SUM(CASE WHEN TotalIncomeLocal > 0 AND TotalIncomeLocal <> FLOOR(TotalIncomeLocal) THEN 1 ELSE 0 END) incHasFrac,
  SUM(CASE WHEN TotalInsuranceLocal > 0 THEN 1 ELSE 0 END) insPos,
  SUM(CASE WHEN TotalInsuranceLocal > 0 AND TotalInsuranceLocal <> FLOOR(TotalInsuranceLocal) THEN 1 ELSE 0 END) insHasFrac
FROM dbo.PR_InsuranceRegistrationReport('1900-01-01','2100-01-01',NULL,5);
