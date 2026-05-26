import Foundation
import Testing
@testable import TimeboxForThings3

@Suite("Things 3 Date Decoder")
struct Things3DateDecoderTests {

    @Test("Decode known date: 2026-03-30")
    func decodeKnownDate() {
        // 2026-03-30 encoded: (2026 << 16) | (3 << 12) | (30 << 7) = 132792064
        let encoded = 132792064
        let date = Things3DateDecoder.decode(encoded)
        #expect(date != nil)

        let components = Calendar.current.dateComponents([.year, .month, .day], from: date!)
        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 30)
    }

    @Test("Decode another date: 2021-03-28")
    func decodeAnotherDate() {
        // From things.py docs: 2021-03-28 = 132464128
        let encoded = 132464128
        let date = Things3DateDecoder.decode(encoded)
        #expect(date != nil)

        let components = Calendar.current.dateComponents([.year, .month, .day], from: date!)
        #expect(components.year == 2021)
        #expect(components.month == 3)
        #expect(components.day == 28)
    }

    @Test("Encode roundtrip")
    func encodeRoundtrip() {
        let original = 132792064
        let date = Things3DateDecoder.decode(original)!
        let reencoded = Things3DateDecoder.encode(date)
        #expect(reencoded == original)
    }

    @Test("Decode zero returns nil")
    func decodeZero() {
        #expect(Things3DateDecoder.decode(0) == nil)
    }

    @Test("Decode components")
    func decodeComponents() {
        let encoded = 132792064
        let components = Things3DateDecoder.decodeComponents(encoded)
        #expect(components != nil)
        #expect(components?.year == 2026)
        #expect(components?.month == 3)
        #expect(components?.day == 30)
    }

    @Test("Decode time: 12:34")
    func decodeTime() {
        // 12:34 encoded: (12 << 26) | (34 << 20) = 840957952
        let encoded = 840957952
        let time = Things3DateDecoder.decodeTime(encoded)
        #expect(time != nil)
        #expect(time?.hour == 12)
        #expect(time?.minute == 34)
    }

    @Test("Decode time zero returns nil")
    func decodeTimeZero() {
        #expect(Things3DateDecoder.decodeTime(0) == nil)
    }
}
