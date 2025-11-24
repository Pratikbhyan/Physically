//
//  PhysicallyApp.swift
//  Physically
//
//  Created by Pratik Bhyan on 19/11/25.
//

import SwiftUI
import SwiftData
import FamilyControls
import UserNotifications

@main
struct PhysicallyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let container: ModelContainer
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var showSquatView = false

    init() {
        // Request Notification Permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        do {
            container = try ModelContainer(for: UserStats.self)
        } catch {
            print("Failed to create ModelContainer: \(error)")
            // Self-healing: Delete the store and try again
            // This happens when the schema changes in development
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            
            do {
                container = try ModelContainer(for: UserStats.self)
            } catch {
                fatalError("Failed to create ModelContainer even after reset: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                ContentView()
                    .onOpenURL { url in
                        if url.scheme == "physically" && url.host == "unlock" {
                            // Handle deep link to open squat view
                            // Ideally, we'd pass this state down or use a router.
                            // For now, we can rely on ContentView's state if we can access it, 
                            // or better, just reset the shield temporarily if that's the intent,
                            // OR present the squat view.
                            // Since ContentView is the root, we might need a better way to trigger it.
                            // Let's use a notification for simplicity in this MVP.
                            NotificationCenter.default.post(name: NSNotification.Name("TriggerSquatSession"), object: nil)
                        }
                    }
            }
        }
        .modelContainer(container)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let action = userInfo["action"] as? String {
            let tokenData = userInfo["tokenData"] as? Data
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if action == "exercise" {
                    NotificationCenter.default.post(name: NSNotification.Name("TriggerExerciseSelection"), object: nil, userInfo: tokenData != nil ? ["tokenData": tokenData!] : nil)
                } else if action == "banked" {
                    NotificationCenter.default.post(name: NSNotification.Name("TriggerBankedUnlock"), object: nil, userInfo: tokenData != nil ? ["tokenData": tokenData!] : nil)
                }
            }
        } else if let exercise = userInfo["exercise"] as? String {
            // Legacy support
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if exercise == "pushup" {
                    NotificationCenter.default.post(name: NSNotification.Name("TriggerPushupSession"), object: nil)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("TriggerSquatSession"), object: nil)
                }
            }
        }
        completionHandler()
    }
}
