//
//  AccessibilityModifiers.swift
//  MyTasksAI
//
//  Accessibility View Modifiers
//  WCAG compliance and VoiceOver support
//

import SwiftUI

// MARK: - Accessibility Button Modifier
struct AccessibleButtonModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Accessible Task Row Modifier
struct AccessibleTaskRowModifier: ViewModifier {
    let task: TaskItem
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(taskLabel)
            .accessibilityHint(taskHint)
            .accessibilityAddTraits(accessibilityTraits)
            .accessibilityValue(taskValue)
    }

    private var taskLabel: String {
        var label = task.title
        if task.isCompleted {
            label = "Completed: \(label)"
        }
        return label
    }

    private var taskHint: String {
        if task.isCompleted {
            return "Double tap to mark as incomplete"
        }
        return "Double tap to mark as complete"
    }

    private var taskValue: String {
        var values: [String] = []

        if let estimate = task.estimatedTimeFormatted {
            values.append("Estimated \(estimate)")
        }

        if let priority = task.aiPriority {
            values.append("\(priority) priority")
        }

        if task.isScheduled {
            values.append("Scheduled")
        }

        return values.joined(separator: ", ")
    }

    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]
        if isSelected {
            _ = traits.insert(.isSelected)
        }
        return traits
    }
}

// MARK: - Accessible Progress Modifier
struct AccessibleProgressModifier: ViewModifier {
    let label: String
    let value: Double
    let total: Double

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value)) of \(Int(total)), \(Int((value/total) * 100))% complete")
    }
}

// MARK: - Accessible Header Modifier
struct AccessibleHeaderModifier: ViewModifier {
    let level: Int

    func body(content: Content) -> some View {
        content
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(headingLevel)
    }

    private var headingLevel: AccessibilityHeadingLevel {
        switch level {
        case 1: return .h1
        case 2: return .h2
        case 3: return .h3
        case 4: return .h4
        case 5: return .h5
        case 6: return .h6
        default: return .unspecified
        }
    }
}

// MARK: - Accessible Image Modifier
struct AccessibleImageModifier: ViewModifier {
    let label: String
    let isDecorative: Bool

    func body(content: Content) -> some View {
        if isDecorative {
            content
                .accessibilityHidden(true)
        } else {
            content
                .accessibilityLabel(label)
                .accessibilityAddTraits(.isImage)
        }
    }
}

// MARK: - Reduced Motion Modifier
struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation
    let reducedAnimation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

// MARK: - High Contrast Modifier
struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    let normalColor: Color
    let highContrastColor: Color

    func body(content: Content) -> some View {
        content
            .foregroundStyle(contrast == .increased ? highContrastColor : normalColor)
    }
}

// MARK: - Large Content Viewer Modifier
struct LargeContentViewerModifier: ViewModifier {
    let text: String
    let image: String?

    func body(content: Content) -> some View {
        content
            .accessibilityShowsLargeContentViewer {
                VStack {
                    if let image {
                        Image(systemName: image)
                            .font(.largeTitle)
                    }
                    Text(text)
                        .font(.title)
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Make button accessible
    func accessibleButton(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = .isButton
    ) -> some View {
        modifier(AccessibleButtonModifier(label: label, hint: hint, traits: traits))
    }

    /// Make task row accessible
    func accessibleTaskRow(task: TaskItem, isSelected: Bool = false) -> some View {
        modifier(AccessibleTaskRowModifier(task: task, isSelected: isSelected))
    }

    /// Make progress accessible
    func accessibleProgress(label: String, value: Double, total: Double) -> some View {
        modifier(AccessibleProgressModifier(label: label, value: value, total: total))
    }

    /// Mark as header
    func accessibleHeader(level: Int = 1) -> some View {
        modifier(AccessibleHeaderModifier(level: level))
    }

    /// Make image accessible
    func accessibleImage(label: String, isDecorative: Bool = false) -> some View {
        modifier(AccessibleImageModifier(label: label, isDecorative: isDecorative))
    }

    /// Respect reduced motion
    func reducedMotionAnimation(
        _ animation: Animation = Theme.Animation.spring,
        reduced: Animation = .linear(duration: 0.01)
    ) -> some View {
        modifier(ReducedMotionModifier(animation: animation, reducedAnimation: reduced))
    }

    /// Support high contrast
    func highContrastColor(normal: Color, highContrast: Color) -> some View {
        modifier(HighContrastModifier(normalColor: normal, highContrastColor: highContrast))
    }

    /// Show large content viewer
    func largeContentViewer(text: String, image: String? = nil) -> some View {
        modifier(LargeContentViewerModifier(text: text, image: image))
    }
}

// MARK: - Accessibility Focus State
@propertyWrapper
struct AccessibilityFocusedValue<Value: Hashable>: DynamicProperty {
    @AccessibilityFocusState private var focusedField: Value?

    var wrappedValue: Value? {
        get { focusedField }
        nonmutating set { focusedField = newValue }
    }

    var projectedValue: AccessibilityFocusState<Value?>.Binding {
        $focusedField
    }
}

// MARK: - Accessible Announcement
struct AccessibilityAnnouncement {
    static func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        UIAccessibility.post(notification: priority, argument: message)
    }

    static func announceScreenChange(_ message: String? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    static func announceLayoutChange(_ element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

// MARK: - Dynamic Type Support
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let minimumScaleFactor: CGFloat

    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? minimumScaleFactor : 1.0)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
    }
}

extension View {
    func supportsDynamicType(minimumScaleFactor: CGFloat = 0.8) -> some View {
        modifier(DynamicTypeModifier(minimumScaleFactor: minimumScaleFactor))
    }
}
