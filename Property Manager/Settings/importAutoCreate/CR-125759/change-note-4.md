# CR-125759 change note 4 — PO review 2026-10-27 (Sabreen Abubakr)

Source: ADO 125759 comment 2026-10-27 (PO review on Beta, Sabreen tenant). Path: onboard-ticket Iterate (Merge Desk ReadyForRelease, not Closed). Set recreated at C:\Hadaf_Work\worktrees\cr125759 (front, erp), offset 800.

PO points:
1. Country is not auto-created; either create it or say on the card that it is excluded and why. → keep the engineer's decision (decisions.md "Field list", spec Out of Scope, A5): country stays excluded; documented on the card (point 3) and in the template tab.
2. «أعمدة القالب» tab texts contradict the new behaviour. → fix (this change).
3. The auto-create decisions are only in code; write them on the card. → ADO comment (draft below, posted on the engineer's yes).

- **What:** i18n only (ar-EG, en-US property-manager.json). Values/Rule column of every list field says either "a missing name is created automatically" or "must exist, never created". Outdated notes fixed: PROJECTIMPORT ProjectStatusNote / CenterNote / ProjectActivityNote, PROPERTY_IMPORT Note_Model, Rule_Activity.
- **Where:** AccFlex_Cloud_Front accflex-erp\src\assets\i18n\{ar-EG,en-US}\property-manager.json. No TS / API change.
- **Test:** npm run testing (front gate), prettier; JSON parses; every changed key exists in both languages.
- **Risk:** Stage_Beta keeps the fixed property-status list (CR 125720), so on Beta property status is "must exist"; the cr125759_Stage_Beta front branch needs PROPERTY_IMPORT._Rule_Status_ in the must-exist wording when this is carried to Stage_Beta.
- **Rollback:** revert the commit.
