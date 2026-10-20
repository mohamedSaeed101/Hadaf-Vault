---
type: cr-source
cr: 94062
customer: تطوير داخلى
story_points: 13
tags: [cr, cr-94062, source, cashcontrol, bank-guarantee]
---

> [!note] Facts read from ADO work item 94062 on 2026-10-07. The plan is in [[CR-94062 - Plan]].

# CR #94062 — اضافة عملاء الخدمات الوجيستية بخطابات الضمان

| Field | Value |
|---|---|
| Type | Change Request → `cr94062`, stage `Stage_Beta`, Merge Desk version `Beta` |
| State | In Development (board column acknowledged, lane BETA), assigned Mohamed Saeed |
| Program / screen | Cash Control / خطابات الضمان (Bank Guarantee, module 419) |
| Work type | Desktop + Web |
| Area | AccFlex_ERP\3- Customer Issues; Category Internal Development; Missed Feature |
| Parent | 1899 |
| Story points | 13 |
| Reviewed by | Sabreen Abubakr (AI-Reviewed tag), 2026-10-07 |
| Mock-up | https://claude.ai/artifact/3Z39vqa9JYvnzQm1ybhDve#cr94062 |

## Customer business value

مطلوب امكانية عمل خطابات ضمان لعملاء الخدمات الوجيسيتية كما هو متاح عمل خطابات الضمان لباقي العملاء من نوع انشاءات او مخازن او غيره، وبالتالي عند الوقوف على خانة العميل ظهور العملاء الموجودين ببرنامج الوجيسيتك. (2 screenshots attached inline.)

## To be implemented (numbered scope)

1. **New beneficiary type "عملاء اللوجستيك"** in the LG screen, web and desktop, next to Accounts / Construction / Inventory / Real-estate customers. Shown only when the company has the Logistics program. Desktop writes to the DB with its own rules, so both places change.
2. **Customer list shows Logistics customers** (code + name, search by name and code), active customers only.
3. **Customer account in LG transactions (liquidation)** comes from the Logistics customer's AR account; the account branch must match the bank branch (account branches = the customer's sales-org branches). Needs confirming.
4. **Additional permission "عملاء اللوجستيك"** on the LG screen, like the other customer types; option visible only with the permission. Open: all Logistics customers, or only those on the user's sales orgs?
5. **LG report and screen search**: beneficiary-type filter includes Logistics; customer name resolves correctly.
6. **Web Inventory / Real-estate customers**: available on desktop only today. Decision needed: Logistics only, or also enable those on web.

UI/UX: changing the type clears the customer; clear "اختار العميل" message when saving without one; same lookup look (code - name) with search; hide the option when not licensed / no permission; in view mode of an old LG, type and customer read-only after the first transaction.

Impacted: desktop LG screen; LG transactions (increase, decrease, extend, close, liquidate); LG report; LG additional permissions; Logistics customer delete must be refused when the customer has an LG; no existing data affected.

## Comments

1. Muhammed Tariq, 2024-10-31: "Planned 2B Developed in 06/25".
2. Sabreen Abubakr, 2026-10-07 (AI review): not in the system. Web accepts Accounts and Construction customers only; Inventory and Real-estate are switched off on web; Logistics missing on both. Recommends deciding whether web should also get Inventory and Real-estate.

## Attachments

Two inline screenshots in Customer Business Value (current LG screens). No relation attachments, no recordings.
