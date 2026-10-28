# Property Manager module — every screen explained for a non-business reader

As of 2026-10-22 · complements [[Property Manager module overview]] · Arabic version: [[شرح الشاشات بالتفصيل]] · the Leasing screens are in [[Leasing screens explained]] · the Sales screens in [[Sales screens explained]].

## The big idea first

Picture a company that owns or manages buildings and compounds, and sells or rents the apartments in them. Before it can sell one apartment or sign one lease, it must record in the system: which projects it owns, which units (apartments, shops, parking spots) sit inside each project, how a customer pays, which extras and services come with a unit, and which legal terms get printed in the contract. This module is the "founding ledger" that holds all of that. The contracts themselves (sale and lease) are not built in the cloud yet; everything here prepares for them.

The natural order of use: general settings → catalogs (payment terms, cost types…) → projects → units → attach amenities and furnishing to units → (later) contracts.

---

## 1. Projects (module 850)

**What it is.** A project is the building, compound or plot that contains the units, such as "Palm Compound" or "Riyadh Tower". A project can have sub-projects: the compound is the main project, each building in it is a sub-project, and the sub-project number is the parent number plus two digits.

**Why it exists.** Every unit belongs to a project, every construction cost is charged to a project, and every contract names the project. The project is the "container" the units inherit their data from.

**What you enter.** Arabic and English name, project number, parent (if any), type (residential, commercial…), status, who owns it ("company" means the company sells for its own account; "other owners" means the company is only a broker earning a commission), the location (country, city, district, street, plot number) and the plot boundaries on a map, the responsible sales department, the currency, and the cost center.

**Helper concepts.** A "cost center" is an accounting drawer that collects every expense of this one project, so one is created automatically when the project is saved. "Capitalised" is the total spent on the project and recorded as an asset (an investment) rather than an expense.

**Rules that matter.** A project with sub-projects or units cannot be deleted. The "costs" tab picks the cost types (land, construction, finishing) and shows each type's accounts.

**Example.** Register "Al Noor Tower" as a main project, then "Al Noor Tower – Building A" as a sub-project under it, then put the apartments under Building A.

## 2. Properties (module 851)

**What it is.** A property here means one unit that is sold or rented: an apartment, shop, office, parking spot, storeroom. (The system word is "property", not "unit".)

**Why it exists.** The unit is the subject of every reservation and every contract. Without it there is nothing to sell.

**What you enter.** The leaf sub-project it sits in (required; from it the unit inherits ownership, geography, sales department, cost center and currency), the unit code, type, status (available, reserved, sold…), model (the design), floor, areas (built, external, total), view, sale price, and the investment type (for sale or for rent). A unit can be a "parent" of smaller units: the building is a parent unit, the apartments sit under it, and a garage hangs off the apartment.

**Planned extra tabs.** "Cost" (the unit's share of the project's costs), "Fixed asset" (turning a company-owned unit into an accounting asset; land is not depreciated, the building is depreciated over 40 years), "Owners" (if several people own the unit, their shares are recorded and must total 100%), "Installment markup" (a price increase when sold on installments), and "Rent prices".

**Missing today.** Geography is sent as fixed values, rent prices are a title with no table, the type is read from the project-types table.

**Example.** Apartment "A-0305" in Building A, third floor, 120 m², priced 900,000, investment type: sale.

## 3. Import projects (module 944)

**What it is.** Instead of typing hundreds of projects, you download a template Excel file (24 columns), fill it, and upload it; the system checks every row, shows errors row by row, and saves only the valid rows.

**Why.** For new customers who already have their data in spreadsheets.

**Rules.** Same rules as the Projects screen (name and number must be unique). Add-only; it never updates an existing project. It creates a cost center per project automatically. It keeps a log of every import with a downloadable error file. A parent must already exist or appear in an earlier row of the same file.

## 4. Import properties (module 945)

**What it is.** The same screen for units (19 columns). You put the sub-project number on every row, and the unit inherits its data automatically on the server.

**Rules.** The project must be a leaf (no sub-projects under it). The unit type must be one of the investment types allowed on the project. A parent unit must be in the same project. Meter numbers are whole numbers only. The rent price column is deferred to a later CR.

## 5. Bulk generation (module 946)

**What it is.** A tool that creates many units in one go from a "pattern": you pick the sub-project, building number, number of floors, units per floor, and a code pattern such as `{P}-{B}-{F}{U}`; the system generates a grid of all the units for you to review and edit, then save. It can add a linked garage per unit automatically, and step the price up by floor.

**Rules.** Up to 500 rows per save, and the save is all-or-nothing. A duplicate code is skipped with a message. The garage is saved as a child unit of the apartment.

**Example.** A building of 10 floors × 4 apartments = 40 units + 40 garages in one minute.

## 6. Amenities (module 854)

**What it is.** The extras sold or rented with a unit: a parking spot, a storeroom, a pool or club subscription. Each amenity has a price, a currency and a payment term (how it is paid), and may have a "premium subscription" at another price. An amenity serves a whole project or one specific unit.

**Why.** So the amenity can be added as a line on the sale or lease contract with its price and payment method.

**Amenity classifications (module 855).** A small window opened from the "+" button to define amenity categories (parking, leisure…).

**Known gaps.** "Serves" sends text while the server expects a number, the payment term is not filtered to the "amenities" type, and there is no duplicate-name check.

## 7. Furnishing

**What it is.** The list of furniture and appliances handed over with a rented unit (fridge, air conditioner, washing machine) with a quantity, a condition and an annual rent per item per unit.

**Why.** When a lease is signed, the furnishing lines are copied into the contract and their rent is added to the installments (annual rent × installment months ÷ 12). At move-in and move-out each item is checked: present / missing / damaged, and a deduction from the deposit is suggested for damage.

**Important note.** Furnishing is not an accounting "fixed asset" (decision of 11 October); it is information for the contract and the handover only. Its revenue goes to the rent revenue account 4120.

## 8. Service items (module 947)

**What it is.** A catalog of the recurring services the company provides to tenants: cleaning, security, periodic maintenance. Each service has a code, a name, a default annual value, and whether it is subject to VAT.

**Why.** On a lease, services are picked and their annual value is spread over the installments. Example: a 3,600-a-year service on a quarterly lease adds 900 to each installment.

**Status.** The catalog is built; its link to the lease is deferred because the lease does not exist in the cloud yet.

## 9. Project expense types (module 948)

**What it is.** The list of "kinds" of spending on a project: land, construction, finishing, permits. Each type has two accounting accounts: an asset account (where spending accumulates as an investment during construction) and a cost account (charged with the unit's share when the unit is handed to the buyer). A "land" flag exists because land is never depreciated.

**Why.** So the system knows what each project cost, what each unit's share is, and how much the company earned on its sale.

**The journal in plain words.** When a contractor's invoice is paid: debit "projects under development" 1311, credit "suppliers" 2230. When a sold unit is handed over: debit "cost of construction of properties sold" 5112, credit "work in progress" 1312 with the unit's share.

**Rules.** The asset account must be cost-center-linked and unique, and cannot be changed once it carries movement. A type used in a project cannot be deleted.

## 10. Contract clauses

**What it is.** A library of the legal terms printed in the contract and signed by both parties: "the tenant undertakes to…", "in case of delay…". Each clause is a text, a type (sale, residential lease, commercial lease), and a lease clause may point to a "violation policy".

**What it is not.** A clause is not an installment or an amount; it generates no invoice and no journal. Amounts come from the installment plan, payment terms and general settings.

**Rules.** The contract stores clause ids only, so editing a clause's text changes how old contracts print (open question: snapshot the text at approval?). A used clause cannot be deleted.

## 11. Print templates

**What it is.** Templates of the full contract text (as printed and signed) with variables filled automatically: {contract number}, {seller}, {buyers}, {property}, {price}, {annual rent}… Each contract type (preliminary sale, final sale, lease) has a company default template, and a project can have its own.

**How the template is chosen at print time.** The project's template if one exists, otherwise the general default of the same type.

**Detail.** If the unit belongs to another owner, the seller prints as "the company on behalf of the owner".

## 12. Payment terms (module 856)

**What it is.** The definition of the "kinds of amounts" a customer pays and how: contract, deposit, utilities, amenities, rent, services, penalty, advance. Each term has a fixed value or a percentage of the contract value, a recurrence (monthly, quarterly…), a grace period before a payment counts as late, and a late penalty.

**Why.** The lease contract and amenities use them to generate the payment schedule. Example: a "rent" term, quarterly, 5 days grace, 2% penalty.

**Known gaps.** The grace unit is wrongly saved from the recurrence unit, the "≤100" check is on the value instead of the percentage, and delete is blocked only for the penalty use.

## 13. Installment plans

**What it is.** A library of ready-made "installment systems" the seller picks on a quotation, reservation or sale contract; the system then generates the installment schedule automatically: down-payment percentage, duration, frequency, rounding, maintenance deposit and late penalty.

**Why.** So the schedule is not calculated by hand for every customer. The plan is a template; installments are copied into the contract at approval and do not change if the plan changes later.

**Details for the accountant.** The price comes from the unit's net price on the document, not from the plan. The reservation deposit is deducted from the down payment. The maintenance deposit goes to account 2340, not revenue. The penalty goes to account 4190 when invoiced. Leases do not use plans; they use payment terms.

## 14. General settings

**What it is.** One screen holding the company settings for the whole module, a single record applied immediately to every screen:

- **General:** company name, country (decides the currency, the VAT rate and whether e-invoicing is mandatory), Hijri date display, brokerage and property-management licences (printed on contracts).
- **Accounts:** four mandatory accounts telling the system where to record tenant deposits (2320), owner dues (2215), sale-contract receivables (1215) and property stock (1310); the 26 October decision added "forfeited reservation deposits revenue" (4195), which receives a reservation deposit when it is forfeited.
- **Defaults:** reservation validity (14 days), deposit percentage (5%), grace days (5), default rent frequency, the installment-edit limit (10%) above which an approval request is required, and the default ownership-transfer fee (5,000; shown in the sale contract's transfer-of-ownership window, CR 126102).
- **Late payment and default:** whether a fine, a charity donation or nothing applies (by country), the legal annual cap, when it starts, and the default stages (after how many days which action is taken).
- **Taxes:** the state's first-home VAT coverage cap, and withholding on broker commissions.
- **Revenue recognition:** whether a sale is recognised at handover or by completion percentage, and whether journals are automatic.
- **Government integrations:** the Ejar platform and e-invoicing.

**Why it matters.** Without this screen no contract can know its currency, its tax or the account it posts to.

## 15. Users and permissions (module 627)

**What it is.** The same permissions screen that already exists in AccFlex (Logistics settings › Users and permissions) with two new permission groups added: "Real-estate marketing" and "Real-estate settings". For each user you set which screens they see and what they may do (add, edit, delete), plus extra permissions such as "change an installment's due date" on the installments follow-up screen (sales and leasing, each on its own).

**Note.** Permissions are per user directly; there are no "roles" (the roles request 123425 is separate).

## 16. Violation policies (module 954)

**What it is.** A catalog of fines for tenant violations: noise, littering, damage, breaking lease terms. Each policy has a type, an amount for the first time, the second time, and the third time or later, a "repeat window" in months (how long violations count as repeats), and an apply mode: automatic or after confirmation.

**What it is not.** It is not the late-payment penalty; that lives inside the installment plan and the payment term.

**Where it is used.** A lease clause points to it, and it is picked in the "violation log" when a violation is recorded (the log is not built yet).

**Example.** Policy "noise": first 200, second 500, third or later 1,000, window 12 months.

---

## Words you will meet often

| Word | Plain meaning |
| --- | --- |
| Sub-project / leaf | The lowest level in the project tree, the only one units can sit under |
| Cost center | An accounting "drawer" that collects the expenses of one thing (a project) so you know what it cost |
| Asset account / cost account | Asset = what you own, recorded as an investment; cost = what was spent to make a sale |
| Capitalised | The total spent on a project and recorded as an asset, not an expense |
| Payment term | A kind of amount and how it is paid (value or percentage, recurrence, grace, penalty) |
| Installment plan | A ready template that generates a sale's installment schedule |
| Revenue recognition | When a sale counts as income in the books: at handover or by completion percentage |
| Merge Desk / CR | The release-management tool, and the change request each screen is built through |
