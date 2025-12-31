//
//  LiquidGlassComponents.swift
//  MyTasksAI
//
//  🌊 Reusable Liquid Glass UI Components
//  Premium components using iOS 26 native Liquid Glass
//

import SwiftUI

// MARK: - Liquid Glass Container

/// GlassEffectContainer wrapper for multiple glass elements  
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
            // Fallback: simple Group container
            Group {
                content()
            }
        }
    }
}

// MARK: - Liquid Glass Pill

/// Compact pill/badge component with glass effect
struct LiquidGlassPill: View {
    let text: String
    var icon: String? = nil
    var color: Color = LiquidGlassDesignSystem.VibrantAccents.electricCyan

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 10, weight: .semibold)
            }
            Text(text)
                .dynamicTypeFont(base: 11, weight: .medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Cosmic Constellation Progress

struct CosmicConstellationProgress: View {
    let steps: [CosmicOnboardingStep]
    let currentStep: CosmicOnboardingStep
    let namespace: Namespace.ID
    
    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }
    
    private var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(currentIndex) / Double(steps.count - 1)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                Circle()
                    .fill(
                        index <= currentIndex ?
                        LiquidGlassDesignSystem.VibrantAccents.electricCyan :
                        Color.white.opacity(0.2)
                    )
                    .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
                    .overlay {
                        if index == currentIndex {
                            Circle()
                                .stroke(LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.3), lineWidth: 8)
                                .blur(radius: 4)
                        }
                    }
                    .animation(LiquidGlassDesignSystem.Springs.ui, value: currentIndex)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Liquid Glass Section Header

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
            // Leading orb indicator
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .blur(radius: 8)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, color, color.opacity(0.8)],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: 8
                        )
                    )
                    .frame(width: 8, height: 8)
            }
            
            // Title with icon
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .dynamicTypeFont(base: 16, weight: .semibold)
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(LiquidGlassDesignSystem.Typography.title3)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
            }
            
            Spacer()
            
            // Action button if provided
            if let action = action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .dynamicTypeFont(base: 12, weight: .semibold)
                        .foregroundStyle(LiquidGlassDesignSystem.Text.tertiary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LiquidGlassDesignSystem.Spacing.lg)
        .padding(.vertical, LiquidGlassDesignSystem.Spacing.md)
    }
}

// MARK: - Liquid Glass Progress Bar

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
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
                
                // Percentage text
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(LiquidGlassDesignSystem.Typography.caption2)
                        .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Liquid Glass Badge

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
                    .dynamicTypeFont(base: 10, weight: .semibold)
            }
            
            Text(text)
                .dynamicTypeFont(base: 11, weight: .semibold)
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

// MARK: - Liquid Glass Toggle Row

struct LiquidGlassToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .dynamicTypeFont(base: 22, weight: .medium)
                    .foregroundStyle(color)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LiquidGlassDesignSystem.Typography.bodyBold)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(LiquidGlassDesignSystem.Typography.caption)
                        .foregroundStyle(LiquidGlassDesignSystem.Text.secondary)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(LiquidGlassDesignSystem.Spacing.lg)
        .liquidContentCard(tint: isOn ? color : nil)
    }
}

// MARK: - Liquid Glass Action Row

struct LiquidGlassActionRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .dynamicTypeFont(base: 22, weight: .medium)
                        .foregroundStyle(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LiquidGlassDesignSystem.Typography.bodyBold)
                        .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(LiquidGlassDesignSystem.Typography.caption)
                            .foregroundStyle(LiquidGlassDesignSystem.Text.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .dynamicTypeFont(base: 14, weight: .semibold)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.tertiary)
            }
            .padding(LiquidGlassDesignSystem.Spacing.lg)
        }
        .buttonStyle(.plain)
        .liquidContentCard()
    }
}

// MARK: - Liquid Glass Empty State

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
            // Icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .dynamicTypeFont(base: 48, weight: .light)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.tertiary)
            }
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(LiquidGlassDesignSystem.Typography.title2)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                
                Text(message)
                    .font(LiquidGlassDesignSystem.Typography.body)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                LiquidGlassButton.primary(actionTitle, action: action)
                    .padding(.horizontal, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Liquid Glass Search Bar

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
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(LiquidGlassDesignSystem.Text.tertiary)
            
            TextField(placeholder, text: $text)
                .font(LiquidGlassDesignSystem.Typography.body)
                .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                .focused($isFocused)
                .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .dynamicTypeFont(base: 16)
                        .foregroundStyle(LiquidGlassDesignSystem.Text.tertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(LiquidGlassDesignSystem.Spacing.md)
        .frame(height: 44)
        .background {
            let shape = RoundedRectangle(cornerRadius: 12)
            let tintColor = isFocused ? LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.1) : Color.clear
            
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(
                        .regular.tint(tintColor),
                        in: shape
                    )
            } else {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if isFocused {
                        shape.fill(tintColor)
                    }
                }
            }
        }
        .animation(LiquidGlassDesignSystem.Springs.quick, value: isFocused)
        .animation(LiquidGlassDesignSystem.Springs.quick, value: text.isEmpty)
    }
}

// MARK: - Liquid Glass Floating Action Button

struct LiquidGlassFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .dynamicTypeFont(base: 22, weight: .semibold)
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
                .liquidGlow(
                    color: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                    radius: 24,
                    intensity: 0.6
                )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

// MARK: - Liquid Glass Alert

struct LiquidGlassAlert: View {
    let title: String
    let message: String
    let icon: String?
    let color: Color
    let primaryAction: (title: String, action: () -> Void)
    let secondaryAction: (title: String, action: () -> Void)?
    
    init(
        title: String,
        message: String,
        icon: String? = nil,
        color: Color = LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
        primaryAction: (title: String, action: () -> Void),
        secondaryAction: (title: String, action: () -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .dynamicTypeFont(base: 28, weight: .medium)
                        .foregroundStyle(color)
                }
            }
            
            // Content
            VStack(spacing: 8) {
                Text(title)
                    .font(LiquidGlassDesignSystem.Typography.title2)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(LiquidGlassDesignSystem.Typography.body)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Actions
            VStack(spacing: 12) {
                Button(primaryAction.title) {
                    primaryAction.action()
                }
                .font(LiquidGlassDesignSystem.Typography.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if let secondaryAction = secondaryAction {
                    Button(secondaryAction.title) {
                        secondaryAction.action()
                    }
                    .font(LiquidGlassDesignSystem.Typography.body)
                    .foregroundStyle(LiquidGlassDesignSystem.Text.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 340)
        .liquidElevatedCard(cornerRadius: 20)
    }
}

// MARK: - Liquid Glass Loading Spinner

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

// MARK: - Preview

#Preview("Liquid Glass Components") {
    ZStack {
        LiquidGlassDesignSystem.Void.cosmos
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 32) {
                // Section Header
                LiquidGlassSectionHeader(
                    "Tasks",
                    icon: "checkmark.circle.fill",
                    color: LiquidGlassDesignSystem.VibrantAccents.auroraGreen
                ) {
                    print("Header tapped")
                }
                
                // Action Row
                LiquidGlassActionRow(
                    title: "Settings",
                    subtitle: "Manage your preferences",
                    icon: "gear",
                    color: LiquidGlassDesignSystem.VibrantAccents.cosmicBlue
                ) {
                    print("Settings tapped")
                }
                .padding(.horizontal, 20)
                
                // Badges
                HStack(spacing: 8) {
                    LiquidGlassBadge("New", color: LiquidGlassDesignSystem.Semantic.success, icon: "sparkles")
                    LiquidGlassBadge("Pro", color: LiquidGlassDesignSystem.VibrantAccents.solarGold)
                    LiquidGlassBadge("3 tasks", color: LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Progress")
                        .font(LiquidGlassDesignSystem.Typography.caption)
                        .foregroundStyle(LiquidGlassDesignSystem.Text.secondary)
                    
                    LiquidGlassProgressBar(
                        progress: 0.65,
                        color: LiquidGlassDesignSystem.VibrantAccents.auroraGreen,
                        showPercentage: true
                    )
                }
                .padding(.horizontal, 20)
                
                // Loading Spinner
                LiquidGlassLoadingSpinner()
            }
            .padding(.vertical, 40)
        }
    }
}
