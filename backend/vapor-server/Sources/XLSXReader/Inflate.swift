import Foundation

/// A custom, self-contained DEFLATE (RFC 1951) inflate decoder.
///
/// Implemented from scratch to keep the backend free of third-party
/// decompression dependencies (Constitution Principle V). The canonical-Huffman
/// decode follows the approach in zlib's reference `puff.c`.
enum Inflate {

    /// Inflate a raw DEFLATE stream (no zlib/gzip wrapper).
    static func inflate(_ input: [UInt8]) throws -> [UInt8] {
        var reader = BitReader(input)
        var out: [UInt8] = []
        out.reserveCapacity(input.count * 4)

        while true {
            let bfinal = try reader.bits(1)
            let btype = try reader.bits(2)
            switch btype {
            case 0:
                try inflateStored(&reader, &out)
            case 1:
                try inflateBlock(&reader, &out, litlen: Huffman.fixedLitLen, dist: Huffman.fixedDist)
            case 2:
                let (litlen, dist) = try readDynamicTables(&reader)
                try inflateBlock(&reader, &out, litlen: litlen, dist: dist)
            default:
                throw XLSXError.inflateFailed("invalid block type 3")
            }
            if bfinal == 1 { break }
        }
        return out
    }

    // MARK: - Block types

    private static func inflateStored(_ reader: inout BitReader, _ out: inout [UInt8]) throws {
        reader.alignToByte()
        let len = Int(try reader.byte()) | (Int(try reader.byte()) << 8)
        let nlen = Int(try reader.byte()) | (Int(try reader.byte()) << 8)
        guard (len ^ 0xFFFF) == nlen else {
            throw XLSXError.inflateFailed("stored block length check failed")
        }
        for _ in 0..<len {
            out.append(try reader.byte())
        }
    }

    private static func inflateBlock(
        _ reader: inout BitReader,
        _ out: inout [UInt8],
        litlen: Huffman,
        dist: Huffman
    ) throws {
        while true {
            let sym = try litlen.decode(&reader)
            if sym == 256 { return }           // end of block
            if sym < 256 {
                out.append(UInt8(sym))
                continue
            }
            // length/distance back-reference
            let li = sym - 257
            guard li < Inflate.lengthBase.count else {
                throw XLSXError.inflateFailed("invalid length symbol \(sym)")
            }
            let length = Inflate.lengthBase[li] + (try reader.bits(Inflate.lengthExtra[li]))
            let dsym = try dist.decode(&reader)
            guard dsym < Inflate.distBase.count else {
                throw XLSXError.inflateFailed("invalid distance symbol \(dsym)")
            }
            let distance = Inflate.distBase[dsym] + (try reader.bits(Inflate.distExtra[dsym]))
            guard distance <= out.count else {
                throw XLSXError.inflateFailed("distance \(distance) beyond output")
            }
            let start = out.count - distance
            for i in 0..<length {
                out.append(out[start + i])     // valid even when distance < length (LZ77 overlap)
            }
        }
    }

    // MARK: - Dynamic Huffman tables

    private static let codeLengthOrder = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]

    private static func readDynamicTables(_ reader: inout BitReader) throws -> (Huffman, Huffman) {
        let hlit = (try reader.bits(5)) + 257
        let hdist = (try reader.bits(5)) + 1
        let hclen = (try reader.bits(4)) + 4

        var clLengths = [Int](repeating: 0, count: 19)
        for i in 0..<hclen {
            clLengths[codeLengthOrder[i]] = try reader.bits(3)
        }
        let clTree = try Huffman(lengths: clLengths)

        var lengths = [Int]()
        lengths.reserveCapacity(hlit + hdist)
        while lengths.count < hlit + hdist {
            let sym = try clTree.decode(&reader)
            switch sym {
            case 0...15:
                lengths.append(sym)
            case 16:
                guard let prev = lengths.last else {
                    throw XLSXError.inflateFailed("repeat code 16 with no previous length")
                }
                let repeatCount = 3 + (try reader.bits(2))
                lengths.append(contentsOf: Array(repeating: prev, count: repeatCount))
            case 17:
                let repeatCount = 3 + (try reader.bits(3))
                lengths.append(contentsOf: Array(repeating: 0, count: repeatCount))
            case 18:
                let repeatCount = 11 + (try reader.bits(7))
                lengths.append(contentsOf: Array(repeating: 0, count: repeatCount))
            default:
                throw XLSXError.inflateFailed("invalid code-length symbol \(sym)")
            }
        }
        guard lengths.count == hlit + hdist else {
            throw XLSXError.inflateFailed("code-length sequence overran")
        }
        let litlen = try Huffman(lengths: Array(lengths[0..<hlit]))
        let dist = try Huffman(lengths: Array(lengths[hlit..<(hlit + hdist)]))
        return (litlen, dist)
    }

    // MARK: - RFC 1951 length/distance tables

    static let lengthBase = [
        3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
        35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
    ]
    static let lengthExtra = [
        0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
        3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
    ]
    static let distBase = [
        1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
        257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
    ]
    static let distExtra = [
        0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
        7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
    ]
}

// MARK: - Bit reader (LSB-first)

/// Reads bits least-significant-bit first, as DEFLATE requires.
struct BitReader {
    private let data: [UInt8]
    private var bytePos = 0
    private var bitBuffer: UInt32 = 0
    private var bitCount = 0

    init(_ data: [UInt8]) {
        self.data = data
    }

    /// Read `n` bits (0...24) as an integer, LSB first.
    mutating func bits(_ n: Int) throws -> Int {
        if n == 0 { return 0 }
        while bitCount < n {
            guard bytePos < data.count else {
                throw XLSXError.inflateFailed("unexpected end of DEFLATE stream")
            }
            bitBuffer |= UInt32(data[bytePos]) << bitCount
            bytePos += 1
            bitCount += 8
        }
        let value = Int(bitBuffer & ((1 << UInt32(n)) - 1))
        bitBuffer >>= UInt32(n)
        bitCount -= n
        return value
    }

    /// Discard buffered bits down to the next byte boundary.
    mutating func alignToByte() {
        let drop = bitCount % 8
        bitBuffer >>= UInt32(drop)
        bitCount -= drop
    }

    /// Read one whole byte, draining any buffered whole bytes first.
    mutating func byte() throws -> UInt8 {
        if bitCount >= 8 {
            let b = UInt8(bitBuffer & 0xFF)
            bitBuffer >>= 8
            bitCount -= 8
            return b
        }
        guard bytePos < data.count else {
            throw XLSXError.inflateFailed("unexpected end of stored block")
        }
        let b = data[bytePos]
        bytePos += 1
        return b
    }
}

// MARK: - Canonical Huffman decoding

/// A canonical Huffman decoder built from a list of code lengths.
struct Huffman {
    /// `count[len]` = number of codes of bit length `len` (index 0 unused).
    private let count: [Int]
    /// Symbols ordered by (length, symbol value).
    private let symbol: [Int]

    private static let maxBits = 15

    init(lengths: [Int]) throws {
        var count = [Int](repeating: 0, count: Huffman.maxBits + 1)
        for length in lengths where length > 0 {
            guard length <= Huffman.maxBits else {
                throw XLSXError.inflateFailed("code length \(length) exceeds 15")
            }
            count[length] += 1
        }

        // Offsets of the first symbol of each length within `symbol`.
        var offsets = [Int](repeating: 0, count: Huffman.maxBits + 2)
        for length in 1...Huffman.maxBits {
            offsets[length + 1] = offsets[length] + count[length]
        }

        var symbol = [Int](repeating: 0, count: lengths.count)
        for (sym, length) in lengths.enumerated() where length > 0 {
            symbol[offsets[length]] = sym
            offsets[length] += 1
        }

        self.count = count
        self.symbol = symbol
    }

    /// Decode the next symbol from the bit stream.
    func decode(_ reader: inout BitReader) throws -> Int {
        var code = 0
        var first = 0
        var index = 0
        for length in 1...Huffman.maxBits {
            code |= try reader.bits(1)
            let countAtLength = count[length]
            if code - first < countAtLength {
                return symbol[index + (code - first)]
            }
            index += countAtLength
            first += countAtLength
            first <<= 1
            code <<= 1
        }
        throw XLSXError.inflateFailed("invalid Huffman code")
    }

    // MARK: Fixed tables (RFC 1951 §3.2.6)

    static let fixedLitLen: Huffman = {
        var lengths = [Int](repeating: 0, count: 288)
        for i in 0...143 { lengths[i] = 8 }
        for i in 144...255 { lengths[i] = 9 }
        for i in 256...279 { lengths[i] = 7 }
        for i in 280...287 { lengths[i] = 8 }
        return try! Huffman(lengths: lengths)
    }()

    static let fixedDist: Huffman = {
        let lengths = [Int](repeating: 5, count: 30)
        return try! Huffman(lengths: lengths)
    }()
}
