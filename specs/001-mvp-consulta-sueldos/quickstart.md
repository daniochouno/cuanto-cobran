# Quickstart: MVP Consulta de Sueldos

End-to-end validation guide for `001-mvp-consulta-sueldos`. Contracts:
[contracts/openapi.yaml](contracts/openapi.yaml) · Data model:
[data-model.md](data-model.md).

## Prerequisites

- macOS with Xcode 16+ (Swift 6.1 toolchain) and an iOS 15+ simulator
- PostgreSQL 16 running locally (`brew install postgresql@16` or Docker)
- JDK 17 and Android Studio (or an Android emulator, API 24+)
- `Retribuciones.xlsx` present at the repository root

## 1. Database setup

```bash
createdb cuanto_cobran
createdb cuanto_cobran_test   # used by backend integration tests
```

Default connection: `postgres://localhost:5432/cuanto_cobran` (override with
`DATABASE_URL`).

## 2. Run the backend (local deployment)

```bash
cd backend/vapor-server
swift run App migrate --yes
swift run App serve --hostname 127.0.0.1 --port 8080
```

Expected: server starts with strict concurrency clean build (warnings are errors) and
`GET http://127.0.0.1:8080/api/v1/health` returns `{"status":"ok"}`.

## 3. Ingest the spreadsheet

```bash
curl -X POST http://127.0.0.1:8080/api/v1/admin/ingest
```

Expected (per [IngestionReport](contracts/openapi.yaml)): JSON with `rowsRead`,
`recordsPublished`, `rejectedRows` (row numbers + reasons), and
`recordsPublished + rejectedRows.length == rowsRead` (SC-003). Re-running replaces the
dataset atomically and bumps `ingestedAt` (FR-005/FR-006). Budget: ≤ 30 s for a
10,000-row file (SC-002).

Failure checks:
- Rename the file away → `404 FILE_NOT_FOUND`, previous dataset still served.
- Point `INGEST_FILE_PATH` at a non-xlsx file → `422 INVALID_FILE`, previous dataset
  still served (FR-004).

## 4. Verify the API

```bash
curl http://127.0.0.1:8080/api/v1/salaries            # list: key fields + lastUpdated
curl http://127.0.0.1:8080/api/v1/salaries/<id>       # detail: all fields
curl http://127.0.0.1:8080/api/v1/salaries/00000000-0000-0000-0000-000000000000
# → 404 {"code":"RECORD_NOT_AVAILABLE", ...}  (FR-013)
```

List p95 must stay under 200 ms (constitution Principle IV) — measured by the
integration perf test, or manually: `time curl -s ... > /dev/null`.

## 5. Run the app

Android:

```bash
cd app
./gradlew :composeApp:installDebug   # with an emulator/device running
```

iOS:

```bash
open app/iosApp/iosApp.xcodeproj     # select a simulator, Run
```

Note: the Android emulator reaches the host's server at `http://10.0.2.2:8080`; iOS
simulator uses `http://127.0.0.1:8080` (configured per platform, see plan).

Expected on both platforms (UI in Spanish):
- List shows every record: cargo, organismo y retribución, plus "Datos actualizados a
  \<fecha\>" (FR-009/FR-011); populated within 2 s of cold open (SC-004).
- Tapping a record opens the detail with all ingested fields labelled with the original
  headers (FR-010); opens in under 1 s (SC-005); back returns to the same scroll
  position.
- With the server stopped: error state with "Reintentar" (FR-012).
- With an empty dataset published: explicit empty state (FR-012).
- Side-by-side iOS/Android check: identical content and labels (SC-007).

## 6. Run the test suites (TDD gate)

```bash
# Backend: XLSXReader unit tests, mapper/validator tests, endpoint integration tests,
# contract tests against contracts/openapi.yaml fixtures
cd backend/vapor-server && swift test

# Client: commonTest (DTO decoding from shared contract fixtures, state holders,
# navigation) + Android unit tests
cd app && ./gradlew check
```

Expected: all green; both suites are required by CI before merge (Constitution
Principles I–II).
