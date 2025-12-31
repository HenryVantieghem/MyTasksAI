//
//  KeyboardAccessoryBar.swift
//  MyTasksAI
//
//  Apple Notes-inspired keyboard accessory bar
//  Slides up with keyboard, contains task action shortcuts
//

import SwiftUI

// MARK: - Quick Due Date Options
enum QuickDueDate: CaseIterable {
    case today
    case tomorrow
    case pickDate

    var label: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .pickDate: return "Pick"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .tomorrow: return "sunrise"
        case .pickDate: return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .today: return Theme.Colors.aiAmber
        case .tomorrow: return Theme.Colors.aiBlue
        case .pickDate: return Theme.Colors.accent
        }
    }
}

// MARK: - Keyboard Accessory Bar
struct KeyboardAccessoryBar: View {
    @Binding var taskTitle: String
    var onAddChecklist: () -> Void = {}
    var onSetPriority: ((TaskPriorityLevel) -> Void)?
    var onSetDueDate: ((Date?) -> Void)?
    var onSetCategory: ((TaskType) -> Void)?
    var onSchedule: () -> Void = {}
    var onAISuggestion: () -> Void = {}
    var onDismissKeyboard: () -> Void = {}

    @State private var showPriorityPicker = false
    @State private var showDueDatePicker = false
    @State private var showCategoryPicker = false
    @State private var selectedPriority: TaskPriorityLevel = .none
    @State private var selectedCategory: TaskType?

    var body: some View {
        VStack(spacing: 0) {
            // Priority picker (expands from the bar)
            if showPriorityPicker {
                priorityPicker
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Due date picker
            if showDueDatePicker {
                dueDatePicker
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Category picker
            if showCategoryPicker {
                categoryPicker
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Main accessory bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    // Checklist button
                    AccessoryButton(
                        icon: "checklist",
                        label: "List",
                        color: Theme.Colors.aiOrange
                    ) {
                        onAddChecklist()
                        HapticsService.shared.selectionFeedback()
                    }

                    // Priority button
                    AccessoryButton(
                        icon: priorityIcon,
                        label: "Priority",
                        color: priorityColor,
                        isActive: selectedPriority != .none
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showPriorityPicker.toggle()
                            showDueDatePicker = false
                            showCategoryPicker = false
                        }
                        HapticsService.shared.selectionFeedback()
                    }

                    // Due date button
                    AccessoryButton(
                        icon: "calendar.badge.clock",
                        label: "Due",
                        color: Theme.Colors.aiAmber
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showDueDatePicker.toggle()
                            showPriorityPicker = false
                            showCategoryPicker = false
                        }
                        HapticsService.shared.selectionFeedback()
                    }

                    // Category button
                    AccessoryButton(
                        icon: categoryIcon,
                        label: "Type",
                        color: categoryColor,
                        isActive: selectedCategory != nil
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCategoryPicker.toggle()
                            showPriorityPicker = false
                            showDueDatePicker = false
                        }
                        HapticsService.shared.selectionFeedback()
                    }

                    // AI Magic button (Claude Code style)
                    AIMagicAccessoryButton {
                        onAISuggestion()
                        HapticsService.shared.impact()
                    }

                    // Divider
                    Capsule()
                        .fill(Theme.Colors.divider)
                        .frame(width: 1, height: 24)
                        .padding(.horizontal, Theme.Spacing.xs)

                    // Dismiss keyboard button
                    Button {
                        onDismissKeyboard()
                        HapticsService.shared.selectionFeedback()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .dynamicTypeFont(base: 18, weight: .medium)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(Theme.Spacing.sm)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .frame(height: 52)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.iridescentPink.opacity(0.05),
                                        Theme.Colors.iridescentCyan.opacity(0.03),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Theme.Colors.glassBorder)
                    .frame(height: 0.5)
            }
        }
    }

    // MARK: - Priority Picker
    private var priorityPicker: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(TaskPriorityLevel.allCases, id: \.self) { priority in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        selectedPriority = priority
                        showPriorityPicker = false
                    }
                    onSetPriority?(priority)
                    HapticsService.shared.selectionFeedback()
                } label: {
                    VStack(spacing: 4) {
                        SwiftUI.Circle()
                            .fill(priority.color)
                            .frame(width: 24, height: 24)
                            .overlay {
                                if selectedPriority == priority {
                                    Image(systemName: "checkmark")
                                        .dynamicTypeFont(base: 12, weight: .bold)
                                        .foregroundStyle(.white)
                                }
                            }

                        Text(priority.label)
                            .dynamicTypeFont(base: 11, weight: .medium)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }

    private var priorityIcon: String {
        switch selectedPriority {
        case .none: return "flag"
        case .low: return "flag.fill"
        case .medium: return "flag.fill"
        case .high: return "flag.fill"
        }
    }

    private var priorityColor: Color {
        selectedPriority.color
    }

    // MARK: - Due Date Picker
    private var dueDatePicker: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(QuickDueDate.allCases, id: \.self) { dueOption in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        showDueDatePicker = false
                    }

                    let date: Date?
                    switch dueOption {
                    case .today:
                        date = Date()
                    case .tomorrow:
                        date = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                    case .pickDate:
                        date = nil  // Parent should show date picker
                        onSchedule()
                        return
                    }

                    onSetDueDate?(date)
                    HapticsService.shared.selectionFeedback()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            SwiftUI.Circle()
                                .fill(dueOption.color.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: dueOption.icon)
                                .dynamicTypeFont(base: 16, weight: .medium)
                                .foregroundStyle(dueOption.color)
                        }

                        Text(dueOption.label)
                            .dynamicTypeFont(base: 11, weight: .medium)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(TaskType.allCases, id: \.self) { taskType in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        selectedCategory = taskType
                        showCategoryPicker = false
                    }
                    onSetCategory?(taskType)
                    HapticsService.shared.selectionFeedback()
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            SwiftUI.Circle()
                                .fill(taskType.color.opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if selectedCategory == taskType {
                                        SwiftUI.Circle()
                                            .strokeBorder(taskType.color, lineWidth: 2)
                                    }
                                }

                            Image(systemName: taskType.icon)
                                .dynamicTypeFont(base: 14, weight: .medium)
                                .foregroundStyle(taskType.color)
                        }

                        Text(taskType.shortLabel)
                            .dynamicTypeFont(base: 10, weight: .medium)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(width: 50)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }

    private var categoryIcon: String {
        selectedCategory?.icon ?? "tag"
    }

    private var categoryColor: Color {
        selectedCategory?.color ?? Theme.Colors.textTertiary
    }
}

// MARK: - Task Priority Level
enum TaskPriorityLevel: CaseIterable {
    case none
    case low
    case medium
    case high

    var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var color: Color {
        switch self {
        case .none: return Theme.Colors.textTertiary
        case .low: return Theme.Colors.success
        case .medium: return Theme.Colors.warning
        case .high: return Theme.Colors.destructive
        }
    }
}

// MARK: - Accessory Button
struct AccessoryButton: View {
    let icon: String
    let label: String?
    let color: Color
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 16, weight: .medium)

                if let label = label {
                    Text(label)
                        .dynamicTypeFont(base: 13, weight: .medium)
                }
            }
            .foregroundStyle(isActive ? color : Theme.Colors.textSecondary)
            .padding(.horizontal, label != nil ? 12 : 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? color.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Magic Accessory Button
/// Special button with Claude Code-style gradient animation
struct AIMagicAccessoryButton: View {
    let action: () -> Void

    @State private var rotation: Double = 0
    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                // Animated gradient orb
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            AngularGradient(
                                colors: Theme.Colors.aiGradient + [Theme.Colors.aiGradient[0]],
                                center: .center
                            )
                        )
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(rotation))

                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: 6
                            )
                        )
                        .frame(width: 18, height: 18)
                }

                Text("AI")
                    .dynamicTypeFont(base: 13, weight: .semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiOrange, Theme.Colors.aiPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiOrange.opacity(0.15),
                                Theme.Colors.aiPurple.opacity(0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiOrange.opacity(0.3),
                                Theme.Colors.aiPurple.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(AIButtonStyle())
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - AI Button Style
struct AIButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Keyboard Accessory View Modifier
struct KeyboardAccessoryModifier: ViewModifier {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var onPrioritySet: ((TaskPriorityLevel) -> Void)?
    var onSetDueDate: ((Date?) -> Void)?
    var onSetCategory: ((TaskType) -> Void)?
    var onSchedule: () -> Void
    var onAISuggestion: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    KeyboardAccessoryBar(
                        taskTitle: $text,
                        onSetPriority: onPrioritySet,
                        onSetDueDate: onSetDueDate,
                        onSetCategory: onSetCategory,
                        onSchedule: onSchedule,
                        onAISuggestion: onAISuggestion,
                        onDismissKeyboard: {
                            isFocused = false
                        }
                    )
                }
            }
    }
}

extension View {
    func keyboardAccessory(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        onPrioritySet: ((TaskPriorityLevel) -> Void)? = nil,
        onSetDueDate: ((Date?) -> Void)? = nil,
        onSetCategory: ((TaskType) -> Void)? = nil,
        onSchedule: @escaping () -> Void = {},
        onAISuggestion: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(KeyboardAccessoryModifier(
            text: text,
            isFocused: isFocused,
            onPrioritySet: onPrioritySet,
            onSetDueDate: onSetDueDate,
            onSetCategory: onSetCategory,
            onSchedule: onSchedule,
            onAISuggestion: onAISuggestion
        ))
    }
}

// MARK: - Expanded Keyboard Toolbar
/// Full-width keyboard toolbar with more actions
struct ExpandedKeyboardToolbar: View {
    @Binding var text: String
    var onDismiss: () -> Void
    var onAddTask: () -> Void

    @State private var showingQuickActions = false

    var body: some View {
        VStack(spacing: 0) {
            // Quick actions panel (expandable)
            if showingQuickActions {
                quickActionsPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Main toolbar
            HStack(spacing: Theme.Spacing.md) {
                // Expand/collapse quick actions
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingQuickActions.toggle()
                    }
                    HapticsService.shared.selectionFeedback()
                } label: {
                    Image(systemName: showingQuickActions ? "chevron.down" : "chevron.up")
                        .dynamicTypeFont(base: 14, weight: .semibold)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            SwiftUI.Circle()
                                .fill(Theme.Colors.backgroundSecondary)
                        )
                }

                Spacer()

                // Character count
                if !text.isEmpty {
                    Text("\(text.count)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                // Dismiss keyboard
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .dynamicTypeFont(base: 18)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                // Add button (when text is not empty)
                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        onAddTask()
                        HapticsService.shared.impact()
                    } label: {
                        Text("Add")
                            .dynamicTypeFont(base: 15, weight: .semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.Colors.accent, Theme.Colors.accentSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(height: 52)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Theme.Colors.glassBorder)
                    .frame(height: 0.5)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text.isEmpty)
    }

    private var quickActionsPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                QuickActionChip(icon: "calendar", label: "Today") {
                    // Schedule for today
                    HapticsService.shared.selectionFeedback()
                }

                QuickActionChip(icon: "sun.max", label: "Tomorrow") {
                    // Schedule for tomorrow
                    HapticsService.shared.selectionFeedback()
                }

                QuickActionChip(icon: "flag.fill", label: "Priority", color: Theme.Colors.warning) {
                    // Set priority
                    HapticsService.shared.selectionFeedback()
                }

                QuickActionChip(icon: "repeat", label: "Repeat") {
                    // Set repeat
                    HapticsService.shared.selectionFeedback()
                }

                QuickActionChip(icon: "bell", label: "Reminder") {
                    // Add reminder
                    HapticsService.shared.selectionFeedback()
                }

                // AI suggestion chip with animation
                AIQuickActionChip {
                    // Get AI suggestion
                    HapticsService.shared.impact()
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .frame(height: 56)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Quick Action Chip
struct QuickActionChip: View {
    let icon: String
    let label: String
    var color: Color = Theme.Colors.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 13, weight: .medium)
                Text(label)
                    .dynamicTypeFont(base: 13, weight: .medium)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Quick Action Chip
struct AIQuickActionChip: View {
    let action: () -> Void

    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .dynamicTypeFont(base: 13, weight: .medium)
                Text("AI Suggest")
                    .dynamicTypeFont(base: 13, weight: .medium)
            }
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiOrange,
                        Theme.Colors.aiPurple,
                        Theme.Colors.aiBlue
                    ],
                    startPoint: UnitPoint(x: shimmerPhase - 0.5, y: 0),
                    endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 0)
                )
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiOrange.opacity(0.12),
                                Theme.Colors.aiPurple.opacity(0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiOrange.opacity(0.3),
                                Theme.Colors.aiPurple.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()

        Text("Keyboard Accessory Bar Preview")
            .font(.headline)

        Spacer()

        KeyboardAccessoryBar(
            taskTitle: .constant("Sample task")
        )

        Spacer().frame(height: 20)

        ExpandedKeyboardToolbar(
            text: .constant("New task"),
            onDismiss: {},
            onAddTask: {}
        )
    }
    .background(Theme.Colors.background)
}
