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
                        Text("Squats for 5 Minutes")
                        HStack {
                            Slider(value: Binding(
                                get: { Double(userStats.exchangeRateSquats) },
                                set: { userStats.exchangeRateSquats = Int($0) }
                            ), in: 5...50, step: 5)
                            Text("\(userStats.exchangeRateSquats)")
                                .fontWeight(.bold)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Pushups for 5 Minutes")
                        HStack {
                            Slider(value: Binding(
                                get: { Double(userStats.exchangeRatePushups) },
                                set: { userStats.exchangeRatePushups = Int($0) }
                            ), in: 5...50, step: 5)
                            Text("\(userStats.exchangeRatePushups)")
                                .fontWeight(.bold)
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
}
