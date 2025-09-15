//
//  Specs.swift
//  AudioNoteKit
//
//  Created by Denis Boliachkin on 15/9/25.
//

public extension InstrumentSpec {
    static let guitar6_Std = InstrumentSpec(
        instrument: .guitar,
        tuning: .guitarStandardE,
        gauges: [0.052, 0.042, 0.032, 0.024, 0.016, 0.012]
    )

    static let bass4_Std = InstrumentSpec(
        instrument: .bass,
        tuning: .bassStandardE,
        gauges: [0.105, 0.085, 0.065, 0.045]
    )

    static let ukulele_GCEA = InstrumentSpec(
        instrument: .ukulele,
        tuning: .ukuleleGCEA,
        gauges: [0.028, 0.036, 0.032, 0.024]
    )
}
