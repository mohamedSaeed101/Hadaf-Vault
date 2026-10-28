---
type: open-questions
cr: 103744
tags: [cr, cr-103744, questions]
---

# CR-103744 — Open questions (each has a proposed default)

## Decisions taken (2026-10-07, with the engineer)

| D | From | Decision |
|---|---|---|
| D1 | Q1 | Follow-up CR for the deep link (Identity + mobile). This CR stores `Url`/`Type`/`EntityId` in the notification data. |
| D2 | Q2 | No notification for the cash holiday-work policy; days only. |
| D3 | Q3 | Logistics auto driver bonuses notify. |
| D4 | Q4 | **Notify on edit AND delete** for bonuses and added leave balances (overrides the proposed default). Plan impact: new message types (bonus updated/cancelled, leave balance updated/removed), hooks on the edit/delete paths, dedupe key includes the event. |
| D2' | Q2 (revised) | **Yes: notify the cash holiday-work allowance too** (replaces D2). Holiday-work notification covers both policies: leave days and cash. |
| D5 | Point 2 | The leave-balance notification is sent **only** when a balance is added (a) as the holiday-work credit, or (b) **manually** for the employee. **Carried-forward balance (رصيد مرحل, `TransferVacationBalance`) sends nothing.** Q7 is dropped. |

### Finding after D5 (2026-10-07)
The web has **no** manual "add earned balance" path. Every `PR_EmployeeAccruedvacation` write in Cloud_ERP is either carried-forward (`AnnualVacationSystemService.cs:328`, excluded) or holiday-work (`AttendanceSheetPolicies.cs:399,461`). `PUT api/EmployeeMain/EmployeeVacationInfo` only saves the vacation system and rule type (`EmployeeMainService.cs` `PutEmployeeVacationInfo`). Manual add exists **only on the desktop, through direct SQL**:
- `AccFlex_ERP/HRManagement/PayRoll/HR/frmAnnualVacationsSetting.cs:87-138` adds a vacation with name, days and date to selected employees (`PrEmployeeAccruedvacationService().Save`);
- `PayRoll.CL/PrEmployeeService.cs:340`, the employee form's grid, deletes and re-saves the whole collection, so edits can't be told apart from new rows without a diff.
So point 2(b) and D4 for leave balances depend completely on Q5.

| D6 | Q5 | **Desktop is out of scope.** No change to AccFlex_ERP; no desktop endpoints. |
| D7 | Q6 | Language = the sender's request culture (existing pattern). |
| D8 | Q8 | All company switches default **on**. |
| D9 | Q9 | Base `Master_Stable`. |

### Consequence of D6 (open: Q10)
With the desktop out, **point 2(b) (manual earned balance) and D4 for leave balances have no code path to hook**: on the web, the only manual add is the carried-forward screen, which D5 excludes. Q10: build a web manual-add, or deliver 2(b) as "not applicable" and say so on the ticket?

| D4' | Q4 (revised) | **Add only.** No notification on edit or delete (replaces D4). Bonus message types: `BonusAdded` only. |
| D10 | Q10 | The web manual add **is the `vacation-balance-transfer` screen** (`POST api/AnnualVacationSystem/TransferVacationBalance`, including its Excel import); it **notifies**. Cloud has no separate automatic year-end carry-forward, so D5's exclusion matches no other web path. |

| Q   | Question                                                                                                                                                                                                                                                 | Proposed default                                                                                                         | Owner            |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------- |
| Q1  | **Deep link and bell on mobile.** The FCM push carries title and body only; a deep link needs `IFireBaseInterface` and `ToPushNotification` changes in `Accflex_SharedProjects_ERP` (Identity) plus the Flutter ESS app, which is not in this workspace. | Out of this set. We store `Url`/`Type`/`EntityId` in the notification data now; a follow-up CR covers Identity + mobile. | PO / mobile team |
| Q2  | Holiday work with a **cash** policy: notify too?                                                                                                                                                                                                         | No. The agreed table, point 3, is "compensation in days".                                                                | PO               |
| Q3  | Logistics auto driver bonuses: notify?                                                                                                                                                                                                                   | Yes. They are bonuses for the employee.                                                                                  | PO               |
| Q4  | Bonus or leave-balance **edit or delete**: notify?                                                                                                                                                                                                       | No in v1.                                                                                                                | PO               |
| Q5  | Desktop direct-SQL paths: desktop calls an API endpoint after commit (chosen), or a DB outbox with a trigger?                                                                                                                                            | API endpoint + server dedupe. No triggers in the tenant DB.                                                              | Tech lead        |
| Q6  | Language: the sender's request culture (existing pattern), or the employee's app language?                                                                                                                                                               | Sender's culture. The employee's language is not stored anywhere today.                                                  | PO               |
| Q7  | Year-end bulk carry-forward: notify every employee?                                                                                                                                                                                                      | Yes, one per employee; the company can switch the type off.                                                              | PO               |
| Q8  | Default of the bonus flag for existing companies.                                                                                                                                                                                                        | On (all three on).                                                                                                       | PO               |
| Q9  | Environment "Beta" in the ticket: is it Temp Cloud Beta (base `CurrentRelease`) or Support Beta (`Master_Stable`)?                                                                                                                                       | `Master_Stable`, the CR default since 2026-10.                                                                           | Engineer         |

## Raised by the phase loop

| Q | Question | Options | Recommendation |
|---|---|---|---|
| Q11 | **Logistics driver-bonus notifications have no tenant.** The Hangfire payload `DriverBonusPayrollEmployeeBonusData` carries only a ConnectionString. The service falls back to `IUserSession.TenantId`, which is probably empty under Hangfire, and the `EmployeeSecurityLevel` query filter may hide the employee in that scope. So these pushes may not arrive. (Phase 4, `DriverBonusPayrollEmployeeBonusService.Execute`.) | (a) Add `TenantId` to the payload in `SharedKernel.Logic` and set it in Logistics `Create/UpdateDriverBonusCommand`. This is a cross-module contract change, made backward compatible as an optional field. (b) Accept as best effort and verify on Temp Cloud Beta. (c) Drop Logistics bonuses from scope (reverses D3). | (a), as an optional field: old jobs still deserialize. |
| Q12 | **Where are the three switches edited?** The Angular Payroll `company-settings-form` only *reads* `GET api/SystemConfiguration/CompanySettings`; nothing in Angular calls the Payroll `PUT …/CompanySettings`, so these settings are edited from the desktop, which is out of scope (D6). Phase 7 exposes the switches on GET and PUT (additive). | (a) Add an editable "ESS notifications" section to the web, which needs a new PUT call and the Client SDK. (b) Add the 3 checkboxes to the desktop company-settings form (reverses D6 for this one form). (c) No UI: the switches stay on by default (D8), changed by SQL when a customer asks. | (c) for this CR, since all switches are on by default; (a) as a follow-up if customers ask. |

## Decisions on the loop's questions (2026-10-07)

| D | From | Decision |
|---|---|---|
| D11 | Q11 | Add an **optional `TenantId`** to `DriverBonusPayrollEmployeeBonusData`, set it in the Logistics Create/UpdateDriverBonus commands, and pass it to `NotifyBonusAddedAsync`. Old queued jobs still deserialize. The Logistics API is redeployed with the CR. |
| D12 | Q12 | **No UI for the switches in this CR.** All on by default; support handles opt-outs. A web screen is a follow-up CR if customers ask. Phase 9 (Front) is dropped; the Client SDK runs at release only if the contract check asks for it. |
| D11' | user, 2026-10-07 | **Reverts D11.** No `TenantId` on the driver-bonus job: the ConnectionString is enough, because the push targets the employee's user id the same way existing Payroll notifications do. Revert commit `498be286c2`; Logistics and the shared payload are unchanged vs Master_Stable. |
| D13 | user, 2026-10-07 | **Remove `PR_EmployeeNotificationLog`** and all its code. Holiday-work repeat sends are prevented by a **before/after comparison** in the attendance calculate/update handlers: notify only when a credit is new or its value changed. Bonus and leave-balance pushes fire on create only. |
