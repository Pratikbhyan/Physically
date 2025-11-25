import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var userStats: UserStats
    
    // State for Emergency Toggle
    @State private var isEmergencyUsed: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 17))
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                Text("Settings")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // Emergency Card
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("15 Min Emergency")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { !canTakeDebt() },
                            set: { newValue in
                                if newValue && canTakeDebt() {
                                    handleDebtRequest()
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(.red)
                        .disabled(!canTakeDebt())
                    }
                    
                    Text("Once daily limit")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(UIColor.systemGray6).opacity(0.15))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                // Exchange Rates Header
                HStack(alignment: .firstTextBaseline) {
                    Text("Exchange Rates")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Earn screen time")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                .padding(.top, 20)
                
                // Exchange Rate Cards Container
                VStack(spacing: 0) {
                    // Squat Card
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional") // Placeholder for Squat Icon
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                            Text("1 Squat")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(userStats.exchangeRateSquats / 60)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Min")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        }
                        
                        HStack {
                            // Custom Slider Look
                            Slider(value: Binding(
                                get: { Double(userStats.exchangeRateSquats) },
                                set: { userStats.exchangeRateSquats = Int($0) }
                            ), in: 60...600, step: 60)
                            .accentColor(.black)
                        }
                        
                        HStack {
                            Text("1m")
                            Spacer()
                            Text("10m")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                    }
                    .padding(24)
                    .background(Color.cyan)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    
                    // Divider
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 1)
                    
                    // Pushup Card
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "figure.pushup") // Placeholder for Pushup Icon
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                            Text("1 Pushup")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(userStats.exchangeRatePushups / 60)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Min")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        }
                        
                        HStack {
                            Slider(value: Binding(
                                get: { Double(userStats.exchangeRatePushups) },
                                set: { userStats.exchangeRatePushups = Int($0) }
                            ), in: 60...300, step: 60)
                            .accentColor(.black)
                        }
                        
                        HStack {
                            Text("1m")
                            Spacer()
                            Text("5m")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                    }
                    .padding(24)
                    .background(Color.cyan.opacity(0.9)) // Slightly different shade or same
                    .cornerRadius(24, corners: [.bottomLeft, .bottomRight])
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
    }
    
    private func canTakeDebt() -> Bool {
        guard let lastDate = userStats.lastDebtDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }
    
    private func handleDebtRequest() {
        if canTakeDebt() {
            userStats.lastDebtDate = Date()
            userStats.debtMinutes += 15
            userStats.bankedMinutes += 15
            // Removed auto-unlock. User must manually redeem minutes.
        }
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    // Mock Data for Preview
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserStats.self, configurations: config)
        let example = UserStats()
        return SettingsView(userStats: example)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
