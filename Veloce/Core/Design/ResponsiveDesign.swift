//
//  ResponsiveDesign.swift
//  Veloce
//
//  Responsive Design System
//  Ensures proper rendering across all iPhone and iPad sizes
//

import SwiftUI

// MARK: - Device Type

enum DeviceType {
    case iPhoneSE        // 375pt width
    case iPhoneStandard  // 390pt width (iPhone 14, 15)
    case iPhoneProMax    // 430pt width (iPhone Pro Max)
    case iPadMini        // 744pt width
    case iPad            // 820pt width (iPad Air, 10th gen)
    case iPadPro11       // 834pt width
    case iPadPro13       // 1024pt width

    static func current(for width: CGFloat) -> DeviceType {
        switch width {
        case ..<380: return .iPhoneSE
        case 380..<420: return .iPhoneStandard
        case 420..<700: return .iPhoneProMax
        case 700..<800: return .iPadMini
        case 800..<900: return .iPad
        case 900..<1000: return .iPadPro11
        default: return .iPadPro13
        }
    }

    var isPhone: Bool {
        switch self {
        case .iPhoneSE, .iPhoneStandard, .iPhoneProMax:
            return true
        default:
            return false
        }
    }

    var isTablet: Bool { !isPhone }

    var isCompact: Bool { self == .iPhoneSE }
}

// MARK: - Responsive Layout

struct ResponsiveLayout {
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?

    var deviceType: DeviceType {
        DeviceType.current(for: screenWidth)
    }

    var isLandscape: Bool {
        screenWidth > screenHeight
    }

    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var isRegular: Bool {
        horizontalSizeClass == .regular
    }

    // MARK: - Adaptive Values

    var columns: Int {
        if isRegular && deviceType.isTablet {
            return isLandscape ? 3 : 2
        }
        return 1
    }

    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }

    var spacing: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 12
        case .iPhoneStandard, .iPhoneProMax: return 16
        case .iPadMini, .iPad: return 20
        case .iPadPro11, .iPadPro13: return 24
        }
    }

    var screenPadding: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 16
        case .iPhoneStandard, .iPhoneProMax: return 20
        case .iPadMini, .iPad: return 32
        case .iPadPro11, .iPadPro13: return 48
        }
    }

    var cardPadding: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 12
        case .iPhoneStandard, .iPhoneProMax: return 16
        case .iPadMini, .iPad, .iPadPro11, .iPadPro13: return 20
        }
    }

    var maxContentWidth: CGFloat {
        switch deviceType {
        case .iPhoneSE, .iPhoneStandard, .iPhoneProMax:
            return .infinity
        case .iPadMini:
            return 600
        case .iPad, .iPadPro11:
            return 700
        case .iPadPro13:
            return 800
        }
    }

    var titleFontSize: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 28
        case .iPhoneStandard, .iPhoneProMax: return 32
        case .iPadMini, .iPad: return 36
        case .iPadPro11, .iPadPro13: return 40
        }
    }

    var bodyFontSize: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 15
        case .iPhoneStandard, .iPhoneProMax: return 16
        case .iPadMini, .iPad, .iPadPro11, .iPadPro13: return 17
        }
    }

    var taskRowHeight: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 64
        case .iPhoneStandard, .iPhoneProMax: return 72
        case .iPadMini, .iPad, .iPadPro11, .iPadPro13: return 80
        }
    }

    var fabSize: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 52
        case .iPhoneStandard, .iPhoneProMax: return 56
        case .iPadMini, .iPad, .iPadPro11, .iPadPro13: return 64
        }
    }

    var orbSize: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 100
        case .iPhoneStandard, .iPhoneProMax: return 120
        case .iPadMini, .iPad: return 140
        case .iPadPro11, .iPadPro13: return 160
        }
    }

    // MARK: - Safe Area & Layout Offsets

    var headerHeight: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 44
        case .iPhoneStandard, .iPhoneProMax: return 48
        case .iPadMini, .iPad: return 52
        case .iPadPro11, .iPadPro13: return 60
        }
    }

    var tabBarHeight: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 60
        case .iPhoneStandard, .iPhoneProMax: return 68
        case .iPadMini, .iPad: return 76
        case .iPadPro11, .iPadPro13: return 80
        }
    }

    /// Total bottom clearance including tab bar and safe area
    var bottomSafeArea: CGFloat {
        tabBarHeight + (deviceType.isPhone ? 34 : 20) // Home indicator
    }

    // MARK: - Touch Targets (Apple HIG: 44pt minimum)

    var minTouchTarget: CGFloat {
        deviceType.isTablet ? 48 : 44
    }

    var buttonHeight: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 48
        case .iPhoneStandard, .iPhoneProMax: return 50
        case .iPadMini, .iPad: return 52
        case .iPadPro11, .iPadPro13: return 56
        }
    }

    // MARK: - Icon Sizes

    var iconSizeSmall: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 16
        case .iPhoneStandard, .iPhoneProMax: return 18
        case .iPadMini, .iPad, .iPadPro11, .iPadPro13: return 20
        }
    }

    var iconSizeMedium: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 22
        case .iPhoneStandard, .iPhoneProMax: return 24
        case .iPadMini, .iPad: return 28
        case .iPadPro11, .iPadPro13: return 32
        }
    }

    var iconSizeLarge: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 28
        case .iPhoneStandard, .iPhoneProMax: return 32
        case .iPadMini, .iPad: return 36
        case .iPadPro11, .iPadPro13: return 40
        }
    }

    // MARK: - Tab Bar Scaling (iPad-optimized)

    var tabItemWidth: CGFloat {
        switch deviceType {
        case .iPhoneSE, .iPhoneStandard: return 48
        case .iPhoneProMax: return 52
        case .iPadMini, .iPad: return 60
        case .iPadPro11, .iPadPro13: return 68
        }
    }

    var tabBarSpacing: CGFloat {
        deviceType.isTablet ? 32 : 16
    }

    var tabIconSize: CGFloat {
        switch deviceType {
        case .iPhoneSE, .iPhoneStandard, .iPhoneProMax: return 24
        case .iPadMini, .iPad: return 28
        case .iPadPro11, .iPadPro13: return 32
        }
    }

    // MARK: - Landscape Support

    var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }

    var landscapeColumns: Int {
        if isLandscape {
            switch deviceType {
            case .iPhoneSE, .iPhoneStandard, .iPhoneProMax: return 2
            case .iPadMini, .iPad: return 3
            case .iPadPro11, .iPadPro13: return 4
            }
        }
        return columns
    }

    var landscapeSpacing: CGFloat {
        isLandscape ? spacing * 0.8 : spacing
    }

    var landscapeHeaderHeight: CGFloat {
        isCompactHeight ? headerHeight * 0.75 : headerHeight
    }

    // MARK: - Font Scaling Factor (for device-aware scaling)

    var fontScale: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 0.9
        case .iPhoneStandard, .iPhoneProMax: return 1.0
        case .iPadMini, .iPad: return 1.1
        case .iPadPro11, .iPadPro13: return 1.15
        }
    }

    // MARK: - Onboarding-specific sizes

    var portalOrbSize: CGFloat {
        orbSize * 2.5 // Scales from 250pt (SE) to 400pt (iPad Pro)
    }

    var onboardingIconSize: CGFloat {
        switch deviceType {
        case .iPhoneSE: return 70
        case .iPhoneStandard, .iPhoneProMax: return 80
        case .iPadMini, .iPad: return 100
        case .iPadPro11, .iPadPro13: return 120
        }
    }
}

// MARK: - Environment Key

private struct ResponsiveLayoutKey: EnvironmentKey {
    static let defaultValue = ResponsiveLayout(
        screenWidth: 390,
        screenHeight: 844,
        horizontalSizeClass: .compact,
        verticalSizeClass: .regular
    )
}

extension EnvironmentValues {
    var responsiveLayout: ResponsiveLayout {
        get { self[ResponsiveLayoutKey.self] }
        set { self[ResponsiveLayoutKey.self] = newValue }
    }
}

// MARK: - Responsive Container

struct ResponsiveContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let content: (ResponsiveLayout) -> Content

    init(@ViewBuilder content: @escaping (ResponsiveLayout) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = ResponsiveLayout(
                screenWidth: geometry.size.width,
                screenHeight: geometry.size.height,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            )

            content(layout)
                .environment(\.responsiveLayout, layout)
        }
    }
}

// MARK: - Adaptive Modifiers

extension View {
    /// Apply responsive padding based on device
    func responsivePadding() -> some View {
        modifier(ResponsivePaddingModifier())
    }

    /// Constrain content to max width on tablets
    func maxWidthConstrained() -> some View {
        modifier(MaxWidthConstrainedModifier())
    }

    /// Adaptive font size
    func adaptiveFont(base: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(AdaptiveFontModifier(baseSize: base, weight: weight))
    }

    /// Hide on compact devices
    func hideOnCompact() -> some View {
        modifier(HideOnCompactModifier())
    }

    /// Show only on tablets
    func tabletOnly() -> some View {
        modifier(TabletOnlyModifier())
    }

    /// Dynamic Type aware font that scales with accessibility settings AND device size
    func dynamicTypeFont(base: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(DynamicTypeFontModifier(baseSize: base, weight: weight, design: design))
    }

    /// Responsive frame that scales with device size
    func responsiveFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        modifier(ResponsiveFrameModifier(baseWidth: width, baseHeight: height))
    }

    /// Responsive spacing for VStack/HStack
    func responsiveSpacing() -> some View {
        modifier(ResponsiveSpacingModifier())
    }

    /// Apply hover effect for iPad pointer support
    func iPadHoverEffect(_ style: HoverEffectStyle = .lift) -> some View {
        modifier(iPadHoverEffectModifier(style: style))
    }
}

// MARK: - Modifiers

struct ResponsivePaddingModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout

    func body(content: Content) -> some View {
        content.padding(.horizontal, layout.screenPadding)
    }
}

struct MaxWidthConstrainedModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: layout.maxContentWidth)
            .frame(maxWidth: .infinity)
    }
}

struct AdaptiveFontModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout
    let baseSize: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        let scale: CGFloat = {
            switch layout.deviceType {
            case .iPhoneSE: return 0.9
            case .iPhoneStandard, .iPhoneProMax: return 1.0
            case .iPadMini, .iPad: return 1.1
            case .iPadPro11, .iPadPro13: return 1.15
            }
        }()

        content.font(.system(size: baseSize * scale, weight: weight))
    }
}

struct HideOnCompactModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout

    func body(content: Content) -> some View {
        if layout.deviceType.isCompact {
            EmptyView()
        } else {
            content
        }
    }
}

struct TabletOnlyModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout

    func body(content: Content) -> some View {
        if layout.deviceType.isTablet {
            content
        } else {
            EmptyView()
        }
    }
}

/// Dynamic Type font modifier - scales with BOTH device size AND accessibility settings
struct DynamicTypeFontModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var accessibilityScale: CGFloat = 1.0

    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        // Combine device scaling with accessibility scaling
        let deviceScale = layout.fontScale
        let finalSize = baseSize * deviceScale * accessibilityScale

        content.font(.system(size: finalSize, weight: weight, design: design))
    }
}

/// Responsive frame modifier - scales dimensions with device size
struct ResponsiveFrameModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout

    let baseWidth: CGFloat?
    let baseHeight: CGFloat?

    func body(content: Content) -> some View {
        let scale = layout.fontScale // Reuse font scale for consistent sizing
        let scaledWidth = baseWidth.map { $0 * scale }
        let scaledHeight = baseHeight.map { $0 * scale }

        content.frame(width: scaledWidth, height: scaledHeight)
    }
}

/// Responsive spacing modifier - applies device-aware spacing
struct ResponsiveSpacingModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout

    func body(content: Content) -> some View {
        content
            .environment(\.defaultMinListRowHeight, layout.taskRowHeight)
    }
}

/// Enum for hover effect styles
enum HoverEffectStyle {
    case lift
    case highlight
    case automatic
}

/// iPad hover effect modifier for pointer support
struct iPadHoverEffectModifier: ViewModifier {
    @Environment(\.responsiveLayout) private var layout
    let style: HoverEffectStyle

    @State private var isHovered = false

    func body(content: Content) -> some View {
        if layout.deviceType.isTablet {
            content
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
                .scaleEffect(isHovered && style == .lift ? 1.02 : 1.0)
                .brightness(isHovered && style == .highlight ? 0.05 : 0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        } else {
            content
        }
    }
}

// MARK: - Responsive Grid

struct ResponsiveGrid<Item: Identifiable, Content: View>: View {
    @Environment(\.responsiveLayout) private var layout

    let items: [Item]
    let content: (Item) -> Content

    init(_ items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: layout.gridColumns, spacing: layout.spacing) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

// MARK: - Preview

private struct ResponsivePreviewContent: View {
    let layout: ResponsiveLayout

    var body: some View {
        VStack(spacing: layout.spacing) {
            Text("Device: \(String(describing: layout.deviceType))")
                .dynamicTypeFont(base: 16, weight: .bold)

            Text("Width: \(Int(layout.screenWidth))pt")
                .dynamicTypeFont(base: 14, weight: .regular)

            Text("Columns: \(layout.columns)")
                .dynamicTypeFont(base: 14, weight: .regular)

            HStack(spacing: layout.spacing) {
                Text("Header: \(Int(layout.headerHeight))")
                Text("TabBar: \(Int(layout.tabBarHeight))")
            }
            .dynamicTypeFont(base: 12, weight: .light)

            // Test button with responsive sizing
            Text("Test Button")
                .dynamicTypeFont(base: 16, weight: .semibold)
                .frame(height: layout.buttonHeight)
                .frame(maxWidth: 200)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .responsivePadding()
    }
}

#Preview("iPhone SE") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 375, height: 667)
}

#Preview("iPhone 15") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 390, height: 844)
}

#Preview("iPhone 15 Pro Max") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 430, height: 932)
}

#Preview("iPad mini") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 744, height: 1133)
}

#Preview("iPad Air") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 820, height: 1180)
}

#Preview("iPad Pro 11\"") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 834, height: 1194)
}

#Preview("iPad Pro 13\"") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 1024, height: 1366)
}

#Preview("iPad Pro 13\" Landscape") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 1366, height: 1024)
}

#Preview("iPhone 15 Landscape") {
    ResponsiveContainer { layout in
        ResponsivePreviewContent(layout: layout)
    }
    .frame(width: 844, height: 390)
}

// MARK: - Dynamic Type Testing Previews

private struct DynamicTypeTestContent: View {
    @Environment(\.responsiveLayout) private var layout
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: layout.spacing) {
            Text("Dynamic Type: \(String(describing: dynamicTypeSize))")
                .dynamicTypeFont(base: 14, weight: .bold)

            Text("Title Text")
                .dynamicTypeFont(base: 24, weight: .bold)

            Text("Body text that demonstrates how Dynamic Type scales with accessibility settings for users who need larger text.")
                .dynamicTypeFont(base: 16, weight: .regular)
                .multilineTextAlignment(.center)

            HStack(spacing: layout.spacing) {
                Text("Button")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .frame(height: layout.buttonHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                Text("Button")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .frame(height: layout.buttonHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .responsivePadding()
    }
}

#Preview("Dynamic Type - Default") {
    ResponsiveContainer { _ in
        DynamicTypeTestContent()
    }
    .frame(width: 390, height: 844)
}

#Preview("Dynamic Type - Large") {
    ResponsiveContainer { _ in
        DynamicTypeTestContent()
    }
    .frame(width: 390, height: 844)
    .dynamicTypeSize(.large)
}

#Preview("Dynamic Type - XXL") {
    ResponsiveContainer { _ in
        DynamicTypeTestContent()
    }
    .frame(width: 390, height: 844)
    .dynamicTypeSize(.xxLarge)
}

#Preview("Dynamic Type - AX3") {
    ResponsiveContainer { _ in
        DynamicTypeTestContent()
    }
    .frame(width: 390, height: 844)
    .dynamicTypeSize(.accessibility3)
}

// MARK: - Device Comparison Grid

private struct DeviceComparisonGrid: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 20) {
                DevicePreviewCard(name: "iPhone SE", width: 375, height: 667)
                DevicePreviewCard(name: "iPhone 15", width: 390, height: 844)
                DevicePreviewCard(name: "iPhone Pro Max", width: 430, height: 932)
                DevicePreviewCard(name: "iPad mini", width: 744, height: 1133)
            }
            .padding()
        }
    }
}

private struct DevicePreviewCard: View {
    let name: String
    let width: CGFloat
    let height: CGFloat

    private var scaleFactor: CGFloat { 0.25 }

    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.headline)

            ResponsiveContainer { layout in
                ResponsivePreviewContent(layout: layout)
                    .frame(width: width, height: height)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(20)
            }
            .frame(width: width * scaleFactor, height: height * scaleFactor)
            .clipped()

            Text("\(Int(width)) × \(Int(height))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("All Devices Grid") {
    DeviceComparisonGrid()
}

// MARK: - Test Matrix Helper

/// A test matrix documenting all supported device configurations
/// Use this as a checklist when testing the app manually
enum ResponsiveTestMatrix {
    static let devices: [(name: String, width: CGFloat, height: CGFloat)] = [
        ("iPhone SE (3rd gen)", 375, 667),
        ("iPhone 14", 390, 844),
        ("iPhone 14 Plus", 428, 926),
        ("iPhone 15", 393, 852),
        ("iPhone 15 Plus", 430, 932),
        ("iPhone 15 Pro", 393, 852),
        ("iPhone 15 Pro Max", 430, 932),
        ("iPhone 16", 393, 852),
        ("iPhone 16 Pro", 402, 874),
        ("iPhone 16 Pro Max", 440, 956),
        ("iPad mini (6th gen)", 744, 1133),
        ("iPad (10th gen)", 820, 1180),
        ("iPad Air (5th gen)", 820, 1180),
        ("iPad Pro 11\"", 834, 1194),
        ("iPad Pro 13\"", 1024, 1366)
    ]

    static let orientations = ["Portrait", "Landscape"]

    static let dynamicTypeSizes: [DynamicTypeSize] = [
        .xSmall, .small, .medium, .large, .xLarge,
        .xxLarge, .xxxLarge, .accessibility1,
        .accessibility2, .accessibility3
    ]
}
