# CR 125293 - app check, before (Stage Stable, legacy MVC iframe) vs after (local front + AnalyticsReader on db-all/UNP-Ali)

Date 2026-10-15. Company UNP-Ali. Layout "الافتراضي" / "Default" for every print. Screenshots are in this folder.

| report | language | before (rows/pages/total) | after grid (rows/total) | after print (pages, layout OK?) | match? | issues |
|---|---|---|---|---|---|---|
| Salaries Items (all employees) | AR | 88 pages, one page per employee, no totals | 286 rows / Amount 522,814.50 | 88 pages, OK (header, item table and RTL are fine) | Yes: 88 employees = 88 pages; 286 / 522,814.50 match SQL | Grid dates show date and time in US format ("9/30/2025, 12:00:00 AM"); the print shows 30/09/2025 |
| Salaries Items | EN | 88 pages | 286 / 522,814.50 | 88 pages, OK (LTR mirror) | Yes | Same grid date format |
| Pay Check 07/2026, All | AR | 3 pages, 75 rows in one Bank_1 group. **Net-salary column and total are blank on legacy** | 75 rows / Salary 300,718.93 | 3 pages, grouped by Branch/Department/Bank with a total per department, header "يوليو / 2026", OK | Yes: 75 rows; amounts per row match the grid | No grand total (300,718.93) in the print, only department subtotals. Grid shows English names (Employee_N) but the AR print shows Arabic names (موظف_N). Grid caption typo "اسم البتك" |
| Pay Check Paid / Not Paid | AR | - | Paid 75 / Not Paid 0 (isPaid=true/false sent) | - | Yes (Not Paid = 0 on this tenant) | When the status changes, the grid keeps the page index ($skip=70), then queries again |
| Pay Check | EN | 3 pages | 75 / 300,718.93 | 3 pages, "July / 2026", Total per department, OK | Yes | Same: no grand total |
| Salary Receipt 08/2026, all | AR | 20 pages (4 employees per page, net salary only) | 1,458 lines | 78 pages (one per employee, with income lines: approved change), OK | Yes: net per employee matches (emp 1 = 30,000, emp 47 = 4,675) | Grid "سنة الراتب" shows "2,026" (thousands separator on the year). Grid caption typo "اسم البتك". Employee name is the 2nd-language name (Employee_N), as on legacy |
| Salary Receipt, one employee (47) | AR | - | 20 lines | 1 page; additions 5,725, deductions 1,050, net 4,675 | Yes (net 4,675 = Pay Check) | - |
| Salary Receipt | EN | 20 pages | 1,458 | 78 pages, OK | Yes | Same year format |
| Insurance Registration 01/01-27/09/2026 | AR | **Empty: "The document does not contain any pages" (also empty for 2000-2026)** | 19 rows / TotalIncome 86,961 | 2 pages, landscape form, OK | Matches SQL (19 / 86,961). Cannot compare with legacy, which is empty | Grid: Gender is English ("Male/Female") in the AR UI; dates include the time. Print is sorted as text (100…117, 98, 99) |
| Insurance Registration | EN | Empty (same) | 19 / 86,961 | 2 pages, new English texts, OK | Matches SQL | Same |
| Employee Bonus 01/01-14/10/2026 | AR | 1 page, 3 rows, 1,000 / 235 / 217.50 | 3 rows / Total 1,452.5 | 1 page, OK | Yes | No total row in the print (legacy has none either) |
| Employee Bonus | EN | 1 page, same 3 rows | 3 / 1,452.5 | 1 page, OK | Yes | "Fixed Amount Bouns" typo (also on legacy) |

No raw translation keys (ODATAREPORTS.* / SALARYODATAREPORTS.*), no empty prints and no cut columns were seen. Console errors were all SignalR / notifications and were ignored.
