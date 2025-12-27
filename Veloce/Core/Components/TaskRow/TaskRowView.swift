//
//  TaskRowView.swift
//  Veloce
//
//  Premium Task Row - Ultra-refined, scannable list item
//  Features: Gradient checkbox, priority stars, glass duration pill, confetti celebration
//  Performance: Preloads AI data on appear for instant detail sheet opening
//

import SwiftUI

// MARK: - Task Row View

struct TaskRowView: View {
    let task: TaskItem
    var onComplete: () -> Void
    var onDelete: () -> Void
    var onTap: () -> Void

    /// Optional namespace for matched geometry transitions
    var transitionNamespace: Namespace.ID?

    @State private var isPressed = false
    @State private var showConfetti = false
    @State private var checkboxScale: CGFloat = 1.0
    @State private var swipeOffset: CGFloat = 0
    @State private var hasAppeared = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let rowHeight: CGFloat = 72
    private let checkboxSize: CGFloat = 26
    private let deleteThreshold: CGFloat = -120

    // MARK: - Computed Properties

    private var priorityStars: Int {
        task.starRating
    }

    private var durationText: String {
        guard let minutes = task.estimatedMinutes, minutes > 0 else {
            return "15m" // Default
        }
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private var priorityColor: Color {
        switch priorityStars {
        case 3: return Theme.CelestialColors.urgencyCritical
        case 2: return Theme.TaskCardColors.coordinate
        default: return Theme.CelestialColors.auroraGreen
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Delete background
            deleteBackground

            // Main row content
            rowContent
                .offset(x: swipeOffset)
                .gesture(swipeGesture)
        }
        .frame(height: rowHeight)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 8)
        // Matched geometry for smooth portal transitions
        .if(transitionNamespace != nil) { view in
            view.matchedGeometryEffect(
                id: "taskRow_\(task.id.uuidString)",
                in: transitionNamespace!,
                properties: .frame
            )
        }
        // Preload AI data in background for instant detail sheet
        .preloadTaskCard(task)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Row Content

    private var rowContent: some View {
        Button(action: {
            HapticsService.shared.selectionFeedback()
            onTap()
        }) {
            HStack(spacing: 14) {
                // Left: Premium Gradient Checkbox
                premiumCheckbox

                // Center: Title + Priority Stars
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(task.isCompleted ? Theme.CelestialColors.starDim : Theme.CelestialColors.starWhite)
                        .strikethrough(task.isCompleted, color: Theme.CelestialColors.starDim)
                        .lineLimit(1)

                    // Priority stars
                    priorityStarsView
                }

                Spacer()

                // Right: Duration Pill
                durationPill
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(rowBackground)
        }
        .buttonStyle(TaskRowPressStyle(reduceMotion: reduceMotion))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details. Swipe left to delete.")
    }

    // MARK: - Premium Gradient Checkbox

    private var premiumCheckbox: some View {
        ZStack {
            // Confetti burst
            if showConfetti {
                TaskRowConfetti(
                    colors: [
                        Theme.CelestialColors.auroraGreen,
                        Theme.TaskCardColors.pointsGlow,
                        Theme.CelestialColors.plasmaCore
                    ]
                )
            }

            // Gradient border circle
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: task.isCompleted
                            ? [Theme.CelestialColors.auroraGreen, Theme.CelestialColors.auroraGreen]
                            : [
                                Theme.CelestialColors.nebulaCore,
                                Theme.CelestialColors.nebulaEdge,
                                Theme.CelestialColors.plasmaCore,
                                Theme.CelestialColors.nebulaCore
                            ],
                        center: .center
                    ),
                    lineWidth: 2.5
                )
                .frame(width: checkboxSize, height: checkboxSize)

            // Fill circle (animated)
            Circle()
                .fill(Theme.CelestialColors.auroraGreen)
                .frame(width: checkboxSize - 4, height: checkboxSize - 4)
                .scaleEffect(task.isCompleted ? 1 : 0)

            // Checkmark
            if task.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.CelestialColors.void)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(width: 44, height: 44) // Touch target
        .contentShape(Circle())
        .scaleEffect(checkboxScale)
        .onTapGesture {
            handleCheckboxTap()
        }
        .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6), value: task.isCompleted)
        .animation(reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.5), value: checkboxScale)
    }

    // MARK: - Priority Stars View

    private var priorityStarsView: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: index <= priorityStars ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(index <= priorityStars ? Color(hex: "FFD700") : Theme.CelestialColors.starGhost)
            }

            Text(priorityLabel)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Theme.CelestialColors.starDim)
                .padding(.leading, 4)
        }
    }

    private var priorityLabel: String {
        switch priorityStars {
        case 3: return "High Priority"
        case 2: return "Medium Priority"
        default: return "Low Priority"
        }
    }

    // MARK: - Duration Pill

    private var durationPill: some View {
        HStack(spacing: 4) {
            Text(durationText)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.CelestialColors.starWhite)

            Image(systemName: "clock.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.CelestialColors.plasmaCore)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            ZStack {
                // Glass base
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)

                // Gradient border
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.plasmaCore.opacity(0.4),
                                Theme.CelestialColors.nebulaEdge.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }

    // MARK: - Row Background

    private var rowBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.CelestialColors.abyss)

            // Subtle border glow
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.nebulaCore.opacity(0.2),
                            Theme.CelestialColors.nebulaEdge.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // Completed state overlay
            if task.isCompleted {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.CelestialColors.auroraGreen.opacity(0.05))
            }
        }
    }

    // MARK: - Delete Background

    private var deleteBackground: some View {
        HStack {
            Spacer()

            ZStack {
                Theme.CelestialColors.errorNebula.opacity(0.25)

                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.CelestialColors.errorNebula)

                    Text("Delete")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.CelestialColors.errorNebula)
                }
                .opacity(-swipeOffset > deleteThreshold * 0.5 ? 1 : 0.5)
            }
            .frame(width: max(0, -swipeOffset))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                let translation = value.translation.width
                // Only allow left swipe (delete)
                if translation < 0 {
                    swipeOffset = max(translation, deleteThreshold - 30)
                }
            }
            .onEnded { value in
                let translation = value.translation.width

                if translation < deleteThreshold {
                    // Delete triggered
                    HapticsService.shared.notification(.warning)

                    if !reduceMotion {
                        withAnimation(.easeOut(duration: 0.2)) {
                            swipeOffset = -UIScreen.main.bounds.width
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDelete()
                    }
                } else {
                    // Reset
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeOffset = 0
                    }
                }
            }
    }

    // MARK: - Actions

    private func handleCheckboxTap() {
        guard !task.isCompleted else { return }

        if reduceMotion {
            HapticsService.shared.notification(.success)
            onComplete()
            return
        }

        // Phase 1: Initial press feedback
        HapticsService.shared.impact(.soft)

        // Scale bounce animation
        withAnimation(.spring(response: 0.12, dampingFraction: 0.35)) {
            checkboxScale = 1.35
        }

        // Show confetti
        showConfetti = true

        // Phase 2: DOPAMINE BURST - The magic moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticsService.shared.dopamineBurst()

            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                checkboxScale = 1.0
            }
        }

        // Phase 3: Trigger completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onComplete()
        }

        // Phase 4: Hide confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showConfetti = false
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let status = task.isCompleted ? "Completed" : "Not completed"
        let priority: String
        switch priorityStars {
        case 3: priority = "High"
        case 2: priority = "Medium"
        default: priority = "Low"
        }
        return "Task: \(task.title), Priority: \(priority), Estimated: \(durationText), \(status)"
    }
}

// MARK: - Task Row Press Style

private struct TaskRowPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.15, dampingFraction: 0.8),
                value: configuration.isPressed
            )
    }
}

// MARK: - Task Row Confetti

private struct TaskRowConfetti: View {
    let colors: [Color]
    private let particleCount = 12

    @State private var particles: [TaskRowConfettiPiece] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                RoundedRectangle(cornerRadius: 1)
                    .fill(particle.color)
                    .frame(width: particle.width, height: particle.height)
                    .rotationEffect(.degrees(particle.rotation))
                    .offset(x: particle.offsetX, y: particle.offsetY)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createConfetti()
            animateConfetti()
        }
    }

    private func createConfetti() {
        particles = (0..<particleCount).map { i in
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi + Double.random(in: -0.3...0.3)
            return TaskRowConfettiPiece(
                id: i,
                color: colors[i % colors.count],
                width: CGFloat.random(in: 3...6),
                height: CGFloat.random(in: 3...8),
                rotation: Double.random(in: 0...360),
                offsetX: 0,
                offsetY: 0,
                targetX: cos(angle) * CGFloat.random(in: 30...50),
                targetY: sin(angle) * CGFloat.random(in: 30...50),
                opacity: 1
            )
        }
    }

    private func animateConfetti() {
        withAnimation(.easeOut(duration: 0.5)) {
            for i in particles.indices {
                particles[i].offsetX = particles[i].targetX
                particles[i].offsetY = particles[i].targetY
                particles[i].rotation += Double.random(in: 180...540)
                particles[i].opacity = 0
            }
        }
    }
}

private struct TaskRowConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var rotation: Double
    var offsetX: CGFloat
    var offsetY: CGFloat
    var targetX: CGFloat
    var targetY: CGFloat
    var opacity: Double
}

// MARK: - Task Row List View

/// Example container showing how to use TaskRowView with the new slidable bottom sheet
/// Copy this pattern to integrate TaskRowView into your views
struct TaskRowListView: View {
    let tasks: [TaskItem]
    var onTaskUpdated: ((TaskItem) -> Void)?

    // Detail sheet state
    @State private var selectedTask: TaskItem?
    @State private var showDetailSheet = false
    @State private var sheetDetent: PresentationDetent = .medium

    @Namespace private var taskRowNamespace

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskRowView(
                        task: task,
                        onComplete: {
                            // Mark task complete
                            task.complete()
                            HapticsService.shared.notification(.success)
                            onTaskUpdated?(task)
                        },
                        onDelete: {
                            // Handle deletion
                            HapticsService.shared.notification(.warning)
                        },
                        onTap: {
                            // Open detail sheet
                            presentDetailSheet(for: task)
                        },
                        transitionNamespace: taskRowNamespace
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        // iOS-Native Slidable Bottom Sheet for Task Details
        .slidableBottomSheet(
            isPresented: $showDetailSheet,
            selectedDetent: $sheetDetent,
            detents: [.fraction(0.25), .medium, .fraction(0.85), .large],
            showDragIndicator: true,
            cornerRadius: 32,
            backgroundStyle: .celestial
        ) {
            if let task = selectedTask {
                TaskDetailBottomSheet(
                    task: task,
                    onComplete: {
                        task.complete()
                        onTaskUpdated?(task)
                    },
                    onDuplicate: {},
                    onSnooze: { _ in },
                    onDelete: {},
                    onSchedule: { _ in },
                    onStartTimer: { _ in }
                )
            }
        }
    }

    private func presentDetailSheet(for task: TaskItem) {
        selectedTask = task
        sheetDetent = .medium
        showDetailSheet = true
        HapticsService.shared.selectionFeedback()
    }
}

// MARK: - Preview

#Preview("Task Row View") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 12) {
                // High Priority
                TaskRowView(
                    task: {
                        let task = TaskItem(title: "Review Q4 strategy presentation")
                        task.starRating = 3
                        task.estimatedMinutes = 45
                        return task
                    }(),
                    onComplete: { print("Completed") },
                    onDelete: { print("Deleted") },
                    onTap: { print("Tapped") }
                )

                // Medium Priority
                TaskRowView(
                    task: {
                        let task = TaskItem(title: "Send project update email")
                        task.starRating = 2
                        task.estimatedMinutes = 15
                        return task
                    }(),
                    onComplete: {},
                    onDelete: {},
                    onTap: {}
                )

                // Low Priority
                TaskRowView(
                    task: {
                        let task = TaskItem(title: "Organize desk and files")
                        task.starRating = 1
                        task.estimatedMinutes = 30
                        return task
                    }(),
                    onComplete: {},
                    onDelete: {},
                    onTap: {}
                )

                // Completed
                TaskRowView(
                    task: {
                        let task = TaskItem(title: "Morning standup meeting")
                        task.starRating = 2
                        task.estimatedMinutes = 15
                        task.isCompleted = true
                        return task
                    }(),
                    onComplete: {},
                    onDelete: {},
                    onTap: {}
                )
            }
            .padding()
        }
    }
}

#Preview("Task Row List Integration") {
    TaskRowListView(tasks: [
        {
            let task = TaskItem(title: "Review Q4 strategy presentation")
            task.starRating = 3
            task.estimatedMinutes = 45
            return task
        }(),
        {
            let task = TaskItem(title: "Send project update email")
            task.starRating = 2
            task.estimatedMinutes = 15
            return task
        }(),
        {
            let task = TaskItem(title: "Organize desk and files")
            task.starRating = 1
            task.estimatedMinutes = 30
            return task
        }()
    ])
    .background(Theme.CelestialColors.void.ignoresSafeArea())
}
