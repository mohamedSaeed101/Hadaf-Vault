using System.Drawing;
using System.Text;
using DevExpress.Drawing;
using DevExpress.DataAccess.ObjectBinding;
using DevExpress.XtraPivotGrid;
using DevExpress.XtraPrinting;
using Parameter = DevExpress.XtraReports.Parameters.Parameter;
using DevExpress.XtraReports.UI;
using DevExpress.XtraReports.UI.PivotGrid;
using AnalyticsReader.Api.ODataViews.GL.FinancialStatements;

// Copies of the AnalyticsReader entities (same namespace and assembly name, so the ObjectDataSource type
// names in the .repx match the real API).
namespace AnalyticsReader.Api.ODataViews.GL.FinancialStatements
{
    public class BriefBalanceSheetReport
    {
        public long RowNo { get; set; }
        public string? RowType { get; set; }
        public string? Description { get; set; }
        public string? DescriptionArabic { get; set; }
        public decimal? Subtotal { get; set; }
        public decimal? Total { get; set; }
    }

    public class CompareBalanceSheetReport
    {
        public long RowNo { get; set; }
        public int? SortOrder { get; set; }
        public string? RowType { get; set; }
        public int? MainItemId { get; set; }
        public string? Description { get; set; }
        public decimal? Balance { get; set; }
        public decimal? PriorBalance { get; set; }
    }

    public class FinancialPositionStatementReport
    {
        public long RowNo { get; set; }
        public int? SortOrder { get; set; }
        public string? RowType { get; set; }
        public int? MainItemId { get; set; }
        public string? MainItemName { get; set; }
        public string? MainItemNameArabic { get; set; }
        public string? SubParentItemName { get; set; }
        public string? SubItemName { get; set; }
        public decimal? Cost { get; set; }
        public decimal? Depreciation { get; set; }
        public decimal? Net { get; set; }
    }

    public class CashFlowReport
    {
        public long RowNo { get; set; }
        public int? Ordr { get; set; }
        public string? RowType { get; set; }
        public string? Section { get; set; }
        public string? Description { get; set; }
        public string? DescriptionArabic { get; set; }
        public decimal? Amount { get; set; }
    }

    public class EquityChangingReport
    {
        public long RowNo { get; set; }
        public string? RowKind { get; set; }
        public string? RowCaption { get; set; }
        public string? RowCaptionArabic { get; set; }
        public int? EquityTypeId { get; set; }
        public string? EquityTypeName { get; set; }
        public string? EquityTypeNameArabic { get; set; }
        public decimal? Amount { get; set; }
    }
}

namespace Gen
{
    record Filter(string Ar, string En, string Expr);
    record Col(string Ar, string En, double Weight, string? HeaderExpr = null);

    static class G
    {
        public const float PageW = 2970, MarginX = 100, W = PageW - 2 * MarginX;
        public const float HeadH = 60, RowH = 55;
        public static readonly Color TitleBack = Color.FromArgb(255, 139, 146, 153);
        public static readonly Color HeadBack = Color.FromArgb(255, 144, 151, 158);
        public static DXFont F(float size, DXFontStyle style = DXFontStyle.Regular) => new("Arial", size, style);
        // RightToLeft mirrors TextAlignment, so MiddleLeft renders on the right in the Arabic layout.
        public const TextAlignment Lead = TextAlignment.MiddleLeft;

        public static XtraReport NewReport(string reportName, Type entity, bool ar, params string[] pars)
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
            foreach (var p in new[] { "CompanyName", "Address", "Telephone", "Email", "Fax" }.Concat(pars))
                r.Parameters.Add(new Parameter { Name = p, Description = p, Visible = false });
            r.Parameters.Add(new Parameter { Name = "Logo", Description = "Logo", Visible = false, Type = typeof(byte[]) });
            r.Parameters.Add(new Parameter { Name = "approximateNo", Description = "approximateNo", Visible = false, Type = typeof(int), Value = 2 });
            return r;
        }

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
        public static float Header(Band band, bool ar, string title, Filter[] filters)
        {
            var pic = new XRPictureBox { Dpi = 254f, Name = "pictureBox1", Sizing = ImageSizeMode.ZoomImage, LocationF = new PointF(0, 5), SizeF = new SizeF(300, 290) };
            Bind(pic, "ImageSource", "?Logo");
            band.Controls.Add(pic);
            band.Controls.Add(Label("lblCompany", "lblCompany", 310, 0, 1000, 116, F(12, DXFontStyle.Bold), Lead, "?CompanyName"));
            band.Controls.Add(Label("lblAddress", "lblAddress", 310, 116, 1000, 73, F(9.75f), Lead, "?Address"));
            string[] caps = ar ? new[] { "البريد الإلكتروني :", "الهاتف :", "الفاكس :" } : new[] { "Email :", "Tel :", "Fax :" };
            string[] names = { "Email", "Tel", "Fax" };
            string[] pars = { "?Email", "?Telephone", "?Fax" };
            for (int i = 0; i < 3; i++)
            {
                band.Controls.Add(Label($"lbl{names[i]}Cap", caps[i], W - 917, 58 * i, 355, 58, F(9.75f, DXFontStyle.Bold), Lead));
                band.Controls.Add(Label($"lbl{names[i]}", $"lbl{names[i]}", W - 562, 58 * i, 562, 58, F(9.75f), Lead, pars[i]));
            }
            band.Controls.Add(new XRLine { Dpi = 254f, Name = "line1", LineWidth = 2, LocationF = new PointF(0, 300), SizeF = new SizeF(W, 10) });
            var t = Label("lblTitle", title, 0, 310, W, 82, F(13, DXFontStyle.Bold), TextAlignment.MiddleCenter);
            t.BackColor = TitleBack; t.ForeColor = Color.Black;
            band.Controls.Add(t);

            // One row of up to three caption/value pairs; fewer pairs widen the last value cell.
            var tbl = Table("tblFilters", ar, 0, 410, W, 58, F(9.75f));
            tbl.Borders = BorderSide.All;
            var row = new XRTableRow { Dpi = 254f, Name = "tblFiltersRow0", Weight = 1 };
            for (int i = 0; i < filters.Length; i++)
            {
                row.Cells.Add(new XRTableCell { Dpi = 254f, Name = $"fCap{i}", Weight = 1, Text = ar ? filters[i].Ar : filters[i].En, Font = F(9.75f, DXFontStyle.Bold), ForeColor = Color.Black, BackColor = TitleBack });
                float vw = 2.4f + (i == filters.Length - 1 ? (3 - filters.Length) * 3.4f : 0);
                var val = new XRTableCell { Dpi = 254f, Name = $"fVal{i}", Weight = vw, Text = $"fVal{i}" };
                Bind(val, "Text", filters[i].Expr);
                row.Cells.Add(val);
            }
            tbl.Rows.Add(row);
            band.Controls.Add(tbl);
            return 410 + 58 + 15;
        }

        public static XRTable Table(string name, bool ar, float x, float y, float w, float h, DXFont font)
        {
            var t = new XRTable { Dpi = 254f, Name = name, LocationF = new PointF(x, y), SizeF = new SizeF(w, h), Font = font, TextAlignment = TextAlignment.MiddleCenter };
            if (ar) t.RightToLeft = DevExpress.XtraReports.UI.RightToLeft.Yes;
            return t;
        }

        // Page header (company block, title, filters, column captions) for a statement printed as one table.
        // Header and row tables are built from the same column list, so their weights match (Excel export).
        public static void StatementHeader(XtraReport r, bool ar, string title, Filter[] filters, Col[] cols)
        {
            var ph = new PageHeaderBand { Dpi = 254f, Name = "PageHeader" };
            float y = Header(ph, ar, title, filters);
            var head = Table("tblHead", ar, 0, y, W, HeadH, F(9.75f, DXFontStyle.Bold));
            head.ForeColor = Color.White; head.BackColor = HeadBack; head.Borders = BorderSide.All;
            var row = new XRTableRow { Dpi = 254f, Name = "tblHeadRow0", Weight = 1 };
            for (int i = 0; i < cols.Length; i++)
            {
                var c = new XRTableCell { Dpi = 254f, Name = $"h{i}", Weight = cols[i].Weight, Text = ar ? cols[i].Ar : cols[i].En };
                if (cols[i].HeaderExpr != null) Bind(c, "Text", cols[i].HeaderExpr!);
                row.Cells.Add(c);
            }
            head.Rows.Add(row);
            ph.Controls.Add(head);
            ph.HeightF = y + HeadH;
            r.Bands.Add(ph);
        }

        // Detail band: one table row per TVF row in RowNo order. cells[i] = text expression of column i
        // (null = blank); money columns bind their format to the `money` expression.
        public static DetailBand StatementRows(XtraReport r, bool ar, Col[] cols, string?[] cells, string money,
            string backColor, string bold)
        {
            var d = new DetailBand { Dpi = 254f, Name = "Detail", KeepTogether = true, HeightF = RowH };
            d.SortFields.Add(new GroupField("RowNo", XRColumnSortOrder.Ascending));
            var t = Table("tblRow", ar, 0, 0, W, RowH, F(8.75f));
            t.Borders = BorderSide.Left | BorderSide.Right | BorderSide.Bottom;
            Bind(t, "BackColor", backColor);
            Bind(t, "Font.Bold", bold);
            var row = new XRTableRow { Dpi = 254f, Name = "tblRowRow0", Weight = 1 };
            for (int i = 0; i < cols.Length; i++)
            {
                var c = new XRTableCell { Dpi = 254f, Name = $"d{i}", Weight = cols[i].Weight, Text = "" };
                if (i == 0)
                {
                    c.TextAlignment = Lead;
                    c.Padding = new PaddingInfo(10, 10, 0, 0, 254);
                }
                else Bind(c, "TextFormatString", money);
                if (cells[i] != null) Bind(c, "Text", cells[i]!);
                row.Cells.Add(c);
            }
            t.Rows.Add(row);
            d.Controls.Add(t);
            r.Bands.Add(d);
            return d;
        }

        // Keeps a statement block (category header, its lines and its totals) on one page when it fits.
        public static void KeepBlocks(XtraReport r, string blockExpr)
        {
            r.CalculatedFields.Add(new CalculatedField { Name = "Block", FieldType = FieldType.Int32, Expression = blockExpr });
            var gh = new GroupHeaderBand { Dpi = 254f, Name = "ghBlock", HeightF = 0, GroupUnion = GroupUnion.WholePage };
            gh.GroupFields.Add(new GroupField("Block", XRColumnSortOrder.None));
            r.Bands.Add(gh);
        }

        public static void PageFooter(XtraReport r, bool ar)
        {
            var b = new PageFooterBand { Dpi = 254f, Name = "PageFooter", HeightF = 58 };
            b.Controls.Add(Label("lblPowered", "Powered by : www.accflex.com", 0, 0, 900, 58, F(9.75f), TextAlignment.MiddleCenter));
            b.Controls.Add(new XRPageInfo { Dpi = 254f, Name = "pageInfoDate", PageInfo = PageInfo.DateTime, TextFormatString = ar ? "طبع في {0:dd/MM/yyyy hh:mm tt}" : "Printed On {0:dd/MM/yyyy hh:mm tt}", TextAlignment = TextAlignment.MiddleCenter, LocationF = new PointF(1000, 0), SizeF = new SizeF(900, 58), Padding = new PaddingInfo(5, 5, 0, 0, 254) });
            b.Controls.Add(new XRPageInfo { Dpi = 254f, Name = "pageInfoNumber", PageInfo = PageInfo.NumberOfTotal, TextFormatString = ar ? "صفحة {0} من {1}" : "Page {0} Of {1}", TextAlignment = TextAlignment.MiddleCenter, LocationF = new PointF(W - 500, 0), SizeF = new SizeF(500, 58), Padding = new PaddingInfo(5, 5, 0, 0, 254) });
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

    static class Reports
    {
        // Money follows the tenant decimals (?approximateNo), as the legacy prints did.
        const string Money = "'{0:n' + ToStr(?approximateNo) + '}'";
        const string Decimals = "Iif(ToInt(?approximateNo) > 0, '.' + Substring('0000000000', 0, ToInt(?approximateNo)), '')";
        const string MoneyInParentheses = "'{0:#,##0' + " + Decimals + " + ';(#,##0' + " + Decimals + " + ')}'";

        // R1: the eight fixed rows; CA and CL fill Subtotal, every other row fills Total.
        public static XtraReport Brief(bool ar)
        {
            var r = G.NewReport("BriefBalanceSheetReport", typeof(BriefBalanceSheetReport), ar, "toDate", "branchFilter");
            Col[] cols = { new("التفاصيل", "Description", 2), new("الاجمالي الفرعي", "Subtotal", 1), new("الاجمالي", "Total", 1) };
            G.StatementHeader(r, ar, ar ? "تقرير الميزانية المختصر" : "Brief Balance Sheet Report",
                new[] { new Filter("في تاريخ", "As Of", "?toDate"), new Filter("الفروع", "Branches", "?branchFilter") }, cols);
            const string totals = "[RowType] In ('WorkingCapital', 'InvestedCapital', 'CapitalInvested')";
            G.StatementRows(r, ar, cols, new[] { ar ? "[DescriptionArabic]" : "[Description]", "[Subtotal]", "[Total]" }, Money,
                $"Iif({totals}, 'Silver', 'White')", totals);
            G.PageFooter(r, ar);
            return r;
        }

        // R2: category header (with its totals), its sub-item lines, then the summary rows; the two money
        // columns are captioned with the balance date and the prior-year date.
        public static XtraReport Compare(bool ar)
        {
            var r = G.NewReport("CompareBalanceSheetReport", typeof(CompareBalanceSheetReport), ar, "toDate", "priorDate");
            Col[] cols = { new("التفاصيل", "Description", 2), new("", "", 1, "?toDate"), new("", "", 1, "?priorDate") };
            G.StatementHeader(r, ar, ar ? "تقرير مقارنة الميزانية" : "Compare Balance Sheet Report",
                new[] { new Filter("في تاريخ", "As Of", "?toDate") }, cols);
            G.KeepBlocks(r, "ToInt(Floor([SortOrder] / 1000.0))");
            // The TVF's Description is English; the Arabic layout translates the fixed rows by RowType.
            string desc = ar
                ? "Iif([RowType] = 'SubItem', '- ' + [Description], " +
                  "[RowType] = 'CategoryHeader' And [MainItemId] = 1, 'الاصول طويلة الاجل', " +
                  "[RowType] = 'CategoryHeader' And [MainItemId] = 2, 'الاصول المتداولة', " +
                  "[RowType] = 'CategoryHeader' And [MainItemId] = 3, 'الخصوم المتداولة', " +
                  "[RowType] = 'CategoryHeader' And [MainItemId] = 4, 'حقوق الملكية', " +
                  "[RowType] = 'CategoryHeader' And [MainItemId] = 5, 'الخصوم طويلة الاجل', " +
                  "[RowType] = 'SummaryAssets', 'اجمالي الاصول', " +
                  "[RowType] = 'NetWorkingCapital', 'صافي رأس المال العامل', " +
                  "[RowType] = 'ContributedCapital', 'رأس المال المستثمر', " +
                  "[RowType] = 'SummaryLiabilities', 'اجمالي الخصوم', [Description])"
                : "Iif([RowType] = 'SubItem', '- ' + [Description], [Description])";
            G.StatementRows(r, ar, cols, new[] { desc, "[Balance]", "[PriorBalance]" }, Money,
                "Iif([RowType] = 'CategoryHeader', 'Gainsboro', [RowType] = 'SubItem', 'White', 'Silver')",
                "[RowType] <> 'SubItem'");
            G.PageFooter(r, ar);
            return r;
        }

        // R3: category / sub-parent headers carry their total in Net; sub-items show Cost, Depreciation, Net;
        // Capital, Total Investment and Investment Financing are the silver total rows.
        public static XtraReport FinancialPosition(bool ar)
        {
            var r = G.NewReport("FinancialPositionStatementReport", typeof(FinancialPositionStatementReport), ar, "toDate", "branchFilter");
            Col[] cols = { new("نوع الحساب", "Balance Type", 2), new("التكلفة", "Cost", 1), new("الإهلاك", "Depreciation", 1), new("الصافي", "Net", 1) };
            G.StatementHeader(r, ar, ar ? "تقرير المركز المالي الإجمالي" : "Financial Position Statement Report",
                new[] { new Filter("الي تاريخ", "To Date", "?toDate"), new Filter("الفروع", "Branches", "?branchFilter") }, cols);
            G.KeepBlocks(r, "ToInt(Floor([SortOrder] / 100000.0))");
            string desc = "Iif([RowType] = 'SubParentHeader', [SubParentItemName], [RowType] = 'SubItem', '- ' + [SubItemName], "
                + (ar ? "[MainItemNameArabic])" : "[MainItemName])");
            G.StatementRows(r, ar, cols, new[] { desc, "[Cost]", "[Depreciation]", "[Net]" }, Money,
                "Iif([RowType] = 'CategoryHeader', 'Gainsboro', [RowType] = 'SubParentHeader', 'WhiteSmoke', [RowType] = 'SubItem', 'White', 'Silver')",
                "[RowType] <> 'SubItem'");
            G.PageFooter(r, ar);
            return r;
        }

        // R4: sixteen rows; negatives print as the absolute value in parentheses, as the legacy report did.
        public static XtraReport CashFlow(bool ar)
        {
            var r = G.NewReport("CashFlowReport", typeof(CashFlowReport), ar, "fromDate", "toDate", "branchFilter");
            Col[] cols = { new("البند", "Item", 1.6), new("القيمة", "Value", 1) };
            G.StatementHeader(r, ar, ar ? "تقرير التدفقات النقدية" : "Cash Flow Report",
                new[] { new Filter("من تاريخ", "From Date", "?fromDate"), new Filter("الي تاريخ", "To Date", "?toDate"), new Filter("الفروع", "Branches", "?branchFilter") }, cols);
            G.StatementRows(r, ar, cols, new[] { ar ? "[DescriptionArabic]" : "[Description]", "[Amount]" }, MoneyInParentheses,
                "Iif([RowType] = 'Total', 'Silver', 'White')", "[RowType] = 'Total'");
            G.PageFooter(r, ar);
            return r;
        }

        // R5: a pivot as in the legacy report: rows = row kind, columns = equity type, cells = Amount.
        public static XtraReport EquityChanging(bool ar)
        {
            var r = G.NewReport("EquityChangingReport", typeof(EquityChangingReport), ar, "fromDate", "toDate");
            var ph = new PageHeaderBand { Dpi = 254f, Name = "PageHeader" };
            float y = G.Header(ph, ar, ar ? "تقرير التغيير في حقوق المساهمين" : "Owners' Equity Changing Report",
                new[] { new Filter("من تاريخ", "From Date", "?fromDate"), new Filter("الي تاريخ", "To Date", "?toDate") });
            ph.HeightF = y;
            r.Bands.Add(ph);
            r.Bands.Add(new DetailBand { Dpi = 254f, Name = "Detail", HeightF = 0, Visible = false });

            var gh = new GroupHeaderBand { Dpi = 254f, Name = "ghPivot", HeightF = 200 };
            var pg = new XRPivotGrid { Dpi = 254f, Name = "pivotEquity", LocationF = new PointF(0, 0), SizeF = new SizeF(G.W, 150) };
            if (ar) pg.RightToLeft = DevExpress.XtraReports.UI.RightToLeft.Yes;
            pg.OptionsView.ShowColumnHeaders = false;
            pg.OptionsView.ShowDataHeaders = false;
            pg.OptionsView.ShowRowHeaders = false;
            pg.OptionsView.ShowFilterHeaders = false;
            pg.OptionsPrint.UsePrintAppearance = true;
            pg.OptionsPrint.PrintColumnAreaOnEveryPage = true;
            var a = pg.Appearance;
            a.Cell.Font = G.F(8.75f);
            a.FieldValue.Font = G.F(8.75f, DXFontStyle.Bold);
            a.FieldValue.BackColor = G.HeadBack; a.FieldValue.ForeColor = Color.White;
            a.FieldValue.WordWrap = true;
            a.FieldValueGrandTotal.Font = G.F(8.75f, DXFontStyle.Bold);
            a.FieldValueGrandTotal.BackColor = Color.Silver; a.FieldValueGrandTotal.ForeColor = Color.Black;
            a.GrandTotalCell.Font = G.F(8.75f, DXFontStyle.Bold);
            a.GrandTotalCell.BackColor = Color.Silver;
            a.CustomTotalCell.Font = G.F(8.75f, DXFontStyle.Bold);
            a.CustomTotalCell.BackColor = Color.Silver;
            a.FieldValueTotal.Font = G.F(8.75f, DXFontStyle.Bold);
            a.FieldValueTotal.BackColor = Color.Silver; a.FieldValueTotal.ForeColor = Color.Black;
            a.Lines.ForeColor = Color.DarkGray;
            foreach (var cell in new[] { a.Cell, a.CustomTotalCell, a.GrandTotalCell })
                cell.TextHorizontalAlignment = DevExpress.Utils.HorzAlignment.Center;

            XRPivotGridField Field(string name, string fieldName, PivotArea area, int index, int widthPx = 0, bool visible = true)
            {
                var f = new XRPivotGridField(fieldName, area) { Name = name, AreaIndex = index, Caption = "", Visible = visible };
                if (widthPx > 0) f.Width = widthPx;
                pg.Fields.Add(f);
                return f;
            }

            // Rows and columns sort by the hidden RowNo / EquityTypeId (Min), so the order is the same in both languages.
            // The bottom "Balance" row is the custom total of a constant outer row field, so its caption can be
            // translated; the right "Total" column is the column grand total.
            pg.OptionsView.ShowRowGrandTotals = false;
            var all = Field("fAllRows", "", PivotArea.RowArea, 0, 6);
            all.UnboundType = DevExpress.Data.UnboundColumnType.String; all.UnboundExpression = "''"; all.UnboundFieldName = "AllRowsValue";
            all.TotalsVisibility = PivotTotalsVisibility.CustomTotals;
            var total = all.CustomTotals.Add(DevExpress.Data.PivotGrid.PivotSummaryType.Sum);
            total.Format.FormatType = DevExpress.Utils.FormatType.Custom;
            total.Format.FormatString = (ar ? "الرصيد" : "Balance") + "{0}";
            var kind = Field("fRowCaption", ar ? "RowCaptionArabic" : "RowCaption", PivotArea.RowArea, 1, 250);
            kind.SortBySummaryInfo.FieldName = "RowNo";
            kind.SortBySummaryInfo.SummaryType = DevExpress.Data.PivotGrid.PivotSummaryType.Min;
            var type = Field("fEquityType", ar ? "EquityTypeNameArabic" : "EquityTypeName", PivotArea.ColumnArea, 0, 110);
            type.SortBySummaryInfo.FieldName = "EquityTypeId";
            type.SortBySummaryInfo.SummaryType = DevExpress.Data.PivotGrid.PivotSummaryType.Min;
            var amount = Field("fAmount", "Amount", PivotArea.DataArea, 0, 110);
            foreach (var fmt in new[] { amount.CellFormat, amount.TotalCellFormat, amount.GrandTotalCellFormat })
            {
                fmt.FormatType = DevExpress.Utils.FormatType.Numeric;
                fmt.FormatString = "N2";
            }
            amount.EmptyCellText = "0.00";
            amount.EmptyValueText = "0.00";
            // Pivot field formats cannot take an expression binding, so the tenant decimals are applied before printing.
            pg.Scripts.OnBeforePrint = "pivotEquity_BeforePrint";
            r.ScriptsSource = string.Join("\r\n", new[] {
                "private void pivotEquity_BeforePrint(object sender, System.ComponentModel.CancelEventArgs e) {",
                "    var pg = (DevExpress.XtraReports.UI.XRPivotGrid)sender;",
                "    var n = System.Convert.ToInt32(pg.RootReport.Parameters[\"approximateNo\"].Value);",
                "    foreach (DevExpress.XtraReports.UI.PivotGrid.XRPivotGridField f in pg.Fields) {",
                "        if (f.Area != DevExpress.XtraPivotGrid.PivotArea.DataArea) continue;",
                "        f.CellFormat.FormatString = f.TotalCellFormat.FormatString = f.GrandTotalCellFormat.FormatString = \"N\" + n;",
                "        f.EmptyCellText = f.EmptyValueText = 0m.ToString(\"N\" + n);",
                "    }",
                "}" });
            gh.Controls.Add(pg);
            r.Bands.Add(gh);
            G.PageFooter(r, ar);
            return r;
        }
    }

    public static class Program
    {
        record Layout(string ReportName, bool Ar, XtraReport Report);
        const string Crlf = "\r\n";

        static readonly Type[] Entities = { typeof(BriefBalanceSheetReport), typeof(CompareBalanceSheetReport), typeof(FinancialPositionStatementReport), typeof(CashFlowReport), typeof(EquityChangingReport) };

        public static int Main(string[] args)
        {
            string outSql = args[0];
            string testDir = args.Length > 1 ? args[1] : "";
            string testApproximateNo = args.Length > 2 ? args[2] : "2";
            // As AnalyticsReader's Startup, so the Equity Changing pivot script runs in the test render.
            DevExpress.XtraReports.Security.ScriptPermissionManager.GlobalInstance = new DevExpress.XtraReports.Security.ScriptPermissionManager(DevExpress.XtraReports.Security.ExecutionMode.Unrestricted);
            foreach (var ty in Entities)
            {
                DevExpress.Utils.DeserializationSettings.RegisterTrustedClass(ty);
                DevExpress.Utils.DeserializationSettings.RegisterTrustedClass(typeof(List<>).MakeGenericType(ty));
            }

            var layouts = new List<Layout>();
            foreach (var ar in new[] { true, false }) layouts.Add(new("BriefBalanceSheetReport", ar, Reports.Brief(ar)));
            foreach (var ar in new[] { true, false }) layouts.Add(new("CompareBalanceSheetReport", ar, Reports.Compare(ar)));
            foreach (var ar in new[] { true, false }) layouts.Add(new("FinancialPositionStatementReport", ar, Reports.FinancialPosition(ar)));
            foreach (var ar in new[] { true, false }) layouts.Add(new("CashFlowReport", ar, Reports.CashFlow(ar)));
            foreach (var ar in new[] { true, false }) layouts.Add(new("EquityChangingReport", ar, Reports.EquityChanging(ar)));

            var sb = new StringBuilder();
            sb.Append(Header);
            int loaded = 0;
            foreach (var l in layouts)
            {
                string xml = G.Xml(l.Report);
                LoadCheck(xml, l);
                loaded++;
                sb.Append("EXEC dbo.InsertLayout @Layout = N'").Append(xml.Replace("'", "''")).Append("',").Append(Crlf);
                sb.Append($"    @ReportName = N'{l.ReportName}',").Append(Crlf);
                sb.Append(l.Ar ? "    @DesignName = N'الافتراضي'," + Crlf + "    @Lang = 'ar-EG', @ApplicationId = 1;" + Crlf
                               : "    @DesignName = N'Default'," + Crlf + "    @Lang = 'en-US', @ApplicationId = 1;" + Crlf);
                sb.Append(Crlf);
                if (testDir != "") Render(xml, l, testDir, testApproximateNo);
            }
            File.WriteAllText(outSql, sb.ToString().TrimEnd() + Crlf, new UTF8Encoding(false));
            Console.WriteLine($"load-check: {loaded}/{layouts.Count} layouts loaded with FromXmlStream and LoadLayoutFromXml");
            return 0;
        }

        // Every layout must load back both ways the server can load it; an exception fails the run.
        static void LoadCheck(string xml, Layout l)
        {
            var bytes = Encoding.UTF8.GetBytes(xml);
            using (var a = XtraReport.FromXmlStream(new MemoryStream(bytes))) { }
            using var b = new XtraReport();
            b.LoadLayoutFromXml(new MemoryStream(bytes));
            if (b.Name != "rpt" + l.ReportName) throw new InvalidOperationException($"{l.ReportName}: loaded name {b.Name}");
        }

        static readonly string Header = string.Join(Crlf, new[] {
            "-- =============================================================================",
            "-- CR 125291 - Financial statements converted to OData: DevExpress print layouts (seeded into",
            "-- ACFX_ReportLayout), ApplicationId = 1 (General Accounting).",
            "-- ReportName (= IAngularReport.ReportName): BriefBalanceSheetReport, CompareBalanceSheetReport,",
            "-- FinancialPositionStatementReport, CashFlowReport, EquityChangingReport.",
            "-- House header. Arabic is the RTL master, English the LTR mirror.",
            "-- The four statements print the TVF rows in RowNo order and style them by RowType; header and row",
            "-- tables share one column spec, so their cell weights match (Excel export). Compare and Financial",
            "-- Position keep each category block on one page when it fits. Cash Flow prints negatives in parentheses.",
            "-- Equity Changing is a pivot (row kind x equity type); the bottom Balance row is a custom total so its",
            "-- caption is translated, the right total column keeps DevExpress's own 'Grand Total' caption.",
            "-- =============================================================================",
        }) + Crlf;

        static void Render(string xml, Layout l, string dir, string approximateNo)
        {
            Directory.CreateDirectory(dir);
            string f = Path.Combine(dir, $"{l.ReportName}_{(l.Ar ? "ar" : "en")}");
            File.WriteAllText(f + ".repx", xml);
            var rep = XtraReport.FromXmlStream(new MemoryStream(Encoding.UTF8.GetBytes(xml)));
            rep.DataSource = TestData.For(l.ReportName);
            foreach (var kv in TestData.Params(l.Ar)) if (rep.Parameters[kv.Key] != null) rep.Parameters[kv.Key].Value = kv.Value;
            rep.Parameters["approximateNo"].Value = approximateNo;
            rep.ExportToPdf(f + ".pdf");
            rep.ExportToXlsx(f + ".xlsx");
            rep.ExportToText(f + ".txt");
        }
    }

    static class TestData
    {
        public static Dictionary<string, object> Params(bool ar) => new()
        {
            ["CompanyName"] = ar ? "شركة الاختبار" : "Test Company", ["Address"] = "Cairo", ["Telephone"] = "0123", ["Email"] = "a@b.c", ["Fax"] = "999",
            ["toDate"] = "31/12/2025", ["fromDate"] = "01/01/2025", ["priorDate"] = "31/12/2024", ["branchFilter"] = ar ? "الكل" : "All",
        };

        public static object For(string name)
        {
            long n = 1;
            switch (name)
            {
                case "BriefBalanceSheetReport":
                    BriefBalanceSheetReport B(string t, string en, string a, decimal? s, decimal? tot) => new() { RowNo = n++, RowType = t, Description = en, DescriptionArabic = a, Subtotal = s, Total = tot };
                    return new List<BriefBalanceSheetReport>
                    {
                        B("FixedAssets", "Fixed Assets", "الاصول الثابته", null, 1500000m),
                        B("CurrentAssets", "Total Current Assets", "الاصول المتداوله", 800000.5m, null),
                        B("CurrentLiabilities", "Total Current Liabilities", "الخصوم المتداوله", -300000m, null),
                        B("WorkingCapital", "Working Capital", "رأس المال العامل", null, 500000.5m),
                        B("InvestedCapital", "Invested Capital", "رأس المال المستثمر", null, 2000000.5m),
                        B("Equity", "Total Owner's Equity", "اجمالي حقوق الملكيه", null, -1800000m),
                        B("LongTermLoans", "Long Term Loans", "قروض طويلة الأجل", null, -200000.5m),
                        B("CapitalInvested", "Capital Invested", "تمويل رأس المال المستثمر", null, -2000000.5m),
                    };
                case "CompareBalanceSheetReport":
                    var c = new List<CompareBalanceSheetReport>();
                    string[] cats = { "", "Long-term assets", "Current Assets", "Current Liabilities", "Equity (Owners' equity)", "Long-Term Liabilities" };
                    void C(int so, string t, int? mi, string d, decimal b) => c.Add(new() { RowNo = n++, SortOrder = so, RowType = t, MainItemId = mi, Description = d, Balance = b, PriorBalance = b * 0.8m });
                    for (int mi = 1; mi <= 5; mi++)
                    {
                        C(mi * 1000, "CategoryHeader", mi, cats[mi], 1000m * mi);
                        for (int s = 1; s <= 12; s++) C(mi * 1000 + 10 + s, "SubItem", mi, $"Sub item {mi}.{s}", 100m * s);
                        if (mi == 2) C(2900, "SummaryAssets", null, "Summary Assets", 3000m);
                        if (mi == 3) { C(3900, "NetWorkingCapital", null, "Net Working Capital", 500m); C(3910, "ContributedCapital", null, "Contributed Capital", 1500m); }
                    }
                    C(9000, "SummaryLiabilities", null, "Summary of Liabilities", -4000m);
                    return c;
                case "FinancialPositionStatementReport":
                    var p = new List<FinancialPositionStatementReport>();
                    string[] en = { "", "Long-term assets", "Current Assets", "Current Liabilities", "Equity", "Long-term liabilities" };
                    string[] arN = { "", "الاصول طويلة الاجل", "الاصول المتداولة", "الخصوم المتداولة", "حقوق الملكية", "الخصوم طويلة الاجل" };
                    void P(int so, string t, int? mi, string e, string a, string? sp, string? si, decimal? cost, decimal? dep, decimal net) => p.Add(new() { RowNo = n++, SortOrder = so, RowType = t, MainItemId = mi, MainItemName = e, MainItemNameArabic = a, SubParentItemName = sp, SubItemName = si, Cost = cost, Depreciation = dep, Net = net });
                    for (int mi = 1; mi <= 3; mi++)
                    {
                        P(mi * 100000, "CategoryHeader", mi, en[mi], arN[mi], null, null, null, null, 9000m);
                        for (int ps = 1; ps <= 2; ps++)
                        {
                            P(mi * 100000 + ps * 1000, "SubParentHeader", mi, en[mi], arN[mi], $"Parent {ps}", null, null, null, 4500m);
                            for (int s = 1; s <= 6; s++) P(mi * 100000 + ps * 1000 + s, "SubItem", mi, en[mi], arN[mi], $"Parent {ps}", $"Item {s}", mi == 1 ? 1000m : 0m, mi == 1 ? 250m : 750m, 750m);
                        }
                    }
                    P(400000, "Capital", null, "Capital", "رأس المال", null, null, null, null, 0m);
                    P(400001, "TotalInvestment", null, "Total Investment", "اجمالي الاستثمار", null, null, null, null, 9000m);
                    P(500000, "SubParentHeader", 4, en[4], arN[4], "Owners", null, null, null, -8000m);
                    P(500001, "CategoryHeader", 4, en[4], arN[4], null, null, null, null, -8000m);
                    for (int s = 1; s <= 3; s++) P(500010 + s, "SubItem", 4, en[4], arN[4], "Owners", $"Equity {s}", 0m, -2666m, -2666m);
                    P(600000, "CategoryHeader", 5, en[5], arN[5], null, null, null, null, -1000m);
                    P(600001, "SubParentHeader", 5, en[5], arN[5], "Loans", null, null, null, -1000m);
                    P(600011, "SubItem", 5, en[5], arN[5], "Loans", "Bank loan", 0m, -1000m, -1000m);
                    P(700000, "InvestmentFinancing", null, "Investment Financing", "الاستثمار المالي", null, null, null, null, -9000m);
                    return p;
                case "CashFlowReport":
                    var f = new List<CashFlowReport>();
                    (int o, string e, string a, decimal v)[] rows = {
                        (1, "Income Statement", "قائمة الدخل", 120000m), (2, "Depreciation", "الاهلاك", 15000m), (3, "Allocations", "المخصصات", -2000m),
                        (4, "Current Assets Decrease/Increase", "النقص / الزياده في الاصول المتداوله", -30000m), (4, "Inventory Decrease/Increase", "النقص / الزياده في المخزون", 5000m),
                        (6, "Current Liabilities Decrease/Increase", "النقص/ الزياده في الخصوم المتداوله", 7000m), (8, "Net Cash Flow From Operating Activity", "صافي التدفقات من نشاط التشغيل", 115000m),
                        (9, "Fixed Assets Sale", "بيع اصول طويلة الأجل", 0m), (10, "Fixed Assets Purchase", "شراء اصول طويلة الأجل", -50000m), (11, "Net Cash Flow From Investment Activity", "صافي التدفقات من نشاط الاستثمار", -50000m),
                        (12, "Equity (Owners’ equity)&Long-term liabilities Increase", "الزيادة في حقوق الملكية و الخصوم طويلة الأجل", 10000m), (13, "Equity (Owners’ equity)&Long-term liabilities Decrease", "النقص في حقوق الملكية و الخصوم طويلة الأجل", -4000m),
                        (14, "Net Cash Flow From Finance Activity", "صافي التدفقات من نشاط التمويل", 6000m), (15, "Net Cash Changing", "صافي التغير في النقدية", 71000m),
                        (16, "Start Period Cash Balance", "رصيد النقدية اول الفترة", -1234.5m), (17, "End Period Cash Balance", "رصيد النقدية اخر الفترة", 69765.5m) };
                    foreach (var x in rows) f.Add(new() { RowNo = n++, Ordr = x.o, RowType = x.o is 8 or 11 or 14 or 15 ? "Total" : "Item", Description = x.e, DescriptionArabic = x.a, Amount = x.v });
                    return f;
                default:
                    var q = new List<EquityChangingReport>();
                    (int id, string e, string a)[] types = { (1, "Equity Capital", "رأس المال"), (2, "Profits/Loss Migrated", "أرباح/خسائر مرحلة"), (3, "Year Profit/Loss", "أرباح/خسائر العام"), (4, "Shareholders' Equity", "حقوق المساهمين"), (5, "Reserves", "الاحتياطيات"), (6, "Allocations", "المخصصات") };
                    (string k, string e, string a)[] kinds = { ("Opening", "Opening Balance", "رصيد أول المدة"), ("Change", "Change in Reserves and Shareholders' Equity", "التغير ف الاحتياطات وحقوق المساهمين") };
                    foreach (var k in kinds) foreach (var t in types.OrderBy(t => t.e)) q.Add(new() { RowNo = n++, RowKind = k.k, RowCaption = k.e, RowCaptionArabic = k.a, EquityTypeId = t.id, EquityTypeName = t.e, EquityTypeNameArabic = t.a, Amount = 10000m * t.id });
                    q.Add(new() { RowNo = n++, RowKind = "NetProfit", RowCaption = "Net Profit/Loss of the Year", RowCaptionArabic = "صافى أرباح/خسائر العام", EquityTypeId = 3, EquityTypeName = types[2].e, EquityTypeNameArabic = types[2].a, Amount = 55555.55m });
                    return q;
            }
        }
    }
}
