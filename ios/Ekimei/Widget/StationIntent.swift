import AppIntents
import WidgetKit

// MARK: - Station entity

/// A station on one particular line. Interchange stations appear once per line.
/// The id is "<line id>:<index>", e.g. "yamanote:19".
struct StationEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Station")
    static let defaultQuery = StationQuery()

    let id: String
    let title: String
    let lineName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(lineName)")
    }

    init(id: String, title: String, lineName: String) {
        self.id = id; self.title = title; self.lineName = lineName
    }

    init?(id: String) {
        let parts = id.split(separator: ":")
        guard parts.count == 2, let i = Int(parts[1]),
              let line = Line.find(String(parts[0])), line.stations.indices.contains(i) else { return nil }
        let s = line.stations[i]
        self.init(id: id, title: "\(line.pre)\(s.number)  \(s.kanji)  \(s.romaji)", lineName: line.name)
    }

    static var everyStation: [StationEntity] {
        Line.all.flatMap { line in
            line.stations.indices.compactMap { StationEntity(id: "\(line.id):\($0)") }
        }
    }
}

struct StationQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [StationEntity] {
        identifiers.compactMap { StationEntity(id: $0) }
    }

    func entities(matching string: String) async throws -> [StationEntity] {
        let q = string.lowercased()
        return StationEntity.everyStation.filter {
            $0.title.lowercased().contains(q) || $0.lineName.lowercased().contains(q)
        }
    }

    func suggestedEntities() async throws -> [StationEntity] { StationEntity.everyStation }

    func defaultResult() async -> StationEntity? {
        let yamanote = Line.find("yamanote")
        return StationEntity(id: "yamanote:\(yamanote?.start ?? 0)")
    }
}

// MARK: - Options

enum TravelDirection: String, AppEnum {
    case forward, reverse
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Direction")
    static let caseDisplayRepresentations: [TravelDirection: DisplayRepresentation] = [
        .forward: "Towards the end of the list",
        .reverse: "Towards the start of the list",
    ]
}

enum RideMode: String, AppEnum {
    case off, every5, every15, every30
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Ride mode")
    static let caseDisplayRepresentations: [RideMode: DisplayRepresentation] = [
        .off: "Off",
        .every5: "Next station every 5 minutes",
        .every15: "Next station every 15 minutes",
        .every30: "Next station every 30 minutes",
    ]
    var minutes: Int {
        switch self { case .off: 0; case .every5: 5; case .every15: 15; case .every30: 30 }
    }
}

enum Appearance: String, AppEnum {
    case system, light, dark
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Appearance")
    static let caseDisplayRepresentations: [Appearance: DisplayRepresentation] = [
        .system: "Match system", .light: "White sign", .dark: "Black sign",
    ]
}

// MARK: - Widget configuration

struct StationSignIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Station sign"
    static let description = IntentDescription("Show a JR-style station sign.")

    @Parameter(title: "Station")
    var station: StationEntity?

    @Parameter(title: "Direction", default: .forward)
    var direction: TravelDirection

    @Parameter(title: "Ride mode", default: .off)
    var ride: RideMode

    @Parameter(title: "Appearance", default: .system)
    var appearance: Appearance
}
