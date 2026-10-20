-- R7 parity: dbo.PR_EmployeesNoIssuedSalariesReport (TVF body verbatim from origin/cr125292)
-- vs legacy dsEmployee.xsd FillByNoSalaryIssued (verbatim from AccFlex_ERP origin/Master_Stable).
-- Read-only: temp tables and variables only. Run with: sqlcmd -v Y=2026 M=8 B=1 L=5
SET NOCOUNT ON;
DECLARE @Month INT = $(M), @Year INT = $(Y), @BranchId INT = $(B), @SecurityLevel INT = $(L);
-- legacy: controller NoSalaryByIssued(int branchId, DateTime month) -> rptEmployee(branchId, month.Month, month.Year); SqlParameters int/int/int
DECLARE @lbranchId INT = $(B), @lmonth INT = $(M), @lyear INT = $(Y);

-- NEW
    WITH Report
      AS ( SELECT   PR_Employee.EmployeeId ,
                    PR_Employee.EmployeeName ,
                    PR_Employee.EmployeeArabicName ,
                    PR_Employee.GenderId ,
                    PR_Employee.JobId ,
                    PR_Employee.DepartmentId ,
                    PR_Employee.DateOfBirth ,
                    PR_Employee.BankAccountNum ,
                    PR_Employee.InsuranceNum ,
                    PR_Employee.DateOfWork ,
                    PR_Employee.GraduationDate ,
                    PR_Employee.EndWorkingDate ,
                    PR_Employee.EmployeeDegree ,
                    PR_Employee.IDNumber ,
                    PR_Employee.Telephone ,
                    PR_Employee.Mobile ,
                    PR_Employee.SalaryPerAttend ,
                    PR_Employee.EmployeeNumber ,
                    PR_Employee.DeductionLimit ,
                    PR_Employee.PenaltyLimit ,
                    PR_Employee.AdvanceLimit ,
                    PR_Employee.MedicalInsurance ,
                    PR_Employee.MedicalInsuranceValue ,
                    PR_Employee.FridayWork ,
                    PR_Employee.SaturdayWork ,
                    PR_Employee.SundayWork ,
                    PR_Employee.MondayWork ,
                    PR_Employee.TuesdayWork ,
                    PR_Employee.WednesdayWork ,
                    PR_Employee.ThursdayWork ,
                    PR_Employee.SearchName ,
                    PR_Employee.EndWork ,
                    PR_Employee.NationalityId ,
                    PR_Department.DepartmentName ,
                    Acc_Branch.BranchName ,
                    PR_Projects.ProjectName ,
                    PR_Job.JobName
           FROM     dbo.PR_Employee
                    INNER JOIN dbo.PR_Job ON PR_Employee.JobId = PR_Job.JobId
                    INNER JOIN dbo.PR_Department ON PR_Employee.DepartmentId = PR_Department.DepartmentId
                    LEFT JOIN dbo.Acc_Branch ON Acc_Branch.BranchId = PR_Employee.BranchId
                    LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
           WHERE    PR_Employee.BranchId = @BranchId
                    AND PR_Employee.EmployeeId NOT IN (
                    SELECT  PR_Salaries.EmployeeId
                    FROM    dbo.PR_Salaries
                            INNER JOIN dbo.PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
                    WHERE   PR_SalaryMain.SalaryMonth = @Month
                            AND PR_SalaryMain.SalaryYear = @Year
                            AND PR_Salaries.Posted = 1 )
                    AND PR_Employee.EmployeeSecurityLevel <= @SecurityLevel
         )
    SELECT   ROW_NUMBER() OVER ( ORDER BY TRY_CAST(Report.EmployeeNumber AS INT), Report.EmployeeId ) AS RowNo
           , Report.*
    INTO #new
    FROM     Report
;
-- OLD
SELECT  PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.GenderId ,
        PR_Employee.JobId ,
        PR_Employee.DepartmentId ,
        PR_Employee.DateOfBirth ,
        PR_Employee.BankAccountNum ,
        PR_Employee.InsuranceNum ,
        PR_Employee.DateOfWork ,
        PR_Employee.GraduationDate ,
        PR_Employee.EndWorkingDate ,
        PR_Employee.EmployeeDegree ,
        PR_Employee.IDNumber ,
        PR_Employee.Telephone ,
        PR_Employee.Mobile ,
        PR_Employee.SalaryPerAttend ,
        PR_Employee.EmployeeNumber ,
        PR_Employee.DeductionLimit ,
        PR_Employee.PenaltyLimit ,
        PR_Employee.AdvanceLimit ,
        PR_Employee.MedicalInsurance ,
        PR_Employee.MedicalInsuranceValue ,
        PR_Employee.FridayWork ,
        PR_Employee.SaturdayWork ,
        PR_Employee.SundayWork ,
        PR_Employee.MondayWork ,
        PR_Employee.TuesdayWork ,
        PR_Employee.WednesdayWork ,
        PR_Employee.ThursdayWork ,
        PR_Employee.SearchName ,
        PR_Employee.EndWork ,
        PR_Employee.NationalityId ,
        PR_Department.DepartmentName ,
        Acc_Branch.BranchName ,
        PR_Projects.ProjectName ,
        PR_Job.JobName
INTO #old
FROM    PR_Employee
        INNER JOIN PR_Job ON PR_Employee.JobId = PR_Job.JobId
        INNER JOIN PR_Department ON PR_Employee.DepartmentId = PR_Department.DepartmentId
        LEFT JOIN dbo.Acc_Branch ON Acc_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   PR_Employee.BranchId = @lbranchId
        AND PR_Employee.EmployeeId NOT IN (
        SELECT  PR_Salaries.EmployeeId
        FROM    PR_Salaries
                INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        WHERE   PR_SalaryMain.SalaryMonth = @lmonth
                AND PR_SalaryMain.SalaryYear = @lyear
                AND PR_Salaries.Posted = 1 )
ORDER BY TRY_CAST(EmployeeNumber AS INT);

SELECT 'R7 Y=$(Y) M=$(M) B=$(B) L=$(L)' AS [case], (SELECT COUNT(*) FROM #old) AS rows_old, (SELECT COUNT(*) FROM #new) AS rows_new,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #old EXCEPT SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #new) d) AS old_minus_new,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #new EXCEPT SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #old) d) AS new_minus_old,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName, COUNT(*) c FROM #old GROUP BY EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName EXCEPT SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName, COUNT(*) FROM #new GROUP BY EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName) d) AS grp_old_minus_new,
  (SELECT COUNT(*) FROM (SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName, COUNT(*) c FROM #new GROUP BY EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName EXCEPT SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName, COUNT(*) FROM #old GROUP BY EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName) d) AS grp_new_minus_old;
SELECT 'sums' k, 'old' src, SUM(DeductionLimit) DeductionLimit, SUM(PenaltyLimit) PenaltyLimit, SUM(AdvanceLimit) AdvanceLimit, SUM(MedicalInsuranceValue) MedicalInsuranceValue FROM #old
UNION ALL SELECT 'sums','new', SUM(DeductionLimit), SUM(PenaltyLimit), SUM(AdvanceLimit), SUM(MedicalInsuranceValue) FROM #new;
SELECT TOP 10 'old-new' k, EmployeeId, EmployeeNumber, EmployeeName FROM (SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #old EXCEPT SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #new) d;
SELECT TOP 10 'new-old' k, EmployeeId, EmployeeNumber, EmployeeName FROM (SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #new EXCEPT SELECT EmployeeId,EmployeeName,GenderId,JobId,DepartmentId,DateOfBirth,BankAccountNum,InsuranceNum,DateOfWork,GraduationDate,EndWorkingDate,EmployeeDegree,IDNumber,Telephone,Mobile,SalaryPerAttend,EmployeeNumber,DeductionLimit,PenaltyLimit,AdvanceLimit,MedicalInsurance,MedicalInsuranceValue,FridayWork,SaturdayWork,SundayWork,MondayWork,TuesdayWork,WednesdayWork,ThursdayWork,SearchName,EndWork,NationalityId,DepartmentName,BranchName,ProjectName,JobName FROM #old) d;
-- order check: RowNo must be non-decreasing in legacy sort key TRY_CAST(EmployeeNumber AS INT)
SELECT 'order_violations' k, COUNT(*) n FROM #new a JOIN #new b ON b.RowNo = a.RowNo + 1
WHERE ISNULL(TRY_CAST(a.EmployeeNumber AS INT), -2147483648) > ISNULL(TRY_CAST(b.EmployeeNumber AS INT), -2147483648);
-- rows the legacy security-free query has that level filter removes (expected none at level 5)
SELECT 'emp_above_level' k, COUNT(*) n FROM #old o JOIN dbo.PR_Employee e ON e.EmployeeId = o.EmployeeId WHERE e.EmployeeSecurityLevel > @SecurityLevel;
DROP TABLE #new; DROP TABLE #old;
