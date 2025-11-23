import SwiftUI
import SpriteKit

struct LiquidView: View {
    var bankedMinutes: Double
    @State private var scene: LiquidScene?
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene ?? createScene(size: geometry.size), options: [.allowsTransparency])
                .background(Color.clear)
                .onChange(of: bankedMinutes) { _, newValue in
                    scene?.updateDrops(bankedMinutes: newValue)
                }
        }
    }
    
    private func createScene(size: CGSize) -> LiquidScene {
        let newScene = LiquidScene(size: size, bankedMinutes: bankedMinutes)
        // Assign to state asynchronously to avoid view update conflicts if needed, 
        // but here we just return it. We need to capture it.
        // Better pattern:
        DispatchQueue.main.async {
            self.scene = newScene
        }
        return newScene
    }
}

import CoreMotion

class LiquidScene: SKScene {
    var bankedMinutes: Double
    let motionManager = CMMotionManager()
    
    init(size: CGSize, bankedMinutes: Double) {
        self.bankedMinutes = bankedMinutes
        super.init(size: size)
        self.backgroundColor = .clear
        self.scaleMode = .aspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Start Motion Updates
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let data = data, let self = self else { return }
                let gravityX = CGFloat(data.acceleration.x) * 9.8
                let gravityY = CGFloat(data.acceleration.y) * 9.8
                self.physicsWorld.gravity = CGVector(dx: gravityX, dy: gravityY)
            }
        }
        
        updateDrops(bankedMinutes: bankedMinutes)
    }
    
    func updateDrops(bankedMinutes: Double) {
        self.bankedMinutes = bankedMinutes
        let targetCount = Int(bankedMinutes)
        let currentCount = children.filter { $0 is SKShapeNode }.count
        
        if currentCount < targetCount {
            // Spawn more
            let diff = targetCount - currentCount
            for _ in 0..<diff {
                spawnDrop()
            }
        } else if currentCount > targetCount {
            // Remove some
            let diff = currentCount - targetCount
            let drops = children.filter { $0 is SKShapeNode }
            for i in 0..<diff {
                if i < drops.count {
                    drops[i].removeFromParent()
                }
            }
        }
    }
    
    func spawnDrop() {
        let radius: CGFloat = 10
        let drop = SKShapeNode(circleOfRadius: radius)
        drop.fillColor = .cyan
        drop.strokeColor = .clear
        drop.position = CGPoint(x: size.width / 2 + CGFloat.random(in: -20...20), y: size.height - 50)
        
        drop.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        drop.physicsBody?.restitution = 0.2
        drop.physicsBody?.friction = 0.1
        drop.physicsBody?.density = 2.0
        
        addChild(drop)
    }
    
    override func update(_ currentTime: TimeInterval) {
        for node in children {
            if node.position.y < -50 || node.position.y > size.height + 50 || node.position.x < -50 || node.position.x > size.width + 50 {
                node.removeFromParent()
                // If we lost a drop, we might want to respawn it if count is mismatched, 
                // but strictly we should just let updateDrops handle it next time or observe count.
                // For now, let's just let it slide to avoid infinite loops.
            }
        }
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}
