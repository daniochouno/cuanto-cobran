import Fluent
import Foundation

/// Read access to published salary data, wrapped behind a protocol so domain and
/// controller code never depend on Fluent directly (Constitution Principle V).
protocol SalaryRepository: Sendable {
    func activeDataset(on db: any Database) async throws -> Dataset?
    func listRecords(datasetID: UUID, on db: any Database) async throws -> [SalaryRecord]
    func findRecord(id: UUID, datasetID: UUID, on db: any Database) async throws -> SalaryRecord?
}

/// Fluent-backed implementation of `SalaryRepository`.
struct FluentSalaryRepository: SalaryRepository {
    func activeDataset(on db: any Database) async throws -> Dataset? {
        try await Dataset.query(on: db)
            .filter(\.$status == DatasetStatus.active)
            .first()
    }

    func listRecords(datasetID: UUID, on db: any Database) async throws -> [SalaryRecord] {
        try await SalaryRecord.query(on: db)
            .filter(\.$dataset.$id == datasetID)
            .sort(\.$sourceRowNumber)
            .all()
    }

    func findRecord(id: UUID, datasetID: UUID, on db: any Database) async throws -> SalaryRecord? {
        try await SalaryRecord.query(on: db)
            .filter(\.$id == id)
            .filter(\.$dataset.$id == datasetID)
            .first()
    }
}
