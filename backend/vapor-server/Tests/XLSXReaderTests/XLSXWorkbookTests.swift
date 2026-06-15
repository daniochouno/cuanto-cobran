import XCTest
@testable import XLSXReader

final class XLSXWorkbookTests: XCTestCase {

    private func loadWorkbook() throws -> XLSXWorkbook {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "Retribuciones", withExtension: "xlsx"),
            "Retribuciones.xlsx fixture missing from test bundle"
        )
        return try XLSXWorkbook(contentsOf: url)
    }

    func testParsesAllRows() throws {
        let workbook = try loadWorkbook()
        // 1 header row + 320 data rows in the real file.
        XCTAssertEqual(workbook.rows.count, 321)
    }

    func testHeaderRowResolvesSharedStrings() throws {
        let workbook = try loadWorkbook()
        XCTAssertEqual(
            workbook.headerRow,
            [
                .string("Alto Cargo"),
                .string("Organismo"),
                .string("Ministerio"),
                .string("Retribución (€)"),
                .string("Año")
            ]
        )
    }

    func testFirstDataRowMixesStringsAndNumbers() throws {
        let workbook = try loadWorkbook()
        let row = try XCTUnwrap(workbook.dataRows.first)
        XCTAssertEqual(row[0], .string("PRESIDENTE DEL GOBIERNO"))
        XCTAssertEqual(row[1], .string("Presidencia del Gobierno"))
        XCTAssertEqual(row[2], .string("Presidencia del Gobierno"))
        XCTAssertEqual(row[3], .number(95943.96))
        XCTAssertEqual(row[4], .string("2025"))
    }

    func testNumberCellRendersAsText() throws {
        let workbook = try loadWorkbook()
        let row = try XCTUnwrap(workbook.dataRows.first)
        XCTAssertEqual(row[3].stringValue, "95943.96")
    }

    func testNonXlsxDataThrows() {
        XCTAssertThrowsError(try XLSXWorkbook(data: Data("plain text".utf8)))
    }
}
