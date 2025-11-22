import SwiftUI
import Vision
import SwiftData

struct PushupView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var pushupManager = PushupManager()
    @Query var userStats: [UserStats]
    
    @State private var flashOpacity: Double = 0.0
    
    var currentUserStats: UserStats? { userStats.first }
    
    var body: some View {
        ZStack {
            // Camera Background
            if let session = cameraManager.session {
                CameraPreview(session: session)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Skeleton Overlay
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(cameraManager.detectedPoints.keys), id: \.self) { joint in
                        if let point = cameraManager.detectedPoints[joint] {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                                .position(x: point.x * geometry.size.width, y: point.y * geometry.size.height)
                        }
                    }
                }
            }
            
            // UI Overlay
            VStack {
                // Top Left: Counter
                HStack {
                    Text("\(pushupManager.pushupCount)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                
                Spacer()
                
                // Bottom Right: OK Button
                HStack {
                    Spacer()
                    Button(action: {
                        finishSession()
                    }) {
                        Text("OK")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(30)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 10)
                    }
                }
                .padding(.bottom, 50)
                .padding(.trailing, 30)
            }
            
            // Flash Effect
            Color.blue
                .opacity(flashOpacity)
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)
        }
        .onAppear {
            pushupManager.setContext(modelContext)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            cameraManager.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: cameraManager.detectedPoints) { _, newParts in
            pushupManager.process(joints: newParts)
        }
        .onChange(of: pushupManager.pushupCount) { _, _ in
            withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 0.5 }
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) { flashOpacity = 0.0 }
        }
    }
    
    private func finishSession() {
        if let stats = currentUserStats {
            let rate = Double(stats.exchangeRatePushups)
            let earned = (Double(pushupManager.pushupCount) / rate) * 5.0
            stats.bankedMinutes += earned
        }
        dismiss()
    }
}
