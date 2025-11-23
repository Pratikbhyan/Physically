import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
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
        
        if activity == .sessionTimer {
            // 1. Load the saved apps from App Group using SharedModel helper
            let selection = UserDefaults.shared.appSelection
            
            // 2. Re-Apply the shield (LOCK EVERYTHING)
            // Even if selection is empty, this ensures we reset the state.
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            
            // 3. Stop monitoring so this doesn't repeat tomorrow
            // Note: The extension generally cannot stop monitoring for the main app, 
            // but the re-lock logic above is persistent until changed.
            logger.log("PhysicallyMonitor: Shield restored. Blocked \(selection.applicationTokens.count) apps.")
        }
    }
}
