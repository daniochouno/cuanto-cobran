import Vapor
import Foundation

/// Freshness metadata for the active dataset (FR-006/FR-011).
struct DatasetInfo: Content, Sendable {
    let lastUpdated: Date
}

/// A list entry — only the key fields shown in the app list (FR-009).
struct SalaryListItem: Content, Sendable {
    let id: UUID
    let positionTitle: String
    let institution: String
    let salaryAmount: Double
}

/// Response for `GET /api/v1/salaries`. `dataset` is null when nothing is published.
struct SalaryListResponse: Content, Sendable {
    let dataset: DatasetInfo?
    let items: [SalaryListItem]
}

/// A full record — list fields plus traceability and all extra columns (FR-010).
struct SalaryRecordDetail: Content, Sendable {
    let id: UUID
    let positionTitle: String
    let institution: String
    let salaryAmount: Double
    let sourceRowNumber: Int
    let extraFields: [LabeledValue]
}

/// Response for `GET /api/v1/salaries/{id}`.
struct SalaryDetailResponse: Content, Sendable {
    let dataset: DatasetInfo
    let record: SalaryRecordDetail
}
