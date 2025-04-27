import SpriteKit

class Asteroid: SKShapeNode {
    static var minMovementSpeed: CGFloat!
    static var minHoningStrength: CGFloat!
    static var maxMovementSpeed: CGFloat!
    static var maxHoningStrength: CGFloat!
    static var waveOn = false
    
    var movementSpeed: CGFloat
    var honingStrength: CGFloat
    var damage: Int
    var movementType: MovementType
    var player: SKShapeNode
    var driftRate: CGFloat
    var asteroidColor: UIColor = .darkGray
    
    // Movement types for asteroids
    enum MovementType {
        case honing
        case drifting
        case straightLine
    }
    
    static func resetAsteroids() {
        Asteroid.waveOn = false
        minMovementSpeed = 5
        minHoningStrength = 0.001
        maxMovementSpeed = 7
        maxHoningStrength = 0.01
    }
    
    // Initializer for the Asteroid class
    init(size: CGFloat, position: CGPoint, player: SKShapeNode) {
        if Asteroid.minMovementSpeed == nil {
            Asteroid.resetAsteroids()
        }
        self.player = player
        let minSpeed: CGFloat = Asteroid.waveOn ? Asteroid.minMovementSpeed * 1.5 : Asteroid.minMovementSpeed
        let maxSpeed: CGFloat = Asteroid.waveOn ? Asteroid.maxMovementSpeed * 1.5: Asteroid.maxMovementSpeed
        self.movementSpeed = CGFloat.random(in: minSpeed...maxSpeed)
        self.honingStrength = CGFloat.random(in: Asteroid.minHoningStrength...Asteroid.maxHoningStrength)
        
        // Define probabilities for damage and healing
        let damageWeights = Int.random(in: 1...100)
        
        if damageWeights <= 70 {
            self.damage = -1  // 70% chance
        } else if damageWeights <= 90 {
            self.damage = -2  // 20% chance
        } else {
            self.damage = -3  // 10% chance
        }
        
        self.movementType = MovementType.random()
        self.driftRate = CGFloat.random(in: -1...1)
        
        super.init()
        
        // Draw the asteroid shape
//        let randomPoints = Int.random(in: 20...40)
//        let path = CGMutablePath()
//        var angle: CGFloat = 0.0
//        let angleIncrement = (2 * .pi) / CGFloat(randomPoints)
//        
//        path.move(to: CGPoint(x: size, y: 0)) // Start point
//        
//        for _ in 1...randomPoints {
//            // Randomizing jaggedness
//            let radiusVariation = CGFloat.random(in: 0.5...1.0)
//            let x = size * cos(angle) * radiusVariation
//            let y = size * sin(angle) * radiusVariation
//            path.addLine(to: CGPoint(x: x, y: y))
//            angle += angleIncrement
//        }
//        path.closeSubpath()
        
        let randomPoints = Int.random(in: 10...25)
        let path = CGMutablePath()

        // Generate random polar coordinates
        var points: [CGPoint] = []
        for _ in 0..<randomPoints {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let radius = size * CGFloat.random(in: 0.5...1.0)
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }

        // Sort points by angle to ensure a non-intersecting shape
        points.sort { atan2($0.y, $0.x) < atan2($1.y, $1.x) }

        if let first = points.first {
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        
        self.position = position
        self.strokeColor = damageColor()
        
        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotationTime = Double.random(in: 1...5)
//        let rotateAction = SKAction.rotate(byAngle: direction * .pi, duration: rotationTime)
//        self.run(SKAction.repeatForever(rotateAction))
        
        let spin = SKAction.rotate(byAngle: direction * .pi, duration: rotationTime)
        let spinForever = SKAction.repeatForever(spin)

        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.1, duration: 0.5),
            SKAction.rotate(byAngle: -0.2, duration: 0.5),
            SKAction.rotate(byAngle: 0.1, duration: 0.5)
        ])
        let wobbleForever = SKAction.repeatForever(wobble)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1),
            SKAction.scale(to: 0.95, duration: 1)
        ])
        let pulseForever = SKAction.repeatForever(pulse)

        self.run(SKAction.group([spinForever, wobbleForever, pulseForever]))
        
        
        self.path = path
        self.fillColor = asteroidColor
        self.lineWidth = 3
        

    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Choose border color based on damage
    private func damageColor() -> UIColor {
        switch damage {
        case -1:
            return .systemYellow
        case -2:
            return .systemOrange
        case -3:
            return .systemRed
        default:
            return .white
        }
    }
    
    
    // Update position based on movement type
    func updatePosition() {
        switch movementType {
        case .honing:
            if let scene = self.scene as? GameScene {
                let target = scene.activeWhirlpool?.position ?? scene.player.position
                
                // Adjust honing strength depending on target type
                let isWhirlpoolTarget = (scene.activeWhirlpool != nil)
                let strength: CGFloat = isWhirlpoolTarget ? honingStrength * 3 : honingStrength

                let dx = target.x - self.position.x
                self.position.x += dx * strength
                self.position.y -= movementSpeed
            }

        case .drifting:
            self.position.x += driftRate
            self.position.y -= movementSpeed

        case .straightLine:
            self.position.y -= movementSpeed
        }

        // Destroy asteroid if it moves off screen
        if self.position.y < -self.frame.size.height {
            self.removeFromParent()
        }
    }
    
    
}

// Helper extension for random movement type
extension Asteroid.MovementType {
    static func random() -> Asteroid.MovementType {
        let types: [Asteroid.MovementType] = [.honing, .drifting, .straightLine]
        return types.randomElement() ?? .straightLine
    }
}
