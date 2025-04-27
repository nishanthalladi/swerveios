import SpriteKit
import CoreMotion

class GameScene: SKScene {
    var miniModeActive = false
    var miniModeUntilScore = 0
    var isGameActive = true
    var player: SKShapeNode!
    let motionManager = CMMotionManager()
    
    // Configuration parameters
    var sensitivity: CGFloat = 90.0
    var waterSensitivity: CGFloat = 80.0
    var lerpFactor: CGFloat = 0.5
    let boxSize = CGSize(width: 40, height: 40)
    var shield: SKShapeNode!
    var airMarker: SKShapeNode?
    var beam: SKSpriteNode!
    
    // Game state variables
    var boxes: [Asteroid] = []
    var hearts = 1
    var stars: [SKShapeNode] = []
    var rightmostHeartXVal: CGFloat = 30
    var deaths = 0
    var lastUpdatedLevelFrame = 0
    var score = 0
    var highscore = 0
    var maxAsteroids = 5
    var controlsAreReversed: Bool = false
    var invincible: Bool = false
    var dragoonCount: Int = 0
    
    var shieldIndicator: SKShapeNode!
    var shieldActive = false
    var lastShieldActivationFrame = 0
    let shieldCooldownDuration = 300 // 3-second cooldown
    
    var parryActive = false
    var parryFrames = 5
    var parryCooldownFrames = 10
    var lastParryActivationFrame = 0
    
    var waveNumber = 1
    var waveOnFrames = 1000
    var waveOffFrames = 500
    var lastWaveStartedFrame = 0
    
    var swipeLeftActive = false
    var swipeLeftFrames = 500
    
    var lastBeamStartedFrame = -250
    var beamCooldownFrames = 250
    
    var whirlpoolDurationSeconds = 10
    
    var touchStartPoint: CGPoint?
    
    var slotUp: ItemType?
    var slotDown: ItemType?
    var slotLeft: ItemType?
    var slotRight: ItemType?
    var customSlotUpEmoji: String?
    var customSlotDownEmoji: String?
    var customSlotLeftEmoji: String?
    var customSlotRightEmoji: String?

    var itemSlotLabels: [SKLabelNode] = []
    
    var dragoonParts: [ItemSlot: Int] = [.up: 0, .down: 0]
    
    var invincibleUntilScore = 0
    var activeWhirlpool: SKNode?
    
    var itemMagnetActive = false
    var itemMagnetUntilScore = 0
    
    var dragoonEffectUntilScore = 0
    
    var originalMinSpeed: CGFloat?
    var originalMaxSpeed: CGFloat?
    
    var restartLabel: SKLabelNode?
    
    var calibrationX: Double = 0.0
    var calibrationY: Double = 0.0
    
    var playerColor: UIColor = .white
    
    enum ItemSlot {
        case up, down, left, right
    }
    
    let playerColors: [UIColor] = [
        .white, .red, .green, .blue, .yellow, .orange,
        .purple, .cyan, .magenta, .brown, .black, .systemTeal
    ]

    
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
    
    let wavelabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Impact")
        label.fontSize = 24
        label.fontColor = .gray
        label.text = "0"
        return label
    }()
    
    let heartlabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Impact")
        label.fontSize = 24
        label.fontColor = .white
        label.text = "x"
        return label
    }()
    
    var infoPopup: SKShapeNode!
    
    func setupGame() {
        createStarryBackground()
        setupPlayer()
        setupMotion()
        // Load calibration values from UserDefaults if available
        if let savedCalibrationX = UserDefaults.standard.object(forKey: "calibrationX") as? Double,
           let savedCalibrationY = UserDefaults.standard.object(forKey: "calibrationY") as? Double {
            calibrationX = savedCalibrationX
            calibrationY = savedCalibrationY
        }
        // Load saved player color
        if let savedColorIndex = UserDefaults.standard.object(forKey: "playerColorIndex") as? Int {
            if savedColorIndex >= 0 && savedColorIndex < playerColors.count {
                playerColor = playerColors[savedColorIndex]
            }
        }
        spawnAsteroids(count: 5)
        setupShield()
        setupLabels()
        setupBeam()
        setupInfoButton()
        setupInfoPopup()
    }
    
    func setupBeam() {
        beam = SKSpriteNode(color: .red, size: CGSize(width: 5, height: frame.height))
        beam.position = CGPoint(x: player.position.x, y: player.position.y)
        beam.zPosition = 10
        addChild(beam)
        beam.isHidden = true
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
    
    func setupLabels() {
        scorelabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        addChild(scorelabel)
        
        if UserDefaults.standard.object(forKey: "highscore") != nil {
            highscore = UserDefaults.standard.integer(forKey: "highscore")
        }
        
        highscorelabel.position = CGPoint(x: size.width / 2, y: size.height - 75)
        addChild(highscorelabel)
        
        heartlabel.position = CGPoint(x: (3 / 4) * size.width, y: size.height - 70)
        heartlabel.zPosition = -1
        addChild(heartlabel)
    
        
        wavelabel.position = CGPoint(x: (3 / 4) * size.width, y: size.height - 100)
        addChild(wavelabel)
        
        setupItemSlotLabels()
    }
    
    func setupInfoButton() {
        let infoButton = SKLabelNode(fontNamed: "New York")
        infoButton.name = "infoButton"
        infoButton.text = "i"
        infoButton.fontSize = 30
        infoButton.fontColor = .white
        infoButton.position = CGPoint(x: size.width - 40, y: size.height - 50)
        infoButton.zPosition = 5
        
        // Add invisible tappable area
        let hitbox = SKShapeNode(rectOf: CGSize(width: 60, height: 60))
        hitbox.fillColor = .clear
        hitbox.strokeColor = .clear
        hitbox.position = infoButton.position
        hitbox.name = "infoButton" // same name for detection
        hitbox.zPosition = 99
        
        addChild(hitbox)
        addChild(infoButton)
    }
    
    func setupInfoPopup() {
        let width: CGFloat = size.width * 0.8
        let height: CGFloat = size.height * 0.5
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        let popup = SKShapeNode(rect: rect, cornerRadius: 10)
        popup.fillColor = .black
        popup.alpha = 0.85
        popup.strokeColor = .white
        popup.lineWidth = 2
        popup.zPosition = 101
        popup.position = CGPoint(x: size.width/2, y: size.height/2)
        popup.name = "infoPopup"
        popup.isHidden = true

        let label = SKLabelNode(fontNamed: "Impact")
        label.text = "Catch '?' for items and swipe to use!"
        label.fontSize = 18
        label.fontColor = .white
        label.numberOfLines = 0
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 180)
        label.zPosition = 102
        popup.addChild(label)
        
        let slider = UISlider(frame: CGRect(x: size.width * 0.25, y: size.height * 0.35, width: size.width * 0.5, height: 20))
        slider.minimumValue = 50
        slider.maximumValue = 250
        slider.value = Float(sensitivity)
        slider.addTarget(self, action: #selector(sensitivitySliderChanged(_:)), for: .valueChanged)
        
        let sensitivityLabel = SKLabelNode(fontNamed: "Impact")
        sensitivityLabel.text = "Sensitivity"
        sensitivityLabel.fontSize = 18
        sensitivityLabel.fontColor = .white
        sensitivityLabel.verticalAlignmentMode = .center
        sensitivityLabel.horizontalAlignmentMode = .center
        sensitivityLabel.position = CGPoint(x: 0, y: 80)
        //        sensitivityLabel.position = .zero
        popup.addChild(sensitivityLabel)
        
        let calibrateButton = SKLabelNode(fontNamed: "Impact")
        calibrateButton.text = "Set As Flat"
        calibrateButton.name = "calibrateButton"
        calibrateButton.fontSize = 22
        calibrateButton.fontColor = .white
        calibrateButton.position = CGPoint(x: 0, y: 0) // Under the slider
        calibrateButton.zPosition = 102
        popup.addChild(calibrateButton)
        
        // Add color picker buttons
        setupColorPicker(in: popup)
        
        if let skView = self.view {
            skView.addSubview(slider)
            slider.tag = 101 // so you can reference it later
            slider.isHidden = true
        }
        
        infoPopup = popup
        addChild(infoPopup)
    }

    func setupColorPicker(in popup: SKShapeNode) {
        let spacingX: CGFloat = 40
        let spacingY: CGFloat = 40
        let startX = -spacingX * 2.5
        let startY: CGFloat = -110
        
        for (index, color) in playerColors.enumerated() {
            let button = SKShapeNode(circleOfRadius: 15)
            button.fillColor = color
            button.strokeColor = .clear
            let column = index % 6
            let row = index / 6
            button.position = CGPoint(
                x: startX + spacingX * CGFloat(column),
                y: startY - spacingY * CGFloat(row)
            )
            button.name = "color_\(index)"
            button.zPosition = 102
            popup.addChild(button)
        }
    }
    
    @objc func sensitivitySliderChanged(_ sender: UISlider) {
        self.sensitivity = CGFloat(sender.value)
        UserDefaults.standard.set(self.sensitivity, forKey: "sensitivity")
    }
    
    func setupPlayer() {
        player = createPlayer(size: 8)
        player.fillColor = playerColor
        player.strokeColor = .white
        player.lineWidth = 3
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        if UserDefaults.standard.object(forKey: "sensitivity") != nil {
            sensitivity = CGFloat(UserDefaults.standard.float(forKey: "sensitivity"))
        }
        addChild(player)
    }
    
    func setupItemSlotLabels() {
        let positions = [
            CGPoint(x: 80, y: size.height - 80),     // Up
            CGPoint(x: 120, y: size.height - 120),     // Right
            CGPoint(x: 80, y: size.height - 160),    // Down
            CGPoint(x: 40, y: size.height - 120)     // Left
        ]

        for i in 0..<4 {
            let label = SKLabelNode(fontNamed: "Impact")
            label.fontSize = 24
            label.fontColor = .white
            label.position = positions[i]
            label.text = "•"
            itemSlotLabels.append(label)
            addChild(label)
        }
    }
    
    func setupMotion() {
//        if motionManager.isAccelerometerAvailable {
//            motionManager.startAccelerometerUpdates()
//        }
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates()
        }
    }
    
    override func didMove(to view: SKView) {
        
        self.view?.preferredFramesPerSecond = 60
        
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
        
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        view.addGestureRecognizer(panGesture)
        
//        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
//        longPress.minimumPressDuration = 0.1 // Adjust duration as needed
//        view.addGestureRecognizer(longPress)
        
        setupGame()
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .ended {
            let velocity = gesture.velocity(in: view)
            let direction = CGVector(dx: velocity.x, dy: velocity.y)

            let length = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
            guard length > 0 else { return }

            let normalized = CGVector(dx: direction.dx / length, dy: -direction.dy / length)
            let teleportStrength = 150.0
            let deltaX = normalized.dx * teleportStrength
            let deltaY = normalized.dy * teleportStrength

            teleportPlayer(byX: deltaX, byY: deltaY)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameActive {
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
            updateItemDrops()
            updateInvincibility()
            updateItemMagnet()
            updateMiniMode()
        }
    }
    
    func updateItemDrops() {
        if Int.random(in: 1...600) == 1 { //10 seconds about
            spawnItemDrop()
        }
    }
    
    func updateInvincibility() {
        invincible = score < invincibleUntilScore
        if !invincible {
            removeStarVisuals()
        }
    }
    
    func spawnItemDrop(at position: CGPoint? = nil) {
        let dropPosition = position ?? CGPoint(
            x: CGFloat.random(in: 30...(size.width - 30)),
            y: size.height + 30
        )

        
        let item = Item(type: .mysteryBox, position: dropPosition)

        // Add a falling action
        let fallDuration = Double.random(in: 4.0...6.0)
        let fallAction = SKAction.moveTo(y: -50, duration: fallDuration)
        let removeAction = SKAction.removeFromParent()
        item.run(SKAction.sequence([fallAction, removeAction]))

        addChild(item)
    }
    
    func updateBeam() {
        beam.position = CGPoint(x: player.position.x, y: player.position.y + frame.height / 2)
        if !beam.isHidden {
            if score > lastBeamStartedFrame + 30 {
                beam.isHidden = true
            }
        }
    }
    
    func updateWave() {
        wavelabel.text = "WAVE \(waveNumber)"
        wavelabel.fontColor = Asteroid.waveOn ? .red : .lightGray
        if Asteroid.waveOn {
            if (score - lastWaveStartedFrame) > waveOnFrames {
                Asteroid.waveOn = false
                lastWaveStartedFrame = score
                waveNumber += 1
                addHearts(count: 1)
            }
        } else {
            if (score - lastWaveStartedFrame) > waveOffFrames {
                Asteroid.waveOn = true
                lastWaveStartedFrame = score
            }
        }
    }
    
    func updateParry() {
        if parryActive {
            player.fillColor = playerColor
        } else {
            player.fillColor = playerColor
        }
        
        if score - lastParryActivationFrame > parryFrames {
            parryActive = false
        }
    }
    
//    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
//        if gesture.state == .began {
//            // Trigger your action once when the hold begins
//            activateBeam()
//        } else if gesture.state == .ended || gesture.state == .cancelled {
//            // Optional: Handle what happens when the player lifts their finger
//            beam.isHidden = true
//        }
//    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if score - lastParryActivationFrame > parryCooldownFrames {
//            parryActive = true
//            lastParryActivationFrame = score
//        }
        
//        if hearts <= 0 {
//            restartGameScene()
//        }
//        activateBeam()
        if let touch = touches.first {
            touchStartPoint = touch.location(in: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if hearts <= 0 {
            restartGameScene()
            return
        }
        
        guard let _ = touchStartPoint, let touch = touches.first else { return }
        let end = touch.location(in: self)
        
        let tappedNodes = nodes(at: end)
        if tappedNodes.contains(where: { $0.name == "infoButton" }) {
            let showingPopup = infoPopup.isHidden == true

            infoPopup.isHidden = !showingPopup

            if let skView = self.view, let slider = skView.viewWithTag(101) as? UISlider {
                slider.isHidden = !showingPopup
            }

            isGameActive = !showingPopup
            return
        }
        
        if tappedNodes.contains(where: { $0.name == "calibrateButton" }) {
            calibrateAccelerometer()
            return
        }

        // Color picker tap handling
        for node in tappedNodes {
            if let name = node.name, name.starts(with: "color_") {
                let indexString = name.replacingOccurrences(of: "color_", with: "")
                if let index = Int(indexString) {
                    playerColor = playerColors[index]
                    player.fillColor = playerColor
                    UserDefaults.standard.set(index, forKey: "playerColorIndex")
                }
                return
            }
        }

        if !infoPopup.isHidden && !infoPopup.contains(end) {
            infoPopup.isHidden = true
            if let skView = self.view, let slider = skView.viewWithTag(101) as? UISlider {
                slider.isHidden = true
            }
            isGameActive = true
            return
        }
    }
    
    @objc func handleSwipeUp(_ gesture: UISwipeGestureRecognizer) {
        useItem(from: .up)
        // teleportPlayer(byX: 0, byY: frame.width / 2)
    }

    @objc func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        useItem(from: .right)
//         teleportPlayer(byX: frame.width / 2, byY: 0)
    }

    @objc func handleSwipeDown(_ gesture: UISwipeGestureRecognizer) {
        useItem(from: .down)
        // teleportPlayer(byX: 0, byY: -frame.width / 2)
    }

    @objc func handleSwipeLeft(_ gesture: UISwipeGestureRecognizer) {
        useItem(from: .left)
//         teleportPlayer(byX: -frame.width / 2, byY: 0)
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
    
    func updateShield() {
        shield.position = player.position
        shieldIndicator.isHidden = !canActivateShield()
        
        if shieldActive && score - lastShieldActivationFrame > 250 {
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
        let numberOfStars = 20
        
        for _ in 0..<numberOfStars {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2)) // Small circles as stars
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat.random(in: 0...self.size.width),
                                    y: CGFloat.random(in: 0...self.size.height))
            star.zPosition = -1 // Behind all other game elements
            let flashProbability: CGFloat = 0.2 // Adjust this value between 0.0 (no stars flash) and 1.0 (all stars flash)
            if CGFloat.random(in: 0...1) < flashProbability {
                let blinkAction = SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.0, duration: Double.random(in: 0.5...1.0)),
                        SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 0.5...1.0))
                    ])
                )
                star.run(blinkAction)
            }
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
        if hearts > 0 {
            heartlabel.text = "❤️ \(hearts)"
        } else {
            heartlabel.text = "❤️ 0"
        }
    }
    
    func restartGameScene() {
        restartLabel?.removeFromParent()
        restartLabel = nil
        if let view = self.view {
            Asteroid.resetAsteroids()
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
            view.presentScene(newScene)
        }
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
    
    func addHearts(count: Int) {
        hearts += count
    }
    
    func spawnAsteroids(count: Int) {
        guard score >= dragoonEffectUntilScore else { return }

        for _ in 0..<count {
            let randomX = Int.random(in: 1...5) == 1 ? player.position.x : CGFloat.random(in: 0...(size.width - boxSize.width))
            let asteroid = Asteroid(size: CGFloat.random(in: 10...50), position: CGPoint(x: randomX, y: size.height), player: player)
            addChild(asteroid)
            boxes.append(asteroid)
        }
    }
    
    func updatePlayerPosition() {
//        guard let data = motionManager.accelerometerData else { return }
//        let adjustedX = data.acceleration.x - calibrationX
//        let adjustedY = data.acceleration.y - calibrationY
        
        guard let attitude = motionManager.deviceMotion?.attitude else { return }
        let adjustedX = attitude.roll - calibrationX
        let adjustedY = -(attitude.pitch - calibrationY)
        
        let targetPosition = CGPoint(
            x: player.position.x + CGFloat(adjustedX) * sensitivity,
            y: player.position.y + CGFloat(adjustedY) * sensitivity
        )
        
        player.position = CGPoint(
            x: max(10, min(lerp(a: player.position.x, b: targetPosition.x, t: lerpFactor), size.width - 10)),
            y: max(10, min(lerp(a: player.position.y, b: targetPosition.y, t: lerpFactor), size.height - 10))
        )
    }
    
    func checkForCollisions() {
        for (index, asteroid) in boxes.enumerated().reversed() {
            if invincible && player.frame.intersects(asteroid.frame) {
                removeAsteroid(at: index)
                spawnAsteroids(count: 1)
                return
            }
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
                addHearts(count: asteroid.damage)
                
                if hearts <= 0 {
                    UserDefaults.standard.set(highscore, forKey: "highscore")
                    isGameActive = false
                    isPaused = true
                    showRestartPrompt()
                }
                
                deaths += asteroid.damage
            }
            
            if !beam.isHidden && beam.frame.intersects(asteroid.frame) {
                triggerHapticFeedback()
                removeAsteroid(at: index)
                spawnAsteroids(count: 1)
            }
        }
        
        for case let item as Item in children {
            if player.frame.intersects(item.frame) {
                let actualType: ItemType = item.type == .mysteryBox
                    ? ItemType.allCases.filter { $0 != .mysteryBox }.randomElement()!
                    : item.type

                handleItemPickup(Item(type: actualType, position: item.position))
                item.removeFromParent()
            }
        }
    }
    
    func showRestartPrompt() {
        let label = SKLabelNode(fontNamed: "Impact")
        label.text = "Tap to Restart"
        label.fontSize = 30
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 200
        addChild(label)
        restartLabel = label
    }
    
    
    func assignToFirstFreeSlot(_ item: ItemType, slot fallbackSlot: ItemSlot? = nil) -> Bool {
        if slotUp == nil {
            slotUp = item
            return true
        } else if slotRight == nil {
            slotRight = item
            return true
        } else if slotDown == nil {
            slotDown = item
            return true
        } else if slotLeft == nil {
            slotLeft = item
            return true
        }
        
        else if let fallback = fallbackSlot {
            switch fallback {
            case .up:
                slotUp = item
            case .down:
                slotDown = item
            case .left:
                slotLeft = item
            case .right:
                slotRight = item
            }
            return true
        }
        return false
    }
    
    func handleItemPickup(_ item: Item) {
        switch item.type {

        case .dragoonPart:
            if slotUp == .dragoonPart {
                dragoonParts[.up, default: 0] += 1
                checkDragoonComplete(slot: .up)
                updateItemSlotLabels()
                return
            }

            if slotDown == .dragoonPart {
                dragoonParts[.down, default: 0] += 1
                checkDragoonComplete(slot: .down)
                updateItemSlotLabels()
                return
            }
            
            if slotLeft == .dragoonPart {
                dragoonParts[.left, default: 0] += 1
                checkDragoonComplete(slot: .left)
                updateItemSlotLabels()
                return
            }
            
            if slotRight == .dragoonPart {
                dragoonParts[.right, default: 0] += 1
                checkDragoonComplete(slot: .right)
                updateItemSlotLabels()
                return
            }

            // If no current stack, assign to first free
            if slotUp == nil {
                slotUp = .dragoonPart
                dragoonParts[.up] = 1
                updateItemSlotLabels()
                return
            }
            
            if slotRight == nil {
                slotRight = .dragoonPart
                dragoonParts[.right] = 1
                updateItemSlotLabels()
                return
            }

            if slotDown == nil {
                slotDown = .dragoonPart
                dragoonParts[.down] = 1
                updateItemSlotLabels()
                return
            }
            
            if slotLeft == nil {
                slotLeft = .dragoonPart
                dragoonParts[.left] = 1
                updateItemSlotLabels()
                return
            }
            
            // All slots full — do nothing
            return

        default:
            _ = assignToFirstFreeSlot(item.type)
            updateItemSlotLabels()
        }
    }
    
    func checkDragoonComplete(slot: ItemSlot) {
        if dragoonParts[slot, default: 0] >= 3 {
            dragoonParts[slot] = 0
            if slot == .up {
                customSlotUpEmoji = "💥"
            } else if slot == .left {
                customSlotLeftEmoji = "💥"
            } else if slot == .right {
                customSlotRightEmoji = "💥"
            } else {
                customSlotDownEmoji = "💥"
            }
//            clearAllAsteroids()
        }
    }
    
    func updateItemMagnet() {
        if score > itemMagnetUntilScore {
            itemMagnetActive = false
            return
        }

        for case let item as Item in children {
            let dx = player.position.x - item.position.x
            let dy = player.position.y - item.position.y
//            let distance = sqrt(dx*dx + dy*dy)

            let attractionStrength: CGFloat = 0.1
            item.position.x += dx * attractionStrength
            item.position.y += dy * attractionStrength
        }
    }
    
    func updateItemSlotLabels() {
        let emojis: [String] = [
            formattedSlotDisplay(for: .up),
            formattedSlotDisplay(for: .right),
            formattedSlotDisplay(for: .down),
            formattedSlotDisplay(for: .left)
        ]
        for (i, emoji) in emojis.enumerated() {
            itemSlotLabels[i].text = emoji
        }
    }
    
    func formattedSlotDisplay(for slot: ItemSlot) -> String {
        let type: ItemType?
        let custom: String?
        let count: Int = dragoonParts[slot, default: 0]

        switch slot {
        case .up:
            type = slotUp
            custom = customSlotUpEmoji
        case .right:
            type = slotRight
            custom = customSlotRightEmoji
        case .down:
            type = slotDown
            custom = customSlotDownEmoji
        case .left:
            type = slotLeft
            custom = customSlotLeftEmoji
            
        }

        if let customEmoji = custom {
            return customEmoji
        }

        if type == .dragoonPart && count > 0 {
            return "\(type!.emoji)\(count)/3"
        }

        return type?.emoji ?? "•"
    }
    
    
    func useItem(from slot: ItemSlot) {
        var itemType: ItemType?
     
        // Peek into slot first to determine item type
        switch slot {
        case .up:
            itemType = slotUp
        case .right:
            itemType = slotRight
        case .down:
            itemType = slotDown
        case .left:
            itemType = slotLeft
        }
     
        guard let type = itemType else { return }
     
        // Handle dragoonPart with 💥 prepped explosion
        if type == .dragoonPart {
            // If explosion is already prepped (💥), trigger immediately
            if formattedSlotDisplay(for: slot).contains("💥") {
                dragoonParts[slot] = 0
                clearAllAsteroids()
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 7),
                    SKAction.run {
                        self.spawnAsteroids(count: self.maxAsteroids)
                    }
                ]))
                dragoonEffectUntilScore = score + 300

                switch slot {
                case .up:
                    slotUp = nil
                    customSlotUpEmoji = nil
                case .right:
                    slotRight = nil
                    customSlotRightEmoji = nil
                case .down:
                    slotDown = nil
                    customSlotDownEmoji = nil
                case .left:
                    slotLeft = nil
                    customSlotLeftEmoji = nil
                }
                updateItemSlotLabels()
                return
            }

            updateItemSlotLabels()
            return
        }
     
        // For all other items, clear slot and use
        switch slot {
        case .up:
            slotUp = nil
            customSlotUpEmoji = nil
        case .right:
            slotRight = nil
            customSlotRightEmoji = nil
        case .down:
            slotDown = nil
            customSlotDownEmoji = nil
        case .left:
            slotLeft = nil
            customSlotLeftEmoji = nil
        }
     
        switch type {
//        case .shield:
//            activateShield()
        case .timeSlow:
            slowAsteroids(duration: 5)
        case .mysteryBox:
            let randomItem = ItemType.allCases.randomElement()!
            _ = assignToFirstFreeSlot(randomItem)
        case .star:
            activateInvincibility(duration: 300)
        case .redShell:
            activateBeam()
        case .whirlpool:
            dropWhirlpool()
        case .lives:
//            activateItemMagnet(duration: 300)
            addHearts(count: 1)
        case .miniMode:
            activateMiniMode(duration: 400) // Approximately 5 seconds
        default:
            break
        }
     
        updateItemSlotLabels()
    }

    func activateMiniMode(duration: Int) {
        if miniModeActive { return }

        miniModeActive = true
        miniModeUntilScore = score + duration

        let shrink = SKAction.scale(to: 0.5, duration: 0.3)
        player.run(shrink)
    }

    func updateMiniMode() {
        if miniModeActive && score >= miniModeUntilScore {
            miniModeActive = false

            let restore = SKAction.scale(to: 1.0, duration: 0.3)
            player.run(restore)
        }
    }
    
    func activateItemMagnet(duration: Int) {
        itemMagnetActive = true
        itemMagnetUntilScore = score + duration
    }
    
    
    
    func slowAsteroids(duration: Int) {
        if originalMinSpeed == nil || originalMaxSpeed == nil {
            originalMinSpeed = Asteroid.minMovementSpeed
            originalMaxSpeed = Asteroid.maxMovementSpeed
        }

        Asteroid.maxMovementSpeed *= 0.5
        Asteroid.minMovementSpeed *= 0.5

        run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(duration)),
            SKAction.run {
                if let originalMin = self.originalMinSpeed, let originalMax = self.originalMaxSpeed {
                    Asteroid.maxMovementSpeed = originalMax
                    Asteroid.minMovementSpeed = originalMin
                }
                self.originalMinSpeed = nil
                self.originalMaxSpeed = nil
            }
        ]))
    }
 
    func launchHomingMissile() {
        guard let target = boxes.first else { return }

        let missile = SKShapeNode(circleOfRadius: 10)
        missile.fillColor = .red
        missile.position = player.position
        missile.zPosition = 10
        addChild(missile)

        let move = SKAction.move(to: target.position, duration: 0.5)
        let impact = SKAction.run {
            if let index = self.boxes.firstIndex(of: target) {
                self.removeAsteroid(at: index)
                self.spawnAsteroids(count: 1)
            }
            missile.removeFromParent()
        }

        missile.run(SKAction.sequence([move, impact]))
    }
    
    func activateInvincibility(duration: Int) {
        invincibleUntilScore = score + duration
        applyStarVisuals()
    }
    
    func applyStarVisuals() {
        let glow = SKAction.sequence([
            SKAction.run { self.player.strokeColor = .yellow },
            SKAction.wait(forDuration: 0.25),
            SKAction.run { self.player.strokeColor = .orange },
            SKAction.wait(forDuration: 0.25)
        ])
        player.run(SKAction.repeatForever(glow), withKey: "starGlow")
    }

    func removeStarVisuals() {
        player.removeAction(forKey: "starGlow")
        player.strokeColor = .white
        player.fillColor = playerColor
    }
 
    func dropWhirlpool() {
        let whirlpool = SKShapeNode(circleOfRadius: 7)
        whirlpool.fillColor = .systemBlue
        whirlpool.strokeColor = .systemBlue
//        whirlpool.alpha = 0.4
        whirlpool.position = player.position
        whirlpool.zPosition = 3
        addChild(whirlpool)
        
        activeWhirlpool = whirlpool

        run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(whirlpoolDurationSeconds)),
            SKAction.run {
                whirlpool.removeFromParent()
                self.activeWhirlpool = nil
            }
        ]))
    }
 
    func clearAllAsteroids() {
        for asteroid in boxes {
            asteroid.removeFromParent()
        }
        boxes.removeAll()
    }
 
    func adjustLevelBasedOnTime() {
        Asteroid.maxMovementSpeed += 0.0001
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
    
    func calibrateAccelerometer() {
//        if let data = motionManager.accelerometerData {
//            calibrationX = data.acceleration.x
//            calibrationY = data.acceleration.y
//            UserDefaults.standard.set(calibrationX, forKey: "calibrationX")
//            UserDefaults.standard.set(calibrationY, forKey: "calibrationY")
//        }
        if let attitude = motionManager.deviceMotion?.attitude {
            calibrationX = attitude.roll
            calibrationY = attitude.pitch
            UserDefaults.standard.set(calibrationX, forKey: "calibrationX")
            UserDefaults.standard.set(calibrationY, forKey: "calibrationY")
        }
        
        let flash = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        flash.fillColor = .white
        flash.alpha = 0.3
        flash.zPosition = 999
        flash.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
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

