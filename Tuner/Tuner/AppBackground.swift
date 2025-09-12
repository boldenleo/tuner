//
//  AppBackground.swift
//  Tuner
//
//  Created by Denis Boliachkin on 12/9/25.
//

import SwiftUI

struct AppBackground: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        ZStack {
            color.ignoresSafeArea(.all)
            content
        }
    }
}

extension View {
    func appBackground(_ color: Color = Color(hex: 0x131B2A)) -> some View {
        modifier(AppBackground(color: color))
    }
}
