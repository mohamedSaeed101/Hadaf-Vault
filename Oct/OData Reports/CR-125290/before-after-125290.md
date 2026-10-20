# CR-125290 — before/after data re-run (2026-10-16)

This re-runs [[parity-125290]] against the TVFs as they stand after review rounds 1–2 and P6, with the `DimensionName` cast removed. The script was regenerated from the current worktree files (`parity-125290.sql`, now with 0 `NVARCHAR(250)`). It ran read-only on `db-all` against Rusasnew, dbriyadh_Primary and ACCFLEX-ERP.

**Before** = the legacy MVC xsd SQL plus the print-time C# rollups. **After** = the new TVF body. For each part, "First non-zero total" is the first money column whose sum is not zero.

**Result:**
- All 158 real-data parts PASS: equal row counts, EXCEPT empty both ways, duplicate-aware check clean, and every money column sum equal.
- Each of the 7 negative controls was detected. These perturb only the new side, so they must show a difference.
- No SQL errors.

| Tenant | Case | Part | Rows before | Rows after | First non-zero total before | after | Result |
|---|---|---|---|---|---|---|---|
| ACCFLEX-ERP | SP 3 (2023-03), all | R1.AccountType | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), all | R1.GOP | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), all | R1.OtherAccountType | 5 | 5 | 9,000.00 | 9,000.00 | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), all | R1.Totals | 2 | 2 | -9,000.00 | -9,000.00 | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), cc 28 (budget cc 28) | R1.AccountType | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), cc 28 (budget cc 28) | R1.GOP | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), cc 28 (budget cc 28) | R1.OtherAccountType | 5 | 5 | 5,000.00 | 5,000.00 | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), cc 28 (budget cc 28) | R1.Totals | 2 | 2 | -5,000.00 | -5,000.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R1.AccountType | 6 | 6 | 5,000.00 | 5,000.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R1.GOP | 10 | 10 | -5,000.00 | -5,000.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R1.OtherAccountType | 5 | 5 | 10,000.00 | 10,000.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R1.Totals | 2 | 2 | -15,030.00 | -15,030.00 | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), br 1026 | R2.AccountType | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), br 1026 | R2.GOP | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), br 1026 | R2.OtherAccountType | 5 | 5 | 9,000.00 | 9,000.00 | PASS |
| ACCFLEX-ERP | SP 3 (2023-03), br 1026 | R2.Totals | 2 | 2 | -9,000.00 | -9,000.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R2.AccountType | 10 | 10 | 10,030.00 | 10,030.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R2.GOP | 18 | 18 | -30.00 | -30.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R2.OtherAccountType | 5 | 5 | 10,000.00 | 10,000.00 | PASS |
| ACCFLEX-ERP | SP 1020 (2025-08), all | R2.Totals | 2 | 2 | -10,060.00 | -10,060.00 | PASS |
| ACCFLEX-ERP | 2025 month=null (1..12), all | R3.Dimension | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | 2025 month=null (1..12), all | R3.Summary | 8 | 8 | -81,500.00 | -81,500.00 | PASS |
| ACCFLEX-ERP | 2024 month=true (1..6), cc 28 | R3.Dimension | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | 2024 month=true (1..6), cc 28 | R3.Summary | 6 | 6 | -42,000.00 | -42,000.00 | PASS |
| ACCFLEX-ERP | 2025 month=null (1..12), br 1026 | R4.Dimension | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | 2025 month=null (1..12), br 1026 | R4.Summary | 8 | 8 | -76,500.00 | -76,500.00 | PASS |
| ACCFLEX-ERP | 2024 month=false (6..12), all | R4.Dimension | 0 | 0 |  |  | PASS |
| ACCFLEX-ERP | 2024 month=false (6..12), all | R4.Summary | 3 | 3 | -15,000.00 | -15,000.00 | PASS |
| ACCFLEX-ERP | 2025 month=null (1..12), all | R5.SubItem | 24 | 24 | 532,531.98 | 532,531.98 | PASS |
| ACCFLEX-ERP | 2025 month=null (1..12), all | R5.Totals | 3 | 3 | -332,271.81 | -332,271.81 | PASS |
| ACCFLEX-ERP | 2024 month=false (6..12), revised=true | R5.SubItem | 1 | 1 | 5,000.00 | 5,000.00 | PASS |
| ACCFLEX-ERP | 2024 month=false (6..12), revised=true | R5.Totals | 3 | 3 | 10,000.00 | 10,000.00 | PASS |
| Rusasnew | SP 13 (2021-06), all | R1.AccountType | 17 | 17 | 156,360.44 | 156,360.44 | PASS |
| Rusasnew | SP 13 (2021-06), all | R1.GOP | 34 | 34 | -156,360.44 | -156,360.44 | PASS |
| Rusasnew | SP 13 (2021-06), all | R1.OtherAccountType | 4 | 4 | 0.00 | 0.00 | PASS |
| Rusasnew | SP 13 (2021-06), all | R1.Totals | 2 | 2 | -156,360.44 | -156,360.44 | PASS |
| Rusasnew | SP 22 (2022-03), cc 32,17,1019, jt 5 | R1.AccountType | 0 | 0 |  |  | PASS |
| Rusasnew | SP 22 (2022-03), cc 32,17,1019, jt 5 | R1.GOP | 0 | 0 |  |  | PASS |
| Rusasnew | SP 22 (2022-03), cc 32,17,1019, jt 5 | R1.OtherAccountType | 4 | 4 | 0.00 | 0.00 | PASS |
| Rusasnew | SP 22 (2022-03), cc 32,17,1019, jt 5 | R1.Totals | 2 | 2 | 0.00 | 0.00 | PASS |
| Rusasnew | SP 13 (2021-06), jt 5,6 (closing journals excluded) | R1.AccountType | 15 | 15 | 57,882.72 | 57,882.72 | PASS |
| Rusasnew | SP 13 (2021-06), jt 5,6 (closing journals excluded) | R1.GOP | 30 | 30 | -57,882.72 | -57,882.72 | PASS |
| Rusasnew | SP 13 (2021-06), jt 5,6 (closing journals excluded) | R1.OtherAccountType | 4 | 4 | 104,646.00 | 104,646.00 | PASS |
| Rusasnew | SP 13 (2021-06), jt 5,6 (closing journals excluded) | R1.Totals | 2 | 2 | -35,760.35 | -35,760.35 | PASS |
| Rusasnew | SP 1 (2021-05), all (type-2 budget on branch 2) | R2.AccountType | 2 | 2 | 5,000.00 | 5,000.00 | PASS |
| Rusasnew | SP 1 (2021-05), all (type-2 budget on branch 2) | R2.GOP | 2 | 2 | -5,000.00 | -5,000.00 | PASS |
| Rusasnew | SP 1 (2021-05), all (type-2 budget on branch 2) | R2.OtherAccountType | 4 | 4 | 0.00 | 0.00 | PASS |
| Rusasnew | SP 1 (2021-05), all (type-2 budget on branch 2) | R2.Totals | 2 | 2 | -10,000.00 | -10,000.00 | PASS |
| Rusasnew | SP 13 (2021-06), br 2 (YTD budget = SP 1) | R2.AccountType | 2 | 2 | 5,000.00 | 5,000.00 | PASS |
| Rusasnew | SP 13 (2021-06), br 2 (YTD budget = SP 1) | R2.GOP | 2 | 2 | -5,000.00 | -5,000.00 | PASS |
| Rusasnew | SP 13 (2021-06), br 2 (YTD budget = SP 1) | R2.OtherAccountType | 4 | 4 | 0.00 | 0.00 | PASS |
| Rusasnew | SP 13 (2021-06), br 2 (YTD budget = SP 1) | R2.Totals | 2 | 2 | -10,000.00 | -10,000.00 | PASS |
| Rusasnew | SP 20 (2022-01), br 1,3, jt 5,6 | R2.AccountType | 0 | 0 |  |  | PASS |
| Rusasnew | SP 20 (2022-01), br 1,3, jt 5,6 | R2.GOP | 0 | 0 |  |  | PASS |
| Rusasnew | SP 20 (2022-01), br 1,3, jt 5,6 | R2.OtherAccountType | 4 | 4 | 0.00 | 0.00 | PASS |
| Rusasnew | SP 20 (2022-01), br 1,3, jt 5,6 | R2.Totals | 2 | 2 | 0.00 | 0.00 | PASS |
| Rusasnew | SP 13 (2021-06), br 2, jt 5,6,24,30 (YTD budget, closing excluded) | R2.AccountType | 2 | 2 | 7,356,114.75 | 7,356,114.75 | PASS |
| Rusasnew | SP 13 (2021-06), br 2, jt 5,6,24,30 (YTD budget, closing excluded) | R2.GOP | 2 | 2 | -48,203.87 | -48,203.87 | PASS |
| Rusasnew | SP 13 (2021-06), br 2, jt 5,6,24,30 (YTD budget, closing excluded) | R2.OtherAccountType | 4 | 4 | 151,649.75 | 151,649.75 | PASS |
| Rusasnew | SP 13 (2021-06), br 2, jt 5,6,24,30 (YTD budget, closing excluded) | R2.Totals | 2 | 2 | -248,057.49 | -248,057.49 | PASS |
| Rusasnew | 2022 month=null (1..12), all | R3.Dimension | 0 | 0 |  |  | PASS |
| Rusasnew | 2022 month=null (1..12), all | R3.Summary | 36 | 36 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2022 month=true (1..6), jt 5,6 | R3.Dimension | 0 | 0 |  |  | PASS |
| Rusasnew | 2022 month=true (1..6), jt 5,6 | R3.Summary | 18 | 18 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2022 month=null (1..12), all | R4.Dimension | 12 | 12 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2022 month=null (1..12), all | R4.Summary | 36 | 36 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2022 month=true (1..6), br 2 | R4.Dimension | 6 | 6 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2022 month=true (1..6), br 2 | R4.Summary | 18 | 18 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2022 month=false (6..12), all | R4.Dimension | 7 | 7 | -1,405,764.79 | -1,405,764.79 | PASS |
| Rusasnew | 2022 month=false (6..12), all | R4.Summary | 21 | 21 | -1,332,562.85 | -1,332,562.85 | PASS |
| Rusasnew | 2023 month=true, br 2, jt 5 | R4.Dimension | 6 | 6 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2023 month=true, br 2, jt 5 | R4.Summary | 18 | 18 | -20,000.00 | -20,000.00 | PASS |
| Rusasnew | 2025 month=true (1..6), all | R5.SubItem | 33 | 33 | -122,650,217.17 | -122,650,217.17 | PASS |
| Rusasnew | 2025 month=true (1..6), all | R5.Totals | 3 | 3 | -10,700,952.56 | -10,700,952.56 | PASS |
| Rusasnew | 2025 month=false (6..12), br 2, cc 32,17 | R5.SubItem | 8 | 8 | 836,299.67 | 836,299.67 | PASS |
| Rusasnew | 2025 month=false (6..12), br 2, cc 32,17 | R5.Totals | 3 | 3 | -2,508,899.02 | -2,508,899.02 | PASS |
| Rusasnew | 2024 month=null (1..12), jt 5,6 | R5.SubItem | 57 | 57 | 221,694,157.93 | 221,694,157.93 | PASS |
| Rusasnew | 2024 month=null (1..12), jt 5,6 | R5.Totals | 3 | 3 | 62,184,236.61 | 62,184,236.61 | PASS |
| Rusasnew | NEGATIVE: 2022 month=true br 2, new side br 3 | R4.Dimension | 6 | 0 | -20,000.00 |  | DETECTED |
| Rusasnew | NEGATIVE: 2022 month=true br 2, new side br 3 | R4.Summary | 18 | 0 | -20,000.00 |  | DETECTED |
| Rusasnew | NEGATIVE: SP 13 br 2, new side br 1 | R2.AccountType | 2 | 0 | 5,000.00 |  | DETECTED |
| Rusasnew | NEGATIVE: SP 13 br 2, new side br 1 | R2.GOP | 2 | 0 | -5,000.00 |  | DETECTED |
| Rusasnew | NEGATIVE: SP 13 br 2, new side br 1 | R2.OtherAccountType | 4 | 4 | 0.00 | 0.00 | NOT DETECTED |
| Rusasnew | NEGATIVE: SP 13 br 2, new side br 1 | R2.Totals | 2 | 2 | -10,000.00 | 0.00 | DETECTED |
| dbriyadh_Primary | SP 18 (2025), all | R1.AccountType | 85 | 85 | 428,498,542.30 | 428,498,542.30 | PASS |
| dbriyadh_Primary | SP 18 (2025), all | R1.GOP | 102 | 102 | 56,098,830.95 | 56,098,830.95 | PASS |
| dbriyadh_Primary | SP 18 (2025), all | R1.OtherAccountType | 5 | 5 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 18 (2025), all | R1.Totals | 2 | 2 | 56,098,830.95 | 56,098,830.95 | PASS |
| dbriyadh_Primary | SP 18 (2025), cc 49,45,43, revised=true | R1.AccountType | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | SP 18 (2025), cc 49,45,43, revised=true | R1.GOP | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | SP 18 (2025), cc 49,45,43, revised=true | R1.OtherAccountType | 5 | 5 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 18 (2025), cc 49,45,43, revised=true | R1.Totals | 2 | 2 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 18 (2025), revised=false, jt 51,14 | R1.AccountType | 43 | 43 | 82,469,837.45 | 82,469,837.45 | PASS |
| dbriyadh_Primary | SP 18 (2025), revised=false, jt 51,14 | R1.GOP | 86 | 86 | -82,469,837.45 | -82,469,837.45 | PASS |
| dbriyadh_Primary | SP 18 (2025), revised=false, jt 51,14 | R1.OtherAccountType | 5 | 5 | 6,888.96 | 6,888.96 | PASS |
| dbriyadh_Primary | SP 18 (2025), revised=false, jt 51,14 | R1.Totals | 2 | 2 | -164,946,563.85 | -164,946,563.85 | PASS |
| dbriyadh_Primary | SP 1 (2023 Q1), all (type-4 budget 400) | R1.AccountType | 30 | 30 | 55,991,195.97 | 55,991,195.97 | PASS |
| dbriyadh_Primary | SP 1 (2023 Q1), all (type-4 budget 400) | R1.GOP | 44 | 44 | -2,649,086.87 | -2,649,086.87 | PASS |
| dbriyadh_Primary | SP 1 (2023 Q1), all (type-4 budget 400) | R1.OtherAccountType | 5 | 5 | 400.00 | 400.00 | PASS |
| dbriyadh_Primary | SP 1 (2023 Q1), all (type-4 budget 400) | R1.Totals | 2 | 2 | -2,649,086.87 | -2,649,086.87 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), all (YTD budget = SP 1) | R1.AccountType | 32 | 32 | 55,308,537.03 | 55,308,537.03 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), all (YTD budget = SP 1) | R1.GOP | 44 | 44 | 1,470,945.41 | 1,470,945.41 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), all (YTD budget = SP 1) | R1.OtherAccountType | 5 | 5 | 400.00 | 400.00 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), all (YTD budget = SP 1) | R1.Totals | 2 | 2 | 1,470,945.41 | 1,470,945.41 | PASS |
| dbriyadh_Primary | SP 18 (2025), all | R2.AccountType | 2 | 2 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 18 (2025), all | R2.GOP | 2 | 2 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 18 (2025), all | R2.OtherAccountType | 5 | 5 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 18 (2025), all | R2.Totals | 2 | 2 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), br 2, revised=false | R2.AccountType | 2 | 2 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), br 2, revised=false | R2.GOP | 2 | 2 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), br 2, revised=false | R2.OtherAccountType | 5 | 5 | 400.00 | 400.00 | PASS |
| dbriyadh_Primary | SP 14 (2023 Q2), br 2, revised=false | R2.Totals | 2 | 2 | -400.00 | -400.00 | PASS |
| dbriyadh_Primary | NEGATIVE: SP 18 all, new side cc 49 | R1.AccountType | 85 | 2 | 428,498,542.30 | 118,086,369.92 | DETECTED |
| dbriyadh_Primary | NEGATIVE: SP 18 all, new side cc 49 | R1.GOP | 102 | 2 | 56,098,830.95 | 4,922,046.64 | DETECTED |
| dbriyadh_Primary | NEGATIVE: SP 18 all, new side cc 49 | R1.OtherAccountType | 5 | 5 | 0.00 | 595,992.66 | DETECTED |
| dbriyadh_Primary | NEGATIVE: SP 18 all, new side cc 49 | R1.Totals | 2 | 2 | 56,098,830.95 | 9,248,100.62 | DETECTED |
| dbriyadh_Primary | 2025 month=null (1..12), all | R3.Dimension | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | 2025 month=null (1..12), all | R3.Summary | 12 | 12 | -14,900.00 | -14,900.00 | PASS |
| dbriyadh_Primary | 2025 month=true (1..6), cc 49 | R3.Dimension | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | 2025 month=true (1..6), cc 49 | R3.Summary | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | 2025 month=false (6..12), revised=true | R3.Dimension | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | 2025 month=false (6..12), revised=true | R3.Summary | 7 | 7 | -11,900.00 | -11,900.00 | PASS |
| dbriyadh_Primary | 2025 month=null (1..12), all | R4.Dimension | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | 2025 month=null (1..12), all | R4.Summary | 12 | 12 | -14,900.00 | -14,900.00 | PASS |
| dbriyadh_Primary | 2026 month=true (1..6), br 2, jt 51,14 | R4.Dimension | 0 | 0 |  |  | PASS |
| dbriyadh_Primary | 2026 month=true (1..6), br 2, jt 51,14 | R4.Summary | 6 | 6 | -4,600.00 | -4,600.00 | PASS |
| dbriyadh_Primary | 2025 month=true (1..6), all | R5.SubItem | 26 | 26 | 197,955,900.55 | 197,955,900.55 | PASS |
| dbriyadh_Primary | 2025 month=true (1..6), all | R5.Totals | 3 | 3 | 51,104,899.89 | 51,104,899.89 | PASS |
| dbriyadh_Primary | 2025 month=false (6..12), cc 49,45, jt 51,14 | R5.SubItem | 12 | 12 | 32,952,717.21 | 32,952,717.21 | PASS |
| dbriyadh_Primary | 2025 month=false (6..12), cc 49,45, jt 51,14 | R5.Totals | 3 | 3 | -98,853,586.62 | -98,853,586.62 | PASS |
| dbriyadh_Primary | 2025 month=null (1..12), br 1, revised=true | R5.SubItem | 1 | 1 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | 2025 month=null (1..12), br 1, revised=true | R5.Totals | 3 | 3 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | 2024 month=null (1..12), revised=false | R5.SubItem | 46 | 46 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | 2024 month=null (1..12), revised=false | R5.Totals | 3 | 3 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | NEGATIVE: 2025 month=true all, new side jt 51 | R5.SubItem | 26 | 9 | 197,955,900.55 | 7,686,054.48 | DETECTED |
| dbriyadh_Primary | NEGATIVE: 2025 month=true all, new side jt 51 | R5.Totals | 3 | 3 | 51,104,899.89 | -23,056,760.48 | DETECTED |
| dbriyadh_Primary | NEGATIVE: 2025 month=null all, new side cc 49 | R3.Dimension | 0 | 0 |  |  | NOT DETECTED |
| dbriyadh_Primary | NEGATIVE: 2025 month=null all, new side cc 49 | R3.Summary | 12 | 0 | -14,900.00 |  | DETECTED |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R1.AccountType | 85 | 85 | 428,498,542.30 | 428,498,542.30 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R1.GOP | 102 | 102 | 56,098,830.95 | 56,098,830.95 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R1.OtherAccountType | 5 | 5 | 9,180.00 | 9,180.00 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R1.Totals | 2 | 2 | 56,098,830.95 | 56,098,830.95 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), cc 49,43, jt 51,14 | R1.AccountType | 4 | 4 | 42,418,764.73 | 42,418,764.73 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), cc 49,43, jt 51,14 | R1.GOP | 4 | 4 | -42,418,764.73 | -42,418,764.73 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), cc 49,43, jt 51,14 | R1.OtherAccountType | 5 | 5 | 5,010.00 | 5,010.00 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), cc 49,43, jt 51,14 | R1.Totals | 2 | 2 | -84,842,539.46 | -84,842,539.46 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), all (YTD budget = SP 1 + SP 14) | R1.AccountType | 43 | 43 | 60,675,569.70 | 60,675,569.70 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), all (YTD budget = SP 1 + SP 14) | R1.GOP | 54 | 54 | 767,441.36 | 767,441.36 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), all (YTD budget = SP 1 + SP 14) | R1.OtherAccountType | 5 | 5 | 9,150.00 | 9,150.00 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), all (YTD budget = SP 1 + SP 14) | R1.Totals | 2 | 2 | 767,441.36 | 767,441.36 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R2.AccountType | 3 | 3 | 46,805.00 | 46,805.00 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R2.GOP | 4 | 4 | -14,085.00 | -14,085.00 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R2.OtherAccountType | 5 | 5 | 9,180.00 | 9,180.00 | PASS |
| dbriyadh_Primary | SYN: SP 18 (2025), all | R2.Totals | 2 | 2 | -37,350.00 | -37,350.00 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), br 3, revised=false | R2.AccountType | 1 | 1 | 4,305.00 | 4,305.00 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), br 3, revised=false | R2.GOP | 2 | 2 | -4,305.00 | -4,305.00 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), br 3, revised=false | R2.OtherAccountType | 5 | 5 | 0.00 | 0.00 | PASS |
| dbriyadh_Primary | SYN: SP 15 (2023 Q3), br 3, revised=false | R2.Totals | 2 | 2 | -8,610.00 | -8,610.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=null (1..12), all | R3.Dimension | 84 | 84 | -280,740.00 | -280,740.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=null (1..12), all | R3.Summary | 36 | 36 | -284,420.00 | -284,420.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=true (1..6), cc 49,45 | R3.Dimension | 18 | 18 | -84,660.00 | -84,660.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=true (1..6), cc 49,45 | R3.Summary | 18 | 18 | -138,870.00 | -138,870.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=false (6..12), jt 51,14 | R3.Dimension | 49 | 49 | -164,815.00 | -164,815.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=false (6..12), jt 51,14 | R3.Summary | 21 | 21 | -170,345.00 | -170,345.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=null, revised=true | R3.Dimension | 84 | 84 | -280,740.00 | -280,740.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=null, revised=true | R3.Summary | 36 | 36 | -284,420.00 | -284,420.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=null (1..12), all | R4.Dimension | 36 | 36 | -160,740.00 | -160,740.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=null (1..12), all | R4.Summary | 36 | 36 | -284,420.00 | -284,420.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=true (1..6), br 2 | R4.Dimension | 12 | 12 | -54,840.00 | -54,840.00 | PASS |
| dbriyadh_Primary | SYN: 2025 month=true (1..6), br 2 | R4.Summary | 18 | 18 | -113,650.00 | -113,650.00 | PASS |
| dbriyadh_Primary | SYN: 2024 month=false (6..12), br 3, jt 51 | R4.Dimension | 7 | 7 | -29,295.00 | -29,295.00 | PASS |
| dbriyadh_Primary | SYN: 2024 month=false (6..12), br 3, jt 51 | R4.Summary | 7 | 7 | -29,295.00 | -29,295.00 | PASS |
| dbriyadh_Primary | SYN NEGATIVE: 2025 month=null all, new side cc 43 | R3.Dimension | 84 | 24 | -280,740.00 | 47,220.00 | DETECTED |
| dbriyadh_Primary | SYN NEGATIVE: 2025 month=null all, new side cc 43 | R3.Summary | 36 | 24 | -284,420.00 | 34,440.00 | DETECTED |
| dbriyadh_Primary | SYN NEGATIVE: SP 15 all, new side SP 14 | R1.AccountType | 43 | 39 | 60,675,569.70 | 55,308,537.03 | DETECTED |
| dbriyadh_Primary | SYN NEGATIVE: SP 15 all, new side SP 14 | R1.GOP | 54 | 52 | 767,441.36 | 1,470,945.41 | DETECTED |
| dbriyadh_Primary | SYN NEGATIVE: SP 15 all, new side SP 14 | R1.OtherAccountType | 5 | 5 | 9,150.00 | 9,140.00 | DETECTED |
| dbriyadh_Primary | SYN NEGATIVE: SP 15 all, new side SP 14 | R1.Totals | 2 | 2 | 767,441.36 | 1,470,945.41 | DETECTED |