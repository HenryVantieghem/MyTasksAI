//
//  PowerUpInventory.swift
//  Veloce
//
//  Power-Up Inventory UI - Collectible Power-Ups Display
//  Shows available and active power-ups with cosmic effects
//  Allows activation with satisfying animations
//

import SwiftUI
import Combine

// MARK: - Power-Up Inventory View

struct PowerUpInventoryView: View {
    let powerUps: [PowerUp]
    var onActivate: ((PowerUp) -> Void)?

    @State private var selectedPowerUp: PowerUp?
    @State private var showActivationSheet = false
    @State private var glowPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var inventory: PowerUpInventory {
        PowerUpInventory(powerUps: powerUps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection

            // Active Power-Ups (if any)
            if !inventory.activePowerUps.isEmpty {
                activePowerUpsSection
            }

            // Inventory Grid
            inventoryGrid
        }
        .padding(20)
        .background(cardBackground)
        .sheet(isPresented: $showActivationSheet) {
            if let powerUp = selectedPowerUp {
                PowerUpActivationSheet(
                    powerUp: powerUp,
                    onActivate: {
                        onActivate?(powerUp)
                        showActivationSheet = false
                    }
                )
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            startAnimations()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.25, blue: 0.98),
                                Color(red: 0.42, green: 0.45, blue: 0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)

                Text("Power-Ups")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Total count badge
            Text("\(inventory.totalCount)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(red: 0.58, green: 0.25, blue: 0.98).opacity(0.3))
                )
        }
    }

    // MARK: - Active Power-Ups Section

    @ViewBuilder
    private var activePowerUpsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(1.5)

            ForEach(inventory.activePowerUps, id: \.id) { powerUp in
                ActivePowerUpRow(powerUp: powerUp, glowPhase: glowPhase)
            }
        }
    }

    // MARK: - Inventory Grid

    @ViewBuilder
    private var inventoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !inventory.activePowerUps.isEmpty {
                Text("INVENTORY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .tracking(1.5)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(PowerUpType.allCases, id: \.self) { type in
                    let powerUp = inventory.powerUp(of: type)
                    let quantity = powerUp?.quantity ?? 0
                    let isActive = powerUp?.isActive == true && !(powerUp?.isExpired ?? true)

                    PowerUpSlot(
                        type: type,
                        quantity: quantity,
                        isActive: isActive,
                        glowPhase: glowPhase
                    ) {
                        if let powerUp = powerUp, powerUp.canUse {
                            selectedPowerUp = powerUp
                            showActivationSheet = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 0.04, green: 0.04, blue: 0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }
    }
}

// MARK: - Active Power-Up Row

struct ActivePowerUpRow: View {
    let powerUp: PowerUp
    let glowPhase: Double

    @State private var timeRemaining: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var type: PowerUpType { powerUp.powerUpType }

    var body: some View {
        HStack(spacing: 12) {
            // Icon with glow
            ZStack {
                SwiftUI.Circle()
                    .fill(type.primaryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .blur(radius: 4)
                    .scaleEffect(1 + glowPhase * 0.1)

                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                type.primaryColor.opacity(0.8),
                                type.secondaryColor.opacity(0.4)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 22
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: type.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(type.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            // Timer
            VStack(alignment: .trailing, spacing: 2) {
                Text(powerUp.timeRemainingFormatted)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(type.primaryColor)

                Text("remaining")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(type.primaryColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(type.primaryColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onReceive(timer) { _ in
            timeRemaining = powerUp.timeRemaining
        }
    }
}

// MARK: - Power-Up Slot

struct PowerUpSlot: View {
    let type: PowerUpType
    let quantity: Int
    let isActive: Bool
    let glowPhase: Double
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    // Glow for available power-ups
                    if quantity > 0 && !isActive {
                        SwiftUI.Circle()
                            .fill(type.primaryColor.opacity(0.3 * type.rarity.glowIntensity))
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)
                            .scaleEffect(1 + glowPhase * 0.1)
                    }

                    // Background
                    SwiftUI.Circle()
                        .fill(
                            quantity > 0
                            ? LinearGradient(
                                colors: [type.primaryColor.opacity(0.3), type.secondaryColor.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 52, height: 52)
                        .overlay(
                            SwiftUI.Circle()
                                .stroke(
                                    quantity > 0
                                    ? type.primaryColor.opacity(0.4)
                                    : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )

                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            quantity > 0
                            ? type.primaryColor
                            : Color.white.opacity(0.2)
                        )

                    // Quantity badge
                    if quantity > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(quantity)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(
                                        SwiftUI.Circle()
                                            .fill(type.primaryColor)
                                    )
                            }
                            Spacer()
                        }
                        .frame(width: 52, height: 52)
                    }

                    // Active indicator
                    if isActive {
                        SwiftUI.Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [type.primaryColor, type.secondaryColor, type.primaryColor],
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(glowPhase * 360))
                    }
                }

                // Label
                Text(type.shortName)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        quantity > 0
                        ? Color.white.opacity(0.8)
                        : Color.white.opacity(0.3)
                    )
            }
        }
        .buttonStyle(PowerUpSlotButtonStyle())
        .disabled(quantity == 0 || isActive)
    }
}

struct PowerUpSlotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Power-Up Activation Sheet

struct PowerUpActivationSheet: View {
    let powerUp: PowerUp
    let onActivate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var glowPhase: Double = 0
    @State private var rotationAngle: Double = 0

    private var type: PowerUpType { powerUp.powerUpType }

    var body: some View {
        VStack(spacing: 24) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(10)
                        .background(SwiftUI.Circle().fill(Color.white.opacity(0.1)))
                }
            }

            Spacer()

            // Power-up visualization
            ZStack {
                // Outer rings
                ForEach(0..<3, id: \.self) { ring in
                    SwiftUI.Circle()
                        .stroke(
                            type.primaryColor.opacity(0.2 - Double(ring) * 0.05),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(120 + ring * 30), height: CGFloat(120 + ring * 30))
                        .scaleEffect(1 + glowPhase * 0.05 * Double(ring + 1))
                }

                // Rotating aura
                SwiftUI.Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                type.primaryColor.opacity(0.6),
                                type.secondaryColor.opacity(0.3),
                                Color.clear,
                                type.primaryColor.opacity(0.6)
                            ],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(rotationAngle))

                // Core glow
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                type.primaryColor.opacity(0.5),
                                type.secondaryColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 15)

                // Icon background
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [type.primaryColor, type.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: type.primaryColor.opacity(0.5), radius: 20)

                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Power-up info
            VStack(spacing: 8) {
                // Rarity badge
                Text(type.rarity.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(type.rarity.color)
                    .tracking(1.5)

                Text(type.displayName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(type.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Duration: \(type.durationText)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(type.primaryColor)
                .padding(.top, 8)
            }

            Spacer()

            // Activate button
            Button {
                HapticsService.shared.impact(.heavy)
                onActivate()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))

                    Text("ACTIVATE")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [type.primaryColor, type.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: type.primaryColor.opacity(0.5), radius: 15)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Compact Power-Up Badge (for showing in other views)

struct CompactPowerUpBadge: View {
    let type: PowerUpType
    let quantity: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: type.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isActive ? type.primaryColor : .white.opacity(0.6))

            if isActive {
                Text("ACTIVE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(type.primaryColor)
            } else {
                Text("×\(quantity)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    isActive
                    ? type.primaryColor.opacity(0.2)
                    : Color.white.opacity(0.08)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isActive
                            ? type.primaryColor.opacity(0.4)
                            : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                PowerUpInventoryView(powerUps: PowerUp.allPreviews)

                // With active power-up
                PowerUpInventoryView(powerUps: [
                    PowerUp.activeXPBoostPreview,
                    PowerUp.streakShieldPreview
                ])

                // Compact badges
                HStack(spacing: 8) {
                    CompactPowerUpBadge(type: .xpBoost, quantity: 2, isActive: false)
                    CompactPowerUpBadge(type: .streakShield, quantity: 1, isActive: true)
                    CompactPowerUpBadge(type: .comboKeeper, quantity: 0, isActive: false)
                }
            }
            .padding()
        }
    }
}
