import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
import Combine

class BlockingManager: ObservableObject {
    static let shared = BlockingManager()
    
    @Published var selection = FamilyActivitySelection()
    
    private let store = ManagedSettingsStore()
    private let userDefaultsKey = "FamilyActivitySelection"
    // Ensure this matches the App Group ID you set in Xcode
    private let appGroupID = "group.com.pratik.physically"
    
    private init() {
        loadSelection()
    }
    
    func updateShield() {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens
        
        saveSelection() // Save whenever we update
        
        if applications.isEmpty && categories.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        } else {
            store.shield.applications = applications
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(categories)
        }
    }
    
    private func saveSelection() {
        // Save to App Group Defaults so Monitor can access it
        if let defaults = UserDefaults(suiteName: appGroupID),
           let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: userDefaultsKey)
        }
        // Also save to standard for local app usage (redundant but safe)
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadSelection() {
        // Try App Group first
        if let defaults = UserDefaults(suiteName: appGroupID),
           let data = defaults.data(forKey: userDefaultsKey),
           let savedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = savedSelection
            return
        }
        
        // Fallback to standard
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = savedSelection
        }
    }
    
    // Call this when user taps "Start Session"
    func startSession(minutes: Int, for token: ApplicationToken? = nil) {
        // 1. Save the FULL selection so the Extension can read it later and RESTORE it
        UserDefaults.shared.appSelection = selection
        
        // 2. Unlock Logic
        if let token = token {
            // Specific Unlock: Remove ONLY this app from the current blocked list
            var tempApplications = selection.applicationTokens
            tempApplications.remove(token)
            
            // Apply the modified shield (Everything else remains blocked)
            store.shield.applications = tempApplications
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            // store.shield.webDomains = selection.webDomainTokens
        } else {
            // Global Unlock (Fallback if no token provided)
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
        }
        
        // 3. Create the schedule
        let now = Date()
        let end = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: end),
            repeats: false // essential: do not repeat this tomorrow
        )
        
        // 4. Start Monitoring
        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(.sessionTimer, during: schedule)
            print("Session started! Apps unlocked for \(minutes) mins.")
        } catch {
            print("Error starting schedule: \(error)")
        }
        
        // 5. BACKUP: Main App Timer (Belt and Suspenders)
        // If the Extension fails to fire (e.g. simulator issues, budget weirdness),
        // this timer will re-lock the apps if the main app is still alive.
        
        let duration = TimeInterval(minutes * 60)
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            print("Main App: Timer ended. Re-locking.")
            // Restore the full shield from the saved selection
            let selection = UserDefaults.shared.appSelection
            self.store.shield.applications = selection.applicationTokens
            self.store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
    }
    
    // Call this to force-lock immediately (Emergency Stop)
    func stopSession() {
        let center = DeviceActivityCenter()
        center.stopMonitoring([.sessionTimer])
        
        // Manually trigger the lock logic
        let store = ManagedSettingsStore()
        let selection = UserDefaults.shared.appSelection
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }
    
    // Legacy adapter for ContentView
    func unblockTemporarily(duration: TimeInterval = 900, for token: ApplicationToken? = nil) {
        // Convert duration to minutes (rounding up)
        let minutes = Int(ceil(duration / 60.0))
        startSession(minutes: minutes, for: token)
    }
}
