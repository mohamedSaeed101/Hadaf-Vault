# CR-125808 — change note 1 (iterate, 2026-10-26)

- **What:** a Confirmed reservation whose «صالح حتى» (ExpiryDate) is before today shows the status «منتهي» / "Expired". The status is derived for display only and never stored: StatusId stays Confirmed (2). The unit stays محجوز, and Confirm-state actions (Cancel, and Convert later) stay allowed. Source: engineer's answer 2026-10-26 (deffer.md D6), same behaviour as the sale reservation.
- **Where:**
  - ERP: `RentReservationStatus` gets a display-only `Expired` entry (not seeded, not stored), or a status-name helper. `GetAllRentReservationsQuery` / `GetRentReservationByIdQuery` return StatusName «منتهي» when Confirmed and ExpiryDate < today (`IDateTime`), and keep `IsExpired`. The status filter gains «منتهي» = Confirmed AND expired; «مؤكد» = Confirmed AND not expired.
  - Front: the list status column and filter show «منتهي»; the form status shows «منتهي»; the expired warning row colour and message stay; the Cancel button stays visible for it. The list filter options come from the Defaults Statuses list.
- **Test:** handler tests (Confirmed + yesterday's expiry → «منتهي» in GetAll and GetById; the filter «منتهي» returns it and «مؤكد» does not; the Cancel of an expired one still works and releases the unit). Gates: API build, PM tests, `npm run testing`.
- **Risk:** low. Display only, no schema change, no stored status change; the Stage_Beta PR branch (`cr125808_Stage_Beta`, Front) must be re-merged after the push.
- **Rollback:** revert the iterate commit on cr125808.
