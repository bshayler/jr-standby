import SwiftUI

/// One station on a line. Decoded from the 4-element arrays in data/lines.json:
/// [kanji, kana, romaji, station number].
struct Station: Codable, Hashable {
    let kanji: String
    let kana: String
    let romaji: String
    let number: String

    init(kanji: String, kana: String, romaji: String, number: String) {
        self.kanji = kanji; self.kana = kana; self.romaji = romaji; self.number = number
    }

    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        kanji = try c.decode(String.self)
        kana = try c.decode(String.self)
        romaji = try c.decode(String.self)
        number = try c.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(kanji); try c.encode(kana); try c.encode(romaji); try c.encode(number)
    }
}

struct Line: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let ch: String          // single kanji shown in the boxed line mark
    let pre: String         // station code letters, e.g. "JY"
    let color: String       // hex, e.g. "#80c241"
    let loop: Bool
    let start: Int          // default station index
    let stations: [Station]

    var tint: Color { Color(hex: color) }

    /// Neighbouring station, wrapping on loop lines and returning nil past the end of linear lines.
    func neighbour(of index: Int, step: Int) -> Station? {
        let n = stations.count
        guard n > 0 else { return nil }
        let j = index + step
        if loop { return stations[((j % n) + n) % n] }
        return stations.indices.contains(j) ? stations[j] : nil
    }

    /// Station index after `steps` moves in `dir` (+1 / -1). Loop lines wrap; linear lines bounce at the ends.
    /// Returns the new index and the direction of travel at that point.
    func advance(from index: Int, dir: Int, steps: Int) -> (index: Int, dir: Int) {
        var i = index, d = dir
        let n = stations.count
        guard n > 1 else { return (i, d) }
        for _ in 0..<max(0, steps) {
            if loop {
                i = ((i + d) % n + n) % n
            } else {
                if !stations.indices.contains(i + d) { d = -d }
                i += d
            }
        }
        return (i, d)
    }
}

extension Line {
    /// All bundled lines. The JSON file must be a resource of every target that uses this.
    static let all: [Line] = {
        guard let url = Bundle.main.url(forResource: "lines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lines = try? JSONDecoder().decode([Line].self, from: data),
              !lines.isEmpty
        else { return [fallback] }
        return lines
    }()

    static func find(_ id: String) -> Line? { all.first { $0.id == id } }

    /// Only used if data/lines.json is missing from the bundle.
    static let fallback = Line(
        id: "yamanote", name: "Yamanote Line 山手線", ch: "山", pre: "JY", color: "#80c241", loop: true, start: 1,
        stations: [
            Station(kanji: "恵比寿", kana: "えびす", romaji: "Ebisu", number: "21"),
            Station(kanji: "渋谷", kana: "しぶや", romaji: "Shibuya", number: "20"),
            Station(kanji: "原宿", kana: "はらじゅく", romaji: "Harajuku", number: "19"),
        ])
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xff) / 255,
                  green: Double((v >> 8) & 0xff) / 255,
                  blue: Double(v & 0xff) / 255)
    }
}
