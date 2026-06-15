---

description: "Task list for MVP Consulta de Sueldos"
---

# Tasks: MVP Consulta de Sueldos — Salary Data Publication & Browsing

**Input**: Design documents from `/specs/001-mvp-consulta-sueldos/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/openapi.yaml, quickstart.md

**Tests**: MANDATORY — Constitution Principle II (Test-Driven Development, NON-NEGOTIABLE). Every component has test tasks written and failing BEFORE its implementation.

**Organization**: Tasks are grouped by user story. US1 (P1) is the full backend (ingestion + consultation API); US2 (P2) and US3 (P3) are the mobile client screens that consume the API.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1, US2, US3 (no label for Setup/Foundational/Polish)
- All paths are relative to the repository root

## Path Conventions

- **Backend**: `backend/vapor-server/Sources/App/`, tests in `backend/vapor-server/Tests/AppTests/`
- **Client shared (domain/data/state)**: `app/shared/src/`
- **Client UI**: `app/composeApp/src/`
- Structure per [plan.md](plan.md) "Project Structure"

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize both parts of the monorepo and the toolchains the constitution requires.

- [ ] T001 Create the monorepo directory skeleton (`backend/vapor-server/`, `app/shared/`, `app/composeApp/`, `app/iosApp/`) per plan.md Project Structure, and place a `.gitkeep`/placeholder where needed
- [ ] T002 Initialize the Vapor backend in `backend/vapor-server/Package.swift` — Swift 6.1, `swiftLanguageMode(.v6)` (complete concurrency → warnings are errors), dependencies: Vapor 4, Fluent, FluentPostgresDriver; declare `App` executable target and `AppTests` test target
- [ ] T003 [P] Initialize the KMP app in `app/settings.gradle.kts`, `app/build.gradle.kts`, `app/shared/build.gradle.kts`, `app/composeApp/build.gradle.kts` — Kotlin 2.1.x, Compose Multiplatform 1.8.x, targets android + iosX64/iosArm64/iosSimulatorArm64, kotlinx.serialization + kotlinx.coroutines; create `app/iosApp/` Xcode wrapper project
- [ ] T004 [P] Configure backend code style and quality gate in `backend/vapor-server/.swift-format` and CI build flags (treat warnings as errors)
- [ ] T005 [P] Configure client code style and quality gate in `app/` (ktlint or detekt config + `allWarningsAsErrors = true` in the Kotlin compiler options)
- [ ] T006 [P] Configure the backend test target with XCTVapor and a dedicated test database (`cuanto_cobran_test`) bootstrap helper in `backend/vapor-server/Tests/AppTests/TestSupport/AppTestCase.swift`
- [ ] T007 [P] Configure the client test setup in `app/shared/src/commonTest/kotlin/TestSupport.kt` (kotlin.test, a `FakeHttpClient`, fixture-loading helper)
- [ ] T008 [P] Copy the canonical contract fixtures derived from `contracts/openapi.yaml` (a `salaries_list.json`, a `salary_detail.json`, an `ingestion_report.json`, and an `api_error.json`) into both `backend/vapor-server/Tests/AppTests/Fixtures/` and `app/shared/src/commonTest/resources/fixtures/` so both stacks are pinned to the same contract

**Checkpoint**: Both projects build empty, both test suites run (and are red/empty), shared fixtures in place.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting infrastructure each user story builds on. No story work starts until this is complete.

**⚠️ CRITICAL**: No user story phase can begin until this phase is done.

### Backend foundation

- [ ] T009 Implement database configuration and migration registration in `backend/vapor-server/Sources/App/configure.swift` (read `DATABASE_URL`, default `postgres://localhost:5432/cuanto_cobran`; register Fluent + Postgres; register migrations; register routes hook)
- [ ] T010 [P] Implement the `ApiError` payload type and reason codes in `backend/vapor-server/Sources/App/Support/ApiError.swift` (codes per contracts/openapi.yaml: `RECORD_NOT_AVAILABLE`, `FILE_NOT_FOUND`, `INVALID_FILE`, `MISSING_REQUIRED_COLUMNS`, `INGESTION_IN_PROGRESS`, `INTERNAL_ERROR`) with Spanish messages
- [ ] T011 [P] Implement an error-mapping middleware in `backend/vapor-server/Sources/App/Support/ErrorMiddleware+Api.swift` that renders thrown errors as `ApiError` JSON with the correct HTTP status

### Client foundation

- [ ] T012 [P] Define the project-owned `HttpClient` interface and `HttpResponse`/`HttpError` types in `app/shared/src/commonMain/kotlin/data/HttpClient.kt` (suspend GET/POST, timeout, error mapping)
- [ ] T013 [P] Implement the Android `actual` HttpClient (HttpURLConnection on `Dispatchers.IO`) in `app/shared/src/androidMain/kotlin/data/HttpClient.android.kt`
- [ ] T014 [P] Implement the iOS `actual` HttpClient (URLSession) in `app/shared/src/iosMain/kotlin/data/HttpClient.ios.kt`
- [ ] T015 [P] Implement `ApiConfig` base-URL resolution in `app/shared/src/commonMain/kotlin/data/ApiConfig.kt` with `expect`/`actual` platform default (Android `http://10.0.2.2:8080`, iOS `http://127.0.0.1:8080`)
- [ ] T016 [P] Implement the centralized Spanish strings object in `app/composeApp/src/commonMain/kotlin/ui/strings/Strings.kt` (FR labels: cargo, organismo, retribución, "Datos actualizados a…", loading/empty/error/Reintentar copy)
- [ ] T017 [P] Implement the design-system theme in `app/composeApp/src/commonMain/kotlin/ui/theme/Theme.kt` (typography, spacing, color, shared component tokens — Principle III)
- [ ] T018 [P] Implement the Spanish number/currency formatter as `expect`/`actual` in `app/shared/src/commonMain/kotlin/util/CurrencyFormatter.kt` (+ `.android.kt` `java.text.NumberFormat` and `.ios.kt` `NSNumberFormatter`, `Locale("es","ES")`, e.g. `70.508,52 €`)
- [ ] T019 [P] Define the generic `UiState` sealed model (`Loading`/`Content`/`Empty`/`Error`) in `app/shared/src/commonMain/kotlin/state/UiState.kt`
- [ ] T020 Implement the custom navigation scaffold (sealed `Screen`, back-stack holder preserving list scroll position) in `app/composeApp/src/commonMain/kotlin/ui/App.kt`

**Checkpoint**: Backend connects to Postgres and renders typed errors; client has networking, theme, strings, formatter, state model, and navigation shell. User stories can now begin.

---

## Phase 3: User Story 1 - Publish salary data from a spreadsheet (Priority: P1) 🎯 MVP

**Goal**: Ingest `Retribuciones.xlsx` into PostgreSQL with per-row validation and atomic dataset replacement, then serve the published records (list + detail) over the API.

**Independent Test**: With the server running and Postgres available, `POST /api/v1/admin/ingest` returns a report where `recordsPublished + rejectedRows.length == rowsRead`; then `GET /api/v1/salaries` lists the records and `GET /api/v1/salaries/{id}` returns one record's full fields; an unknown id returns 404 `RECORD_NOT_AVAILABLE`.

### Tests for User Story 1 (MANDATORY - TDD per Constitution Principle II) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation.**

- [ ] T021 [P] [US1] XLSXReader unit tests against committed fixture `.xlsx` files in `backend/vapor-server/Tests/AppTests/Unit/XLSXReaderTests.swift` (ZIP central-directory parsing, RFC 1951 inflate against known vectors, shared-string vs inline vs number cells, cell-reference column mapping with gaps, malformed-archive error)
- [ ] T022 [P] [US1] ColumnMapper unit tests in `backend/vapor-server/Tests/AppTests/Unit/ColumnMapperTests.swift` (header normalization, alias matching for cargo/organismo/retribución, missing-required-column → `MISSING_REQUIRED_COLUMNS`, extra columns preserved in order)
- [ ] T023 [P] [US1] RowValidator unit tests in `backend/vapor-server/Tests/AppTests/Unit/RowValidatorTests.swift` (mandatory-field presence, Spanish numeric parsing `70.508,52`, `MISSING_MANDATORY_FIELD` / `INVALID_SALARY_AMOUNT`, duplicate-row flagging)
- [ ] T024 [US1] IngestionService integration test in `backend/vapor-server/Tests/AppTests/Integration/IngestionServiceTests.swift` (atomic replace: second ingest supersedes the first; partial failure leaves prior dataset intact; report counts satisfy `published + rejected == rowsRead`)
- [ ] T025 [P] [US1] Contract + integration test for `POST /api/v1/admin/ingest` in `backend/vapor-server/Tests/AppTests/Contract/IngestEndpointTests.swift` (200 report shape vs fixture; 404 `FILE_NOT_FOUND`; 409 `INGESTION_IN_PROGRESS`; 422 `INVALID_FILE` leaves dataset unchanged)
- [ ] T026 [P] [US1] Contract + integration test for `GET /api/v1/salaries` in `backend/vapor-server/Tests/AppTests/Contract/ListEndpointTests.swift` (populated list shape vs `salaries_list.json`; empty dataset → `dataset: null, items: []`)
- [ ] T027 [P] [US1] Contract + integration test for `GET /api/v1/salaries/{id}` in `backend/vapor-server/Tests/AppTests/Contract/DetailEndpointTests.swift` (full record shape vs `salary_detail.json`; unknown id → 404 `RECORD_NOT_AVAILABLE`)

### Implementation for User Story 1

- [ ] T028 [P] [US1] Implement the ZIP container reader in `backend/vapor-server/Sources/App/XLSXReader/ZIPArchive.swift` (End of Central Directory + central directory + local file headers; extract entry bytes for stored method 0 and deflated method 8)
- [ ] T029 [P] [US1] Implement the custom RFC 1951 DEFLATE inflate decoder (fixed + dynamic Huffman) in `backend/vapor-server/Sources/App/XLSXReader/Inflate.swift`
- [ ] T030 [US1] Implement SpreadsheetML reading (sharedStrings.xml + first worksheet sheetData via Foundation `XMLParser`; resolve shared/inline/number/boolean cells honoring the `r` cell reference) in `backend/vapor-server/Sources/App/XLSXReader/SpreadsheetML.swift` (depends on T028, T029)
- [ ] T031 [US1] Implement the public `XLSXWorkbook` API returning the first sheet as rows of `XLSXCellValue` plus the header row in `backend/vapor-server/Sources/App/XLSXReader/XLSXWorkbook.swift` (depends on T028, T029, T030)

> Note: the `IngestionService` (T039) consumes `XLSXWorkbook` rows; `ColumnMapper`/`RowValidator` operate on the parsed rows and are format-agnostic.

- [ ] T032 [P] [US1] Implement the `Dataset` Fluent model in `backend/vapor-server/Sources/App/Models/Dataset.swift` (id, ingested_at, status, source_file, rows_read)
- [ ] T033 [P] [US1] Implement the `SalaryRecord` Fluent model in `backend/vapor-server/Sources/App/Models/SalaryRecord.swift` (FK dataset_id, position_title, institution, salary_amount numeric(12,2), source_row_number, extra_fields JSONB ordered label/value array)
- [ ] T034 [US1] Implement migrations in `backend/vapor-server/Sources/App/Migrations/CreateDatasetAndSalaryRecord.swift` (tables, FK cascade, partial unique index on `status = 'active'`, index on `dataset_id`) and register in configure.swift
- [ ] T035 [P] [US1] Implement the `ColumnMapper` (header normalization + alias sets per research.md R10) in `backend/vapor-server/Sources/App/Ingestion/ColumnMapper.swift`
- [ ] T036 [P] [US1] Implement the `RowValidator` (mandatory fields, Spanish number parsing) in `backend/vapor-server/Sources/App/Ingestion/RowValidator.swift`
- [ ] T037 [P] [US1] Implement the `IngestionReport` DTO in `backend/vapor-server/Sources/App/Ingestion/IngestionReport.swift`
- [ ] T038 [US1] Implement the protocol-wrapped repository in `backend/vapor-server/Sources/App/Repositories/SalaryRepository.swift` (active dataset query, list, find-by-id, transactional replace) so domain code never imports Fluent directly
- [ ] T039 [US1] Implement `IngestionService` in `backend/vapor-server/Sources/App/Ingestion/IngestionService.swift` — parse whole file → validate rows → single transaction inserting new active dataset + records and superseding the previous; `actor`-guarded in-progress flag (409 on concurrent); post-commit cleanup of superseded datasets (depends on T031, T034, T035, T036, T037, T038)
- [ ] T040 [US1] Implement `SalariesController` (`GET /api/v1/salaries`, `GET /api/v1/salaries/{id}` with 404 mapping) in `backend/vapor-server/Sources/App/Controllers/SalariesController.swift` (depends on T038)
- [ ] T041 [US1] Implement `AdminController` (`POST /api/v1/admin/ingest`, reads `INGEST_FILE_PATH` default repo-root `Retribuciones.xlsx`, 404 when missing) in `backend/vapor-server/Sources/App/Controllers/AdminController.swift` (depends on T039)
- [ ] T042 [US1] Implement `GET /api/v1/health` and register all routes in `backend/vapor-server/Sources/App/routes.swift` (depends on T040, T041)

**Checkpoint**: US1 is independently testable — ingest the file and query list/detail entirely from the backend (the MVP backend slice).

---

## Phase 4: User Story 2 - Browse the list of salary records (Priority: P2)

**Goal**: The Compose app shows a scrollable list of records with the key fields (cargo, organismo, retribución) and the data-freshness date, with explicit loading/empty/error states, on iOS and Android.

**Independent Test**: With a known dataset (or contract fixture) served, open the app on each platform and verify the list renders every record's key fields plus "Datos actualizados a …", and that loading/empty/error(+retry) states display correctly.

### Tests for User Story 2 (MANDATORY - TDD per Constitution Principle II) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation.**

- [ ] T043 [P] [US2] DTO decoding test for `SalaryListResponse` from `fixtures/salaries_list.json` (incl. `dataset: null` empty case) in `app/shared/src/commonTest/kotlin/data/SalaryListDtoTest.kt`
- [ ] T044 [P] [US2] `SalariesApi.fetchSalaries` test using `FakeHttpClient` (success, empty, network-error mapping) in `app/shared/src/commonTest/kotlin/data/SalariesApiListTest.kt`
- [ ] T045 [P] [US2] `ListStateHolder` test (Loading → Content / Empty / Error, retry re-fetch) in `app/shared/src/commonTest/kotlin/state/ListStateHolderTest.kt`

### Implementation for User Story 2

- [ ] T046 [P] [US2] Implement domain models `SalaryListItem` and `DatasetInfo` in `app/shared/src/commonMain/kotlin/domain/Salary.kt`
- [ ] T047 [P] [US2] Implement `@Serializable` list DTOs (`SalaryListResponse`, `DatasetInfo`, `SalaryListItem`) + mappers in `app/shared/src/commonMain/kotlin/data/SalaryDtos.kt`
- [ ] T048 [US2] Implement `SalariesApi.fetchSalaries()` in `app/shared/src/commonMain/kotlin/data/SalariesApi.kt` (uses HttpClient + ApiConfig, decodes via kotlinx.serialization) (depends on T046, T047)
- [ ] T049 [US2] Implement `ListStateHolder` exposing `StateFlow<UiState<SalaryList>>` in `app/shared/src/commonMain/kotlin/state/ListStateHolder.kt` (depends on T048)
- [ ] T050 [US2] Implement `SalaryListScreen` (LazyColumn of key fields, freshness header, Loading/Empty/Error+Reintentar states, currency formatting) in `app/composeApp/src/commonMain/kotlin/ui/list/SalaryListScreen.kt` (depends on T049)
- [ ] T051 [US2] Wire the list screen as the app start destination in `app/composeApp/src/commonMain/kotlin/ui/App.kt`, and confirm Android (`MainActivity`) and iOS (`MainViewController`) entry points launch it (depends on T050)

**Checkpoint**: US1 + US2 work — the list is browsable on both platforms against the live API.

---

## Phase 5: User Story 3 - View the full detail of a record (Priority: P3)

**Goal**: Tapping a list item opens a detail screen showing every ingested field (labelled with original headers) plus freshness; back returns to the list at the prior scroll position; a vanished record shows a clear "no longer available" state.

**Independent Test**: With a known dataset served, tap any list entry on each platform and verify the detail shows all fields with correct labels/values; requesting a removed record shows the `RECORD_NOT_AVAILABLE` state; back preserves list scroll position.

### Tests for User Story 3 (MANDATORY - TDD per Constitution Principle II) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation.**

- [ ] T052 [P] [US3] DTO decoding test for `SalaryDetailResponse` (incl. ordered `extraFields`) from `fixtures/salary_detail.json` in `app/shared/src/commonTest/kotlin/data/SalaryDetailDtoTest.kt`
- [ ] T053 [P] [US3] `SalariesApi.fetchSalaryDetail` test using `FakeHttpClient` (success, 404 → `RECORD_NOT_AVAILABLE`) in `app/shared/src/commonTest/kotlin/data/SalariesApiDetailTest.kt`
- [ ] T054 [P] [US3] `DetailStateHolder` test (Loading → Content / Error-not-available) in `app/shared/src/commonTest/kotlin/state/DetailStateHolderTest.kt`
- [ ] T055 [P] [US3] Navigation test: list → detail → back preserves list scroll position in `app/composeApp/src/commonTest/kotlin/ui/NavigationTest.kt`

### Implementation for User Story 3

- [ ] T056 [P] [US3] Implement domain models `SalaryRecordDetail` and `LabeledValue` in `app/shared/src/commonMain/kotlin/domain/SalaryDetail.kt`
- [ ] T057 [P] [US3] Implement `@Serializable` detail DTOs (`SalaryDetailResponse`, `SalaryRecordDetail`, `LabeledValue`) + mappers in `app/shared/src/commonMain/kotlin/data/SalaryDetailDtos.kt`
- [ ] T058 [US3] Implement `SalariesApi.fetchSalaryDetail(id)` with 404→`RECORD_NOT_AVAILABLE` mapping in `app/shared/src/commonMain/kotlin/data/SalariesApi.kt` (depends on T056, T057)
- [ ] T059 [US3] Implement `DetailStateHolder` exposing `StateFlow<UiState<SalaryRecordDetail>>` in `app/shared/src/commonMain/kotlin/state/DetailStateHolder.kt` (depends on T058)
- [ ] T060 [US3] Implement `SalaryDetailScreen` (all labelled fields incl. ordered extraFields, freshness, not-available state) in `app/composeApp/src/commonMain/kotlin/ui/detail/SalaryDetailScreen.kt` (depends on T059)
- [ ] T061 [US3] Wire list→detail navigation with scroll-position preservation in `app/composeApp/src/commonMain/kotlin/ui/App.kt` and the list item tap handler (depends on T060, T051)

**Checkpoint**: All three stories work independently and together — full consultation journey on iOS and Android.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate budgets, parity, and docs across stories.

- [ ] T062 [US1] Add the list-endpoint performance test asserting < 200 ms p95 under a representative dataset in `backend/vapor-server/Tests/AppTests/Integration/ListPerformanceTests.swift` (Principle IV)
- [ ] T063 [US1] Validate ingestion of a 10,000-row fixture completes ≤ 30 s (SC-002) in `backend/vapor-server/Tests/AppTests/Integration/IngestionPerformanceTests.swift`
- [ ] T064 [P] iOS/Android parity check (SC-007): verify identical content and field labels side-by-side; record results in `specs/001-mvp-consulta-sueldos/quickstart.md` validation notes
- [ ] T065 [P] Update `README.md` repository-structure section to reflect the realized `backend/` and `app/` layout (incl. `iosApp/`)
- [ ] T066 Run the full `quickstart.md` validation end-to-end (DB → server → ingest → API → app on both platforms) and fix any gaps
- [ ] T067 [P] Final code-quality pass on both stacks (remove dead code, confirm warnings-as-errors clean, doc public APIs) per Constitution Principle I

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational; independent of US2/US3
- **User Story 2 (Phase 4)**: Depends on Foundational; consumes the US1 API at integration time but is developed/tested against contract fixtures, so it can proceed in parallel with US1
- **User Story 3 (Phase 5)**: Depends on Foundational and on US2's navigation/list wiring (T051) for the tap-through; otherwise developed against fixtures
- **Polish (Phase 6)**: Depends on the stories it validates being complete

### User Story Dependencies

- **US1 (P1)**: Fully independent — backend only
- **US2 (P2)**: Independent of US1 via contract fixtures; integrates with the live API once US1 ships
- **US3 (P3)**: Builds on US2's list/navigation (T051) to open details; data layer is independent

### Within Each User Story

- Tests are written and MUST FAIL before implementation (TDD — NON-NEGOTIABLE)
- Backend: XLSXReader/models/mapper/validator → repository → service → controllers → routes
- Client: domain → DTOs → api → state holder → screen → navigation wiring
- Story complete before moving to the next priority

### Parallel Opportunities

- Setup: T003–T008 run in parallel ([P])
- Foundational: backend (T010, T011) and the entire client foundation (T012–T019) run in parallel; T009 precedes backend stories, T020 follows T019
- US1 tests T021–T023, T025–T027 in parallel; implementation [P] groups: T028/T029 (reader), T032/T033 (models), T035/T036/T037 (ingestion helpers)
- US2 tests T043–T045 in parallel; T046/T047 in parallel
- US3 tests T052–T055 in parallel; T056/T057 in parallel
- With two developers, one can own the backend (US1) while the other builds the client foundation + US2/US3 against fixtures

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 Setup → 2. Phase 2 Foundational (backend portion at minimum) → 3. Phase 3 US1
4. **STOP and VALIDATE**: ingest `Retribuciones.xlsx`, query list + detail via curl per quickstart.md
5. This backend slice is the deployable MVP foundation.

### Incremental Delivery

1. Setup + Foundational → both shells ready
2. US1 → backend ingest + API verified independently → demo via curl
3. US2 → list browsable on iOS + Android → demo
4. US3 → detail + navigation → demo
5. Polish → performance/parity/docs validated

### Parallel Team Strategy

After Foundational: Developer A takes US1 (backend); Developer B builds client foundation then US2 then US3 against contract fixtures; integrate against the live API once US1 lands.

---

## Notes

- [P] = different files, no dependency on an incomplete task
- [Story] label maps each task to its user story for traceability
- Tests-first is mandatory (Constitution Principle II); verify red before implementing
- Shared contract fixtures (T008) keep backend and client pinned to `contracts/openapi.yaml`
- Commit after each task or logical group; keep warnings-as-errors green on both stacks
