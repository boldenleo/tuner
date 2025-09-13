//
//  GuitarStringsView.swift
//  Tuner
//
//  Created by Denis Boliachkin on 13/9/25.
//

import SwiftUI

public struct GuitarStringsView: View {
    
    public var body: some View {
        VStack {
            HStack{
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Spacer()
                Circle().fill(Color.red).frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    GuitarStringsView()
}
