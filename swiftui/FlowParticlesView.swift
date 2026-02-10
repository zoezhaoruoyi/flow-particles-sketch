import SwiftUI

struct FlowParticlesView: View {
    @StateObject private var audio = AudioAnalyzer()
    @State private var strokes: [Stroke] = []
    @State private var currentPoints: [TouchPoint] = []
    @State private var isDrawing = false
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0.02, blue: 0.04)
            
            // Main canvas - 60fps rendering
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let v = audio.volume
                    let screenCenter = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    // 1. Draw active stroke (tapered brush)
                    if isDrawing && currentPoints.count > 1 {
                        drawTaperedStroke(context: &context, points: currentPoints)
                    }
                    
                    // 2. Draw particles with additive blending
                    context.blendMode = .plusLighter
                    
                    for stroke in strokes {
                        for p in stroke.particles {
                            let pos = calculatePosition(
                                particle: p, time: time, volume: v,
                                center: screenCenter,
                                strokeCenter: CGPoint(x: stroke.centerX, y: stroke.centerY)
                            )
                            let alpha = calculateAlpha(particle: p, time: time, volume: v)
                            let drawSize = p.size * (1 + v * 1.5)
                            
                            guard alpha > 0.01 else { continue }
                            
                            // Glow (larger, faint)
                            if drawSize > 0.8 {
                                let glowRect = CGRect(
                                    x: pos.x - drawSize * 5,
                                    y: pos.y - drawSize * 5,
                                    width: drawSize * 10,
                                    height: drawSize * 10
                                )
                                context.opacity = alpha * 0.2
                                context.fill(
                                    Circle().path(in: glowRect),
                                    with: .color(Color(red: 1, green: 0.92, blue: 0.7))
                                )
                            }
                            
                            // Core (bright white)
                            let coreRect = CGRect(
                                x: pos.x - drawSize,
                                y: pos.y - drawSize,
                                width: drawSize * 2,
                                height: drawSize * 2
                            )
                            context.opacity = alpha * 0.95
                            context.fill(
                                Circle().path(in: coreRect),
                                with: .color(.white)
                            )
                        }
                    }
                }
            }
            // Touch handling
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = TouchPoint(
                            x: value.location.x,
                            y: value.location.y,
                            pressure: 1.0,
                            timestamp: Date().timeIntervalSinceReferenceDate
                        )
                        
                        if !isDrawing {
                            isDrawing = true
                            currentPoints = [point]
                        } else {
                            // Distance check (>2px)
                            if let last = currentPoints.last {
                                let dist = hypot(point.x - last.x, point.y - last.y)
                                if dist > Constants.minPointDistance {
                                    currentPoints.append(point)
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isDrawing = false
                        if currentPoints.count > 3 {
                            let result = ParticleGenerator.generate(from: currentPoints)
                            let stroke = Stroke(
                                points: currentPoints,
                                particles: result.particles,
                                centerX: result.centerX,
                                centerY: result.centerY
                            )
                            strokes.append(stroke)
                        }
                        currentPoints = []
                    }
            )
            
            // UI Overlay
            VStack {
                // Title
                Text("FLOW PARTICLES")
                    .font(.system(size: 12, weight: .light))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 60)
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Instructions
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Draw freely on screen")
                            .font(.system(size: 10, weight: .light))
                        Text("Particles drift to sound")
                            .font(.system(size: 10, weight: .light))
                    }
                    .foregroundColor(.white.opacity(0.2))
                    
                    Spacer()
                    
                    // Mic button
                    Button {
                        if audio.isActive {
                            audio.stop()
                        } else {
                            audio.start()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(audio.isActive ? Color.yellow.opacity(0.6) : Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 48, height: 48)
                            
                            if audio.isActive {
                                Circle()
                                    .fill(Color.yellow.opacity(0.15))
                                    .frame(width: 48, height: 48)
                            }
                            
                            Text("🎤")
                                .font(.system(size: 22))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .allowsHitTesting(true)
        }
    }
    
    // MARK: - Drawing
    
    /// Draw tapered stroke (thick start, thin end)
    private func drawTaperedStroke(context: inout GraphicsContext, points: [TouchPoint]) {
        let count = CGFloat(points.count)
        for i in 1..<points.count {
            let prev = points[i-1].cgPoint
            let curr = points[i].cgPoint
            let width = max(1, 10 * (count - CGFloat(i)) / count)
            
            var path = Path()
            path.move(to: prev)
            path.addLine(to: curr)
            
            context.stroke(
                path,
                with: .color(.white.opacity(0.8)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
    }
    
    // MARK: - Particle Physics
    
    /// Calculate particle position for current frame
    private func calculatePosition(
        particle p: NebulaParticle,
        time: TimeInterval,
        volume v: CGFloat,
        center: CGPoint,
        strokeCenter: CGPoint
    ) -> CGPoint {
        let t = CGFloat(time)
        
        // A. Flow (always active)
        let flowX = sin(t * Constants.flowSpeed + p.phase + p.originY * 0.005) * 5
        let flowY = cos(t * (Constants.flowSpeed * 0.7) + p.phase + p.originX * 0.005) * 8
        
        // B. Ripple (sound-driven)
        let dx = (p.originX + p.offsetX) - center.x
        let dy = (p.originY + p.offsetY) - center.y
        let distToCenter = hypot(dx, dy)
        let rippleOffset = sin(distToCenter * Constants.rippleFreq - t * Constants.rippleSpeed) * (v * Constants.maxRippleAmp)
        let rippleX = distToCenter > 0 ? (dx / distToCenter) * rippleOffset : 0
        let rippleY = distToCenter > 0 ? (dy / distToCenter) * rippleOffset : 0
        
        // C. Turbulence
        let idx = CGFloat(p.index)
        let turbX = sin(t * 2 + idx * 0.1) * (2 + v * 10)
        let turbY = cos(t * 1.5 + idx * 0.15) * (2 + v * 10)
        
        return CGPoint(
            x: p.originX + p.offsetX + flowX + rippleX + turbX,
            y: p.originY + p.offsetY + flowY + rippleY + turbY
        )
    }
    
    /// Calculate particle alpha for current frame
    private func calculateAlpha(particle p: NebulaParticle, time: TimeInterval, volume v: CGFloat) -> Double {
        let t = CGFloat(time)
        let breathe = 0.8 + sin(t * 3 + p.phase) * 0.2
        let soundBoost = 1 + v * 0.6
        return min(1.0, Double(p.opacity * breathe * soundBoost))
    }
}

#Preview {
    FlowParticlesView()
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
}
