import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
import Combine
import UserNotifications
import AVFoundation

class BlockingManager: ObservableObject {
    static let shared = BlockingManager()
    
    @Published var selection = FamilyActivitySelection()
    @Published var activeSessions: [ApplicationToken: Date] = [:]
    
    // Deprecated but kept to avoid breaking other views temporarily if they reference it
    @Published var currentlyUnblockedToken: ApplicationToken?
    @Published var sessionEndTime: Date?
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    
    // Ensure this matches your entitlements exactly
    private let appGroupID = "group.com.pratik.physically"
    
    private init() {
        loadSelection()
        // Restore any persisted sessions if we had them (omitted for MVP, assuming fresh start)
    }
    
    // MARK: - Audio Keep-Alive
    private func setupSilentAudio() {
        if audioPlayer != nil { return } // Already setup
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let sampleRate = 44100.0
            let duration = 1.0
            let frameCount = Int(sampleRate * duration)
            let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            
            let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("silent.wav")
            
            if !FileManager.default.fileExists(atPath: tempUrl.path) {
                let audioFile = try AVAudioFile(forWriting: tempUrl, settings: audioFormat.settings)
                let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount))!
                buffer.frameLength = AVAudioFrameCount(frameCount)
                try audioFile.write(from: buffer)
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: tempUrl)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.01
            audioPlayer?.prepareToPlay()
            
        } catch {
            print("Audio Setup Failed: \(error)")
        }
    }
    
    // MARK: - Shield Management
    
    func updateShield() {
        // Calculate which apps should be blocked
        // Start with ALL selected apps
        var appsToBlock = selection.applicationTokens
        
        // Remove any apps that are currently in an active session
        let activeTokens = Set(activeSessions.keys)
        appsToBlock.subtract(activeTokens)
        
        // Apply the shield
        store.shield.applications = appsToBlock
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        
        saveSelection()
    }
    
    private func saveSelection() {
        UserDefaults.shared.appSelection = selection
    }
    
    private func loadSelection() {
        selection = UserDefaults.shared.appSelection
    }
    
    // MARK: - Session Management
    
    func startSession(minutes: Int, for token: ApplicationToken? = nil) {
        // 0. Start Keep-Alive
        setupSilentAudio()
        if audioPlayer?.isPlaying == false {
            audioPlayer?.play()
            print("Main App: Silent Audio Started")
        }
        
        // 1. Calculate End Time
        let now = Date()
        let end = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        
        // 2. Update Active Sessions
        DispatchQueue.main.async {
            if let token = token {
                // Specific App Unlock
                self.activeSessions[token] = end
            } else {
                // Global Unlock (Special case: we might want to track a "global" token or just clear all)
                // For now, let's say global unlock clears the shield but we don't track it in the dict easily
                // unless we define a special key. 
                // BETTER: If token is nil, we just don't block anything for X minutes.
                // But the user asked for "separate timers for each app".
                // Let's assume this is primarily for specific app unlocks.
                // If global, we can just clear the shield and set a "global" timer.
                // For simplicity in this refactor, let's handle specific tokens.
                // If global is requested, we can iterate all selected apps and add them to activeSessions?
                // That seems safest.
                for appToken in self.selection.applicationTokens {
                    self.activeSessions[appToken] = end
                }
            }
            
            // 3. Update Shield immediately
            self.updateShield()
            
            // 4. Start/Update Polling Timer
            self.startPolling()
        }
    }
    
    private func startPolling() {
        timer?.invalidate()
        // Poll every 0.5s
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkSessions()
        }
    }
    
    private func checkSessions() {
        let now = Date()
        var didExpire = false
        
        // Check for expired sessions
        for (token, endTime) in activeSessions {
            if now >= endTime {
                activeSessions.removeValue(forKey: token)
                didExpire = true
                print("Session expired for token: \(token)")
            }
        }
        
        if didExpire {
            // Force Refresh Strategy
            forceRefreshShield()
        }
        
        // Stop audio if no sessions left
        if activeSessions.isEmpty {
            timer?.invalidate()
            audioPlayer?.stop()
            print("All sessions ended. Audio stopped.")
        }
    }
    
    private func forceRefreshShield() {
        // Just update the shield directly.
        // The "Flash All" strategy (.all()) causes the shield to appear on unblocked apps briefly.
        // By simply recalculating and applying the correct shield, we avoid this artifact.
        DispatchQueue.main.async {
            self.updateShield()
            print("Shield Refreshed after expiration.")
        }
    }
    
    func cancelSession(for token: ApplicationToken) {
        activeSessions.removeValue(forKey: token)
        forceRefreshShield()
        
        if activeSessions.isEmpty {
            timer?.invalidate()
            audioPlayer?.stop()
        }
    }
    
    func unblockTemporarily(duration: TimeInterval = 900, for token: ApplicationToken? = nil) {
        let minutes = Int(ceil(duration / 60.0))
        startSession(minutes: minutes, for: token)
    }
    
    func unblockApps(for duration: TimeInterval, token: ApplicationToken? = nil) {
        unblockTemporarily(duration: duration, for: token)
    }
}
