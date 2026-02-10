import Foundation
import CoreGraphics

// MARK: - Core Data Types

struct TouchPoint {
    var x: CGFloat
    var y: CGFloat
    var pressure: CGFloat
    var timestamp: TimeInterval
    
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

enum ParticleLayer {
    case core    // 30% - tight to curve, bright
    case dust    // 50% - medium spread
    case nebula  // 20% - wide spread, faint
}

struct NebulaParticle {
    // Anchor on curve (fixed)
    let originX: CGFloat
    let originY: CGFloat
    
    // Random offset from anchor (fixed)
    let offsetX: CGFloat
    let offsetY: CGFloat
    
    // Current draw position (updated each frame)
    var x: CGFloat
    var y: CGFloat
    
    // Properties
    let size: CGFloat
    let opacity: CGFloat
    let phase: CGFloat          // 0~2π random phase
    let freq: CGFloat           // individual frequency
    let layer: ParticleLayer
    let brightnessMultiplier: CGFloat  // 20% chance = 2.0, else 1.0
    
    // Index for turbulence variation
    let index: Int
}

struct Stroke: Identifiable {
    let id = UUID()
    let points: [TouchPoint]
    var particles: [NebulaParticle]
    let centerX: CGFloat
    let centerY: CGFloat
}

// MARK: - Golden Constants

enum Constants {
    static let flowSpeed: CGFloat = 0.08
    static let particleDensity: CGFloat = 25.0
    static let rippleFreq: CGFloat = 0.015
    static let rippleSpeed: CGFloat = 5.0
    static let maxRippleAmp: CGFloat = 40
    static let coreWidth: CGFloat = 5
    static let nebulaWidth: CGFloat = 45
    static let minPointDistance: CGFloat = 2
}
