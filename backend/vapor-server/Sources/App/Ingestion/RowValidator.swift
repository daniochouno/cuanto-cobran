import Foundation
import XLSXReader

/// A row that passed validation and is ready to publish.
struct ValidatedRecord: Sendable {
    let positionTitle: String
    let institution: String
    let salaryAmount: Double
    let extraFields: [LabeledValue]

    /// Stable signature for duplicate detection.
    var signature: String {
        let extras = extraFields.map { "\($0.label)=\($0.value)" }.joined(separator: "|")
        return "\(positionTitle)|\(institution)|\(salaryAmount)|\(extras)"
    }
}

/// Outcome of validating a single data row.
enum RowOutcome: Sendable {
    case valid(ValidatedRecord)
    case rejected(reason: String)
}

/// Rejection reason codes (must match contracts/openapi.yaml).
enum RejectionReason {
    static let missingField = "MISSING_MANDATORY_FIELD"
    static let invalidSalary = "INVALID_SALARY_AMOUNT"
}

/// Validates a worksheet row against the column mapping: mandatory fields must be
/// present, the salary must be a non-negative number (accepting Spanish-formatted
/// numeric strings such as `70.508,52`).
enum RowValidator {

    static func validate(row: [XLSXCellValue], mapping: ColumnMapping) -> RowOutcome {
        let position = cellString(row, mapping.positionTitleIndex)
        let institution = cellString(row, mapping.institutionIndex)

        guard !position.isEmpty, !institution.isEmpty else {
            return .rejected(reason: RejectionReason.missingField)
        }

        guard let salary = parseSalary(cell(row, mapping.salaryIndex)), salary >= 0 else {
            return .rejected(reason: RejectionReason.invalidSalary)
        }

        let extras = mapping.extraColumns.map { column in
            LabeledValue(label: column.label, value: CellJSON(cell(row, column.index)))
        }

        return .valid(ValidatedRecord(
            positionTitle: position,
            institution: institution,
            salaryAmount: salary,
            extraFields: extras
        ))
    }

    private static func cell(_ row: [XLSXCellValue], _ index: Int) -> XLSXCellValue {
        index >= 0 && index < row.count ? row[index] : .empty
    }

    private static func cellString(_ row: [XLSXCellValue], _ index: Int) -> String {
        cell(row, index).stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parse a salary cell: numeric cells pass through; strings are interpreted as
    /// Spanish-formatted numbers ("." thousands, "," decimal), tolerating a "€".
    static func parseSalary(_ cell: XLSXCellValue) -> Double? {
        switch cell {
        case .number(let value):
            return value
        case .empty:
            return nil
        case .string(let raw):
            var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            text = text.replacingOccurrences(of: "€", with: "")
            text = text.replacingOccurrences(of: " ", with: "")
            guard !text.isEmpty else { return nil }
            // Spanish format: remove thousands separators ".", use "," as decimal.
            if text.contains(",") {
                text = text.replacingOccurrences(of: ".", with: "")
                text = text.replacingOccurrences(of: ",", with: ".")
            }
            return Double(text)
        }
    }
}
