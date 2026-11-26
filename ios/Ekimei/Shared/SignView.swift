import SwiftUI

struct SignTheme {
    let paper: Color
    let ink: Color
    let muted: Color

    static let light = SignTheme(paper: .white, ink: Color(white: 0.06), muted: Color(white: 0.36))
    static let dark = SignTheme(paper: .black, ink: .white, muted: Color(white: 0.65))
}

/// Arrow-ended band. The tip is as wide as the band is tall.
struct ArrowBand: Shape {
    func path(in r: CGRect) -> Path {
        let tip = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - tip, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - tip, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// The station sign. Lays itself out for a square (small widget) or a wide (medium widget, iPad, app) frame.
/// The clock uses Text(_:style:), which keeps itself up to date inside widgets.
struct SignView: View {
    let line: Line
    let current: Station
    let previous: Station?
    let next: Station?
    let theme: SignTheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let compact = w / max(h, 1) < 1.4
            let u = compact ? w / 60 : min(w / 100, h / 52)

            VStack(spacing: u * 1.5) {
                header(u: u, compact: compact)
                Spacer(minLength: 0)
                nameBlock(u: u, compact: compact)
                Spacer(minLength: 0)
                strip(u: u, compact: compact)
            }
            .padding(.horizontal, u * (compact ? 3.5 : 4))
            .padding(.vertical, u * 3)
            .frame(width: w, height: h)
            .background(theme.paper)
        }
    }

    private func header(u: CGFloat, compact: Bool) -> some View {
        let box = u * (compact ? 6 : 6)
        return HStack(spacing: u * 1.4) {
            Text(Date(), style: .time)
                .font(.system(size: u * (compact ? 4.6 : 5.4), weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(theme.ink)
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text(line.pre).font(.system(size: u * 1.7, weight: .bold))
                Text(current.number).font(.system(size: u * 2.6, weight: .bold)).monospacedDigit()
            }
            .foregroundStyle(theme.ink)
            .frame(width: box, height: box)
            .overlay(Circle().stroke(line.tint, lineWidth: u * 0.45))
            Text(line.ch)
                .font(.system(size: u * 3.8, weight: .black))
                .foregroundStyle(theme.ink)
                .frame(width: box, height: box)
                .overlay(RoundedRectangle(cornerRadius: u * 0.5).stroke(theme.ink, lineWidth: u * 0.45))
        }
        .frame(height: box)
    }

    private func nameBlock(u: CGFloat, compact: Bool) -> some View {
        VStack(spacing: u * 0.8) {
            Text(current.kanji)
                .font(.system(size: u * (compact ? 15 : 14), weight: .black))
                .tracking(u * 0.3)
            Text(current.kana)
                .font(.system(size: u * (compact ? 4 : 4.5), weight: .medium))
                .tracking(u * 0.5)
            Text(current.romaji)
                .font(.system(size: u * (compact ? 6.5 : 7.5), weight: .bold))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.3)
        .foregroundStyle(theme.ink)
        .multilineTextAlignment(.center)
    }

    private func strip(u: CGFloat, compact: Bool) -> some View {
        let bandH = u * (compact ? 5.5 : 7)
        return VStack(spacing: u) {
            ZStack {
                ArrowBand().fill(line.tint)
                Rectangle().fill(Color.white.opacity(0.45)).frame(width: bandH, height: bandH)
            }
            .frame(height: bandH)

            HStack(alignment: .top) {
                neighbour(previous, u: u, compact: compact, trailing: false)
                Spacer(minLength: u * 3)
                neighbour(next, u: u, compact: compact, trailing: true)
            }
        }
    }

    private func neighbour(_ s: Station?, u: CGFloat, compact: Bool, trailing: Bool) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: u * 0.2) {
            Text(s?.kanji ?? " ")
                .font(.system(size: u * (compact ? 3.8 : 3), weight: .bold))
                .foregroundStyle(theme.ink)
            if !compact {
                Text(s?.romaji ?? " ")
                    .font(.system(size: u * 2.1, weight: .medium))
                    .foregroundStyle(theme.muted)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

#Preview("Wide", traits: .fixedLayout(width: 844, height: 390)) {
    let l = Line.fallback
    SignView(line: l, current: l.stations[1], previous: l.stations[0], next: l.stations[2], theme: .light)
}

#Preview("Small", traits: .fixedLayout(width: 170, height: 170)) {
    let l = Line.fallback
    SignView(line: l, current: l.stations[1], previous: l.stations[0], next: l.stations[2], theme: .dark)
}
