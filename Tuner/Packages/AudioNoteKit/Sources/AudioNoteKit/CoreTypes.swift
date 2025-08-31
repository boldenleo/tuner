//
//  CoreTypes.swift
//  AudioNoteKit
//
//  Created by Denis Boliachkin on 31/8/25.
//

import Foundation

public struct PitchEstimate {
    public let frequency: Double
    public let confidence: Double
    public init(frequency: Double, confidence: Double) {
        self.frequency = frequency
        self.confidence = confidence
    }
}
