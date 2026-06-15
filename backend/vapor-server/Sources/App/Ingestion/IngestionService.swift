import Fluent
import Foundation
import XLSXReader

/// Serializes ingestion: only one may run at a time across the whole process.
/// Holds nothing but a Bool, so it is safe to share (Sendable).
actor IngestionGuard {
    private var running = false

    /// Returns true if ingestion may start; false if one is already running.
    func begin() -> Bool {
        if running { return false }
        running = true
        return true
    }

    func end() {
        running = false
    }
}

/// Orchestrates ingestion: parse the whole file, validate rows, then atomically
/// replace the active dataset in one transaction (research.md R3/R4, FR-005).
struct IngestionService: Sendable {
    static let shared = IngestionGuard()

    /// Ingest `fileURL`, returning the report. Throws `ApiError` on failure;
    /// a failed parse/validation never mutates the published dataset (FR-004).
    func ingest(fileURL: URL, sourceName: String, on db: any Database) async throws -> IngestionReport {
        guard await IngestionService.shared.begin() else {
            throw ApiError.ingestionInProgress
        }
        do {
            let report = try await perform(fileURL: fileURL, sourceName: sourceName, on: db)
            await IngestionService.shared.end()
            return report
        } catch {
            await IngestionService.shared.end()
            throw error
        }
    }

    private func perform(fileURL: URL, sourceName: String, on db: any Database) async throws -> IngestionReport {
        let workbook: XLSXWorkbook
        do {
            workbook = try XLSXWorkbook(contentsOf: fileURL)
        } catch {
            throw ApiError.invalidFile
        }

        let mapping = try ColumnMapper.map(header: workbook.headerRow)

        var validated: [(record: ValidatedRecord, rowNumber: Int)] = []
        var rejected: [IngestionReport.RejectedRow] = []
        var duplicates: [Int] = []
        var seen = Set<String>()

        var rowNumber = 1 // header is row 1
        for row in workbook.dataRows {
            rowNumber += 1
            switch RowValidator.validate(row: row, mapping: mapping) {
            case .valid(let record):
                if !seen.insert(record.signature).inserted {
                    duplicates.append(rowNumber)
                }
                validated.append((record, rowNumber))
            case .rejected(let reason):
                rejected.append(.init(rowNumber: rowNumber, reason: reason))
            }
        }

        let rowsRead = max(0, workbook.rows.count - 1)
        let ingestedAt = Date()
        let recordsToInsert = validated // immutable copy for the @Sendable transaction closure

        let newDatasetID = try await db.transaction { tx -> UUID in
            // Supersede any current active dataset BEFORE inserting the new one,
            // so the partial unique index never sees two active rows.
            let actives = try await Dataset.query(on: tx)
                .filter(\.$status == DatasetStatus.active)
                .all()
            for dataset in actives {
                dataset.status = DatasetStatus.superseded
                try await dataset.save(on: tx)
            }

            let dataset = Dataset(
                ingestedAt: ingestedAt,
                status: DatasetStatus.active,
                sourceFile: sourceName,
                rowsRead: rowsRead
            )
            try await dataset.create(on: tx)
            let datasetID = try dataset.requireID()

            for entry in recordsToInsert {
                let record = SalaryRecord(
                    datasetID: datasetID,
                    positionTitle: entry.record.positionTitle,
                    institution: entry.record.institution,
                    salaryAmount: entry.record.salaryAmount,
                    sourceRowNumber: entry.rowNumber,
                    extraFields: entry.record.extraFields
                )
                try await record.create(on: tx)
            }
            return datasetID
        }

        // Post-commit cleanup: superseded datasets (and their records) are gone.
        try await Dataset.query(on: db)
            .filter(\.$status == DatasetStatus.superseded)
            .delete()

        return IngestionReport(
            datasetId: newDatasetID,
            ingestedAt: ingestedAt,
            rowsRead: rowsRead,
            recordsPublished: validated.count,
            rejectedRows: rejected,
            duplicateRowNumbers: duplicates
        )
    }
}
