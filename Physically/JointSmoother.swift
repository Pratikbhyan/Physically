import Foundation
import Vision

class JointSmoother {
    private var history: [VNHumanBodyPoseObservation.JointName: [CGPoint]] = [:]
    private let windowSize: Int
    
    init(windowSize: Int = 10) {
        self.windowSize = windowSize
    }
    
    func smooth(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var smoothedJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        for (joint, point) in joints {
            if history[joint] == nil {
                history[joint] = []
            }
            
            history[joint]?.append(point)
            
            if let count = history[joint]?.count, count > windowSize {
                history[joint]?.removeFirst()
            }
            
            let averagePoint = calculateAverage(for: history[joint] ?? [])
            smoothedJoints[joint] = averagePoint
        }
        
        return smoothedJoints
    }
    
    private func calculateAverage(for points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let count = CGFloat(points.count)
        
        return CGPoint(x: sumX / count, y: sumY / count)
    }
}
