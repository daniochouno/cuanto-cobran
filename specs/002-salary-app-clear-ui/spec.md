# Feature Specification: Salary Consultation with a Clear, Margin-Respecting UI

**Feature Branch**: `002-salary-app-clear-ui`

**Created**: 2026-06-15

**Status**: Draft

**Input**: User description: "Build a server, which will receive an .xls file as input, parse the data and serve it through an API. Deploy locally. Then, build an app, for iOS and Android, to see the data from the API. The app will have a list showing only the most important data for each row and a details page with all the info available for each row. The UI must be clear and respect the device margins so that all information is displayed correctly."

## Clarifications

This feature restates the salary-consultation product (publish a spreadsheet → serve it
over an API → browse it on a mobile app) and adds one new, first-class requirement: the
mobile UI MUST be **clear** and MUST **respect the device's safe-area margins** so that no
information is clipped or obscured on any device. This specification treats that UI-clarity
requirement as the differentiating goal of the increment; the ingestion and consultation
behavior is restated as the surrounding scope (see Assumptions for its relationship to the
prior increment).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read every record clearly within the device's safe area (Priority: P1)

A citizen opens the app on phones with different physical shapes — a status bar, a notch or
dynamic island at the top, rounded corners, and a home indicator at the bottom. On every
screen (list and detail), all content is fully visible: nothing is hidden behind the status
bar, camera cutout, or home indicator, nothing is clipped by rounded corners, and long text
wraps or truncates legibly instead of overflowing or being cut off.

**Why this priority**: This is the explicit new goal of the increment. A consultation app
whose titles or values are hidden under the notch or run off the screen fails its core
promise of letting people *read* public salaries. It is independently valuable and testable.

**Independent Test**: With data available, open the app on devices/simulators with a notch
or dynamic island and with a home indicator, in the smallest supported screen size, and
verify every element on both the list and detail screens is fully visible and legibly laid
out within the safe area, with consistent margins.

**Acceptance Scenarios**:

1. **Given** the list screen on a device with a top cutout (notch/dynamic island), **When**
   the screen is shown, **Then** the screen title and the first record are fully visible
   below the cutout, not overlapped by it or the status bar.
2. **Given** any screen on a device with a home indicator, **When** the screen is shown,
   **Then** the bottom-most content and any actions sit above the home indicator and remain
   tappable.
3. **Given** a record whose position title is very long, **When** it is displayed in the
   list and on the detail screen, **Then** the text wraps or truncates within the screen
   margins without overflowing horizontally or overlapping other elements.
4. **Given** any screen, **When** it is shown, **Then** content is inset from the left and
   right screen edges by a consistent margin so text never touches or is clipped by the
   rounded corners.
5. **Given** the same content on iOS and Android, **When** each is shown, **Then** the
   layout applies equivalent, consistent margins and remains fully legible on both.

---

### User Story 2 - Browse the list of salary records (Priority: P2)

A citizen sees a scrollable list of public salary records. Each entry shows only the most
important data — the position title, the institution, and the salary amount — plus an
indication of when the data was last updated.

**Why this priority**: This is the primary consultation journey. It depends on published
data and is the main way people use the product.

**Independent Test**: With a known dataset available, open the app and verify the list shows
every record's key fields and the last-updated indicator, with correct loading, empty, and
error states.

**Acceptance Scenarios**:

1. **Given** available data, **When** the user opens the app, **Then** a scrollable list
   shows position title, institution, and salary amount for every record.
2. **Given** data is being fetched, **When** the list is not yet ready, **Then** a loading
   state is shown (never a blank screen).
3. **Given** no data is available, **When** the user opens the app, **Then** an explicit
   empty state is shown.
4. **Given** the data service is unreachable, **When** the user opens the app, **Then** a
   clear error state with a retry action is shown.
5. **Given** the list is shown, **When** the user looks at it, **Then** the date of the last
   data update is visible.

---

### User Story 3 - View the full detail of a record (Priority: P3)

From the list, the citizen opens a record and sees a detail screen showing all the
information available for that row, clearly labelled, plus the last-updated date.

**Why this priority**: It completes the consultation journey by exposing the full data, but
the list alone already delivers scannable value.

**Independent Test**: With data available, open any record from the list and verify the
detail screen shows every available field with correct labels and values, laid out within
the device margins.

**Acceptance Scenarios**:

1. **Given** the list is shown, **When** the user selects a record, **Then** a detail screen
   shows all available fields for that record, each clearly labelled.
2. **Given** the detail screen is open, **When** the user reviews it, **Then** every value
   matches the source data and the last-updated date is visible.
3. **Given** the detail screen is open, **When** the user goes back, **Then** the list is
   shown again at the position where they left it.

---

### User Story 4 - Publish salary data from a spreadsheet (Priority: P4)

A data manager submits an official `.xls` spreadsheet (one record per row). The system
parses and validates it and makes the valid records available for consultation through the
API.

**Why this priority**: It is a prerequisite for there being data to browse, but it is an
operator task performed rarely and outside the citizen-facing app.

**Independent Test**: Submit a sample `.xls` file and then retrieve the published records
(list and a single record) through the API, verifying the returned content matches the
spreadsheet rows and that the result reports how many rows were accepted and rejected.

**Acceptance Scenarios**:

1. **Given** a running system, **When** a well-formed `.xls` file with N valid rows is
   submitted, **Then** the system reports N records published and all N are retrievable.
2. **Given** a file with some invalid rows, **When** it is ingested, **Then** valid rows are
   published, invalid rows are excluded, and the result reports accepted/rejected counts
   with reasons.
3. **Given** a file that is not a readable `.xls`, **When** it is submitted, **Then** the
   system rejects it with a clear error and any previously published data is unchanged.
4. **Given** data is already published, **When** a new valid file is submitted, **Then** the
   new dataset fully replaces the previous one and the last-updated indicator changes.

---

### Edge Cases

- Device with a tall top cutout (dynamic island) in portrait: title and first row remain
  fully visible.
- Device rotated to landscape (if allowed): content respects left/right safe insets next to
  the cutout and is not clipped.
- Largest system font / accessibility text size: text wraps within margins without
  horizontal overflow or overlap.
- Very long position titles or institution names: wrap or truncate legibly, never run off
  screen.
- Smallest supported screen: all key information still fits and remains readable.
- A record visible in the list no longer exists when opened (data replaced): the app shows a
  clear "no longer available" message rather than a generic failure.
- Connectivity lost mid-browse: already loaded content stays visible; new requests show the
  error/retry state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST run on iOS and Android, presenting the same content, structure,
  and behavior on both.
- **FR-002**: All app screens MUST keep their content within the device safe area — below
  the status bar and any top cutout, above the home indicator, and inset from rounded
  corners — so that no information is hidden or clipped.
- **FR-003**: All screens MUST apply consistent left/right and top/bottom margins so content
  never touches the screen edges, and the margin treatment MUST be consistent across screens
  and platforms.
- **FR-004**: Text that exceeds the available width MUST wrap or truncate legibly within the
  margins; no content may overflow horizontally or overlap other elements.
- **FR-005**: Scrollable screens MUST allow the user to scroll to and fully read the first
  and last items without any item being obscured by a cutout, status bar, or home indicator.
- **FR-006**: The list screen MUST display, for every record, exactly the key fields:
  position title, institution, and salary amount.
- **FR-007**: The detail screen MUST display all fields available for the selected record,
  each clearly labelled.
- **FR-008**: Both list and detail screens MUST display the dataset's last-updated date.
- **FR-009**: Every screen that loads data MUST present explicit loading, empty, and error
  states; the error state MUST offer a retry action.
- **FR-010**: The system MUST accept an `.xls` spreadsheet, validate each row, reject rows
  missing mandatory fields (position title, institution, salary amount) or with unparseable
  values, and report total rows read, records published, and rejected rows with reasons.
- **FR-011**: A successful ingestion MUST atomically replace the entire previously published
  dataset and update the last-updated indicator; consumers MUST never see a partially
  replaced dataset.
- **FR-012**: The system MUST serve published records through the API as (a) a list of all
  records and (b) an individual record with all its fields.
- **FR-013**: Requesting a record that no longer exists MUST produce a clear "record not
  available" outcome rather than a generic failure.

### Key Entities

- **Salary Record**: One row of the source spreadsheet — a public position and its
  remuneration. Key attributes: position title, institution, salary amount; plus all other
  source columns, preserved for the detail view.
- **Dataset**: The records produced by one successful ingestion, with its last-updated
  timestamp. Exactly one dataset is published at a time.
- **Ingestion Result**: The report of one submission: rows read, records published, and
  rejected rows with reasons.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On every supported device profile (with notch/dynamic island, with home
  indicator, smallest screen), 100% of on-screen information on the list and detail screens
  is fully visible within the safe area — nothing clipped, overlapped, or hidden.
- **SC-002**: A first-time user can read a record's position, institution, and salary in the
  list, and open its full detail, without any text being cut off, on the first attempt.
- **SC-003**: The same dataset shown on iOS and Android presents identical content and field
  labels with consistent margins (100% parity on a side-by-side check).
- **SC-004**: Users see the populated list within 2 seconds of opening the app under normal
  connectivity, and opening a record's detail feels immediate (under 1 second perceived).
- **SC-005**: 100% of published records are traceable to a row of the ingested file, and the
  ingestion report accounts for every row read (published + rejected = total).
- **SC-006**: Ingesting a file of up to 10,000 rows completes and reports its result in
  under 30 seconds.

## Assumptions

- This increment builds on the existing salary-consultation system (feature
  `001-mvp-consulta-sueldos`): the ingestion pipeline and the list/detail consultation
  already exist, and this spec's primary delta is the clear, margin-respecting UI (US1 and
  FR-002…FR-005). The restated ingestion/consultation requirements describe the surrounding
  behavior the UI sits on top of.
- "Device margins" means the platform safe-area insets (status bar, top cutout/notch/dynamic
  island, home indicator) plus a consistent content margin from the screen edges, applied
  consistently on both platforms.
- "Most important data" for the list means position title, institution, and salary amount.
- The source spreadsheet has a header row with mandatory columns (position title,
  institution, salary amount); any additional columns are ingested as-is and shown only in
  the detail view.
- A single trusted operator performs ingestion locally; no authentication is required in
  this increment, and public exposure of ingestion is out of scope.
- Each new file fully supersedes the previous dataset; no history, search, or filtering in
  this increment.
- The system and app run locally / in a development environment; production deployment and
  app-store distribution are out of scope.
