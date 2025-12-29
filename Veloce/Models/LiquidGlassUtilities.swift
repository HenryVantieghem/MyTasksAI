//
//  LiquidGlassUtilities.swift
//  MyTasksAI
//
//  Reusable utilities for applying Liquid Glass throughout the app
//

import SwiftUI

// MARK: - View Extensions for Easy Glass Application

extension View {
    /// Apply standard card styling with Liquid Glass
    func glassCard(
        color: Color,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 18
    ) -> some View {
        self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.15),
                                color.opacity(0.10),
                                color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.4), radius: 12, y: 6)
            }
            .glassEffect(.regular.tint(color).interactive(), in: .rect(cornerRadius: cornerRadius))
    }
    
    /// Apply vibrant button styling with Liquid Glass
    func glassButton(
        colors: [Color],
        cornerRadius: CGFloat = 16,
        isEnabled: Bool = true
    ) -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: colors.first?.opacity(0.5) ?? .clear, radius: 12, y: 4)
            }
            .glassEffect(
                .regular.tint(colors.first ?? .blue).interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    /// Apply pill/tag styling with Liquid Glass
    func glassPill(
        color: Color,
        isSelected: Bool = false
    ) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isSelected 
                                ? [color, color.opacity(0.8)]
                                : [.white.opacity(0.1), .white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.5) : .clear,
                        radius: isSelected ? 12 : 0,
                        y: isSelected ? 4 : 0
                    )
            }
            .glassEffect(
                isSelected ? .regular.tint(color).interactive() : .regular,
                in: .capsule
            )
    }
    
    /// Apply badge styling with Liquid Glass
    func glassBadge(
        color: Color,
        cornerRadius: CGFloat = 12
    ) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.2),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .glassEffect(.regular.tint(color), in: .rect(cornerRadius: cornerRadius))
    }
    
    /// Apply gradient text
    func gradientText(
        colors: [Color] = [.white, .white.opacity(0.9)]
    ) -> some View {
        self
            .foregroundStyle(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Gradient Builders

extension LinearGradient {
    /// 3-color vibrant gradient
    static func vibrant(
        base: Color,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
        LinearGradient(
            colors: [
                base,
                base.opacity(0.8),
                base.opacity(0.6)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /// 2-color smooth gradient
    static func smooth(
        base: Color,
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) -> LinearGradient {
        LinearGradient(
            colors: [
                base,
                base.opacity(0.7)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    /// Category-based gradient
    static func forCategory(_ category: GoalCategory) -> LinearGradient {
        switch category {
        case .career:
            return vibrant(base: .blue)
        case .health:
            return vibrant(base: .green)
        case .personal:
            return vibrant(base: .purple)
        case .financial:
            return vibrant(base: .orange)
        case .education:
            return vibrant(base: .cyan)
        case .relationships:
            return vibrant(base: .pink)
        case .other:
            return vibrant(base: .gray)
        }
    }
    
    /// Timeframe-based gradient
    static func forTimeframe(_ timeframe: GoalTimeframe) -> LinearGradient {
        switch timeframe {
        case .sprint:
            return vibrant(base: Theme.Colors.aiCyan)
        case .milestone:
            return vibrant(base: Theme.Colors.aiBlue)
        case .horizon:
            return vibrant(base: Theme.Colors.aiPurple)
        }
    }
}

// MARK: - Reusable Glass Components

/// Standard section header with glass effect
struct GlassSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let color: Color
    let action: (() -> Void)?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        color: Color = Theme.Colors.aiPurple,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .gradientText(colors: [.white, .white.opacity(0.9)])
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(color)
                }
            }
        }
        .glassCard(color: color, cornerRadius: 18, padding: 16)
    }
}

/// Stat card with glass effect
struct GlassStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                
                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .gradientText()
            }
            
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .glassCard(color: color, cornerRadius: 18, padding: 18)
    }
}

/// Animated progress card with glass
struct GlassProgressCard: View {
    let title: String
    let progress: Double
    let color: Color
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(animatedProgress * 100))")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .gradientText(colors: [color, color.opacity(0.8)])
                    .contentTransition(.numericText())
                
                Text("%")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            GradientProgressBar(
                progress: animatedProgress,
                height: 12,
                cornerRadius: 6,
                colors: [color, color.opacity(0.7)]
            )
        }
        .glassCard(color: color, cornerRadius: 20, padding: 20)
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.3)) {
                animatedProgress = progress
            }
        }
    }
}

/// Action button with glass effect
struct GlassActionButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String,
        colors: [Color],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .glassButton(colors: colors)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

/// Container for multiple glass elements
struct GlassGroup<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

// MARK: - Example Usage in Views

struct GlassExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Section header
                GlassSectionHeader(
                    "Your Progress",
                    subtitle: "Keep up the great work!",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                ) {
                    print("Tapped header")
                }
                
                // Stats row
                GlassGroup(spacing: 12) {
                    HStack(spacing: 12) {
                        GlassStatCard(
                            icon: "target",
                            value: "12",
                            label: "Goals",
                            color: .blue
                        )
                        
                        GlassStatCard(
                            icon: "flame.fill",
                            value: "28",
                            label: "Streak",
                            color: .orange
                        )
                        
                        GlassStatCard(
                            icon: "checkmark.seal.fill",
                            value: "8",
                            label: "Done",
                            color: .green
                        )
                    }
                }
                
                // Progress card
                GlassProgressCard(
                    title: "Overall Progress",
                    progress: 0.67,
                    color: .purple
                )
                
                // Action button
                GlassActionButton(
                    "Create New Goal",
                    icon: "plus.circle.fill",
                    colors: [.purple, .purple.opacity(0.8), .blue.opacity(0.6)]
                ) {
                    print("Create goal")
                }
                
                // Pills
                HStack(spacing: 12) {
                    Text("Active")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .glassPill(color: .blue, isSelected: true)
                    
                    Text("Completed")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .glassPill(color: .green, isSelected: false)
                }
                
                // Badge
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                    Text("Premium")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .glassBadge(color: .orange)
            }
            .padding()
        }
        .background(Color.black)
    }
}

// MARK: - Quick Apply to Existing Views

/*
 TO UPDATE YOUR EXISTING VIEWS:
 
 1. Replace plain backgrounds with .glassCard():
    VStack { /* content */ }
        .glassCard(color: .blue)
 
 2. Replace plain buttons with .glassButton():
    Button("Action") { }
        .glassButton(colors: [.blue, .purple])
 
 3. Replace plain text with .gradientText():
    Text("Title")
        .font(.largeTitle)
        .gradientText()
 
 4. Wrap stats in GlassGroup:
    GlassGroup {
        HStack {
            GlassStatCard(...)
            GlassStatCard(...)
        }
    }
 
 5. Use GlassSectionHeader for sections:
    GlassSectionHeader("Section", subtitle: "Info", icon: "star", color: .blue)
 */

// MARK: - Preview

#Preview {
    GlassExamplesView()
}
