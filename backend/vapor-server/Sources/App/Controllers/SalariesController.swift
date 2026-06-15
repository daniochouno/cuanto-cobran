import Vapor
import Fluent

/// Serves the published dataset: a list of records and a single record's detail.
struct SalariesController: RouteCollection {
    let repository: any SalaryRepository

    init(repository: any SalaryRepository = FluentSalaryRepository()) {
        self.repository = repository
    }

    func boot(routes: any RoutesBuilder) throws {
        let salaries = routes.grouped("api", "v1", "salaries")
        salaries.get(use: list)
        salaries.get(":id", use: detail)
    }

    /// `GET /api/v1/salaries` — key fields for every record of the active dataset.
    @Sendable
    func list(req: Request) async throws -> SalaryListResponse {
        guard let dataset = try await repository.activeDataset(on: req.db),
              let datasetID = dataset.id else {
            return SalaryListResponse(dataset: nil, items: [])
        }
        let records = try await repository.listRecords(datasetID: datasetID, on: req.db)
        let items = records.compactMap { record -> SalaryListItem? in
            guard let id = record.id else { return nil }
            return SalaryListItem(
                id: id,
                positionTitle: record.positionTitle,
                institution: record.institution,
                salaryAmount: record.salaryAmount
            )
        }
        return SalaryListResponse(dataset: DatasetInfo(lastUpdated: dataset.ingestedAt), items: items)
    }

    /// `GET /api/v1/salaries/{id}` — all fields for one record, or 404 if it is
    /// not in the active dataset (FR-013).
    @Sendable
    func detail(req: Request) async throws -> SalaryDetailResponse {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw ApiError.recordNotAvailable
        }
        guard let dataset = try await repository.activeDataset(on: req.db),
              let datasetID = dataset.id else {
            throw ApiError.recordNotAvailable
        }
        guard let record = try await repository.findRecord(id: id, datasetID: datasetID, on: req.db),
              let recordID = record.id else {
            throw ApiError.recordNotAvailable
        }
        return SalaryDetailResponse(
            dataset: DatasetInfo(lastUpdated: dataset.ingestedAt),
            record: SalaryRecordDetail(
                id: recordID,
                positionTitle: record.positionTitle,
                institution: record.institution,
                salaryAmount: record.salaryAmount,
                sourceRowNumber: record.sourceRowNumber,
                extraFields: record.extraFields.values
            )
        )
    }
}
