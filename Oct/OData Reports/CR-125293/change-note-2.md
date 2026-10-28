# CR-125293 change note 2 — Insurance registration «إلى تاريخ» covers the whole day (Muhammed Tariq, ADO comment 10021304, 2026-10-25)

- **What**: `PR_InsuranceRegistrationReport` gets `_toDate.GetDayEnd()` instead of `GetDayStart()`, so employees whose SocialInsuranceStartDate falls on the To date after 00:00 are included. Reverses commit 857d878a94: it matched the MVC page, but the desktop form (`frmInsuranceRegistrationReport.cs:15`) sends 23:59:59, and every other report in the controller uses GetDayEnd.
- **Where**: AccFlex_Cloud_ERP only, set `D:\Hadaf-worktrees\cr125293\AccFlex_Cloud_ERP` — `AnalyticsReader/.../ODataControllers/Payroll/PayrollOdataController.cs` and `.../Payroll/SalariesReports/InsuranceRegistrationRptAng.cs`.
- **Test**: AnalyticsReader.Api builds; on Sabreen 27/09/2026 → 27/09/2026 returns the 3 employees starting that day (ABDULAAZIZ SHUBAYLI, HAYA JAMHAN, YAHYA HAZAZI).
- **Risk**: one report only; rows on the To date now appear, which is the asked behaviour.
- **Rollback**: revert the commit on cr125293.
