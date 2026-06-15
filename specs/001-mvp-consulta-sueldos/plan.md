# Implementation Plan: MVP Consulta de Sueldos — Salary Data Publication & Browsing

**Branch**: `main` | **Date**: 2026-06-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-mvp-consulta-sueldos/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Ingest the official `Retribuciones.xlsx` (repository root) into a local PostgreSQL
database through a Vapor (Swift 6, strict concurrency) server exposing a small versioned
API — trigger ingestion, list records, record detail — with atomic replace-on-ingest
semantics. A Kotlin Multiplatform app with shared Compose Multiplatform UI (Android +
iOS, Spanish-only UI) consumes the API: a list screen with the key fields (cargo,
organismo, retribución) and a detail screen with every ingested field. Custom-first
throughout: a purpose-built OOXML `.xlsx` reader in Swift and a custom `expect/actual`
HTTP client in Kotlin; the only third-party dependencies are Vapor-org persistence
packages (justified below).

## Technical Context

**Language/Version**: Backend: Swift 6.1 (Swift 6 language mode, complete concurrency
checking). Client: Kotlin 2.1.x, Compose Multiplatform 1.8.x, Gradle 8.x, JDK 17.

**Primary Dependencies**: Backend: Vapor 4, Fluent + FluentPostgresDriver (Vapor org —
see Complexity Tracking). Client: Compose Multiplatform, kotlinx.serialization,
kotlinx.coroutines (all first-party per constitution); custom HTTP client (no Ktor).

**Storage**: PostgreSQL 16, local instance. Tables `datasets` + `salary_records`
(JSONB for extra columns). See [data-model.md](data-model.md).

**Testing**: Backend: XCTest + XCTVapor (unit: XLSXReader/mapper/validators; integration:
all endpoints on `cuanto_cobran_test`; contract: fixtures pinned to
[contracts/openapi.yaml](contracts/openapi.yaml)). Client: kotlin.test in `commonTest`
(DTOs from shared contract fixtures, state holders, navigation), platform smoke tests.

**Target Platform**: Server: macOS host, local deployment (127.0.0.1:8080). App:
Android minSdk 24 / targetSdk 35, iOS 15.0+.

**Project Type**: Mobile app + API (two-part repository per constitution).

**Performance Goals**: List/detail endpoints < 200 ms p95; 10,000-row ingestion ≤ 30 s
(SC-002); app list populated < 2 s after cold open (SC-004); detail < 1 s perceived
(SC-005); 60 fps list scrolling on Pixel 6a / iPhone 12.

**Constraints**: Swift strict concurrency (warnings = errors); UI language Spanish with
centralized strings; atomic dataset replacement (consumers never see partial data);
input file fixed at repo root `Retribuciones.xlsx` (overridable via `INGEST_FILE_PATH`);
no authentication (local trusted operator — public exposure out of scope); offline app
shows explicit error/retry states.

**Scale/Scope**: Hundreds to a few thousand records (10k upper bound); single dataset
at a time, no history; 2 app screens; 4 API endpoints.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Code Quality First | Idiomatic Swift/Kotlin; warnings-as-errors both stacks (Swift 6 mode; Kotlin `allWarningsAsErrors`); public APIs documented; no dead code | ✅ PASS — encoded in toolchain config tasks |
| II. TDD (NON-NEGOTIABLE) | Tests precede code for every component; contract tests at API boundary; integration tests per endpoint; common-source-set tests for shared Kotlin | ✅ PASS — test strategy in [research.md R11](research.md); shared JSON fixtures pin both stacks to the contract |
| III. UX Consistency | All UI in shared Compose; single design-system file; source/last-updated visible on list & detail; explicit loading/empty/error states; centralized Spanish strings | ✅ PASS — FR-011/FR-012 map directly; `Strings.es` + `Theme.kt` in commonMain ([research.md R7–R8](research.md)) |
| IV. Performance | Budgets stated and measurable: <200 ms p95 API, ≤30 s/10k ingest, <2 s app start, 60 fps, <500 ms search (n/a — no search this increment); measurement via integration perf test + manual profile per [quickstart.md](quickstart.md) | ✅ PASS |
| V. Minimal Dependencies, Custom-First | Custom OOXML .xlsx reader (R1: custom ZIP + RFC 1951 inflate, XML via first-party Foundation XMLParser); custom HTTP client (R5); custom navigation/state (R7); only third-party: Fluent + FluentPostgresDriver, justified in Complexity Tracking and wrapped behind repository protocols | ✅ PASS |
| Tech Stack & Constraints | KMP + Compose MP app / Vapor backend split; strict concurrency on; versioned API only boundary; repo layout per README | ✅ PASS |

**Post-Phase-1 re-check**: design artifacts (data-model, contracts, quickstart) introduce
no new dependencies or violations. ✅ PASS.

## Project Structure

### Documentation (this feature)

```text
specs/001-mvp-consulta-sueldos/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/
│   └── openapi.yaml     # API contract (Phase 1 output)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
Retribuciones.xlsx                    # Input file (repo root, per user requirement)

backend/
└── vapor-server/
    ├── Package.swift                 # Swift 6 mode, strict concurrency
    ├── Sources/App/
    │   ├── entrypoint.swift
    │   ├── configure.swift           # DB config, migrations, routes registration
    │   ├── XLSXReader/               # Custom OOXML .xlsx reader (R1) — no Vapor imports
    │   │   ├── ZIPArchive.swift      # ZIP container: central dir + entry extraction
    │   │   ├── Inflate.swift         # Custom RFC 1951 DEFLATE inflate
    │   │   ├── SpreadsheetML.swift   # sharedStrings + worksheet via Foundation XMLParser
    │   │   └── XLSXWorkbook.swift    # Public API: rows of XLSXCellValue
    │   ├── Ingestion/
    │   │   ├── ColumnMapper.swift    # Header normalization + alias mapping (R10)
    │   │   ├── RowValidator.swift    # Mandatory fields, Spanish number parsing
    │   │   ├── IngestionService.swift# Orchestration + atomic replace (R4), actor guard
    │   │   └── IngestionReport.swift
    │   ├── Models/                   # Fluent models: Dataset, SalaryRecord
    │   ├── Migrations/
    │   ├── Repositories/             # Protocol-wrapped Fluent access (Principle V)
    │   └── Controllers/
    │       ├── SalariesController.swift   # GET list / GET detail
    │       └── AdminController.swift      # POST ingest
    └── Tests/AppTests/
        ├── Unit/                     # XLSXReader, ColumnMapper, RowValidator
        ├── Integration/              # Endpoints against cuanto_cobran_test
        ├── Contract/                 # Response shape vs contracts/ fixtures
        └── Fixtures/                 # Sample .xlsx files + canned JSON

app/
├── settings.gradle.kts
├── gradle/ …
├── shared/                           # KMP library: domain + data (no UI)
│   └── src/
│       ├── commonMain/kotlin/
│       │   ├── domain/               # SalaryListItem, SalaryRecordDetail, DatasetInfo
│       │   ├── data/
│       │   │   ├── HttpClient.kt     # Project-owned interface (R5)
│       │   │   ├── SalariesApi.kt    # Endpoints + kotlinx.serialization DTOs
│       │   │   └── ApiConfig.kt      # Base URL per platform (10.0.2.2 / 127.0.0.1)
│       │   └── state/                # ListStateHolder, DetailStateHolder (StateFlow)
│       ├── commonTest/kotlin/        # DTO decoding (contract fixtures), state, fakes
│       ├── androidMain/kotlin/       # actual HttpClient (HttpURLConnection), formatter
│       └── iosMain/kotlin/           # actual HttpClient (URLSession), formatter
├── composeApp/                       # Shared Compose UI + platform entry points
│   └── src/
│       ├── commonMain/kotlin/ui/
│       │   ├── App.kt                # Root + custom navigation (R7)
│       │   ├── theme/Theme.kt        # Design system (Principle III)
│       │   ├── strings/Strings.kt    # Centralized Spanish strings (R8)
│       │   ├── list/SalaryListScreen.kt    # + Loading/Empty/Error states
│       │   └── detail/SalaryDetailScreen.kt
│       ├── androidMain/kotlin/       # MainActivity
│       └── iosMain/kotlin/           # MainViewController
└── iosApp/                           # Xcode wrapper project (entry point only)
```

**Structure Decision**: Two-part monorepo per the constitution's Technology Stack
section and README: `backend/vapor-server` (Vapor API + ingestion) and `app/` (KMP:
`shared` for domain/data/state, `composeApp` for all UI, `iosApp` as the thin Xcode
entry wrapper — an addition to the README sketch required to build for iOS). The
`XLSXReader` module stays Vapor-free so it is unit-testable in isolation and reusable.

## Complexity Tracking

> Constitution Principle V requires every third-party dependency to be recorded here
> with justification. (No constitution gate violations exist; this table documents the
> approved dependency exceptions.)

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `fluent` + `fluent-postgres-driver` (Vapor org) | PostgreSQL mandated by user; needs wire protocol, pooling, migrations, transactions | Custom Postgres wire-protocol client is the canonical "unreasonable custom implementation"; raw `PostgresNIO` (same org) means hand-written SQL/row-decoding/migration tracking — more custom code, zero fewer dependency families. Access is wrapped behind `Repositories/` protocols so domain code never imports Fluent. License: MIT; maintained by Vapor core team. |
| *(none on the client)* | — | Ktor was rejected in favor of a custom HTTP client ([research.md R5](research.md)); serialization/coroutines/Compose are first-party per constitution. |
