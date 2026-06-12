# Research: MVP Consulta de Sueldos

**Feature**: `001-mvp-consulta-sueldos` | **Date**: 2026-06-12

All NEEDS CLARIFICATION items from the Technical Context are resolved here. Each decision
follows the constitution's custom-first dependency policy (Principle V).

## R1. Parsing .xls (legacy binary Excel) in Swift

**Decision**: Implement a custom, minimal `.xls` (BIFF8) reader as a standalone Swift
module (`XLSReader`) inside the backend package, scoped to exactly what
`Retribuciones.xls` needs:

- CFB (Compound File Binary) container: header, FAT, directory, `Workbook` stream
  reassembly (including mini-stream for small files).
- BIFF8 records: `BOF`, `BoundSheet8`, `SST`/`Continue`, `LabelSst`, `Label`, `Number`,
  `RK`, `MulRk`, `Blank`, `Formula` (cached numeric result + `String` follow record),
  `EOF`. Unknown records are skipped by length — the format is length-prefixed, so a
  subset reader is safe.
- String decoding: BIFF8 unicode strings (compressed 8-bit and UTF-16LE variants,
  including continuation across `Continue` records).
- Output: first worksheet as `[[XLSCellValue]]` (string/number/empty) plus the header
  row, which is all ingestion needs.

**Rationale**: Constitution Principle V mandates custom-first. The BIFF8 subset above is
well documented (MS-XLS spec), bounded, and fully unit-testable with small fixture files.
No maintained first-party Swift option exists.

**Alternatives considered**:
- `libxls` (C library via SPM system target): third-party, C interop, unmaintained
  periods, security advisories — rejected.
- `CoreXLSX`: parses `.xlsx` (OOXML) only, not legacy `.xls` — not applicable.
- Converting the file to CSV/XLSX out-of-band: violates FR-001 (the system must accept
  `.xls`) and adds a manual step — rejected.

**Risk & mitigation**: BIFF8 has many record types; risk of fixture files using
unhandled records. Mitigated by skip-by-length design, fixture tests generated from the
real `Retribuciones.xls`, and a clear `XLSError` taxonomy so unreadable files fail whole
(FR-004) instead of corrupting data.

## R2. Persistence: PostgreSQL access layer

**Decision**: Fluent ORM with `fluent-postgres-driver` (both `vapor/*` official
packages) on a local PostgreSQL 16 instance.

**Rationale**: PostgreSQL was mandated by the user. Implementing the Postgres wire
protocol is the canonical "custom implementation is unreasonable" case. Fluent and its
Postgres driver are maintained by the Vapor core team (same org as the mandated
framework), giving migrations, model mapping, and transactions with one
dependency family. Recorded in the plan's Complexity Tracking per Principle V.

**Alternatives considered**:
- `PostgresNIO` directly (also Vapor org): fewer abstractions but hand-written SQL,
  manual row decoding, and hand-rolled migration tracking — more custom code with no
  dependency-count benefit (Fluent builds on it anyway).
- SQLite/in-memory: contradicts the user's explicit PostgreSQL requirement.

## R3. Ingestion trigger & file location

**Decision**: `POST /api/v1/admin/ingest` triggers ingestion. The server reads the file
from a configured filesystem path (`INGEST_FILE_PATH` env var), defaulting to
`Retribuciones.xls` at the repository root. The endpoint responds with the full
ingestion report (FR-003). An `actor`-guarded flag rejects concurrent ingestions with
`409 INGESTION_IN_PROGRESS`.

**Rationale**: The user specified the file lives at the project root with a fixed name,
so a trigger-endpoint-reads-path design is simpler and more scriptable than multipart
upload, while still satisfying FR-001's "accept submission" as a single submission step
(SC-001). No auth, per the spec assumption (local, trusted operator).

**Alternatives considered**:
- Multipart file upload: more general but contradicts the stated fixed-location input
  and adds client tooling needs — deferred to a future increment.
- Ingest automatically on server boot: hides failures, makes the ingestion report
  awkward to deliver, complicates tests — rejected.
- Console command only: not reachable as "a single submission step" while the server
  runs; the endpoint can be curl'd locally — rejected as the primary path.

## R4. Atomic dataset replacement

**Decision**: Two tables, `datasets` and `salary_records` (records FK → dataset). Flow:
parse the whole file first (in memory); then in one transaction insert the new dataset
(status `active`), insert all its records, and flip any previous dataset to
`superseded`; readers always query "the single `active` dataset". A post-commit cleanup
deletes superseded datasets. Parse failures (FR-004) abort before any write.

**Rationale**: Satisfies FR-005 (consumers never see a partial dataset — visibility
flips with one transactional status change) and the spec edge case "never leaves a
partially published dataset". Keeping exactly one active dataset matches the
no-history assumption.

**Alternatives considered**:
- `TRUNCATE` + bulk insert in one transaction: holds a heavier lock and equates "dataset"
  with "table contents", losing the `ingested_at` metadata home — rejected.
- Versioned datasets kept forever: out of scope (no history in this increment).

## R5. KMP networking: custom HTTP client

**Decision**: A minimal custom HTTP GET/POST client behind a project-owned
`HttpClient` interface in `commonMain`, with `expect/actual` implementations:
`URLSession` (iOS) and `HttpURLConnection` on `Dispatchers.IO` (Android). Suspend-based
API returning status + body; timeouts and error mapping included.

**Rationale**: The app needs two GET endpoints against a local server. Constitution
Principle V: custom is reasonable here (~100 lines per platform), removing the only
third-party candidate (Ktor) from the client entirely. The interface wrapper keeps a
later swap to Ktor trivial if scope grows (WebSockets, auth, multipart).

**Alternatives considered**:
- Ktor client: well-established (JetBrains) and the conventional choice, but not needed
  for two GETs; fails the "custom implementation unreasonable" test — rejected for now.

## R6. JSON serialization (client)

**Decision**: `kotlinx.serialization` with `@Serializable` DTOs in `commonMain`.

**Rationale**: kotlinx libraries are explicitly first-party under the constitution.
Hand-rolling a JSON parser is error-prone and adds no value.

**Alternatives considered**: custom parser (unjustifiable risk), Moshi/Gson (JVM-only,
third-party) — rejected.

## R7. Client architecture, navigation, and state

**Decision**: All UI in shared Compose Multiplatform (`composeApp`); domain, DTOs,
networking, and screen state in `app/shared`. Plain state-holder classes (no ViewModel
library) exposing `StateFlow<UiState>` consumed via `collectAsState()`. Navigation is a
custom two-destination back stack (sealed `Screen` class + `mutableStateListOf`),
preserving list scroll position on back (spec US3-AS3). Each screen models
`Loading / Content / Empty / Error(retry)` explicitly (FR-012, Principle III).

**Rationale**: Two screens do not justify navigation or DI libraries; sealed-class
navigation is fully testable in `commonTest`. kotlinx.coroutines is first-party.

**Alternatives considered**: Jetpack Navigation MP / Voyager / Decompose (third-party or
overkill for two screens), platform-specific ViewModels (breaks shared-max goal) —
rejected.

## R8. Spanish UI text

**Decision**: A single `Strings.es` object in `commonMain` (project-owned, type-safe
constants), used by all composables. Spanish number/currency formatting (e.g.
`1.234,56 €`) via a small `expect/actual` formatter over platform locale APIs
(`NSNumberFormatter` / `java.text.NumberFormat` with `Locale("es","ES")`).

**Rationale**: Constitution Principle III requires centralized user-facing text;
single-language MVP needs no resource framework. Data values are shown as-is (Spanish
source data).

## R9. Swift strict concurrency

**Decision**: Swift 6 language mode with complete concurrency checking
(`swiftLanguageMode(.v6)` in Package.swift); concurrency warnings are errors by
definition there. Shared mutable state (ingestion-in-progress flag) lives in an
`actor`; request handlers stay `Sendable`-clean; Fluent models confined per Vapor 4
Swift-6 guidance.

**Rationale**: Mandated by the user and the constitution's Technology Stack section.

## R10. Column mapping for `Retribuciones.xls`

**Decision**: Header-driven mapping with normalization (trim, lowercase, strip accents,
collapse spaces). Mandatory columns matched via alias sets:
- position title ← `cargo`, `puesto`, `denominacion del puesto`
- institution ← `organismo`, `departamento`, `ministerio`, `institucion`
- salary amount ← `retribucion`, `retribucion anual`, `retribuciones`, `total anual`,
  `sueldo`

All remaining columns are preserved untouched (original header → raw cell value, ordered
as in the file) into the record's `extra_fields` JSONB, which feeds the detail view
(FR-010). Salary cells accept numeric cells or Spanish-formatted numeric strings
(`70.508,52`). Rows failing mandatory-field validation are rejected with row number and
reason (FR-002/FR-003). If a mandatory *header* cannot be found, the whole file is
rejected (FR-004 class error `MISSING_REQUIRED_COLUMNS`).

**Rationale**: The real file's exact layout is confirmed at implementation time; alias
matching plus lossless extras make the mapping robust to header variations without
schema churn — extra columns never require migrations.

## R11. Testing stacks & TDD mechanics

**Decision**:
- Backend: `XCTest` + `XCTVapor`. Unit tests for `XLSReader` (fixture .xls files
  committed under `Tests/.../Fixtures/`), the column mapper, and validators. Integration
  tests for every endpoint against a dedicated test database
  (`cuanto_cobran_test`, migrated/reset per run). Contract tests assert response JSON
  shape against the OpenAPI contract.
- Client: `kotlin.test` in `commonTest` for domain, DTO decoding (shared JSON fixtures
  copied from `contracts/`), state holders (with a fake `HttpClient`), and navigation
  logic. Platform smoke tests in `androidTest`/iOS test target.
- Contract boundary: the same canned JSON fixtures are used by backend contract tests
  (server must produce) and client tests (client must consume), keeping both sides
  pinned to `contracts/openapi.yaml`.

**Rationale**: Principle II requires tests-first with contract tests at the API
boundary; shared fixtures make the contract executable on both stacks.

## R12. Toolchain versions & platform minimums

**Decision**: Backend: Swift 6.1+, Vapor 4 (latest), PostgreSQL 16 (local, Homebrew or
Docker), macOS host. Client: Kotlin 2.1.x, Compose Multiplatform 1.8.x (stable iOS),
Gradle 8.x, JDK 17, Android `minSdk 24` / `targetSdk 35`, iOS 15.0+ deployment target.
Reference devices for performance budgets: Pixel 6a / iPhone 12.

**Rationale**: Current stable versions as of June 2026 baseline; Compose iOS is stable;
minimums chosen for broad device coverage without legacy workarounds.
