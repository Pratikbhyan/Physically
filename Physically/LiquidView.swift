import SwiftUI
import SpriteKit

struct LiquidView: View {
    var bankedMinutes: Double
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: LiquidScene(size: geometry.size, bankedMinutes: bankedMinutes), options: [.allowsTransparency])
                .background(Color.clear)
        }
    }
}

class LiquidScene: SKScene {
    var bankedMinutes: Double
    
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
        
        // Spawn drops based on banked minutes
        // Let's say 1 drop = 1 minute for visual density
        let dropCount = Int(bankedMinutes)
        
        let spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.children.count < dropCount {
                self.spawnDrop()
            } else {
                timer.invalidate()
            }
        }
        spawnTimer.fire()
    }
    
    func spawnDrop() {
        let radius: CGFloat = 10
        let drop = SKShapeNode(circleOfRadius: radius)
        drop.fillColor = .cyan
        drop.strokeColor = .clear
        drop.position = CGPoint(x: size.width / 2 + CGFloat.random(in: -20...20), y: size.height - 50)
        
        drop.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        drop.physicsBody?.restitution = 0.2 // Low bounce for heavy liquid feel
        drop.physicsBody?.friction = 0.1
        drop.physicsBody?.density = 2.0 // Heavy
        
        addChild(drop)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Remove nodes that fall out of bounds (safety)
        for node in children {
            if node.position.y < -50 {
                node.removeFromParent()
            }
        }
    }
}
