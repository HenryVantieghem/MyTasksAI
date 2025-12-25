//
//  CosmicParticles.swift
//  Veloce
//
//  Living Cosmos Particle Systems
//  Supernova bursts, AI sparkles, urgency embers, focus shields
//

import SwiftUI
import Combine

// MARK: - Cosmic Particle System

/// Base particle structure for all cosmic effects
struct CosmicParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGSize
    var size: CGFloat
    var color: Color
    var opacity: Double
    var rotation: Double
    var scale: CGFloat
    var lifetime: Double
    var age: Double = 0
}

// MARK: - Particle Emitter

/// Generic particle emitter for creating various cosmic effects
class ParticleEmitter: ObservableObject {
    @Published var particles: [CosmicParticle] = []

    private var timer: Timer?
    private let maxParticles: Int

    init(maxParticles: Int = 50) {
        self.maxParticles = maxParticles
    }

    func start(interval: TimeInterval = 0.1) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func emit(particle: CosmicParticle) {
        guard particles.count < maxParticles else { return }
        particles.append(particle)
    }

    func emitBurst(count: Int, at position: CGPoint, generator: (CGPoint) -> CosmicParticle) {
        for _ in 0..<count {
            let particle = generator(position)
            particles.append(particle)
        }
    }

    private func update() {
        particles = particles.compactMap { particle in
            var p = particle
            p.age += 0.016

            // Remove expired particles
            if p.age >= p.lifetime {
                return nil
            }

            // Update position
            p.position.x += p.velocity.width
            p.position.y += p.velocity.height

            // Fade out near end of life
            let lifeProgress = p.age / p.lifetime
            if lifeProgress > 0.7 {
                p.opacity = p.opacity * (1 - (lifeProgress - 0.7) / 0.3)
            }

            return p
        }
    }
}

// MARK: - Supernova Particle Burst

/// Explosive particle burst for task completion celebrations
struct SupernovaParticleBurst: View {
    let centerPosition: CGPoint
    let colors: [Color]
    let particleCount: Int
    let onComplete: (() -> Void)?

    @State private var particles: [CosmicParticle] = []
    @State private var centralFlash: CGFloat = 0
    @State private var hasTriggered = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        at position: CGPoint,
        colors: [Color] = [
            .white,
            Theme.CelestialColors.auroraGreen,
            Theme.CelestialColors.plasmaCore,
            Theme.CelestialColors.solarFlare
        ],
        particleCount: Int = 32,
        onComplete: (() -> Void)? = nil
    ) {
        self.centerPosition = position
        self.colors = colors
        self.particleCount = particleCount
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Central flash
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            colors.first?.opacity(0.8) ?? .white.opacity(0.8),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .position(centerPosition)
                .scaleEffect(centralFlash)
                .opacity(Double(centralFlash) * 0.8)

            // Particles
            ForEach(particles) { particle in
                particleView(particle)
            }
        }
        .onAppear {
            if !hasTriggered {
                triggerBurst()
            }
        }
    }

    private func particleView(_ particle: CosmicParticle) -> some View {
        Group {
            if particle.size > 4 {
                // Larger particles are stars
                Image(systemName: "star.fill")
                    .font(.system(size: particle.size))
                    .foregroundStyle(particle.color)
            } else {
                // Small particles are circles
                SwiftUI.Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
        .position(particle.position)
        .opacity(particle.opacity)
        .rotationEffect(.degrees(particle.rotation))
        .scaleEffect(particle.scale)
        .blur(radius: particle.size > 3 ? 0 : 0.5)
    }

    private func triggerBurst() {
        guard !reduceMotion else {
            onComplete?()
            return
        }

        hasTriggered = true

        // Central flash
        withAnimation(.easeOut(duration: 0.3)) {
            centralFlash = 2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                centralFlash = 0
            }
        }

        // Generate particles
        for i in 0..<particleCount {
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi + Double.random(in: -0.2...0.2)
            let speed = CGFloat.random(in: 3...8)
            let distance = CGFloat.random(in: 60...150)

            let particle = CosmicParticle(
                id: UUID(),
                position: centerPosition,
                velocity: CGSize(
                    width: CGFloat(Darwin.cos(angle)) * speed,
                    height: CGFloat(Darwin.sin(angle)) * speed
                ),
                size: CGFloat.random(in: 2...6),
                color: colors.randomElement() ?? .white,
                opacity: 1,
                rotation: Double.random(in: 0...360),
                scale: 1,
                lifetime: Double.random(in: 0.6...1.2)
            )

            particles.append(particle)

            // Animate particle outward
            let targetPosition = CGPoint(
                x: centerPosition.x + CGFloat(Darwin.cos(angle)) * distance,
                y: centerPosition.y + CGFloat(Darwin.sin(angle)) * distance
            )

            withAnimation(.easeOut(duration: particle.lifetime)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].position = targetPosition
                    particles[index].opacity = 0
                    particles[index].scale = 0.3
                    particles[index].rotation += Double.random(in: 180...360)
                }
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particles.removeAll()
            onComplete?()
        }
    }
}

// MARK: - AI Sparkle Field

/// Gentle floating sparkles for AI-enhanced content
struct AISparkleField: View {
    let bounds: CGSize
    let density: SparkeDensity
    let primaryColor: Color

    enum SparkeDensity {
        case light, medium, heavy

        var count: Int {
            switch self {
            case .light: return 6
            case .medium: return 12
            case .heavy: return 20
            }
        }
    }

    @State private var sparkles: [Sparkle] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Sparkle: Identifiable {
        let id: UUID
        var position: CGPoint
        let size: CGFloat
        let color: Color
        var opacity: Double
        let floatOffset: CGFloat
        let floatDuration: Double
    }

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                sparkleView(sparkle)
            }
        }
        .onAppear {
            generateSparkles()
        }
    }

    private func sparkleView(_ sparkle: Sparkle) -> some View {
        ZStack {
            // Glow
            SwiftUI.Circle()
                .fill(sparkle.color.opacity(0.4))
                .frame(width: sparkle.size * 2, height: sparkle.size * 2)
                .blur(radius: sparkle.size)

            // Core
            SwiftUI.Circle()
                .fill(sparkle.color)
                .frame(width: sparkle.size, height: sparkle.size)
        }
        .position(sparkle.position)
        .opacity(sparkle.opacity)
        .modifier(FloatModifier(
            offset: sparkle.floatOffset,
            duration: sparkle.floatDuration
        ))
    }

    private func generateSparkles() {
        guard !reduceMotion else { return }

        let colors: [Color] = [
            .white.opacity(0.8),
            primaryColor.opacity(0.6),
            Theme.CelestialColors.nebulaEdge.opacity(0.5),
            Theme.CelestialColors.plasmaCore.opacity(0.4)
        ]

        for i in 0..<density.count {
            let sparkle = Sparkle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                ),
                size: CGFloat.random(in: 2...4),
                color: colors.randomElement() ?? .white,
                opacity: 0,
                floatOffset: CGFloat.random(in: 3...8),
                floatDuration: Double.random(in: 2...4)
            )
            sparkles.append(sparkle)

            // Staggered fade in
            let delay = Double(i) * 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    if let index = sparkles.firstIndex(where: { $0.id == sparkle.id }) {
                        sparkles[index].opacity = Double.random(in: 0.4...0.9)
                    }
                }
            }
        }
    }
}

// MARK: - Float Modifier

struct FloatModifier: ViewModifier {
    let offset: CGFloat
    let duration: Double

    @State private var isFloating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -offset : offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating = true
                }
            }
    }
}

// MARK: - Urgency Embers

/// Warm pulsing particles for overdue/urgent tasks
struct UrgencyEmbers: View {
    let bounds: CGSize
    let intensity: Double  // 0-1, affects count and brightness

    @State private var embers: [Ember] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Ember: Identifiable {
        let id: UUID
        var position: CGPoint
        let size: CGFloat
        var opacity: Double
        let riseSpeed: CGFloat
        let swayAmount: CGFloat
        let swaySpeed: Double
    }

    private var emberCount: Int {
        Int(5 + (intensity * 10))
    }

    var body: some View {
        ZStack {
            ForEach(embers) { ember in
                emberView(ember)
            }
        }
        .onAppear {
            if !reduceMotion {
                generateEmbers()
            }
        }
    }

    private func emberView(_ ember: Ember) -> some View {
        ZStack {
            // Glow
            SwiftUI.Circle()
                .fill(Theme.CelestialColors.urgencyCritical.opacity(0.5))
                .frame(width: ember.size * 3, height: ember.size * 3)
                .blur(radius: ember.size * 2)

            // Core
            SwiftUI.Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.CelestialColors.solarFlare,
                            Theme.CelestialColors.urgencyCritical,
                            Theme.CelestialColors.urgencyCritical.opacity(0.5)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: ember.size
                    )
                )
                .frame(width: ember.size, height: ember.size)
        }
        .position(ember.position)
        .opacity(ember.opacity)
        .modifier(EmberRiseModifier(
            bounds: bounds,
            riseSpeed: ember.riseSpeed,
            swayAmount: ember.swayAmount,
            swaySpeed: ember.swaySpeed
        ))
    }

    private func generateEmbers() {
        for i in 0..<emberCount {
            let ember = Ember(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: bounds.height + CGFloat.random(in: 0...50)
                ),
                size: CGFloat.random(in: 2...5),
                opacity: 0,
                riseSpeed: CGFloat.random(in: 0.5...1.5),
                swayAmount: CGFloat.random(in: 5...15),
                swaySpeed: Double.random(in: 1...2)
            )
            embers.append(ember)

            // Staggered fade in
            let delay = Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: 0.5)) {
                    if let index = embers.firstIndex(where: { $0.id == ember.id }) {
                        embers[index].opacity = Double.random(in: 0.5...0.9) * intensity
                    }
                }
            }
        }
    }
}

// MARK: - Ember Rise Modifier

struct EmberRiseModifier: ViewModifier {
    let bounds: CGSize
    let riseSpeed: CGFloat
    let swayAmount: CGFloat
    let swaySpeed: Double

    @State private var offset: CGFloat = 0
    @State private var sway: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: sway, y: -offset)
            .onAppear {
                // Rise animation
                withAnimation(
                    .linear(duration: Double(bounds.height / riseSpeed / 60))
                    .repeatForever(autoreverses: false)
                ) {
                    offset = bounds.height + 100
                }

                // Sway animation
                withAnimation(
                    .easeInOut(duration: swaySpeed)
                    .repeatForever(autoreverses: true)
                ) {
                    sway = swayAmount
                }
            }
    }
}

// MARK: - Focus Shield Particles

/// Orbiting particles forming a protective ring during focus mode
struct FocusShieldParticles: View {
    let radius: CGFloat
    let particleCount: Int
    let isActive: Bool

    @State private var rotationAngle: Double = 0
    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Shield ring glow
            SwiftUI.Circle()
                .stroke(
                    Theme.CelestialColors.nebulaEdge.opacity(0.3),
                    lineWidth: 2 + (pulsePhase * 2)
                )
                .frame(width: radius * 2, height: radius * 2)
                .blur(radius: 4 + (pulsePhase * 2))

            // Orbiting particles
            ForEach(0..<particleCount, id: \.self) { i in
                shieldParticle(index: i)
            }
        }
        .opacity(isActive ? 1 : 0)
        .animation(Theme.Animation.portalOpen, value: isActive)
        .onAppear {
            if !reduceMotion && isActive {
                startAnimations()
            }
        }
        .onChange(of: isActive) { _, active in
            if active && !reduceMotion {
                startAnimations()
            }
        }
    }

    private func shieldParticle(index: Int) -> some View {
        let angle = (Double(index) / Double(particleCount)) * 2 * .pi + rotationAngle

        return SwiftUI.Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Theme.CelestialColors.plasmaCore,
                        Theme.CelestialColors.nebulaEdge.opacity(0.5),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 6
                )
            )
            .frame(width: 8, height: 8)
            .offset(
                x: CGFloat(Darwin.cos(angle)) * radius,
                y: CGFloat(Darwin.sin(angle)) * radius
            )
    }

    private func startAnimations() {
        // Orbit rotation
        withAnimation(
            .linear(duration: 8)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = .pi * 2
        }

        // Pulse
        withAnimation(Theme.Animation.plasmaPulse) {
            pulsePhase = 1
        }
    }
}

// MARK: - Cosmic Confetti Burst (Enhanced)

/// Enhanced confetti burst with cosmic styling
struct CosmicConfettiBurst: View {
    let particleCount: Int
    let colors: [Color]

    @State private var confetti: [ConfettiPiece] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct ConfettiPiece: Identifiable {
        let id: UUID
        var position: CGPoint
        var velocity: CGSize
        var rotation: Double
        var rotationSpeed: Double
        let color: Color
        let shape: ConfettiShape
        var opacity: Double
    }

    enum ConfettiShape: CaseIterable {
        case circle, star, sparkle, rectangle
    }

    init(
        particleCount: Int = 60,
        colors: [Color] = [
            Theme.CelestialColors.nebulaCore,
            Theme.CelestialColors.nebulaGlow,
            Theme.CelestialColors.nebulaEdge,
            Theme.CelestialColors.auroraGreen,
            Theme.CelestialColors.solarFlare,
            .white
        ]
    ) {
        self.particleCount = particleCount
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confetti) { piece in
                    confettiView(piece)
                }
            }
            .onAppear {
                if !reduceMotion {
                    triggerBurst(in: geometry.size)
                }
            }
        }
    }

    @ViewBuilder
    private func confettiView(_ piece: ConfettiPiece) -> some View {
        Group {
            switch piece.shape {
            case .circle:
                SwiftUI.Circle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)

            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(piece.color)

            case .sparkle:
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundStyle(piece.color)

            case .rectangle:
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 6, height: 10)
            }
        }
        .position(piece.position)
        .rotationEffect(.degrees(piece.rotation))
        .opacity(piece.opacity)
    }

    private func triggerBurst(in size: CGSize) {
        let centerX = size.width / 2
        let topY = size.height * 0.2

        for _ in 0..<particleCount {
            let piece = ConfettiPiece(
                id: UUID(),
                position: CGPoint(
                    x: centerX + CGFloat.random(in: -50...50),
                    y: topY
                ),
                velocity: CGSize(
                    width: CGFloat.random(in: -6...6),
                    height: CGFloat.random(in: 2...8)
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -20...20),
                color: colors.randomElement() ?? .white,
                shape: ConfettiShape.allCases.randomElement() ?? .circle,
                opacity: 1
            )
            confetti.append(piece)
        }

        // Animate falling
        animateConfetti(in: size)
    }

    private func animateConfetti(in size: CGSize) {
        let gravity: CGFloat = 0.15
        let drag: CGFloat = 0.98

        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            var shouldContinue = false

            for i in confetti.indices {
                // Apply gravity
                confetti[i].velocity.height += gravity

                // Apply drag
                confetti[i].velocity.width *= drag

                // Update position
                confetti[i].position.x += confetti[i].velocity.width
                confetti[i].position.y += confetti[i].velocity.height

                // Update rotation
                confetti[i].rotation += confetti[i].rotationSpeed

                // Fade out when below screen
                if confetti[i].position.y > size.height {
                    confetti[i].opacity = max(0, confetti[i].opacity - 0.05)
                }

                if confetti[i].opacity > 0 {
                    shouldContinue = true
                }
            }

            if !shouldContinue {
                timer.invalidate()
                confetti.removeAll()
            }
        }
    }
}

// MARK: - Preview

#Preview("Cosmic Particles") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: 40) {
            // Supernova
            SupernovaParticleBurst(
                at: CGPoint(x: 200, y: 100),
                particleCount: 24
            )
            .frame(height: 200)

            // AI Sparkles
            AISparkleField(
                bounds: CGSize(width: 300, height: 100),
                density: .medium,
                primaryColor: Theme.CelestialColors.nebulaCore
            )
            .frame(width: 300, height: 100)
            .background(Theme.CelestialColors.abyss)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Focus Shield
            FocusShieldParticles(
                radius: 60,
                particleCount: 8,
                isActive: true
            )
            .frame(width: 150, height: 150)
        }
    }
}
