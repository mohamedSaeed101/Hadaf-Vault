---
type: cr-source
cr: 103744
customer: تطوير داخلى (internal)
program: ESS App
work_type: API+Desktop
environment: Beta
state: New
parent: 18226
created: 2025-05-11
read: 2026-10-07
tags: [cr, cr-103744, source, payroll, ess, notifications]
---

> [!note] Facts read from Azure DevOps on 2026-10-07 (every field, the one comment, relations). The work item has no attachments; the only link besides the parent is the mock-up artifact in "To be implemented". Plan: [[CR-103744 - Plan]].

# CR #103744 — ESS notifications for bonuses and added leave balance

**Title:** فى حالة إصدار مكافأة للموظف أو اضافة رصيد اجازات مستحق يتم ارسال للموظف notifications

## Metadata

| Field | Value |
|---|---|
| Type / State | Change Request / New (reviewed 2026-10-06 by Sabreen Abubakr, tag `AI-Reviewed`) |
| Area | `AccFlex_ERP\3- Customer Issues` |
| Program | ESS App |
| Customer | تطوير داخلى (internal development), Egypt |
| Category | Internal Development · Not paid · Not breaking |
| Work type | **API + Desktop** |
| Environment | Beta |
| Team | SKY |
| Priority | Medium |
| Due date | 2025-05-25 (long past) · comment's delivery date 12/2025 |
| Parent | 18226 |
| Fees | "With no Change Fees" |

## Description (original)

ESS app: send a notification when a bonus is issued to an employee, and when an earned leave balance is added for an employee who attends on official holidays (that day is added to the employee).

## Agreed scope — comment "ما سيتم تنفيذه" (Muhammed Tariq, 2025-05-11)

1. Notification to the employee on the app when a **bonus** is created for them. Contains bonus type, amount, date, description.
2. Notification when an **earned leave balance** is added. Contains the leave type added, number of days, date, and description of the reason.
3. Notification when **compensation for working on official holidays** is added. Contains the compensation in days, date, description.

## "To be implemented" field (AI review, 2026-10-06), summarised

- **Bonus:** fire on save from the bonus screen and from bonus import (one notification per employee per bonus, only after a successful import). Text: "A bonus was added for you" + type, amount + currency, date, description. Tapping opens the bonus details (read-only) or that month's salary details.
- **Leave balance:** manual add (carried-forward leave balance screen) and import. Text: leave type, days, date, reason. Tapping opens the leave screen on that type. Notes that balance is computed, not stored. Monthly accrual is not a recorded transaction, so it gets no notification. Open point: the year-end carry-forward hits the whole company at once.
- **Public-holiday work:** created during the monthly attendance-sheet calculation, only when the day is a holiday and the employee has both a check-in and a check-out. Policy: cash / leave balance / per holiday. Recalculation deletes and recreates the credit, so **notify once per day only**. If the day is cancelled on recalculation, either send a cancellation or nothing (decision). No annual-leave type means no credit, so no notification.
- **Common:** only employees with an app account; no error otherwise. Edit or delete before payroll: notify or not (decision). Employee's app language (ar/en). **Per-company on/off setting per notification type** (recommended). Personal to the employee, never to their manager or substitute.
- **UI/UX:** must deep-link to the right screen; must state the reason clearly. Recommended: a bell list with an unread count. Optional: group bulk-import notifications.
- **Affected:** bonus screen and bonus import (web), Logistics auto-bonuses (driver bonus, a decision), carried-forward balance and import, monthly attendance calculation and recalculation, **desktop** (adds balances and edits the holiday policy without the web), the ESS app (receive, deep-link, show the new balance).
- Mock-up: https://claude.ai/artifact/3Z39vqa9JYvnzQm1ybhDve#cr103744
