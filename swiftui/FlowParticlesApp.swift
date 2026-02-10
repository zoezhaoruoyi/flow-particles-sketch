import SwiftUI

@main
struct FlowParticlesApp: App {
    var body: some Scene {
        WindowGroup {
            FlowParticlesView()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
        }
    }
}
