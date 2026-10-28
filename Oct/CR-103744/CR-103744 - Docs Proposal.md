---
type: docs-proposal
cr: 103744
status: proposed (not applied to accflex-docs)
tags: [cr, cr-103744, docs]
---

# CR-103744 — proposed `accflex-docs` updates

Apply after the tester signs off. Each block is meant to be pasted under a new `## Employee notification (ESS)` heading in the named note.

## `Payroll/5 - Wages & Salaries/EmployeeBonus/EmployeeBonus.business.md`

> When a bonus is **added** for an employee, the employee gets a notification on the ESS app if they have an app account. This applies to bonuses from the bonus screen, the bonus import and Logistics driver bonuses. It shows the bonus name, amount and currency, date and description. Edits and deletes send nothing. Company setting: *Notify employee on bonus* (on by default). Bonuses saved from the desktop also notify, because the desktop saves through the API.

## `Payroll/1 - Organization & Policies/VacationWorkPolicy/VacationWorkPolicy.business.md`

> When the monthly attendance sheet credits an employee for working an official holiday, the employee is notified once per holiday, however often the sheet is recalculated:
> - **Vacation balance mode:** "leave credit for working on a public holiday", with the days, the date and the holiday name.
> - **Cash mode:** "allowance for working on a public holiday", with the date, the holiday name, the amount and currency, and "paid with this month's salary". One notification per currency.
> - **Depends on the holiday:** whichever of the two the holiday decides.
>
> No notification is sent when the credit is silently skipped (no annual leave type), or when the sheet is calculated from the desktop. Company setting: *Notify employee on holiday work* (on by default).

## `Payroll/1 - Organization & Policies/SystemConfiguration/SystemConfiguration.business.md`

> Three company switches control ESS notifications: **bonus added**, **leave balance added** (vacation balance transfer screen) and **work on official holidays**. All three are on by default. They are exposed on `GET/PUT api/SystemConfiguration/CompanySettings`. There is no web screen to edit them yet (CR-103744 Q12).

## Leave balance (cycle 2, `Vacations` / the vacation balance transfer screen)

> Saving the *Vacation balance transfer* screen, including rows that came from its Excel import, notifies each employee whose balance was added (rows with 0 days excluded): leave type, days, valid-from date and description. Company setting: *Notify employee on leave balance*.
