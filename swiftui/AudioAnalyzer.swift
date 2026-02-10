import AVFoundation
import Combine

/// Captures microphone input and provides a normalized volume level (0~1)
class AudioAnalyzer: ObservableObject {
    @Published var volume: CGFloat = 0
    @Published var isActive = false
    @Published var error: String?
    
    private var audioEngine: AVAudioEngine?
    private var smoothVolume: CGFloat = 0
    
    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            self.error = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 256, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let channelData = buffer.floatChannelData?[0]
            let frames = Int(buffer.frameLength)
            guard let data = channelData, frames > 0 else { return }
            
            var sum: Float = 0
            for i in 0..<frames {
                sum += abs(data[i])
            }
            let rawVolume = CGFloat(sum / Float(frames))
            
            // Smooth with lerp (matching web: 0.15 factor)
            self.smoothVolume += (rawVolume - self.smoothVolume) * 0.15
            
            DispatchQueue.main.async {
                self.volume = self.smoothVolume
            }
        }
        
        do {
            try engine.start()
            audioEngine = engine
            isActive = true
        } catch {
            self.error = "Engine start error: \(error.localizedDescription)"
        }
    }
    
    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isActive = false
        volume = 0
    }
}
