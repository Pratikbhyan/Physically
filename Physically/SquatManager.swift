import Foundation
import Vision
import SwiftData
import SwiftUI
import Combine

class SquatManager: ObservableObject {
    @Published var squatCount = 0
    @Published var isSquatting = false
    @Published var feedbackText = "Stand in frame"
    @Published var isBossMode = false
    @Published var targetSquats = 5
    @Published var currentAngle: Double = 0.0
    
    private var state: SquatState = .idle
    private var modelContext: ModelContext?
    private var userStats: UserStats?
    private let smoother = JointSmoother(windowSize: 6)
    private var repReady = false
    
    enum SquatState {
        case idle
        case descending
        case bottom
        case ascending
        case completed
    }
    
    init() {
        // Boss Fight: 5% chance
        if Double.random(in: 0...1) < 0.05 {
            isBossMode = true
            targetSquats = 10
            feedbackText = "BOSS FIGHT! 10 Reps!"
        }
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
        // Smooth the joints
        let smoothedJoints = smoother.smooth(joints: joints)
        
        // We need Hip, Knee, Ankle for at least one side.
        // Let's prioritize Right side for now, or check both.
        
        guard let rightHip = smoothedJoints[.rightHip],
              let rightKnee = smoothedJoints[.rightKnee],
              let rightAnkle = smoothedJoints[.rightAnkle] else {
            // Try left side
            guard let leftHip = smoothedJoints[.leftHip],
                  let leftKnee = smoothedJoints[.leftKnee],
                  let leftAnkle = smoothedJoints[.leftAnkle] else {
                return
            }
            checkSquat(hip: leftHip, knee: leftKnee, ankle: leftAnkle)
            return
        }
        
        checkSquat(hip: rightHip, knee: rightKnee, ankle: rightAnkle)
    }
    
    private func checkSquat(hip: CGPoint, knee: CGPoint, ankle: CGPoint) {
        let angle = calculateAngle(p1: hip, p2: knee, p3: ankle)
        DispatchQueue.main.async {
            self.currentAngle = angle
        }
        
        // Hysteresis State Machine
        switch state {
        case .idle, .completed:
            if angle > 160 {
                state = .idle
                repReady = false
                if !isBossMode { feedbackText = "Squat down!" }
            } else if angle < 150 {
                state = .descending
                feedbackText = "Going down..."
            }
            
        case .descending:
            if angle < 100 {
                state = .bottom
                repReady = true
                feedbackText = "Hold..."
            } else if angle > 160 {
                // Aborted rep
                state = .idle
                feedbackText = "Squat down!"
            }
            
        case .bottom:
            if angle > 120 {
                state = .ascending
                feedbackText = "Push up!"
            }
            
        case .ascending:
            if angle > 160 {
                if repReady {
                    completeRep()
                } else {
                    state = .idle // Should not happen if logic is correct
                }
            } else if angle < 100 {
                // Went back down
                state = .bottom
            }
        }
    }
    
    private func completeRep() {
        state = .completed
        squatCount += 1
        repReady = false
        
        // Update Stats
        if let stats = userStats {
            stats.totalSquats += 1
            
            // Add Banked Minutes based on Exchange Rate
            // MOVED TO VIEW: Minutes are now added when user clicks "OK"
            // let minutesEarned = 5.0 / Double(stats.exchangeRateSquats)
            // stats.bankedMinutes += minutesEarned
            
            if squatCount > targetSquats {
                stats.squatsBanked += 1 // Legacy field
            }
        }
        
        feedbackText = "Good rep!"
        
        // Audio & Haptics
        AudioManager.shared.playCoin()
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Check for completion
        if squatCount == targetSquats {
            AudioManager.shared.playRegister()
            feedbackText = "UNLOCKED!"
            BlockingManager.shared.unblockTemporarily()
        }
    }
    
    private func calculateAngle(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
        let v1 = CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
        let v2 = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
        
        let angleRad = atan2(v2.y, v2.x) - atan2(v1.y, v1.x)
        var angleDeg = angleRad * 180 / .pi
        
        if angleDeg < 0 { angleDeg += 360 }
        if angleDeg > 180 { angleDeg = 360 - angleDeg }
        
        return angleDeg
    }
}
