import Foundation

/// A single cell value extracted from a worksheet.
public enum XLSXCellValue: Equatable, Sendable {
    case string(String)
    case number(Double)
    case empty

    /// The cell rendered as text (numbers use a minimal, locale-independent form).
    public var stringValue: String {
        switch self {
        case .string(let s): return s
        case .number(let n):
            if n == n.rounded() && abs(n) < 1e15 {
                return String(Int64(n))
            }
            return String(n)
        case .empty:
            return ""
        }
    }
}

/// Reads an `.xlsx` (OOXML) workbook and exposes its first worksheet as rows of
/// cell values. Custom-built (ZIP + DEFLATE + SpreadsheetML) with no third-party
/// dependencies, per Constitution Principle V and research decision R1.
public struct XLSXWorkbook: Sendable {

    /// All rows of the first worksheet, in document order. `rows[0]` is the header.
    public let rows: [[XLSXCellValue]]

    /// The header row (first row), or an empty array if the sheet is empty.
    public var headerRow: [XLSXCellValue] {
        rows.first ?? []
    }

    /// Data rows (everything after the header).
    public var dataRows: ArraySlice<[XLSXCellValue]> {
        rows.count > 1 ? rows[1...] : [][...]
    }

    /// Parse a workbook from in-memory `.xlsx` bytes.
    public init(data: Data) throws {
        let archive = try ZIPArchive([UInt8](data))

        let sharedStrings: [String]
        if archive.contains("xl/sharedStrings.xml") {
            sharedStrings = try SpreadsheetML.parseSharedStrings(try archive.readString("xl/sharedStrings.xml"))
        } else {
            sharedStrings = []
        }

        guard archive.contains("xl/workbook.xml") else {
            throw XLSXError.noWorksheet
        }
        let workbookXML = try archive.readString("xl/workbook.xml")
        let relsXML = archive.contains("xl/_rels/workbook.xml.rels")
            ? try archive.readString("xl/_rels/workbook.xml.rels")
            : ""

        let sheetPath = SpreadsheetML.firstWorksheetPath(
            workbookXML: workbookXML,
            relsXML: relsXML,
            archive: archive
        )
        guard archive.contains(sheetPath) else {
            throw XLSXError.noWorksheet
        }

        let worksheetXML = try archive.readString(sheetPath)
        self.rows = try SpreadsheetML.parseWorksheet(worksheetXML, sharedStrings: sharedStrings)
    }

    /// Parse a workbook from a file URL.
    public init(contentsOf url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
}
