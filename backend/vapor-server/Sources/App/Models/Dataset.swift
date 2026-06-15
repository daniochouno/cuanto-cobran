import Fluent
import Foundation

/// The set of records produced by one successful ingestion. Exactly one dataset
/// is `active` at a time; readers only ever see the active dataset (FR-005/FR-006).
final class Dataset: Model, @unchecked Sendable {
    static let schema = "datasets"

    @ID(key: .id) var id: UUID?
    @Field(key: "ingested_at") var ingestedAt: Date
    @Field(key: "status") var status: String
    @Field(key: "source_file") var sourceFile: String
    @Field(key: "rows_read") var rowsRead: Int

    init() {}

    init(id: UUID? = nil, ingestedAt: Date, status: String, sourceFile: String, rowsRead: Int) {
        self.id = id
        self.ingestedAt = ingestedAt
        self.status = status
        self.sourceFile = sourceFile
        self.rowsRead = rowsRead
    }
}

/// Allowed values for `Dataset.status`.
enum DatasetStatus {
    static let active = "active"
    static let superseded = "superseded"
}
