//
//  TunerArcMeterView.swift
//  Tuner
//
//  Created by Denis Boliachkin on 2/9/25.
//

import SwiftUI

public struct TunerArcMeterView: View {
    private let size: CGFloat = 300
    private let ring: CGFloat = 130
    private let glow: CGFloat = 20
    
    public init() {}
    
    public var body: some View {
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
        }
        .frame(width: size, height: size)
    }
    
    // MARK: Layers
    private func base() -> some View {
        ZStack{
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0x2E4156).opacity(0.25))
                .frame(width: size, height: size)
            
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0x243444).opacity(0.8))
                .frame(width: size, height: size)
                .blur(radius: glow)
        }
        
    }
    
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
}

private struct RingSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var thickness: CGFloat = 1
    
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY) // center
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

#Preview {
    TunerArcMeterView()
        .preferredColorScheme(.dark)
}
