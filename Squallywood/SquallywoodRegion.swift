import Foundation
import CoreGraphics

struct SquallywoodRegion: Identifiable, Codable {
    let id: String
    var points: [CGPoint]
} 