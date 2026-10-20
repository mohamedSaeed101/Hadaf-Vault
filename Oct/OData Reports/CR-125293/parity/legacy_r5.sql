-- legacy dtEmployeeBonus (Accounting/EmployeeBonus/dsEmployeeBonus.xsd), untouched
SELECT PR_EmployeeBonus.SerialNumber
     , PR_EmployeeBonus.EmployeeId
     , PR_EmployeeBonus.EmployeeBonusId
     , PR_EmployeeBonus.BonusId
     , PR_EmployeeBonus.BonusTypeId
     , PR_Employee.EmployeeName
     , PR_Bonus.BonusName
     , PR_EmployeeBonus.BonusDate
     , IIF(@isArabic = 1, PR_EmployeeBonusType.BonusTypeName, PR_EmployeeBonusType.BonusTypeNameSecondLanguage) AS BonusValueTypeName
     , PR_EmployeeBonus.BonusCurrencyId
     , IIF(@isArabic = 1, Acc_Currency.CurrencyNameArabic, Acc_Currency.CurrencyName) AS CurrencyName
     , Acc_Currency.EnglishLetter AS CurrencyEnglishLetter
     , Acc_Currency.ArabicLetter AS CurrencyArabicLetter
     , PR_EmployeeBonus.BonusAmount
     , PR_EmployeeBonus.BounsTotalValue
     , PR_EmployeeBonus.Description
     , PR_EmployeeBonus.Paid AS IsPaid
     , IIF(PR_EmployeeBonus.Paid = 1, IIF(@isArabic = 1, N'نعم', 'Yes'), IIF(@isArabic = 1, N'لا', 'No')) AS IsPaidStr
	 , PR_Employee.EmployeeNumber,	dbo.PR_Job.JobName AS jobName
FROM PR_EmployeeBonus
    INNER JOIN PR_Employee ON PR_EmployeeBonus.EmployeeId = PR_Employee.EmployeeId
    LEFT JOIN PR_EmployeeBonusType ON PR_EmployeeBonus.BonusTypeId = PR_EmployeeBonusType.BonusTypeId
    LEFT JOIN PR_Bonus ON PR_EmployeeBonus.BonusId = PR_Bonus.BonusId
    LEFT JOIN Acc_Currency ON PR_EmployeeBonus.BonusCurrencyId = CurrencyId
	LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
WHERE (PR_Employee.EmployeeSecurityLevel <= @userSecurityLevel AND PR_Employee.EndWork = 0)
    AND (PR_EmployeeBonus.BonusDate BETWEEN @fromDate AND @toDate)
    AND (@employeeIds IS NULL OR PR_Employee.EmployeeId IN (SELECT number FROM dbo.Acc_ConvertIntListToTable(@employeeIds)));
