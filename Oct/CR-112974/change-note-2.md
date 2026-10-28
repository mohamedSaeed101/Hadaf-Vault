# Change note 2 — CR 112974, QA comment 10015919, issue 3

- **What:** raw-material job items keep their unit when the tenant does not integrate with logistics: the unit field shows and is required, and the unit is no longer zeroed on create / full update. With logistics on, behaviour is unchanged (unit derived from the warehouse item).
- **Where:** Front only — `projects/construction/src/app/modules/project-job-items/job-items.form.service.ts` (flag from the existing system-configuration subscription; the two `UnitId = 0` lines; `validateForm` unit check) and `Components/job-items-pop-up/job-items-pop-up.component.html` (unit field `*ngIf`). No backend change: the backend already looks the unit up when logistics is off.
- **Test:** BETA-dbriyadhbn (logistics off), edit raw-material item 1001 (id 67526) → unit field shows «متر مكعب», save succeeds; create a raw-material item without a unit → required-fields toast. Front build gate.
- **Risk:** tenants with logistics on: none (same branch as before). Tenants with logistics off: raw-material items now need a unit, which is what the backend already demanded.
- **Rollback:** revert the two files.

User decision 2026-10-25: fix issue 3 in this CR, local only, no commit. Origin of the bug: front `443402a490d` / `ccc3c61b805`, backend `78667b6867` (Sept 2025).
