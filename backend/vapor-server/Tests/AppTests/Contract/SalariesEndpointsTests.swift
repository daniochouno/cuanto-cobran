import XCTVapor
@testable import App

final class SalariesEndpointsTests: XCTestCase {

    /// Ingest the fixture via the service so endpoint tests have data.
    private func seed(_ app: Application) async throws {
        _ = try await IngestionService().ingest(
            fileURL: URL(fileURLWithPath: try fixtureXLSXPath()),
            sourceName: "Retribuciones.xlsx",
            on: app.db
        )
    }

    func testHealthReturnsOk() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/health", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                XCTAssertTrue(res.body.string.contains("\"status\""))
                XCTAssertTrue(res.body.string.contains("ok"))
            })
        }
    }

    func testListEmptyWhenNothingPublished() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/salaries", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let response = try res.content.decode(SalaryListResponse.self)
                XCTAssertNil(response.dataset)
                XCTAssertTrue(response.items.isEmpty)
            })
        }
    }

    func testListReturnsKeyFieldsAfterIngest() async throws {
        try await withApp { app in
            try await seed(app)
            try await app.test(.GET, "api/v1/salaries", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let response = try res.content.decode(SalaryListResponse.self)
                XCTAssertNotNil(response.dataset)
                XCTAssertEqual(response.items.count, 320)
                // Ordered by source row: first record is the President.
                XCTAssertEqual(response.items.first?.positionTitle, "PRESIDENTE DEL GOBIERNO")
                XCTAssertEqual(response.items.first?.salaryAmount, 95943.96)
            })
        }
    }

    func testDetailReturnsAllFields() async throws {
        try await withApp { app in
            try await seed(app)
            // Get an id from the list, then fetch its detail.
            var firstID: UUID?
            try await app.test(.GET, "api/v1/salaries", afterResponse: { res async throws in
                let response = try res.content.decode(SalaryListResponse.self)
                firstID = response.items.first?.id
            })
            let id = try XCTUnwrap(firstID)
            try await app.test(.GET, "api/v1/salaries/\(id)", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let response = try res.content.decode(SalaryDetailResponse.self)
                XCTAssertEqual(response.record.id, id)
                XCTAssertEqual(response.record.sourceRowNumber, 2)
                // Extra columns (Ministerio, Año) preserved with original labels.
                XCTAssertEqual(response.record.extraFields.map(\.label), ["Ministerio", "Año"])
            })
        }
    }

    func testDetailUnknownIdReturns404() async throws {
        try await withApp { app in
            try await seed(app)
            try await app.test(.GET, "api/v1/salaries/00000000-0000-0000-0000-000000000000", afterResponse: { res async throws in
                XCTAssertEqual(res.status, .notFound)
                let error = try res.content.decode(ApiErrorBody.self)
                XCTAssertEqual(error.code, "RECORD_NOT_AVAILABLE")
            })
        }
    }
}
