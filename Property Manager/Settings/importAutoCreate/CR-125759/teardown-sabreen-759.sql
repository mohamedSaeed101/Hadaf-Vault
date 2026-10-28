-- CR-125759 end-to-end teardown on db-all / Sabreen_Primary: removes only the «759» test data created on 2026-10-22.
-- Run it yourself (sqlcmd or SSMS). One transaction; prints row counts, then the counts to compare with the
-- baseline: projects 17, govs 16, cities 127, centers 20, types 2, statuses 1, views 1, activities 1, models 0, project logs 6.
SET XACT_ABORT ON; BEGIN TRAN;
DECLARE @props TABLE(id int); INSERT @props SELECT PropertyId FROM Pm_Properties WHERE PropertyNumber LIKE 'T759%';
DECLARE @projs TABLE(id int); INSERT @projs SELECT ProjectId FROM Pm_Project WHERE ProjectNumber LIKE 'T759%';
DELETE FROM Pm_PropertyInvestmentType WHERE PropertyId IN (SELECT id FROM @props); PRINT CONCAT('prop inv ', @@ROWCOUNT);
DELETE FROM Pm_Properties WHERE PropertyId IN (SELECT id FROM @props); PRINT CONCAT('props ', @@ROWCOUNT);
DELETE FROM Pm_ProjectInvestmentType WHERE ProjectId IN (SELECT id FROM @projs); PRINT CONCAT('proj inv ', @@ROWCOUNT);
DELETE FROM Pm_Project WHERE ProjectId IN (SELECT id FROM @projs); PRINT CONCAT('projects ', @@ROWCOUNT);
DELETE FROM Pm_PropertyModel WHERE Name LIKE N'%759%'; PRINT CONCAT('models ', @@ROWCOUNT);
DELETE FROM Pm_ProjectType WHERE Name LIKE N'%759%'; PRINT CONCAT('types ', @@ROWCOUNT);
DELETE FROM Pm_ProjectStatus WHERE Name LIKE N'%759%'; PRINT CONCAT('statuses ', @@ROWCOUNT);
DELETE FROM Pm_ProjectView WHERE Name LIKE N'%759%'; PRINT CONCAT('views ', @@ROWCOUNT);
DELETE FROM Pm_ProjectActivities WHERE Name LIKE N'%759%'; PRINT CONCAT('activities ', @@ROWCOUNT);
DELETE FROM ACFX_Center WHERE CenterName LIKE N'%759%'; PRINT CONCAT('centers ', @@ROWCOUNT);
DELETE c FROM ACFX_City c JOIN ACFX_Governorate g ON g.GovernorateId = c.GovernorateId
 WHERE c.CityName LIKE N'%759%' OR (c.CityName = 'RIYADH' AND g.GovernorateName = 'MAKKAH REGION'); PRINT CONCAT('cities ', @@ROWCOUNT);
DELETE FROM ACFX_Governorate WHERE GovernorateName LIKE N'%759%'; PRINT CONCAT('govs ', @@ROWCOUNT);
DELETE FROM Pm_ProjectImportLog WHERE FileName LIKE 'e2e-projects%' AND ImportDate >= '2026-10-22'; PRINT CONCAT('proj logs ', @@ROWCOUNT);
DELETE FROM Pm_PropertyImportLog WHERE FileName LIKE 'e2e-properties%' AND ImportDate >= '2026-10-22'; PRINT CONCAT('prop logs ', @@ROWCOUNT);
COMMIT;
SELECT (SELECT COUNT(*) FROM Pm_Project) projects, (SELECT COUNT(*) FROM ACFX_Governorate) govs, (SELECT COUNT(*) FROM ACFX_City) cities,
       (SELECT COUNT(*) FROM ACFX_Center) centers, (SELECT COUNT(*) FROM Pm_ProjectType) types, (SELECT COUNT(*) FROM Pm_ProjectStatus) st,
       (SELECT COUNT(*) FROM Pm_ProjectView) vw, (SELECT COUNT(*) FROM Pm_ProjectActivities) act, (SELECT COUNT(*) FROM Pm_PropertyModel) models,
       (SELECT COUNT(*) FROM Pm_ProjectImportLog) plog;
