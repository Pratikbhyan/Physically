import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
import Combine

class BlockingManager: ObservableObject {
    static let shared = BlockingManager()
    
    @Published var selection = FamilyActivitySelection()
    @Published var currentlyUnblockedToken: ApplicationToken?
    @Published var sessionEndTime: Date?
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    
    // Ensure this matches your entitlements exactly
    private let appGroupID = "group.com.pratik.physically"
    
    private init() {
        loadSelection()
    }
    
    func updateShield() {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens
        
        saveSelection()
        
        // Apply shield immediately
        store.shield.applications = applications
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(categories)
    }
    
    private func saveSelection() {
        UserDefaults.shared.appSelection = selection
    }
    
    private func loadSelection() {
        selection = UserDefaults.shared.appSelection
    }
    
    func startSession(minutes: Int, for token: ApplicationToken? = nil) {
        // 1. Save state
        saveSelection()
        
        // 2. Unlock immediately (Main Thread for UI responsiveness)
        DispatchQueue.main.async {
            if let token = token {
                // Specific unlock
                var tempApplications = self.selection.applicationTokens
                tempApplications.remove(token)
                self.store.shield.applications = tempApplications
                // Keep categories blocked if unlocking specific app
                self.store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(self.selection.categoryTokens)
                
                // Track Active Session
                self.currentlyUnblockedToken = token
                self.sessionEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
            } else {
                // Global unlock
                self.store.shield.applications = nil
                self.store.shield.applicationCategories = nil
                self.currentlyUnblockedToken = nil
                self.sessionEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
            }
            self.store.shield.webDomains = nil
        }
        
        // 3. Stop existing monitoring
        center.stopMonitoring([.sessionTimer])
        
        // 4. Create Schedule
        // We use the requested minutes directly.
        // If it's too short for the system (<15 min), the Monitor might fail (caught below),
        // but the Backup Timer (added next) will handle the locking.
        let now = Date()
        let end = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        
        // We schedule the "window" to cover the unlock period.
        // The Monitor will fire intervalDidEnd when 'end' is reached.
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: end),
            repeats: false,
            warningTime: nil
        )
        
        do {
            try center.startMonitoring(.sessionTimer, during: schedule)
            print("Physically: Monitoring started for \(minutes) minutes.")
        } catch {
            print("Physically: Schedule FAILED (likely too short): \(error.localizedDescription)")
            // We continue, relying on the Backup Timer below.
        }
        
        // 5. BACKUP TIMER (Essential for short unlocks < 15 mins)
        // If the Monitor fails or the app is in the foreground, this ensures re-locking.
        // Note: We do NOT use beginBackgroundTask here because we cannot keep the app alive
        // for arbitrary durations (iOS limits to ~30s). This timer works while the app is
        // in the foreground or when it returns to foreground.
        let duration = TimeInterval(minutes * 60)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            print("Main App: Backup Timer ended. Re-locking.")
            self.stopSession() // Re-use stopSession to lock everything
        }
    }
    
    func stopSession() {
        center.stopMonitoring([.sessionTimer])
        updateShield() // Re-lock everything
        
        // Clear Active Session State
        DispatchQueue.main.async {
            self.currentlyUnblockedToken = nil
            self.sessionEndTime = nil
        }
    }
    
    func unblockTemporarily(duration: TimeInterval = 900, for token: ApplicationToken? = nil) {
        // Convert to minutes. We do NOT clamp to 15 anymore.
        // If < 15, DeviceActivity might fail, but Backup Timer handles it.
        let minutes = Int(ceil(duration / 60.0))
        startSession(minutes: minutes, for: token)
    }
}
