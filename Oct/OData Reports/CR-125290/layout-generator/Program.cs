using System.Drawing;
using System.Text;
using DevExpress.Drawing;
using DevExpress.DataAccess.ObjectBinding;
using DevExpress.XtraPivotGrid;
using DevExpress.XtraPrinting;
using Parameter = DevExpress.XtraReports.Parameters.Parameter;
using DevExpress.XtraReports.UI;
using DevExpress.XtraReports.UI.PivotGrid;
using AnalyticsReader.Api.ODataViews.GL.IncomeStatementBudgetReports;

namespace AnalyticsReader.Api.ODataViews.GL.IncomeStatementBudgetReports
{
    public class IncomeStatementCostCenterPeriodBudgetReport
    {
        public long RowNo { get; set; }
        public int? SortOrder { get; set; }
        public string? RowType { get; set; }
        public int? DimensionId { get; set; }
        public string? DimensionNo { get; set; }
        public string? DimensionName { get; set; }
        public int? AccountTypeId { get; set; }
        public string? AccountTypeName { get; set; }
        public string? AccountTypeNameArabic { get; set; }
        public decimal? PeriodBalance { get; set; }
        public decimal? PeriodBudget { get; set; }
        public decimal? BudgetDiff { get; set; }
        public decimal? LastBalance { get; set; }
        public decimal? LastBalanceDiff { get; set; }
        public decimal? YearToPeriodBalance { get; set; }
        public decimal? YearToPeriodBudget { get; set; }
        public decimal? YearToPeriodBudgetDiff { get; set; }
        public decimal? LastYearToPeriodBalance { get; set; }
        public decimal? LastYearToPeriodBalanceDiff { get; set; }
    }
    public class IncomeStatementBranchPeriodBudgetReport : IncomeStatementCostCenterPeriodBudgetReport { }

    public class CostCenterIncomeBudgetComparisonReport
    {
        public long RowNo { get; set; }
        public string? Section { get; set; }
        public int? DimensionId { get; set; }
        public string? DimensionName { get; set; }
        public int? AccountTypeId { get; set; }
        public string? AccountTypeName { get; set; }
        public string? AccountTypeNameArabic { get; set; }
        public int? MonthNo { get; set; }
        public string? MonthName { get; set; }
        public string? MonthNameArabic { get; set; }
        public decimal? Budget { get; set; }
        public decimal? Actual { get; set; }
    }
    public class BranchIncomeBudgetComparisonReport : CostCenterIncomeBudgetComparisonReport { }

    public class IncomeStatementPerMonthReport
    {
        public long RowNo { get; set; }
        public string? RowType { get; set; }
        public int? MainItemId { get; set; }
        public string? MainItemName { get; set; }
        public string? MainItemNameArabic { get; set; }
        public int? IncomeStatmentSubItemId { get; set; }
        public string? SubItemName { get; set; }
        public int? OrderInReport { get; set; }
        public int? MonthNo { get; set; }
        public string? MonthName { get; set; }
        public string? MonthNameArabic { get; set; }
        public decimal? Balance { get; set; }
    }
}

namespace Gen
{
    record Filter(string Ar, string En, string Expr);

    static class G
    {
        public const float PageW = 2970, MarginX = 100, W = PageW - 2 * MarginX;
        public static readonly Color TitleBack = Color.FromArgb(255, 139, 146, 153);
        public static readonly Color HeadBack = Color.FromArgb(255, 144, 151, 158);
        public static DXFont F(float size, DXFontStyle style = DXFontStyle.Regular) => new("Arial", size, style);

        public static XtraReport NewReport(string reportName, Type entity, bool ar)
        {
            var r = new XtraReport
            {
                Name = "rpt" + reportName,
                DisplayName = reportName,
                ReportUnit = ReportUnit.TenthsOfAMillimeter,
                Landscape = true,
                PaperKind = DevExpress.Drawing.Printing.DXPaperKind.A4,
                Font = F(9.75f),
                Version = "24.2",
            };
            r.Margins = new DevExpress.Drawing.DXMargins(100, 100, 50, 50);
            if (ar)
            {
                r.RightToLeft = DevExpress.XtraReports.UI.RightToLeft.Yes;
                r.RightToLeftLayout = RightToLeftLayout.Yes;
            }
            r.DataSource = new ObjectDataSource { DataSource = typeof(List<>).MakeGenericType(entity) };
            r.Extensions["DataSerializationExtension"] = "DevExpress.XtraReports.Web.ReportDesigner.DefaultDataSerializer";
            r.Bands.Add(new TopMarginBand { Dpi = 254f, Name = "topMarginBand1", HeightF = 50 });
            r.Bands.Add(new BottomMarginBand { Dpi = 254f, Name = "bottomMarginBand1", HeightF = 50 });
            foreach (var p in new[] { "CompanyName", "Address", "Telephone", "Email", "Fax" })
                AddParam(r, p);
            r.Parameters.Add(new Parameter { Name = "Logo", Description = "Logo", Visible = false, Type = typeof(byte[]) });
            return r;
        }

        public static void AddParam(XtraReport r, string name) =>
            r.Parameters.Add(new Parameter { Name = name, Description = name, Visible = false });

        public static void Bind(XRControl c, string prop, string expr) =>
            c.ExpressionBindings.Add(new ExpressionBinding("BeforePrint", prop, expr));

        public static XRLabel Label(string name, string text, float x, float y, float w, float h, DXFont font,
            TextAlignment ta = TextAlignment.MiddleLeft, string? expr = null)
        {
            var l = new XRLabel { Dpi = 254f, Name = name, Text = text, LocationF = new PointF(x, y), SizeF = new SizeF(w, h), Font = font, TextAlignment = ta, Padding = new PaddingInfo(5, 5, 0, 0, 254) };
            if (expr != null) Bind(l, "Text", expr);
            return l;
        }

        // Company block, title banner and filter grid; returns the y below them.
        public static float Header(Band band, bool ar, string title, Filter[][] filterRows)
        {
            var pic = new XRPictureBox { Dpi = 254f, Name = "pictureBox1", Sizing = DevExpress.XtraPrinting.ImageSizeMode.ZoomImage, LocationF = new PointF(0, 5), SizeF = new SizeF(300, 290) };
            Bind(pic, "ImageSource", "?Logo");
            band.Controls.Add(pic);
            band.Controls.Add(Label("lblCompany", "lblCompany", 310, 0, 1000, 116, F(12, DXFontStyle.Bold), expr: "?CompanyName"));
            band.Controls.Add(Label("lblAddress", "lblAddress", 310, 116, 1000, 73, F(9.75f), expr: "?Address"));
            string[] caps = ar ? new[] { "البريد الإلكتروني :", "الهاتف :", "الفاكس :" } : new[] { "Email :", "Tel :", "Fax :" };
            string[] names = { "Email", "Tel", "Fax" };
            string[] pars = { "?Email", "?Telephone", "?Fax" };
            for (int i = 0; i < 3; i++)
            {
                band.Controls.Add(Label($"lbl{names[i]}Cap", caps[i], W - 917, 58 * i, 355, 58, F(9.75f, DXFontStyle.Bold)));
                band.Controls.Add(Label($"lbl{names[i]}", $"lbl{names[i]}", W - 562, 58 * i, 562, 58, F(9.75f), expr: pars[i]));
            }
            band.Controls.Add(new XRLine { Dpi = 254f, Name = "line1", LineWidth = 2, LocationF = new PointF(0, 300), SizeF = new SizeF(W, 10) });
            var t = Label("lblTitle", title, 0, 310, W, 82, F(13, DXFontStyle.Bold), TextAlignment.MiddleCenter);
            t.BackColor = TitleBack; t.ForeColor = Color.Black;
            band.Controls.Add(t);

            // Each row holds up to three caption/value pairs; a shorter row widens its last value cell so
            // every cell boundary falls on a boundary of a full row (Excel export).
            var tbl = Table("tblFilters", ar, 0, 410, W, 58 * filterRows.Length, F(9.75f));
            tbl.Borders = BorderSide.All;
            int n = 0;
            foreach (var fr in filterRows)
            {
                var row = new XRTableRow { Dpi = 254f, Name = $"tblFiltersRow{n}", Weight = 1 };
                for (int i = 0; i < fr.Length; i++)
                {
                    var cap = new XRTableCell { Dpi = 254f, Name = $"fCap{n}{i}", Weight = 1, Text = ar ? fr[i].Ar : fr[i].En, Font = F(9.75f, DXFontStyle.Bold), ForeColor = Color.Black, BackColor = TitleBack };
                    float vw = 2.4f + (i == fr.Length - 1 ? (3 - fr.Length) * 3.4f : 0);
                    var val = new XRTableCell { Dpi = 254f, Name = $"fVal{n}{i}", Weight = vw, Text = $"fVal{n}{i}" };
                    Bind(val, "Text", fr[i].Expr);
                    row.Cells.Add(cap); row.Cells.Add(val);
                }
                tbl.Rows.Add(row);
                n++;
            }
            band.Controls.Add(tbl);
            return 410 + 58 * filterRows.Length + 15;
        }

        public static XRTable Table(string name, bool ar, float x, float y, float w, float h, DXFont font)
        {
            var t = new XRTable { Dpi = 254f, Name = name, LocationF = new PointF(x, y), SizeF = new SizeF(w, h), Font = font, TextAlignment = TextAlignment.MiddleCenter };
            if (ar) t.RightToLeft = DevExpress.XtraReports.UI.RightToLeft.Yes;
            return t;
        }

        public static void PageFooter(XtraReport r, bool ar)
        {
            var b = new PageFooterBand { Dpi = 254f, Name = "PageFooter", HeightF = 58 };
            b.Controls.Add(Label("lblPowered", "Powered by : www.accflex.com", 0, 0, 900, 58, F(9.75f), TextAlignment.MiddleCenter));
            b.Controls.Add(new XRPageInfo { Dpi = 254f, Name = "pageInfoDate", PageInfo = PageInfo.DateTime, TextFormatString = ar ? "طبع في {0:dd/MM/yyyy hh:mm tt}" : "Printed On {0:dd/MM/yyyy hh:mm tt}", TextAlignment = TextAlignment.MiddleCenter, LocationF = new PointF(1000, 0), SizeF = new SizeF(900, 58), Padding = new PaddingInfo(5, 5, 0, 0, 254) });
            b.Controls.Add(new XRPageInfo { Dpi = 254f, Name = "pageInfoNumber", PageInfo = PageInfo.NumberOfTotal, TextFormatString = ar ? "صفحة {0} من {1}" : "Page {0} Of {1}", TextAlignment = TextAlignment.MiddleRight, LocationF = new PointF(W - 500, 0), SizeF = new SizeF(500, 58), Padding = new PaddingInfo(5, 5, 0, 0, 254) });
            r.Bands.Add(b);
        }

        public static string Xml(XtraReport r)
        {
            using var ms = new MemoryStream();
            r.SaveLayoutToXml(ms);
            var s = new UTF8Encoding(false).GetString(ms.ToArray()).TrimStart('﻿');
            return s.Replace("\r\n", "\n").Replace("\n", "\r\n");
        }
    }

    // R1 / R2: one row per TVF row, in RowNo order, styled by RowType.
    static class PeriodBudget
    {
        static readonly string[] Fields = { "PeriodBalance", "PeriodBudget", "BudgetDiff", "LastBalance", "LastBalanceDiff", "YearToPeriodBalance", "YearToPeriodBudget", "YearToPeriodBudgetDiff", "LastYearToPeriodBalance", "LastYearToPeriodBalanceDiff" };
        const float DescW = 2f;
        const string Totals = "[RowType] In ('GrossProfit', 'TotalGrossProfit', 'NetProfit')";

        public static XtraReport Build(string reportName, Type entity, bool ar, bool branch)
        {
            var r = G.NewReport(reportName, entity, ar);
            foreach (var p in new[] { "periodStart", "periodEnd", "journalReviseFilter", "journalTypeFilter", branch ? "branchFilter" : "costCenterFilter", "periodCaption", "lastPeriodCaption", "yearToDateCaption", "lastYearToDateCaption", "yearsCaption" })
                G.AddParam(r, p);

            var ph = new PageHeaderBand { Dpi = 254f, Name = "PageHeader" };
            string title = branch
                ? (ar ? "تقرير قائمة الدخل مقارن فروع شهر / سنه" : "Income Statement By Branch Year To Date Report")
                : (ar ? "تقرير قائمة الدخل مقارن مراكز تكلفة شهر / سنه" : "Income Statement By Cost Center Year To Date Report");
            float y = G.Header(ph, ar, title, new[]
            {
                new[] { new Filter("من تاريخ", "From Date", "?periodStart"), new Filter("الي تاريخ", "To Date", "?periodEnd"), new Filter("القيود", "Journals", "?journalReviseFilter") },
                new[] { new Filter("أنواع القيود", "Journal Types", "?journalTypeFilter"), branch ? new Filter("الفروع", "Branches", "?branchFilter") : new Filter("مراكز التكلفة", "Cost Centers", "?costCenterFilter") },
            });

            // Three header rows: block captions, column captions, period captions (legacy clPeriod/clYearDate cells).
            var head = G.Table("tblHead", ar, 0, y, G.W, 165, G.F(8.5f, DXFontStyle.Bold));
            head.ForeColor = Color.White; head.BackColor = G.HeadBack; head.Borders = BorderSide.All;
            var rowA = new XRTableRow { Dpi = 254f, Name = "tblHeadRowA", Weight = 1 };
            rowA.Cells.Add(new XRTableCell { Dpi = 254f, Name = "hA0", Weight = DescW, Text = "" });
            rowA.Cells.Add(new XRTableCell { Dpi = 254f, Name = "hA1", Weight = 5, Text = ar ? "الفترة" : "Period" });
            rowA.Cells.Add(new XRTableCell { Dpi = 254f, Name = "hA2", Weight = 5, Text = ar ? "من اول العام لنهاية الفتره" : "Year To Date" });
            string[] capsAr = { "الرصيد", "التقديري", "الانحراف التقديري", "السنه السابقه", "الانحراف عن السنه السابقه" };
            string[] capsEn = { "Balance", "Budget", "B. Deviation", "Last Year", "LY Deviation" };
            string[] periodPars = { "?periodCaption", "?periodCaption", "?periodCaption", "?lastPeriodCaption", "?yearsCaption", "?yearToDateCaption", "?yearToDateCaption", "?yearToDateCaption", "?lastYearToDateCaption", "?yearsCaption" };
            var rowB = new XRTableRow { Dpi = 254f, Name = "tblHeadRowB", Weight = 1 };
            var rowC = new XRTableRow { Dpi = 254f, Name = "tblHeadRowC", Weight = 1 };
            rowB.Cells.Add(new XRTableCell { Dpi = 254f, Name = "hB0", Weight = DescW, Text = ar ? "التفاصيل" : "Description" });
            rowC.Cells.Add(new XRTableCell { Dpi = 254f, Name = "hC0", Weight = DescW, Text = "" });
            for (int i = 0; i < 10; i++)
            {
                rowB.Cells.Add(new XRTableCell { Dpi = 254f, Name = $"hB{i + 1}", Weight = 1, Text = ar ? capsAr[i % 5] : capsEn[i % 5] });
                var c = new XRTableCell { Dpi = 254f, Name = $"hC{i + 1}", Weight = 1, Text = "" };
                G.Bind(c, "Text", periodPars[i]);
                rowC.Cells.Add(c);
            }
            head.Rows.AddRange(new[] { rowA, rowB, rowC });
            ph.Controls.Add(head);
            ph.HeightF = y + 165;
            r.Bands.Add(ph);

            // Dimension rows group per dimension; the rows after them group per RowType.
            r.CalculatedFields.Add(new CalculatedField
            {
                Name = "SectionKey",
                FieldType = FieldType.String,
                Expression = "Iif([RowType] In ('AccountType', 'GrossProfit', 'GrossProfitPercent'), 'D' + Iif(IsNull([DimensionNo]), '', [DimensionNo]), [RowType])",
            });
            var gh = new GroupHeaderBand { Dpi = 254f, Name = "ghSection", GroupUnion = GroupUnion.WithFirstDetail, KeepTogether = true, RepeatEveryPage = true, HeightF = 60 };
            gh.GroupFields.Add(new GroupField("SectionKey", XRColumnSortOrder.None));
            G.Bind(gh, "Visible", "[RowType] In ('AccountType', 'GrossProfit', 'GrossProfitPercent', 'OtherAccountType')");
            var gt = G.Table("tblSection", ar, 0, 0, G.W, 60, G.F(9.75f, DXFontStyle.Bold));
            gt.Borders = BorderSide.All;
            var grow = new XRTableRow { Dpi = 254f, Name = "tblSectionRow0", Weight = 1 };
            var gcap = new XRTableCell { Dpi = 254f, Name = "sCap", Weight = DescW, Text = "sCap", BackColor = Color.DarkGray, ForeColor = Color.Black };
            G.Bind(gcap, "Text", ar
                ? $"Iif([RowType] = 'OtherAccountType', 'بنود أخرى', '{(branch ? "الفرع" : "مركز التكلفة")}')"
                : $"Iif([RowType] = 'OtherAccountType', 'Other Items', '{(branch ? "Branch" : "Cost Center")}')");
            var gval = new XRTableCell { Dpi = 254f, Name = "sVal", Weight = 10, Text = "sVal", BackColor = Color.WhiteSmoke, TextAlignment = TextAlignment.MiddleLeft, Padding = new PaddingInfo(10, 10, 0, 0, 254) };
            G.Bind(gval, "Text", "Iif([RowType] = 'OtherAccountType', '', [DimensionName])");
            grow.Cells.Add(gcap); grow.Cells.Add(gval);
            gt.Rows.Add(grow);
            gh.Controls.Add(gt);
            r.Bands.Add(gh);

            var d = new DetailBand { Dpi = 254f, Name = "Detail", KeepTogether = true, HeightF = 55 };
            d.SortFields.Add(new GroupField("RowNo", XRColumnSortOrder.Ascending));
            var t = G.Table("tblRow", ar, 0, 0, G.W, 55, G.F(8.5f));
            t.Borders = BorderSide.Left | BorderSide.Right | BorderSide.Bottom;
            G.Bind(t, "BackColor", "Iif([RowType] In ('TotalGrossProfit', 'NetProfit'), 'Silver', [RowType] = 'GrossProfit', 'Gainsboro', 'White')");
            G.Bind(t, "Font.Bold", Totals);
            G.Bind(t, "Font.Italic", "[RowType] = 'GrossProfitPercent'");
            G.Bind(t, "Borders", $"Iif({Totals}, 'All', 'Left, Right, Bottom')");
            var row = new XRTableRow { Dpi = 254f, Name = "tblRowRow0", Weight = 1 };
            var desc = new XRTableCell { Dpi = 254f, Name = "dDesc", Weight = DescW, Text = "dDesc", TextAlignment = TextAlignment.MiddleLeft, Padding = new PaddingInfo(10, 10, 0, 0, 254) };
            G.Bind(desc, "Text", ar ? "[AccountTypeNameArabic]" : "[AccountTypeName]");
            row.Cells.Add(desc);
            for (int i = 0; i < 10; i++)
            {
                var c = new XRTableCell { Dpi = 254f, Name = $"d{i}", Weight = 1, Text = $"d{i}", TextFormatString = "{0:N2}" };
                G.Bind(c, "Text", $"[{Fields[i]}]");
                G.Bind(c, "TextFormatString", "Iif([RowType] = 'GrossProfitPercent', '{0:P2}', '{0:N2}')");
                row.Cells.Add(c);
            }
            t.Rows.Add(row);
            d.Controls.Add(t);
            r.Bands.Add(d);

            G.PageFooter(r, ar);
            return r;
        }
    }

    static class Pivots
    {
        // XRPivotGrid field and row-header widths are in pixels (96 per inch), not report units.
        public const int MonthPx = 58;

        public static XRPivotGrid NewPivot(string name, bool ar, float y)
        {
            var pg = new XRPivotGrid { Dpi = 254f, Name = name, LocationF = new PointF(0, y), SizeF = new SizeF(G.W, 150) };
            if (ar) pg.RightToLeft = DevExpress.XtraReports.UI.RightToLeft.Yes;
            pg.OptionsView.ShowColumnHeaders = false;
            pg.OptionsView.ShowDataHeaders = false;
            pg.OptionsView.ShowRowHeaders = false;
            pg.OptionsView.ShowFilterHeaders = false;
            pg.OptionsPrint.UsePrintAppearance = true;
            pg.OptionsPrint.PrintColumnAreaOnEveryPage = true;
            var a = pg.Appearance;
            a.Cell.Font = G.F(7f);
            a.FieldValue.Font = G.F(7f, DXFontStyle.Bold);
            a.FieldValue.BackColor = G.HeadBack; a.FieldValue.ForeColor = Color.White;
            a.FieldValueTotal.Font = G.F(7f, DXFontStyle.Bold);
            a.FieldValueTotal.BackColor = Color.Gainsboro; a.FieldValueTotal.ForeColor = Color.Black;
            a.FieldValueGrandTotal.Font = G.F(7f, DXFontStyle.Bold);
            a.FieldValueGrandTotal.BackColor = Color.Silver; a.FieldValueGrandTotal.ForeColor = Color.Black;
            a.TotalCell.Font = G.F(7f, DXFontStyle.Bold);
            a.TotalCell.BackColor = Color.Gainsboro;
            a.GrandTotalCell.Font = G.F(6.5f, DXFontStyle.Bold);
            a.GrandTotalCell.BackColor = Color.Silver;
            a.CustomTotalCell.Font = G.F(7f, DXFontStyle.Bold);
            a.CustomTotalCell.BackColor = Color.Gainsboro;
            a.Lines.ForeColor = Color.DarkGray;
            return pg;
        }

        public static XRPivotGridField Field(XRPivotGrid pg, string name, string fieldName, PivotArea area, int areaIndex, string caption = "", int widthPx = 0, bool visible = true)
        {
            var f = new XRPivotGridField(fieldName, area) { Name = name, AreaIndex = areaIndex, Caption = caption, Visible = visible };
            if (widthPx > 0) f.Width = widthPx;
            pg.Fields.Add(f);
            return f;
        }

        // A row total whose header reads `format` ({0} = the field value). Custom totals are used because the
        // pivot's own total and grand-total headers only show DevExpress's localized "Total" / "Grand Total".
        public static void CustomTotal(XRPivotGridField f, string format)
        {
            f.TotalsVisibility = PivotTotalsVisibility.CustomTotals;
            var t = f.CustomTotals.Add(DevExpress.Data.PivotGrid.PivotSummaryType.Sum);
            t.Format.FormatType = DevExpress.Utils.FormatType.Custom;
            t.Format.FormatString = format;
        }

        // The row grand total with its own caption: an outermost constant row field whose custom total stands in for it.
        public static void RowGrandTotal(XRPivotGrid pg, string prefix, string caption)
        {
            pg.OptionsView.ShowRowGrandTotals = false;
            var all = new XRPivotGridField("", PivotArea.RowArea) { Name = prefix + "All", AreaIndex = 0, UnboundType = DevExpress.Data.UnboundColumnType.String, UnboundExpression = "''", UnboundFieldName = prefix + "AllValue", Width = 6 };
            pg.Fields.Add(all);
            CustomTotal(all, caption + "{0}");
        }

        // Month columns in calendar order: the hidden MonthNo data field drives the sort.
        public static void MonthColumns(XRPivotGrid pg, string prefix, bool ar)
        {
            var no = Field(pg, prefix + "MonthNo", "MonthNo", PivotArea.DataArea, 9, "MonthNo", visible: false);
            var m = Field(pg, prefix + "Month", ar ? "MonthNameArabic" : "MonthName", PivotArea.ColumnArea, 0, ar ? "الشهر" : "Month", MonthPx);
            m.SortBySummaryInfo.Field = no;
            m.SortBySummaryInfo.SummaryType = DevExpress.Data.PivotGrid.PivotSummaryType.Min;
        }

        public static void Money(XRPivotGridField f, bool absCells)
        {
            // Plain cells drop the minus sign (the legacy pivot printed them as ABS); totals keep it.
            f.CellFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            f.CellFormat.FormatString = absCells ? "#,##0.00;#,##0.00" : "N2";
            f.TotalCellFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            f.TotalCellFormat.FormatString = "N2";
            f.GrandTotalCellFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            f.GrandTotalCellFormat.FormatString = "N2";
        }

        public static XRLabel Caption(string name, string text, float y)
        {
            var l = G.Label(name, text, 0, y, G.W, 60, G.F(9.75f, DXFontStyle.Bold));
            l.BackColor = Color.DarkGray; l.ForeColor = Color.Black;
            return l;
        }
    }

    // R3 / R4: pivot 1 = Section 'Dimension', pivot 2 = Section 'Summary'.
    static class BudgetComparison
    {
        public static XtraReport Build(string reportName, Type entity, bool ar, bool branch)
        {
            var r = G.NewReport(reportName, entity, ar);
            foreach (var p in new[] { "fromMonth", "toMonth", "year", "journalReviseFilter", "journalTypeFilter", branch ? "branchFilter" : "costCenterFilter" })
                G.AddParam(r, p);
            var ph = new PageHeaderBand { Dpi = 254f, Name = "PageHeader" };
            string title = branch
                ? (ar ? "قائمة الدخل بالفروع مقارن تقديرى" : "Branch Income Statement Budget Comparison")
                : (ar ? "قائمة الدخل بمراكز التكلفة مقارن تقديرى" : "Cost Center Income Statement Budget Comparison");
            float y = G.Header(ph, ar, title, new[]
            {
                new[] { new Filter("من شهر", "From Month", "?fromMonth"), new Filter("الي شهر", "To Month", "?toMonth"), new Filter("السنة", "Year", "?year") },
                new[] { new Filter("القيود", "Journals", "?journalReviseFilter"), new Filter("أنواع القيود", "Journal Types", "?journalTypeFilter"), branch ? new Filter("الفروع", "Branches", "?branchFilter") : new Filter("مراكز التكلفة", "Cost Centers", "?costCenterFilter") },
            });
            ph.HeightF = y;
            r.Bands.Add(ph);
            r.Bands.Add(new DetailBand { Dpi = 254f, Name = "Detail", HeightF = 0, Visible = false });

            // No group fields: the band prints once, before the (hidden) detail rows. Each pivot sits in its own
            // sub-band, hidden when its slice of the rows is empty (the legacy report cancelled empty pivots).
            var gh = new GroupHeaderBand { Dpi = 254f, Name = "ghPivots", HeightF = 0 };
            var sb1 = new SubBand { Dpi = 254f, Name = "sbDimension", HeightF = 230 };
            G.Bind(sb1, "Visible", "[][[Section] = 'Dimension'].Exists()");
            sb1.Controls.Add(Pivots.Caption("lblDimension", branch ? (ar ? "الفروع" : "Branches") : (ar ? "مراكز التكلفة" : "Cost Centers"), 0));
            var p1 = Pivots.NewPivot("pivotDimension", ar, 70);
            AddPivot(p1, "p1", ar, true, ar ? "أجمالى الربح" : "Total Profit", ar ? "التقديري" : "Budget", ar ? "الفعلي" : "Actual");
            p1.Prefilter.CriteriaString = "[p1Section] = 'Dimension'";
            sb1.Controls.Add(p1);
            gh.SubBands.Add(sb1);

            var sb = new SubBand { Dpi = 254f, Name = "sbSummary", HeightF = 240 };
            G.Bind(sb, "Visible", "[][[Section] = 'Summary'].Exists()");
            sb.Controls.Add(Pivots.Caption("lblSummary", ar ? "ملخص قائمة الدخل" : "Income Statement Summary", 10));
            var p2 = Pivots.NewPivot("pivotSummary", ar, 80);
            AddPivot(p2, "p2", ar, false, ar ? "الربح" : "Profit", ar ? "القيمة التقديرية" : "Budget Value", ar ? "القيمة الفعلية" : "Actual Value");
            p2.Prefilter.CriteriaString = "[p2Section] = 'Summary'";
            sb.Controls.Add(p2);
            gh.SubBands.Add(sb);
            r.Bands.Add(gh);
            G.PageFooter(r, ar);
            return r;
        }

        static void AddPivot(XRPivotGrid pg, string p, bool ar, bool withDimension, string rowGrandTotal, string budgetCap, string actualCap)
        {
            Pivots.Field(pg, p + "Section", "Section", PivotArea.FilterArea, 0, visible: false);
            var typeId = Pivots.Field(pg, p + "AccountTypeId", "AccountTypeId", PivotArea.DataArea, 8, "AccountTypeId", visible: false);
            Pivots.RowGrandTotal(pg, p, rowGrandTotal);
            int idx = 1;
            if (withDimension)
            {
                var dim = Pivots.Field(pg, p + "Dimension", "DimensionName", PivotArea.RowArea, idx++, "", 85);
                Pivots.CustomTotal(dim, ar ? "إجمالي {0}" : "Total {0}");
            }
            var type = Pivots.Field(pg, p + "AccountType", ar ? "AccountTypeNameArabic" : "AccountTypeName", PivotArea.RowArea, idx++, "", withDimension ? 90 : 175);
            type.SortBySummaryInfo.Field = typeId;
            type.SortBySummaryInfo.SummaryType = DevExpress.Data.PivotGrid.PivotSummaryType.Min;
            // Budget and Actual sit in the row area, so a full year still fits one landscape page width.
            pg.OptionsDataField.Area = PivotDataArea.RowArea;
            pg.OptionsDataField.AreaIndex = idx;
            pg.OptionsDataField.RowHeaderWidth = 62;
            Pivots.MonthColumns(pg, p, ar);
            var budget = Pivots.Field(pg, p + "Budget", "Budget", PivotArea.DataArea, 0, budgetCap);
            var actual = Pivots.Field(pg, p + "Actual", "Actual", PivotArea.DataArea, 1, actualCap);
            Pivots.Money(budget, true);
            Pivots.Money(actual, true);
        }
    }

    // R5: six pivots, one per income statement main item, with the three legacy profit lines between them.
    static class PerMonth
    {
        public static XtraReport Build(string reportName, Type entity, bool ar)
        {
            var r = G.NewReport(reportName, entity, ar);
            foreach (var p in new[] { "fromMonth", "toMonth", "year", "journalReviseFilter", "journalTypeFilter", "costCenterFilter", "branchFilter", "grossProfit", "netProfitBeforeTax", "netProfit" })
                G.AddParam(r, p);
            var ph = new PageHeaderBand { Dpi = 254f, Name = "PageHeader" };
            float y = G.Header(ph, ar, ar ? "تقرير قائمة الدخل تفصيلى نصف سنوى" : "Income Statement Detail Branch Per Month Report", new[]
            {
                new[] { new Filter("من شهر", "From Month", "?fromMonth"), new Filter("الي شهر", "To Month", "?toMonth"), new Filter("السنة", "Year", "?year") },
                new[] { new Filter("القيود", "Journals", "?journalReviseFilter"), new Filter("أنواع القيود", "Journal Types", "?journalTypeFilter"), new Filter("مراكز التكلفة", "Cost Centers", "?costCenterFilter") },
                new[] { new Filter("الفروع", "Branches", "?branchFilter") },
            });
            ph.HeightF = y;
            r.Bands.Add(ph);
            r.Bands.Add(new DetailBand { Dpi = 254f, Name = "Detail", HeightF = 0, Visible = false });

            var gh = new GroupHeaderBand { Dpi = 254f, Name = "ghItems", HeightF = 0 };
            r.Bands.Add(gh);
            gh.SubBands.Add(PivotBand(1, ar));
            gh.SubBands.Add(PivotBand(2, ar));
            gh.SubBands.Add(TotalBand("sbGrossProfit", ar ? "اجمالي الارباح" : "Total Profit", "grossProfit", ar));
            gh.SubBands.Add(PivotBand(3, ar));
            gh.SubBands.Add(PivotBand(4, ar));
            gh.SubBands.Add(PivotBand(5, ar));
            gh.SubBands.Add(TotalBand("sbNetProfitBeforeTax", ar ? "اجمالي الارباح قبل الضريبة" : "Total Profit Before Tax", "netProfitBeforeTax", ar));
            gh.SubBands.Add(PivotBand(6, ar));
            gh.SubBands.Add(TotalBand("sbNetProfit", ar ? "صافي الارباح" : "Net Profit", "netProfit", ar));
            G.PageFooter(r, ar);
            return r;
        }

        static SubBand PivotBand(int item, bool ar)
        {
            var sb = new SubBand { Dpi = 254f, Name = $"sbItem{item}", HeightF = 165 };
            G.Bind(sb, "Visible", $"[][[RowType] = 'SubItem' And [MainItemId] = {item}].Exists()");
            sb.Controls.Add(Pivot(item, ar, 15));
            return sb;
        }

        static XRPivotGrid Pivot(int item, bool ar, float y)
        {
            string p = $"p{item}";
            var pg = Pivots.NewPivot($"pivotItem{item}", ar, y);
            // One main item per pivot: its custom total is the pivot's total row, so no grand total row.
            pg.OptionsView.ShowRowGrandTotals = false;
            Pivots.Field(pg, p + "RowType", "RowType", PivotArea.FilterArea, 0, visible: false);
            Pivots.Field(pg, p + "MainItemId", "MainItemId", PivotArea.FilterArea, 1, visible: false);
            var main = Pivots.Field(pg, p + "MainItem", ar ? "MainItemNameArabic" : "MainItemName", PivotArea.RowArea, 0, "", 90);
            Pivots.CustomTotal(main, ar ? "إجمالي {0}" : "Total {0}");
            Pivots.Field(pg, p + "SubItem", "SubItemName", PivotArea.RowArea, 1, "", 135);
            Pivots.MonthColumns(pg, p, ar);
            var bal = Pivots.Field(pg, p + "Balance", "Balance", PivotArea.DataArea, 0, ar ? "الرصيد" : "Balance");
            Pivots.Money(bal, false);
            pg.Prefilter.CriteriaString = $"[{p}RowType] = 'SubItem' And [{p}MainItemId] = {item}";
            return pg;
        }

        static SubBand TotalBand(string name, string caption, string param, bool ar)
        {
            // Legacy hid each profit line when its value is 0; the API sends the totals as invariant strings.
            var sb = new SubBand { Dpi = 254f, Name = name, HeightF = 85 };
            G.Bind(sb, "Visible", $"?{param} <> '0'");
            var t = G.Table("tbl" + name, ar, 0, 15, 1400, 70, G.F(10, DXFontStyle.Bold));
            t.Borders = BorderSide.All;
            var row = new XRTableRow { Dpi = 254f, Name = name + "Row", Weight = 1 };
            row.Cells.Add(new XRTableCell { Dpi = 254f, Name = name + "Cap", Weight = 1.6, Text = caption, BackColor = G.HeadBack, ForeColor = Color.White });
            var v = new XRTableCell { Dpi = 254f, Name = name + "Val", Weight = 1, Text = name + "Val", BackColor = Color.Silver };
            G.Bind(v, "Text", $"FormatString('{{0:N2}}', ToDecimal(?{param}))");
            row.Cells.Add(v);
            t.Rows.Add(row);
            sb.Controls.Add(t);
            return sb;
        }
    }

    public static class Program
    {
        record Layout(string ReportName, bool Ar, XtraReport Report);

        public static void Main(string[] args)
        {
            if (args[0] == "il") { new XRPivotGrid(); Il.Run(args[1], args[2], args[3]); return; }
            if (args[0] == "exp") { Exp.Run(args.Length > 1 ? args[1] : ""); return; }
            string outSql = args[0];
            string testDir = args.Length > 1 ? args[1] : "";
            var layouts = new List<Layout>();
            foreach (var ar in new[] { true, false })
            {
                layouts.Add(new("IncomeStatementCostCenterPeriodBudgetReport", ar, PeriodBudget.Build("IncomeStatementCostCenterPeriodBudgetReport", typeof(IncomeStatementCostCenterPeriodBudgetReport), ar, false)));
            }
            foreach (var ar in new[] { true, false })
                layouts.Add(new("IncomeStatementBranchPeriodBudgetReport", ar, PeriodBudget.Build("IncomeStatementBranchPeriodBudgetReport", typeof(IncomeStatementBranchPeriodBudgetReport), ar, true)));
            foreach (var ar in new[] { true, false })
                layouts.Add(new("CostCenterIncomeBudgetComparisonReport", ar, BudgetComparison.Build("CostCenterIncomeBudgetComparisonReport", typeof(CostCenterIncomeBudgetComparisonReport), ar, false)));
            foreach (var ar in new[] { true, false })
                layouts.Add(new("BranchIncomeBudgetComparisonReport", ar, BudgetComparison.Build("BranchIncomeBudgetComparisonReport", typeof(BranchIncomeBudgetComparisonReport), ar, true)));
            foreach (var ar in new[] { true, false })
                layouts.Add(new("IncomeStatementPerMonthReport", ar, PerMonth.Build("IncomeStatementPerMonthReport", typeof(IncomeStatementPerMonthReport), ar)));

            var sb = new StringBuilder();
            sb.Append(Header);
            foreach (var l in layouts)
            {
                string xml = G.Xml(l.Report);
                sb.Append("EXEC dbo.InsertLayout @Layout = N'").Append(xml.Replace("'", "''")).Append("',\r\n");
                sb.Append($"    @ReportName = N'{l.ReportName}',\r\n");
                sb.Append(l.Ar ? "    @DesignName = N'الافتراضي',\r\n    @Lang = 'ar-EG', @ApplicationId = 1;\r\n" : "    @DesignName = N'Default',\r\n    @Lang = 'en-US', @ApplicationId = 1;\r\n");
                sb.Append("\r\n");
                if (testDir != "") Render(xml, l, testDir);
            }
            File.WriteAllText(outSql, sb.ToString().TrimEnd() + "\r\n", new UTF8Encoding(false));
        }

        static readonly string Header = string.Join(Crlf, new[] {
            "-- =============================================================================",
            "-- CR 125290 - Income statement budget / per-month reports converted to OData: DevExpress print",
            "-- layouts (seeded into ACFX_ReportLayout), ApplicationId = 1 (General Accounting).",
            "-- ReportName (= IAngularReport.ReportName): IncomeStatementCostCenterPeriodBudgetReport,",
            "-- IncomeStatementBranchPeriodBudgetReport, CostCenterIncomeBudgetComparisonReport,",
            "-- BranchIncomeBudgetComparisonReport, IncomeStatementPerMonthReport.",
            "-- House header. Arabic is the RTL master, English the LTR mirror.",
            "-- The two period-budget reports print the TVF rows in RowNo order and style them by RowType; header and",
            "-- row tables share one column spec, so their cell weights match (Excel export).",
            "-- The comparison and per-month reports are pivots, as in the legacy reports: each pivot takes its slice of",
            "-- the rows through a Prefilter on hidden fields, months sort by a hidden MonthNo field, and a pivot whose",
            "-- slice is empty is hidden. Row totals are custom totals so their captions can be translated; the column",
            "-- grand total keeps DevExpress's own 'Grand Total' caption (changing it needs a report script).",
            "-- =============================================================================",
        }) + Crlf;
        const string Crlf = "\r\n";

        static void Render(string xml, Layout l, string dir)
        {
            File.WriteAllText(Path.Combine(dir, $"{l.ReportName}_{(l.Ar ? "ar" : "en")}.repx"), xml);
            foreach (var ty in new[]{typeof(IncomeStatementCostCenterPeriodBudgetReport),typeof(IncomeStatementBranchPeriodBudgetReport),typeof(CostCenterIncomeBudgetComparisonReport),typeof(BranchIncomeBudgetComparisonReport),typeof(IncomeStatementPerMonthReport)}) { DevExpress.Utils.DeserializationSettings.RegisterTrustedClass(ty); DevExpress.Utils.DeserializationSettings.RegisterTrustedClass(typeof(List<>).MakeGenericType(ty)); }
            var rep = XtraReport.FromXmlStream(new MemoryStream(Encoding.UTF8.GetBytes(xml)));
            rep.DataSource = TestData.For(l.ReportName);
            foreach (var kv in TestData.Params(l.ReportName, l.Ar)) if (rep.Parameters[kv.Key] != null) rep.Parameters[kv.Key].Value = kv.Value;
            string f = Path.Combine(dir, $"{l.ReportName}_{(l.Ar ? "ar" : "en")}");
            rep.ExportToPdf(f + ".pdf");
            rep.ExportToXlsx(f + ".xlsx");
            rep.ExportToText(f + ".txt");
        }
    }

    static class TestData
    {
        public static Dictionary<string, object> Params(string name, bool ar)
        {
            var d = new Dictionary<string, object>
            {
                ["CompanyName"] = ar ? "شركة الاختبار" : "Test Company", ["Address"] = "Cairo", ["Telephone"] = "0123", ["Email"] = "a@b.c", ["Fax"] = "999",
                ["journalReviseFilter"] = ar ? "جميع القيود" : "Both Journals Revised & NOT Revised", ["journalTypeFilter"] = "JV, Receipt",
                ["costCenterFilter"] = "CC1, CC2", ["branchFilter"] = "Main",
                ["periodStart"] = "01/03/2026", ["periodEnd"] = "31/03/2026", ["periodCaption"] = "3/2026", ["lastPeriodCaption"] = "3/2025",
                ["yearToDateCaption"] = "1-3/2026", ["lastYearToDateCaption"] = "1-3/2025", ["yearsCaption"] = "2026-2025",
                ["fromMonth"] = "1", ["toMonth"] = "12", ["year"] = "2026", ["grossProfit"] = "12345.678", ["netProfitBeforeTax"] = "0", ["netProfit"] = "-500.5",
            };
            return d;
        }

        public static object For(string name)
        {
            if (name.Contains("PeriodBudget"))
            {
                var l = new List<IncomeStatementCostCenterPeriodBudgetReport>();
                long n = 1;
                IncomeStatementCostCenterPeriodBudgetReport R(string type, string? no, string? dn, int? at, string en, string arN, decimal v) => new()
                { RowNo = n++, RowType = type, DimensionNo = no, DimensionName = dn, AccountTypeId = at, AccountTypeName = en, AccountTypeNameArabic = arN, PeriodBalance = v, PeriodBudget = v / 2, BudgetDiff = v / 3, LastBalance = v * 2, LastBalanceDiff = v, YearToPeriodBalance = v * 10, YearToPeriodBudget = v * 9, YearToPeriodBudgetDiff = v, LastYearToPeriodBalance = v * 8, LastYearToPeriodBalanceDiff = v * 2 };
                foreach (var cc in new[] { ("01", "Cost Center A"), ("02", "Cost Center B") })
                {
                    l.Add(R("AccountType", cc.Item1, cc.Item2, 1, "Operating income", "ايرادات التشغيل", 150000.25m));
                    l.Add(R("AccountType", cc.Item1, cc.Item2, 2, "Operating expenses", "مصروفات التشغيل", 90000m));
                    l.Add(R("GrossProfit", cc.Item1, cc.Item2, null, "GOP", "اجمالي الربح", 60000.25m));
                    l.Add(R("GrossProfitPercent", cc.Item1, cc.Item2, null, "%", "%", 0m));
                }
                l.Add(R("TotalGrossProfit", null, null, null, "Total Cost Center GOP", "اجمالي ارباح مركز التكلفة", 120000.5m));
                l.Add(R("OtherAccountType", null, null, 3, "Other income", "ايرادات اخرى", 5000m));
                l.Add(R("OtherAccountType", null, null, 4, "Admin expenses", "مصروفات عمومية", 7000m));
                l.Add(R("NetProfit", null, null, null, "Net Profit", "صافي الربح", -1234567.89m));
                return l;
            }
            string[] en = { "", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };
            string[] arM = { "", "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر" };
            if (name.Contains("Comparison"))
            {
                var l = new List<CostCenterIncomeBudgetComparisonReport>();
                long n = 1;
                foreach (var dim in Enumerable.Range(1, 3).Select(i => $"Cost Center {i:00}"))
                    foreach (var at in new[] { (1, "Operating income", "ايرادات التشغيل", 1m), (2, "Operating expenses", "مصروفات التشغيل", -1m) })
                        for (int m = 1; m <= 12; m++)
                            l.Add(new() { RowNo = n++, Section = "Dimension", DimensionName = dim, AccountTypeId = at.Item1, AccountTypeName = at.Item2, AccountTypeNameArabic = at.Item3, MonthNo = m, MonthName = en[m], MonthNameArabic = arM[m], Budget = at.Item4 * 1234567.89m, Actual = -at.Item4 * 1000000m });
                foreach (var at in new[] { (1, "Total Operating Income", "ايرادات التشغيل", 1m), (2, "Total Operating expenses ", "مصروفات التشغيل", -1m), (4, "Admin", "مصروفات عمومية", -1m) })
                    for (int m = 1; m <= 12; m++)
                        l.Add(new() { RowNo = n++, Section = "Summary", AccountTypeId = at.Item1, AccountTypeName = at.Item2, AccountTypeNameArabic = at.Item3, MonthNo = m, MonthName = en[m], MonthNameArabic = arM[m], Budget = at.Item4 * 5000m, Actual = at.Item4 * 4000m });
                return l;
            }
            var p = new List<IncomeStatementPerMonthReport>();
            long k = 1;
            string[] mains = { "", "Operating Income", "Operating Expenses", "Other Income", "Administrative", "Other Expense", "Taxes" };
            string[] mainsAr = { "", "ايرادات التشغيل", "مصروفات التشغيل", "ايرادات اخرى", "مصروفات عمومية وادارية", "مصروفات اخرى", "الضرائب" };
            for (int mi = 1; mi <= 6; mi++)
                foreach (var sub in new[] { "Sub A", "Sub B" })
                    for (int m = 6; m <= 12; m++)
                        p.Add(new() { RowNo = k++, RowType = "SubItem", MainItemId = mi, MainItemName = mains[mi], MainItemNameArabic = mainsAr[mi], SubItemName = sub, MonthNo = m, MonthName = en[m], MonthNameArabic = arM[m], Balance = (m % 2 == 0 ? 1 : -1) * 98765.43m });
            p.Add(new() { RowNo = k++, RowType = "GrossProfit", MainItemName = "Total Profit", Balance = 12345.678m });
            return p;
        }
    }
}
