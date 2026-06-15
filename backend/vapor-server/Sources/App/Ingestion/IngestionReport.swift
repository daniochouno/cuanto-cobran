import Vapor
import Foundation

/// The outcome of one ingestion submission (FR-003, contracts/openapi.yaml).
/// Invariant: `recordsPublished + rejectedRows.count == rowsRead` (SC-003).
struct IngestionReport: Content, Sendable {
    let datasetId: UUID
    let ingestedAt: Date
    let rowsRead: Int
    let recordsPublished: Int
    let rejectedRows: [RejectedRow]
    let duplicateRowNumbers: [Int]

    struct RejectedRow: Content, Sendable {
        let rowNumber: Int
        let reason: String
    }
}
