---
type: remaining
cr: 94062
updated: 2026-10-08
---

# CR-94062 — what is remaining

> [!info] State on 2026-10-08
> Code is complete, reviewed (round 2 **pass**) and **pushed** in all 4 repos. Web end-to-end on Sabreen is mostly verified ([[p8-results]]). **Merge Desk #94062 is still at Acknowledge**, so no PRs are open.

## Pushed heads (`origin/cr94062`)

| Repo | Head |
|---|---|
| AccFlex_Cloud_Database | `cda8b811b` |
| AccFlex_Cloud_ERP | `0db81200e5` |
| AccFlex_Cloud_Front | `718390d9d0` |
| AccFlex_ERP (desktop) | `57968fb116` |

## Remaining, in order

- [ ] **1. Desktop check** (engineer; I could not drive WinForms). Sign in to the Cash Management desktop **again after granting permission 500**: it reads extra permissions at login. Then:
  - [ ] The letters-of-guarantee screen shows "عملاء اللوجستيك" only on a Logistics-licensed company, and only with permission 500.
  - [ ] Choose a bank, then type 12: Logistics customers are listed with a **Code** column, and search by code finds one.
  - [ ] Save a guarantee for a Logistics customer.
  - [ ] Liquidate (تسييل) it: the account offered or used is the customer's receivable account (`Lgx_Customer.InvoiceAccountId`). If the customer isn't in the loaded list, the screen looks the account up by id; with no account it shows a message.
  - [ ] The guarantee report offers Logistics; the report and single print show the Logistics customer name.
  - [ ] Optional: confirm the shared desktop customer search form (`frmCustomerSearch_New`) still behaves on another screen, e.g. a receivable bank transfer. It now also matches on code.
  - Option: Claude launches `worktrees\cr94062\AccFlex_ERP\CashManagement\AccountingSafe\bin\Debug\Accflex AccountingSafe.exe` and checks each step in the Sabreen database, read-only. First check which DB and Cash Control API the desktop build points at.
- [ ] **2. Decide on Q6** ([[open-questions]]): which products count as "has Logistics" on web. Implemented: Logistics, LogisticsWeb, LogisticsSubs. Desktop uses `Product.Logistics` only. Not blocking.
- [ ] **3. ONE ship approval** (engineer says "ship 94062"). Then Claude:
  - [ ] fetches and re-checks that permission id **500** is still free on every `origin/*` branch;
  - [ ] confirms all 4 heads are pushed (they are, as of 2026-10-08);
  - [ ] moves Merge Desk **#94062 Acknowledge → Solved** (browser; the MCP was not connected). Merge Desk opens the PRs `cr94062 → Stage_Beta` and `cr94062 → Master_Stable` in API, Database, Desktop and WebContainer.
  - [ ] writes the PR notes (Merge Desk opens the PRs, so add them as PR comments or the description):
    - the shared `frmCustomerSearch_New` now also matches on code;
    - Logistics reads CashControl's `Saf_BankGuarantee` for the delete guard;
    - permission 500 (not 494, which is taken on Stage_Beta);
    - no NSwag regeneration (no contract change).
  - If a `Stage_Beta` PR conflicts: cut `cr94062_Stage_Beta` off `Stage_Beta`, merge `cr94062` into it, resolve there. **Never merge Stage_Beta into cr94062.**
- [ ] **4. After the Stage Beta deploy**, re-check what local P8 could not:
  - [ ] the report **grid** and **print** (locally the shared grid sent no request for any type, Accounts included);
  - [ ] decrease, extend and close on a Logistics LG;
  - [ ] a tenant **without** Logistics sees no new option (Acceptance 8).
- [ ] **5. ADO 94062 → Solved** once the stage PR is merged and checked.
- [ ] **6. Cleanup** once Merge Desk shows **Closed**: `scripts\remove-cr.ps1 -Id 94062` (frees port offset 100). Also remove the `cr94062-front` entry from `D:\Hadaf_Work\.claude\launch.json` (git-ignored, local only).

## Optional follow-ups (separate tickets, not this CR)

- [ ] **Bug: editing a saved LG fails.** `PUT /api/BankGuarantee/{id}` sends `ExpenseTaxPercent: null` and the API answers 400 ("Error converting value {null} to type 'System.Decimal'"). Exists before this CR. Check it on Beta.
- [ ] **Bug: liquidation pays the original amount.** After an increase (10,000 + 2,000), the liquidation row shows 12,000 but the payable journal is 10,000. `CloseOrCashBankGuaranteeCommand.cs:270` uses `Amount`, while the cover return uses `CurrentCoverAmount`. Applies to all types.
- [ ] Inventory and Real-estate customers on web (Q2: separate CR).
- [ ] Desktop enforcement of permissions 286–289 (Q4: separate decision).
- [ ] Ask the identity admin to register `http://localhost:4200/signout` (post-logout) and the 43xx ports (CORS) for client `accflexcloudangular` on `localbeta`, so local fronts stop bouncing to the deployed site.

## Test data left on Sabreen (support-db2)

- LG `CR94062-TEST-1` (Logistics customer 1, ابو سهيل): created, increased 2,000, liquidated.
- LG `CR94062-TEST-2` (Logistics customer 2, مخبز الرابية): created.
- Permission row 500 and the 2 report objects, from [[cr94062-sabreen.sql]].
- Permission 500 granted to the engineer's test user (done in the app by the engineer).
