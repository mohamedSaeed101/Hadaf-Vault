// rptRiskAnalysis.BeforePrint, oracle copy. Lines 50 and 67-137 of
// AccFlex_ERP\HRManagement\Payroll.Reports\HR\RiskAnalysis\rptRiskAnalysis.cs are pasted
// verbatim (checked with diff against the legacy file); only the data access (lines 52-65)
// is replaced by dsRiskAnalysis.Fill. BeforePrintFixed is the same text with one change, CR 125299
// decision D6: both income Where clauses also require u.EmployeeId == the row's EmployeeId.
using System;
using System.Linq;
using Microsoft.Data.SqlClient;
using Payroll.Reports.Helper;

namespace Payroll.Reports.HR.RiskAnalysis
{
    public class rptRiskAnalysis
    {
        public dsRiskAnalysis dsRiskAnalysis1 = new dsRiskAnalysis();
        private string _employees;
        DateTime _atDate;
        bool IsArabic;

        public rptRiskAnalysis(string employees, DateTime atDate, bool isArabic)
        {
            _employees = employees;
            _atDate = atDate;
            IsArabic = isArabic;
        }

        public void BeforePrint(SqlConnection connection)
        {
            DateTime vacDate = new DateTime(_atDate.AddMonths(-1).Year, _atDate.AddMonths(-1).Month, DateTime.DaysInMonth(_atDate.AddMonths(-1).Year, _atDate.AddMonths(-1).Month));
            dsRiskAnalysis1.Fill(connection, _employees, IsArabic, vacDate);

            for (int i = 0; i < dsRiskAnalysis1.PR_Employee.Count; i++)
            {
                decimal salary = dsRiskAnalysis1.PR_EmployeeIncome
                    .Where(u => u.IncomeStartDate <= _atDate && u.IncomeCurrency == dsRiskAnalysis1.PR_Employee[i].CurrencyId)
                    .Sum(u => Convert.ToDecimal(u.IncomeAmount));
                TimeSpan WorkPeriodspan = _atDate.Date.AddDays(1).AddSeconds(-1) - dsRiskAnalysis1.PR_Employee[i].DateOfWork.Date;
                DateDifference dateDifference = new DateDifference(_atDate.Date, dsRiskAnalysis1.PR_Employee[i].DateOfWork.Date);
                 dsRiskAnalysis1.PR_Employee[i].DaysOfWork = dateDifference.Days;
                dsRiskAnalysis1.PR_Employee[i].MonthesOfWork = dateDifference.Months;
                int years =dsRiskAnalysis1.PR_Employee[i].YearsOfWork = dateDifference.Years;
                if ((dateDifference.Days > 0 || dateDifference.Months > 0) && WorkPeriodspan.TotalDays > 90)
                {
                    years++;
                }
                dsRiskAnalysis1.PR_Employee[i].NetYearsOfWork = years;

                if (WorkPeriodspan.TotalDays > 90)
                {
                    dsRiskAnalysis1.PR_Employee[i].RiskAmount = Math.Round(salary * 2, 2);
                }
                else
                {
                    dsRiskAnalysis1.PR_Employee[i].RiskAmount = 0;
                }
                if (!dsRiskAnalysis1.PR_Employee[i].IsEndServicePolicyIdNull())
                {
                    if (dsRiskAnalysis1.PR_Employee[i] != null)
                    {
                        TimeSpan YearsSpan = _atDate.Date.AddDays(1).AddMinutes(-1) - dsRiskAnalysis1.PR_Employee[i].DateOfWork;
                        int Years = dateDifference.Years;
                        int TotalWorkingYears = Convert.ToInt32(Years);

                        var stage = dsRiskAnalysis1.Pr_EndServicePolicyDetail
                            .Where(u => u.EndServicePolicyId == dsRiskAnalysis1.PR_Employee[i].EndServicePolicyId)
                            .OrderByDescending(u => u.WorkingYearsFrom)
                            .FirstOrDefault(u => u.WorkingYearsFrom <= TotalWorkingYears && u.WorkingYearsTo >= TotalWorkingYears);

                        if (stage != null)
                        {
                            var incomeList = dsRiskAnalysis1.Pr_IncomeEndServicePolicyDetail.Where(u => u.EndServicePolicyDetailId == stage.EndServicePolicyDetailId);

                            var Ids = incomeList.Select(u => u.IncomeId).Distinct().ToList();

                            decimal employeeSalary = dsRiskAnalysis1.PR_EmployeeIncome
                                .Where(u => u.IncomeStartDate <= _atDate && u.IncomeCurrency == dsRiskAnalysis1.PR_Employee[i].CurrencyId && Ids.Exists(x => x == u.IncomeId))
                                .Sum(u => Convert.ToDecimal(u.IncomeAmount));

                            dsRiskAnalysis1.PR_Employee[i].Compensation = Math.Round(Convert.ToDecimal((employeeSalary * stage.BounsMonthesPerYear * dsRiskAnalysis1.PR_Employee[i].YearsOfWork)), 0);
                        }
                        else
                        {
                            dsRiskAnalysis1.PR_Employee[i].Compensation = 0;
                        }
                    }
                }
                else
                {
                    dsRiskAnalysis1.PR_Employee[i].Compensation = 0;
                }
                var empoyeeVacation = dsRiskAnalysis1.Pr_VacationBalance.FindByEmployeeId(dsRiskAnalysis1.PR_Employee[i].EmployeeId);
                decimal takenVacation = empoyeeVacation.IsPaidVactionsNull() ? 0 : empoyeeVacation.PaidVactions;
                decimal yearVacations = empoyeeVacation.IsVacationBalanceNull() ? 0 : empoyeeVacation.VacationBalance;
                decimal dueVacations = (21.0m / 12.0m) * vacDate.Month;
                decimal vacationBalance = dueVacations - takenVacation;
                if (yearVacations > 21)
                {
                    vacationBalance += yearVacations - 21;
                }
                dsRiskAnalysis1.PR_Employee[i].VacationBalance = Math.Round(vacationBalance, 2);
                dsRiskAnalysis1.PR_Employee[i].Vacations = Math.Round(Convert.ToDecimal(Convert.ToDecimal(salary / 30 * vacationBalance)), 2);
            }
        }

        public void BeforePrintFixed(SqlConnection connection)
        {
            DateTime vacDate = new DateTime(_atDate.AddMonths(-1).Year, _atDate.AddMonths(-1).Month, DateTime.DaysInMonth(_atDate.AddMonths(-1).Year, _atDate.AddMonths(-1).Month));
            dsRiskAnalysis1.Fill(connection, _employees, IsArabic, vacDate);

            for (int i = 0; i < dsRiskAnalysis1.PR_Employee.Count; i++)
            {
                decimal salary = dsRiskAnalysis1.PR_EmployeeIncome
                    .Where(u => u.IncomeStartDate <= _atDate && u.IncomeCurrency == dsRiskAnalysis1.PR_Employee[i].CurrencyId && u.EmployeeId == dsRiskAnalysis1.PR_Employee[i].EmployeeId)
                    .Sum(u => Convert.ToDecimal(u.IncomeAmount));
                TimeSpan WorkPeriodspan = _atDate.Date.AddDays(1).AddSeconds(-1) - dsRiskAnalysis1.PR_Employee[i].DateOfWork.Date;
                DateDifference dateDifference = new DateDifference(_atDate.Date, dsRiskAnalysis1.PR_Employee[i].DateOfWork.Date);
                 dsRiskAnalysis1.PR_Employee[i].DaysOfWork = dateDifference.Days;
                dsRiskAnalysis1.PR_Employee[i].MonthesOfWork = dateDifference.Months;
                int years =dsRiskAnalysis1.PR_Employee[i].YearsOfWork = dateDifference.Years;
                if ((dateDifference.Days > 0 || dateDifference.Months > 0) && WorkPeriodspan.TotalDays > 90)
                {
                    years++;
                }
                dsRiskAnalysis1.PR_Employee[i].NetYearsOfWork = years;

                if (WorkPeriodspan.TotalDays > 90)
                {
                    dsRiskAnalysis1.PR_Employee[i].RiskAmount = Math.Round(salary * 2, 2);
                }
                else
                {
                    dsRiskAnalysis1.PR_Employee[i].RiskAmount = 0;
                }
                if (!dsRiskAnalysis1.PR_Employee[i].IsEndServicePolicyIdNull())
                {
                    if (dsRiskAnalysis1.PR_Employee[i] != null)
                    {
                        TimeSpan YearsSpan = _atDate.Date.AddDays(1).AddMinutes(-1) - dsRiskAnalysis1.PR_Employee[i].DateOfWork;
                        int Years = dateDifference.Years;
                        int TotalWorkingYears = Convert.ToInt32(Years);

                        var stage = dsRiskAnalysis1.Pr_EndServicePolicyDetail
                            .Where(u => u.EndServicePolicyId == dsRiskAnalysis1.PR_Employee[i].EndServicePolicyId)
                            .OrderByDescending(u => u.WorkingYearsFrom)
                            .FirstOrDefault(u => u.WorkingYearsFrom <= TotalWorkingYears && u.WorkingYearsTo >= TotalWorkingYears);

                        if (stage != null)
                        {
                            var incomeList = dsRiskAnalysis1.Pr_IncomeEndServicePolicyDetail.Where(u => u.EndServicePolicyDetailId == stage.EndServicePolicyDetailId);

                            var Ids = incomeList.Select(u => u.IncomeId).Distinct().ToList();

                            decimal employeeSalary = dsRiskAnalysis1.PR_EmployeeIncome
                                .Where(u => u.IncomeStartDate <= _atDate && u.IncomeCurrency == dsRiskAnalysis1.PR_Employee[i].CurrencyId && Ids.Exists(x => x == u.IncomeId) && u.EmployeeId == dsRiskAnalysis1.PR_Employee[i].EmployeeId)
                                .Sum(u => Convert.ToDecimal(u.IncomeAmount));

                            dsRiskAnalysis1.PR_Employee[i].Compensation = Math.Round(Convert.ToDecimal((employeeSalary * stage.BounsMonthesPerYear * dsRiskAnalysis1.PR_Employee[i].YearsOfWork)), 0);
                        }
                        else
                        {
                            dsRiskAnalysis1.PR_Employee[i].Compensation = 0;
                        }
                    }
                }
                else
                {
                    dsRiskAnalysis1.PR_Employee[i].Compensation = 0;
                }
                var empoyeeVacation = dsRiskAnalysis1.Pr_VacationBalance.FindByEmployeeId(dsRiskAnalysis1.PR_Employee[i].EmployeeId);
                decimal takenVacation = empoyeeVacation.IsPaidVactionsNull() ? 0 : empoyeeVacation.PaidVactions;
                decimal yearVacations = empoyeeVacation.IsVacationBalanceNull() ? 0 : empoyeeVacation.VacationBalance;
                decimal dueVacations = (21.0m / 12.0m) * vacDate.Month;
                decimal vacationBalance = dueVacations - takenVacation;
                if (yearVacations > 21)
                {
                    vacationBalance += yearVacations - 21;
                }
                dsRiskAnalysis1.PR_Employee[i].VacationBalance = Math.Round(vacationBalance, 2);
                dsRiskAnalysis1.PR_Employee[i].Vacations = Math.Round(Convert.ToDecimal(Convert.ToDecimal(salary / 30 * vacationBalance)), 2);
            }
        }
    }
}
