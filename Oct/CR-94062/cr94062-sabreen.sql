-- CR 94062: targeted apply to support-db2 / Sabreen (test tenant). Only these 3 objects.
SET NOCOUNT ON;
GO
CREATE OR ALTER FUNCTION dbo.Saf_Rpt_BankGuaranteeReport
(
    @StartDateFrom DATETIME = NULL,
    @StartDateTo DATETIME = NULL,
    @EndDateFrom DATETIME = NULL,
    @EndDateTo DATETIME = NULL,
    @BankGuaranteeTypeId INT = NULL,
    @BankId INT = NULL,
    @ApplicationId  NVARCHAR(MAX) = NULL, 
    @CustomerIds NVARCHAR(MAX) = NULL, 
    @ProjectId INT = NULL,
    @TransactionTypeIds NVARCHAR(MAX) = NULL,
    @IsArabic BIT = 0
)
RETURNS TABLE
AS
RETURN
WITH Customers AS (
    SELECT CustomerId, CustomerName, 2 AS ApplicationId FROM dbo.Inv_Customer
    UNION ALL
    SELECT OwnerId, OwnerName, 9 FROM dbo.Cnt_Owner
    UNION ALL
    SELECT CustomerId, CustomerName, 8 FROM dbo.Rst_Customer
    UNION ALL
    SELECT CustomerId, CustomerName, 12 FROM dbo.Lgx_Customer
),
ExtendDate AS (
    SELECT MAX(EndDate) AS MaxExtendDate, BankGuaranteeId
    FROM dbo.Saf_BankGuaranteeTransaction
    WHERE BankGuaranteeTransactionTypeId = 4
    GROUP BY BankGuaranteeId
),
BankGuaranteeHeader AS (
    SELECT
        bankGuarantee.BankGuaranteeId,
		bankGuarantee.BankGuaranteeSerial,
		bankGuarantee.BankGuaranteeTypeId,
		bankGuarantee.BankGuaranteeCostCenterId,
		bankGuarantee.ApplicationId,
		bankGuarantee.BankId,
		bankGuarantee.CustomerId,
	    bankGuarantee.StartDate,
        bankGuarantee.EndDate,
		bankGuarantee.CreateDate,
        bankGuarantee.ModifiedDate,
	    bankGuarantee.BenfitCostCenterId,
        bankGuarantee.ActualEndDate,
		ISNULL(NULLIF(bankGuarantee.BankGuaranteeNumber, ''), NULL) AS BankGuaranteeNumber,
        ISNULL(bankGuarantee.Amount, 0) AS AmountSafe,
        ISNULL(bankGuarantee.CoverAmount, 0) AS CoverAmountSafe,
        ISNULL(bankGuarantee.BenfitAmount, 0) AS BenfitAmountSafe,
        ISNULL(bankGuarantee.ExpenseAmount, 0) AS ExpenseAmountSafe,
        ISNULL(bankGuarantee.ExpenseTaxPercent, 0) AS ExpenseTaxPercentSafe,
        ISNULL(bankGuarantee.IsPercentageExpense, 0) AS IsPercentageExpenseSafe,
        ISNULL(bankGuarantee.IsConditional, 0) AS IsConditionalSafe,
        ISNULL(bankGuarantee.CurrentAmount, 0) AS CurrentAmountSafe,
        ISNULL(bankGuarantee.CurrentCoverAmount, 0) AS CurrentCoverAmountSafe,
        ISNULL(bankGuarantee.IsPercentageCover, 0) AS IsPercentageCoverSafe,
        ISNULL(bankGuarantee.IsPercentageBenfit, 0) AS IsPercentageBenfitSafe
    FROM Saf_BankGuarantee bankGuarantee
),
CalcValues AS (
    SELECT
        bankGuarantee.BankGuaranteeId,
        CASE 
            WHEN bankGuarantee.IsPercentageExpenseSafe = 1 
                THEN bankGuarantee.ExpenseAmountSafe * bankGuarantee.ExpenseTaxPercentSafe * bankGuarantee.AmountSafe
            ELSE bankGuarantee.ExpenseAmountSafe * bankGuarantee.ExpenseTaxPercentSafe
        END AS ExpenseTaxAmount,
        CASE 
            WHEN bankGuarantee.IsPercentageCoverSafe = 1 
                THEN bankGuarantee.CoverAmountSafe * bankGuarantee.AmountSafe
            ELSE bankGuarantee.CoverAmountSafe
        END AS CoverCalcValue,
        CASE 
            WHEN bankGuarantee.IsPercentageExpenseSafe = 1 
                THEN bankGuarantee.ExpenseAmountSafe * bankGuarantee.AmountSafe
            ELSE bankGuarantee.ExpenseAmountSafe
        END AS ExpenseCalcValue,
        CASE 
            WHEN bankGuarantee.IsPercentageBenfitSafe = 1
                THEN (bankGuarantee.AmountSafe - 
                      (CASE WHEN bankGuarantee.IsPercentageCoverSafe = 1 
                            THEN bankGuarantee.CoverAmountSafe * bankGuarantee.AmountSafe
                            ELSE bankGuarantee.CoverAmountSafe END)
                     ) * bankGuarantee.BenfitAmountSafe
            ELSE bankGuarantee.BenfitAmountSafe
        END AS BenfitCalcValue
    FROM BankGuaranteeHeader bankGuarantee
)
SELECT
    bankGuarantee.BankGuaranteeId,
    bankGuarantee.BankGuaranteeSerial,
    ISNULL(NULLIF(bankGuarantee.BankGuaranteeNumber, ''), NULL) AS BankGuaranteeNumber,
    bankGuarantee.StartDate,
    bankGuarantee.EndDate,
    bankGuarantee.BankId,
    bankGuarantee.ApplicationId,
    bankGuarantee.CustomerId,
    bankGuarantee.AmountSafe AS Amount,
    bankGuarantee.CoverAmountSafe AS CoverAmount,
    bankGuarantee.BenfitAmountSafe AS BenfitAmount,
    bankGuarantee.ExpenseAmountSafe AS ExpenseAmount,
    bankGuarantee.ExpenseTaxPercentSafe AS ExpenseTaxPercentage,
    CalculatedValues.ExpenseTaxAmount,
    bankGuarantee.IsConditionalSafe AS IsConditional,
    bankGuarantee.BankGuaranteeTypeId,
    ISNULL(costCenter.CostCenterName, NULL) AS CostCenterName,
    bankGuarantee.CreateDate,
    bankGuarantee.ModifiedDate,
    bankGuarantee.BenfitCostCenterId,
    bankGuarantee.CurrentAmountSafe AS CurrentAmount,
    bankGuarantee.CurrentCoverAmountSafe AS CurrentCoverAmount,
    bankGuarantee.ActualEndDate,
    ISNULL(bank.BankName, NULL) AS BankName,
    CASE 
        WHEN @IsArabic = 0 THEN ISNULL(bankGuaranteeType.BankGuaranteeTypeName, NULL)
        ELSE ISNULL(bankGuaranteeType.BankGuaranteeTypeArabicName, NULL)
    END AS BankGuaranteeTypeName,
    ISNULL(customers.CustomerName, NULL) AS CustomerName,
    CalculatedValues.CoverCalcValue,
    CalculatedValues.ExpenseCalcValue,
    CalculatedValues.BenfitCalcValue,
    extendDate.MaxExtendDate
FROM BankGuaranteeHeader bankGuarantee
LEFT JOIN Saf_BankGuaranteeType bankGuaranteeType ON bankGuarantee.BankGuaranteeTypeId = bankGuaranteeType.BankGuaranteeTypeId
LEFT JOIN Customers customers ON customers.ApplicationId = bankGuarantee.ApplicationId AND customers.CustomerId = bankGuarantee.CustomerId
LEFT JOIN Saf_Bank bank ON bankGuarantee.BankId = bank.BankId
LEFT JOIN dbo.Acc_CostCenter costCenter ON bankGuarantee.BankGuaranteeCostCenterId = costCenter.CostCenterId
LEFT JOIN ExtendDate extendDate ON extendDate.BankGuaranteeId = bankGuarantee.BankGuaranteeId
LEFT JOIN CalcValues CalculatedValues ON CalculatedValues.BankGuaranteeId = bankGuarantee.BankGuaranteeId
WHERE
    (@StartDateFrom IS NULL OR bankGuarantee.StartDate >= @StartDateFrom)
    AND (@StartDateTo IS NULL OR bankGuarantee.StartDate <= @StartDateTo)
    AND (@EndDateFrom IS NULL OR bankGuarantee.EndDate >= @EndDateFrom)
    AND (@EndDateTo IS NULL OR bankGuarantee.EndDate <= @EndDateTo)
    AND (@BankGuaranteeTypeId IS NULL OR bankGuarantee.BankGuaranteeTypeId = @BankGuaranteeTypeId)
    AND (@BankId IS NULL OR bankGuarantee.BankId = @BankId)
    AND (
        @CustomerIds IS NULL
        OR bankGuarantee.CustomerId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@CustomerIds))
        OR bankGuarantee.ApplicationId = 1
    )
    AND (@ApplicationId IS NULL OR bankGuarantee.ApplicationId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@ApplicationId)))
    AND (@ProjectId IS NULL OR bankGuarantee.BankGuaranteeCostCenterId = @ProjectId)
    AND (
        @TransactionTypeIds IS NULL
        OR EXISTS (
            SELECT 1
            FROM dbo.Saf_Rpt_BankGuaranteeTransactionDetail(bankGuarantee.BankGuaranteeId, @TransactionTypeIds, @IsArabic) t
        )
    )
;
GO
CREATE OR ALTER VIEW [dbo].[Vw_Saf_BankGuaranteePrint]  
AS
WITH Customers AS (
    SELECT CustomerId, CustomerName, 2 AS ApplicationId
    FROM dbo.Inv_Customer
    UNION ALL
    SELECT OwnerId, OwnerName, 9
    FROM dbo.Cnt_Owner
    UNION ALL
    SELECT CustomerId, CustomerName, 8
    FROM dbo.Rst_Customer
    UNION ALL
    SELECT CustomerId, CustomerName, 12
    FROM dbo.Lgx_Customer
),
ExtendDate AS (
    SELECT MAX(EndDate) AS MaxExtendDate, BankGuaranteeId
    FROM dbo.Saf_BankGuaranteeTransaction
    WHERE BankGuaranteeTransactionTypeId = 4
    GROUP BY BankGuaranteeId
)
SELECT
    Saf_BankGuarantee.BankGuaranteeId,
    Saf_BankGuarantee.BankGuaranteeSerial,
    Saf_BankGuarantee.BankGuaranteeNumber,
    Saf_BankGuarantee.StartDate,
    Saf_BankGuarantee.EndDate,
    Saf_BankGuarantee.BankId,
    Saf_BankGuarantee.ApplicationId,
    Saf_BankGuarantee.CustomerId,
    Saf_BankGuarantee.Amount,
    Saf_BankGuarantee.CurrencyId,
    Saf_BankGuarantee.CurrencyFactor,
    Saf_BankGuarantee.CoverAmount,
    Saf_BankGuarantee.CoverAccountId,
    Saf_BankGuarantee.IsPercentageCover,
    Saf_BankGuarantee.BenfitAmount,
    Saf_BankGuarantee.BenfitAccountId,
    Saf_BankGuarantee.IsPercentageBenfit,
    Saf_BankGuarantee.ExpenseAmount,
    Saf_BankGuarantee.ExpenseTaxPercent AS ExpenseTaxPercentage,
    CASE WHEN Saf_BankGuarantee.IsPercentageExpense = 1
         THEN (Saf_BankGuarantee.ExpenseAmount * Saf_BankGuarantee.ExpenseTaxPercent * Saf_BankGuarantee.Amount)
         ELSE (Saf_BankGuarantee.ExpenseAmount * Saf_BankGuarantee.ExpenseTaxPercent)
    END AS ExpenseTaxAmount,
    Saf_BankGuarantee.ExpenseAccountId,
    Saf_BankGuarantee.IsPercentageExpense,
    Saf_BankGuarantee.IsConditional,
    Saf_BankGuarantee.BankGuaranteeTypeId,
    Saf_BankGuarantee.ExpenseCostCenterId,
    Acc_Account.AccountName,
    Acc_CostCenter.CostCenterName,
    Saf_BankGuarantee.CreateDate,
    Saf_BankGuarantee.ModifiedDate,
    Saf_BankGuarantee.CreatedBy,
    Saf_BankGuarantee.ModifiedBy,
    Saf_BankGuarantee.Descriptions,
    Saf_BankGuarantee.BenfitCostCenterId,
    Saf_BankGuarantee.CurrentAmount,
    Saf_BankGuarantee.CurrentCoverAmount,
    Saf_BankGuarantee.ActualEndDate,
    Saf_Bank.BankName,
    Saf_BankGuaranteeType.BankGuaranteeTypeName,
    Saf_BankGuaranteeType.BankGuaranteeTypeArabicName,
    Acc_Currency.CurrencyName,
    Acc_Currency.CurrencyNameArabic,
    Customers.CustomerName,
    CASE WHEN Saf_BankGuarantee.IsPercentageCover = 1
         THEN Saf_BankGuarantee.CoverAmount * Saf_BankGuarantee.Amount
         ELSE Saf_BankGuarantee.CoverAmount
    END AS CoverCalcValue,
    CASE WHEN Saf_BankGuarantee.IsPercentageExpense = 1
         THEN Saf_BankGuarantee.ExpenseAmount * Saf_BankGuarantee.Amount
         ELSE Saf_BankGuarantee.ExpenseAmount
    END AS ExpenseCalcValue,
    CASE WHEN Saf_BankGuarantee.IsPercentageBenfit = 1
         THEN (Saf_BankGuarantee.Amount
                - (CASE WHEN Saf_BankGuarantee.IsPercentageCover = 1
                        THEN Saf_BankGuarantee.CoverAmount * Saf_BankGuarantee.Amount
                        ELSE Saf_BankGuarantee.CoverAmount
                   END)) * Saf_BankGuarantee.BenfitAmount
         ELSE Saf_BankGuarantee.BenfitAmount
    END AS BenfitCalcValue,
    ExtendDate.MaxExtendDate
FROM Saf_BankGuarantee
    LEFT JOIN Saf_BankGuaranteeType ON Saf_BankGuarantee.BankGuaranteeTypeId = Saf_BankGuaranteeType.BankGuaranteeTypeId
    LEFT JOIN Customers ON Customers.ApplicationId = Saf_BankGuarantee.ApplicationId
        AND Customers.CustomerId = Saf_BankGuarantee.CustomerId
    LEFT JOIN Saf_Bank ON Saf_BankGuarantee.BankId = Saf_Bank.BankId
    LEFT JOIN Acc_Currency ON Saf_BankGuarantee.CurrencyId = Acc_Currency.CurrencyId
    LEFT JOIN dbo.Acc_Account ON Saf_BankGuarantee.BankGuaranteeAccountId = Acc_Account.AccountId
    LEFT JOIN dbo.Acc_CostCenter ON Saf_BankGuarantee.BankGuaranteeCostCenterId = Acc_CostCenter.CostCenterId
    LEFT JOIN ExtendDate ON ExtendDate.BankGuaranteeId = Saf_BankGuarantee.BankGuaranteeId
 
GO
IF NOT EXISTS (SELECT 1 FROM dbo.Acc_ModulePermission WHERE ModulePermissionId = 500)
BEGIN
  SET IDENTITY_INSERT dbo.Acc_ModulePermission ON;
  INSERT INTO dbo.Acc_ModulePermission (ModulePermissionId, Permission, Description, ModuleId) VALUES (500, N'Logistics Customers', N'عملاء خدمات لوجستية', 419);
  SET IDENTITY_INSERT dbo.Acc_ModulePermission OFF;
END
GO
