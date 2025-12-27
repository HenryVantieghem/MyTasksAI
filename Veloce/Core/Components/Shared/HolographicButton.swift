//
//  HolographicButton.swift
//  MyTasksAI
//
//  Holographic Button - Premium Interactive Component
//  Ultra-premium glass morphism buttons with prismatic shifting borders,
//  liquid gradient fills, press animations, and micro-haptics.
//  Designed to feel like Apple paid a billion dollars for this.
//

import SwiftUI

// MARK: - Holographic Button Style

enum HolographicButtonStyle {
    case primary     // Gradient fill with glow
    case secondary   // Glass with prismatic border
    case ghost       // Minimal with prismatic hover
    case success     // Green gradient
    case destructive // Red gradient
}

// MARK: - Holographic Button

struct HolographicButton: View {
    let title: String
    let style: HolographicButtonStyle
    let icon: String?
    let iconPosition: IconPosition
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    enum IconPosition {
        case leading
        case trailing
    }

    @State private var isPressed = false
    @State private var borderPhase: Double = 0
    @State private var glowPhase: Double = 0
    @State private var loadingRotation: Double = 0
    @State private var appearScale: CGFloat = 0.95

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Premium prismatic colors
    private let prismaticColors: [Color] = [
        Color(red: 0.55, green: 0.35, blue: 1.0),   // Deep violet
        Color(red: 0.35, green: 0.55, blue: 1.0),   // Electric blue
        Color(red: 0.25, green: 0.85, blue: 0.95),  // Cyan plasma
        Color(red: 0.55, green: 0.95, blue: 0.85),  // Seafoam
        Color(red: 0.95, green: 0.55, blue: 0.85),  // Rose quartz
    ]

    init(
        _ title: String,
        style: HolographicButtonStyle = .primary,
        icon: String? = nil,
        iconPosition: IconPosition = .trailing,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            HapticsService.shared.impact()
            action()
        } label: {
            HStack(spacing: 10) {
                if iconPosition == .leading, let icon {
                    iconView(icon)
                }

                if isLoading {
                    loadingIndicator
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .tracking(0.5)
                }

                if iconPosition == .trailing, let icon, !isLoading {
                    iconView(icon)
                }
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: shadowRadius, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
        .scaleEffect(isPressed ? 0.97 : 1)
        .scaleEffect(appearScale)
        .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appearScale = 1.0
            }
            startAnimations()
        }
    }

    // MARK: - Icon View

    @ViewBuilder
    private func iconView(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
    }

    // MARK: - Loading Indicator

    private var loadingIndicator: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 2.5)
                .frame(width: 22, height: 22)

            Circle()
                .trim(from: 0, to: 0.35)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(loadingRotation))
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            primaryBackground
        case .secondary:
            secondaryBackground
        case .ghost:
            Color.clear
        case .success:
            successBackground
        case .destructive:
            destructiveBackground
        }
    }

    private var primaryBackground: some View {
        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            prismaticColors[0],
                            prismaticColors[1],
                            prismaticColors[2].opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 12)
                .opacity(0.5 * (0.8 + glowPhase * 0.2))

            // Main gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            prismaticColors[0],
                            prismaticColors[1],
                            prismaticColors[2].opacity(0.9)
                        ],
                        startPoint: UnitPoint(x: 0 + borderPhase * 0.1, y: 0),
                        endPoint: UnitPoint(x: 1 + borderPhase * 0.1, y: 1)
                    )
                )

            // Glass overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Shimmer
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: -1 + borderPhase * 0.4, y: 0.5),
                        endPoint: UnitPoint(x: 0 + borderPhase * 0.4, y: 0.5)
                    )
                )
        }
    }

    private var secondaryBackground: some View {
        ZStack {
            // Glass base
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)

            // Void overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.04, blue: 0.08).opacity(0.8),
                            Color(red: 0.02, green: 0.02, blue: 0.06).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle accent hint
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    RadialGradient(
                        colors: [
                            prismaticColors[0].opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
        }
    }

    private var successBackground: some View {
        ZStack {
            // Glow
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.auroraGreen)
                .blur(radius: 12)
                .opacity(0.4 * (0.8 + glowPhase * 0.2))

            // Main
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.auroraGreen,
                            Theme.CelestialColors.auroraGreen.opacity(0.85),
                            Color(red: 0.15, green: 0.75, blue: 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Glass overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
    }

    private var destructiveBackground: some View {
        ZStack {
            // Glow
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.errorNebula)
                .blur(radius: 12)
                .opacity(0.4 * (0.8 + glowPhase * 0.2))

            // Main
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.errorNebula,
                            Theme.CelestialColors.errorNebula.opacity(0.85),
                            Color(red: 0.85, green: 0.25, blue: 0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Glass overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
    }

    // MARK: - Border Overlay

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .ghost:
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            prismaticColors[0].opacity(0.3),
                            Color.white.opacity(0.15),
                            prismaticColors[2].opacity(0.3),
                            Color.white.opacity(0.25)
                        ],
                        center: .center,
                        angle: .degrees(borderPhase * 60)
                    ),
                    lineWidth: 1.5
                )

        case .secondary:
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    AngularGradient(
                        colors: [
                            prismaticColors[0].opacity(0.5),
                            prismaticColors[1].opacity(0.3),
                            prismaticColors[2].opacity(0.4),
                            prismaticColors[0].opacity(0.3),
                            prismaticColors[0].opacity(0.5)
                        ],
                        center: .center,
                        angle: .degrees(borderPhase * 60)
                    ),
                    lineWidth: 1.5
                )

        default:
            EmptyView()
        }
    }

    // MARK: - Colors

    private var textColor: Color {
        switch style {
        case .primary, .success, .destructive:
            return .white
        case .secondary, .ghost:
            return .white.opacity(0.9)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return prismaticColors[0].opacity(isPressed ? 0.5 : 0.35)
        case .success:
            return Theme.CelestialColors.auroraGreen.opacity(isPressed ? 0.5 : 0.35)
        case .destructive:
            return Theme.CelestialColors.errorNebula.opacity(isPressed ? 0.5 : 0.35)
        default:
            return Color.clear
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .success, .destructive:
            return isPressed ? 10 : 16
        default:
            return 0
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Border rotation for secondary/ghost
        if style == .secondary || style == .ghost {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                borderPhase = 6
            }
        }

        // Shimmer for primary
        if style == .primary {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                borderPhase = 5
            }
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }

        // Loading rotation
        if isLoading {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                loadingRotation = 360
            }
        }
    }
}

// MARK: - Holographic Link Button

struct HolographicLinkButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false
    @State private var shimmerPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ title: String, color: Color = Color(red: 0.55, green: 0.35, blue: 1.0), action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            action()
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            color,
                            color.opacity(0.8 + shimmerPhase * 0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                shimmerPhase = 1
            }
        }
    }
}

// MARK: - Preview

#Preview("Holographic Buttons") {
    ZStack {
        Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()

        VStack(spacing: 20) {
            HolographicButton("Primary Button", style: .primary, icon: "arrow.right") {}

            HolographicButton("Secondary Button", style: .secondary, icon: "chevron.right") {}

            HolographicButton("Ghost Button", style: .ghost) {}

            HolographicButton("Success Button", style: .success, icon: "checkmark") {}

            HolographicButton("Destructive", style: .destructive, icon: "trash") {}

            HolographicButton("Loading...", style: .primary, isLoading: true) {}

            HolographicButton("Disabled", style: .primary, isEnabled: false) {}

            HStack {
                HolographicLinkButton("Link Button") {}
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(24)
    }
}
