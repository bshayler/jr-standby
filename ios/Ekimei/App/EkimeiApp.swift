import SwiftUI

@main
struct EkimeiApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @AppStorage("lineID") private var lineID = "yamanote"
    @AppStorage("stationIndex") private var index = 19
    @AppStorage("reversed") private var reversed = false
    @AppStorage("dark") private var dark = true
    @State private var fullScreen = false

    private var line: Line { Line.find(lineID) ?? Line.all[0] }
    private var safeIndex: Int { min(max(index, 0), line.stations.count - 1) }
    private var dir: Int { (line.loop ? -1 : 1) * (reversed ? -1 : 1) }
    private var theme: SignTheme { dark ? .dark : .light }

    var body: some View {
        NavigationStack {
            Form {
                Section("Line") {
                    Picker("Line", selection: $lineID) {
                        ForEach(Line.all) { Text($0.name).tag($0.id) }
                    }
                    .onChange(of: lineID) { _, _ in index = line.start }
                    Picker("Station", selection: $index) {
                        ForEach(line.stations.indices, id: \.self) { i in
                            let s = line.stations[i]
                            Text("\(line.pre)\(s.number)  \(s.kanji)  \(s.romaji)").tag(i)
                        }
                    }
                    Toggle("Reverse direction", isOn: $reversed)
                    Toggle("Black sign", isOn: $dark)
                }
                Section("Preview") {
                    sign.aspectRatio(2.1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                }
                Section {
                    Button("Show full screen") { fullScreen = true }
                } footer: {
                    Text("Full screen keeps the display awake. Turn the device to landscape and put it on a charger. For StandBy, add the Ekimei widget from the widget gallery.")
                }
            }
            .navigationTitle("Ekimei 駅名")
        }
        .fullScreenCover(isPresented: $fullScreen) {
            sign
                .ignoresSafeArea()
                .persistentSystemOverlays(.hidden)
                .statusBarHidden()
                .onTapGesture { fullScreen = false }
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
                .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }

    private var sign: some View {
        SignView(line: line,
                 current: line.stations[safeIndex],
                 previous: line.neighbour(of: safeIndex, step: -dir),
                 next: line.neighbour(of: safeIndex, step: dir),
                 theme: theme)
    }
}
