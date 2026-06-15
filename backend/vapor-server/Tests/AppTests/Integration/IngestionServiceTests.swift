import XCTVapor
import Fluent
@testable import App

final class IngestionServiceTests: XCTestCase {

    func testIngestPublishesRealFileAndBalancesReport() async throws {
        try await withApp { app in
            let report = try await IngestionService().ingest(
                fileURL: URL(fileURLWithPath: try fixtureXLSXPath()),
                sourceName: "Retribuciones.xlsx",
                on: app.db
            )
            // Real file: 320 data rows, all valid.
            XCTAssertEqual(report.rowsRead, 320)
            XCTAssertEqual(report.recordsPublished + report.rejectedRows.count, report.rowsRead)
            XCTAssertEqual(report.recordsPublished, 320)

            let datasets = try await Dataset.query(on: app.db).all()
            XCTAssertEqual(datasets.count, 1)
            XCTAssertEqual(datasets.first?.status, DatasetStatus.active)

            let count = try await SalaryRecord.query(on: app.db).count()
            XCTAssertEqual(count, 320)
        }
    }

    func testSecondIngestAtomicallyReplacesAndLeavesOneActive() async throws {
        try await withApp { app in
            let service = IngestionService()
            let path = try fixtureXLSXPath()
            _ = try await service.ingest(fileURL: URL(fileURLWithPath: path), sourceName: "Retribuciones.xlsx", on: app.db)
            let second = try await service.ingest(fileURL: URL(fileURLWithPath: path), sourceName: "Retribuciones.xlsx", on: app.db)

            // Exactly one active dataset remains; superseded ones were cleaned up.
            let datasets = try await Dataset.query(on: app.db).all()
            XCTAssertEqual(datasets.count, 1)
            XCTAssertEqual(datasets.first?.id, second.datasetId)
            XCTAssertEqual(datasets.first?.status, DatasetStatus.active)

            // No orphaned records from the superseded dataset (cascade delete).
            let count = try await SalaryRecord.query(on: app.db).count()
            XCTAssertEqual(count, 320)
        }
    }

    func testInvalidFileThrowsAndLeavesDatasetUnchanged() async throws {
        try await withApp { app in
            // Publish a good dataset first.
            _ = try await IngestionService().ingest(
                fileURL: URL(fileURLWithPath: try fixtureXLSXPath()),
                sourceName: "Retribuciones.xlsx",
                on: app.db
            )
            // Attempt to ingest a non-xlsx file.
            let badURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("bad.xlsx")
            try Data("not a zip".utf8).write(to: badURL)
            defer { try? FileManager.default.removeItem(at: badURL) }

            do {
                _ = try await IngestionService().ingest(fileURL: badURL, sourceName: "bad.xlsx", on: app.db)
                XCTFail("expected ApiError.invalidFile")
            } catch let error as ApiError {
                XCTAssertEqual(error.code, "INVALID_FILE")
            }

            // Previous dataset still intact.
            let count = try await SalaryRecord.query(on: app.db).count()
            XCTAssertEqual(count, 320)
        }
    }
}
