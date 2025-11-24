import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
import UserNotifications
import os.log // Import for logging

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore()
    let logger = Logger(subsystem: "com.pratik.physically", category: "Monitor")
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.log("PhysicallyMonitor: Interval DID START for \(activity.rawValue)")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.log("PhysicallyMonitor: Interval DID END for \(activity.rawValue)")
        lockApps(for: activity)
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        logger.log("PhysicallyMonitor: Interval WARNING for \(activity.rawValue) - Locking now.")
        lockApps(for: activity)
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        logger.log("PhysicallyMonitor: Threshold REACHED for \(event.rawValue) - Locking now.")
        lockApps(for: activity)
    }
    
    private func lockApps(for activity: DeviceActivityName) {
        if activity == .sessionTimer {
            // 1. Load the saved apps from App Group using SharedModel helper
            let selection = UserDefaults.shared.appSelection
            
            // 2. Force Refresh (The "Flash All" Strategy)
            // We briefly block ALL categories. This is an aggressive state change
            // that forces the system to re-evaluate the foreground app immediately.
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
            
            // Wait a moment to let the system propagate the "Block All" state
            Thread.sleep(forTimeInterval: 0.5)
            
            // 3. Re-Apply the correct selection
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            
            // 4. Log
            logger.log("PhysicallyMonitor: Shield restored. Blocked \(selection.applicationTokens.count) apps.")
        }
    }
}


