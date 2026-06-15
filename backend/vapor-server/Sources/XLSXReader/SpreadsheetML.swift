import Foundation

/// Parsers for the SpreadsheetML parts of an `.xlsx` package, built on
/// Foundation's first-party event-based `XMLParser` (Constitution Principle V:
/// no third-party XML dependency).
enum SpreadsheetML {

    /// Parse `xl/sharedStrings.xml` into an ordered string table.
    /// Each `<si>` may contain several `<t>` runs which are concatenated.
    static func parseSharedStrings(_ xml: String) throws -> [String] {
        let delegate = SharedStringsDelegate()
        try run(xml, delegate, context: "sharedStrings.xml")
        return delegate.strings
    }

    /// Resolve the first worksheet's part path (e.g. `xl/worksheets/sheet1.xml`)
    /// from `workbook.xml` + `workbook.xml.rels`, falling back to a direct lookup.
    static func firstWorksheetPath(workbookXML: String, relsXML: String, archive: ZIPArchive) -> String {
        let workbook = WorkbookDelegate()
        try? run(workbookXML, workbook, context: "workbook.xml")
        let rels = RelationshipsDelegate()
        try? run(relsXML, rels, context: "workbook.xml.rels")

        if let rid = workbook.firstSheetRID, var target = rels.targets[rid] {
            if !target.hasPrefix("/") {
                target = "xl/" + target
            } else {
                target.removeFirst()
            }
            if archive.contains(target) { return target }
        }
        // Fallback: first worksheet part by convention.
        if archive.contains("xl/worksheets/sheet1.xml") { return "xl/worksheets/sheet1.xml" }
        return archive.entryNames.first { $0.hasPrefix("xl/worksheets/") && $0.hasSuffix(".xml") }
            ?? "xl/worksheets/sheet1.xml"
    }

    /// Parse a worksheet part into rows of cells, resolving shared strings.
    static func parseWorksheet(_ xml: String, sharedStrings: [String]) throws -> [[XLSXCellValue]] {
        let delegate = WorksheetDelegate(sharedStrings: sharedStrings)
        try run(xml, delegate, context: "worksheet")
        return delegate.rows
    }

    private static func run(_ xml: String, _ delegate: XMLParserDelegate, context: String) throws {
        guard let data = xml.data(using: .utf8) else {
            throw XLSXError.malformedXML("\(context) is not valid UTF-8")
        }
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        if !parser.parse() {
            let reason = parser.parserError?.localizedDescription ?? "unknown error"
            throw XLSXError.malformedXML("\(context): \(reason)")
        }
    }

    /// Translate a cell reference's column letters (e.g. "AB12") to a 0-based index.
    static func columnIndex(fromCellRef ref: String) -> Int {
        var index = 0
        var found = false
        for ch in ref.utf8 {
            if ch >= 65 && ch <= 90 {           // 'A'...'Z'
                index = index * 26 + Int(ch - 64)
                found = true
            } else if ch >= 97 && ch <= 122 {   // 'a'...'z'
                index = index * 26 + Int(ch - 96)
                found = true
            } else {
                break
            }
        }
        return found ? index - 1 : 0
    }
}

// MARK: - sharedStrings.xml

private final class SharedStringsDelegate: NSObject, XMLParserDelegate {
    private(set) var strings: [String] = []
    private var inItem = false
    private var inText = false
    private var current = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        switch elementName {
        case "si":
            inItem = true
            current = ""
        case "t":
            inText = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inItem && inText { current += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        switch elementName {
        case "t":
            inText = false
        case "si":
            strings.append(current)
            inItem = false
        default:
            break
        }
    }
}

// MARK: - workbook.xml (first <sheet> r:id)

private final class WorkbookDelegate: NSObject, XMLParserDelegate {
    private(set) var firstSheetRID: String?

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        guard elementName == "sheet", firstSheetRID == nil else { return }
        firstSheetRID = attributeDict["r:id"] ?? attributeDict["id"]
    }
}

// MARK: - workbook.xml.rels (id -> target)

private final class RelationshipsDelegate: NSObject, XMLParserDelegate {
    private(set) var targets: [String: String] = [:]

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        guard elementName == "Relationship",
              let id = attributeDict["Id"], let target = attributeDict["Target"] else { return }
        targets[id] = target
    }
}

// MARK: - worksheet sheetData

private final class WorksheetDelegate: NSObject, XMLParserDelegate {
    private(set) var rows: [[XLSXCellValue]] = []

    private let sharedStrings: [String]

    private var currentRow: [Int: XLSXCellValue] = [:]
    private var maxColInRow = -1

    private var cellType = ""
    private var cellColumn = 0
    private var inValue = false
    private var inInlineString = false
    private var valueText = ""

    init(sharedStrings: [String]) {
        self.sharedStrings = sharedStrings
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        switch elementName {
        case "row":
            currentRow = [:]
            maxColInRow = -1
        case "c":
            cellType = attributeDict["t"] ?? ""
            if let ref = attributeDict["r"] {
                cellColumn = SpreadsheetML.columnIndex(fromCellRef: ref)
            } else {
                cellColumn = maxColInRow + 1
            }
            valueText = ""
        case "v":
            inValue = true
            valueText = ""
        case "t" where cellType == "inlineStr":
            inInlineString = true
            valueText = ""
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inValue || inInlineString { valueText += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        switch elementName {
        case "v":
            inValue = false
        case "t" where inInlineString:
            inInlineString = false
        case "c":
            currentRow[cellColumn] = resolveCell()
            maxColInRow = max(maxColInRow, cellColumn)
        case "row":
            rows.append(flattenRow())
        default:
            break
        }
    }

    private func resolveCell() -> XLSXCellValue {
        switch cellType {
        case "s":
            if let index = Int(valueText), index >= 0, index < sharedStrings.count {
                return .string(sharedStrings[index])
            }
            return .empty
        case "inlineStr", "str":
            return valueText.isEmpty ? .empty : .string(valueText)
        case "b":
            return .number(valueText == "1" ? 1 : 0)
        default:
            if valueText.isEmpty { return .empty }
            if let number = Double(valueText) { return .number(number) }
            return .string(valueText)
        }
    }

    private func flattenRow() -> [XLSXCellValue] {
        guard maxColInRow >= 0 else { return [] }
        var row = [XLSXCellValue](repeating: .empty, count: maxColInRow + 1)
        for (col, value) in currentRow where col <= maxColInRow {
            row[col] = value
        }
        return row
    }
}
