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
    private let center = DeviceActivityCenter() // moved to property
    
    // Ensure this matches your entitlements exactly
    private let appGroupID = "group.com.pratik.physically"
    private let userDefaultsKey = "SavedAppSelection" // Matched with SharedModel
    
    private init() {
        loadSelection()
    }
    
    func updateShield() {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens
        
        saveSelection()
        
        // Only update the store if we are NOT currently in an active unlock session
        // (Simplified logic: always update, but user assumes risk if modifying during a session)
        store.shield.applications = applications
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(categories)
    }
    
    private func saveSelection() {
        // Use the extension variable from SharedModel.swift for consistency
        UserDefaults.shared.appSelection = selection
    }
    
    private func loadSelection() {
        selection = UserDefaults.shared.appSelection
    }
    
    func startSession(minutes: Int, for token: ApplicationToken? = nil) {
        // 1. Force Save the FULL selection immediately
        saveSelection()
        
        // 2. Unlock Logic (Visual update)
        // 2. Unlock Logic (Visual update)
        // We wrap in main async to ensure immediate UI update
        DispatchQueue.main.async {
            if let token = token {
                var tempApplications = self.selection.applicationTokens
                tempApplications.remove(token)
                
                self.store.shield.applications = tempApplications.isEmpty ? nil : tempApplications
                
                if self.selection.categoryTokens.isEmpty {
                    self.store.shield.applicationCategories = nil
                } else {
                    self.store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(self.selection.categoryTokens)
                }
            } else {
                self.store.shield.applications = nil
                self.store.shield.applicationCategories = nil
            }
            self.store.shield.webDomains = nil
        }
        
        // 3. Stop any existing monitoring to avoid conflicts
        center.stopMonitoring([.sessionTimer])
        
        // 4. Create a Robust Schedule
        // We set the start time to 5 seconds in the past to ensure the system sees it as "Active"
        // We use repeats: true because one-time schedules are often buggy in iOS 16/17, 
        // even though we only want it once. We will cancel it in the extension.
        let now = Date()
        let start = Calendar.current.date(byAdding: .second, value: -5, to: now)!
        let end = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: start),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: end),
            repeats: true
        )
        
        // 5. Start Monitoring
        do {
            try center.startMonitoring(.sessionTimer, during: schedule)
            print("Physically: Monitoring started for \(minutes) minutes.")
        } catch {
            print("Physically: Error starting schedule: \(error)")
            // If the schedule fails (e.g. interval too short), we MUST rely on the backup timer.
        }
        
        // 6. BACKUP: Main App Timer
        // Essential for short intervals (e.g. 1 minute) which iOS might reject with 'intervalTooShort'.
        let duration = TimeInterval(minutes * 60)
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            print("Main App: Backup Timer ended. Re-locking.")
            // Restore the full shield
            let selection = UserDefaults.shared.appSelection
            self.store.shield.applications = selection.applicationTokens
            self.store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
    }
    
    func stopSession() {
        center.stopMonitoring([.sessionTimer])
        updateShield() // Re-applies the saved selection
    }
    
    func unblockTemporarily(duration: TimeInterval = 900, for token: ApplicationToken? = nil) {
        let minutes = Int(ceil(duration / 60.0))
        startSession(minutes: minutes, for: token)
    }
}
