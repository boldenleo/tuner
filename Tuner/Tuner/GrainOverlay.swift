//
//  GrainOverlay.swift
//  Tuner
//
//  Created by Denis Boliachkin on 19/9/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

final class NoiseTile {
    static let shared = NoiseTile()
    let cgImage: CGImage

    private init() {
        let ctx = CIContext()
        let gen = CIFilter.randomGenerator()
        let tileSize: CGFloat = 256
        let img = gen.outputImage!
            .cropped(to: CGRect(x: 0, y: 0, width: tileSize, height: tileSize))
        self.cgImage = ctx.createCGImage(img, from: img.extent)!
    }
}

struct GrainOverlay: View {
    var opacity: Double = 0.06
    var blend: BlendMode = .overlay
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            Image(decorative: NoiseTile.shared.cgImage, scale: 1, orientation: .up)
                .resizable(resizingMode: .tile)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .offset(x: phase, y: -phase)
                .blendMode(blend)
                .opacity(opacity)
                .animation(.linear(duration: 2).repeatForever(autoreverses: true), value: phase)
                .onAppear { phase = 0.7 }
        }
        .allowsHitTesting(false)
    }
}
