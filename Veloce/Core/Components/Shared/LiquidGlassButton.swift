//
//  LiquidGlassButton.swift
//  Veloce
//
//  Ultra-Premium Liquid Glass Button Component
//  Features native iOS 26 glass effects with graceful fallbacks,
//  animated gradients, shimmer effects, and premium haptics.
//

import SwiftUI

// MARK: - Liquid Glass Button

struct LiquidGlassButton: View {
    let title: String
    let style: LiquidGlassButtonStyle
    let icon: String?
    let iconPosition: IconPosition
    let isLoading: Bool
    let isEnabled: Bool
    let fullWidth: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var glowPulse: Double = 0
    @State private var borderRotation: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum IconPosition {
        case leading
        case trailing
    }

    init(
        _ title: String,
        style: LiquidGlassButtonStyle = .primary,
        icon: String? = nil,
        iconPosition: IconPosition = .trailing,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            triggerHaptic()
            action()
        } label: {
            buttonContent
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(LiquidGlassDesignSystem.Springs.press, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && isEnabled && !isLoading {
                        isPressed = true
                        HapticsService.shared.lightImpact()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Button Content

    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: 10) {
            if iconPosition == .leading, let icon = icon {
                iconView(systemName: icon)
            }

            if isLoading {
                loadingIndicator
            } else {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(0.5)
            }

            if iconPosition == .trailing, let icon = icon, !isLoading {
                iconView(systemName: icon)
            }
        }
        .foregroundStyle(textColor)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(height: LiquidGlassDesignSystem.Sizing.buttonHeight)
        .padding(.horizontal, 24)
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.buttonCornerRadius))
        .overlay(buttonBorder)
        .overlay(shimmerOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        .opacity(isEnabled ? 1 : 0.5)
    }

    // MARK: - Icon View

    @ViewBuilder
    private func iconView(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(textColor)
    }

    // MARK: - Loading Indicator

    @ViewBuilder
    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                .scaleEffect(0.85)

            Text("Loading...")
                .font(.system(size: 16, weight: .medium))
        }
    }

    // MARK: - Background (iOS 26 Native Liquid Glass)

    @ViewBuilder
    private var buttonBackground: some View {
        let cornerRadius = LiquidGlassDesignSystem.Sizing.buttonCornerRadius
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        
        switch style {
        case .primary:
            // iOS 26: Use native Liquid Glass with gradient tint
            if #available(iOS 26.0, *) {
                ZStack {
                    // Base gradient
                    shape.fill(LiquidGlassDesignSystem.Gradients.ctaPrimary)
                    
                    // Native glass overlay with interactive response
                    Color.clear
                        .glassEffect(
                            .regular
                                .tint(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.3))
                                .interactive(true),
                            in: shape
                        )
                    
                    // Glow overlay on press
                    if isPressed {
                        shape.fill(Color.white.opacity(0.15))
                    }
                }
            } else {
                ZStack {
                    shape.fill(LiquidGlassDesignSystem.Gradients.ctaPrimary)
                    shape.fill(.ultraThinMaterial.opacity(0.3))
                    
                    if isPressed {
                        shape.fill(Color.white.opacity(0.15))
                    }
                }
            }

        case .secondary:
            // iOS 26: Pure native interactive glass
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(
                        .regular
                            .tint(LiquidGlassDesignSystem.GlassTints.interactive.opacity(0.2))
                            .interactive(true),
                        in: shape
                    )
            } else {
                shape
                    .fill(.ultraThinMaterial)
                    .background(shape.fill(LiquidGlassDesignSystem.GlassTints.interactive.opacity(0.1)))
            }

        case .ghost:
            if isPressed {
                if #available(iOS 26.0, *) {
                    Color.clear
                        .glassEffect(.regular.interactive(true), in: shape)
                } else {
                    shape.fill(.ultraThinMaterial.opacity(0.5))
                }
            } else {
                Color.clear
            }

        case .success:
            // iOS 26: Glass over gradient
            if #available(iOS 26.0, *) {
                ZStack {
                    shape.fill(LiquidGlassDesignSystem.Gradients.success)
                    
                    Color.clear
                        .glassEffect(
                            .regular.tint(LiquidGlassDesignSystem.Semantic.success.opacity(0.2)),
                            in: shape
                        )
                }
            } else {
                ZStack {
                    shape.fill(LiquidGlassDesignSystem.Gradients.success)
                    shape.fill(.ultraThinMaterial.opacity(0.25))
                }
            }

        case .destructive:
            // iOS 26: Glass over red gradient
            if #available(iOS 26.0, *) {
                ZStack {
                    shape.fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    Color.clear
                        .glassEffect(
                            .regular.tint(Color.red.opacity(0.2)),
                            in: shape
                        )
                }
            } else {
                ZStack {
                    shape.fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    shape.fill(.ultraThinMaterial.opacity(0.2))
                }
            }
        }
    }

    // MARK: - Border

    @ViewBuilder
    private var buttonBorder: some View {
        switch style {
        case .primary, .success:
            // Subtle inner highlight
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.buttonCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )

        case .secondary:
            // Prismatic animated border
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.buttonCornerRadius)
                .stroke(
                    AngularGradient(
                        colors: [
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                            LiquidGlassDesignSystem.VibrantAccents.nebulaPink,
                            LiquidGlassDesignSystem.VibrantAccents.electricCyan
                        ],
                        center: .center,
                        startAngle: .degrees(borderRotation),
                        endAngle: .degrees(borderRotation + 360)
                    ),
                    lineWidth: isPressed ? 1.5 : 1.0
                )

        case .ghost:
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.buttonCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPressed ? 0.4 : 0.2),
                            Color.white.opacity(isPressed ? 0.2 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )

        case .destructive:
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.buttonCornerRadius)
                .stroke(
                    Color.red.opacity(0.5),
                    lineWidth: 0.75
                )
        }
    }

    // MARK: - Shimmer Overlay

    @ViewBuilder
    private var shimmerOverlay: some View {
        if style == .primary && !reduceMotion && isEnabled {
            RoundedRectangle(cornerRadius: LiquidGlassDesignSystem.Sizing.buttonCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: shimmerOffset - 0.3, y: 0.5),
                        endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
                    )
                )
                .allowsHitTesting(false)
        }
    }

    // MARK: - Colors

    private var textColor: Color {
        switch style {
        case .primary, .success, .destructive:
            return .white
        case .secondary:
            return LiquidGlassDesignSystem.VibrantAccents.stellarWhite
        case .ghost:
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        }
    }

    private var shadowColor: Color {
        guard isEnabled else { return .clear }

        switch style {
        case .primary:
            return LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(isPressed ? 0.5 : 0.3)
        case .secondary:
            return LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(isPressed ? 0.4 : 0.2)
        case .ghost:
            return .clear
        case .success:
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen.opacity(isPressed ? 0.5 : 0.3)
        case .destructive:
            return Color.red.opacity(isPressed ? 0.4 : 0.2)
        }
    }

    private var shadowRadius: CGFloat {
        isPressed ? 24 : 16
    }

    private var shadowY: CGFloat {
        isPressed ? 4 : 8
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }

        // Shimmer animation for primary buttons
        if style == .primary {
            withAnimation(
                .linear(duration: LiquidGlassDesignSystem.MorphAnimation.shimmerSweep)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2.0
            }
        }

        // Border rotation for secondary buttons
        if style == .secondary {
            withAnimation(
                .linear(duration: LiquidGlassDesignSystem.MorphAnimation.prismaticRotation)
                .repeatForever(autoreverses: false)
            ) {
                borderRotation = 360
            }
        }

        // Glow pulse for success buttons
        if style == .success {
            withAnimation(
                .easeInOut(duration: LiquidGlassDesignSystem.MorphAnimation.glowPulse)
                .repeatForever(autoreverses: true)
            ) {
                glowPulse = 1
            }
        }
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        switch style {
        case .primary:
            HapticsService.shared.premiumButtonPress()
        case .secondary:
            HapticsService.shared.impact(.medium)
        case .ghost:
            HapticsService.shared.lightImpact()
        case .success:
            HapticsService.shared.successConfirm()
        case .destructive:
            HapticsService.shared.impact(.rigid)
        }
    }
}

// MARK: - Convenience Initializers

extension LiquidGlassButton {
    /// Primary CTA button
    static func primary(
        _ title: String,
        icon: String? = "arrow.right",
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .primary,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Secondary button with prismatic border
    static func secondary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .secondary,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Ghost button (minimal style)
    static func ghost(
        _ title: String,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .ghost,
            icon: icon,
            iconPosition: iconPosition,
            fullWidth: false,
            action: action
        )
    }

    /// Success button (for completion actions)
    static func success(
        _ title: String,
        icon: String? = "checkmark",
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> LiquidGlassButton {
        LiquidGlassButton(
            title,
            style: .success,
            icon: icon,
            isLoading: isLoading,
            action: action
        )
    }
}

// MARK: - Small Button Variant

struct LiquidGlassButtonSmall: View {
    let title: String
    let style: LiquidGlassButtonStyle
    let icon: String?
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        style: LiquidGlassButtonStyle = .secondary,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(style == .ghost ? LiquidGlassDesignSystem.VibrantAccents.electricCyan : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(smallButtonBackground)
            .clipShape(Capsule())
            .overlay(smallButtonBorder)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(LiquidGlassDesignSystem.Springs.press, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var smallButtonBackground: some View {
        switch style {
        case .primary:
            if #available(iOS 26.0, *) {
                ZStack {
                    Capsule().fill(LiquidGlassDesignSystem.Gradients.ctaPrimary)
                    Color.clear.glassEffect(.regular.tint(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.2)), in: Capsule())
                }
            } else {
                Capsule().fill(LiquidGlassDesignSystem.Gradients.ctaPrimary)
            }
            
        case .secondary:
            if #available(iOS 26.0, *) {
                Color.clear.glassEffect(.regular.interactive(true), in: Capsule())
            } else {
                Capsule().fill(.ultraThinMaterial)
            }
            
        case .ghost:
            Color.clear
            
        case .success:
            if #available(iOS 26.0, *) {
                ZStack {
                    Capsule().fill(LiquidGlassDesignSystem.Gradients.success)
                    Color.clear.glassEffect(.regular.tint(LiquidGlassDesignSystem.Semantic.success.opacity(0.15)), in: Capsule())
                }
            } else {
                Capsule().fill(LiquidGlassDesignSystem.Gradients.success)
            }
            
        case .destructive:
            if #available(iOS 26.0, *) {
                ZStack {
                    Capsule().fill(Color.red.opacity(0.7))
                    Color.clear.glassEffect(.regular.tint(Color.red.opacity(0.15)), in: Capsule())
                }
            } else {
                Capsule().fill(Color.red.opacity(0.7))
            }
        }
    }

    @ViewBuilder
    private var smallButtonBorder: some View {
        Capsule()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(style == .ghost ? 0.3 : 0.2),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - Icon-Only Button

struct LiquidGlassIconButton: View {
    let icon: String
    let size: CGFloat
    let tint: Color?
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        size: CGFloat = 44,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(tint ?? .white)
                .frame(width: size, height: size)
        }
        .buttonStyle(PlainButtonStyle())
        .background {
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(
                        .regular
                            .tint((tint ?? LiquidGlassDesignSystem.VibrantAccents.electricCyan).opacity(0.15))
                            .interactive(true),
                        in: Circle()
                    )
            } else {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if let tint = tint {
                            Circle().fill(tint.opacity(0.1))
                        }
                    }
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(LiquidGlassDesignSystem.Springs.press, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    ZStack {
        Theme.CelestialColors.voidDeep
            .ignoresSafeArea()

        VStack(spacing: 24) {
            Text("Liquid Glass Buttons")
                .font(.title2.bold())
                .foregroundStyle(.white)

            LiquidGlassButton.primary("Get Started") {
                print("Primary tapped")
            }

            LiquidGlassButton.secondary("Learn More", icon: "info.circle") {
                print("Secondary tapped")
            }

            LiquidGlassButton.success("Complete Setup", icon: "checkmark.circle") {
                print("Success tapped")
            }

            LiquidGlassButton(
                "Delete Account",
                style: .destructive,
                icon: "trash",
                iconPosition: .leading
            ) {
                print("Destructive tapped")
            }

            HStack(spacing: 16) {
                LiquidGlassButton.ghost("Back", icon: "arrow.left", iconPosition: .leading) {
                    print("Ghost tapped")
                }

                Spacer()

                LiquidGlassButtonSmall("Skip", icon: "forward") {
                    print("Small tapped")
                }
            }

            HStack(spacing: 16) {
                LiquidGlassIconButton(icon: "xmark") {
                    print("Close tapped")
                }

                LiquidGlassIconButton(icon: "heart.fill", tint: .pink) {
                    print("Heart tapped")
                }

                LiquidGlassIconButton(icon: "plus", tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan) {
                    print("Add tapped")
                }
            }
        }
        .padding()
    }
}

#Preview("Loading State") {
    ZStack {
        Theme.CelestialColors.voidDeep
            .ignoresSafeArea()

        VStack(spacing: 24) {
            LiquidGlassButton(
                "Creating Account...",
                style: .primary,
                isLoading: true
            ) {}

            LiquidGlassButton(
                "Disabled Button",
                style: .primary,
                isEnabled: false
            ) {}
        }
        .padding()
    }
}
