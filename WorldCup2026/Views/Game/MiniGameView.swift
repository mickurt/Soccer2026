
import SwiftUI
import SpriteKit

struct MiniGameView: View {
    @State private var score: Int = 0
    @AppStorage("miniGameHighScore") private var highScore: Int = 0
    @State private var gameId = UUID()
    
    // Scene creation
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GeometryReader { bgGeometry in
                    Image("game_background")
                        .resizable()
                        .scaledToFill()
                        .frame(width: bgGeometry.size.width, height: bgGeometry.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
                
                SpriteView(scene: makeScene(size: geometry.size), options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .id(gameId) // Force recreate if needed
                
                VStack {
                    // Scores Header
                    HStack {
                        // Current Score
                        HStack(spacing: 6) {
                            Image(systemName: "soccerball")
                                .foregroundStyle(.white)
                            Text("\(score)")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                        .overlay(Capsule().stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                        
                        Spacer()
                        
                        // High Score
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.4))
                            Text(LocalizedStringKey("Best: \(highScore)"))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                        .overlay(Capsule().stroke(Color(red: 0.9, green: 0.8, blue: 0.4).opacity(0.5), lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                    }
                    .padding(.top, 10) // Moved up
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "hand.draw.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.8))
                            .offset(y: -10)
                        
                        Text(LocalizedStringKey("DRAG & RELEASE TO SHOOT!"))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 2)
                    }
                    .padding(.bottom, 60)
                    .allowsHitTesting(false)
                }
            }
        }
    }
    
    func makeScene(size: CGSize) -> SKScene {
        let scene = PenaltyGameScene(size: size)
        scene.scaleMode = .resizeFill
        scene.onGoal = {
            score += 1
            if score > highScore { highScore = score }
            triggerHaptic(type: .success)
        }
        scene.onMiss = {
            score = 0
            triggerHaptic(type: .error)
        }
        return scene
    }
    
    func triggerHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
    


class PenaltyGameScene: SKScene, SKPhysicsContactDelegate {
    
    var onGoal: (() -> Void)?
    var onMiss: (() -> Void)?
    
    private var ball: SKSpriteNode?
    private var goalkeeper: SKSpriteNode?
    private var goalLine: SKNode?
    
    let ballCategory: UInt32 = 0x1 << 0
    let keeperCategory: UInt32 = 0x1 << 1
    let goalLineCategory: UInt32 = 0x1 << 2
    let borderCategory: UInt32 = 0x1 << 3
    
    var isBallMoving = false
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.gravity = .zero 
        physicsWorld.contactDelegate = self
        
        setupPitch()
        setupGoal()
        setupKeeper()
        spawnBall()
        
        // Boundaries
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 0.5
        borderBody.categoryBitMask = borderCategory
        self.physicsBody = borderBody
    }
    
    // ... (Pitch and Goal setup remain same, omitting for brevity in replace tool if untouched, but including for context if needed. 
    // Wait, I am replacing a huge chunk. I need to be careful not to delete methods I don't show here.)
    // ACTUALLY, I will just proceed to the touch methods and methods that need changing.
    
    // ... setupPitch, setupGoal, setupKeeper ...
    
    func setupPitch() {
        let goalY = size.height * 0.55
        
        let boxWidth = size.width * 0.85
        let boxHeight = size.height * 0.25
        let boxY = goalY - (boxHeight / 2)
        
        let box = SKShapeNode(rectOf: CGSize(width: boxWidth, height: boxHeight))
        box.strokeColor = .clear
        box.lineWidth = 3
        box.position = CGPoint(x: size.width/2, y: boxY)
        addChild(box)
        
        let spot = SKShapeNode(circleOfRadius: 3)
        spot.fillColor = .clear
        spot.position = CGPoint(x: size.width/2, y: size.height * 0.20)
        addChild(spot)
    }
    
    func setupGoal() {
        let goalWidth: CGFloat = size.width * 0.84
        let goalY = size.height * 0.55
        let netDepth: CGFloat = size.height * 0.17 // Reduced height for realistic proportions
        
        // Visual Net container
        let netNode = SKNode()
        netNode.position = CGPoint(x: size.width/2, y: goalY + netDepth/2)
        
        // Draw real goal grid (Cadrillage)
        let gridSize: CGFloat = 15
        
        // Draw outline/frame with rounded top corners
        let framePath = CGMutablePath()
        let w = goalWidth / 2
        let h = netDepth / 2
        let cornerRadius: CGFloat = 20
        
        framePath.move(to: CGPoint(x: -w, y: -h)) // Bottom-left
        framePath.addLine(to: CGPoint(x: -w, y: h - cornerRadius)) // Left edge
        // Top-left corner
        framePath.addArc(center: CGPoint(x: -w + cornerRadius, y: h - cornerRadius), radius: cornerRadius, startAngle: .pi, endAngle: .pi/2, clockwise: true)
        // Top edge
        framePath.addLine(to: CGPoint(x: w - cornerRadius, y: h))
        // Top-right corner
        framePath.addArc(center: CGPoint(x: w - cornerRadius, y: h - cornerRadius), radius: cornerRadius, startAngle: .pi/2, endAngle: 0, clockwise: true)
        // Right edge
        framePath.addLine(to: CGPoint(x: w, y: -h))
        framePath.addLine(to: CGPoint(x: -w, y: -h)) // Bottom edge
        
        let frame = SKShapeNode(path: framePath)
        frame.strokeColor = .white
        frame.lineWidth = 3
        netNode.addChild(frame)
        
        // Draw horizontal lines
        var currentY = -netDepth/2 + gridSize
        while currentY < netDepth/2 {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -goalWidth/2, y: currentY))
            path.addLine(to: CGPoint(x: goalWidth/2, y: currentY))
            line.path = path
            line.strokeColor = .white.withAlphaComponent(0.4)
            line.lineWidth = 1
            netNode.addChild(line)
            currentY += gridSize
        }
        
        // Draw vertical lines
        var currentX = -goalWidth/2 + gridSize
        while currentX < goalWidth/2 {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: currentX, y: -netDepth/2))
            path.addLine(to: CGPoint(x: currentX, y: netDepth/2))
            line.path = path
            line.strokeColor = .white.withAlphaComponent(0.4)
            line.lineWidth = 1
            netNode.addChild(line)
            currentX += gridSize
        }
        
        addChild(netNode)
        
        // Physical Net Boundaries (Back and Sides)
        let backWall = SKNode()
        backWall.position = CGPoint(x: size.width/2, y: goalY + netDepth)
        backWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: goalWidth, height: 5))
        backWall.physicsBody?.isDynamic = false
        backWall.physicsBody?.categoryBitMask = borderCategory
        backWall.physicsBody?.collisionBitMask = ballCategory
        addChild(backWall)
        
        let leftWall = SKNode()
        leftWall.position = CGPoint(x: size.width/2 - goalWidth/2, y: goalY + netDepth/2)
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 5, height: netDepth))
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = borderCategory
        leftWall.physicsBody?.collisionBitMask = ballCategory
        addChild(leftWall)
        
        let rightWall = SKNode()
        rightWall.position = CGPoint(x: size.width/2 + goalWidth/2, y: goalY + netDepth/2)
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 5, height: netDepth))
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = borderCategory
        rightWall.physicsBody?.collisionBitMask = ballCategory
        addChild(rightWall)
        
        // Goal Line (Sensor)
        let sensor = SKShapeNode(rectOf: CGSize(width: goalWidth, height: 10))
        // Push the sensor deep into the net so the ball hits the keeper first
        sensor.position = CGPoint(x: size.width/2, y: goalY + 60)
        sensor.strokeColor = .clear
        
        sensor.physicsBody = SKPhysicsBody(rectangleOf: sensor.frame.size)
        sensor.physicsBody?.isDynamic = false
        sensor.physicsBody?.categoryBitMask = goalLineCategory
        sensor.physicsBody?.contactTestBitMask = ballCategory
        sensor.physicsBody?.collisionBitMask = 0
        addChild(sensor)
        self.goalLine = sensor
        
        // Posts
        let postL = SKShapeNode(circleOfRadius: 6)
        postL.fillColor = .white
        postL.position = CGPoint(x: size.width/2 - goalWidth/2, y: goalY)
        postL.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        postL.physicsBody?.isDynamic = false
        postL.physicsBody?.categoryBitMask = borderCategory
        postL.physicsBody?.collisionBitMask = ballCategory
        addChild(postL)
        
        let postR = SKShapeNode(circleOfRadius: 6)
        postR.fillColor = .white
        postR.position = CGPoint(x: size.width/2 + goalWidth/2, y: goalY)
        postR.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        postR.physicsBody?.isDynamic = false
        postR.physicsBody?.categoryBitMask = borderCategory
        postR.physicsBody?.collisionBitMask = ballCategory
        addChild(postR)
    }
    
    func setupKeeper() {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let keeper = SKSpriteNode(imageNamed: "GoalKeeper")
        
        let targetWidth: CGFloat = isIPad ? 300 : 200
        let originalW = max(keeper.size.width, 1)
        let scale = targetWidth / originalW
        keeper.size = CGSize(width: targetWidth, height: keeper.size.height * scale)
        
        let keeperBaseY = size.height * 0.58 // Keep keeper at original height
        keeper.position = CGPoint(x: size.width/2, y: keeperBaseY + 10)
        
        let physicsWidth: CGFloat = isIPad ? 240 : 160
        let physicsHeight: CGFloat = isIPad ? 120 : 80
        keeper.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: physicsWidth, height: physicsHeight))
        keeper.physicsBody?.isDynamic = false
        keeper.physicsBody?.categoryBitMask = keeperCategory
        keeper.physicsBody?.contactTestBitMask = ballCategory
        keeper.physicsBody?.collisionBitMask = ballCategory 
        
        addChild(keeper)
        self.goalkeeper = keeper 
        
        moveKeeperRandomly()
    }
    
    func moveKeeperRandomly() {
        guard let keeper = goalkeeper else { return }
        
        let range = size.width * 0.6
        let minX = size.width/2 - range/2
        let maxX = size.width/2 + range/2
        
        // Pick a random target X within the goal area
        let randomX = CGFloat.random(in: minX...maxX)
        
        let distance = abs(keeper.position.x - randomX)
        let duration = max(0.2, Double((distance / range) * 1.0))
        
        let move = SKAction.move(to: CGPoint(x: randomX, y: keeper.position.y), duration: duration)
        move.timingMode = .easeInEaseOut
        
        // Overwrite existing movement for erratic direction changes
        keeper.run(move, withKey: "keeperMove")
        
        // Don't wait for the movement to finish! Change mind randomly.
        let nextDecisionTime = TimeInterval.random(in: 0.2...0.6)
        
        let wait = SKAction.wait(forDuration: nextDecisionTime)
        let nextMove = SKAction.run { [weak self] in
            self?.moveKeeperRandomly()
        }
        
        keeper.run(SKAction.sequence([wait, nextMove]), withKey: "keeperDecision")
    }
    
    func spawnBall() {
        ball?.removeFromParent()
        isBallMoving = false
        
        let b = SKSpriteNode(imageNamed: "ball")
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let ballDiameter: CGFloat = isPad ? 100 : 40 // +150% size for iPad
        b.size = CGSize(width: ballDiameter, height: ballDiameter)
        b.position = CGPoint(x: size.width/2, y: size.height * 0.28) // Raised ball so it's above text
        
        b.physicsBody = SKPhysicsBody(circleOfRadius: ballDiameter / 2) // Matching physical radius
        b.physicsBody?.isDynamic = true
        b.physicsBody?.mass = 0.5
        b.physicsBody?.linearDamping = 0.5
        b.physicsBody?.restitution = 0.7
        b.physicsBody?.categoryBitMask = ballCategory
        b.physicsBody?.contactTestBitMask = goalLineCategory | keeperCategory
        b.physicsBody?.collisionBitMask = keeperCategory | borderCategory
        
        addChild(b)
        self.ball = b
        
        // Ensure ball is drawn on top
        b.zPosition = 10
    }
    
    // Touch Input
    private var touchStart: CGPoint = .zero
    private var isDragging = false
    private var trajectoryLine: SKShapeNode?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBallMoving, let t = touches.first, let ball = ball else { return }
        let location = t.location(in: self)
        
        // Manual distance check since CGPoint distance() doesn't exist
        let dx = location.x - ball.position.x
        let dy = location.y - ball.position.y
        let dist = sqrt(dx*dx + dy*dy)
        
        // Check if touch is near ball
        if ball.contains(location) || dist < 40 {
            isDragging = true
            touchStart = location
            
            // Create Trajectory Line
            let line = SKShapeNode()
            line.strokeColor = .white
            line.lineWidth = 3
            addChild(line)
            self.trajectoryLine = line
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let t = touches.first, let ball = ball else { return }
        let location = t.location(in: self)
        
        // Limit drag distance
        let maxDrag: CGFloat = 150
        var dx = location.x - touchStart.x
        var dy = location.y - touchStart.y
        let dist = sqrt(dx*dx + dy*dy)
        
        if dist > maxDrag {
            let ratio = maxDrag / dist
            dx *= ratio
            dy *= ratio
        }
        
        let aimVector = CGVector(dx: touchStart.x - location.x, dy: touchStart.y - location.y)
        
        // Create Dashed Path manually
        let path = CGMutablePath()
        let start = ball.position
        let end = CGPoint(x: ball.position.x + aimVector.dx, y: ball.position.y + aimVector.dy)
        
        path.move(to: start)
        path.addLine(to: end)
        
        // "Dashed" line using built-in path copy pattern
        let dashPattern: [CGFloat] = [5.0, 5.0]
        let dashedPath = path.copy(dashingWithPhase: 0, lengths: dashPattern)
        
        trajectoryLine?.path = dashedPath
        
        // Color based on power
        let strength = min(dist / maxDrag, 1.0)
        trajectoryLine?.strokeColor = UIColor(hue: 0.3 - (strength * 0.3), saturation: 1, brightness: 1, alpha: 1) // Green to Red
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let t = touches.first else { return }
        isDragging = false
        trajectoryLine?.removeFromParent()
        
        let location = t.location(in: self)
        
        // Calculate Impulse (Start - End)
        let dx = touchStart.x - location.x
        let dy = touchStart.y - location.y
        
        // Only allow shooting generally upwards
        if dy > 0 { 
            shootBall(dx: dx, dy: dy)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        trajectoryLine?.removeFromParent()
    }
    
    func shootBall(dx: CGFloat, dy: CGFloat) {
        isBallMoving = true
        
        // Apply Impulse
        let multiplier: CGFloat = 4.0 // Reduced power by 50%
        let vector = CGVector(dx: dx * multiplier, dy: dy * multiplier)
        
        // Cap max force
        let maxF: CGFloat = 600 // Reduced max force by 50%
        let fx = max(min(vector.dx, maxF), -maxF)
        let fy = max(min(vector.dy, maxF), 0)
        
        ball?.physicsBody?.applyImpulse(CGVector(dx: fx, dy: fy))
        
        // Auto reset if missed (timeout)
        let wait = SKAction.wait(forDuration: 3.0)
        let checkMiss = SKAction.run { [weak self] in
            if self?.ball?.parent != nil {
                 self?.handleMiss(text: "") // Removed "MISSED!" text
            }
        }
        run(SKAction.sequence([wait, checkMiss]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if mask == (ballCategory | goalLineCategory) {
            handleGoal()
        } else if mask == (ballCategory | keeperCategory) {
            handleMiss(text: NSLocalizedString("BLOCKED!", comment: ""))
        }
    }
    
    func handleGoal() {
        guard isBallMoving else { return }
        isBallMoving = false // Prevent back-to-back triggers (Goal then Block, or Block then Goal)
        // Prevent double counting
        ball?.physicsBody?.categoryBitMask = 0
        
        ball?.removeFromParent()
        onGoal?()
        showFlashText(NSLocalizedString("GOAL!!!", comment: ""), color: UIColor(red: 0.9, green: 0.8, blue: 0.4, alpha: 1.0))
        
        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            self?.spawnBall()
        }
    }
    
    func handleMiss(text: String) {
        guard isBallMoving else { return }
        isBallMoving = false // Prevent back-to-back triggers
        
        // Prevent double triggering
        // Just invalidate the ball logic for this round
        // Let it bounce but don't count goal if it trickles in after block (optional rule)
        // Usually if blocked, it's a miss.
        
        // If we want instant reset on block:
        onMiss?()
        if !text.isEmpty {
            showFlashText(text, color: .red) // Only show if there's text (BLOCKED)
        }
        
        // Disable ball goal detection immediately
        ball?.physicsBody?.contactTestBitMask = 0
        
        // Wait and reset
        run(SKAction.wait(forDuration: 1.5)) { [weak self] in
            self?.spawnBall()
        }
    }
    
    func showFlashText(_ text: String, color: UIColor) {
        let label = SKLabelNode(text: text)
        label.fontSize = 55 // Much larger font
        label.fontName = "AvenirNext-HeavyItalic" // Dynamic sporty font
        label.fontColor = color
        label.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        label.zPosition = 100
        
        // Add a dark drop shadow for better contrast against the stadium background
        let shadow = SKLabelNode(text: text)
        shadow.fontSize = label.fontSize
        shadow.fontName = label.fontName
        shadow.fontColor = .black
        shadow.position = CGPoint(x: 3, y: -3)
        shadow.zPosition = -1
        shadow.alpha = 0.7
        label.addChild(shadow)
        
        addChild(label)
        
        // Springy, exciting animation
        label.setScale(0.1)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.2),
                SKAction.fadeIn(withDuration: 0.2)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.8),
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
