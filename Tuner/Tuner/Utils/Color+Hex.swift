//
//  Color+Hex.swift
//  Tuner
//
//  Created by Denis Boliachkin on 4/9/25.
//

import SwiftUI

public extension Color {
    init(hex: Int) {
        let r, g, b, a: Double
        if hex > 0xFFFFFF { // AARRGGBB
            a = Double((hex >> 24) & 0xFF) / 255.0
            r = Double((hex >> 16) & 0xFF) / 255.0
            g = Double((hex >> 8)  & 0xFF) / 255.0
            b = Double( hex        & 0xFF) / 255.0
        } else {             // RRGGBB
            a = 1.0
            r = Double((hex >> 16) & 0xFF) / 255.0
            g = Double((hex >> 8)  & 0xFF) / 255.0
            b = Double( hex        & 0xFF) / 255.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    init(hex string: String) {
        var s = string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#")  { s.removeFirst() }
        if s.hasPrefix("0X") { s.removeFirst(2) }

        if s.count == 3 || s.count == 4 {
            s = s.map { "\($0)\($0)" }.joined()
        }

        let value = UInt64(s, radix: 16) ?? 0
        let r, g, b, a: Double

        switch s.count {
        case 8: // AARRGGBB
            a = Double((value >> 24) & 0xFF) / 255.0
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8)  & 0xFF) / 255.0
            b = Double( value        & 0xFF) / 255.0
        case 6: // RRGGBB
            a = 1.0
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8)  & 0xFF) / 255.0
            b = Double( value        & 0xFF) / 255.0
        default:
            self = .clear
            return
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
