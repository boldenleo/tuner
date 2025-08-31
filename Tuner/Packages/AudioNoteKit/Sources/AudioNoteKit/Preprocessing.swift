//
//  Preprocessing.swift
//  AudioNoteKit
//
//  Created by Denis Boliachkin on 31/8/25.
//

import Foundation

@inlinable
public func removeDC(_ x: inout [Float]) {
    guard !x.isEmpty else { return }
    var sum: Float = 0
    for v in x { sum += v }
    let mean = sum / Float(x.count)
    if mean != 0 {
        for i in x.indices { x[i] -= mean }
    }
}

@inlinable
public func rms(_ x: [Float]) -> Float {
    guard !x.isEmpty else { return 0 }
    var acc: Float = 0
    for v in x { acc += v * v }
    return sqrt(acc / Float(x.count))
}

@inlinable
public func makeHannWindow(_ n: Int) -> [Float] {
    guard n > 0 else { return [] }
    var w = [Float](repeating: 0, count: n)
    let denom = Float(n - 1)
    for i in 0..<n {
        w[i] = 0.5 - 0.5 * cosf(2.0 * .pi * Float(i) / denom)
    }
    return w
}

@inlinable
public func applyWindowInPlace(_ x: inout [Float], window: [Float]) {
    guard x.count == window.count else { return }
    for i in x.indices { x[i] *= window[i] }
}
