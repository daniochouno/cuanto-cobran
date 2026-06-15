import XCTest
@testable import XLSXReader

final class InflateTests: XCTestCase {

    /// Raw DEFLATE stream (no zlib header) produced by zlib for the known string
    /// below. Exercises dynamic Huffman + LZ77 back-references (the repeated
    /// "Hello, DEFLATE! " forces a length/distance copy).
    func testInflateKnownVector() throws {
        let compressed: [UInt8] = [
            0xf3, 0x48, 0xcd, 0xc9, 0xc9, 0xd7, 0x51, 0x70, 0x71, 0x75, 0xf3, 0x71, 0x0c, 0x71, 0x55, 0x54,
            0xf0, 0x40, 0xe3, 0x87, 0x64, 0xa4, 0x2a, 0x14, 0x96, 0x66, 0x26, 0x67, 0x2b, 0x24, 0x15, 0xe5,
            0x97, 0xe7, 0x29, 0xa4, 0xe5, 0x57, 0x28, 0x64, 0x95, 0xe6, 0x16, 0x14, 0x2b, 0xe4, 0x97, 0xa5,
            0x16, 0x29, 0x94, 0x00, 0xa5, 0x73, 0x12, 0xab, 0x2a, 0x15, 0x52, 0xf2, 0xd3, 0xf5, 0x14, 0x0c,
            0x8d, 0x8c, 0x4d, 0x4c, 0xcd, 0xcc, 0x2d, 0x2c, 0x0d, 0xf4, 0x00
        ]
        let expected = "Hello, DEFLATE! Hello, DEFLATE! The quick brown fox jumps over the lazy dog. 1234567890."

        let inflated = try Inflate.inflate(compressed)
        XCTAssertEqual(String(bytes: inflated, encoding: .utf8), expected)
    }

    /// A stored (uncompressed) block: BFINAL=1, BTYPE=00, then LEN/NLEN + bytes.
    func testInflateStoredBlock() throws {
        let payload: [UInt8] = Array("ABCDE".utf8)
        var stream: [UInt8] = [0x01]                       // BFINAL=1, BTYPE=00 (LSB-first)
        let len = UInt16(payload.count)
        stream.append(UInt8(len & 0xFF))
        stream.append(UInt8(len >> 8))
        let nlen = ~len
        stream.append(UInt8(nlen & 0xFF))
        stream.append(UInt8(nlen >> 8))
        stream.append(contentsOf: payload)

        let inflated = try Inflate.inflate(stream)
        XCTAssertEqual(inflated, payload)
    }

    func testInflateRejectsTruncatedStream() {
        XCTAssertThrowsError(try Inflate.inflate([0xf3, 0x48])) { error in
            XCTAssertTrue(error is XLSXError)
        }
    }
}
