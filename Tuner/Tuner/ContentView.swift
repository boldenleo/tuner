//
//  ContentView.swift
//  Tuner
//
//  Created by Denis Boliachkin on 31/8/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = MicViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sample rate: \(Int(vm.sampleRate)) Hz")
                .font(.caption).foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: "RMS: %.4f", vm.rmsValue)).monospaced()
                ProgressView(value: min(1, Double(vm.rmsValue) * 20))
                    .progressViewStyle(.linear)
            }

            HStack(spacing: 12) {
                Text("Frequency:")
                Text(vm.frequencyHz > 0 ? String(format: "%.2f Hz", vm.frequencyHz) : "—")
                    .font(.title2).monospaced()
                Spacer()
                Text(String(format: "conf: %.2f", vm.confidence))
                    .font(.caption).foregroundStyle(.secondary).monospaced()
            }

            Spacer()

            Button(vm.isRunning ? "Stop" : "Start") {
                vm.isRunning ? vm.stop() : vm.start()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

#Preview { ContentView() }
