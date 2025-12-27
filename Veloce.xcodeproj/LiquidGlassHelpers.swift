//
//  LiquidGlassHelpers.swift
//  Veloce
//
//  Additional Liquid Glass Helper Views & Modifiers
//  Premium glass components for consistent design throughout the app
//

import SwiftUI

// MARK: - Glass Effect Variants

extension View {
    /// Premium glass card with rounded corners and shadows
    func premiumGlassCard(
        cornerRadius: CGFloat = 16,
        tint: Color? = nil,
        interactive: Bool = true
    ) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .if(tint != nil) { view in
                        view.overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(tint!)
                        )
                    }
            }
            .glassEffect(
                interactive ? .regular.interactive(true) : .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.35),
                                .white.opacity(0.18),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    /// Glass pill/capsule for buttons and chips
    func glassPill(
        tint: Color? = nil,
        interactive: Bool = true
    ) -> some View {
        self
            .glassEffect(
                interactive ? .regular.interactive(true) : .regular,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .if(tint != nil) { view in
                view.background(
                    Capsule()
                        .fill(tint!.opacity(0.08))
                )
            }
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
    
    /// Premium glass circle for avatars and badges
    func glassCircle(
        size: CGFloat = 44,
        tint: Color? = nil
    ) -> some View {
        self
            .frame(width: size, height: size)
            .glassEffect(
                .regular.interactive(true),
                in: Circle()
            )
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .if(tint != nil) { view in
                view.background(
                    Circle()
                        .fill(tint!.opacity(0.1))
                )
            }
    }
}

// MARK: - Premium Glass Button

/// Button with full Liquid Glass treatment
struct LiquidGlassButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        
        var tint: Color {
            switch self {
            case .primary: return Color(hex: "8B5CF6")
            case .secondary: return .blue
            case .destructive: return .red
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .primary:
                return LinearGradient(
                    colors: [
                        Color(hex: "8B5CF6"),
                        Color(hex: "6366F1")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                return LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .destructive:
                return LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background {
                Capsule()
                    .fill(style.gradient)
            }
            .glassEffect(
                .regular.interactive(true),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: style.tint.opacity(0.3),
                radius: 12,
                y: 6
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Glass Container

/// Container view with Liquid Glass that groups child glass effects
struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content()
        }
    }
}

// MARK: - Glass Section Header

/// Premium section header with glass background
struct GlassSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let action: (() -> Void)?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6"),
                                Color(hex: "06B6D4")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let action {
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .premiumGlassCard(cornerRadius: 14, interactive: action != nil)
    }
}

// MARK: - Glass Badge

/// Small glass badge for counts and indicators
struct GlassBadge: View {
    let value: String
    let color: Color
    
    init(_ value: String, color: Color = .blue) {
        self.value = value
        self.color = color
    }
    
    init(_ value: Int, color: Color = .blue) {
        self.value = "\(value)"
        self.color = color
    }
    
    var body: some View {
        Text(value)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(color)
            }
            .glassEffect(
                .regular,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        .white.opacity(0.3),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}

// MARK: - Glass Divider

/// Subtle glass divider line
struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.2),
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

// MARK: - Conditional Modifier Helper

extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension View {
    func previewInGlassContainer() -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0A0A0F"),
                    Color(hex: "1A1A2E")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            self
                .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

#Preview("Liquid Glass Button") {
    VStack(spacing: 20) {
        LiquidGlassButton("Continue", icon: "arrow.right", style: .primary) {
            print("Primary tapped")
        }
        
        LiquidGlassButton("Learn More", icon: "info.circle", style: .secondary) {
            print("Secondary tapped")
        }
        
        LiquidGlassButton("Delete", icon: "trash", style: .destructive) {
            print("Destructive tapped")
        }
    }
    .previewInGlassContainer()
}

#Preview("Glass Section Header") {
    VStack(spacing: 16) {
        GlassSectionHeader(
            "Recent Tasks",
            subtitle: "5 completed today",
            icon: "checkmark.circle.fill",
            action: { print("Tapped") }
        )
        
        GlassSectionHeader(
            "Achievements",
            icon: "star.fill"
        )
    }
    .previewInGlassContainer()
}

#Preview("Glass Badges") {
    HStack(spacing: 12) {
        GlassBadge("5", color: .blue)
        GlassBadge("New", color: .purple)
        GlassBadge("Pro", color: .orange)
        GlassBadge(99, color: .red)
    }
    .previewInGlassContainer()
}

#Preview("Glass Cards") {
    VStack(spacing: 20) {
        Text("Premium Card")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .premiumGlassCard(tint: Color(hex: "8B5CF6").opacity(0.1))
        
        Text("Standard Card")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .premiumGlassCard()
        
        Text("Non-interactive Card")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .premiumGlassCard(interactive: false)
    }
    .padding()
    .previewInGlassContainer()
}
