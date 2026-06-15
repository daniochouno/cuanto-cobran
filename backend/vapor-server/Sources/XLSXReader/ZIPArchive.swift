import Foundation

/// A minimal read-only ZIP container reader.
///
/// Parses the End Of Central Directory record and the central directory, and
/// extracts individual entries (stored or DEFLATE-compressed). Scoped to what an
/// `.xlsx` package needs — no ZIP64, encryption, or spanning support.
struct ZIPArchive {

    private struct Entry {
        let method: UInt16
        let compressedSize: Int
        let localHeaderOffset: Int
    }

    private let data: [UInt8]
    private let entries: [String: Entry]

    private static let eocdSignature: UInt32 = 0x0605_4b50
    private static let centralSignature: UInt32 = 0x0201_4b50
    private static let localSignature: UInt32 = 0x0403_4b50

    init(_ bytes: [UInt8]) throws {
        self.data = bytes
        self.entries = try ZIPArchive.readCentralDirectory(bytes)
    }

    /// The names of all entries in the archive.
    var entryNames: [String] { Array(entries.keys) }

    /// Returns true if an entry with `name` exists.
    func contains(_ name: String) -> Bool { entries[name] != nil }

    /// Read and decompress the entry named `name`.
    func read(_ name: String) throws -> [UInt8] {
        guard let entry = entries[name] else {
            throw XLSXError.entryNotFound(name)
        }
        let dataStart = try localDataOffset(entry)
        guard dataStart + entry.compressedSize <= data.count else {
            throw XLSXError.corruptArchive("entry \(name) data exceeds archive bounds")
        }
        let compressed = Array(data[dataStart..<(dataStart + entry.compressedSize)])
        switch entry.method {
        case 0:
            return compressed
        case 8:
            return try Inflate.inflate(compressed)
        default:
            throw XLSXError.unsupportedCompression(entry.method)
        }
    }

    /// Read an entry and decode it as UTF-8 text.
    func readString(_ name: String) throws -> String {
        let bytes = try read(name)
        guard let s = String(bytes: bytes, encoding: .utf8) else {
            throw XLSXError.malformedXML("entry \(name) is not valid UTF-8")
        }
        return s
    }

    // MARK: - Central directory

    private static func readCentralDirectory(_ data: [UInt8]) throws -> [String: Entry] {
        let eocd = try findEOCD(data)
        let cdCount = Int(readU16(data, eocd + 10))
        let cdOffset = Int(readU32(data, eocd + 16))

        var entries: [String: Entry] = [:]
        var pos = cdOffset
        for _ in 0..<cdCount {
            guard pos + 46 <= data.count, readU32(data, pos) == centralSignature else {
                throw XLSXError.corruptArchive("bad central directory header")
            }
            let method = readU16(data, pos + 10)
            let compressedSize = Int(readU32(data, pos + 20))
            let nameLen = Int(readU16(data, pos + 28))
            let extraLen = Int(readU16(data, pos + 30))
            let commentLen = Int(readU16(data, pos + 32))
            let localOffset = Int(readU32(data, pos + 42))
            let nameStart = pos + 46
            guard nameStart + nameLen <= data.count else {
                throw XLSXError.corruptArchive("central directory name overruns archive")
            }
            let name = String(bytes: data[nameStart..<(nameStart + nameLen)], encoding: .utf8) ?? ""
            entries[name] = Entry(method: method, compressedSize: compressedSize, localHeaderOffset: localOffset)
            pos = nameStart + nameLen + extraLen + commentLen
        }
        return entries
    }

    /// Compute where an entry's compressed data begins, reading its local header.
    private func localDataOffset(_ entry: Entry) throws -> Int {
        let p = entry.localHeaderOffset
        guard p + 30 <= data.count, ZIPArchive.readU32(data, p) == ZIPArchive.localSignature else {
            throw XLSXError.corruptArchive("bad local file header")
        }
        let nameLen = Int(ZIPArchive.readU16(data, p + 26))
        let extraLen = Int(ZIPArchive.readU16(data, p + 28))
        return p + 30 + nameLen + extraLen
    }

    /// Scan backward for the End Of Central Directory signature.
    private static func findEOCD(_ data: [UInt8]) throws -> Int {
        guard data.count >= 22 else { throw XLSXError.notAZipArchive }
        // The EOCD is 22 bytes plus an optional comment (max 65535).
        let minPos = max(0, data.count - 22 - 0xFFFF)
        var pos = data.count - 22
        while pos >= minPos {
            if readU32(data, pos) == eocdSignature {
                return pos
            }
            pos -= 1
        }
        throw XLSXError.notAZipArchive
    }

    // MARK: - Little-endian readers

    private static func readU16(_ data: [UInt8], _ offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readU32(_ data: [UInt8], _ offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
