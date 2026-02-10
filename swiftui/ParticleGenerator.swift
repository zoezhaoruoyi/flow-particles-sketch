import Foundation
import CoreGraphics

/// Generates particles along a stroke path
enum ParticleGenerator {
    
    /// Generate particles distributed along the stroke
    static func generate(from points: [TouchPoint]) -> (particles: [NebulaParticle], centerX: CGFloat, centerY: CGFloat) {
        guard points.count >= 2 else { return ([], 0, 0) }
        
        // 1. Calculate total arc length
        var totalLength: CGFloat = 0
        for i in 1..<points.count {
            totalLength += distance(points[i-1], points[i])
        }
        guard totalLength > 0 else { return ([], 0, 0) }
        
        // 2. Calculate center for ripple
        let cx = points.map(\.x).reduce(0, +) / CGFloat(points.count)
        let cy = points.map(\.y).reduce(0, +) / CGFloat(points.count)
        
        // 3. Determine particle count
        let particleCount = min(Int(totalLength * Constants.particleDensity), 5000)
        
        var particles: [NebulaParticle] = []
        particles.reserveCapacity(particleCount)
        
        for i in 0..<particleCount {
            let t = CGFloat(i) / CGFloat(max(1, particleCount - 1))
            let targetDist = t * totalLength
            
            // Find position on curve
            guard let pos = pointOnCurve(points: points, at: targetDist) else { continue }
            
            // Determine layer
            let rand = CGFloat.random(in: 0...1)
            let layer: ParticleLayer
            let spreadRadius: CGFloat
            let opacity: CGFloat
            let sizeMultiplier: CGFloat
            
            if rand > 0.7 {
                layer = .core
                spreadRadius = Constants.coreWidth
                opacity = CGFloat.random(in: 0.8...1.0)
                sizeMultiplier = 0.15
            } else if rand < 0.2 {
                layer = .nebula
                spreadRadius = Constants.nebulaWidth * 1.5
                opacity = CGFloat.random(in: 0.05...0.2)
                sizeMultiplier = 0.35
            } else {
                layer = .dust
                spreadRadius = Constants.nebulaWidth
                opacity = CGFloat.random(in: 0.3...0.7)
                sizeMultiplier = 0.2
            }
            
            // Random offset
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let radius = CGFloat.random(in: 0...spreadRadius)
            let offsetX = cos(angle) * radius
            let offsetY = sin(angle) * radius
            
            // Size
            let size = CGFloat.random(in: 0.5...2.5) * sizeMultiplier
            
            // Brightness (20% chance of 2x)
            let brightness: CGFloat = CGFloat.random(in: 0...1) < 0.2 ? 2.0 : 1.0
            
            particles.append(NebulaParticle(
                originX: pos.x,
                originY: pos.y,
                offsetX: offsetX,
                offsetY: offsetY,
                x: pos.x + offsetX,
                y: pos.y + offsetY,
                size: size,
                opacity: opacity,
                phase: CGFloat.random(in: 0...(2 * .pi)),
                freq: CGFloat.random(in: 0.5...2.0),
                layer: layer,
                brightnessMultiplier: brightness,
                index: i
            ))
        }
        
        return (particles, cx, cy)
    }
    
    // MARK: - Helpers
    
    private static func distance(_ a: TouchPoint, _ b: TouchPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }
    
    /// Find the (x, y) position at a given arc distance along the polyline
    private static func pointOnCurve(points: [TouchPoint], at targetDist: CGFloat) -> CGPoint? {
        var currentDist: CGFloat = 0
        for j in 1..<points.count {
            let d = distance(points[j-1], points[j])
            if currentDist + d >= targetDist || j == points.count - 1 {
                let localT = d == 0 ? 0 : (targetDist - currentDist) / d
                let x = points[j-1].x + (points[j].x - points[j-1].x) * localT
                let y = points[j-1].y + (points[j].y - points[j-1].y) * localT
                return CGPoint(x: x, y: y)
            }
            currentDist += d
        }
        return nil
    }
}
