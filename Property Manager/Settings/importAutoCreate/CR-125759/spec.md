# CR-125759 spec: one-step import and auto-created lookups

Sources: [[facts]], [[decisions]], [[grill-context]]. Path taken: the agent grilled itself against the code (explorer scout) and asked the engineer only what the code could not answer (Q1–Q8).

## Problem Statement
Import Projects (CR-125486) and Import Properties (CR-125487) need three steps: upload, verify, import. A row whose type, status, view, activity, model, governorate, city or center is not yet defined fails, so the user must leave the screen, create the value on its own screen, and upload again.

## Solution
Uploading a file validates and imports in one call. A value in one of the auto-create columns that the tenant lacks is created during the import and used for the row. The result shows what was imported, the skipped rows with their errors, and a «تم إنشاؤه» section listing every record created, grouped by field.

## User Stories
1. As a property manager, I upload a projects file and its valid rows are saved at once, without a separate verify step.
2. As a property manager, when my file names a city that is not defined, it is created under the row's governorate and my project uses it.
3. As a property manager, after the import I can see which types, statuses, cities and other records were created, so I can review them.
4. As a property manager, I still see every skipped row with its errors and can download the error file.

## Implementation Decisions
- **Auto-create columns.** Projects: type (6), status (8), governorate (12), city (13), center (14), view (22), activity (23). Properties: type (6), activity (8), status (9), model (12), view (17). Every other lookup column keeps its current "not found" error. Country is never created.
- **Tables.** Property type / activity / status / view use the same Pm_ tables as the project ones (Pm_ProjectType, Pm_ProjectActivities, Pm_ProjectStatus, Pm_ProjectView); property model is Pm_PropertyModel. Geography is SharedKernel ACFX_Governorate / ACFX_City / ACFX_Center.
- **Matching (Q7).** Both imports match with the projects `Normalize` (trim, case, alef forms, ة/ه, ى/ي, tashkeel), moved to one shared helper. Inactive records are matched too. One new record per distinct normalized value per file (per parent for geography).
- **Validation never writes.** The validator returns, per row, the values it would create; it builds transient entities so the domain `Create` checks still run. Only the Import command saves them.
- **Creation (Q5).** Only for rows that are valid apart from the missing value. Inside the import's existing transaction, before the rows: Pm_ lookups first, then governorate → city → center. Any failure rolls back everything, including the created records.
- **Values of a new record (Q3, Q4).** Name and second-language name = the cell text. Pm_ lookups: Serial = max(Serial) in the table + 1, then +1 per further new record; IsActive = true. Governorate under the row's country, city under its governorate (existing or new), center under its city (existing or new). Geography is matched only under the row's parent; a name that exists only under another parent is created under the row's parent, replacing today's not-in-parent row errors (decisions Q9).
- **City factory.** City has no single-record create; add `City.Create(name, nameSecond, Maybe<Governorate>)` beside `Governorate.CreateGovernorate` in SharedKernel.Logic.
- **Transaction.** The project import already shares one connection between the PropertyManager and GeneralLedger contexts (`PropertyManagerTransaction`); the SharedKernel context joins it the same way. The property import creates only Pm_ records, inside its existing PropertyManager transaction.
- **Permission (Q2).** The import screen's Add permission (944 / 945) is enough; no extra check.
- **Contract.** `ImportProjectsResultDto` and `PropertyImportResultDto` gain `Rows` (each row's line, valid flag, errors) and `CreatedLookups` (field + names). Verify endpoints stay for compatibility; the front stops calling them. The `property-manager` client is re-synced (`api:sync`).
- **Front (Q1, Q6, Q8).** Choosing the file reads it and calls Import directly: no review-then-import step and no confirmation dialog. The parent cost center dropdown (projects) stays above the upload; if rows need a cost center and none is chosen, the server's existing error is shown and nothing is saved. After the import: the result message, the «تم إنشاؤه» section, and the skipped rows with errors plus the error-file download.

## Acceptance
- A1 Uploading a valid projects file saves the projects with no other click; same for properties.
- A2 A file with 4 valid and 2 invalid rows imports 4, skips 2, and shows both skipped rows with their errors; the error file downloads.
- A3 A project row with an unknown city under an existing governorate creates the city under that governorate, and the project points to it.
- A4 A project row with an unknown governorate, city and center creates all three in a chain under the row's existing country.
- A5 An unknown country is still a row error; nothing is created for that row.
- A6 The same unknown value on several rows (spelling variants that normalize the same) creates one record.
- A7 A new type / status / activity / view / model gets Serial = previous max + 1 and is active, with the cell text in both names.
- A8 A row skipped for another error creates nothing.
- A9 A property row with an unknown property model creates it; an unknown status / view / activity on a property creates it in the shared project table.
- A10 The result shows «تم إنشاؤه» grouped by field with the created names; nothing created → the section is hidden.
- A11 If the import fails at save, nothing is kept: no rows and no created records.
- A13 A city name that exists only under another governorate is created under the row's governorate.
- A12 Projects: rows needing a cost center with no parent chosen → nothing is imported and the message says so.

## Testing Decisions
- Unit tests (PropertyManager test project, Moq + in-memory doubles as in CR-125486): shared Normalize; each validator turns a missing auto-create value into a valid row with a pending record; dedup across rows; geography chain; skipped rows create nothing; Serial max + 1; import result carries rows and created lookups.
- End to end on Sabreen (local PM API, offset 1400): A1–A12 through the screens.

## Out of Scope
- Auto-creating country, ownership, investment type, cost distribution, sales organization or currency.
- A permission check per lookup screen (Q2).
- Recording created records in the import log tables.
- Removing the Verify endpoints.

## Further Notes
- Related: CR-125486 (projects import), CR-125487 (properties import), both Closed.
- Geography records are tenant-wide: they appear in every module's dropdowns.
