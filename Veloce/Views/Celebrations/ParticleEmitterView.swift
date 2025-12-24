//
//  ParticleEmitterView.swift
//  Veloce
//
//  Particle Effects for Celebrations
//  SpriteKit-powered cosmic particle system for task completion celebrations
//

import SwiftUI
import SpriteKit

// MARK: - Particle Effect Type

enum ParticleEffectType {
    case stellarBurst      // Quick task - radial star particles
    case cosmicRing        // Normal task - ring expansion
    case confetti          // Important task - falling confetti
    case supernova         // Milestone - full screen explosion
    case aurora            // Streak continuation - flowing aurora
    case xpTrail           // XP floating up with particle trail

    var particleTexture: String {
        switch self {
        case .stellarBurst: return "spark"
        case .cosmicRing: return "star"
        case .confetti: return "confetti"
        case .supernova: return "glow"
        case .aurora: return "aurora_particle"
        case .xpTrail: return "star"
        }
    }
}

// MARK: - Celebration Particle Scene

final class CelebrationParticleScene: SKScene {

    // MARK: Properties
    private var effectType: ParticleEffectType = .stellarBurst
    private var effectPosition: CGPoint = .zero
    private var particleCount: Int = 30
    private var colors: [UIColor] = []

    // MARK: Configuration
    func configure(
        type: ParticleEffectType,
        position: CGPoint,
        particleCount: Int = 30,
        colors: [Color]? = nil
    ) {
        self.effectType = type
        self.effectPosition = position
        self.particleCount = particleCount
        self.colors = (colors ?? Theme.Celebration.confettiColors).map { UIColor($0) }
    }

    // MARK: Setup
    override func didMove(to view: SKView) {
        backgroundColor = .clear

        switch effectType {
        case .stellarBurst:
            createStellarBurst()
        case .cosmicRing:
            createCosmicRing()
        case .confetti:
            createConfetti()
        case .supernova:
            createSupernova()
        case .aurora:
            createAurora()
        case .xpTrail:
            createXPTrail()
        }
    }

    // MARK: - Stellar Burst Effect

    private func createStellarBurst() {
        let position = CGPoint(x: effectPosition.x, y: size.height - effectPosition.y)

        for i in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = colors.randomElement() ?? .white
            particle.strokeColor = .clear
            particle.position = position
            particle.alpha = 1.0
            particle.zPosition = 1

            // Add glow
            particle.glowWidth = 3

            addChild(particle)

            // Calculate radial direction
            let angle = CGFloat(i) / CGFloat(particleCount) * .pi * 2
            let distance = CGFloat.random(in: 60...120)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            // Animate outward with fade
            let moveAction = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.5)
            moveAction.timingMode = .easeOut

            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let scaleAction = SKAction.scale(to: 0.3, duration: 0.5)

            let group = SKAction.group([moveAction, fadeAction, scaleAction])
            let remove = SKAction.removeFromParent()

            // Stagger start time slightly
            let wait = SKAction.wait(forDuration: Double(i) * 0.01)
            particle.run(SKAction.sequence([wait, group, remove]))
        }
    }

    // MARK: - Cosmic Ring Effect

    private func createCosmicRing() {
        let position = CGPoint(x: effectPosition.x, y: size.height - effectPosition.y)

        // Create expanding ring
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = UIColor(Theme.Celebration.plasmaCore)
        ring.lineWidth = 3
        ring.fillColor = .clear
        ring.position = position
        ring.alpha = 1.0
        ring.glowWidth = 5
        addChild(ring)

        // Expand and fade
        let expand = SKAction.scale(to: 8, duration: 0.6)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.6)
        let group = SKAction.group([expand, fade])
        ring.run(SKAction.sequence([group, .removeFromParent()]))

        // Add particle burst
        for i in 0..<particleCount {
            let particle = createGlowParticle(size: 3)
            particle.position = position
            addChild(particle)

            let angle = CGFloat(i) / CGFloat(particleCount) * .pi * 2
            let distance = CGFloat.random(in: 80...150)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let delay = SKAction.wait(forDuration: 0.1)
            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let scale = SKAction.scale(to: 0.2, duration: 0.5)

            let group = SKAction.group([move, fade, scale])
            particle.run(SKAction.sequence([delay, group, .removeFromParent()]))
        }
    }

    // MARK: - Confetti Effect

    private func createConfetti() {
        for _ in 0..<particleCount {
            let confetti = createConfettiPiece()
            let startX = CGFloat.random(in: 0...size.width)
            confetti.position = CGPoint(x: startX, y: size.height + 20)
            addChild(confetti)

            // Fall with physics-like motion
            let fallDuration = Double.random(in: 2.0...3.5)
            let horizontalDrift = CGFloat.random(in: -100...100)

            let fall = SKAction.moveTo(y: -50, duration: fallDuration)
            fall.timingMode = .easeIn

            let drift = SKAction.moveBy(x: horizontalDrift, y: 0, duration: fallDuration)

            // Rotation
            let rotationSpeed = CGFloat.random(in: -4...4)
            let rotate = SKAction.rotate(byAngle: rotationSpeed, duration: fallDuration)

            // Slight tumble effect
            let tumble = SKAction.sequence([
                SKAction.scaleX(to: 0.3, duration: 0.2),
                SKAction.scaleX(to: 1.0, duration: 0.2)
            ])
            let tumbleRepeat = SKAction.repeat(tumble, count: Int(fallDuration / 0.4))

            let group = SKAction.group([fall, drift, rotate, tumbleRepeat])
            confetti.run(SKAction.sequence([group, .removeFromParent()]))
        }
    }

    private func createConfettiPiece() -> SKNode {
        let shapes: [SKNode] = [
            createRectangleConfetti(),
            createCircleConfetti(),
            createStarConfetti()
        ]
        return shapes.randomElement()!
    }

    private func createRectangleConfetti() -> SKShapeNode {
        let rect = SKShapeNode(rectOf: CGSize(width: 8, height: 12), cornerRadius: 2)
        rect.fillColor = colors.randomElement() ?? .white
        rect.strokeColor = .clear
        return rect
    }

    private func createCircleConfetti() -> SKShapeNode {
        let circle = SKShapeNode(circleOfRadius: 5)
        circle.fillColor = colors.randomElement() ?? .white
        circle.strokeColor = .clear
        return circle
    }

    private func createStarConfetti() -> SKShapeNode {
        let star = SKShapeNode(circleOfRadius: 4)
        star.fillColor = UIColor(Theme.Celebration.starGold)
        star.strokeColor = .clear
        star.glowWidth = 3
        return star
    }

    // MARK: - Supernova Effect

    private func createSupernova() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Central flash
        let flash = SKShapeNode(circleOfRadius: 20)
        flash.fillColor = UIColor(Theme.Celebration.supernovaWhite)
        flash.strokeColor = .clear
        flash.glowWidth = 30
        flash.position = center
        flash.alpha = 0
        flash.setScale(0.1)
        addChild(flash)

        // Flash animation
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.5, duration: 0.1)
        ])
        let hold = SKAction.wait(forDuration: 0.1)
        let expand = SKAction.group([
            SKAction.scale(to: 20, duration: 0.4),
            SKAction.fadeOut(withDuration: 0.4)
        ])
        flash.run(SKAction.sequence([appear, hold, expand, .removeFromParent()]))

        // Particle explosion (multiple waves)
        createSupernovaWave(center: center, delay: 0, count: particleCount / 3, distance: 100...200)
        createSupernovaWave(center: center, delay: 0.1, count: particleCount / 3, distance: 150...300)
        createSupernovaWave(center: center, delay: 0.2, count: particleCount / 3, distance: 200...400)

        // Secondary ring waves
        for i in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: 20)
            ring.strokeColor = colors.randomElement() ?? UIColor(Theme.Celebration.plasmaCore)
            ring.lineWidth = 2
            ring.fillColor = .clear
            ring.position = center
            ring.alpha = 0.8
            ring.glowWidth = 8
            addChild(ring)

            let delay = SKAction.wait(forDuration: Double(i) * 0.15)
            let expand = SKAction.scale(to: 15, duration: 0.8)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.8)

            ring.run(SKAction.sequence([delay, .group([expand, fade]), .removeFromParent()]))
        }
    }

    private func createSupernovaWave(
        center: CGPoint,
        delay: Double,
        count: Int,
        distance: ClosedRange<CGFloat>
    ) {
        for i in 0..<count {
            let particle = createGlowParticle(size: CGFloat.random(in: 3...6))
            particle.position = center
            particle.alpha = 0
            addChild(particle)

            let angle = CGFloat(i) / CGFloat(count) * .pi * 2 + CGFloat.random(in: -0.2...0.2)
            let dist = CGFloat.random(in: distance)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist

            let waitAction = SKAction.wait(forDuration: delay)
            let appear = SKAction.fadeIn(withDuration: 0.05)
            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.7)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 0.2, duration: 0.7)

            let group = SKAction.group([move, fade, scale])
            particle.run(SKAction.sequence([waitAction, appear, group, .removeFromParent()]))
        }
    }

    // MARK: - Aurora Effect

    private func createAurora() {
        let position = CGPoint(x: effectPosition.x, y: size.height - effectPosition.y)

        for _ in 0..<(particleCount / 2) {
            let particle = createGlowParticle(size: CGFloat.random(in: 2...4))
            particle.position = position
            particle.fillColor = UIColor(Theme.Celebration.auroraGreen).withAlphaComponent(0.8)
            addChild(particle)

            // Flowing upward motion with wave
            let duration = Double.random(in: 1.0...2.0)
            let path = CGMutablePath()
            path.move(to: position)

            let amplitude = CGFloat.random(in: 20...40)
            let steps = 20
            for i in 1...steps {
                let progress = CGFloat(i) / CGFloat(steps)
                let x = position.x + sin(progress * .pi * 2) * amplitude
                let y = position.y + progress * 150
                path.addLine(to: CGPoint(x: x, y: y))
            }

            let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration)
            let group = SKAction.group([follow, fade])

            particle.run(SKAction.sequence([group, .removeFromParent()]))
        }
    }

    // MARK: - XP Trail Effect

    private func createXPTrail() {
        let startPosition = CGPoint(x: effectPosition.x, y: size.height - effectPosition.y)

        // Main XP particles rising
        for i in 0..<10 {
            let particle = createGlowParticle(size: 3)
            particle.position = startPosition
            particle.fillColor = UIColor(Theme.Celebration.starGold)
            addChild(particle)

            let delay = Double(i) * 0.03
            let duration = 0.8

            // Slight random offset
            let offset = CGFloat.random(in: -15...15)
            let riseDistance: CGFloat = 100 + CGFloat(i) * 5

            let wait = SKAction.wait(forDuration: delay)
            let move = SKAction.moveBy(x: offset, y: riseDistance, duration: duration)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: duration * 0.7)
            let scale = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: duration * 0.3),
                SKAction.scale(to: 0.3, duration: duration * 0.7)
            ])

            let group = SKAction.group([move, fade, scale])
            particle.run(SKAction.sequence([wait, group, .removeFromParent()]))
        }
    }

    // MARK: - Helpers

    private func createGlowParticle(size: CGFloat) -> SKShapeNode {
        let particle = SKShapeNode(circleOfRadius: size)
        particle.fillColor = colors.randomElement() ?? .white
        particle.strokeColor = .clear
        particle.glowWidth = size
        return particle
    }
}

// MARK: - SwiftUI Wrapper

struct ParticleEmitterView: View {
    let effectType: ParticleEffectType
    let position: CGPoint
    let particleCount: Int
    let colors: [Color]?

    init(
        type: ParticleEffectType,
        at position: CGPoint,
        particleCount: Int = 30,
        colors: [Color]? = nil
    ) {
        self.effectType = type
        self.position = position
        self.particleCount = particleCount
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            SpriteView(
                scene: createScene(size: geometry.size),
                options: [.allowsTransparency]
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private func createScene(size: CGSize) -> CelebrationParticleScene {
        let scene = CelebrationParticleScene()
        scene.size = size
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.configure(
            type: effectType,
            position: position,
            particleCount: particleCount,
            colors: colors
        )
        return scene
    }
}

// MARK: - Celebration Particle Overlay

struct CelebrationParticleOverlay: View {
    let event: CelebrationEvent?
    @State private var showParticles = false

    var body: some View {
        ZStack {
            if let event = event, showParticles {
                ParticleEmitterView(
                    type: effectTypeFor(event.level),
                    at: event.position,
                    particleCount: adjustedParticleCount(for: event.level)
                )
                .transition(.opacity)
            }
        }
        .onChange(of: event?.id) { _, newValue in
            if newValue != nil {
                showParticles = true

                // Auto-hide after animation
                Task {
                    try? await Task.sleep(for: .seconds(event?.level.duration ?? 1.0))
                    withAnimation(.easeOut(duration: 0.3)) {
                        showParticles = false
                    }
                }
            }
        }
    }

    private func effectTypeFor(_ level: CelebrationLevel) -> ParticleEffectType {
        switch level {
        case .quick: return .stellarBurst
        case .normal: return .cosmicRing
        case .important: return .confetti
        case .milestone: return .supernova
        }
    }

    private func adjustedParticleCount(for level: CelebrationLevel) -> Int {
        // Respect reduce motion
        if UIAccessibility.isReduceMotionEnabled {
            return level.particleCount / 3
        }
        return level.particleCount
    }
}

// MARK: - Preview

#Preview("Particle Effects") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Button("Stellar Burst") {}
            Button("Cosmic Ring") {}
            Button("Confetti") {}
            Button("Supernova") {}
        }
        .foregroundColor(.white)

        // Demo particle effect
        ParticleEmitterView(
            type: .supernova,
            at: CGPoint(x: 200, y: 400),
            particleCount: 100
        )
    }
}
