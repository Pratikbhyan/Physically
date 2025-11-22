import AVFoundation
import Foundation
import Combine

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var coinPlayer: AVAudioPlayer?
    private var registerPlayer: AVAudioPlayer?
    private var correctionPlayer: AVAudioPlayer?
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        // Load sound files (assuming they are in the bundle)
        // In a real app, you'd add these files to the project.
        // For now, we'll try to load them, but handle failure gracefully.
        
        if let url = Bundle.main.url(forResource: "coin", withExtension: "wav") {
            coinPlayer = try? AVAudioPlayer(contentsOf: url)
            coinPlayer?.prepareToPlay()
        }
        
        if let url = Bundle.main.url(forResource: "cash_register", withExtension: "wav") {
            registerPlayer = try? AVAudioPlayer(contentsOf: url)
            registerPlayer?.prepareToPlay()
        }
        
        if let url = Bundle.main.url(forResource: "down", withExtension: "wav") {
            correctionPlayer = try? AVAudioPlayer(contentsOf: url)
            correctionPlayer?.prepareToPlay()
        }
    }
    
    func playCoin() {
        coinPlayer?.stop()
        coinPlayer?.currentTime = 0
        coinPlayer?.play()
    }
    
    func playRegister() {
        registerPlayer?.stop()
        registerPlayer?.currentTime = 0
        registerPlayer?.play()
    }
    
    func playCorrection(pan: Float) {
        correctionPlayer?.stop()
        correctionPlayer?.currentTime = 0
        correctionPlayer?.pan = pan // -1.0 for left, 1.0 for right
        correctionPlayer?.play()
    }
}
