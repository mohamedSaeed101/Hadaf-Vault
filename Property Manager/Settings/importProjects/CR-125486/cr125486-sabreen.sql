-- CR 125486: targeted apply to db-all / Sabreen_Primary (test tenant), for the end-to-end test.
-- Only: new table Pm_ProjectImportLog + module row 934. Idempotent.
-- Deliberately NOT dropping Pm_Project.ProofOfIncomeAndExpenses here: other branches' code on this
-- tenant may still read it; this CR's code no longer maps it and its DEFAULT 1 keeps inserts working.
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.Pm_ProjectImportLog', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Pm_ProjectImportLog]
    (
        [ProjectImportLogId]  INT            IDENTITY (1, 1) NOT NULL,
        [ImportDate]          DATETIME       NOT NULL,
        [FileName]            NVARCHAR (500) NOT NULL,
        [UserId]              INT            NOT NULL,
        [TotalRows]           INT            NOT NULL,
        [NewRows]             INT            NOT NULL,
        [ErrorRows]           INT            NOT NULL,
        [NewCostCenters]      INT            CONSTRAINT [DF_Pm_ProjectImportLog_NewCostCenters] DEFAULT ((0)) NOT NULL,
        [ParentCostCenterId]  INT            NULL,
        [CreatedById]         INT            NOT NULL,
        [CreatedOn]           DATETIME       NOT NULL,
        [LastModifiedById]    INT            NOT NULL,
        [LastModifiedOn]      DATETIME       NOT NULL,
        CONSTRAINT [PK_Pm_ProjectImportLog] PRIMARY KEY CLUSTERED ([ProjectImportLogId] ASC)
    );
    PRINT 'Pm_ProjectImportLog created';
END
ELSE PRINT 'Pm_ProjectImportLog already exists';

IF NOT EXISTS (SELECT 1 FROM dbo.Acc_Module WHERE ModuleId = 934)
BEGIN
    SET IDENTITY_INSERT [Acc_Module] ON;
    INSERT INTO [Acc_Module] ([ModuleId], [ModuleName], [ModuleSubCategory], [ModuleCategory], [ModuleNameArabic],
                              [ModuleSubCategoryArabic], [ApplicationId], [ModuleCategoryArabic], [HashKey], [ModuleNameForUI])
    VALUES (934, N'Property Manager Project Import', N'Projects & Properties Tools', N'Projects & Properties Tools',
            N'استيراد المشاريع', N'أدوات المشاريع والعقارات', 14, N'أدوات المشاريع والعقارات', NULL, N'project-import');
    SET IDENTITY_INSERT [Acc_Module] OFF;
    PRINT 'Module 934 inserted';
END
ELSE PRINT 'Module 934 already exists';
