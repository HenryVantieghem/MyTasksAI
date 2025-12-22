//
//  LogoVariants.swift
//  MyTasksAI
//
//  Logo Variants - Static and specialized versions
//  For different contexts and states
//

import SwiftUI

// MARK: - Static Logo

/// Non-animated logo for performance-sensitive contexts
struct StaticLogoView: View {
    let size: LogoSize
    var tintColor: Color? = nil

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) * 0.35
            let strokeWidth = radius * 0.18

            // Create the infinity-orbital path (static)
            let path = createStaticOrbitalPath(center: center, radius: radius)

            // Gradient colors
            let gradient = Gradient(colors: [
                tintColor ?? Color(hex: "8B5CF6"),
                Color(hex: "3B82F6"),
                Color(hex: "06B6D4"),
                Color(hex: "3B82F6"),
                tintColor ?? Color(hex: "8B5CF6")
            ])

            let shading = GraphicsContext.Shading.conicGradient(
                gradient,
                center: center,
                angle: .degrees(0)
            )

            // Main stroke
            context.stroke(
                path,
                with: shading,
                style: StrokeStyle(
                    lineWidth: strokeWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .frame(width: size.dimension, height: size.dimension)
    }

    private func createStaticOrbitalPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        let segments = 100

        for i in 0...segments {
            let t = Double(i) / Double(segments) * 2 * .pi
            let a = 1.0
            let denominator = 1 + pow(sin(t), 2)
            let x = a * cos(t) / denominator
            let y = a * sin(t) * cos(t) / denominator

            let point = CGPoint(
                x: center.x + x * radius,
                y: center.y + y * radius
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

// MARK: - Loading Logo

/// Logo with pulsing animation for loading states
struct LoadingLogoView: View {
    let size: LogoSize
    @State private var pulsePhase: Double = 0

    var body: some View {
        ZStack {
            // Pulsing glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "8B5CF6").opacity(0.3 * pulsePhase),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.dimension * 0.6
                    )
                )
                .frame(width: size.dimension * 1.5, height: size.dimension * 1.5)
                .blur(radius: size.dimension * 0.1)
                .scaleEffect(0.8 + pulsePhase * 0.2)

            AppLogoView(size: size, isAnimating: true)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulsePhase = 1
            }
        }
    }
}

// MARK: - Success Logo Burst

/// Logo that bursts into particles on success
struct SuccessLogoBurst: View {
    let size: LogoSize
    @Binding var shouldBurst: Bool

    @State private var burstProgress: Double = 0
    @State private var particleOffsets: [CGPoint] = []
    @State private var particleOpacities: [Double] = []

    private let particleCount = 20

    var body: some View {
        ZStack {
            // Original logo (fades out during burst)
            AppLogoView(size: size, isAnimating: !shouldBurst)
                .opacity(shouldBurst ? 1 - burstProgress : 1)
                .scaleEffect(shouldBurst ? 1 + burstProgress * 0.3 : 1)

            // Burst particles
            if shouldBurst {
                ForEach(0..<particleCount, id: \.self) { index in
                    BurstParticle(
                        index: index,
                        progress: burstProgress,
                        baseSize: size.dimension
                    )
                }
            }
        }
        .onChange(of: shouldBurst) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
    }

    private func triggerBurst() {
        withAnimation(.easeOut(duration: 1.2)) {
            burstProgress = 1
        }

        // Reset after burst completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            burstProgress = 0
            shouldBurst = false
        }
    }
}

struct BurstParticle: View {
    let index: Int
    let progress: Double
    let baseSize: CGFloat

    private var config: BurstConfig {
        let seed = Double(index)
        let angle = (seed / 20) * 2 * .pi + seed * 0.5
        let distance = baseSize * (0.8 + sin(seed * 1.7) * 0.4)
        let particleSize = baseSize * (0.05 + sin(seed * 2.3) * 0.02)

        return BurstConfig(
            angle: angle,
            distance: distance,
            particleSize: particleSize,
            color: index % 3 == 0 ? Color(hex: "8B5CF6") :
                   index % 3 == 1 ? Color(hex: "3B82F6") : Color(hex: "06B6D4")
        )
    }

    var body: some View {
        let cfg = config
        let x = cos(cfg.angle) * cfg.distance * progress
        let y = sin(cfg.angle) * cfg.distance * progress

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        cfg.color,
                        cfg.color.opacity(0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: cfg.particleSize
                )
            )
            .frame(width: cfg.particleSize * 2, height: cfg.particleSize * 2)
            .offset(x: x, y: y)
            .opacity(1 - progress * 0.8)
            .blur(radius: cfg.particleSize * 0.2 * progress)
    }
}

struct BurstConfig {
    let angle: Double
    let distance: CGFloat
    let particleSize: CGFloat
    let color: Color
}

// MARK: - Monochrome Logo

/// Single-color logo for specific UI contexts
struct MonochromeLogo: View {
    let size: LogoSize
    let color: Color

    var body: some View {
        StaticLogoView(size: size, tintColor: color)
            .opacity(0.8)
    }
}

// MARK: - Logo with Text

struct LogoWithText: View {
    let size: LogoSize
    var showTagline: Bool = true
    var isAnimating: Bool = true

    var body: some View {
        VStack(spacing: textSpacing) {
            AppLogoView(size: size, isAnimating: isAnimating)

            VStack(spacing: 4) {
                Text("MyTasksAI")
                    .font(titleFont)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if showTagline {
                    Text("INFINITE PRODUCTIVITY")
                        .font(taglineFont)
                        .foregroundStyle(Color(hex: "06B6D4").opacity(0.7))
                        .tracking(taglineTracking)
                }
            }
        }
    }

    private var textSpacing: CGFloat {
        switch size {
        case .tiny, .small: return 8
        case .medium: return 16
        case .large: return 24
        case .hero: return 32
        }
    }

    private var titleFont: Font {
        switch size {
        case .tiny, .small: return .system(size: 14, weight: .medium, design: .rounded)
        case .medium: return .system(size: 20, weight: .light, design: .rounded)
        case .large: return .system(size: 28, weight: .light, design: .rounded)
        case .hero: return .system(size: 36, weight: .light, design: .rounded)
        }
    }

    private var taglineFont: Font {
        switch size {
        case .tiny, .small: return .system(size: 8, weight: .medium)
        case .medium: return .system(size: 10, weight: .medium)
        case .large: return .system(size: 12, weight: .medium)
        case .hero: return .system(size: 14, weight: .medium)
        }
    }

    private var taglineTracking: CGFloat {
        switch size {
        case .tiny, .small: return 1
        case .medium: return 1.5
        case .large, .hero: return 2
        }
    }
}

// MARK: - App Icon Generator View

/// For generating app icon assets
struct AppIconView: View {
    let iconSize: CGFloat

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0F0A1A"),
                    Color(hex: "1A0F2E"),
                    Color(hex: "0F0A1A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow
            RadialGradient(
                colors: [
                    Color(hex: "8B5CF6").opacity(0.3),
                    Color(hex: "3B82F6").opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: iconSize * 0.5
            )

            // Static logo (no animation for icon)
            StaticLogoView(
                size: .custom(dimension: iconSize * 0.55)
            )
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// MARK: - Custom Logo Size Extension

extension LogoSize {
    static func custom(dimension: CGFloat) -> LogoSize {
        if dimension <= 24 { return .tiny }
        if dimension <= 40 { return .small }
        if dimension <= 80 { return .medium }
        if dimension <= 120 { return .large }
        return .hero
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            StaticLogoView(size: .large)

            HStack(spacing: 20) {
                StaticLogoView(size: .medium)
                StaticLogoView(size: .small)
                StaticLogoView(size: .tiny)
            }
        }
    }
}
