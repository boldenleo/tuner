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
        }
        .frame(width: size, height: size)
    }
    
    // MARK: Layers
    private func base() -> some View {
        ZStack{
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0x243444).opacity(1.0))
                .frame(width: size, height: size)
                .blur(radius: glow)
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0x2E4156).opacity(0.25))
                .frame(width: size, height: size)
        }
        
    }
    
    private func redZone() -> some View {
        ZStack{
            // Left Red Zone
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(200), thickness: ring)
                .fill(Color(hex: 0xFF96A6).opacity(1.0))
                .frame(width: size, height: size)
                .blur(radius: glow)
            RingSegment(startAngle: .degrees(170), endAngle: .degrees(200), thickness: ring)
                .fill(Color(hex: 0xFF4D6D).opacity(0.5))
                .frame(width: size, height: size)
            // Right Red Zone
            RingSegment(startAngle: .degrees(-20), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0xFF96A6).opacity(1.0))
                .frame(width: size, height: size)
                .blur(radius: glow)
            RingSegment(startAngle: .degrees(-20), endAngle: .degrees(10), thickness: ring)
                .fill(Color(hex: 0xFF4D6D).opacity(0.5))
                .frame(width: size, height: size)
        }
        
    }
    
    private func greenZone() -> some View {
        ZStack{
            RingSegment(startAngle: .degrees(-110), endAngle: .degrees(-70), thickness: ring)
                .fill(Color(hex: 0x74FFD9).opacity(1.0))
                .frame(width: size, height: size)
                .blur(radius: glow)
            RingSegment(startAngle: .degrees(-110), endAngle: .degrees(-70), thickness: ring)
                .fill(Color(hex: 0x21E0A5).opacity(0.5))
                .frame(width: size, height: size)
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

#Preview {
    TunerArcMeterView()
        .preferredColorScheme(.dark)
}
