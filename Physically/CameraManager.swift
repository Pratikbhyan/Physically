import AVFoundation
import Vision
import UIKit
import Combine

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedPoints: [VNHumanBodyPoseObservation.JointName : CGPoint] = [:]
    @Published var session: AVCaptureSession?
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sequenceHandler = VNSequenceRequestHandler()
    
    override init() {
        super.init()
        checkPermissionsAndStart()
    }
    
    func checkPermissionsAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { DispatchQueue.main.async { self.setupCamera() } }
            }
        default: print("Camera permission denied")
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high // High quality for better detection
        
        // 1. INPUT: Use Front Camera (Selfie Mode)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        // 2. OUTPUT: Configure Data Stream
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing"))
        
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
        // 3. CRITICAL FIX: Rotate the video stream to match Portrait Mode
        // Without this, Vision thinks you are lying sideways.
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            connection.isVideoMirrored = true // Mirror it so it acts like a mirror
        }
        
        DispatchQueue.main.async { self.session = session }
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session?.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session?.stopRunning()
        }
    }
    
    // 4. The Vision Loop
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest()
        
        do {
            // Perform request. Note: We used rotationAngle 90 above, so we pass .up here.
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: .up)
            
            guard let observation = request.results?.first else {
                DispatchQueue.main.async { self.detectedPoints = [:] }
                return
            }
            
            // Extract and Normalize Points
            let recognizedPoints = try observation.recognizedPoints(.all)
            var newPoints: [VNHumanBodyPoseObservation.JointName : CGPoint] = [:]
            
            for (key, point) in recognizedPoints {
                if point.confidence > 0.3 {
                    // CRITICAL COORDINATE FLIP
                    // Vision Origin: Bottom-Left. SwiftUI Origin: Top-Left.
                    // We must flip Y: (1 - point.y)
                    newPoints[key] = CGPoint(x: point.location.x, y: 1 - point.location.y)
                }
            }
            
            DispatchQueue.main.async { self.detectedPoints = newPoints }
            
        } catch {
            print("Vision Error: \(error)")
        }
    }
}
