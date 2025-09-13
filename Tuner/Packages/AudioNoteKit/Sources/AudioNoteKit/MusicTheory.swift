//
//  MusicTheory.swift
//  AudioNoteKit
//
//  Created by Denis Boliachkin on 2/9/25.
//

import Foundation

public enum NoteName: Int, CaseIterable, Sendable {
    case C = 0, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B

    public var display: String {
        switch self {
        case .C:  return "C"
        case .Cs: return "C#"
        case .D:  return "D"
        case .Ds: return "D#"
        case .E:  return "E"
        case .F:  return "F"
        case .Fs: return "F#"
        case .G:  return "G"
        case .Gs: return "G#"
        case .A:  return "A"
        case .As: return "A#"
        case .B:  return "B"
        }
    }
}

public struct Note: Hashable, Sendable {
    public let name: NoteName
    public let octave: Int
    public init(_ name: NoteName, _ octave: Int) {
        self.name = name; self.octave = octave
    }

    public var midi: Int {
        let semitoneFromC = name.rawValue
        return (octave + 1) * 12 + semitoneFromC
    }

    public var display: String { "\(name.display)\(octave)" }

    public func frequency(a4: Double = 440.0) -> Double {
        let n = Double(midi - 69)
        return a4 * pow(2.0, n / 12.0)
    }
}

public enum Tuning: Sendable, Equatable {
    case guitarStandardE                         // E2 A2 D3 G3 B3 E4
    case guitarDropD                            // D2 A2 D3 G3 B3 E4
    case guitarOpenG                            // D2 G2 D3 G3 B3 D4
    case custom(name: String, strings: [Note])  // 6→1

    public var name: String {
        switch self {
        case .guitarStandardE: return "Standard E"
        case .guitarDropD:     return "Drop D"
        case .guitarOpenG:     return "Open G"
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
        case .custom(_, let s):
            return s
        }
    }
}

public enum PitchMath {
    public static func midi(forFrequency f: Double, a4: Double = 440.0) -> Double {
        69.0 + 12.0 * log2(f / a4)
    }

    public static func frequency(forMidi m: Double, a4: Double = 440.0) -> Double {
        a4 * pow(2.0, (m - 69.0) / 12.0)
    }

    public static func cents(from f: Double, to target: Double) -> Double {
        1200.0 * log2(f / target)
    }

    public static func nearestNote(for f: Double, a4: Double = 440.0) -> (note: Note, cents: Double) {
        let m = round(midi(forFrequency: f, a4: a4))
        let noteName = NoteName(rawValue: Int(m) % 12)!
        let octave = Int(floor(m / 12.0)) - 1
        let note = Note(noteName, octave)
        let targetF = note.frequency(a4: a4)
        let cents = cents(from: f, to: targetF)
        return (note, cents)
    }

    public static func deviationToStrings(frequency f: Double,
                                          tuning: Tuning,
                                          a4: Double = 440.0) -> (index: Int, cents: Double)
    {
        var bestIdx = 0
        var bestAbs = Double.greatestFiniteMagnitude
        var bestCents = 0.0

        for (i, note) in tuning.strings.enumerated() {
            let t = note.frequency(a4: a4)
            var cents = cents(from: f, to: t)

            cents = wrapToPlusMinus600(cents)
            let absC = abs(cents)
            if absC < bestAbs {
                bestAbs = absC
                bestCents = cents
                bestIdx = i
            }
        }
        return (bestIdx, bestCents)
    }

    private static func wrapToPlusMinus600(_ c: Double) -> Double {
        var x = c.truncatingRemainder(dividingBy: 1200.0)
        if x > 600 { x -= 1200 }
        if x < -600 { x += 1200 }
        return x
    }
}

public extension NoteName {
    var isSharp: Bool {
        switch self {
        case .Cs, .Ds, .Fs, .Gs, .As: return true
        default: return false
        }
    }
    var letter: String {
        switch self {
        case .C, .Cs: return "C"
        case .D, .Ds: return "D"
        case .E:      return "E"
        case .F, .Fs: return "F"
        case .G, .Gs: return "G"
        case .A, .As: return "A"
        case .B:      return "B"
        }
    }
}
