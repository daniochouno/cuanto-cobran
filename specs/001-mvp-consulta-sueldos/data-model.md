# Data Model: MVP Consulta de Sueldos

**Feature**: `001-mvp-consulta-sueldos` | **Date**: 2026-06-12

Derived from the spec's Key Entities and FR-001…FR-013. Storage is PostgreSQL (backend);
the client consumes API DTOs only and persists nothing.

## Entity: Dataset

One successful ingestion of `Retribuciones.xls`. Exactly one dataset is `active` at any
time; it is the only one consumers can see.

**Table**: `datasets`

| Column        | Type           | Constraints                              |
|---------------|----------------|------------------------------------------|
| `id`          | `uuid`         | PK, generated                            |
| `ingested_at` | `timestamptz`  | NOT NULL — the "last updated" indicator  |
| `status`      | `text`         | NOT NULL, `active` \| `superseded`       |
| `source_file` | `text`         | NOT NULL — file name as ingested         |
| `rows_read`   | `int`          | NOT NULL                                 |

**Invariants**:
- At most one row with `status = 'active'` (partial unique index on `status` WHERE
  `status = 'active'`).
- A dataset and its records are inserted in the same transaction that supersedes the
  previous active dataset (FR-005 — atomic replacement).

**State transitions**:
`(parsing, in memory)` → `active` (on commit) → `superseded` (when the next ingestion
commits) → deleted (post-commit cleanup). Parse/validation failure of the whole file
never reaches the database (FR-004).

## Entity: Salary Record

One valid row of the ingested spreadsheet — a public position and its remuneration.

**Table**: `salary_records`

| Column            | Type            | Constraints                                       |
|-------------------|-----------------|---------------------------------------------------|
| `id`              | `uuid`          | PK, generated                                     |
| `dataset_id`      | `uuid`          | NOT NULL, FK → `datasets.id` ON DELETE CASCADE    |
| `position_title`  | `text`          | NOT NULL, non-empty (mandatory field, FR-002)     |
| `institution`     | `text`          | NOT NULL, non-empty (mandatory field, FR-002)     |
| `salary_amount`   | `numeric(12,2)` | NOT NULL, ≥ 0 (mandatory field, FR-002)           |
| `source_row_number` | `int`         | NOT NULL — 1-based row in the source file (SC-003) |
| `extra_fields`    | `jsonb`         | NOT NULL, default `[]`                            |

`extra_fields` is an **ordered array** of `{ "label": <original header>, "value":
<string|number|null> }` pairs — column order of the source file is preserved for the
detail view (FR-010); labels are the original (Spanish) headers, displayed as-is.

**Validation rules (ingestion)**:
- `position_title`, `institution`: present and non-blank after trimming → else row
  rejected (`MISSING_MANDATORY_FIELD`).
- `salary_amount`: numeric cell, or string parseable as a Spanish-formatted number
  (`70.508,52`); must be ≥ 0 → else rejected (`INVALID_SALARY_AMOUNT`).
- Duplicate rows are allowed and published as distinct records; flagged in the
  ingestion report (spec edge case).
- Index: `(dataset_id)` for the list query; list is returned ordered by
  `source_row_number` (stable, mirrors the source file).

## Transient: Ingestion Result (not persisted)

Returned by the ingest endpoint (FR-003); not stored beyond the `datasets` row counts.

| Field              | Type                                | Notes                              |
|--------------------|-------------------------------------|------------------------------------|
| `datasetId`        | uuid                                | The newly active dataset           |
| `ingestedAt`       | ISO-8601 timestamp                  | Equals `datasets.ingested_at`      |
| `rowsRead`         | int                                 | Data rows found (excl. header)     |
| `recordsPublished` | int                                 | = rowsRead − rejected count        |
| `rejectedRows`     | array of `{rowNumber, reason}`      | Reason codes from validation rules |
| `duplicateRowNumbers` | array of int                     | Informational (rows published)     |

Invariant: `recordsPublished + len(rejectedRows) = rowsRead` (SC-003).

## API DTOs (client-side mirror)

Defined by [contracts/openapi.yaml](contracts/openapi.yaml); the client declares
`@Serializable` equivalents in `commonMain`:

- `SalaryListResponse` → `dataset: DatasetInfo?`, `items: [SalaryListItem]`
- `DatasetInfo` → `lastUpdated`
- `SalaryListItem` → `id`, `positionTitle`, `institution`, `salaryAmount` (the "most
  important data", FR-009)
- `SalaryDetailResponse` → `dataset: DatasetInfo`, `record: SalaryRecordDetail`
- `SalaryRecordDetail` → list item fields + `sourceRowNumber` + `extraFields:
  [LabeledValue]` (FR-010)
- `ApiError` → `code`, `message` (machine code + Spanish-displayable fallback handled
  client-side; e.g. `RECORD_NOT_AVAILABLE` → FR-013 message)

## Relationships

```text
Dataset 1 ──── * SalaryRecord        (cascade delete)
Dataset (active) ──── exposed via API; superseded datasets are deleted
Institution ── attribute of SalaryRecord (not a table in this increment, per spec)
```
