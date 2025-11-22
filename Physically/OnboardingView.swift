import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentTab = 0
    
    var body: some View {
        TabView(selection: $currentTab) {
            // Slide 1: Intro
            VStack(spacing: 20) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("Welcome to Physically")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Stop scrolling. Start growing.")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .tag(0)
            
            // Slide 2: How it Works
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("Block Distractions")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select apps to block. When you try to open them, you'll need to pay with sweat.")
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .tag(1)
            
            // Slide 3: Permissions & Go
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("Ready?")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We need permission to block apps and use the camera for squat detection.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    requestPermissions()
                    hasCompletedOnboarding = true
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    
    func requestPermissions() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                let _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("Failed to request authorization: \(error)")
            }
        }
    }
}
