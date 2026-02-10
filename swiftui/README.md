# Flow Particles Sketch — SwiftUI Implementation

SwiftUI + Canvas (iOS 15+) implementation of the Flow Particles interactive drawing effect.

## Files

| File | Description |
|------|-------------|
| `FlowParticlesApp.swift` | App entry point |
| `Models.swift` | Data types: TouchPoint, NebulaParticle, Stroke, Constants |
| `AudioAnalyzer.swift` | Microphone input → normalized volume (0~1) |
| `ParticleGenerator.swift` | Stroke → particle generation (3-layer: core/dust/nebula) |
| `FlowParticlesView.swift` | Main view: touch input + 60fps Canvas rendering + particle physics |

## Setup in Xcode

1. Create a new **iOS App** project (SwiftUI, Swift)
2. Delete the default `ContentView.swift`
3. Copy all 5 `.swift` files into the project
4. In `Info.plist`, add: `NSMicrophoneUsageDescription` = "Audio reactivity for particles"
5. Build & Run (iOS 15+ / iPhone or iPad)

## Architecture

```
Touch Input (DragGesture)
    ↓
Particle Generation (touchUp)
    ↓
60fps Render Loop (TimelineView + Canvas)
    ↓
Particle Physics: Flow + Ripple + Turbulence
    ↑
Audio Analyzer (AVAudioEngine → volume 0~1)
```

## Key Formulas

All formulas match the web version exactly. See the root `docs/` folder for the full technical spec.
