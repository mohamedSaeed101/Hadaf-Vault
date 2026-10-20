// Risk Analysis parity oracle: legacy rptRiskAnalysis.BeforePrint (verbatim) vs dbo.PR_RiskAnalysisReport.
// Credentials come from ACCFLEX_DB_USER / ACCFLEX_DB_PASSWORD (source C:\Hadaf_Work\.env.local first).
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using Microsoft.Data.SqlClient;
using Payroll.Reports.HR.RiskAnalysis;

static class Program
{
    static readonly string[] Columns =
    {
        "CurrencyName", "EmployeeName", "EmployeeNumber", "JobName", "DateOfWork", "DaysOfWork", "MonthesOfWork",
        "YearsOfWork", "NetYearsOfWork", "Compensation", "RiskAmount", "VacationBalance", "Vacations", "Others", "Total"
    };

    static int Main(string[] args)
    {
        var cs = new SqlConnectionStringBuilder
        {
            DataSource = "db-all",
            InitialCatalog = "UNP-Ali",
            UserID = Environment.GetEnvironmentVariable("ACCFLEX_DB_USER"),
            Password = Environment.GetEnvironmentVariable("ACCFLEX_DB_PASSWORD"),
            TrustServerCertificate = true,
        }.ConnectionString;

        using var cn = new SqlConnection(cs);
        cn.Open();

        string all;
        using (var cmd = new SqlCommand("SELECT STRING_AGG(CAST(EmployeeId AS NVARCHAR(MAX)), ',') FROM dbo.PR_Employee WHERE EndWork = 0", cn))
            all = (string)cmd.ExecuteScalar();

        var dates = new[]
        {
            "2026-10-15 14:37:21", // today with a time part (controller: MinValue -> DateTime.Now)
            "2026-10-15",          // today; hires of Jul..Sep 2026 are under 90 days
            "2026-09-30",          // month-end
            "2025-12-31",          // 31 Dec
            "2026-12-31",          // 31 Dec
            "2026-03-01",          // 1 Mar, Feb borrow (non-leap); later hires swap the dates
            "2024-03-01",          // 1 Mar, Feb borrow (leap)
            "2026-01-15",          // vacDate in December of the previous year
            "2026-04-10",          // some hires of 2026-01/02 are under 90 days
            "2026-09-28",          // 89 days after the 2026-07-01 hire: not over 90
            "2026-09-29",          // 90 days after the 2026-07-01 hire: span 90.99 days, over 90
        };
        var idSets = new[] { ("all active", all), ("ids 31,30,17", "31,30,17") };

        // --fixed: compare with BeforePrintFixed (per-employee salary, decision D6) instead of the verbatim loop
        bool isFixed = args.Contains("--fixed");
        Console.WriteLine(isFixed ? "Mode: FIXED (D6, per-employee salary)" : "Mode: LEGACY (verbatim)");
        var tvfAmounts = new Dictionary<(string, bool, string, int, int), string>();
        int totalMismatches = 0;
        Console.WriteLine("| RiskDate | Ids | IsArabic | Legacy rows | TVF rows | Mismatches | Missing vacation rows | Over-90 rows | RowNo ok |");
        Console.WriteLine("|---|---|---|---|---|---|---|---|---|");
        var details = new List<string>();
        foreach (var d in dates)
        foreach (var (idName, ids) in idSets)
        foreach (var isArabic in new[] { false, true })
        {
            var atDate = DateTime.Parse(d, CultureInfo.InvariantCulture);
            var report = new rptRiskAnalysis(ids, atDate, isArabic);
            if (isFixed) report.BeforePrintFixed(cn); else report.BeforePrint(cn);
            var legacy = report.dsRiskAnalysis1.PR_Employee.Table;

            var tvf = new DataTable();
            using (var cmd = new SqlCommand("SELECT * FROM dbo.PR_RiskAnalysisReport(@EmployeeIds, @RiskDate, @IsArabic)", cn))
            {
                cmd.Parameters.Add("@EmployeeIds", SqlDbType.NVarChar, -1).Value = ids;
                cmd.Parameters.Add("@RiskDate", SqlDbType.DateTime).Value = atDate;
                cmd.Parameters.Add("@IsArabic", SqlDbType.Bit).Value = isArabic;
                new SqlDataAdapter(cmd).Fill(tvf);
            }

            var tvfByKey = tvf.Rows.Cast<DataRow>().ToDictionary(r => ((int)r["EmployeeId"], (int)r["CurrencyId"]));
            var rowNos = tvf.Rows.Cast<DataRow>().Select(r => (long)r["RowNo"]).OrderBy(x => x).ToList();
            bool rowNoOk = rowNos.SequenceEqual(Enumerable.Range(1, tvf.Rows.Count).Select(x => (long)x));

            int mism = 0, over90 = 0;
            var seen = new HashSet<(int, int)>();
            foreach (DataRow l in legacy.Rows)
            {
                var key = ((int)l["EmployeeId"], (int)l["CurrencyId"]);
                seen.Add(key);
                if ((decimal)l["RiskAmount"] != 0) over90++;
                if (!tvfByKey.TryGetValue(key, out var t))
                {
                    mism++; details.Add($"{d} {idName} ar={isArabic} {key}: missing in TVF");
                    continue;
                }
                foreach (var c in Columns)
                {
                    object lv = l[c], tv = t[c];
                    bool eq = lv is DBNull || tv is DBNull ? lv is DBNull && tv is DBNull
                        : lv is decimal ld ? ld == Convert.ToDecimal(tv)
                        : lv is int li ? li == Convert.ToInt32(tv)
                        : lv.Equals(tv);
                    if (!eq)
                    {
                        mism++;
                        details.Add($"{d} {idName} ar={isArabic} {key} {c}: legacy={Fmt(lv)} tvf={Fmt(tv)}");
                    }
                }
            }
            foreach (var key in tvfByKey.Keys.Where(k => !seen.Contains(k)))
            {
                mism++; details.Add($"{d} {idName} ar={isArabic} {key}: extra in TVF");
            }
            foreach (DataRow t in tvf.Rows)
                tvfAmounts[(d, isArabic, idName, (int)t["EmployeeId"], (int)t["CurrencyId"])] =
                    string.Join(" / ", new[] { "RiskAmount", "Compensation", "Vacations", "Total" }.Select(c => Fmt(t[c])));
            totalMismatches += mism;
            Console.WriteLine($"| {d} | {idName} | {(isArabic ? 1 : 0)} | {legacy.Rows.Count} | {tvf.Rows.Count} | {mism} | {report.dsRiskAnalysis1.Pr_VacationBalance.Misses} | {over90} | {(rowNoOk ? "yes" : "NO")} |");
        }

        Console.WriteLine();
        Console.WriteLine($"TOTAL MISMATCHES: {totalMismatches}");

        // Selection independence: the subset employees' TVF amounts against the same employees in the full run
        int subsetDiffs = 0, subsetChecked = 0;
        foreach (var kv in tvfAmounts.Where(k => k.Key.Item3 == idSets[1].Item1))
        {
            subsetChecked++;
            var fullKey = (kv.Key.Item1, kv.Key.Item2, idSets[0].Item1, kv.Key.Item4, kv.Key.Item5);
            if (tvfAmounts[fullKey] != kv.Value)
            {
                subsetDiffs++;
                details.Add($"{kv.Key.Item1} ar={kv.Key.Item2} emp {kv.Key.Item4}: subset {kv.Value} vs full {tvfAmounts[fullKey]}");
            }
        }
        Console.WriteLine($"SUBSET vs FULL (RiskAmount / Compensation / Vacations / Total): {subsetChecked} rows checked, {subsetDiffs} differ");
        var distinctRisk = tvfAmounts.Where(k => k.Key.Item1 == "2026-10-15" && !k.Key.Item2 && k.Key.Item3 == idSets[0].Item1)
            .Select(k => k.Value.Split(" / ")[0]).Distinct().Count();
        Console.WriteLine($"Distinct RiskAmount values, 2026-10-15 full run: {distinctRisk}");
        foreach (var kv in tvfAmounts.Where(k => k.Key.Item1 == "2026-10-15" && !k.Key.Item2 && (k.Key.Item4 == 17 || k.Key.Item4 == 31)).OrderBy(k => k.Key.Item4))
            Console.WriteLine($"Sample 2026-10-15 {kv.Key.Item3} emp {kv.Key.Item4}: {kv.Value}");
        foreach (var line in details.Take(200)) Console.WriteLine(line);
        return totalMismatches == 0 ? 0 : 1;
    }

    static string Fmt(object v) => v is DBNull ? "NULL" : v is DateTime dt ? dt.ToString("yyyy-MM-dd HH:mm:ss.fff") : Convert.ToString(v, CultureInfo.InvariantCulture);
}
