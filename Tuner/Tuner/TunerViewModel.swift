//
//  TunerViewModel.swift
//  Tuner
//
//  Created by Denis Boliachkin on 2/9/25.
//

import Foundation
import Combine
import AudioNoteKit

@MainActor
final class TunerViewModel: ObservableObject {

    struct Config {
        var minConfidence: Double = 0.25
        var minRMS: Float = 0.01
        var smoothAlpha: Double = 0.25
        var snapThreshold: Double = 25.0
        var stableCents: Double = 3.0
        var stableHold: TimeInterval = 0.20
        var displayRange: Double = 50.0
    }
    var config = Config()

    @Published var frequencyHz: Double = 0
    @Published var confidence: Double = 0
    @Published var rmsValue: Float = 0

    @Published var a4: Double = 440.0

    @Published var tuning: Tuning = .guitarStandardE {
        didSet { clampSelectionIfNeeded() }
    }

    @Published var selectedStringIndex: Int = 0

    @Published private(set) var nearestNote: Note? = nil
    @Published private(set) var centsToNearest: Double = 0
    @Published private(set) var targetStringIndex: Int = 0
    @Published private(set) var centsToTarget: Double = 0
    @Published private(set) var isStable: Bool = false

    private var smoothCents: Double? = nil
    private var stableSince: Date? = nil

    func updateFromDetector(freq: Double, conf: Double, rms: Float) {
        frequencyHz = freq
        confidence = conf
        rmsValue = rms

        guard freq > 0, conf >= config.minConfidence, rms >= config.minRMS else {
            handleNoSignal()
            return
        }

        let nn = PitchMath.nearestNote(for: freq, a4: a4)
        nearestNote = nn.note
        centsToNearest = nn.cents

        let idx = clampedIndex(selectedStringIndex)
        targetStringIndex = idx

        let targetFreq = tuning.strings[idx].frequency(a4: a4)
        let raw = PitchMath.cents(from: freq, to: targetFreq)
        let smoothed = smooth(raw: raw)
        updateStability(with: smoothed)

        let display = max(-config.displayRange, min(config.displayRange, smoothed))
        centsToTarget = display
    }

    private func handleNoSignal() {
        nearestNote = nil
        isStable = false
        stableSince = nil
        smoothCents = nil
        targetStringIndex = clampedIndex(selectedStringIndex)
        centsToTarget = 0
    }

    private func clampSelectionIfNeeded() {
        let clamped = clampedIndex(selectedStringIndex)
        if clamped != selectedStringIndex {
            selectedStringIndex = clamped
        }
    }

    private func clampedIndex(_ i: Int) -> Int {
        guard !tuning.strings.isEmpty else { return 0 }
        // startIndex = 0, endIndex = count
        return min(max(i, tuning.strings.startIndex), tuning.strings.endIndex - 1)
    }

    private func smooth(raw: Double) -> Double {
        guard let prev = smoothCents else { smoothCents = raw; return raw }
        if abs(raw - prev) >= config.snapThreshold {
            smoothCents = raw
            return raw
        }
        let a = max(0.0, min(1.0, config.smoothAlpha))
        let next = a * raw + (1.0 - a) * prev
        smoothCents = next
        return next
    }

    private func updateStability(with smoothedCents: Double) {
        let inWindow = abs(smoothedCents) <= config.stableCents
        let now = Date()
        if inWindow {
            if stableSince == nil { stableSince = now }
            isStable = now.timeIntervalSince(stableSince!) >= config.stableHold
        } else {
            stableSince = nil
            isStable = false
        }
    }
}
