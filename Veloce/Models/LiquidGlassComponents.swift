//
//  LiquidGlassComponents.swift
//  MyTasksAI
//
//  Reusable UI Components with Native Liquid Glass
//  Pure Apple iOS 26 implementation
//

import SwiftUI

// MARK: - Liquid Glass Container (GlassEffectContainer Wrapper)

/// Use when you have multiple glass UI elements near each other for better performance
struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat = 40, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            Group {
                content()
            }
        }
    }
}

// MARK: - Liquid Glass Pill

/// Compact pill/badge component
struct LiquidGlassPill: View {
    let text: String
    var icon: String? = nil
    var color: Color = LiquidGlassDesignSystem.VibrantAccents.electricCyan

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Section Header

struct LiquidGlassSectionHeader: View {
    let title: String
    let icon: String?
    let color: Color
    let action: (() -> Void)?

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon indicator
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            // Title with icon
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Action button
            if let action = action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Progress Bar

struct LiquidGlassProgressBar: View {
    let progress: Double // 0.0 - 1.0
    let color: Color
    let showPercentage: Bool

    init(
        progress: Double,
        color: Color = LiquidGlassDesignSystem.VibrantAccents.electricCyan,
        showPercentage: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.showPercentage = showPercentage
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * progress)

                // Percentage
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Badge

struct LiquidGlassBadge: View {
    let text: String
    let color: Color
    let icon: String?

    init(
        _ text: String,
        color: Color = LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
        icon: String? = nil
    ) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
            }

            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(color.opacity(0.15))
                .overlay {
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - Toggle Row

struct LiquidGlassToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(16)
        .contentCard()
    }
}

// MARK: - Action Row

struct LiquidGlassActionRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .contentCard()
    }
}

// MARK: - Empty State

struct LiquidGlassEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                LiquidGlassButton.primary(actionTitle, action: action)
                    .padding(.horizontal, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Bar

struct LiquidGlassSearchBar: View {
    @Binding var text: String
    let placeholder: String

    @FocusState private var isFocused: Bool

    init(text: Binding<String>, placeholder: String = "Search") {
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.tertiary)

            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundStyle(.primary)
                .focused($isFocused)
                .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .frame(height: 44)
        .adaptiveGlass(cornerRadius: 12, interactive: false)
        .animation(.spring(response: 0.25), value: text.isEmpty)
    }
}

// MARK: - Loading Spinner

struct LiquidGlassLoadingSpinner: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                        LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                        .clear
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 32, height: 32)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Floating Action Button

struct LiquidGlassFloatingActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsService.shared.impact(.medium)
            action()
        }) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.4), radius: 16, y: 8)
        }
        .buttonStyle(.pressable)
    }
}

// MARK: - Preview

#Preview("Components") {
    ZStack {
        LiquidGlassDesignSystem.Void.cosmos
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                LiquidGlassSectionHeader(
                    "Tasks",
                    icon: "checkmark.circle.fill",
                    color: LiquidGlassDesignSystem.VibrantAccents.utopianGreen
                )

                LiquidGlassActionRow(
                    title: "Settings",
                    subtitle: "Manage preferences",
                    icon: "gear",
                    color: LiquidGlassDesignSystem.VibrantAccents.cosmicBlue
                ) { }
                .padding(.horizontal, 20)

                HStack(spacing: 8) {
                    LiquidGlassBadge("New", color: LiquidGlassDesignSystem.Semantic.success, icon: "sparkles")
                    LiquidGlassBadge("Pro", color: LiquidGlassDesignSystem.VibrantAccents.solarGold)
                }

                LiquidGlassProgressBar(progress: 0.65, showPercentage: true)
                    .padding(.horizontal, 20)

                LiquidGlassLoadingSpinner()
            }
            .padding(.vertical, 40)
        }
    }
    .preferredColorScheme(.dark)
}
