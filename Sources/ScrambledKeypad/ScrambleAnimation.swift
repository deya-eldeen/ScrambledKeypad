import SwiftUI

struct ScrambleAnimation {
    static let outDuration: TimeInterval = 0.08
    static let inDuration: TimeInterval = 0.08
    static let maxOffset: CGFloat = 14

    static func offsets(for ids: [String]) -> [String: CGSize] {
        var result: [String: CGSize] = [:]
        result.reserveCapacity(ids.count)
        for id in ids {
            let angle = Double.random(in: 0..<Double.pi * 2)
            let distance = CGFloat.random(in: 6...maxOffset)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            result[id] = CGSize(width: dx, height: dy)
        }
        return result
    }
}
