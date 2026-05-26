import Foundation

/// Decodes and encodes dates in Things 3's custom binary format.
///
/// Things 3 encodes dates as integers with bit layout: YYYYYYYYYYYMMMMDDDDD0000000
/// - 11 bits for year
/// - 4 bits for month
/// - 5 bits for day
/// - 7 trailing zero bits
enum Things3DateDecoder {

    static func decode(_ value: Int) -> Date? {
        guard value != 0 else { return nil }
        let year = (value >> 16) & 0x7FF
        let month = (value >> 12) & 0xF
        let day = (value >> 7) & 0x1F
        guard year > 0, (1...12).contains(month), (1...31).contains(day) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    static func encode(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return 0 }
        return (year << 16) | (month << 12) | (day << 7)
    }

    static func decodeComponents(_ value: Int) -> DateComponents? {
        guard value != 0 else { return nil }
        let year = (value >> 16) & 0x7FF
        let month = (value >> 12) & 0xF
        let day = (value >> 7) & 0x1F
        guard year > 0, (1...12).contains(month), (1...31).contains(day) else { return nil }
        return DateComponents(year: year, month: month, day: day)
    }

    /// Decodes Things 3's time format: hhhhhmmmmmm00000000000000000000 (32 bits)
    static func decodeTime(_ value: Int) -> (hour: Int, minute: Int)? {
        guard value != 0 else { return nil }
        let hours = (value >> 26) & 0x1F
        let minutes = (value >> 20) & 0x3F
        guard (0...23).contains(hours), (0...59).contains(minutes) else { return nil }
        return (hours, minutes)
    }
}
