import Fluent
import SQLKit

/// Creates the `datasets` and `salary_records` tables plus the partial unique
/// index guaranteeing at most one active dataset (data-model.md).
struct CreateDatasetAndSalaryRecord: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("datasets")
            .id()
            .field("ingested_at", .datetime, .required)
            .field("status", .string, .required)
            .field("source_file", .string, .required)
            .field("rows_read", .int, .required)
            .create()

        try await database.schema("salary_records")
            .id()
            .field("dataset_id", .uuid, .required, .references("datasets", "id", onDelete: .cascade))
            .field("position_title", .string, .required)
            .field("institution", .string, .required)
            .field("salary_amount", .double, .required)
            .field("source_row_number", .int, .required)
            .field("extra_fields", .json, .required)
            .create()

        if let sql = database as? SQLDatabase {
            try await sql.raw("""
                CREATE UNIQUE INDEX uq_active_dataset ON datasets (status) WHERE status = 'active'
                """).run()
            try await sql.raw("""
                CREATE INDEX idx_salary_records_dataset ON salary_records (dataset_id)
                """).run()
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema("salary_records").delete()
        try await database.schema("datasets").delete()
    }
}
