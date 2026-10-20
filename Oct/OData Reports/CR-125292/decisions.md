# CR-125292 — decisions

All taken by the engineer on 2026-10-14, each the recommended option from [[open-questions]].

| # | Decision | Effect on the plan |
|---|---|---|
| D2 | **Full interactive report grid** for all 8 (not printOnlyMode). R2 and R3 use `report-grid-multi-request` (employee → income lines). | Deviation from the `mvc-to-odata-report-migration` skill, which targets print-only; the ticket's AC wins. Needs an `odata/<Name>` action per entity in `PayrollOdataController`. |
| D3 | **Keep the old print** as a "Print (previous design)" button on each screen, as fx124062 did for Total Salaries. | P7: each shell keeps `accflex-report-iframe-post` behind the button. |
| D4 | **Port the legacy SQL exactly**, except the R8 `VarChar(1024)` id-list cut, which is dropped (NVARCHAR(MAX) / NULL = all). R3 double bank account, R4 "Main Salary" = `InsuranceCompany`, R6/R8 end-of-work join are reproduced and reported to the PO as separate Bugs. | P1/P2 copy the queries verbatim; P4 parity expects zero difference, except R8 on a tenant whose full id list exceeds 1024 chars (legacy drops rows there). |
| D5 | **Apply the user's security level in all 8 reports** (today only R4, R6, R8). | Every TVF takes `@SecurityLevel`; behaviour change for non-admin users. Parity runs as admin (level 5), so numbers stay identical. |
| D6 | **Menu ModuleIds on every route and OData endpoint**: R1 514, R2 537, R3 542, R4 543, R5 539, R6 540, R7 538, R8 541. | R1, R5, R7 become reachable for non-admins holding the permission (today admins only); R4 checks 543 instead of the inherited 285. |

## Applied during P1/P2 (2026-10-14)

- **D4 extended to R3 lines:** legacy passed the header's salary ids to the lines query as an `nvarchar(1024)` CSV, same old-pipeline limit as R8; not reproduced (lines semi-join the header).
- **R1/R2 empty employee list:** legacy returned every month's salaries when the list was empty, but the old front always sent every employee id, so users only ever saw "all employees, chosen month". The TVFs implement that (NULL/'' = all employees, chosen month).
- **R6, R7 keep their legacy filters** (R6 department + branch CSVs, R7 single branch); no employee filter was added, matching "same filters".
- **R4 month label:** TVF returns both `Mnth` (EN) and `MnthArabic`; no `@IsArabic` parameter.
- **R3 "Total Employees Insurance"** = sum of `EmployeeInsuranceAmount` on the lines TVF (income id 10), so a header row duplicated by a second bank account does not double it.

## To report to the PO (from D4)

- R3: employee with more than one bank account in the salary currency prints twice; company-insurance total double-counted.
- R4: "Main Salary" column and footer show `InsuranceCompany`, not `BasicSalary`.
- R6, R8: end-of-work join by `EmployeeId` only pulls an ending employee's historical salary rows in with end-work amounts.

## Applied during P5–P7 (2026-10-14)

- **R4 dates:** from = start of day, to = end of day (legacy used raw timestamps from the date boxes). P4 parity must send date-only values.
- **R3 print "Total Employees Insurance":** computed in `EmployeesDetailedSalariesRptAng` over the lines list (each line once) and passed as report parameter `totalEmployeesInsurance`; the layout no longer sums lines attached per header (that doubled for a second bank account, unlike legacy).
- **Legacy print (D3):** the existing "Print" button of `pay-salary-report-form` / `pay-income-group-report-form` (used only by these 8 shells) is relabelled "Print (previous design)" and still runs the unchanged iframe path.
- **Language:** currency, salary source and R4 month label follow the UI/report language (legacy printed Arabic in both).
- **Grid totals:** none on screen (report-grid has no total-summary input); legacy totals live in the print layouts.
- **Money in layouts:** `{0:N2}` on the raw field (as 0405), not `?ApproximatePriceTo` (Logistics precision).
