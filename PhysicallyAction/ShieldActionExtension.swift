//
//  ShieldActionExtension.swift
//  PhysicallyAction
//
//  Created by Pratik Bhyan on 22/11/25.
//

import ManagedSettings
import UserNotifications
import UIKit

// Override the functions below to customize the shield actions used in various situations.
// The system provides a default response for any functions that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle the action as needed.
        switch action {
        case .primaryButtonPressed:
            // Unlock with Exercise
            scheduleNotification(for: application, actionType: "exercise")
            completionHandler(.none)
            
        case .secondaryButtonPressed:
            // Use Banked Minutes
            scheduleNotification(for: application, actionType: "banked")
            completionHandler(.none)
            
        @unknown default:
            completionHandler(.none)
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.none)
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.none)
    }
    
    private func scheduleNotification(for application: ApplicationToken, actionType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Physically Locked"
        
        if actionType == "exercise" {
            content.body = "Tap to choose an exercise and unlock."
        } else {
            content.body = "Tap to use banked minutes to unlock."
        }
        
        content.sound = .default
        
        var userInfo: [String: Any] = ["action": actionType]
        
        // Encode ApplicationToken
        if let data = try? JSONEncoder().encode(application) {
            userInfo["tokenData"] = data
        }
        
        content.userInfo = userInfo
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
