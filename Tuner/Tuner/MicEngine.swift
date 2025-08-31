//
//  MicEngine.swift
//  Tuner
//
//  Created by Denis Boliachkin on 31/8/25.
//

import AVFoundation

final class MicEngine {
    private let engine = AVAudioEngine()
    private var isStarted = false

    func start(onFrame: @escaping (_ samples: [Float], _ sampleRate: Double) -> Void) throws {
        guard !isStarted else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [])
        try session.setPreferredSampleRate(44_100)
        try session.setPreferredIOBufferDuration(0.023)
        try session.setActive(true)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let bufferSize: AVAudioFrameCount = 2048

        input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, _ in
            guard let ch = buffer.floatChannelData else { return }
            let n = Int(buffer.frameLength)
            if n == 0 { return }

            let samples = Array(UnsafeBufferPointer(start: ch[0], count: n))
            onFrame(samples, format.sampleRate)
        }

        engine.prepare()
        try engine.start()
        isStarted = true
    }

    func stop() {
        guard isStarted else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        isStarted = false
    }
}
