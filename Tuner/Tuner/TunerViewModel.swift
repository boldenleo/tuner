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

        // Сглаживание центов
        var smoothAlpha: Double = 0.25
        var snapThreshold: Double = 25.0

        // Критерий "попал в ноту"
        var stableCents: Double = 3.0
        var stableHold: TimeInterval = 0.20

        // Диапазон отображения
        var displayRange: Double = 50.0

        // -------- Новое: авто-определение струны --------
        /// Включить авто-детект струны?
        var autoStringDetection: Bool = true

        /// Если авто-детект выключен: переключаться на лучшую струну,
        /// если ручная "в молоко" (больше этого порога)?
        var softSwitchManualIfWorseThan: Double = 200.0   // > полтона

        /// ...и если при этом у лучшей струны |cents| меньше этого?
        var softSwitchBestIfBetterThan: Double = 50.0     // < полутон

        /// Ограничивать fold по октаве при ручной настройке,
        /// чтобы не "подгонять" E2 под E4 и наоборот.
        /// 0 = без ограничения; 1 = не более одного удвоения/деления.
        var maxOctaveShiftWhenManual: Int = 1
    }
    var config = Config()

    @Published var frequencyHz: Double = 0
    @Published var confidence: Double = 0
    @Published var rmsValue: Float = 0

    @Published var a4: Double = 440.0

    @Published var tuning: Tuning = .guitarStandardE {
        didSet { clampSelectionIfNeeded() }
    }

    /// Ручной выбор пользователя (останется как есть)
    @Published var selectedStringIndex: Int = 0

    /// Фактическая "целевая струна" тюнера (учитывает авто-выбор)
    @Published private(set) var targetStringIndex: Int = 0

    @Published private(set) var nearestNote: Note? = nil
    @Published private(set) var centsToNearest: Double = 0
    @Published private(set) var centsToTarget: Double = 0
    @Published private(set) var isStable: Bool = false

    private var smoothCents: Double? = nil
    private var stableSince: Date? = nil

    // MARK: - Публичный апдейт

    func updateFromDetector(freq: Double, conf: Double, rms: Float) {
        frequencyHz = freq
        confidence  = conf
        rmsValue    = rms

        guard freq > 0, conf >= config.minConfidence, rms >= config.minRMS else {
            handleNoSignal()
            return
        }

        // Ближайшая нота (просто для отображения)
        let nn = PitchMath.nearestNote(for: freq, a4: a4)
        nearestNote = nn.note
        centsToNearest = nn.cents

        // ---- Выбираем целевую струну ----
        let manualIdx = clampedIndex(selectedStringIndex)

        // Лучший индекс относительно всех струн (±600¢ у каждой)
        let best = PitchMath.deviationToStrings(frequency: freq, tuning: tuning, a4: a4)
        var idx = manualIdx

        if config.autoStringDetection {
            idx = best.index
        } else {
            // Мягкое авто-переключение, если ручная явно "промах"
            let manualTargetF = tuning.strings[manualIdx].frequency(a4: a4)
            let manualRaw = PitchMath.cents(from: freq, to: manualTargetF)

            if abs(manualRaw) > config.softSwitchManualIfWorseThan && abs(best.cents) < config.softSwitchBestIfBetterThan {
                idx = best.index
            }
        }

        targetStringIndex = idx

        // ---- Считаем отклонение до целевой струны (с fold по октаве) ----
        let targetFreq = tuning.strings[idx].frequency(a4: a4)
        let (fCorr, shifts) = foldToTargetOctave(freq, target: targetFreq,
                                                 maxShift: config.autoStringDetection ? nil
                                                                                      : config.maxOctaveShiftWhenManual)

        let raw = PitchMath.cents(from: fCorr, to: targetFreq)
        let smoothed = smooth(raw: raw)
        updateStability(with: smoothed)

        // Ограничение для UI
        let display = max(-config.displayRange, min(config.displayRange, smoothed))
        centsToTarget = display

        print(String(format:
                        "f=%.2fHz fCorr=%.2fHz tgt=%.2fHz raw=%+.1f¢ sm=%+.1f¢ disp=%+.1f¢ nearest=%@ conf=%.2f rms=%.3f stable=%@ idx=%d shifts=%d (best=%d,%+.1f¢)",
                         freq, fCorr, targetFreq, raw, smoothed, display, nearestNote?.display ?? "—", conf, rms, isStable.description,
                         idx, shifts, best.index, best.cents))
    }

    // MARK: - Вспомогательная логика

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
        return min(max(i, tuning.strings.startIndex), tuning.strings.endIndex - 1)
    }

    /// Экспоненциальное сглаживание с защитой от "скачков"
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

    /// Фиксация "попал в ноту": |смещение| ≤ stableCents в течение stableHold
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

    /// Приводим измеренную частоту к ближайшей октаве относительно target (±600¢).
    /// Если maxShift задан (например, =1 при ручной настройке), ограничиваем количество удвоений/делений,
    /// чтобы не "подгонять E2 к E4" и наоборот.
    private func foldToTargetOctave(_ f: Double, target: Double, maxShift: Int?) -> (f: Double, shifts: Int) {
        guard f > 0, target > 0 else { return (f, 0) }
        var g = f
        var shifts = 0

        // тянем к диапазону ±600¢
        while PitchMath.cents(from: g, to: target) <= -600 {
            if let m = maxShift, shifts >= m { break }
            g *= 2
            shifts += 1
        }
        while PitchMath.cents(from: g, to: target) >= 600 {
            if let m = maxShift, shifts <= -m { break }
            g /= 2
            shifts -= 1
        }
        return (g, shifts)
    }
}
