import Vapor
import XLSXReader

/// A JSON-encodable cell value: string, number, or null. Used for the ordered
/// `extraFields` of a record so non-mandatory columns are preserved verbatim.
enum CellJSON: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    init(_ cell: XLSXCellValue) {
        switch cell {
        case .string(let s): self = .string(s)
        case .number(let n): self = .number(n)
        case .empty: self = .null
        }
    }
}

/// A labelled cell value (original column header + its value).
struct LabeledValue: Content, Sendable, Equatable {
    let label: String
    let value: CellJSON
}

/// Wraps the ordered extra columns so Fluent stores them as a single `jsonb`
/// document rather than a Postgres `jsonb[]` array.
struct ExtraFields: Codable, Sendable, Equatable {
    var values: [LabeledValue]

    init(_ values: [LabeledValue]) {
        self.values = values
    }
}
