import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

struct RedeemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query var userStats: [UserStats]
    
    var applicationToken: ApplicationToken?
    
    @State private var minutesToRedeem: Double = 15.0
    
    var blockingManager = BlockingManager.shared
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Text("Redeem Minutes")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                if let stats = userStats.first {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Text("\(Int(minutesToRedeem)) / \(Int(stats.bankedMinutes))")
                            .font(.system(size: 60, weight: .heavy, design: .rounded))
                            .foregroundColor(.cyan)
                        
                        Text("MINUTES TO USE")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .tracking(2)
                    }
                    
                    // Aesthetic Slider
                    Slider(value: $minutesToRedeem, in: 1...max(1, stats.bankedMinutes), step: 1)
                        .accentColor(.cyan)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        redeemMinutes(stats: stats)
                    }) {
                        Text("Unlock App")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    
                } else {
                    Text("No user stats found.")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    func redeemMinutes(stats: UserStats) {
        guard stats.bankedMinutes >= minutesToRedeem else { return }
        
        // Deduct minutes
        stats.bankedMinutes -= minutesToRedeem
        
        // Unlock apps (specific or global)
        blockingManager.unblockApps(for: TimeInterval(minutesToRedeem * 60), token: applicationToken)
        
        dismiss()
    }
}

#Preview {
    RedeemView()
}
