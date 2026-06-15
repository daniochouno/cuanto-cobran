# Feature Specification: MVP Consulta de Sueldos — Salary Data Publication & Browsing

**Feature Branch**: `001-mvp-consulta-sueldos`

**Created**: 2026-06-12

**Status**: Draft

**Input**: User description: "Build a server in Vapor, which will receive an .xls file as input, parse the data and serve it through an API. Deploy locally. Then, build a Kotlin Multiplatform app with Jetpack Compose, for iOS and Android, to see the data from the API. The app will have a list showing only the most important data for each row and a details page with all the info available for each row."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publish salary data from a spreadsheet (Priority: P1)

A data manager has an official spreadsheet (.xlsx) containing public salary records (one
row per public position). They submit the file to the system, which parses and validates
it and makes every valid record available for consultation. From that moment, anyone
querying the published data sees the content of that spreadsheet.

**Why this priority**: Nothing else in the product works without published data. This
story alone produces a verifiable, queryable dataset and is the foundation every other
story consumes.

**Independent Test**: Can be fully tested without the mobile app by submitting a sample
.xlsx file and then retrieving the published records (list and individual record) through
the system's consultation interface, verifying the returned content matches the
spreadsheet rows.

**Acceptance Scenarios**:

1. **Given** a running system with no published data, **When** the data manager submits a
   well-formed .xlsx file with N valid rows, **Then** the system confirms the ingestion,
   reports N records published, and all N records are retrievable.
2. **Given** a submitted file where some rows are missing mandatory values, **When**
   ingestion completes, **Then** valid rows are published, invalid rows are excluded, and
   the ingestion result reports how many rows were accepted and how many were rejected
   (with row numbers and reasons).
3. **Given** a file that is not a readable .xlsx spreadsheet, **When** the data manager
   submits it, **Then** the system rejects the whole submission with a clear error and
   the previously published dataset (if any) remains unchanged.
4. **Given** a dataset already published, **When** the data manager submits a new valid
   file, **Then** the new dataset fully replaces the previous one and the data freshness
   date is updated.

---

### User Story 2 - Browse the list of salary records (Priority: P2)

A citizen opens the mobile app on their phone (iPhone or Android) and sees a scrollable
list of public salary records. Each list entry shows only the most important data for
that record — the position title, the institution it belongs to, and the salary amount —
so the user can scan and compare records quickly. The app also shows when the data was
last updated.

**Why this priority**: This is the core citizen-facing value of the product: consulting
public salaries at a glance. It depends on published data (US1) but delivers the primary
user journey.

**Independent Test**: With a known dataset published, open the app on each platform and
verify the list displays every record with the expected key fields, in a usable
scrollable form, including the data freshness indicator, plus correct loading, empty, and
error states.

**Acceptance Scenarios**:

1. **Given** a published dataset, **When** the user opens the app, **Then** a list of all
   records appears showing position title, institution, and salary amount for each entry.
2. **Given** the app is fetching data, **When** the list is not yet available, **Then** a
   loading state is shown (never a blank screen).
3. **Given** no dataset has been published, **When** the user opens the app, **Then** an
   explicit empty state explains that no data is available yet.
4. **Given** the data service is unreachable, **When** the user opens the app, **Then** a
   clear error state is shown with the option to retry.
5. **Given** the list is displayed, **When** the user looks at the screen, **Then** the
   date of the last data update is visible.

---

### User Story 3 - View the full detail of a record (Priority: P3)

From the list, the citizen taps a record and opens a detail page showing all the
information available for that row of the original spreadsheet — every field that was
ingested, clearly labelled — together with the data freshness date.

**Why this priority**: It completes the consultation journey by exposing the full
underlying data and its traceability, but the list alone already delivers scannable
value.

**Independent Test**: With a known dataset published, tap any list entry on each platform
and verify the detail page shows every ingested field for that record with correct
values and labels.

**Acceptance Scenarios**:

1. **Given** the list is displayed, **When** the user selects a record, **Then** a detail
   page opens showing all available fields for that record.
2. **Given** the detail page is open, **When** the user reviews it, **Then** every value
   shown matches the corresponding row of the ingested spreadsheet and the last-update
   date is visible.
3. **Given** the detail page is open, **When** the user navigates back, **Then** the list
   is shown again in the position where they left it.

---

### Edge Cases

- Empty spreadsheet (headers only, zero data rows): ingestion succeeds with 0 records
  published and the consultation surfaces show the empty state.
- A file with duplicate rows: duplicates are published as distinct records (the system
  reflects the source faithfully); flagged in the ingestion report.
- Very large file (tens of thousands of rows): ingestion completes within the defined
  time budget or fails with a clear message — never leaves a partially published dataset.
- Fields with unexpected formats (e.g., salary not numeric, malformed dates): the row is
  rejected and reported with its row number and reason.
- A new dataset is published while a user is browsing: the user continues to see
  consistent data within their session; refreshed views show the new dataset.
- A record visible in the list no longer exists when its detail is requested (dataset
  replaced in between): the app shows a clear "no longer available" error and returns the
  user to the refreshed list.
- Device loses connectivity mid-browse: already loaded content stays visible; new
  requests show the error/retry state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST accept submission of a spreadsheet file in .xlsx format
  containing public salary records, one record per row with a header row.
- **FR-002**: System MUST validate each row during ingestion; rows missing mandatory
  fields (position title, institution, salary amount) or containing unparseable values
  MUST be rejected without blocking the ingestion of valid rows.
- **FR-003**: System MUST return an ingestion result reporting total rows read, records
  published, and rejected rows with row numbers and rejection reasons.
- **FR-004**: System MUST reject files that are not readable .xlsx spreadsheets with a
  clear error, leaving any previously published dataset untouched.
- **FR-005**: Each successful ingestion MUST atomically replace the entire previously
  published dataset; consumers MUST never observe a partially replaced dataset.
- **FR-006**: System MUST record the date and time of each successful ingestion and
  expose it as the dataset's last-updated indicator.
- **FR-007**: System MUST make published records available for consultation as (a) a
  list of all records and (b) an individual record with all its fields.
- **FR-008**: The mobile app MUST run on iOS and Android offering the same content,
  structure, and behavior on both platforms.
- **FR-009**: The app's list screen MUST display, for every published record, exactly
  the key fields: position title, institution, and salary amount.
- **FR-010**: The app's detail page MUST display all fields available for the selected
  record, clearly labelled.
- **FR-011**: Both list and detail screens MUST display the dataset's last-updated date.
- **FR-012**: Every screen that loads data MUST present explicit loading, empty, and
  error states; error states MUST offer a retry action.
- **FR-013**: Requesting the detail of a record that no longer exists MUST produce a
  clear "record not available" outcome rather than a generic failure.

### Key Entities

- **Salary Record**: One row of the ingested spreadsheet — a public position and its
  remuneration. Key attributes: position title, institution, salary amount; plus all
  other columns present in the source file, preserved for the detail view.
- **Institution**: The public body a record belongs to (an attribute of the record in
  this increment, not an independently managed entity).
- **Dataset**: The set of records produced by one successful ingestion, with its
  publication (last-updated) timestamp. Exactly one dataset is published at a time.
- **Ingestion Result**: The outcome report of one submission: rows read, records
  published, rejected rows with reasons.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A data manager can go from having a valid .xlsx file to seeing its records
  publicly consultable in under 5 minutes, in a single submission step.
- **SC-002**: Ingestion of a file with up to 10,000 rows completes and reports its result
  in under 30 seconds.
- **SC-003**: 100% of published records are traceable to a row of the ingested file, and
  the ingestion report accounts for every row read (published + rejected = total).
- **SC-004**: On a mid-range phone, users see the populated list within 2 seconds of
  opening the app under normal connectivity.
- **SC-005**: Opening a record's detail from the list feels immediate — under 1 second
  perceived latency.
- **SC-006**: A user with no prior instruction can find a specific record's full detail
  (scrolling the list and opening it) on the first attempt, on either platform.
- **SC-007**: The same dataset rendered on iOS and Android shows identical content and
  field labels (100% parity on a side-by-side check).

## Assumptions

- The source spreadsheet comes from an official public source with a known, stable
  column layout: first row contains headers; mandatory columns are position title,
  institution, and salary amount; any additional columns are ingested as-is and shown
  only in the detail view.
- Salary amounts are annual gross figures in euros; data is in Spanish and shown as-is
  (no localization in this increment).
- "Most important data" for the list means position title, institution, and salary
  amount, matching the product's documented MVP intent.
- A single trusted data manager performs ingestion in a local/controlled environment;
  submission requires no authentication in this increment. Public exposure of the
  ingestion capability is out of scope and would require access control first.
- Replace-on-ingest semantics: each new file fully supersedes the previous dataset; no
  history, merging, or versioning in this increment.
- The system and app run locally / in a development environment; production deployment,
  distribution through app stores, search, filtering, and comparisons are out of scope
  for this increment (search and filters are planned as later increments).
- Expected dataset size for the MVP is in the order of hundreds to a few thousand
  records; the 10,000-row budget in SC-002 is the upper bound.
