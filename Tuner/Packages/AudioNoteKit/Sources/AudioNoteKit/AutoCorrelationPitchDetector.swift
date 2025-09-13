//
//  AutoCorrelationPitchDetector.swift
//  AudioNoteKit
//
//  Created by Denis Boliachkin on 31/8/25.
//

import Foundation

public struct AutoCorrelationPitchDetector {
    public struct Config {
        public var minFrequency: Double = 70
        public var maxFrequency: Double = 1000

        public var powerThreshold: Float = 0.01

        public var peakThreshold: Float = 0.4

        public var useFirstPeak: Bool = true

        public init() {}
    }

    private var cfg: Config
    private var window: [Float] = []

    public init(config: Config = .init()) {
        self.cfg = config
    }

    public mutating func process(samples inSamples: [Float], sampleRate: Double) -> PitchEstimate? {
        let n = inSamples.count
        guard n >= 512, sampleRate > 0 else { return nil }

        var x = inSamples

        let level = rms(x)
        if level < cfg.powerThreshold { return nil }

        removeDC(&x)

        if window.count != n { window = makeHannWindow(n) }
        applyWindowInPlace(&x, window: window)

        let maxTau = Int(floor(sampleRate / cfg.minFrequency))
        let minTau = max(2, Int(floor(sampleRate / cfg.maxFrequency)))
        if minTau >= maxTau || maxTau >= n { return nil }

        var prefixSq = [Float](repeating: 0, count: n + 1)
        for i in 0..<n {
            prefixSq[i + 1] = prefixSq[i] + x[i] * x[i]
        }

        func normCorr(_ tau: Int) -> Float {
            let count = n - tau
            if count <= 0 { return -1 }
            var s: Float = 0
            var i = 0
            while i < count {
                s += x[i] * x[i + tau]
                i += 1
            }
            let e0 = prefixSq[count] - prefixSq[0]
            let e1 = prefixSq[n] - prefixSq[tau]
            let denom = Double(e0) * Double(e1)
            if denom <= Double.leastNonzeroMagnitude { return 0 }
            return Float(Double(s) / sqrt(denom))
        }

        var bestTau: Int = 0
        var bestVal: Float = 0

        if cfg.useFirstPeak {
            var t = max(minTau, 1)
            while t < maxTau - 1 {
                let c0 = normCorr(t - 1)
                let c1 = normCorr(t)
                let c2 = normCorr(t + 1)
                if c1 > c0 && c1 >= c2 && c1 > cfg.peakThreshold {
                    bestTau = t
                    bestVal = c1
                    break
                }
                t += 1
            }
        }

        if bestTau == 0 {
            var maxV: Float = -Float.greatestFiniteMagnitude
            var maxI: Int = 0
            for tau in minTau..<maxTau {
                let c = normCorr(tau)
                if c > maxV {
                    maxV = c
                    maxI = tau
                }
            }
            bestTau = maxI
            bestVal = maxV
        }

        if bestTau == 0 { return nil }

        let c_1 = normCorr(bestTau - 1)
        let c0  = normCorr(bestTau)
        let c1  = normCorr(bestTau + 1)
        let denom = (c_1 - 2*c0 + c1)
        let delta: Double = denom == 0 ? 0 : 0.5 * Double(c_1 - c1) / Double(denom)

        let tauHat = max(Double(minTau),
                         min(Double(maxTau - 1), Double(bestTau) + delta))

        let freq = sampleRate / tauHat
        let conf = Double(max(0, min(1, c0)))

        if !freq.isFinite || freq < cfg.minFrequency || freq > cfg.maxFrequency {
            return nil
        }

        return PitchEstimate(frequency: freq, confidence: conf)
    }
}
