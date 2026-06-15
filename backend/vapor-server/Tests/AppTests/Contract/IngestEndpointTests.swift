import XCTVapor
@testable import App

final class IngestEndpointTests: XCTestCase {

    func testIngestReturnsBalancedReport() async throws {
        try await withApp { app in
            setenv("INGEST_FILE_PATH", try fixtureXLSXPath(), 1)
            defer { unsetenv("INGEST_FILE_PATH") }

            try await app.test(.POST, "api/v1/admin/ingest", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let report = try res.content.decode(IngestionReport.self)
                XCTAssertEqual(report.rowsRead, 320)
                XCTAssertEqual(report.recordsPublished, 320)
                XCTAssertEqual(report.recordsPublished + report.rejectedRows.count, report.rowsRead)
            })
        }
    }

    func testIngestMissingFileReturns404() async throws {
        try await withApp { app in
            setenv("INGEST_FILE_PATH", "/tmp/does-not-exist-\(UUID().uuidString).xlsx", 1)
            defer { unsetenv("INGEST_FILE_PATH") }

            try await app.test(.POST, "api/v1/admin/ingest", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
                let error = try res.content.decode(ApiErrorBody.self)
                XCTAssertEqual(error.code, "FILE_NOT_FOUND")
            })
        }
    }

    func testIngestInvalidFileReturns422() async throws {
        try await withApp { app in
            let badURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("bad-\(UUID().uuidString).xlsx")
            try Data("not a real xlsx".utf8).write(to: badURL)
            defer { try? FileManager.default.removeItem(at: badURL) }
            setenv("INGEST_FILE_PATH", badURL.path, 1)
            defer { unsetenv("INGEST_FILE_PATH") }

            try await app.test(.POST, "api/v1/admin/ingest", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unprocessableEntity)
                let error = try res.content.decode(ApiErrorBody.self)
                XCTAssertEqual(error.code, "INVALID_FILE")
            })
        }
    }
}
