import Foundation
import Vision
import SwiftData
import SwiftUI
import Combine

class PushupManager: ObservableObject {
    @Published var pushupCount = 0
    @Published var isPushing = false
    @Published var feedbackText = "Get in position"
    @Published var targetPushups = 5
    @Published var currentAngle: Double = 0.0
    
    private var state: PushupState = .up
    private var modelContext: ModelContext?
    private var userStats: UserStats?
    private let smoother = JointSmoother(windowSize: 6)
    
    // Velocity Check
    private var startShoulderY: CGFloat = 0.0
    private var minShoulderY: CGFloat = 0.0 // Track lowest point (highest Y value)
    
    enum PushupState {
        case up
        case down
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
        fetchStats()
    }
    
    private func fetchStats() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<UserStats>()
            if let stats = try context.fetch(descriptor).first {
                self.userStats = stats
            } else {
                let newStats = UserStats()
                context.insert(newStats)
                self.userStats = newStats
            }
        } catch {
            print("Failed to fetch stats: \(error)")
        }
    }
    
    func process(joints: [VNHumanBodyPoseObservation.JointName : CGPoint]) {
        let smoothedJoints = smoother.smooth(joints: joints)
        
        // Pushups: Shoulder, Elbow, Wrist
        guard let rightShoulder = smoothedJoints[.rightShoulder],
              let rightElbow = smoothedJoints[.rightElbow],
              let rightWrist = smoothedJoints[.rightWrist] else {
            
            guard let leftShoulder = smoothedJoints[.leftShoulder],
                  let leftElbow = smoothedJoints[.leftElbow],
                  let leftWrist = smoothedJoints[.leftWrist] else {
                return
            }
            checkPushup(shoulder: leftShoulder, elbow: leftElbow, wrist: leftWrist)
            return
        }
        
        checkPushup(shoulder: rightShoulder, elbow: rightElbow, wrist: rightWrist)
    }
    
    private func checkPushup(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint) {
        let angle = calculateAngle(p1: shoulder, p2: elbow, p3: wrist)
        DispatchQueue.main.async {
            self.currentAngle = angle
        }
        
        // Hysteresis Loop (The Logic Fix)
        // Pushup Down Threshold: < 90 degrees
        // Pushup Up Threshold: > 160 degrees
        
        // Velocity Check: Shoulder Y (0 is top, 1 is bottom)
        // Down movement means Y increases.
        
        switch state {
        case .up:
            if angle < 90 {
                state = .down
                startShoulderY = shoulder.y
                minShoulderY = shoulder.y
                feedbackText = "Push!"
            } else {
                feedbackText = "Go down!"
            }
            
        case .down:
            // Track lowest point (max Y)
            if shoulder.y > minShoulderY {
                minShoulderY = shoulder.y
            }
            
            if angle > 160 {
                // Check if shoulder moved down significantly
                // Threshold: e.g., 0.1 normalized units (approx 10% of screen height)
                // If camera is far, this might be small. Let's try 0.05.
                let distance = minShoulderY - startShoulderY
                
                if distance > 0.05 {
                    completeRep()
                } else {
                    feedbackText = "Go lower!" // Failed velocity check
                }
                state = .up
            } else {
                feedbackText = "Push up!"
            }
        }
    }
    
    private func completeRep() {
        pushupCount += 1
        
        // Update Stats
        if let stats = userStats {
            stats.totalSquats += 1
            
            // Add Banked Minutes based on Exchange Rate
            // MOVED TO VIEW: Minutes are now added when user clicks "OK"
            // let minutesEarned = 5.0 / Double(stats.exchangeRatePushups)
            // stats.bankedMinutes += minutesEarned
        }
        
        feedbackText = "Good pushup!"
        
        AudioManager.shared.playCoin()
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        if pushupCount == targetPushups {
            AudioManager.shared.playRegister()
            feedbackText = "UNLOCKED!"
            BlockingManager.shared.unblockTemporarily()
        }
    }
    
    private func calculateAngle(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
        let v1 = CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
        let v2 = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
        
        let angleRad = atan2(v2.y, v2.x) - atan2(v1.y, v1.x)
        var angleDeg = abs(angleRad * 180 / .pi)
        
        if angleDeg > 180 { angleDeg = 360 - angleDeg }
        
        return angleDeg
    }
}
