//
//  AutoCorrelationPitchDetecto.swift
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

        var energy: Float = 0
        for v in x { energy += v*v }
        if energy <= .ulpOfOne { return nil }

        var bestTau = 0
        var bestVal: Float = 0

        for tau in minTau..<maxTau {
            let count = n - tau
            var s: Float = 0
            var i = 0
            while i < count {
                s += x[i] * x[i + tau]
                i += 1
            }
            if s > bestVal {
                bestVal = s
                bestTau = tau
            }
        }

        if bestTau == 0 { return nil }

        func corr(_ tau: Int) -> Float {
            if tau < minTau || tau >= maxTau { return -1 }
            let count = n - tau
            var s: Float = 0
            var i = 0
            while i < count {
                s += x[i] * x[i + tau]
                i += 1
            }
            return s
        }

        let y1 = corr(bestTau - 1)
        let y2 = bestVal
        let y3 = corr(bestTau + 1)
        let denom = (y1 - 2*y2 + y3)
        let delta = denom == 0 ? 0 : 0.5 * (Double(y1 - y3) / Double(denom))
        let refinedTau = max(Double(minTau), min(Double(maxTau - 1), Double(bestTau) + delta))

        let freq = sampleRate / refinedTau
        let confidence = max(0, min(1, Double(bestVal / energy))) // грубая нормировка

        if freq.isNaN || freq.isInfinite || freq < cfg.minFrequency || freq > cfg.maxFrequency {
            return nil
        }
        return PitchEstimate(frequency: freq, confidence: confidence)
    }
}
