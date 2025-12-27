//
//  FocusGemView.swift
//  Veloce
//
//  Opal-inspired 3D gem collectibles for focus milestones
//  Creates depth and shine through layered gradients
//

import SwiftUI

// MARK: - Gem Type

enum FocusGemType: String, CaseIterable, Identifiable {
    case sapphire = "First Focus"
    case emerald = "Deep Diver"
    case ruby = "Week Warrior"
    case diamond = "Month Master"
    case amethyst = "Century Club"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .sapphire: return Color(red: 0.2, green: 0.4, blue: 0.95)
        case .emerald: return Color(red: 0.15, green: 0.8, blue: 0.5)
        case .ruby: return Color(red: 0.95, green: 0.2, blue: 0.3)
        case .diamond: return Color(red: 0.85, green: 0.9, blue: 1.0)
        case .amethyst: return Theme.Colors.aiPurple
        }
    }

    var secondaryColor: Color {
        switch self {
        case .sapphire: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .emerald: return Color(red: 0.3, green: 0.95, blue: 0.7)
        case .ruby: return Color(red: 1.0, green: 0.4, blue: 0.5)
        case .diamond: return Color.white
        case .amethyst: return Theme.Colors.aiPink
        }
    }

    var requirement: String {
        switch self {
        case .sapphire: return "Complete your first focus session"
        case .emerald: return "Complete a 90+ minute deep work session"
        case .ruby: return "Maintain a 7-day focus streak"
        case .diamond: return "Maintain a 30-day focus streak"
        case .amethyst: return "Accumulate 100 total focus hours"
        }
    }

    var icon: String {
        switch self {
        case .sapphire: return "diamond.fill"
        case .emerald: return "leaf.fill"
        case .ruby: return "flame.fill"
        case .diamond: return "crown.fill"
        case .amethyst: return "sparkles"
        }
    }
}

// MARK: - Focus Gem View

struct FocusGemView: View {
    let gemType: FocusGemType
    let isEarned: Bool
    let size: CGFloat

    @State private var rotationAngle: Double = 0
    @State private var sparklePhase: Double = 0
    @State private var isPressed = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(gemType: FocusGemType, isEarned: Bool, size: CGFloat = 60) {
        self.gemType = gemType
        self.isEarned = isEarned
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer glow (only when earned)
            if isEarned {
                gemGlow
            }

            // 3D Gem shape
            gem3DShape

            // Sparkles (only when earned)
            if isEarned && !reduceMotion {
                sparkleOverlay
            }

            // Lock overlay (when not earned)
            if !isEarned {
                lockOverlay
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isPressed ? 0.95 : 1)
        .onAppear {
            if !reduceMotion && isEarned {
                startAnimations()
            }
        }
    }

    // MARK: - Gem Glow

    private var gemGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        gemType.color.opacity(0.4),
                        gemType.color.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.6
                )
            )
            .frame(width: size * 1.4, height: size * 1.4)
            .blur(radius: 8)
    }

    // MARK: - 3D Gem Shape

    private var gem3DShape: some View {
        ZStack {
            // Base gem shape (diamond)
            GemDiamondShape()
                .fill(
                    LinearGradient(
                        colors: isEarned
                            ? [gemType.color, gemType.secondaryColor]
                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.7, height: size * 0.8)

            // Top facet highlight
            GemDiamondShape()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(isEarned ? 0.5 : 0.2),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.7, height: size * 0.8)
                .mask {
                    Rectangle()
                        .frame(height: size * 0.4)
                        .offset(y: -size * 0.2)
                }

            // Left facet
            GemDiamondShape()
                .fill(
                    LinearGradient(
                        colors: [
                            isEarned ? gemType.color.opacity(0.8) : Color.gray.opacity(0.25),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.7, height: size * 0.8)
                .mask {
                    Rectangle()
                        .frame(width: size * 0.35)
                        .offset(x: -size * 0.175)
                }

            // Bottom shadow
            GemDiamondShape()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(isEarned ? 0.3 : 0.1)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.7, height: size * 0.8)

            // Stroke outline
            GemDiamondShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(isEarned ? 0.4 : 0.1),
                            isEarned ? gemType.color.opacity(0.3) : .gray.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size * 0.7, height: size * 0.8)
        }
        .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0))
        .shadow(color: isEarned ? gemType.color.opacity(0.4) : .clear, radius: 8, y: 4)
    }

    // MARK: - Sparkle Overlay

    private var sparkleOverlay: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.15))
                    .foregroundStyle(.white)
                    .offset(
                        x: sparkleOffset(for: index).x,
                        y: sparkleOffset(for: index).y
                    )
                    .opacity(sparkleOpacity(for: index))
                    .scaleEffect(sparkleScale(for: index))
            }
        }
    }

    private func sparkleOffset(for index: Int) -> CGPoint {
        let angle = (Double(index) / 4.0) * 360 + sparklePhase * 90
        let radius = size * 0.4
        return CGPoint(
            x: cos(angle * .pi / 180) * radius,
            y: sin(angle * .pi / 180) * radius
        )
    }

    private func sparkleOpacity(for index: Int) -> Double {
        let phase = (sparklePhase + Double(index) * 0.25).truncatingRemainder(dividingBy: 1)
        return phase < 0.5 ? phase * 2 : (1 - phase) * 2
    }

    private func sparkleScale(for index: Int) -> CGFloat {
        let phase = (sparklePhase + Double(index) * 0.25).truncatingRemainder(dividingBy: 1)
        return 0.5 + CGFloat(phase) * 0.5
    }

    // MARK: - Lock Overlay

    private var lockOverlay: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.5))
                .frame(width: size * 0.5, height: size * 0.5)

            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.2, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Subtle rotation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            rotationAngle = 10
        }

        // Sparkle phase
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            sparklePhase = 1
        }
    }
}

// MARK: - Gem Diamond Shape

struct GemDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topPoint = CGPoint(x: rect.midX, y: rect.minY)
        let leftPoint = CGPoint(x: rect.minX, y: rect.height * 0.35)
        let rightPoint = CGPoint(x: rect.maxX, y: rect.height * 0.35)
        let bottomPoint = CGPoint(x: rect.midX, y: rect.maxY)

        path.move(to: topPoint)
        path.addLine(to: rightPoint)
        path.addLine(to: bottomPoint)
        path.addLine(to: leftPoint)
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
            HStack(spacing: 20) {
                ForEach(FocusGemType.allCases) { gem in
                    VStack(spacing: 8) {
                        FocusGemView(gemType: gem, isEarned: true, size: 60)

                        Text(gem.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            Divider()
                .background(.white.opacity(0.2))
                .padding(.horizontal, 40)

            HStack(spacing: 20) {
                ForEach(FocusGemType.allCases) { gem in
                    VStack(spacing: 8) {
                        FocusGemView(gemType: gem, isEarned: false, size: 60)

                        Text("Locked")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
