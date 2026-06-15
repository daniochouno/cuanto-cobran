import XCTest
import XLSXReader
@testable import App

final class ColumnMapperTests: XCTestCase {

    private func header(_ titles: [String]) -> [XLSXCellValue] {
        titles.map { .string($0) }
    }

    func testMapsRealHeaderAndPreservesExtras() throws {
        let mapping = try ColumnMapper.map(header: header([
            "Alto Cargo", "Organismo", "Ministerio", "Retribución (€)", "Año"
        ]))
        XCTAssertEqual(mapping.positionTitleIndex, 0)
        XCTAssertEqual(mapping.institutionIndex, 1)
        XCTAssertEqual(mapping.salaryIndex, 3)
        // Ministerio (2) and Año (4) are non-mandatory extras, in file order.
        XCTAssertEqual(mapping.extraColumns.map(\.index), [2, 4])
        XCTAssertEqual(mapping.extraColumns.map(\.label), ["Ministerio", "Año"])
    }

    func testInstitutionPrefersOrganismoOverMinisterio() throws {
        // Both "organismo" and "ministerio" are institution aliases; organismo wins.
        let mapping = try ColumnMapper.map(header: header(["Ministerio", "Organismo", "Cargo", "Retribución"]))
        XCTAssertEqual(mapping.institutionIndex, 1)
        XCTAssertEqual(mapping.positionTitleIndex, 2)
    }

    func testMissingMandatoryColumnThrows() {
        XCTAssertThrowsError(try ColumnMapper.map(header: header(["Cargo", "Organismo"]))) { error in
            guard let apiError = error as? ApiError else { return XCTFail("expected ApiError") }
            XCTAssertEqual(apiError.code, "MISSING_REQUIRED_COLUMNS")
        }
    }

    func testNormalizeStripsAccentsAndSymbols() {
        XCTAssertEqual(ColumnMapper.normalize("Retribución (€)"), "retribucion")
        XCTAssertEqual(ColumnMapper.normalize("  ALTO   Cargo "), "alto cargo")
    }
}
