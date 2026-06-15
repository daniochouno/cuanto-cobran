import Foundation

/// Errors thrown while reading an `.xlsx` (OOXML) workbook.
///
/// The taxonomy lets the ingestion layer fail an unreadable or corrupt file as a
/// whole (FR-004) instead of publishing partial data.
public enum XLSXError: Error, Equatable, Sendable {
    /// The data does not contain a ZIP End Of Central Directory record.
    case notAZipArchive
    /// The ZIP structure is malformed (bad signature, truncated record, …).
    case corruptArchive(String)
    /// A required part (e.g. the worksheet) is absent from the archive.
    case entryNotFound(String)
    /// The entry uses a compression method other than stored (0) or deflate (8).
    case unsupportedCompression(UInt16)
    /// The DEFLATE stream could not be inflated.
    case inflateFailed(String)
    /// A required XML part could not be parsed.
    case malformedXML(String)
    /// The workbook contains no worksheet.
    case noWorksheet
}
