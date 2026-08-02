//
//  GameScene.swift
//  Space Apocalypse
//
//  Created by Elliot Williams on 2025-06-22.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Game State
    enum GameState {
        case intro
        case playing
        case gameOver
    }
    var currentState: GameState = .intro
    
    // MARK: - Game Elements
    var player: SKSpriteNode!
    var laser: SKSpriteNode!
    var stars = [SKSpriteNode]()
    var aliens = [SKSpriteNode]()
    var asteroids = [SKSpriteNode]()
    
    // MARK: - Game Variables
    var score = 0
    var level = 1
    var highScore = 0
    var highestLevel = 1
    var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Physics Categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let player: UInt32 = 0b1
        static let laser: UInt32 = 0b10
        static let alien: UInt32 = 0b100
        static let asteroid: UInt32 = 0b1000
    }
    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        backgroundColor = .black
        
        createStars()
        createPlayer()
        createUI()
        preloadAssets()
    }
    
    func createStars() {
        for _ in 0..<550 {
            let star = SKSpriteNode(color: .white, size: CGSize(width: 2, height: 2))
            star.position = CGPoint(
                x: CGFloat.random(in: 0..<size.width),
                y: CGFloat.random(in: 0..<size.height)
            )
            star.zPosition = -1
            addChild(star)
            stars.append(star)
        }
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "spaceship")
        player.position = CGPoint(x: size.width/2, y: 100)
        player.zPosition = 10
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.isDynamic = false
        addChild(player)
        
        laser = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 30))
        laser.position = player.position
        laser.zPosition = 5
        laser.isHidden = true
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.alien
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(laser)
    }
    
    func createAlien() {
        let alien = SKSpriteNode(imageNamed: "alien")
        alien.position = CGPoint(
            x: CGFloat.random(in: 50..<size.width-50),
            y: size.height + 50
        )
        alien.zPosition = 1
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.categoryBitMask = PhysicsCategory.alien
        alien.physicsBody?.contactTestBitMask = PhysicsCategory.laser
        alien.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(alien)
        aliens.append(alien)
        
        // Movement
        let moveAction = SKAction.moveTo(y: -100, duration: TimeInterval.random(in: 3...8))
        alien.run(moveAction) {
            alien.removeFromParent()
            if let index = self.aliens.firstIndex(of: alien) {
                self.aliens.remove(at: index)
            }
        }
    }
    
    func createAsteroid(type: Int) {
        let asteroid = SKSpriteNode(imageNamed: "asteroid\(type)")
        asteroid.position = CGPoint(
            x: CGFloat.random(in: 0..<size.width),
            y: CGFloat.random(in: 0..<size.height)
        )
        asteroid.zPosition = 0
        addChild(asteroid)
        asteroids.append(asteroid)
        
        // Bouncing movement
        let xMove = SKAction.moveBy(x: CGFloat.random(in: -200...200), y: 0, duration: 2)
        let yMove = SKAction.moveBy(x: 0, y: CGFloat.random(in: -200...200), duration: 2)
        let sequence = SKAction.sequence([xMove, yMove])
        asteroid.run(SKAction.repeatForever(sequence))
    }
    
    func createUI() {
        // Score label setup would go here
    }
    
    func preloadAssets() {
        // Preload textures for better performance
        _ = SKTexture(imageNamed: "spaceship")
        _ = SKTexture(imageNamed: "alien")
        for i in 0..<3 {
            _ = SKTexture(imageNamed: "asteroid\(i)")
        }
    }
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        guard currentState == .playing else { return }
        
        // Move stars
        for star in stars {
            star.position.y -= 1
            if star.position.y < 0 {
                star.position.y = size.height
            }
        }
        
        // Spawn aliens
        if aliens.count < 19 && Int.random(in: 0...100) < 5 {
            createAlien()
        }
        
        // Move laser
        if !laser.isHidden {
            laser.position.y += 20
            if laser.position.y > size.height {
                resetLaser()
            }
        }
    }
    
    // MARK: - Input Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch currentState {
        case .intro:
            startGame()
        case .playing:
            fireLaser()
        case .gameOver:
            resetGame()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        player.position.x = location.x
    }
    
    // MARK: - Game Actions
    func fireLaser() {
        guard laser.isHidden else { return }
        
        laser.isHidden = false
        laser.position = CGPoint(
            x: player.position.x,
            y: player.position.y + 50
        )
        
        run(SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false))
    }
    
    func resetLaser() {
        laser.isHidden = true
        laser.position = player.position
    }
    
    func startGame() {
        currentState = .playing
        score = 0
        level = 1
        
        // Clear existing aliens
        aliens.forEach { $0.removeFromParent() }
        aliens.removeAll()
    }
    
    func resetGame() {
        currentState = .intro
        // Reset game state
    }
    
    func gameOver() {
        currentState = .gameOver
        if score > highScore {
            highScore = score
            highestLevel = level
        }
    }
    
    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Laser hits alien
        if collision == PhysicsCategory.laser | PhysicsCategory.alien {
            if contact.bodyA.categoryBitMask == PhysicsCategory.laser {
                alienHit(laser: contact.bodyA.node as! SKSpriteNode, alien: contact.bodyB.node as! SKSpriteNode)
            } else {
                alienHit(laser: contact.bodyB.node as! SKSpriteNode, alien: contact.bodyA.node as! SKSpriteNode)
            }
        }
    }
    
    func alienHit(laser: SKSpriteNode, alien: SKSpriteNode) {
        run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        
        alien.removeFromParent()
        if let index = aliens.firstIndex(of: alien) {
            aliens.remove(at: index)
        }
        
        resetLaser()
        score += 3
        
        // Create new alien
        createAlien()
    }
}
