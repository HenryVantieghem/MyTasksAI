//
//  LiquidGlassTaskComponents.swift
//  MyTasksAI
//
//  Premium Liquid Glass Task Components
//  Task cards, input bars, and task-related UI with native iOS 26 glass
//

import SwiftUI

// MARK: - Liquid Glass Task Card

/// Premium task card with Liquid Glass background and interactive elements
struct LiquidGlassTaskCard: View {
    let task: TaskItem
    let onTap: () -> Void
    let onComplete: () -> Void
    
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                // Completion checkbox
                checkboxButton
                
                // Task content
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .strikethrough(task.isCompleted, color: .white.opacity(0.5))
                    
                    // Metadata row
                    HStack(spacing: 12) {
                        // Due date if present
                        if let dueDate = task.scheduledTime {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                                Text(dueDate, style: .relative)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(task.isOverdue ? LiquidGlassDesignSystem.VibrantAccents.nebulaPink : .white.opacity(0.6))
                        }
                        
                        // Priority indicator
                        if task.priority.rawValue > 0 {
                            LiquidGlassPill(
                                text: priorityText,
                                icon: "flag.fill",
                                color: priorityColor
                            )
                        }
                        
                        // Task type
                        LiquidGlassPill(
                            text: task.taskType.rawValue,
                            color: taskTypeColor(task.taskType.rawValue)
                        )
                    }
                }
                
                Spacer()
                
                // Chevron for details
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.05)
                .onChanged { _ in
                    if !reduceMotion {
                        withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(LiquidGlassDesignSystem.Springs.ui) {
                        isPressed = false
                    }
                    HapticsService.shared.impact(.medium)
                    onTap()
                }
        )
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            taskAccentColor.opacity(0.4),
                            taskAccentColor.opacity(0.2),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: taskAccentColor.opacity(0.2), radius: 16, y: 8)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(LiquidGlassDesignSystem.Springs.ui, value: isPressed)
    }
    
    private var checkboxButton: some View {
        Button(action: onComplete) {
            ZStack {
                Circle()
                    .stroke(
                        task.isCompleted ? taskAccentColor : .white.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)
                
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(taskAccentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var taskAccentColor: Color {
        if task.isCompleted {
            return LiquidGlassDesignSystem.VibrantAccents.auroraGreen
        }
        if task.isOverdue {
            return LiquidGlassDesignSystem.VibrantAccents.nebulaPink
        }
        if task.priority == .high {
            return LiquidGlassDesignSystem.VibrantAccents.solarGold
        }
        return LiquidGlassDesignSystem.VibrantAccents.electricCyan
    }

    private var priorityText: String {
        switch task.priority {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return LiquidGlassDesignSystem.VibrantAccents.cosmicBlue
        case .medium: return LiquidGlassDesignSystem.VibrantAccents.solarGold
        case .high: return LiquidGlassDesignSystem.VibrantAccents.nebulaPink
        }
    }
    
    private func taskTypeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "work": return Color(hex: "6366F1")
        case "personal": return Color(hex: "EC4899")
        case "health": return Color(hex: "10B981")
        case "learning": return Color(hex: "8B5CF6")
        default: return LiquidGlassDesignSystem.VibrantAccents.electricCyan
        }
    }
}

// MARK: - Liquid Glass Task Input Bar

/// Premium floating input bar with Liquid Glass effect
struct LiquidGlassTaskInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: (String) -> Void
    let onVoiceInput: () -> Void
    
    @State private var showMicrophone = true
    @Environment(\.responsiveLayout) private var layout
    
    var body: some View {
        HStack(spacing: 12) {
            // Plus button for quick actions
            Button {
                HapticsService.shared.lightImpact()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Input field container
            HStack(spacing: 12) {
                TextField("Add a task...", text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .tint(LiquidGlassDesignSystem.VibrantAccents.electricCyan)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        submitTask()
                    }
                
                // Voice/Send button
                if text.isEmpty && showMicrophone {
                    Button(action: onVoiceInput) {
                        Image(systemName: "waveform")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 40, height: 40)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if !text.isEmpty {
                    Button(action: submitTask) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                                            LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(
                            color: LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.5),
                            radius: 12,
                            y: 4
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(
                .regular.interactive(),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: isFocused ? [
                                LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.6),
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.4)
                            ] : [
                                .white.opacity(0.2),
                                .white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 1.5 : 0.5
                    )
            }
            .shadow(
                color: isFocused ? LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.3) : .black.opacity(0.25),
                radius: isFocused ? 24 : 16,
                y: isFocused ? 12 : 8
            )
            .animation(LiquidGlassDesignSystem.Springs.ui, value: isFocused)
        }
        .padding(.horizontal, layout.screenPadding)
        .padding(.vertical, 12)
        .animation(LiquidGlassDesignSystem.Springs.ui, value: text.isEmpty)
    }
    
    private func submitTask() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        withAnimation(LiquidGlassDesignSystem.Springs.ui) {
            text = ""
            isFocused = false
        }
        
        HapticsService.shared.success()
        onSubmit(trimmedText)
    }
}

// MARK: - Liquid Glass Task Section Header

/// Section header for task lists (e.g., "Today", "Tomorrow", "Later")
struct LiquidGlassTaskSection: View {
    let title: String
    let taskCount: Int
    let icon: String
    let accentColor: Color
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .blur(radius: 8)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                
                // Title
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                
                // Count badge
                Text("\(taskCount)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(.white.opacity(0.1))
                    }
                
                Spacer()
                
                // Expand/collapse chevron
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
        .animation(LiquidGlassDesignSystem.Springs.ui, value: isExpanded)
    }
}

// MARK: - Liquid Glass Empty State

/// Empty state view with glass styling
struct TaskComponentsEmptyState: View {
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
                                LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.plasmaPurple)
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if let actionTitle = actionTitle, let action = action {
                LiquidGlassButton.primary(actionTitle, icon: "plus", action: action)
                    .frame(maxWidth: 280)
            }
        }
        .padding(40)
        .frame(maxWidth: 400)
    }
}

// MARK: - Liquid Glass Quick Action Menu

/// Floating quick action menu with glass effect
struct LiquidGlassQuickActionMenu: View {
    let isPresented: Bool
    let onDismiss: () -> Void
    let onAddTask: () -> Void
    let onAddGoal: () -> Void
    let onStartFocus: () -> Void
    let onBrainDump: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                // Backdrop
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                
                // Menu container
                VStack(spacing: 12) {
                    quickActionButton(
                        icon: "checkmark.circle.fill",
                        title: "Add Task",
                        color: LiquidGlassDesignSystem.VibrantAccents.electricCyan,
                        action: onAddTask
                    )
                    
                    quickActionButton(
                        icon: "target",
                        title: "Add Goal",
                        color: LiquidGlassDesignSystem.VibrantAccents.solarGold,
                        action: onAddGoal
                    )
                    
                    quickActionButton(
                        icon: "brain.head.profile",
                        title: "Start Focus",
                        color: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple,
                        action: onStartFocus
                    )
                    
                    quickActionButton(
                        icon: "bolt.fill",
                        title: "Brain Dump",
                        color: LiquidGlassDesignSystem.VibrantAccents.auroraGreen,
                        action: onBrainDump
                    )
                }
                .padding(20)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: 32, y: 16)
                .padding(40)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            .animation(LiquidGlassDesignSystem.Springs.focus, value: isPresented)
        }
    }
    
    private func quickActionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticsService.shared.impact(.light)
            action()
            onDismiss()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(16)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 0.5)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Task Card") {
    VStack(spacing: 16) {
        LiquidGlassTaskCard(
            task: TaskItem(
                id: UUID(),
                title: "Complete project proposal",
                isCompleted: false,
                aiPriority: "high",
                scheduledTime: Date().addingTimeInterval(3600)
            ),
            onTap: {},
            onComplete: {}
        )

        LiquidGlassTaskCard(
            task: TaskItem(
                id: UUID(),
                title: "Team meeting",
                isCompleted: true,
                aiPriority: "medium"
            ),
            onTap: {},
            onComplete: {}
        )
    }
    .padding()
    .background(Color(red: 0.02, green: 0.02, blue: 0.04))
    .preferredColorScheme(.dark)
}

#Preview("Task Input Bar") {
    struct PreviewContainer: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool
        
        var body: some View {
            VStack {
                Spacer()
                
                LiquidGlassTaskInputBar(
                    text: $text,
                    isFocused: $isFocused,
                    onSubmit: { _ in },
                    onVoiceInput: {}
                )
            }
            .background(Color(red: 0.02, green: 0.02, blue: 0.04))
        }
    }
    
    return PreviewContainer()
        .preferredColorScheme(.dark)
}
