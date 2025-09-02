//
//  MicViewModel.swift
//  Tuner
//
//  Created by Denis Boliachkin on 31/8/25.
//

import Foundation
import AVFoundation
import AudioNoteKit

@MainActor
final class MicViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var sampleRate: Double = 0
    @Published var rmsValue: Float = 0
    @Published var frequencyHz: Double = 0
    @Published var confidence: Double = 0

    private let mic = MicEngine()
    private var detector = AutoCorrelationPitchDetector()
    
    let tuner = TunerViewModel()

    func start() {
        requestMicPermission { [weak self] granted in
            guard let self else { return }
            if granted { self.startEngine() }
            else { self.isRunning = false }
        }
    }

    func stop() {
        mic.stop()
        isRunning = false
    }

    // MARK: - Permission (iOS 17+)
    private func requestMicPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined:
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async { completion(granted) }
                }
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async { completion(granted) }
                }
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }

    // MARK: - Engine
    private func startEngine() {
        do {
            try mic.start { [weak self] samples, sr in
                guard let self else { return }

                var x = samples
                let level = rms(x)
                if level < 0.01 {
                    DispatchQueue.main.async {
                        self.rmsValue = level
                        self.sampleRate = sr
                        self.frequencyHz = 0
                        self.confidence = 0
                    }
                    return
                }

                if let pitch = self.detector.process(samples: x, sampleRate: sr) {
                        DispatchQueue.main.async {
                            self.sampleRate = sr
                            self.rmsValue = level
                            self.frequencyHz = pitch.frequency
                            self.confidence = pitch.confidence
                            self.tuner.updateFromDetector(freq: pitch.frequency, conf: pitch.confidence, rms: level)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.sampleRate = sr
                            self.rmsValue = level
                            self.frequencyHz = 0
                            self.confidence = 0
                            self.tuner.updateFromDetector(freq: 0, conf: 0, rms: level)
                        }
                    }
            }
            isRunning = true
        } catch {
            print("Mic start error:", error)
            isRunning = false
        }
    }
}
