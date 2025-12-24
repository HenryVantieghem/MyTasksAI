//
//  CrystallineCard.swift
//  Veloce
//
//  Crystalline Card
//  Premium glass-morphic card with proper depth rendering on cosmic backgrounds.
//  Features inner shadows, clean borders, and aurora glow on selection.
//

import SwiftUI

// MARK: - Crystalline Card Modifier

struct CrystallineCardModifier: ViewModifier {
    let isSelected: Bool
    let accentColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat

    @State private var glowOpacity: Double = 0

    init(
        isSelected: Bool = false,
        accentColor: Color = Aurora.Colors.violet,
        cornerRadius: CGFloat = Aurora.Radius.card,
        padding: CGFloat = Aurora.Layout.cardPadding
    ) {
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(cardBackground)
            .overlay(cardBorder)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: glowShadowColor, radius: isSelected ? 16 : 8, y: 4)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(Aurora.Animation.spring, value: isSelected)
            .onChange(of: isSelected) { _, selected in
                withAnimation(Aurora.Animation.standard) {
                    glowOpacity = selected ? 0.5 : 0
                }
            }
            .onAppear {
                glowOpacity = isSelected ? 0.5 : 0
            }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base fill - proper glass on cosmic black
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Aurora.Colors.cosmicSurface)

            // Subtle gradient overlay for depth
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Aurora.Colors.glassBase,
                            Aurora.Colors.cosmicSurface.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Selection glow
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(accentColor.opacity(0.08))
            }

            // Inner shadow for depth (at top)
            VStack {
                LinearGradient(
                    colors: [
                        Aurora.Colors.glassInnerShadow,
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 2)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Inner highlight (at top-left)
            VStack {
                HStack {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                    .frame(width: 100, height: 60)
                    Spacer()
                }
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    // MARK: - Card Border

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(borderGradient, lineWidth: isSelected ? 1.5 : 1)
    }

    private var borderGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [
                    accentColor.opacity(0.6),
                    accentColor.opacity(0.3),
                    Aurora.Colors.glassBorder
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Aurora.Colors.glassHighlight.opacity(0.8),
                    Aurora.Colors.glassBorder,
                    Aurora.Colors.glassBorder.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var glowShadowColor: Color {
        isSelected ? accentColor.opacity(0.3) : Color.clear
    }
}

// MARK: - View Extension

extension View {
    /// Apply crystalline card styling
    func crystallineCard(
        isSelected: Bool = false,
        accentColor: Color = Aurora.Colors.violet,
        cornerRadius: CGFloat = Aurora.Radius.card,
        padding: CGFloat = Aurora.Layout.cardPadding
    ) -> some View {
        modifier(CrystallineCardModifier(
            isSelected: isSelected,
            accentColor: accentColor,
            cornerRadius: cornerRadius,
            padding: padding
        ))
    }
}

// MARK: - Crystalline Selection Card

/// A complete selection card with icon, title, and selection state
struct CrystallineSelectionCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed: Bool = false

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        accentColor: Color = Aurora.Colors.violet,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            action()
        } label: {
            HStack(spacing: Aurora.Layout.spacing) {
                // Icon circle
                iconCircle

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Aurora.Colors.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Aurora.Colors.textTertiary)
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .crystallineCard(isSelected: isSelected, accentColor: accentColor)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(Aurora.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var iconCircle: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(
                    isSelected
                        ? accentColor.opacity(0.2)
                        : Aurora.Colors.cosmicElevated
                )
                .frame(width: 48, height: 48)

            if isSelected {
                SwiftUI.Circle()
                    .stroke(accentColor.opacity(0.4), lineWidth: 1)
                    .frame(width: 48, height: 48)
            }

            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isSelected ? accentColor : Aurora.Colors.textSecondary)
        }
    }
}

// MARK: - Crystalline Feature Card

/// A card for displaying features/benefits
struct CrystallineFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color

    init(
        icon: String,
        title: String,
        description: String,
        accentColor: Color = Aurora.Colors.cyan
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(spacing: Aurora.Layout.spacing) {
            // Glowing icon
            ZStack {
                SwiftUI.Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .blur(radius: 4)

                SwiftUI.Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Aurora.Colors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Aurora.Colors.textTertiary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .crystallineCard(padding: Aurora.Layout.spacing)
    }
}

// MARK: - Preview

#Preview("Crystalline Cards") {
    VStack(spacing: 16) {
        Text("Selection Cards")
            .font(.headline)
            .foregroundStyle(.white)

        CrystallineSelectionCard(
            icon: "briefcase.fill",
            title: "Work",
            subtitle: "Career & professional tasks",
            isSelected: true,
            action: {}
        )

        CrystallineSelectionCard(
            icon: "heart.fill",
            title: "Health",
            subtitle: "Fitness & wellness goals",
            isSelected: false,
            accentColor: Aurora.Colors.rose,
            action: {}
        )

        Text("Feature Cards")
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.top)

        CrystallineFeatureCard(
            icon: "sparkles",
            title: "AI-Powered Insights",
            description: "Smart suggestions to boost your productivity"
        )

        CrystallineFeatureCard(
            icon: "bell.badge.fill",
            title: "Smart Reminders",
            description: "Never miss an important task",
            accentColor: Aurora.Colors.emerald
        )
    }
    .padding()
    .background(AuroraBackground.auth)
}

#Preview("Card States") {
    VStack(spacing: 20) {
        Text("Default")
            .crystallineCard()

        Text("Selected")
            .crystallineCard(isSelected: true)

        Text("Custom Color")
            .crystallineCard(isSelected: true, accentColor: Aurora.Colors.emerald)
    }
    .foregroundStyle(.white)
    .padding()
    .background(Aurora.Colors.cosmicBlack)
}
