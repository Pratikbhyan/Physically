import SwiftUI
import SwiftData

struct ContractView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var userStats: UserStats
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.9, blue: 0.8) // Paper color
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("THE CONTRACT")
                    .font(.custom("Times New Roman", size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 50)
                
                Text("I, the undersigned, agree to the following exchange rates for my time:")
                    .font(.custom("Times New Roman", size: 18))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                    .background(Color.black)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Squat Exchange Rate")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("\(userStats.exchangeRateSquats) Squats")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        Text("= 5 Minutes")
                            .foregroundColor(.black)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(userStats.exchangeRateSquats) },
                        set: { userStats.exchangeRateSquats = Int($0) }
                    ), in: 5...50, step: 5)
                    .accentColor(.black)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pushup Exchange Rate")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("\(userStats.exchangeRatePushups) Pushups")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                        Text("= 5 Minutes")
                            .foregroundColor(.black)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(userStats.exchangeRatePushups) },
                        set: { userStats.exchangeRatePushups = Int($0) }
                    ), in: 5...50, step: 5)
                    .accentColor(.black)
                }
                .padding()
                
                Divider()
                    .background(Color.black)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("SIGN & SEAL")
                        .font(.custom("Times New Roman", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.bottom, 50)
                .padding(.horizontal)
            }
            .padding()
        }
    }
}
