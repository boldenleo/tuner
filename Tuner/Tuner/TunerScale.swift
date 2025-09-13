//
//  TunerScale.swift
//  Tuner
//
//  Created by Denis Boliachkin on 13/9/25.
//

import Foundation

struct TunerScale {
    let displayRange: Double = 50       // ±50 ¢
    let divisionCents: Double = 5       // 1 деление = 5 ¢

    // половины зон (в центах)
    var greenHalf: Double   { 2 * divisionCents }   // ±10 ¢
    var neutralHalf: Double { 7 * divisionCents }   // 2 + 5 = 7 делений = ±35 ¢
}

enum TuneZone { case green, neutral, red }

extension TunerScale {
    func zone(for cents: Double) -> TuneZone {
        let a = abs(cents)
        if a <= greenHalf   { return .green }
        if a <= neutralHalf { return .neutral }
        return .red
    }
}
