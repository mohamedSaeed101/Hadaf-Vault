SET XACT_ABORT ON;
SET NOCOUNT ON;
USE [Sabreen_Primary];
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings]
    ADD [CompanyName]                        NVARCHAR (250)  NULL,
        [CompanyNameSecondLanguage]          NVARCHAR (250)  NULL,
        [CountryId]                          INT             NULL,
        [ShowHijriDate]                      BIT             CONSTRAINT [DF_Pm_RealEstateSettings_ShowHijriDate] DEFAULT (1) NOT NULL,
        [RegaBrokerageLicense]               NVARCHAR (50)   NULL,
        [RegaPropertyManagementLicense]      NVARCHAR (50)   NULL,
        [RegaLicenseExpiryDate]              DATE            NULL,
        [TenantDepositsAccountId]            INT             NULL,
        [OwnerDuesAccountId]                 INT             NULL,
        [UnbilledSaleReceivablesAccountId]   INT             NULL,
        [PropertyStockAccountId]             INT             NULL,
        [RentPaymentsInTransitAccountId]     INT             NULL,
        [ReservationValidityDays]            INT             NULL,
        [ReservationDownPaymentPercent]      DECIMAL (5, 2)  NULL,
        [GracePeriodDays]                    INT             NULL,
        [RentFrequencyId]                    INT             NULL,
        [InstallmentChangeLimitPercent]      DECIMAL (5, 2)  NULL,
        [CreateJournalsManually]             BIT             CONSTRAINT [DF_Pm_RealEstateSettings_CreateJournalsManually] DEFAULT (1) NOT NULL,
        [ProofOfIncomeAndExpensesId]         INT             NULL,
        [AccruedRentRevenueAccountId]        INT             NULL,
        [UnearnedRentRevenueAccountId]       INT             NULL,
        [FirstHomeTaxExemptionCap]           DECIMAL (18, 2) NULL,
        [BrokerCommissionWithholdingPercent] DECIMAL (5, 2)  NULL,
        [LatePenaltyTreatmentId]             INT             NULL,
        [AnnualLegalPenaltyCapPercent]       DECIMAL (5, 2)  NULL,
        [PenaltyStartId]                     INT             NULL,
        [PenaltyCappedAtPrincipal]           BIT             NULL,
        [ContractPenaltyCapId]               INT             NULL,
        [Stage1FromDay]                      INT             NULL,
        [Stage1ActionId]                     INT             NULL,
        [Stage2FromDay]                      INT             NULL,
        [Stage2ActionId]                     INT             NULL,
        [Stage3FromDay]                      INT             NULL,
        [Stage3ActionId]                     INT             NULL,
        [Stage4FromDay]                      INT             NULL,
        [Stage4ActionId]                     INT             NULL,
        [EjarIntegrationModeId]              INT             NULL,
        [EjarEnvironmentId]                  INT             NULL,
        [EjarTransferBusinessDays]           INT             NULL,
        [EjarDefaultPaymentForCommercial]    BIT             NULL,
        [EInvoiceExemptInstallments]         BIT             NULL;
GO
CREATE TABLE [dbo].[Pm_ContractPenaltyCap] (
    [Id]                 INT            NOT NULL,
    [Name]               NVARCHAR (100) NOT NULL,
    [NameSecondLanguage] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Pm_ContractPenaltyCap] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Pm_DefaultStageAction] (
    [Id]                 INT            NOT NULL,
    [Name]               NVARCHAR (100) NOT NULL,
    [NameSecondLanguage] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Pm_DefaultStageAction] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Pm_EjarEnvironment] (
    [Id]                 INT            NOT NULL,
    [Name]               NVARCHAR (100) NOT NULL,
    [NameSecondLanguage] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Pm_EjarEnvironment] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Pm_EjarIntegrationMode] (
    [Id]                 INT            NOT NULL,
    [Name]               NVARCHAR (100) NOT NULL,
    [NameSecondLanguage] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Pm_EjarIntegrationMode] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Pm_LatePenaltyTreatment] (
    [Id]                 INT            NOT NULL,
    [Name]               NVARCHAR (100) NOT NULL,
    [NameSecondLanguage] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Pm_LatePenaltyTreatment] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Pm_PenaltyStart] (
    [Id]                 INT            NOT NULL,
    [Name]               NVARCHAR (100) NOT NULL,
    [NameSecondLanguage] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Pm_PenaltyStart] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Pm_RentFrequency] (
    [Id]                 INT            NOT NULL,
    [Name]               NVARCHAR (100) NOT NULL,
    [NameSecondLanguage] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Pm_RentFrequency] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Acc_Account_AccruedRentRevenueAccountId] FOREIGN KEY ([AccruedRentRevenueAccountId]) REFERENCES [dbo].[Acc_Account] ([AccountId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Acc_Account_OwnerDuesAccountId] FOREIGN KEY ([OwnerDuesAccountId]) REFERENCES [dbo].[Acc_Account] ([AccountId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Acc_Account_PropertyStockAccountId] FOREIGN KEY ([PropertyStockAccountId]) REFERENCES [dbo].[Acc_Account] ([AccountId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Acc_Account_RentPaymentsInTransitAccountId] FOREIGN KEY ([RentPaymentsInTransitAccountId]) REFERENCES [dbo].[Acc_Account] ([AccountId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Acc_Account_TenantDepositsAccountId] FOREIGN KEY ([TenantDepositsAccountId]) REFERENCES [dbo].[Acc_Account] ([AccountId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Acc_Account_UnbilledSaleReceivablesAccountId] FOREIGN KEY ([UnbilledSaleReceivablesAccountId]) REFERENCES [dbo].[Acc_Account] ([AccountId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Acc_Account_UnearnedRentRevenueAccountId] FOREIGN KEY ([UnearnedRentRevenueAccountId]) REFERENCES [dbo].[Acc_Account] ([AccountId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_ACFX_Country] FOREIGN KEY ([CountryId]) REFERENCES [dbo].[ACFX_Country] ([CountryId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_ContractPenaltyCap] FOREIGN KEY ([ContractPenaltyCapId]) REFERENCES [dbo].[Pm_ContractPenaltyCap] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_DefaultStageAction_Stage1ActionId] FOREIGN KEY ([Stage1ActionId]) REFERENCES [dbo].[Pm_DefaultStageAction] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_DefaultStageAction_Stage2ActionId] FOREIGN KEY ([Stage2ActionId]) REFERENCES [dbo].[Pm_DefaultStageAction] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_DefaultStageAction_Stage3ActionId] FOREIGN KEY ([Stage3ActionId]) REFERENCES [dbo].[Pm_DefaultStageAction] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_DefaultStageAction_Stage4ActionId] FOREIGN KEY ([Stage4ActionId]) REFERENCES [dbo].[Pm_DefaultStageAction] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_EjarEnvironment] FOREIGN KEY ([EjarEnvironmentId]) REFERENCES [dbo].[Pm_EjarEnvironment] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_EjarIntegrationMode] FOREIGN KEY ([EjarIntegrationModeId]) REFERENCES [dbo].[Pm_EjarIntegrationMode] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_LatePenaltyTreatment] FOREIGN KEY ([LatePenaltyTreatmentId]) REFERENCES [dbo].[Pm_LatePenaltyTreatment] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_PenaltyStart] FOREIGN KEY ([PenaltyStartId]) REFERENCES [dbo].[Pm_PenaltyStart] ([Id]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_ProofOfIncomeAndExpenses] FOREIGN KEY ([ProofOfIncomeAndExpensesId]) REFERENCES [dbo].[Pm_ProofOfIncomeAndExpenses] ([ProofOfIncomeAndExpensesId]);
GO
ALTER TABLE [dbo].[Pm_RealEstateSettings] WITH NOCHECK
    ADD CONSTRAINT [FK_Pm_RealEstateSettings_Pm_RentFrequency] FOREIGN KEY ([RentFrequencyId]) REFERENCES [dbo].[Pm_RentFrequency] ([Id]);
GO
