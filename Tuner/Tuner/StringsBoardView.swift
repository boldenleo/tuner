//
//  StringsBoardView.swift
//  Tuner
//
//  Created by Denis Boliachkin on 13/9/25.
//

import SwiftUI
import AudioNoteKit

public struct StringsBoardView: View {
    public let spec: InstrumentSpec
    public var stringsHeight: CGFloat = 3000
    public var bubbleSpacing: CGFloat = 12
    public var bubbleDiameter: CGFloat = 36
    public var activeIndex: Int? = nil
    public var fretCount: Int = 4

    public init(spec: InstrumentSpec,
                stringsHeight: CGFloat = 300,
                bubbleSpacing: CGFloat = 12,
                bubbleDiameter: CGFloat = 36,
                activeIndex: Int? = nil,
                fretCount: Int = 4) {
        self.spec = spec
        self.stringsHeight = stringsHeight
        self.bubbleSpacing = bubbleSpacing
        self.bubbleDiameter = bubbleDiameter
        self.activeIndex = activeIndex
        self.fretCount = fretCount
    }

    private var gridWidth: CGFloat {
        CGFloat(spec.stringCount) * bubbleDiameter
        + CGFloat(max(0, spec.stringCount - 1)) * bubbleSpacing
    }

    public var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: bubbleSpacing) {
                ForEach(spec.notes.indices, id: \.self) { i in
                    NoteBubble(letter: spec.notes[i].name.letter,
                               sharp: spec.notes[i].name.isSharp,
                               isActive: activeIndex == i,
                               diameter: bubbleDiameter)
                }
            }
            ZStack(alignment: .top) {
                if fretCount > 0 {
                    FretsOverlay(
                        fretCount: fretCount,
                        columnWidth: bubbleDiameter,
                        stringCount: spec.stringCount,
                        leftThickness: thickness(for: 0),
                        rightThickness: thickness(for: max(0, spec.stringCount - 1))
                    )
                    .frame(width: gridWidth, height: stringsHeight)
                    .allowsHitTesting(false)
                }
                HStack(alignment: .top, spacing: bubbleSpacing) {
                    ForEach(spec.notes.indices, id: \.self) { i in
                        ZStack {
                            StringLine(thickness: thickness(for: i),
                                       isActive: activeIndex == i)
                                .frame(width: thickness(for: i), height: stringsHeight)
                        }
                        .frame(width: bubbleDiameter, alignment: .top)
                    }
                }
                .frame(width: gridWidth)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private func thickness(for index: Int,
                           minPt: CGFloat = 2.0,
                           maxPt: CGFloat = 6.0) -> CGFloat
    {
        let gauges = spec.gauges
        if gauges.count == spec.stringCount, let gMin = gauges.min(), let gMax = gauges.max(), gMax > gMin {
            let g = gauges[index]
            let t = (g - gMin) / (gMax - gMin) // 0...1
            return minPt + CGFloat(t) * (maxPt - minPt)
        } else {
            let n = max(1, spec.stringCount - 1)
            let t = 1.0 - Double(index) / Double(n)
            return minPt + CGFloat(t) * (maxPt - minPt)
        }
    }
}

private struct NoteBubble: View {
    let letter: String
    let sharp: Bool
    let isActive: Bool
    let diameter: CGFloat

    var body: some View {
        let accent = isActive ? Color(hex: 0x21E0A5) : .white
        ZStack {
            Circle()
                .fill(Color.white.opacity(isActive ? 0.16 : 0.08))
                .overlay(
                    Circle().stroke(isActive ? accent.opacity(0.8) : Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(radius: isActive ? 6 : 0)

            HStack(spacing: 2) {
                Text(letter)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(accent)
                if sharp {
                    Text("♯")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .baselineOffset(4)
                        .foregroundColor(accent)
                }
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

private struct StringLine: View {
    let thickness: CGFloat
    let isActive: Bool
    var body: some View {
        Rectangle()
            .fill(.white.opacity(isActive ? 0.95 : 0.60))
            .frame(width: thickness)
            .overlay(
                Rectangle()
                    .fill(.white.opacity(isActive ? 0.28 : 0.12))
                    .frame(width: max(1, thickness * 0.25))
            )
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .white, location: 0.22),
                        .init(color: .white, location: 0.78),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

private struct FretsOverlay: View {
    let fretCount: Int
    let columnWidth: CGFloat
    let stringCount: Int
    let leftThickness: CGFloat
    let rightThickness: CGFloat

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            // Horizontal bounds: exactly from left string edge to right string edge
            let leftCenter  = columnWidth / 2
            let rightCenter = width - columnWidth / 2
            let leftEdge  = leftCenter  - leftThickness / 2
            let rightEdge = rightCenter + rightThickness / 2
            let fretWidth = max(0, rightEdge - leftEdge)
            let fretX = leftEdge + fretWidth / 2

            // Vertical positions: top and bottom insets 30pt, evenly spaced including both ends
            let topInset: CGFloat = 30
            let bottomInset: CGFloat = 30
            let usable = max(0, height - topInset - bottomInset)

            let ys: [CGFloat] = {
                if fretCount <= 0 { return [] }
                if fretCount == 1 { return [height / 2] }
                return (0..<fretCount).map { i in
                    topInset + usable * CGFloat(i) / CGFloat(fretCount - 1)
                }
            }()

            ZStack {
                ForEach(Array(ys.enumerated()), id: \.offset) { _, y in
                    Rectangle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: fretWidth + 15, height: 3)
                        .position(x: fretX, y: y)
                }
            }
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .white, location: 0.15),
                        .init(color: .white, location: 0.85),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 24) {
        StringsBoardView(spec: .guitar6_Std, stringsHeight: 300, activeIndex: 4, fretCount: 4)
        StringsBoardView(spec: .bass4_Std, stringsHeight: 300)
    }
    .padding()
    .preferredColorScheme(.dark)
}
