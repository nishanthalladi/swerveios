import SpriteKit
import CoreMotion

class GameScene: SKScene {
    var player: SKShapeNode!
    let motionManager = CMMotionManager()
    
    // Configuration parameters
    var sensitivity: CGFloat = 80.0
    var waterSensitivity: CGFloat = 80.0
    var lerpFactor: CGFloat = 0.5
    let boxSize = CGSize(width: 40, height: 40)
    var shield: SKShapeNode!
    var airMarker: SKShapeNode?
    var beam: SKSpriteNode!
    
    // Game state variables
    var boxes: [Asteroid] = []
    var hearts = 9
    var stars: [SKShapeNode] = []
    var rightmostHeartXVal: CGFloat = 30
    var deaths = 0
    var lastUpdatedLevelFrame = 0
    var score = 0
    var highscore = 0
    var maxAsteroids = 9
    
    var shieldIndicator: SKShapeNode!
    var shieldActive = false
    var lastShieldActivationFrame = 0
    let shieldCooldownDuration = 300 // 3-second cooldown
    
    var parryActive = false
    var parryFrames = 5
    var parryCooldownFrames = 10
    var lastParryActivationFrame = 0
    
//    var waveNumber = 1
//    var waveOnFrames = 1000
//    var waveOffFrames = 100
    var lastWaveStartedFrame = 0
    
    var swipeLeftActive = false
    var swipeLeftFrames = 500
    
    var lastBeamStartedFrame = -250
    var beamCooldownFrames = 250

    
    // UI elements
    let scorelabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Impact")
        label.fontSize = 24
        label.fontColor = .white
        label.text = "0"
        return label
    }()
    
    let highscorelabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Impact")
        label.fontSize = 24
        label.fontColor = .yellow
        label.text = "0"
        return label
    }()
    
//    let wavelabel: SKLabelNode = {
//        let label = SKLabelNode(fontNamed: "Impact")
//        label.fontSize = 30
//        label.fontColor = .gray
//        label.text = "0"
//        return label
//    }()
    
    let heartlabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Impact")
        label.fontSize = 30
        label.fontColor = .green
        label.text = "x"
        return label
    }()
    
    
    override func didMove(to view: SKView) {
        // Create swipe down gesture recognizer
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp(_:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.1 // Adjust duration as needed
        view.addGestureRecognizer(longPress)
        
        setupGame()
    }
    
    override func update(_ currentTime: TimeInterval) {
        updatePlayerPosition()
        updateAsteroids()
        checkForCollisions()
        adjustLevelBasedOnTime()
        updateScore()
        updateStars()
        updateShield()
        updateParry()
        updateWave()
        updateBeam()
        
        if hearts <= 0 && !isPaused {
            restartGameScene()
        }
    }
    
    func updateBeam() {
        beam.position = CGPoint(x: player.position.x, y: player.position.y + frame.height / 2)
        if !beam.isHidden {
            if score > lastBeamStartedFrame + 10 {
                beam.isHidden = true
            }
        }
    }
    
    func updateWave() { // now for swipeLeft water feature, slows down all asteroids
//        wavelabel.text = "WAVE \(waveNumber)"
//        wavelabel.fontColor = Asteroid.waveOn ? .red : .lightGray
        if Asteroid.waveOn {
            if (score - lastWaveStartedFrame) > swipeLeftFrames {
                Asteroid.waveOn = false
                lastWaveStartedFrame = score
//                waveNumber += 1
//                addHearts(count: 1)
            }
        } else {
//            if (score - lastWaveStartedFrame) > waveOffFrames {
//                Asteroid.waveOn = true
//                lastWaveStartedFrame = score
//            }
        }
    }
    
    func updateParry() {
        if parryActive {
            player.fillColor = .white
        } else {
            player.fillColor = .blue
        }
        
        if score - lastParryActivationFrame > parryFrames {
            parryActive = false
        }
    }
    
    func setupGame() {
        createStarryBackground()
        setupPlayer()
        setupMotion()
        spawnAsteroids(count: 5)
        setupShield()
        setupScores()
        setupHearts()
        setupBeam()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Trigger your action once when the hold begins
            activateBeam()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            // Optional: Handle what happens when the player lifts their finger
            beam.isHidden = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if score - lastParryActivationFrame > parryCooldownFrames {
//            parryActive = true
//            lastParryActivationFrame = score
//        }
        
//        if hearts <= 0 {
//            restartGameScene()
//        }
//        activateBeam()
    }
    
    @objc func handleSwipeDown(_ gesture: UISwipeGestureRecognizer) {
//        activateShield() // Call the shield activation function
//        activateBeam()
        teleportPlayer(byX: 0, byY: -frame.width / 2)
        
    }
    
    @objc func handleSwipeUp(_ gesture: UISwipeGestureRecognizer) {
//        activateMarkerTeleport()
        teleportPlayer(byX: 0, byY: frame.width / 2)
    }
    
    @objc func handleSwipeLeft(_ gesture: UISwipeGestureRecognizer) {
        teleportPlayer(byX: -frame.width / 2, byY: 0)
    }
    
    @objc func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        teleportPlayer(byX: frame.width / 2, byY: 0)
    }
    
    func activateWaterMode() {
        if score > lastWaveStartedFrame + swipeLeftFrames {
            Asteroid.waveOn = true
            lastWaveStartedFrame = score
        }
    }
    
    func activateMarkerTeleport() {
        if let marker = airMarker {
            // Teleport and remove
            player.position = marker.position
            marker.removeFromParent()
            airMarker = nil
        } else {
            // Create yellow X shape
            let size: CGFloat = 5
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size, y: -size))
            path.addLine(to: CGPoint(x: size, y: size))
            path.move(to: CGPoint(x: -size, y: size))
            path.addLine(to: CGPoint(x: size, y: -size))
            
            let marker = SKShapeNode(path: path)
            marker.strokeColor = .brown
            marker.lineWidth = 4
            marker.position = player.position
            marker.zPosition = 5
            
            addChild(marker)
            airMarker = marker
        }
    }
    
    func activateBeam() {
        if score > lastBeamStartedFrame + beamCooldownFrames {
            beam.position = CGPoint(x: player.position.x, y: player.position.y)
            lastBeamStartedFrame = score
            beam.isHidden = false
        }
    }
    
    func setupBeam() {
        beam = SKSpriteNode(color: .red, size: CGSize(width: 5, height: frame.height))
        beam.position = CGPoint(x: player.position.x, y: player.position.y)
        beam.zPosition = 10
        addChild(beam)
        beam.isHidden = true
    }
    
    func setupHearts() {
        let heart = SKShapeNode(circleOfRadius: 10)
        heart.fillColor = .green
        heart.strokeColor = .green
        heart.position = CGPoint(x: 75, y: size.height - 75)
        addChild(heart)
        
        heartlabel.position = CGPoint(x: 105, y: size.height - 85)
        heartlabel.zPosition = -1
        addChild(heartlabel)
    }
    
    func setupShield() {
        // Create the shield (a circular SKShapeNode)
        shield = SKShapeNode(circleOfRadius: 15)
        
        // Set shield appearance
        shield.strokeColor = .purple  // Outline color of the shield
        shield.lineWidth = 5        // Thickness of the shield's border
        shield.fillColor = .clear   // Transparent inside
        shield.position = player.position // Place the shield around the player
        shield.name = "playerShield" // Assign a name to identify it later
        
        shieldIndicator = SKShapeNode(circleOfRadius: 15)
        shieldIndicator.strokeColor = .purple
        shieldIndicator.lineWidth = 5
        shieldIndicator.position = CGPoint(x: 30, y: size.height - 75)
//        addChild(shieldIndicator)
    }
    
    func setupScores() {
        scorelabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        addChild(scorelabel)
        
        if UserDefaults.standard.object(forKey: "highscore") != nil {
            highscore = UserDefaults.standard.integer(forKey: "highscore")
        }
        
        highscorelabel.position = CGPoint(x: size.width / 2, y: size.height - 75)
        addChild(highscorelabel)
        
//        wavelabel.position = CGPoint(x: size.width - 75, y: size.height - 75)
//        addChild(wavelabel)
    }
    
    func updateShield() {
        shield.position = player.position
        shieldIndicator.isHidden = !canActivateShield()
        
        if shieldActive && score - lastShieldActivationFrame > 60 {
            destroyShield()
        }
    }
    
    func canActivateShield() -> Bool {
        if score - lastShieldActivationFrame >= shieldCooldownDuration {
            return true
        } else {
            return false
        }
    }
    
    func activateShield() {
        shieldActive = true
        lastShieldActivationFrame = score
        addChild(shield)
    }
    
    func destroyShield() {
        shieldActive = false
        lastShieldActivationFrame = score
        shield.removeFromParent()
    }
    
    func createStarryBackground() {
        let numberOfStars = 100
        
        for _ in 0..<numberOfStars {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2)) // Small circles as stars
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat.random(in: 0...self.size.width),
                                    y: CGFloat.random(in: 0...self.size.height))
            star.zPosition = -1 // Behind all other game elements
            stars.append(star)
            addChild(star)
        }
    }
    
    func updateStars() {
        for star in stars {
            star.position.y -= 1  // Move the star downward
            // Reposition the star to the top once it leaves the bottom of the screen
            if star.position.y < 0 {
                star.position.y = self.size.height
            }
        }
    }
    
    func updateScore() {
        score += 1
        scorelabel.text = "\(score)"
        highscore = max(score, highscore)
        highscorelabel.text = "\(highscore)"
        heartlabel.text = "x\(hearts)"
    }
    
    func restartGameScene() {
        if let view = self.view {
            Asteroid.resetAsteroids()
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
            view.presentScene(newScene)
        }
    }
    
    func setupPlayer() {
        player = createPlayer(size: 8)
        player.fillColor = .blue
        player.strokeColor = .white
        player.lineWidth = 3
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }
    
    func createPlayer(size: CGFloat) -> SKShapeNode {
        // Define the points of the triangle
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size))           // Top point
        path.addLine(to: CGPoint(x: -size, y: 0))       // Left point
        path.addLine(to: CGPoint(x: 0, y: -size/2))       // Bottom point
        path.addLine(to: CGPoint(x: size, y: 0))        // Right point
        path.closeSubpath()                                 // Close the path
        
        
        return SKShapeNode(path: path)
    }
    
    func setupMotion() {
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates()
        }
    }
    
    func addHearts(count: Int) {
        hearts += count
    }
    
    func removeHeart(count: Int) {
        if count < 0 {
            addHearts(count: 1)
            return
        }
        hearts -= 1
    }
    
    func spawnAsteroids(count: Int) {
        for _ in 0..<count {
            // Generate random x-position for the asteroid
            let randomX = Int.random(in: 1...5) == 1 ? player.position.x : CGFloat.random(in: 0...(size.width - boxSize.width))
            
            // Create asteroid
            let asteroid = Asteroid(size: CGFloat.random(in: 20...50), position: CGPoint(x: randomX, y: size.height), player: player)
            
            // Add asteroid to the scene and store it in the array
            addChild(asteroid)
            boxes.append(asteroid)
        }
    }
    
    func updatePlayerPosition() {
        guard let data = motionManager.accelerometerData else { return }
        let targetPosition = CGPoint(
            x: player.position.x + CGFloat(data.acceleration.x) * (Asteroid.waveOn ? waterSensitivity : sensitivity),
            y: player.position.y + CGFloat(data.acceleration.y) * (Asteroid.waveOn ? waterSensitivity : sensitivity)
        )
        player.position = CGPoint(
            x: max(10, min(lerp(a: player.position.x, b: targetPosition.x, t: lerpFactor), size.width - 10)),
            y: max(10, min(lerp(a: player.position.y, b: targetPosition.y, t: lerpFactor), size.height - 10))
        )
    }
    
    func checkForCollisions() {
        for (index, asteroid) in boxes.enumerated().reversed() {
            if parryActive && player.frame.intersects(asteroid.frame) {
                removeAsteroid(at: index)
                spawnAsteroids(count: 1)
                parryActive = false
                lastParryActivationFrame = score
                return
            }
            
            if shieldActive && shield.frame.intersects(asteroid.frame) {
                destroyShield()
                removeAsteroid(at: index)
                spawnAsteroids(count: 1)
                return
            }
            
            if player.frame.intersects(asteroid.frame) {
                triggerHapticFeedback()
                removeAsteroid(at: index)
                spawnAsteroids(count: 1)
                removeHeart(count: asteroid.damage)
                
                if hearts <= 0 {
                    UserDefaults.standard.set(highscore, forKey: "highscore")
                    isPaused = true
                }
                
                deaths += asteroid.damage
            }
            
            if !beam.isHidden && beam.frame.intersects(asteroid.frame) {
                triggerHapticFeedback()
                removeAsteroid(at: index)
                spawnAsteroids(count: 1)
            }
        }
    }
    
    func adjustLevelBasedOnTime() {
        Asteroid.maxMovementSpeed += 0.001
        Asteroid.minMovementSpeed += 0.0001
//        guard (score - lastUpdatedLevelFrame) > (1000) else { return }
//        
//        UserDefaults.standard.set(highscore, forKey: "highscore")
//        
//        if boxes.count < maxAsteroids && Int.random(in: 1...10) <= 2 {
//            spawnAsteroids(count: 1)
//        } else {
//            Asteroid.maxMovementSpeed += 0.50
//        }
//        
//        deaths = 0
//        lastUpdatedLevelFrame = score
    }
    
    func updateAsteroids() {
        for (index, asteroid) in boxes.enumerated().reversed() {
            asteroid.updatePosition() // Update asteroid's movement based on its movement type
            
            // If the asteroid has moved off the screen, remove it and spawn a new one
            if asteroid.position.y < -asteroid.frame.size.height {
                removeAsteroid(at: index)
                spawnAsteroids(count: 1)
            }
        }
    }
    
    func removeAsteroid(at index: Int) {
        boxes[index].removeFromParent() // Remove the asteroid from the scene
        boxes.remove(at: index)         // Remove from the array
    }
    
    func lerp(a: CGFloat, b: CGFloat, t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        generator.impactOccurred()
    }

    func teleportPlayer(byX deltaX: CGFloat, byY deltaY: CGFloat) {
        let newX = max(10, min(player.position.x + deltaX, size.width - 10))
        let newY = max(10, min(player.position.y + deltaY, size.height - 10))
        player.position = CGPoint(x: newX, y: newY)
    }
}


extension SKAction {
    static func followPlayer(player: SKShapeNode) -> SKAction {
        return SKAction.repeatForever(SKAction.run {
            if let shield = player.scene?.childNode(withName: "playerShield") as? SKShapeNode {
                shield.position = player.position // Make sure the shield stays around the player
            }
        })
    }
}
