-- CR 125486 e2e: minimal test reference data on db-all / Sabreen_Primary (test tenant). Idempotent.
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM Pm_ProjectType WHERE Name = N'سكني')
  INSERT INTO Pm_ProjectType (Name, NameSecondLanguage, Serial, IsActive) VALUES (N'سكني', N'Residential', N'1', 1);
IF NOT EXISTS (SELECT 1 FROM Pm_ProjectType WHERE Name = N'تجاري')
  INSERT INTO Pm_ProjectType (Name, NameSecondLanguage, Serial, IsActive) VALUES (N'تجاري', N'Commercial', N'2', 1);
IF NOT EXISTS (SELECT 1 FROM Pm_ProjectStatus WHERE Name = N'تحت الإنشاء')
  INSERT INTO Pm_ProjectStatus (Name, NameSecondLanguage, Serial, IsActive) VALUES (N'تحت الإنشاء', N'Under Construction', N'1', 1);
IF NOT EXISTS (SELECT 1 FROM Pm_ProjectActivities WHERE Name = N'سكني')
  INSERT INTO Pm_ProjectActivities (Name, NameSecondLanguage, Serial, IsActive) VALUES (N'سكني', N'Residential', N'1', 1);
IF NOT EXISTS (SELECT 1 FROM Pm_ProjectView WHERE Name = N'حديقة')
  INSERT INTO Pm_ProjectView (Name, NameSecondLanguage, Serial, IsActive) VALUES (N'حديقة', N'Garden', N'1', 1);
IF NOT EXISTS (SELECT 1 FROM Acc_CostCenter WHERE CostCenterNo = N'5')
  INSERT INTO Acc_CostCenter (CostCenterName, CostCenterNameSecondLanguage, CostCenterNo, IsActive, IsLastNode, CostCenterLevel, HasTransactions, CreatedDate)
  VALUES (N'مراكز تكلفة مشاريع المنطقة الغربية', N'Western Region Project Cost Centers', N'5', 1, 0, 0, 0, GETDATE());
SELECT 'type' k, ProjectTypeId, Name FROM Pm_ProjectType;
SELECT 'status' k, ProjectStatusId, Name FROM Pm_ProjectStatus;
SELECT 'activity' k, ActivityId, Name FROM Pm_ProjectActivities;
SELECT 'view' k, ProjectViewId, Name FROM Pm_ProjectView;
SELECT 'cc' k, CostCenterId, CostCenterNo, CostCenterName, IsLastNode FROM Acc_CostCenter WHERE CostCenterNo = N'5';
