//
//  CirclesPill.swift
//  Veloce
//
//  Premium Social Access Pill
//  Floating glassmorphic pill for accessing Circles (social features)
//  Appears in top-left of each main page
//

import SwiftUI

// MARK: - Circles Pill

struct CirclesPill: View {
    @Binding var isPresented: Bool

    // Data
    var friendsOnlineCount: Int = 0
    var hasNotifications: Bool = false

    // Animation state
    @State private var isPressed: Bool = false
    @State private var pulsePhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0

    // Environment
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            triggerHaptic()
            withAnimation(Veloce.Animation.spring) {
                isPresented = true
            }
        } label: {
            pillContent
        }
        .buttonStyle(CirclesPillButtonStyle())
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Pill Content (Native Liquid Glass)

    private var pillContent: some View {
        HStack(spacing: 8) {
            // Icon with online indicator
            ZStack {
                Image(systemName: "person.2.fill")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white)

                // Online indicator dot
                if friendsOnlineCount > 0 {
                    Circle()
                        .fill(Veloce.Colors.success)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(Veloce.Colors.success.opacity(0.4))
                                .scaleEffect(1 + pulsePhase * 0.5)
                        )
                        .offset(x: 8, y: -6)
                }
            }

            // Friends count or "Circles" text
            if friendsOnlineCount > 0 {
                Text("\(friendsOnlineCount)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            } else {
                Text("Circles")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Notification badge
            if hasNotifications {
                Circle()
                    .fill(Veloce.Colors.social)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(pillBackground)
        .glassEffect(.regular, in: Capsule())
        .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
    }

    // MARK: - Background

    private var pillBackground: some View {
        // Subtle accent glow when friends online
        Group {
            if friendsOnlineCount > 0 {
                Capsule()
                    .fill(Veloce.Colors.social.opacity(0.1 * glowPhase))
            }
        }
    }

    // MARK: - Shadow

    private var shadowColor: Color {
        friendsOnlineCount > 0
            ? Veloce.Colors.social.opacity(0.15)
            : Color.black.opacity(0.2)
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Animations

    private func startAnimations() {
        // Pulse animation for online indicator
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            pulsePhase = 1
        }

        // Glow animation
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        ) {
            glowPhase = 1
        }
    }
}

// MARK: - Button Style

struct CirclesPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Compact Variant (for smaller spaces)

struct CirclesPillCompact: View {
    @Binding var isPresented: Bool
    var hasNotifications: Bool = false

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(Veloce.Animation.spring) {
                isPresented = true
            }
        } label: {
            ZStack {
                Image(systemName: "person.2.fill")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(.white)

                // Notification dot
                if hasNotifications {
                    Circle()
                        .fill(Veloce.Colors.social)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.3), lineWidth: 2)
                        )
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 40, height: 40)
            .glassEffect(.regular, in: SwiftUI.Circle())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(CirclesPillButtonStyle())
    }
}

// MARK: - Header Integration

/// Use this view to add the CirclesPill to any page header
struct CirclesPillHeader: View {
    @Binding var showCircles: Bool
    var friendsOnline: Int = 0
    var hasNotifications: Bool = false
    var title: String? = nil

    var body: some View {
        HStack(alignment: .center) {
            // Circles pill (left)
            CirclesPill(
                isPresented: $showCircles,
                friendsOnlineCount: friendsOnline,
                hasNotifications: hasNotifications
            )

            Spacer()

            // Optional title (center)
            if let title {
                Text(title)
                    .font(Veloce.Typography.title3)
                    .foregroundStyle(Veloce.Colors.textPrimary)
            }

            Spacer()

            // Balance spacer (right) - same width as pill
            Color.clear
                .frame(width: 80, height: 1)
        }
        .padding(.horizontal, Veloce.Spacing.screenPadding)
        .padding(.top, Veloce.Spacing.sm)
    }
}

// MARK: - Previews

#Preview("Circles Pill - Default") {
    ZStack {
        Veloce.Colors.voidBlack.ignoresSafeArea()

        VStack(spacing: 30) {
            CirclesPill(isPresented: .constant(false))

            CirclesPill(
                isPresented: .constant(false),
                friendsOnlineCount: 3
            )

            CirclesPill(
                isPresented: .constant(false),
                friendsOnlineCount: 12,
                hasNotifications: true
            )
        }
    }
}

#Preview("Circles Pill - Compact") {
    ZStack {
        Veloce.Colors.voidBlack.ignoresSafeArea()

        HStack(spacing: 20) {
            CirclesPillCompact(isPresented: .constant(false))
            CirclesPillCompact(isPresented: .constant(false), hasNotifications: true)
        }
    }
}

#Preview("Header with Pill") {
    ZStack {
        Veloce.Colors.voidBlack.ignoresSafeArea()

        VStack {
            CirclesPillHeader(
                showCircles: .constant(false),
                friendsOnline: 5,
                hasNotifications: true,
                title: "Tasks"
            )
            Spacer()
        }
    }
}
