// Data-access shim for the oracle: the members of the typed dataset dsRiskAnalysis that
// rptRiskAnalysis.BeforePrint touches, filled with the legacy xsd queries verbatim.
// PR_Employee is a real DataTable built from the xsd column definitions (DefaultValue 0 on
// RiskAmount / Vacations / Compensation / Others, Total = Expression) so Total is computed by
// ADO.NET exactly as in the legacy report.
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Microsoft.Data.SqlClient;

namespace Payroll.Reports.HR.RiskAnalysis
{
    public class dsRiskAnalysis
    {
        public PR_EmployeeDataTable PR_Employee = new PR_EmployeeDataTable();
        public List<PR_EmployeeIncomeRow> PR_EmployeeIncome = new List<PR_EmployeeIncomeRow>();
        public List<Pr_EndServicePolicyDetailRow> Pr_EndServicePolicyDetail = new List<Pr_EndServicePolicyDetailRow>();
        public List<Pr_IncomeEndServicePolicyDetailRow> Pr_IncomeEndServicePolicyDetail = new List<Pr_IncomeEndServicePolicyDetailRow>();
        public Pr_VacationBalanceDataTable Pr_VacationBalance = new Pr_VacationBalanceDataTable();

        const string EmployeeSql = @"WITH EmployeeCurrencies AS (
SELECT DISTINCT IncomeCurrency,EmployeeId FROM dbo.PR_EmployeeIncome
)
SELECT        PR_Employee.EmployeeId,CurrencyId,CASE WHEN @IsArabic = 1 THEN EmployeeArabicName ELSE  PR_Employee.EmployeeName END AS EmployeeName,CASE WHEN @IsArabic = 1 THEN CurrencyNameArabic ELSE  CurrencyName END AS CurrencyName, PR_Employee.DateOfWork, PR_Employee.EmployeeNumber, PR_Job.JobName, PR_Employee.EndServicePolicyId
FROM            PR_Employee
INNER JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
INNER JOIN EmployeeCurrencies ON EmployeeCurrencies.EmployeeId = PR_Employee.EmployeeId
INNER JOIN dbo.Acc_Currency ON  EmployeeCurrencies.IncomeCurrency=CurrencyId
WHERE        (PR_Employee.EmployeeId IN
                             (SELECT        number
                                FROM            dbo.Acc_ConvertIntListToTable(@employees) AS Acc_ConvertIntListToTable_1))
								AND @IsArabic=@IsArabic";

        const string IncomeSql = @"SELECT  *
FROM    dbo.PR_EmployeeIncome
WHERE   EmployeeId IN ( SELECT  *
                        FROM    dbo.Acc_ConvertIntListToTable(@Employees) )
AND	((SELECT TOP 1 SelectSeparateInsuranceItem FROM dbo.PR_SystemConfiguration) = 0 OR SocialInsuranceRoleId IS NULL)";

        public void Fill(SqlConnection cn, string employees, bool isArabic, DateTime vacDate)
        {
            using (var cmd = new SqlCommand(EmployeeSql, cn))
            {
                cmd.Parameters.Add("@IsArabic", SqlDbType.Bit).Value = isArabic;
                cmd.Parameters.Add("@employees", SqlDbType.NVarChar, -1).Value = (object)employees ?? DBNull.Value;
                new SqlDataAdapter(cmd).Fill(PR_Employee.Table);
            }
            using (var cmd = new SqlCommand(IncomeSql, cn))
            {
                cmd.Parameters.Add("@Employees", SqlDbType.NVarChar, -1).Value = (object)employees ?? DBNull.Value;
                using (var r = cmd.ExecuteReader())
                    while (r.Read())
                        PR_EmployeeIncome.Add(new PR_EmployeeIncomeRow
                        {
                            EmployeeId = (int)r["EmployeeId"],
                            IncomeId = (int)r["IncomeId"],
                            IncomeCurrency = (int)r["IncomeCurrency"],
                            IncomeAmount = (decimal)r["IncomeAmount"],
                            IncomeStartDate = (DateTime)r["IncomeStartDate"],
                        });
            }
            using (var cmd = new SqlCommand("SELECT  *\r\nFROM    dbo.Pr_EndServicePolicyDetail", cn))
            using (var r = cmd.ExecuteReader())
                while (r.Read())
                    Pr_EndServicePolicyDetail.Add(new Pr_EndServicePolicyDetailRow
                    {
                        EndServicePolicyDetailId = (int)r["EndServicePolicyDetailId"],
                        _EndServicePolicyId = r["EndServicePolicyId"] as int?,
                        _BounsMonthesPerYear = r["BounsMonthesPerYear"] as decimal?,
                        _WorkingYearsFrom = r["WorkingYearsFrom"] as decimal?,
                        _WorkingYearsTo = r["WorkingYearsTo"] as decimal?,
                    });
            using (var cmd = new SqlCommand("SELECT  *\r\nFROM    dbo.Pr_IncomeEndServicePolicyDetail", cn))
            using (var r = cmd.ExecuteReader())
                while (r.Read())
                    Pr_IncomeEndServicePolicyDetail.Add(new Pr_IncomeEndServicePolicyDetailRow
                    {
                        _IncomeId = r["IncomeId"] as int?,
                        _EndServicePolicyDetailId = r["EndServicePolicyDetailId"] as int?,
                    });
            using (var cmd = new SqlCommand("dbo.Pr_VacationBalance", cn) { CommandType = CommandType.StoredProcedure })
            {
                cmd.Parameters.Add("@EmployeeIds", SqlDbType.NVarChar, -1).Value = (object)employees ?? DBNull.Value;
                cmd.Parameters.Add("@atDate", SqlDbType.DateTime).Value = vacDate;
                cmd.Parameters.Add("@PaidVacation", SqlDbType.Bit).Value = DBNull.Value;
                cmd.Parameters.Add("@IsArabic", SqlDbType.Bit).Value = isArabic;
                using (var r = cmd.ExecuteReader())
                    while (r.Read())
                        Pr_VacationBalance.Add(new Pr_VacationBalanceRow
                        {
                            EmployeeId = (int)r["EmployeeId"],
                            _PaidVactions = r["PaidVactions"] as decimal?,
                            _VacationBalance = r["VacationBalance"] as decimal?,
                        });
            }
        }
    }

    public class PR_EmployeeDataTable
    {
        public readonly DataTable Table = new DataTable("PR_Employee");

        public PR_EmployeeDataTable()
        {
            Table.Columns.Add("EmployeeId", typeof(int));
            Table.Columns.Add("EmployeeName", typeof(string));
            Table.Columns.Add("DateOfWork", typeof(DateTime)).AllowDBNull = false;
            Table.Columns.Add("EmployeeNumber", typeof(string)).AllowDBNull = false;
            Table.Columns.Add("JobName", typeof(string));
            Table.Columns.Add("DaysOfWork", typeof(int));
            Table.Columns.Add("MonthesOfWork", typeof(int));
            Table.Columns.Add("NetYearsOfWork", typeof(int));
            Table.Columns.Add("YearsOfWork", typeof(int));
            Table.Columns.Add("RiskAmount", typeof(decimal)).DefaultValue = 0m;
            Table.Columns.Add("Vacations", typeof(decimal)).DefaultValue = 0m;
            Table.Columns.Add("Compensation", typeof(decimal)).DefaultValue = 0m;
            Table.Columns.Add("Others", typeof(decimal)).DefaultValue = 0m;
            Table.Columns.Add("Total", typeof(decimal), "RiskAmount+Others+Compensation+Vacations").ReadOnly = true;
            Table.Columns.Add("VacationBalance", typeof(decimal));
            Table.Columns.Add("EndServicePolicyId", typeof(int));
            Table.Columns.Add("CurrencyId", typeof(int));
            Table.Columns.Add("CurrencyName", typeof(string));
        }

        public int Count => Table.Rows.Count;
        public PR_EmployeeRow this[int i] => new PR_EmployeeRow(Table.Rows[i]);
    }

    public class PR_EmployeeRow
    {
        readonly DataRow r;
        public PR_EmployeeRow(DataRow row) { r = row; }
        public DataRow Row => r;
        public int EmployeeId => (int)r["EmployeeId"];
        public int CurrencyId => (int)r["CurrencyId"];
        public DateTime DateOfWork => (DateTime)r["DateOfWork"];
        public int EndServicePolicyId => (int)r["EndServicePolicyId"];
        public bool IsEndServicePolicyIdNull() => r.IsNull("EndServicePolicyId");
        public int DaysOfWork { get => (int)r["DaysOfWork"]; set => r["DaysOfWork"] = value; }
        public int MonthesOfWork { get => (int)r["MonthesOfWork"]; set => r["MonthesOfWork"] = value; }
        public int YearsOfWork { get => (int)r["YearsOfWork"]; set => r["YearsOfWork"] = value; }
        public int NetYearsOfWork { get => (int)r["NetYearsOfWork"]; set => r["NetYearsOfWork"] = value; }
        public decimal RiskAmount { get => (decimal)r["RiskAmount"]; set => r["RiskAmount"] = value; }
        public decimal Compensation { get => (decimal)r["Compensation"]; set => r["Compensation"] = value; }
        public decimal VacationBalance { get => (decimal)r["VacationBalance"]; set => r["VacationBalance"] = value; }
        public decimal Vacations { get => (decimal)r["Vacations"]; set => r["Vacations"] = value; }
    }

    public class PR_EmployeeIncomeRow
    {
        public int EmployeeId, IncomeId, IncomeCurrency;
        public decimal IncomeAmount;
        public DateTime IncomeStartDate;
    }

    public class Pr_EndServicePolicyDetailRow
    {
        public int EndServicePolicyDetailId;
        public int? _EndServicePolicyId;
        public decimal? _BounsMonthesPerYear, _WorkingYearsFrom, _WorkingYearsTo;
        // .Value throws on NULL, as the typed-dataset getter does
        public int EndServicePolicyId => _EndServicePolicyId.Value;
        public decimal BounsMonthesPerYear => _BounsMonthesPerYear.Value;
        public decimal WorkingYearsFrom => _WorkingYearsFrom.Value;
        public decimal WorkingYearsTo => _WorkingYearsTo.Value;
    }

    public class Pr_IncomeEndServicePolicyDetailRow
    {
        public int? _IncomeId, _EndServicePolicyDetailId;
        public int IncomeId => _IncomeId.Value;
        public int EndServicePolicyDetailId => _EndServicePolicyDetailId.Value;
    }

    public class Pr_VacationBalanceRow
    {
        public int EmployeeId;
        public decimal? _PaidVactions, _VacationBalance;
        public bool IsPaidVactionsNull() => !_PaidVactions.HasValue;
        public bool IsVacationBalanceNull() => !_VacationBalance.HasValue;
        public decimal PaidVactions => _PaidVactions.Value;
        public decimal VacationBalance => _VacationBalance.Value;
    }

    public class Pr_VacationBalanceDataTable
    {
        readonly Dictionary<int, Pr_VacationBalanceRow> rows = new Dictionary<int, Pr_VacationBalanceRow>();
        public int Misses;

        // the typed table has PrimaryKey EmployeeId: a duplicate makes Fill throw
        public void Add(Pr_VacationBalanceRow row) => rows.Add(row.EmployeeId, row);

        // Legacy returns null here and BeforePrint crashes on the next line. Decision D2: a missing
        // row counts as 0, so hand back a row whose values are NULL (read as 0 by the verbatim code).
        public Pr_VacationBalanceRow FindByEmployeeId(int employeeId)
        {
            if (rows.TryGetValue(employeeId, out var row)) return row;
            Misses++;
            return new Pr_VacationBalanceRow { EmployeeId = employeeId };
        }
    }
}
