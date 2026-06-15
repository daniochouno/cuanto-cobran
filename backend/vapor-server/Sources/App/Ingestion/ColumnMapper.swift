import Foundation
import XLSXReader

/// Where each logical field lives within a worksheet's columns, plus the
/// remaining (non-mandatory) columns to preserve in order.
struct ColumnMapping: Sendable {
    let positionTitleIndex: Int
    let institutionIndex: Int
    let salaryIndex: Int
    let extraColumns: [ExtraColumn]

    struct ExtraColumn: Sendable {
        let index: Int
        let label: String
    }
}

/// Maps a header row to mandatory fields using accent/case-insensitive alias
/// matching (research.md R10). Unmatched columns are preserved as extras in file
/// order. Throws `ApiError.missingRequiredColumns` if a mandatory column is absent.
enum ColumnMapper {

    private static let positionAliases = ["alto cargo", "cargo", "puesto", "denominacion del puesto", "denominacion"]
    private static let institutionAliases = ["organismo", "institucion", "entidad", "departamento", "ministerio"]
    private static let salaryAliases = ["retribucion", "retribuciones", "retribucion anual", "total anual", "sueldo", "importe"]

    static func map(header: [XLSXCellValue]) throws -> ColumnMapping {
        let normalized = header.map { normalize($0.stringValue) }

        var taken = Set<Int>()
        // Assign the first not-yet-taken column whose normalized header matches an
        // alias, trying aliases in priority order.
        func assign(_ aliases: [String]) -> Int? {
            for alias in aliases {
                for (i, value) in normalized.enumerated() where value == alias && !taken.contains(i) {
                    taken.insert(i)
                    return i
                }
            }
            return nil
        }

        let position = assign(positionAliases)
        let institution = assign(institutionAliases)
        let salary = assign(salaryAliases)

        var missing: [String] = []
        if position == nil { missing.append("cargo") }
        if institution == nil { missing.append("organismo") }
        if salary == nil { missing.append("retribución") }
        guard let positionIndex = position, let institutionIndex = institution, let salaryIndex = salary else {
            throw ApiError.missingRequiredColumns(missing)
        }

        let mandatory: Set<Int> = [positionIndex, institutionIndex, salaryIndex]
        let extras = header.enumerated().compactMap { index, cell -> ColumnMapping.ExtraColumn? in
            guard !mandatory.contains(index) else { return nil }
            let label = cell.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else { return nil }
            return ColumnMapping.ExtraColumn(index: index, label: label)
        }

        return ColumnMapping(
            positionTitleIndex: positionIndex,
            institutionIndex: institutionIndex,
            salaryIndex: salaryIndex,
            extraColumns: extras
        )
    }

    /// Lowercase, strip accents, drop non-alphanumeric characters, collapse spaces.
    static func normalize(_ raw: String) -> String {
        let folded = raw.folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES")).lowercased()
        var result = ""
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
            } else {
                result.append(" ")
            }
        }
        return result.split(separator: " ").joined(separator: " ")
    }
}
