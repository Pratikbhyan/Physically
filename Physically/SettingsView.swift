import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var userStats: UserStats
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exchange Rates")) {
                    VStack(alignment: .leading) {
                        Text("Squat Exchange Rate")
                        HStack {
                            Slider(value: Binding(
                                get: {
                                    // 0: 30, 1: 60, 2: 120, 3: 180, 4: 240, 5: 300
                                    let val = userStats.exchangeRateSquats
                                    let steps = [30, 60, 120, 180, 240, 300]
                                    return Double(steps.firstIndex(where: { $0 >= val }) ?? 0)
                                },
                                set: {
                                    let steps = [30, 60, 120, 180, 240, 300]
                                    let index = Int($0)
                                    if index < steps.count {
                                        userStats.exchangeRateSquats = steps[index]
                                    }
                                }
                            ), in: 0...5, step: 1)
                            
                            Text(formatRate(userStats.exchangeRateSquats))
                                .fontWeight(.bold)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Pushup Exchange Rate")
                        HStack {
                            Slider(value: Binding(
                                get: {
                                    let val = userStats.exchangeRatePushups
                                    let steps = [30, 60, 120, 180, 240, 300]
                                    return Double(steps.firstIndex(where: { $0 >= val }) ?? 0)
                                },
                                set: {
                                    let steps = [30, 60, 120, 180, 240, 300]
                                    let index = Int($0)
                                    if index < steps.count {
                                        userStats.exchangeRatePushups = steps[index]
                                    }
                                }
                            ), in: 0...5, step: 1)
                            
                            Text(formatRate(userStats.exchangeRatePushups))
                                .fontWeight(.bold)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
                
                Section(header: Text("Emergency")) {
                    Button(action: {
                        handleDebtRequest()
                    }) {
                        HStack {
                            Text("Use Emergency Credit (15 min)")
                            Spacer()
                            if !canTakeDebt() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(!canTakeDebt())
                }
                
                Section(footer: Text("You can only use emergency credit once per day.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
            BlockingManager.shared.unblockTemporarily()
        }
    }
    
    private func formatRate(_ seconds: Int) -> String {
        if seconds == 30 { return "0.5 min" }
        return "\(seconds / 60) min"
    }
}
