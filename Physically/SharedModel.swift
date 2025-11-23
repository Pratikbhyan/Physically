import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// 1. Add this helper to easily save/load the selection
extension UserDefaults {
    // Use your ACTUAL Group ID here
    static let shared = UserDefaults(suiteName: "group.com.pratik.physically")!
    
    var appSelection: FamilyActivitySelection {
        get {
            guard let data = data(forKey: "SavedAppSelection") else { return FamilyActivitySelection() }
            let decoder = PropertyListDecoder()
            return (try? decoder.decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
        }
        set {
            let encoder = PropertyListEncoder()
            if let data = try? encoder.encode(newValue) {
                set(data, forKey: "SavedAppSelection")
            }
        }
    }
}

// 2. Define a name for your session
extension DeviceActivityName {
    static let sessionTimer = DeviceActivityName("sessionTimer")
}
