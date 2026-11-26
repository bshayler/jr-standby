import SwiftUI
import WidgetKit

@main
struct EkimeiWidgetBundle: WidgetBundle {
    var body: some Widget { EkimeiWidget() }
}

// MARK: - Timeline

struct SignEntry: TimelineEntry {
    let date: Date
    let line: Line
    let index: Int
    let dir: Int            // +1 or -1: which way "next" lies in the station list
    let appearance: Appearance
}

struct Provider: AppIntentTimelineProvider {
    private static var fallbackLine: Line { Line.find("yamanote") ?? Line.all[0] }

    /// Resolves the configured station, or Shibuya when nothing has been picked yet.
    private func base(_ cfg: StationSignIntent) -> (line: Line, index: Int, dir: Int) {
        var line = Self.fallbackLine
        var index = line.start
        if let id = cfg.station?.id {
            let parts = id.split(separator: ":")
            if parts.count == 2, let l = Line.find(String(parts[0])), let i = Int(parts[1]),
               l.stations.indices.contains(i) { line = l; index = i }
        }
        // The Yamanote Line list runs clockwise; the reference sign (Shibuya, next Harajuku) travels the other way.
        let natural = line.loop ? -1 : 1
        return (line, index, cfg.direction == .forward ? natural : -natural)
    }

    func placeholder(in context: Context) -> SignEntry {
        let l = Self.fallbackLine
        return SignEntry(date: .now, line: l, index: l.start, dir: -1, appearance: .system)
    }

    func snapshot(for cfg: StationSignIntent, in context: Context) async -> SignEntry {
        let b = base(cfg)
        return SignEntry(date: .now, line: b.line, index: b.index, dir: b.dir, appearance: cfg.appearance)
    }

    func timeline(for cfg: StationSignIntent, in context: Context) async -> Timeline<SignEntry> {
        let b = base(cfg)
        let minutes = cfg.ride.minutes
        guard minutes > 0 else {
            let e = SignEntry(date: .now, line: b.line, index: b.index, dir: b.dir, appearance: cfg.appearance)
            return Timeline(entries: [e], policy: .never)
        }
        // Ride mode: pre-compute the next 12 hours of stations. Entries are free; only reloads count against the budget.
        let count = 12 * 60 / minutes
        let entries = (0..<count).map { step -> SignEntry in
            let pos = b.line.advance(from: b.index, dir: b.dir, steps: step)
            return SignEntry(date: Date().addingTimeInterval(Double(step * minutes * 60)),
                             line: b.line, index: pos.index, dir: pos.dir, appearance: cfg.appearance)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - View

struct EkimeiEntryView: View {
    let entry: SignEntry

    @Environment(\.colorScheme) private var scheme
    @Environment(\.showsWidgetContainerBackground) private var showsBackground

    private var theme: SignTheme {
        switch entry.appearance {
        case .light: return .light
        case .dark: return .dark
        case .system:
            // StandBy removes the container background and shows widgets on black.
            return (scheme == .dark || !showsBackground) ? .dark : .light
        }
    }

    var body: some View {
        let line = entry.line
        SignView(line: line,
                 current: line.stations[entry.index],
                 previous: line.neighbour(of: entry.index, step: -entry.dir),
                 next: line.neighbour(of: entry.index, step: entry.dir),
                 theme: theme)
            .containerBackground(for: .widget) { theme.paper }
    }
}

// MARK: - Widget

struct EkimeiWidget: Widget {
    let kind = "EkimeiWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StationSignIntent.self, provider: Provider()) { entry in
            EkimeiEntryView(entry: entry)
        }
        .configurationDisplayName("JR Station Sign")
        .description("A Japanese station name sign with a live clock.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
