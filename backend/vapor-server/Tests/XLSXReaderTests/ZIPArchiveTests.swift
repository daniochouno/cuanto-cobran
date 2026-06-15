import XCTest
@testable import XLSXReader

final class ZIPArchiveTests: XCTestCase {

    private func fixtureBytes() throws -> [UInt8] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "Retribuciones", withExtension: "xlsx"),
            "Retribuciones.xlsx fixture missing from test bundle"
        )
        return try [UInt8](Data(contentsOf: url))
    }

    func testReadsCentralDirectoryEntries() throws {
        let archive = try ZIPArchive(fixtureBytes())
        XCTAssertTrue(archive.contains("xl/workbook.xml"))
        XCTAssertTrue(archive.contains("xl/sharedStrings.xml"))
        XCTAssertTrue(archive.contains("xl/worksheets/sheet1.xml"))
        XCTAssertTrue(archive.contains("[Content_Types].xml"))
    }

    func testInflatesDeflatedEntryToValidXML() throws {
        let archive = try ZIPArchive(fixtureBytes())
        let workbook = try archive.readString("xl/workbook.xml")
        XCTAssertTrue(workbook.contains("<sheet"))
        XCTAssertTrue(workbook.contains("HOJA1"))
    }

    func testUnknownEntryThrows() throws {
        let archive = try ZIPArchive(fixtureBytes())
        XCTAssertThrowsError(try archive.read("nope.xml")) { error in
            XCTAssertEqual(error as? XLSXError, .entryNotFound("nope.xml"))
        }
    }

    func testNonZipDataThrows() {
        XCTAssertThrowsError(try ZIPArchive([UInt8]("not a zip file at all".utf8))) { error in
            XCTAssertEqual(error as? XLSXError, .notAZipArchive)
        }
    }
}
