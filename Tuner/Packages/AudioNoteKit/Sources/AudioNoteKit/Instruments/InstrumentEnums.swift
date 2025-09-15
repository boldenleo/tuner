//
//  InstrumentEnums.swift
//  Tuner
//
//  Created by Denis Boliachkin on 15/9/25.
//

import Foundation

public enum Instrument: Sendable {
    case guitar
    case bass
    case ukulele
}

public enum TuningKind: Sendable, Equatable {
    case guitarStandardE       // E2 A2 D3 G3 B3 E4
    case guitarDropD           // D2 A2 D3 G3 B3 E4
    case guitarOpenG           // D2 G2 D3 G3 B3 D4
    // Bass
    case bassStandardE         // E1 A1 D2 G2
    // Ukulele (soprano/concert/tenor re-entrant)
    case ukuleleGCEA           // G4 C4 E4 A4
    // Пользовательское
    case custom(name: String, strings: [Note])

    public var displayName: String {
        switch self {
        case .guitarStandardE: return "Standard E"
        case .guitarDropD:     return "Drop D"
        case .guitarOpenG:     return "Open G"
        case .bassStandardE:   return "E A D G"
        case .ukuleleGCEA:     return "G C E A"
        case .custom(let n, _):return n
        }
    }

    public var strings: [Note] {
        switch self {
        case .guitarStandardE:
            return [Note(.E,2), Note(.A,2), Note(.D,3), Note(.G,3), Note(.B,3), Note(.E,4)]
        case .guitarDropD:
            return [Note(.D,2), Note(.A,2), Note(.D,3), Note(.G,3), Note(.B,3), Note(.E,4)]
        case .guitarOpenG:
            return [Note(.D,2), Note(.G,2), Note(.D,3), Note(.G,3), Note(.B,3), Note(.D,4)]
        case .bassStandardE:
            return [Note(.E,1), Note(.A,1), Note(.D,2), Note(.G,2)]
        case .ukuleleGCEA:
            return [Note(.G,4), Note(.C,4), Note(.E,4), Note(.A,4)]
        case .custom(_, let s):
            return s
        }
    }
}

public struct InstrumentSpec: Sendable, Equatable {
    public let instrument: Instrument
    public let tuning: TuningKind
    public let gauges: [Double]

    public init(instrument: Instrument, tuning: TuningKind, gauges: [Double]) {
        self.instrument = instrument
        self.tuning = tuning
        self.gauges = gauges
    }

    public var notes: [Note] { tuning.strings }
    public var stringCount: Int { notes.count }
}
