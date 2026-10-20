using DevExpress.XtraReports.UI;
using AnalyticsReader.Api.ODataViews.GL.IncomeStatementBudgetReports;
namespace Gen {
public static class Exp {
  public static void Run(string mode) {
    string[] exprs = { "[][[Section] = 'Summary'].Count() > 0", "[][[Section] = 'Dimension'].Count() > 0", "[][[Section] = 'Summary'].Exists()", "[][[Section] = 'Dimension'].Exists()", "[DataSource.RowCount] > 0" };
    foreach (var e in exprs) {
      var r = new XtraReport();
      r.Bands.Add(new DetailBand{HeightF=0, Visible=false}); var gh = new GroupHeaderBand(); r.Bands.Add(gh);
      var sb = new SubBand{HeightF=50}; gh.SubBands.Add(sb);
      var l = new XRLabel{Text="SHOWN"}; sb.Controls.Add(l);
      sb.ExpressionBindings.Add(new ExpressionBinding("BeforePrint","Visible", e));
      r.DataSource = new List<CostCenterIncomeBudgetComparisonReport>{ new(){Section="Dimension"}, new(){Section="Dimension"} };
      try { r.ExportToText("exp.txt"); Console.WriteLine(e + " => " + File.ReadAllText("exp.txt").Trim()); } catch (Exception ex) { Console.WriteLine(e + " => ERR " + ex.Message); }
    }
  }
}}
