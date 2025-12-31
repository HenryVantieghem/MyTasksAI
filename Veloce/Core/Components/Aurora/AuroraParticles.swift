//
//  AuroraParticles.swift
//  Veloce
//
//  Aurora Particle Systems - Fireflies, Dust Trails, Supernovas
//  Maximum wow factor particle effects
//

import SwiftUI

// MARK: - Particle Types

/// Types of particle effects in Aurora Design System
public enum AuroraParticleType {
    /// Ambient floating fireflies
    case firefly
    /// Energy dust trail (task completion)
    case dustTrail
    /// Supernova burst (celebration)
    case supernova
    /// Confetti shower (milestone)
    case confetti
    /// Mini checkbox burst
    case miniBurst
    /// Rising embers (urgency)
    case embers
}

// MARK: - Firefly Constellation

/// Ambient floating particle field
public struct AuroraFireflyField: View {

    let count: Int
    let colors: [Color]

    @State private var particles: [FireflyParticle] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        count: Int = Aurora.Particles.firefly,
        colors: [Color] = [
            Aurora.Colors.electricCyan,
            Aurora.Colors.borealisViolet,
            Aurora.Colors.stellarMagenta,
            Aurora.Colors.prismaticGreen
        ]
    ) {
        self.count = count
        self.colors = colors
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    FireflyView(particle: particle, containerSize: geometry.size)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        guard !reduceMotion else { return }

        particles = (0..<count).map { index in
            FireflyParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                targetPosition: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...5),
                color: colors.randomElement() ?? Aurora.Colors.electricCyan,
                opacity: Double.random(in: 0.3...0.8),
                glowIntensity: CGFloat.random(in: 0.3...0.7),
                animationDelay: Double(index) * 0.1,
                speed: Double.random(in: 15...40)
            )
        }
    }
}

struct FireflyParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var targetPosition: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
    let glowIntensity: CGFloat
    let animationDelay: Double
    let speed: Double
}

struct FireflyView: View {
    let particle: FireflyParticle
    let containerSize: CGSize

    @State private var currentPosition: CGPoint
    @State private var isGlowing = false

    init(particle: FireflyParticle, containerSize: CGSize) {
        self.particle = particle
        self.containerSize = containerSize
        self._currentPosition = State(initialValue: particle.position)
    }

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .shadow(
                color: particle.color.opacity(isGlowing ? particle.glowIntensity : particle.glowIntensity * 0.5),
                radius: isGlowing ? 12 : 6
            )
            .opacity(particle.opacity)
            .position(currentPosition)
            .onAppear {
                startAnimation()
            }
    }

    private func startAnimation() {
        // Glow pulse
        withAnimation(
            .easeInOut(duration: AuroraMotion.Duration.breathingCycle)
            .repeatForever(autoreverses: true)
            .delay(particle.animationDelay)
        ) {
            isGlowing = true
        }

        // Movement
        moveToNewPosition()
    }

    private func moveToNewPosition() {
        let newTarget = CGPoint(
            x: CGFloat.random(in: 0...containerSize.width),
            y: CGFloat.random(in: 0...containerSize.height)
        )

        let duration = particle.speed / 10

        withAnimation(.easeInOut(duration: duration)) {
            currentPosition = newTarget
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            moveToNewPosition()
        }
    }
}

// MARK: - Supernova Burst

/// Explosive particle burst for celebrations
public struct AuroraSupernovaBurst: View {

    @Binding var isActive: Bool

    let color: Color
    let particleCount: Int
    let duration: Double

    @State private var particles: [SupernovaParticle] = []

    public init(
        isActive: Binding<Bool>,
        color: Color = Aurora.Colors.cosmicGold,
        particleCount: Int = Aurora.Particles.supernova,
        duration: Double = 1.0
    ) {
        self._isActive = isActive
        self.color = color
        self.particleCount = particleCount
        self.duration = duration
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    SupernovaParticleView(particle: particle)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    triggerBurst(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerBurst(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        particles = (0..<particleCount).map { index in
            let angle = (Double(index) / Double(particleCount)) * 360
            let distance = CGFloat.random(in: 100...250)
            let endX = center.x + cos(angle * .pi / 180) * distance
            let endY = center.y + sin(angle * .pi / 180) * distance

            return SupernovaParticle(
                startPosition: center,
                endPosition: CGPoint(x: endX, y: endY),
                size: CGFloat.random(in: 3...8),
                color: [color, Aurora.Colors.stellarWhite, color.opacity(0.7)].randomElement()!,
                shape: [.circle, .star, .sparkle].randomElement()!,
                delay: Double.random(in: 0...0.1)
            )
        }

        // Reset after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.3) {
            particles = []
            isActive = false
        }
    }
}

struct SupernovaParticle: Identifiable {
    let id = UUID()
    let startPosition: CGPoint
    let endPosition: CGPoint
    let size: CGFloat
    let color: Color
    let shape: ParticleShape
    let delay: Double

    enum ParticleShape {
        case circle, star, sparkle
    }
}

struct SupernovaParticleView: View {
    let particle: SupernovaParticle

    @State private var position: CGPoint
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = 0

    init(particle: SupernovaParticle) {
        self.particle = particle
        self._position = State(initialValue: particle.startPosition)
    }

    var body: some View {
        particleShape
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .shadow(color: particle.color.opacity(0.6), radius: 4)
            .opacity(opacity)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .onAppear {
                animate()
            }
    }

    private var particleShape: AnyShape {
        switch particle.shape {
        case .circle:
            AnyShape(Circle())
        case .star:
            AnyShape(Star(points: 4, innerRatio: 0.5))
        case .sparkle:
            AnyShape(Star(points: 6, innerRatio: 0.3))
        }
    }

    private func animate() {
        // Burst out
        withAnimation(
            .spring(response: 0.4, dampingFraction: 0.6)
            .delay(particle.delay)
        ) {
            position = particle.endPosition
            scale = 1.0
            rotation = Double.random(in: 180...360)
        }

        // Fade out
        withAnimation(
            .easeOut(duration: 0.5)
            .delay(particle.delay + 0.3)
        ) {
            opacity = 0
            scale = 0.3
        }
    }
}

// MARK: - Star Shape

struct Star: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio

        for i in 0..<(points * 2) {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti Shower

/// Celebration confetti with physics
public struct AuroraConfettiShower: View {

    @Binding var isActive: Bool

    let colors: [Color]
    let particleCount: Int

    @State private var particles: [ConfettiParticle] = []

    public init(
        isActive: Binding<Bool>,
        colors: [Color] = [
            Aurora.Colors.electricCyan,
            Aurora.Colors.stellarMagenta,
            Aurora.Colors.cosmicGold,
            Aurora.Colors.prismaticGreen,
            Aurora.Colors.borealisViolet
        ],
        particleCount: Int = Aurora.Particles.confetti
    ) {
        self._isActive = isActive
        self.colors = colors
        self.particleCount = particleCount
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle, containerHeight: geometry.size.height)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    triggerConfetti(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerConfetti(in size: CGSize) {
        particles = (0..<particleCount).map { index in
            ConfettiParticle(
                startPosition: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                color: colors.randomElement()!,
                size: CGSize(
                    width: CGFloat.random(in: 8...14),
                    height: CGFloat.random(in: 4...8)
                ),
                rotationSpeed: Double.random(in: 2...8),
                fallSpeed: Double.random(in: 2...4),
                swayAmplitude: CGFloat.random(in: 20...50),
                delay: Double(index) * 0.02
            )
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            particles = []
            isActive = false
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let startPosition: CGPoint
    let color: Color
    let size: CGSize
    let rotationSpeed: Double
    let fallSpeed: Double
    let swayAmplitude: CGFloat
    let delay: Double
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let containerHeight: CGFloat

    @State private var position: CGPoint
    @State private var rotation: Double = 0
    @State private var rotationX: Double = 0

    init(particle: ConfettiParticle, containerHeight: CGFloat) {
        self.particle = particle
        self.containerHeight = containerHeight
        self._position = State(initialValue: particle.startPosition)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size.width, height: particle.size.height)
            .shadow(color: particle.color.opacity(0.4), radius: 2)
            .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0))
            .rotationEffect(.degrees(rotation))
            .position(position)
            .onAppear {
                animate()
            }
    }

    private func animate() {
        // Fall animation
        withAnimation(
            .linear(duration: particle.fallSpeed)
            .delay(particle.delay)
        ) {
            position = CGPoint(
                x: particle.startPosition.x + CGFloat.random(in: -particle.swayAmplitude...particle.swayAmplitude),
                y: containerHeight + 50
            )
        }

        // Rotation
        withAnimation(
            .linear(duration: 1)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }

        // 3D flip
        withAnimation(
            .linear(duration: 0.5)
            .repeatForever(autoreverses: false)
        ) {
            rotationX = 360
        }
    }
}

// MARK: - Mini Burst (Checkbox)

/// Small particle burst for checkbox completion
public struct AuroraMiniBurst: View {

    @Binding var isActive: Bool

    let color: Color
    let position: CGPoint

    @State private var particles: [MiniParticle] = []

    public init(
        isActive: Binding<Bool>,
        color: Color = Aurora.Colors.prismaticGreen,
        position: CGPoint = .zero
    ) {
        self._isActive = isActive
        self.color = color
        self.position = position
    }

    public var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .shadow(color: particle.color.opacity(0.5), radius: 3)
                    .modifier(MiniParticleAnimator(particle: particle, startPosition: position))
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerBurst() {
        particles = (0..<Aurora.Particles.miniBurst).map { index in
            let angle = (Double(index) / Double(Aurora.Particles.miniBurst)) * 360
            let distance = CGFloat.random(in: 20...40)

            return MiniParticle(
                angle: angle,
                distance: distance,
                size: CGFloat.random(in: 2...4),
                color: [color, Aurora.Colors.stellarWhite, color.opacity(0.7)].randomElement()!
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            particles = []
            isActive = false
        }
    }
}

struct MiniParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let color: Color
}

struct MiniParticleAnimator: ViewModifier {
    let particle: MiniParticle
    let startPosition: CGPoint

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .opacity(opacity)
            .position(startPosition)
            .onAppear {
                let endX = cos(particle.angle * .pi / 180) * particle.distance
                let endY = sin(particle.angle * .pi / 180) * particle.distance

                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    offset = CGSize(width: endX, height: endY)
                }

                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Rising Embers (Urgency)

/// Rising ember particles for overdue tasks
public struct AuroraRisingEmbers: View {

    let intensity: CGFloat
    let color: Color

    @State private var embers: [EmberParticle] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        intensity: CGFloat = 0.5,
        color: Color = Aurora.Colors.warning
    ) {
        self.intensity = intensity
        self.color = color
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(embers) { ember in
                    EmberView(ember: ember, containerHeight: geometry.size.height)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                generateEmbers(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateEmbers(in size: CGSize) {
        let count = Int(20 * intensity)

        embers = (0..<count).map { _ in
            EmberParticle(
                startX: CGFloat.random(in: 0...size.width),
                size: CGFloat.random(in: 2...5),
                color: [color, color.opacity(0.7), Aurora.Colors.stellarMagenta].randomElement()!,
                speed: Double.random(in: 3...6),
                swayAmplitude: CGFloat.random(in: 10...30),
                delay: Double.random(in: 0...2)
            )
        }
    }
}

struct EmberParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let size: CGFloat
    let color: Color
    let speed: Double
    let swayAmplitude: CGFloat
    let delay: Double
}

struct EmberView: View {
    let ember: EmberParticle
    let containerHeight: CGFloat

    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(ember.color)
            .frame(width: ember.size, height: ember.size)
            .shadow(color: ember.color.opacity(0.6), radius: ember.size)
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
            .position(x: ember.startX, y: containerHeight)
            .onAppear {
                startAnimation()
            }
    }

    private func startAnimation() {
        // Fade in
        withAnimation(.easeIn(duration: 0.3).delay(ember.delay)) {
            opacity = 0.8
        }

        // Rise
        withAnimation(
            .linear(duration: ember.speed)
            .delay(ember.delay)
            .repeatForever(autoreverses: false)
        ) {
            offsetY = -containerHeight - 50
        }

        // Sway
        withAnimation(
            .easeInOut(duration: 1)
            .repeatForever(autoreverses: true)
        ) {
            offsetX = ember.swayAmplitude
        }

        // Fade out at top
        DispatchQueue.main.asyncAfter(deadline: .now() + ember.delay + ember.speed * 0.7) {
            withAnimation(.easeOut(duration: ember.speed * 0.3)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Preview

#Preview("Particle Systems") {
    struct ParticlePreview: View {
        @State private var showSupernova = false
        @State private var showConfetti = false
        @State private var showMiniBurst = false

        var body: some View {
            ZStack {
                Aurora.Colors.voidCosmos.ignoresSafeArea()

                // Firefly field
                AuroraFireflyField()

                VStack(spacing: 30) {
                    Button("Supernova") {
                        showSupernova = true
                    }
                    .padding()
                    .auroraGlass(.interactive, in: Capsule())

                    Button("Confetti") {
                        showConfetti = true
                    }
                    .padding()
                    .auroraGlass(.interactive, in: Capsule())

                    Button("Mini Burst") {
                        showMiniBurst = true
                    }
                    .padding()
                    .auroraGlass(.interactive, in: Capsule())
                }
                .foregroundStyle(Aurora.Colors.textPrimary)

                // Particle overlays
                AuroraSupernovaBurst(isActive: $showSupernova)
                AuroraConfettiShower(isActive: $showConfetti)

                GeometryReader { geo in
                    AuroraMiniBurst(
                        isActive: $showMiniBurst,
                        position: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 + 100)
                    )
                }
            }
        }
    }

    return ParticlePreview()
}
