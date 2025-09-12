//
//  ContentView.swift
//  Tuner
//
//  Created by Denis Boliachkin on 31/8/25.
//

import SwiftUI
import AudioNoteKit

struct ContentView: View {
    @StateObject private var mic = MicViewModel()

    private var selectedStringBinding: Binding<Int> {
        Binding(
            get: { mic.tuner.selectedStringIndex },
            set: { mic.tuner.selectedStringIndex = $0 }
        )
    }

    private var a4Binding: Binding<Double> {
        Binding(
            get: { mic.tuner.a4 },
            set: { mic.tuner.a4 = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sample rate: \(Int(mic.sampleRate)) Hz")
                .font(.caption).foregroundStyle(.secondary)

            HStack {
                Text(String(format: "RMS: %.4f", mic.rmsValue)).monospaced()
                Spacer()
                Text(String(format: "conf: %.2f", mic.confidence))
                    .font(.caption).foregroundStyle(.secondary).monospaced()
            }

            TunerArcMeterView(
                note: mic.tuner.nearestNote,
                isInTune: mic.tuner.isStable
            )
                .frame(maxWidth: .infinity)
                .frame(height: 340)

            Text(String(format: "%+.1f cents", mic.tuner.centsToTarget))
                .font(.footnote)
                .foregroundStyle(mic.tuner.isStable ? .green : .secondary)
                .monospacedDigit()

            Spacer()

            StringsRow(
                tuning: mic.tuner.tuning,
                selected: selectedStringBinding
            )

            HStack {
                Button(mic.isRunning ? "Stop" : "Start") {
                    mic.isRunning ? mic.stop() : mic.start()
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Stepper("A4 = \(Int(mic.tuner.a4)) Hz",
                        value: a4Binding, in: 430...450, step: 1)
                    .font(.footnote)
            }
        }
        .padding()
        .padding()
        .onAppear {
            mic.start()
            mic.tuner.tuning = .guitarStandardE
        }
        .onDisappear { mic.stop() }
        .appBackground(Color(hex: 0x131B2A))
    }
}

// MARK: - Subviews

private struct StringsRow: View {
    let tuning: Tuning
    @Binding var selected: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(tuning.strings.enumerated()), id: \.0) { (idx, note) in
                let isSelected = (selected == idx)

                Button {
                    selected = idx
                } label: {
                    VStack(spacing: 2) {
                        Text(note.name.display).bold()
                        Text("\(note.octave)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(isSelected ? Color.blue.opacity(0.22)
                                             : Color.gray.opacity(0.12))
                    }
                    .overlay {
                        Capsule().stroke(isSelected ? Color.blue
                                                    : Color.gray.opacity(0.4), lineWidth: 1)
                    }
                }
            }
        }
    }
}

private struct TunerMeterView: View {
    let title: String
    let cents: Double
    let isStable: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.12))
                    let greenWidth = max(6, w * (6.0 / 100.0))
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.25))
                        .frame(width: greenWidth, height: h)

                    HStack {
                        Text("−50").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("0").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("+50").font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 6)
                    .frame(maxHeight: .infinity, alignment: .top)

                    let x = positionX(width: w, cents: cents)
                    Capsule()
                        .fill(isStable ? Color.green : (cents < 0 ? Color.blue : Color.red))
                        .frame(width: 4, height: h * 0.85)
                        .position(x: x, y: h/2)
                        .animation(.easeOut(duration: 0.08), value: x)
                }
            }

            Text(String(format: "%+.1f cents", cents))
                .font(.footnote).foregroundStyle(isStable ? .green : .secondary)
                .monospacedDigit()
        }
    }

    private func positionX(width: CGFloat, cents: Double) -> CGFloat {
        let pad: CGFloat = 12
        let span = max(1, width - 2*pad)
        let t = (cents + 50.0) / 100.0
        return pad + CGFloat(t) * span
    }
}

#Preview { ContentView() }
