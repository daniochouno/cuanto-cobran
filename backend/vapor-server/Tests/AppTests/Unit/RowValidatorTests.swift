import XCTest
import XLSXReader
@testable import App

final class RowValidatorTests: XCTestCase {

    // Mapping: position=0, institution=1, salary=2, extra=3 ("Año").
    private let mapping = ColumnMapping(
        positionTitleIndex: 0,
        institutionIndex: 1,
        salaryIndex: 2,
        extraColumns: [.init(index: 3, label: "Año")]
    )

    func testValidRowWithNumberSalary() {
        let row: [XLSXCellValue] = [.string("Presidente"), .string("Gobierno"), .number(95943.96), .string("2025")]
        guard case .valid(let record) = RowValidator.validate(row: row, mapping: mapping) else {
            return XCTFail("expected valid row")
        }
        XCTAssertEqual(record.positionTitle, "Presidente")
        XCTAssertEqual(record.institution, "Gobierno")
        XCTAssertEqual(record.salaryAmount, 95943.96)
        XCTAssertEqual(record.extraFields, [LabeledValue(label: "Año", value: .string("2025"))])
    }

    func testParsesSpanishFormattedSalaryString() {
        let row: [XLSXCellValue] = [.string("Cargo"), .string("Org"), .string("70.508,52 €"), .string("2025")]
        guard case .valid(let record) = RowValidator.validate(row: row, mapping: mapping) else {
            return XCTFail("expected valid row")
        }
        XCTAssertEqual(record.salaryAmount, 70508.52, accuracy: 0.001)
    }

    func testMissingMandatoryFieldRejected() {
        let row: [XLSXCellValue] = [.string("   "), .string("Org"), .number(1000), .empty]
        guard case .rejected(let reason) = RowValidator.validate(row: row, mapping: mapping) else {
            return XCTFail("expected rejection")
        }
        XCTAssertEqual(reason, RejectionReason.missingField)
    }

    func testInvalidSalaryRejected() {
        let row: [XLSXCellValue] = [.string("Cargo"), .string("Org"), .string("n/d"), .empty]
        guard case .rejected(let reason) = RowValidator.validate(row: row, mapping: mapping) else {
            return XCTFail("expected rejection")
        }
        XCTAssertEqual(reason, RejectionReason.invalidSalary)
    }

    func testNegativeSalaryRejected() {
        let row: [XLSXCellValue] = [.string("Cargo"), .string("Org"), .number(-5), .empty]
        guard case .rejected(let reason) = RowValidator.validate(row: row, mapping: mapping) else {
            return XCTFail("expected rejection")
        }
        XCTAssertEqual(reason, RejectionReason.invalidSalary)
    }
}
