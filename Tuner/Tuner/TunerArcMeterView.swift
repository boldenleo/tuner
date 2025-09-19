//
//  TunerArcMeterView.swift
//  Tuner
//
//  Created by Denis Boliachkin on 2/9/25.
//

import SwiftUI
import AudioNoteKit

public struct TunerArcMeterView: View {
    private let size: CGFloat = 300
    private let ring: CGFloat = 130
    private let glow: CGFloat = 20

    var note: Note?
    var isInTune: Bool
    var cents: Double

    private let scale = TunerScale()

    private let spanDeg: Double = 200
    private var centerDeg: Double { -90 }
    private var startDeg: Double { centerDeg - spanDeg/2 }
    private var endDeg: Double { centerDeg + spanDeg/2 }

    public init(note: Note?, isInTune: Bool, cents: Double) {
        self.note = note
        self.isInTune = isInTune
        self.cents = cents
    }

    public var body: some View {
        VStack(spacing: 12) {
            NoteLabel(note: note, isInTune: isInTune)

            GeometryReader { geo in
                ZStack {
                    base()
                    redZone()
                    greenZone()
                    
                    Ticks(
                        startAngle: .degrees(0),
                        endAngle: .degrees(190),
                        step: 10.0,
                        outerInset: 10,
                        length: 10,
                        width: 1.5,
                        color: Color(hex: 0x4C6070).opacity(0.8)
                    )
                    GrainOverlay(opacity: 0.03, blend: .overlay)
                        .mask(
                            RingSegment(
                                startAngle: .degrees(170),
                                endAngle:   .degrees(10),
                                thickness:  ring + glow * 2
                            )
                            .frame(width: size, height: size)
                            .blur(radius: 2)
                        )
                    
                    pointer(cents: cents)
                }
            }
            .frame(width: size, height: size * 0.62)
        }
    }

    // MARK: - Drawing

    private func base() -> some View {
        ZStack{
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0x2E4156).opacity(0.25))
                .frame(width: size, height: size)
            
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0x243444).opacity(0.8))
                .blur(radius: glow)
        }
    }

    @ViewBuilder
    private func redZone() -> some View {
        ZStack{
            // Left Red Zone
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(200), thickness: ring)
                .fill(Color(hex: 0xFF4D6D).opacity(0.5))
                .frame(width: size, height: size)
            
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(200), thickness: ring)
                .fill(Color(hex: 0xFF96A6).opacity(0.8))
                .frame(width: size, height: size)
                .blur(radius: glow)
            // Right Red Zone
            
            RingSegment(startAngle: .degrees(-20), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0xFF4D6D).opacity(0.5))
                .frame(width: size, height: size)
            
            RingSegment(startAngle: .degrees(-20), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0xFF96A6).opacity(0.8))
                .frame(width: size, height: size)
                .blur(radius: glow)
        }
        
    }
    
    @ViewBuilder
    private func greenZone() -> some View {
        ZStack{
            RingSegment(startAngle: .degrees(-110), endAngle: .degrees(-70), thickness: ring)
                .fill(Color(hex: 0x21E0A5).opacity(0.5))
                .frame(width: size, height: size)
            
            RingSegment(startAngle: .degrees(-110), endAngle: .degrees(-70), thickness: ring)
                .fill(Color(hex: 0x74FFD9).opacity(0.8))
                .frame(width: size, height: size)
                .blur(radius: glow)
        }
    }

    @ViewBuilder
    private func tickMarks(stepCents: Double) -> some View {
        let stepDeg = spanDeg * (stepCents / (2 * scale.displayRange))
        Ticks(
            startAngle: .degrees(startDeg),
            endAngle: .degrees(endDeg),
            step: stepDeg,
            outerInset: 10,
            length: 12,
            width: 2,
            color: Color(hex: 0x4C6070).opacity(0.85)
        )
    }
    
    private let displayRangeCents: Double = 50
    private let degPerCent: Double = 2.0

    private func angle(for cents: Double) -> Angle {
        let clamped = max(-displayRangeCents, min(displayRangeCents, cents))
        return .degrees(degPerCent * clamped)    // 0¢ -> 0°, верх
    }
    
    @ViewBuilder
    private func pointer(cents: Double) -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let clamped = max(-displayRangeCents, min(displayRangeCents, cents))

            ZStack {
                Circle()
                    .fill(Color(hex: 0xD9D9D9).opacity(0.95))
                    .frame(width: 15, height: 15)
                    .shadow(radius: 1)

                TaperedNeedle(length: 75, baseWidth: 10, tipWidth: 2)
                    .fill(Color(hex: 0xD9D9D9).opacity(0.95))
                    .rotationEffect(angle(for: clamped))
                    .animation(.easeOut(duration: 0.08), value: clamped)
            }
            .frame(width: side, height: side)
        }
    }
    
    private struct TaperedNeedle: Shape {
        var length: CGFloat
        var baseWidth: CGFloat
        var tipWidth: CGFloat

        func path(in rect: CGRect) -> Path {
            let cx = rect.midX
            let cy = rect.midY

            var p = Path()
            p.move(to: CGPoint(x: cx - baseWidth/2, y: cy))
            p.addLine(to: CGPoint(x: cx + baseWidth/2, y: cy))
            p.addLine(to: CGPoint(x: cx + tipWidth/2, y: cy - length))
            p.addArc(center: CGPoint(x: cx, y: cy - length),
                     radius: tipWidth/2,
                     startAngle: .degrees(0),
                     endAngle: .degrees(180),
                     clockwise: false)
            p.addLine(to: CGPoint(x: cx - baseWidth/2, y: cy))
            p.closeSubpath()
            return p
        }
    }
}

private struct RingSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var thickness: CGFloat = 1
    
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) * 0.5
        let innerR = max(0, outerR - thickness)
        
        let a0 = startAngle.radians
        var a1 = endAngle.radians
        if a1 < a0 {
            a1 += .pi * 2
        }
        
        var p = Path()
        p.addArc(center: c, radius: outerR,
                 startAngle: .radians(a0), endAngle: .radians(a1),
                 clockwise: false)
        p.addArc(center: c, radius: innerR,
                 startAngle: .radians(a1), endAngle: .radians(a0),
                 clockwise: true)
        p.closeSubpath()
        return p
    }
}

private struct Ticks: View {
    var startAngle: Angle
    var endAngle: Angle
    var step: Double = 10.0
    var outerInset: CGFloat = 10
    var length: CGFloat = 20
    var width: CGFloat = 3
    var color: Color = .black
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let outerR = side * 0.5
            let radialPos = outerR - outerInset - length/2
            
            ZStack {
                ForEach(tickAngles(), id: \.self) { deg in
                    Capsule()
                        .fill(color)
                        .frame(width: width, height: length)
                        .offset(y: -radialPos)
                        .rotationEffect(.degrees(deg - 90))
                }
            }
            .frame(width: side, height: side)
        }
    }
    
    private func tickAngles() -> [Double] {
        let s = startAngle.degrees
        var e = endAngle.degrees
        if e <= s { e += 360 }
        let step = max(0.0001, abs(step))

        var res: [Double] = []
        var cur = s
        while cur < e - 1e-9 {
            res.append(cur)
            cur += step
        }
        return res
    }
}

struct NoteLabel: View {
    let note: Note?
    let isInTune: Bool

    var body: some View {
        let accent = isInTune ? Color(hex: 0x21E0A5) : .white
        if let note {
            HStack(spacing: 0) {
                Text(note.name.letter)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                if note.name.isSharp {
                    Text("♯")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .baselineOffset(6)
                        .foregroundColor(accent)
                }
                Text("\(note.octave)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .monospacedDigit()
                    .baselineOffset(18)
            }
        } else {
            Text("—")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TunerArcMeterView(note: Note(.D, 4), isInTune: false, cents: -30)
        .preferredColorScheme(.dark)
}
