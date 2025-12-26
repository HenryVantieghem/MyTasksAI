//
//  InfinityRingLogo.swift
//  Veloce
//
//  Glowing Infinity Ring Logo
//  Premium 3D cloud-like animated logo
//

import SwiftUI
import Foundation

// MARK: - Infinity Ring Logo

struct InfinityRingLogo: View {
    let size: LogoSize
    var isAnimating: Bool = true
    var showParticles: Bool = true

    // Animation state
    @State private var rotationAngle: Double = 0
    @State private var glowPhase: Double = 0
    @State private var cloudPhase: Double = 0
    @State private var particlePhase: Double = 0

    // Computed dimensions
    private var dimension: CGFloat { size.dimension }
    private var strokeWidth: CGFloat { dimension * 0.06 }
    private var glowRadius: CGFloat { dimension * 0.15 }

    var body: some View {
        ZStack {
            // Layer 1: Deep glow (cloud effect)
            if size.showGlow {
                cloudGlowLayer
            }

            // Layer 2: Outer glow
            if size.showGlow {
                outerGlowLayer
            }

            // Layer 3: Main infinity ring
            mainInfinityRing

            // Layer 4: Specular highlights
            specularHighlights

            // Layer 5: Orbiting particles
            if showParticles && size.showParticles {
                orbitingParticles
            }
        }
        .frame(width: dimension, height: dimension * 0.6)
        .onAppear {
            guard isAnimating else { return }
            startAnimations()
        }
    }

    // MARK: - Cloud Glow Layer

    private var cloudGlowLayer: some View {
        InfinityShape()
            .stroke(
                LinearGradient(
                    colors: [
                        Veloce.Colors.accentPrimary.opacity(0.3),
                        Veloce.Colors.accentSecondary.opacity(0.2),
                        Veloce.Colors.accentTertiary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: strokeWidth * 4
            )
            .blur(radius: glowRadius * 1.5)
            .scaleEffect(1.0 + cloudPhase * 0.08)
            .opacity(0.6 + cloudPhase * 0.2)
    }

    // MARK: - Outer Glow Layer

    private var outerGlowLayer: some View {
        InfinityShape()
            .stroke(
                LinearGradient(
                    colors: [
                        Veloce.Colors.accentPrimary.opacity(0.5),
                        Veloce.Colors.accentSecondary.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: strokeWidth * 2
            )
            .blur(radius: glowRadius)
            .scaleEffect(1.0 + glowPhase * 0.04)
    }

    // MARK: - Main Infinity Ring

    private var mainInfinityRing: some View {
        InfinityShape()
            .stroke(
                LinearGradient(
                    colors: [
                        Veloce.Colors.accentPrimary,
                        Veloce.Colors.accentSecondary,
                        Veloce.Colors.accentPrimary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: strokeWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .shadow(color: Veloce.Colors.accentPrimary.opacity(0.5), radius: 4, x: 0, y: 0)
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: 0.2, y: 1.0, z: 0),
                perspective: 0.3
            )
    }

    // MARK: - Specular Highlights

    private var specularHighlights: some View {
        ZStack {
            // Top-left highlight
            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: strokeWidth * 1.2, height: strokeWidth * 1.2)
                .blur(radius: 2)
                .offset(x: -dimension * 0.35, y: -dimension * 0.08)

            // Top-right highlight
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: strokeWidth * 0.8, height: strokeWidth * 0.8)
                .blur(radius: 1.5)
                .offset(x: dimension * 0.35, y: -dimension * 0.06)

            // Center crossing highlight
            Circle()
                .fill(.white.opacity(0.4))
                .frame(width: strokeWidth * 0.6, height: strokeWidth * 0.6)
                .blur(radius: 1)
                .offset(y: dimension * 0.02)
        }
        .opacity(0.7 + glowPhase * 0.3)
    }

    // MARK: - Orbiting Particles

    private var orbitingParticles: some View {
        ForEach(0..<6, id: \.self) { index in
            Circle()
                .fill(
                    index % 2 == 0
                        ? Veloce.Colors.accentPrimary
                        : Veloce.Colors.accentSecondary
                )
                .frame(width: strokeWidth * 0.4, height: strokeWidth * 0.4)
                .blur(radius: 1)
                .offset(x: particleOffset(for: index).x, y: particleOffset(for: index).y)
                .opacity(particleOpacity(for: index))
        }
    }

    private func particleOffset(for index: Int) -> CGPoint {
        let angle = (Double(index) / 6.0 * 360 + particlePhase * 60).degreesToRadians
        let radiusX = dimension * 0.45
        let radiusY = dimension * 0.25
        return CGPoint(
            x: Darwin.cos(angle) * radiusX,
            y: Darwin.sin(angle) * radiusY
        )
    }

    private func particleOpacity(for index: Int) -> Double {
        let phase = (Double(index) / 6.0 + particlePhase / 6.0).truncatingRemainder(dividingBy: 1.0)
        return 0.3 + Darwin.sin(phase * .pi * 2) * 0.4
    }

    // MARK: - Animations

    private func startAnimations() {
        // Gentle 3D rotation (8s cycle, subtle tilt)
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
            rotationAngle = 12
        }

        // Glow pulsing (2.5s cycle)
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowPhase = 1.0
        }

        // Cloud breathing (4s cycle)
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            cloudPhase = 1.0
        }

        // Particle orbit (6s cycle)
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            particlePhase = 6.0
        }
    }
}

// MARK: - Infinity Shape

struct InfinityShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let centerY = height / 2

        // Control points for smoother curves
        let leftLoopCenter = CGPoint(x: width * 0.25, y: centerY)
        let rightLoopCenter = CGPoint(x: width * 0.75, y: centerY)
        let loopRadius = min(width * 0.22, height * 0.4)

        // Create infinity shape using bezier curves
        let centerX = width / 2

        // Start from center, going to top-right
        path.move(to: CGPoint(x: centerX, y: centerY))

        // Right loop (clockwise)
        path.addCurve(
            to: CGPoint(x: rightLoopCenter.x + loopRadius, y: centerY),
            control1: CGPoint(x: centerX + loopRadius * 0.5, y: centerY - loopRadius * 0.8),
            control2: CGPoint(x: rightLoopCenter.x, y: centerY - loopRadius)
        )
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY),
            control1: CGPoint(x: rightLoopCenter.x + loopRadius, y: centerY + loopRadius * 0.8),
            control2: CGPoint(x: centerX + loopRadius * 0.5, y: centerY + loopRadius * 0.8)
        )

        // Left loop (counter-clockwise)
        path.addCurve(
            to: CGPoint(x: leftLoopCenter.x - loopRadius, y: centerY),
            control1: CGPoint(x: centerX - loopRadius * 0.5, y: centerY + loopRadius * 0.8),
            control2: CGPoint(x: leftLoopCenter.x, y: centerY + loopRadius)
        )
        path.addCurve(
            to: CGPoint(x: centerX, y: centerY),
            control1: CGPoint(x: leftLoopCenter.x - loopRadius, y: centerY - loopRadius * 0.8),
            control2: CGPoint(x: centerX - loopRadius * 0.5, y: centerY - loopRadius * 0.8)
        )

        return path
    }
}

// MARK: - Helper Extension

private extension Double {
    var degreesToRadians: Double {
        self * .pi / 180
    }
}

// MARK: - Static Logo (No Animation)

struct InfinityRingLogoStatic: View {
    let size: LogoSize

    var body: some View {
        InfinityRingLogo(size: size, isAnimating: false, showParticles: false)
    }
}

// MARK: - Previews

#Preview("All Sizes") {
    VStack(spacing: 40) {
        Group {
            Text("Tiny (24pt)")
            InfinityRingLogo(size: .tiny)
        }

        Group {
            Text("Small (40pt)")
            InfinityRingLogo(size: .small)
        }

        Group {
            Text("Medium (80pt)")
            InfinityRingLogo(size: .medium)
        }

        Group {
            Text("Large (120pt)")
            InfinityRingLogo(size: .large)
        }
    }
    .foregroundStyle(.white)
    .padding()
    .background(Veloce.Colors.voidBlack)
}

#Preview("Hero Size") {
    VStack {
        InfinityRingLogo(size: .hero)

        Text("MyTasksAI")
            .font(Veloce.Typography.displayHero)
            .foregroundStyle(Veloce.Colors.textPrimary)
            .padding(.top, 20)

        Text("Achieve the Impossible")
            .font(Veloce.Typography.body)
            .foregroundStyle(Veloce.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Veloce.Colors.voidBlack)
}
