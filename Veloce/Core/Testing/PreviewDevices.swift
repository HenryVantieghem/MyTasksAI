//
//  PreviewDevices.swift
//  Veloce
//
//  Preview helpers for testing responsive design across all device sizes
//

import SwiftUI

// MARK: - Preview Device Configuration

enum PreviewDeviceConfig: String, CaseIterable {
    // iPhones - Critical sizes
    case iPhoneSE = "iPhone SE (3rd generation)"
    case iPhone15 = "iPhone 15"
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15ProMax = "iPhone 15 Pro Max"
    case iPhone16ProMax = "iPhone 16 Pro Max"

    // iPads - Critical sizes
    case iPadMini = "iPad mini (6th generation)"
    case iPadAir = "iPad Air (5th generation)"
    case iPadPro11 = "iPad Pro 11-inch (4th generation)"
    case iPadPro13 = "iPad Pro (12.9-inch) (6th generation)"

    var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .iPhoneSE: return (375, 667)
        case .iPhone15: return (393, 852)
        case .iPhone15Pro: return (393, 852)
        case .iPhone15ProMax: return (430, 932)
        case .iPhone16ProMax: return (440, 956)
        case .iPadMini: return (744, 1133)
        case .iPadAir: return (820, 1180)
        case .iPadPro11: return (834, 1194)
        case .iPadPro13: return (1024, 1366)
        }
    }

    var isPhone: Bool {
        switch self {
        case .iPhoneSE, .iPhone15, .iPhone15Pro, .iPhone15ProMax, .iPhone16ProMax:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .iPhoneSE: return "SE (375pt)"
        case .iPhone15: return "15 (393pt)"
        case .iPhone15Pro: return "15 Pro"
        case .iPhone15ProMax: return "15 Pro Max (430pt)"
        case .iPhone16ProMax: return "16 Pro Max (440pt)"
        case .iPadMini: return "iPad mini"
        case .iPadAir: return "iPad Air"
        case .iPadPro11: return "iPad Pro 11\""
        case .iPadPro13: return "iPad Pro 13\""
        }
    }

    /// Critical devices to always test
    static var critical: [PreviewDeviceConfig] {
        [.iPhoneSE, .iPhone15, .iPhone15ProMax, .iPadMini, .iPadPro13]
    }

    /// Phones only
    static var phones: [PreviewDeviceConfig] {
        [.iPhoneSE, .iPhone15, .iPhone15ProMax, .iPhone16ProMax]
    }

    /// iPads only
    static var tablets: [PreviewDeviceConfig] {
        [.iPadMini, .iPadAir, .iPadPro11, .iPadPro13]
    }
}

// MARK: - Device Preview Wrapper

/// Wraps content in ResponsiveContainer with specific device dimensions
struct DevicePreviewWrapper<Content: View>: View {
    let device: PreviewDeviceConfig
    let isLandscape: Bool
    let content: () -> Content

    init(
        device: PreviewDeviceConfig,
        isLandscape: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.device = device
        self.isLandscape = isLandscape
        self.content = content
    }

    var body: some View {
        let (width, height) = device.dimensions
        let finalWidth = isLandscape ? height : width
        let finalHeight = isLandscape ? width : height

        ResponsiveContainer { _ in
            content()
        }
        .frame(width: finalWidth, height: finalHeight)
        .previewDisplayName("\(device.displayName)\(isLandscape ? " Landscape" : "")")
    }
}

// MARK: - View Extensions for Previews

extension View {
    /// Preview on all critical device sizes
    func previewAllCriticalDevices() -> some View {
        ForEach(PreviewDeviceConfig.critical, id: \.rawValue) { device in
            DevicePreviewWrapper(device: device) {
                self
            }
        }
    }

    /// Preview on phone size extremes (smallest and largest)
    func previewPhoneExtremes() -> some View {
        Group {
            DevicePreviewWrapper(device: .iPhoneSE) { self }
            DevicePreviewWrapper(device: .iPhone16ProMax) { self }
        }
    }

    /// Preview on all phone sizes
    func previewAllPhones() -> some View {
        ForEach(PreviewDeviceConfig.phones, id: \.rawValue) { device in
            DevicePreviewWrapper(device: device) {
                self
            }
        }
    }

    /// Preview on all iPad sizes including landscape
    func previewAlliPads() -> some View {
        Group {
            ForEach(PreviewDeviceConfig.tablets, id: \.rawValue) { device in
                DevicePreviewWrapper(device: device) { self }
            }
            // Also test iPad Pro in landscape
            DevicePreviewWrapper(device: .iPadPro13, isLandscape: true) { self }
        }
    }

    /// Preview at Dynamic Type extremes
    func previewDynamicTypeExtremes() -> some View {
        Group {
            self
                .dynamicTypeSize(.xSmall)
                .previewDisplayName("Dynamic Type: xSmall")
            self
                .dynamicTypeSize(.large)
                .previewDisplayName("Dynamic Type: Large (Default)")
            self
                .dynamicTypeSize(.accessibility3)
                .previewDisplayName("Dynamic Type: Accessibility 3")
        }
    }

    /// Preview with accessibility settings
    func previewAccessibilitySettings() -> some View {
        Group {
            self
                .previewDisplayName("Default")
            self
                .environment(\.accessibilityReduceMotion, true)
                .previewDisplayName("Reduce Motion")
            self
                .environment(\.accessibilityReduceTransparency, true)
                .previewDisplayName("Reduce Transparency")
            self
                .environment(\.colorSchemeContrast, .increased)
                .previewDisplayName("Increase Contrast")
        }
    }
}

// MARK: - Debug Responsive Layout Overlay

/// Shows responsive layout info overlay for debugging
struct ResponsiveDebugOverlay: ViewModifier {
    @Environment(\.responsiveLayout) private var layout
    let showOverlay: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if showOverlay {
                    debugInfo
                }
            }
    }

    private var debugInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Device: \(String(describing: layout.deviceType))")
            Text("Width: \(Int(layout.screenWidth))pt")
            Text("Columns: \(layout.columns)")
            Text("Spacing: \(Int(layout.spacing))pt")
            Text("Font Scale: \(String(format: "%.2f", layout.fontScale))x")
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .padding(8)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(8)
    }
}

extension View {
    /// Shows responsive debug info (for development only)
    func responsiveDebugOverlay(_ show: Bool = true) -> some View {
        modifier(ResponsiveDebugOverlay(showOverlay: show))
    }
}

// MARK: - Layout Assertion Modifier (Debug Only)

#if DEBUG
/// Warns if view uses potentially problematic hardcoded sizes
struct LayoutAssertionModifier: ViewModifier {
    let file: String
    let line: Int

    @Environment(\.responsiveLayout) private var layout

    private let suspiciousSizes: Set<CGFloat> = [
        40, 44, 48, 50, 52, 56, 60, 64, 72, 80, 100, 120, 140, 160,
        180, 200, 240, 280, 300, 320, 360, 400
    ]

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            validateDimensions(geo.size)
                        }
                }
            )
    }

    private func validateDimensions(_ size: CGSize) {
        let warningThreshold: CGFloat = 2.0

        for suspicious in suspiciousSizes {
            if abs(size.width - suspicious) < warningThreshold ||
               abs(size.height - suspicious) < warningThreshold {
                print("""
                    [LAYOUT WARNING] Potential hardcoded size detected
                    File: \(file):\(line)
                    Size: \(Int(size.width)) x \(Int(size.height))
                    Device: \(layout.deviceType)
                    Consider using ResponsiveLayout values instead.
                    """)
            }
        }
    }
}

extension View {
    /// Assert that view uses responsive sizing (debug builds only)
    func assertResponsive(file: String = #file, line: Int = #line) -> some View {
        modifier(LayoutAssertionModifier(file: file, line: line))
    }
}
#endif

// MARK: - Preview Examples

#Preview("Device Comparison - TaskCard Example") {
    VStack(spacing: 16) {
        Text("Task Card Preview")
            .dynamicTypeFont(base: 20, weight: .bold)

        Text("Test task content goes here")
            .dynamicTypeFont(base: 16)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .responsiveDebugOverlay()
    .previewAllCriticalDevices()
}

#Preview("Dynamic Type Test") {
    VStack(spacing: 16) {
        Text("Title Text")
            .dynamicTypeFont(base: 24, weight: .bold)

        Text("This is body text that should scale with Dynamic Type settings for accessibility.")
            .dynamicTypeFont(base: 16)
    }
    .padding()
    .previewDynamicTypeExtremes()
}

#Preview("Phone Extremes") {
    VStack {
        Text("Small vs Large Phone")
            .dynamicTypeFont(base: 18, weight: .semibold)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.blue.opacity(0.1))
    .previewPhoneExtremes()
}
