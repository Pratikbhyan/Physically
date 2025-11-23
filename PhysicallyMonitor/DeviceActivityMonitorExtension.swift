//
//  DeviceActivityMonitorExtension.swift
//  PhysicallyMonitor
//
//  Created by Pratik Bhyan on 22/11/25.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// Ensure this matches the App Group ID you set in Xcode
let appGroupID = "group.com.pratik.physically"
// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore()
    
    // When the timer STARTS: Do NOTHING.
    // The Main App has already set the specific unlock state.
    // We don't want to override it by unlocking everything.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        if activity == .sessionTimer {
            print("Monitor: Session started.")
        }
    }
    
    // When the timer ENDS: LOCK everything
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        if activity == .sessionTimer {
            // 1. Load the saved apps from App Group
            let selection = UserDefaults.shared.appSelection
            
            // 2. Apply the shield (Lock)
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            // store.shield.webDomains = selection.webDomainTokens // Uncomment if you block websites
        }
    }
}
