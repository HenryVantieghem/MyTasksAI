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

#Preview("Responsive - iPhone SE") {
    ResponsiveContainer { layout in
        VStack {
            Text("Device: \(String(describing: layout.deviceType))")
            Text("Width: \(Int(layout.screenWidth))")
            Text("Columns: \(layout.columns)")
        }
    }
    .frame(width: 375, height: 667)
}

#Preview("Responsive - iPad Pro") {
    ResponsiveContainer { layout in
        VStack {
            Text("Device: \(String(describing: layout.deviceType))")
            Text("Width: \(Int(layout.screenWidth))")
            Text("Columns: \(layout.columns)")
        }
    }
    .frame(width: 1024, height: 1366)
}
