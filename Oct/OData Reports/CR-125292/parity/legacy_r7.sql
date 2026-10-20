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
FROM    PR_Employee
        INNER JOIN PR_Job ON PR_Employee.JobId = PR_Job.JobId
        INNER JOIN PR_Department ON PR_Employee.DepartmentId = PR_Department.DepartmentId
        LEFT JOIN dbo.Acc_Branch ON Acc_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   PR_Employee.BranchId = @branchId
        AND PR_Employee.EmployeeId NOT IN (
        SELECT  PR_Salaries.EmployeeId
        FROM    PR_Salaries
                INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        WHERE   PR_SalaryMain.SalaryMonth = @month
                AND PR_SalaryMain.SalaryYear = @year
                AND PR_Salaries.Posted = 1 )
ORDER BY TRY_CAST(EmployeeNumber AS INT);