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
        minMovementSpeed = 4
        minHoningStrength = 0.001
        maxMovementSpeed = 10
        maxHoningStrength = 0.015
    }
    
    // Initializer for the Asteroid class
    init(size: CGFloat, position: CGPoint, player: SKShapeNode) {
        if Asteroid.minMovementSpeed == nil {
            Asteroid.resetAsteroids()
        }
        self.player = player
        let minSpeed: CGFloat = Asteroid.waveOn ? Asteroid.minMovementSpeed * 0.80: Asteroid.minMovementSpeed
        let maxSpeed: CGFloat = Asteroid.waveOn ? Asteroid.maxMovementSpeed * 0.80: Asteroid.maxMovementSpeed
        self.movementSpeed = CGFloat.random(in: minSpeed...maxSpeed)
        self.honingStrength = CGFloat.random(in: Asteroid.minHoningStrength...Asteroid.maxHoningStrength)
        
        // Define probabilities for damage and healing
        let damageWeights = Int.random(in: 1...101)
        
        if damageWeights <= 70 {
            self.damage = 1  // 70% chance
        } else if damageWeights <= 90 {
            self.damage = 2  // 20% chance
        } else if damageWeights <= 99 {
            self.damage = 3  // 9% chance
        } else {
            self.damage = -1 // 1% chance (healing asteroid)
        }
        
        self.movementType = MovementType.random()
        self.driftRate = CGFloat.random(in: -1...1)
        
        super.init()
        
        // Draw the asteroid shape
        let randomPoints = Int.random(in: 20...40)
        let path = CGMutablePath()
        var angle: CGFloat = 0.0
        let angleIncrement = (2 * .pi) / CGFloat(randomPoints)
        
        path.move(to: CGPoint(x: size, y: 0)) // Start point
        
        for _ in 1...randomPoints {
            // Randomizing jaggedness
            let radiusVariation = CGFloat.random(in: 0.7...1.0)
            let x = size * cos(angle) * radiusVariation
            let y = size * sin(angle) * radiusVariation
            path.addLine(to: CGPoint(x: x, y: y))
            angle += angleIncrement
        }
        
        path.closeSubpath()
        self.position = position
        self.strokeColor = damageColor()
        
        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotationTime = Double.random(in: 3...5)
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
        
        
        if self.damage == -1 {
            self.path = SKShapeNode(circleOfRadius: 10).path
            self.fillColor = .green
            
        } else {
            self.path = path
            self.fillColor = asteroidColor
            self.lineWidth = 3
        }
        

    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Choose border color based on damage
    private func damageColor() -> UIColor {
        switch damage {
        case 1:
            return .yellow
        case 2:
            return .orange
        case 3:
            return .red
        case -1:
            return .green
        default:
            return .white
        }
    }
    
    
    // Update position based on movement type
    func updatePosition() {
        switch movementType {
        case .honing:
            let dx = player.position.x - self.position.x
            self.position.x += dx * honingStrength
            self.position.y -= movementSpeed
            
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
