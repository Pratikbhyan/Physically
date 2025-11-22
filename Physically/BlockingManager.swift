import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
import Combine

class BlockingManager: ObservableObject {
    static let shared = BlockingManager()
    
    @Published var selection = FamilyActivitySelection()
    
    private let store = ManagedSettingsStore()
    
    private init() {}
    
    func updateShield() {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens
        // let webCategories = selection.webDomainTokens // If needed later
        
        if applications.isEmpty && categories.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        } else {
            store.shield.applications = applications
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(categories)
        }
    }
    
    func unblockTemporarily(duration: TimeInterval = 900) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        
        // Re-enable after specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.updateShield()
        }
    }
}
