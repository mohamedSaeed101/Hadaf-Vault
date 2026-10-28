SET XACT_ABORT ON;
USE [Sabreen_Primary];
GO
-- === 0466_Pm_RealEstateSettingsLookups.sql (set copy) ===
SET NOCOUNT ON

DECLARE @mergeError INT, @mergeCount INT

-- [dbo].[Pm_RentFrequency]
MERGE INTO [dbo].[Pm_RentFrequency] AS [Target]
USING (VALUES
  (1, N'شهري', N'Monthly'),
  (2, N'ربع سنوي', N'Quarterly'),
  (3, N'نصف سنوي', N'Semi-annual'),
  (4, N'سنوي', N'Annual')
) AS [Source] ([Id], [Name], [NameSecondLanguage])
ON [Target].[Id] = [Source].[Id]
WHEN MATCHED AND (
    NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR
    NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL
) THEN
    UPDATE SET
        [Name] = [Source].[Name],
        [NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [NameSecondLanguage])
    VALUES ([Source].[Id], [Source].[Name], [Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT

IF @mergeError != 0
    PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_RentFrequency]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100));
ELSE
    PRINT '[dbo].[Pm_RentFrequency] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));

-- [dbo].[Pm_LatePenaltyTreatment]
MERGE INTO [dbo].[Pm_LatePenaltyTreatment] AS [Target]
USING (VALUES
  (1, N'غرامة / فائدة تأخير مالية', N'Financial late penalty'),
  (2, N'غرامة تُصرف في أوجه البر', N'Penalty donated to charity'),
  (3, N'بدون غرامة مالية – إجراءات التعثر فقط', N'No financial penalty – default actions only')
) AS [Source] ([Id], [Name], [NameSecondLanguage])
ON [Target].[Id] = [Source].[Id]
WHEN MATCHED AND (
    NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR
    NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL
) THEN
    UPDATE SET
        [Name] = [Source].[Name],
        [NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [NameSecondLanguage])
    VALUES ([Source].[Id], [Source].[Name], [Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT

IF @mergeError != 0
    PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_LatePenaltyTreatment]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100));
ELSE
    PRINT '[dbo].[Pm_LatePenaltyTreatment] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));

-- [dbo].[Pm_PenaltyStart]
MERGE INTO [dbo].[Pm_PenaltyStart] AS [Target]
USING (VALUES
  (1, N'بعد انتهاء فترة السماح', N'After the grace period'),
  (2, N'من تاريخ استحقاق القسط', N'From the instalment due date')
) AS [Source] ([Id], [Name], [NameSecondLanguage])
ON [Target].[Id] = [Source].[Id]
WHEN MATCHED AND (
    NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR
    NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL
) THEN
    UPDATE SET
        [Name] = [Source].[Name],
        [NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [NameSecondLanguage])
    VALUES ([Source].[Id], [Source].[Name], [Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT

IF @mergeError != 0
    PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_PenaltyStart]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100));
ELSE
    PRINT '[dbo].[Pm_PenaltyStart] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));

-- [dbo].[Pm_ContractPenaltyCap]
MERGE INTO [dbo].[Pm_ContractPenaltyCap] AS [Target]
USING (VALUES
  (1, N'بدون', N'None'),
  (2, N'قسط واحد لكامل العقد', N'One instalment per contract')
) AS [Source] ([Id], [Name], [NameSecondLanguage])
ON [Target].[Id] = [Source].[Id]
WHEN MATCHED AND (
    NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR
    NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL
) THEN
    UPDATE SET
        [Name] = [Source].[Name],
        [NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [NameSecondLanguage])
    VALUES ([Source].[Id], [Source].[Name], [Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT

IF @mergeError != 0
    PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_ContractPenaltyCap]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100));
ELSE
    PRINT '[dbo].[Pm_ContractPenaltyCap] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));

-- [dbo].[Pm_DefaultStageAction]
MERGE INTO [dbo].[Pm_DefaultStageAction] AS [Target]
USING (VALUES
  (1, N'تذكير ودي', N'Friendly reminder'),
  (2, N'إنذار رسمي بالسداد', N'Formal payment notice'),
  (3, N'إشعار تعثر', N'Default notice'),
  (4, N'حلول باقي الأقساط', N'Acceleration of remaining instalments'),
  (5, N'فسخ العقد – الإخلاء', N'Contract termination – eviction'),
  (6, N'تحويل للشؤون القانونية – طلب تنفيذ', N'Legal referral – enforcement request')
) AS [Source] ([Id], [Name], [NameSecondLanguage])
ON [Target].[Id] = [Source].[Id]
WHEN MATCHED AND (
    NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR
    NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL
) THEN
    UPDATE SET
        [Name] = [Source].[Name],
        [NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [NameSecondLanguage])
    VALUES ([Source].[Id], [Source].[Name], [Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT

IF @mergeError != 0
    PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_DefaultStageAction]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100));
ELSE
    PRINT '[dbo].[Pm_DefaultStageAction] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));

-- [dbo].[Pm_EjarIntegrationMode]
MERGE INTO [dbo].[Pm_EjarIntegrationMode] AS [Target]
USING (VALUES
  (1, N'API', N'API'),
  (2, N'يدوي – استيراد', N'Manual – import')
) AS [Source] ([Id], [Name], [NameSecondLanguage])
ON [Target].[Id] = [Source].[Id]
WHEN MATCHED AND (
    NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR
    NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL
) THEN
    UPDATE SET
        [Name] = [Source].[Name],
        [NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [NameSecondLanguage])
    VALUES ([Source].[Id], [Source].[Name], [Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT

IF @mergeError != 0
    PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_EjarIntegrationMode]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100));
ELSE
    PRINT '[dbo].[Pm_EjarIntegrationMode] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));

-- [dbo].[Pm_EjarEnvironment]
MERGE INTO [dbo].[Pm_EjarEnvironment] AS [Target]
USING (VALUES
  (1, N'تجريبي', N'Sandbox'),
  (2, N'تشغيل', N'Production')
) AS [Source] ([Id], [Name], [NameSecondLanguage])
ON [Target].[Id] = [Source].[Id]
WHEN MATCHED AND (
    NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR
    NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL
) THEN
    UPDATE SET
        [Name] = [Source].[Name],
        [NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Id], [Name], [NameSecondLanguage])
    VALUES ([Source].[Id], [Source].[Name], [Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT

IF @mergeError != 0
    PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_EjarEnvironment]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100));
ELSE
    PRINT '[dbo].[Pm_EjarEnvironment] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));

-- [dbo].[Pm_RealEstateSettings]: the single settings row; the user's values are never overwritten
IF NOT EXISTS (SELECT 1 FROM [dbo].[Pm_RealEstateSettings] WHERE [Id] = 1)
    INSERT INTO [dbo].[Pm_RealEstateSettings] ([Id], [CustomerGroupId]) VALUES (1, NULL);

SET NOCOUNT OFF

GO
-- === 0328_Pm_ProofOfIncomeAndExpenses.sql (set copy) ===
--MERGE generated by 'sp_generate_merge' stored procedure
--Originally by Vyas (http://vyaskn.tripod.com/code): sp_generate_inserts (build 22)
--Adapted for SQL Server 2008+ by Daniel Nolan (https://twitter.com/dnlnln)

SET NOCOUNT ON

SET IDENTITY_INSERT [dbo].[Pm_ProofOfIncomeAndExpenses] ON

MERGE INTO [dbo].[Pm_ProofOfIncomeAndExpenses] AS [Target]
USING (VALUES
  (1,N'التعاقد على الوحدة',N'Property Contraction'),
  (2,N'تسليم الوحدة',N'Property Delivery'),
  (3,N'نسبة الإنجاز (البيع على الخارطة)',N'Percentage of completion (off-plan)')
) AS [Source] ([ProofOfIncomeAndExpensesId],[Name],[NameSecondLanguage])
ON ([Target].[ProofOfIncomeAndExpensesId] = [Source].[ProofOfIncomeAndExpensesId])
WHEN MATCHED AND (
	NULLIF([Source].[Name], [Target].[Name]) IS NOT NULL OR NULLIF([Target].[Name], [Source].[Name]) IS NOT NULL OR 
	NULLIF([Source].[NameSecondLanguage], [Target].[NameSecondLanguage]) IS NOT NULL OR NULLIF([Target].[NameSecondLanguage], [Source].[NameSecondLanguage]) IS NOT NULL) THEN
 UPDATE SET
  [Target].[Name] = [Source].[Name], 
  [Target].[NameSecondLanguage] = [Source].[NameSecondLanguage]
WHEN NOT MATCHED BY TARGET THEN
 INSERT([ProofOfIncomeAndExpensesId],[Name],[NameSecondLanguage])
 VALUES([Source].[ProofOfIncomeAndExpensesId],[Source].[Name],[Source].[NameSecondLanguage])
WHEN NOT MATCHED BY SOURCE THEN 
 DELETE;

DECLARE @mergeError int
 , @mergeCount int
SELECT @mergeError = @@ERROR, @mergeCount = @@ROWCOUNT
IF @mergeError != 0
 BEGIN
 PRINT 'ERROR OCCURRED IN MERGE FOR [dbo].[Pm_ProofOfIncomeAndExpenses]. Rows affected: ' + CAST(@mergeCount AS VARCHAR(100)); -- SQL should always return zero rows affected
 END
ELSE
 BEGIN
 PRINT '[dbo].[Pm_ProofOfIncomeAndExpenses] rows affected by MERGE: ' + CAST(@mergeCount AS VARCHAR(100));
 END


SET IDENTITY_INSERT [dbo].[Pm_ProofOfIncomeAndExpenses] OFF
SET NOCOUNT OFF


GO

-- CR 125733: module row 953 (guarded)
IF NOT EXISTS (SELECT 1 FROM [dbo].[Acc_Module] WHERE [ModuleId] = 953)
BEGIN
    SET IDENTITY_INSERT [dbo].[Acc_Module] ON;
    INSERT INTO [dbo].[Acc_Module] ([ModuleId],[ModuleName],[ModuleSubCategory],[ModuleCategory],[ModuleNameArabic],[ModuleSubCategoryArabic],[ApplicationId],[ModuleCategoryArabic],[HashKey],[ModuleNameForUI])
    VALUES (953,N'Property Manager Real Estate Settings',N'Property Basic Data',N'Property Settings',N'إعدادات التسويق العقاري',N'البيانات الأساسية للعقارات',14,N'إعدادات العقارات',NULL,N'RealEstateSettings');
    SET IDENTITY_INSERT [dbo].[Acc_Module] OFF;
END
SELECT 'module937' AS k, COUNT(*) AS n FROM [dbo].[Acc_Module] WHERE [ModuleId] = 953;
SELECT 'proof_rows' AS k, COUNT(*) AS n FROM [dbo].[Pm_ProofOfIncomeAndExpenses];
SELECT 'settings_rows' AS k, COUNT(*) AS n FROM [dbo].[Pm_RealEstateSettings];
SELECT 'rentfreq' AS k, COUNT(*) AS n FROM [dbo].[Pm_RentFrequency];
GO
