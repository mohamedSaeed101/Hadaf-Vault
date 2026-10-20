-- CR 125562: targeted apply to db-all / Sabreen_Primary (test tenant). Only Pm_ServiceItem + module 947. Idempotent.
SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.Pm_ServiceItem', N'U') IS NULL
BEGIN
EXEC(N'
CREATE TABLE [dbo].[Pm_ServiceItem]
(
    [Id]                INT             IDENTITY (1, 1) NOT NULL,
    [Code]              NVARCHAR (50)   NOT NULL,
    [NameAr]            NVARCHAR (200)  NOT NULL,
    [NameEn]            NVARCHAR (200)  NULL,
    [AnnualPrice]       DECIMAL (18, 4) CONSTRAINT [DF_Pm_ServiceItem_AnnualPrice] DEFAULT ((0)) NOT NULL,
    [IsSubjectToVat]    BIT             CONSTRAINT [DF_Pm_ServiceItem_IsSubjectToVat] DEFAULT ((1)) NOT NULL,
    [IsActive]          BIT             CONSTRAINT [DF_Pm_ServiceItem_IsActive] DEFAULT ((1)) NOT NULL,
    [CreatedById]       INT             NOT NULL,
    [CreatedOn]         DATETIME2 (3)   NOT NULL,
    [LastModifiedById]  INT             NOT NULL,
    [LastModifiedOn]    DATETIME2 (3)   NOT NULL,
    [RowVer]            ROWVERSION      NOT NULL,

    CONSTRAINT [PK_Pm_ServiceItem] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Pm_ServiceItem_Code] UNIQUE NONCLUSTERED ([Code] ASC),
    CONSTRAINT [CK_Pm_ServiceItem_AnnualPrice] CHECK ([AnnualPrice] >= 0)
)
');
PRINT 'Pm_ServiceItem created';
END
ELSE PRINT 'Pm_ServiceItem already exists';

IF NOT EXISTS (SELECT 1 FROM dbo.Acc_Module WHERE ModuleId = 947)
BEGIN
    SET IDENTITY_INSERT [Acc_Module] ON;
    INSERT INTO [Acc_Module] ([ModuleId], [ModuleName], [ModuleSubCategory], [ModuleCategory], [ModuleNameArabic], [ModuleSubCategoryArabic], [ApplicationId], [ModuleCategoryArabic], [HashKey], [ModuleNameForUI])
    VALUES (947, N'Property Manager Service Items', N'Property Basic Data', N'Property Settings', N'بنود الخدمات', N'البيانات الأساسية للعقارات', 14, N'إعدادات العقارات', NULL, N'ServiceItems');
    SET IDENTITY_INSERT [Acc_Module] OFF;
    PRINT 'Module 947 inserted';
END
ELSE PRINT 'Module 947 already exists';
