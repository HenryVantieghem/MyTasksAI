//
//  SlidableBottomSheet.swift
//  Veloce
//
//  iOS-Native Slidable Bottom Sheet with UIKit-style detents
//  Features: Multiple snap points, interactive drag, glass morphism
//

import SwiftUI

// MARK: - Sheet Detent Configuration

/// Custom detent configuration for the slidable bottom sheet
enum SheetDetentHeight: CaseIterable, Identifiable {
    case compact    // ~25% - Quick peek
    case half       // ~50% - Standard view
    case expanded   // ~85% - Full details
    case full       // ~95% - Maximum expansion

    var id: String { String(describing: self) }

    var fraction: CGFloat {
        switch self {
        case .compact: return 0.25
        case .half: return 0.50
        case .expanded: return 0.85
        case .full: return 0.95
        }
    }

    var detent: PresentationDetent {
        switch self {
        case .compact: return .fraction(0.25)
        case .half: return .medium
        case .expanded: return .fraction(0.85)
        case .full: return .large
        }
    }
}

// MARK: - Slidable Bottom Sheet View Modifier

struct SlidableBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedDetent: PresentationDetent
    let detents: Set<PresentationDetent>
    let showDragIndicator: Bool
    let enableInteractiveDismiss: Bool
    let cornerRadius: CGFloat
    let backgroundStyle: SheetBackgroundStyle
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                sheetContent()
                    .presentationDetents(detents, selection: $selectedDetent)
                    .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
                    .presentationCornerRadius(cornerRadius)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationContentInteraction(.scrolls)
                    .interactiveDismissDisabled(!enableInteractiveDismiss)
                    .presentationBackground {
                        sheetBackground
                    }
            }
    }

    @ViewBuilder
    private var sheetBackground: some View {
        switch backgroundStyle {
        case .glass:
            ZStack {
                // Deep void base
                Theme.CelestialColors.voidDeep

                // Glass effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)

                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Theme.CelestialColors.nebulaCore.opacity(0.08),
                        Color.clear,
                        Theme.CelestialColors.plasmaCore.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()

        case .solid(let color):
            color.ignoresSafeArea()

        case .celestial:
            ZStack {
                Theme.CelestialColors.voidDeep

                // Radial gradient for depth
                RadialGradient(
                    colors: [
                        Theme.CelestialColors.nebulaCore.opacity(0.15),
                        Theme.CelestialColors.voidDeep.opacity(0.8),
                        Theme.CelestialColors.void
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
            }
            .ignoresSafeArea()
        }
    }
}

enum SheetBackgroundStyle {
    case glass
    case solid(Color)
    case celestial
}

// MARK: - View Extension

extension View {
    /// Presents a slidable bottom sheet with iOS-native detent behavior
    func slidableBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        selectedDetent: Binding<PresentationDetent> = .constant(.medium),
        detents: Set<PresentationDetent> = [.medium, .large],
        showDragIndicator: Bool = true,
        enableInteractiveDismiss: Bool = true,
        cornerRadius: CGFloat = 32,
        backgroundStyle: SheetBackgroundStyle = .celestial,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(SlidableBottomSheetModifier(
            isPresented: isPresented,
            selectedDetent: selectedDetent,
            detents: detents,
            showDragIndicator: showDragIndicator,
            enableInteractiveDismiss: enableInteractiveDismiss,
            cornerRadius: cornerRadius,
            backgroundStyle: backgroundStyle,
            sheetContent: content
        ))
    }
}

// MARK: - Task Detail Bottom Sheet

/// Premium slidable bottom sheet specifically for task details
/// Provides iOS-native sheet experience with celestial glass styling
struct TaskDetailBottomSheet: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onDuplicate: () -> Void
    let onSnooze: (Date) -> Void
    let onDelete: () -> Void
    let onSchedule: (Date) -> Void
    let onStartTimer: (TaskItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentDetent: PresentationDetent = .medium
    @State private var viewModel = TaskDetailViewModel()
    @State private var appeared = false
    @State private var showCopiedToast = false
    @State private var showSnoozeOptions = false
    @State private var showDeleteConfirm = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Main scrollable content
            ScrollView {
                VStack(spacing: 20) {
                    // Drag indicator area (custom styled)
                    dragIndicatorArea

                    // Task header with completion
                    taskHeader
                        .sectionReveal(appeared: appeared, delay: 0)

                    // Quick action pills
                    quickActions
                        .sectionReveal(appeared: appeared, delay: 0.05)

                    // Sub-tasks section
                    subTasksSection
                        .sectionReveal(appeared: appeared, delay: 0.1)

                    // AI Insights section
                    aiInsightsSection
                        .sectionReveal(appeared: appeared, delay: 0.15)

                    // Notes section
                    notesSection
                        .sectionReveal(appeared: appeared, delay: 0.2)

                    // Focus mode section
                    focusModeSection
                        .sectionReveal(appeared: appeared, delay: 0.25)

                    // Bottom spacer for action bar
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)

            // Sticky bottom action bar
            VStack {
                Spacer()
                bottomActionBar
            }

            // Toast overlay
            if showCopiedToast {
                toastOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            viewModel.setup(task: task)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            Task { await viewModel.loadAIInsights() }
        }
        .confirmationDialog("Snooze Task", isPresented: $showSnoozeOptions) {
            Button("1 Hour") { snoozeFor(hours: 1) }
            Button("3 Hours") { snoozeFor(hours: 3) }
            Button("Tomorrow Morning") { snoozeTomorrowMorning() }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Drag Indicator Area

    private var dragIndicatorArea: some View {
        VStack(spacing: 12) {
            // Custom drag indicator with glow
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.starDim.opacity(0.6),
                            Theme.CelestialColors.starWhite.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 5)
                .shadow(color: Theme.CelestialColors.nebulaCore.opacity(0.3), radius: 4, y: 2)

            // Sheet title
            Text("Task Details")
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Task Header

    private var taskHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            // Completion checkbox
            Button {
                HapticsService.shared.successFeedback()
                onComplete()
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: task.isCompleted
                                    ? [Theme.CelestialColors.auroraGreen]
                                    : [
                                        Theme.CelestialColors.nebulaCore,
                                        Theme.CelestialColors.nebulaEdge,
                                        Theme.CelestialColors.plasmaCore,
                                        Theme.CelestialColors.nebulaCore
                                    ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 32, height: 32)

                    if task.isCompleted {
                        Circle()
                            .fill(Theme.CelestialColors.auroraGreen)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .dynamicTypeFont(base: 14, weight: .bold)
                            .foregroundStyle(.black)
                    }
                }
            }

            // Task title
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.isEditingTitle {
                    TextField("Task title", text: $viewModel.editableTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit { viewModel.isEditingTitle = false }
                } else {
                    Text(viewModel.editableTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .strikethrough(task.isCompleted, color: Theme.CelestialColors.starDim)
                }

                // Priority stars
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { index in
                        Image(systemName: index <= task.starRating ? "star.fill" : "star")
                            .dynamicTypeFont(base: 12, weight: .medium)
                            .foregroundColor(index <= task.starRating ? Color(hex: "FFD700") : Theme.CelestialColors.starGhost)
                    }

                    Text(priorityLabel)
                        .dynamicTypeFont(base: 11, weight: .medium)
                        .foregroundColor(Theme.CelestialColors.starDim)
                        .padding(.leading, 4)
                }
            }

            Spacer()

            // Edit button
            Button {
                HapticsService.shared.selectionFeedback()
                viewModel.isEditingTitle.toggle()
            } label: {
                Image(systemName: "pencil")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.abyss.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Theme.CelestialColors.nebulaCore.opacity(0.3),
                                    Theme.CelestialColors.nebulaEdge.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    private var priorityLabel: String {
        switch task.starRating {
        case 3: return "High Priority"
        case 2: return "Medium Priority"
        default: return "Low Priority"
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            // Duration pill
            QuickActionPill(
                icon: "clock",
                text: viewModel.estimatedMinutes > 0 ? "\(viewModel.estimatedMinutes)m" : "Add",
                color: Theme.CelestialColors.nebulaCore,
                onTap: { viewModel.cycleDuration() }
            )

            // Schedule pill
            QuickActionPill(
                icon: "calendar",
                text: task.scheduledDateFormatted ?? "Today",
                color: Theme.Colors.aiBlue,
                onTap: { viewModel.showSchedulePicker = true }
            )

            // Recurring pill
            QuickActionPill(
                icon: "arrow.triangle.2.circlepath",
                text: task.recurring.displayName,
                color: Theme.Colors.aiAmber,
                onTap: { viewModel.cycleRecurring() }
            )

            Spacer()
        }
    }

    // MARK: - Sub-tasks Section

    private var subTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Sub-tasks")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()

                // Progress
                HStack(spacing: 6) {
                    Text(viewModel.subTasks.progressString)
                        .dynamicTypeFont(base: 13, weight: .medium)
                        .foregroundStyle(Theme.CelestialColors.starDim)

                    // Mini progress ring
                    ZStack {
                        Circle()
                            .stroke(Theme.CelestialColors.starDim.opacity(0.3), lineWidth: 2)
                            .frame(width: 18, height: 18)

                        Circle()
                            .trim(from: 0, to: viewModel.subTasks.progress)
                            .stroke(Theme.CelestialColors.auroraGreen, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 18, height: 18)
                            .rotationEffect(.degrees(-90))
                    }
                }
            }

            // Sub-task list or empty state
            if viewModel.subTasks.isEmpty {
                emptySubTasksState
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.subTasks) { subTask in
                        SubTaskRow(
                            subTask: subTask,
                            onToggle: { viewModel.toggleSubTask(subTask) },
                            onDelete: { viewModel.deleteSubTask(subTask) }
                        )
                    }
                }
            }

            // Add sub-task button
            HStack(spacing: 12) {
                Button {
                    HapticsService.shared.selectionFeedback()
                    viewModel.isAddingSubTask = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .dynamicTypeFont(base: 12, weight: .bold)
                        Text("Add Step")
                            .dynamicTypeFont(base: 13, weight: .medium)
                    }
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                Button {
                    HapticsService.shared.impact()
                    Task { await viewModel.generateAISubTasks() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .dynamicTypeFont(base: 12, weight: .bold)
                        Text("AI Generate")
                            .dynamicTypeFont(base: 13, weight: .medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.CelestialColors.nebulaCore.opacity(0.3), in: Capsule())
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.abyss.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.CelestialColors.starDim.opacity(0.15), lineWidth: 1)
                }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    private var emptySubTasksState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "list.bullet.indent")
                    .dynamicTypeFont(base: 24)
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.5))
                Text("No sub-tasks yet")
                    .dynamicTypeFont(base: 13)
                    .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.7))
            }
            .padding(.vertical, 16)
            Spacer()
        }
    }

    // MARK: - AI Insights Section

    private var aiInsightsHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .dynamicTypeFont(base: 16)
                .foregroundStyle(Theme.CelestialColors.nebulaCore)

            Text("AI Insights")
                .dynamicTypeFont(base: 16, weight: .semibold)
                .foregroundStyle(.white)

            Spacer()

            Button {
                HapticsService.shared.impact()
                Task { await viewModel.loadAIInsights() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .dynamicTypeFont(base: 13, weight: .medium)
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)
                    .rotationEffect(.degrees(viewModel.isLoadingAI ? 360 : 0))
                    .animation(
                        viewModel.isLoadingAI ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: viewModel.isLoadingAI
                    )
            }
            .disabled(viewModel.isLoadingAI)
        }
    }

    private var aiLoadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(Theme.CelestialColors.nebulaCore)
            Text("Analyzing task...")
                .dynamicTypeFont(base: 13)
                .foregroundStyle(Theme.CelestialColors.starDim)
        }
        .padding(.vertical, 12)
    }

    private var aiPromptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI Assistant Prompt")
                .dynamicTypeFont(base: 13, weight: .medium)
                .foregroundStyle(.white.opacity(0.9))

            Text(viewModel.aiPrompt)
                .dynamicTypeFont(base: 13)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(3)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))

            Button {
                UIPasteboard.general.string = viewModel.aiPrompt
                HapticsService.shared.successFeedback()
                withAnimation { showCopiedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showCopiedToast = false }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                        .dynamicTypeFont(base: 12)
                    Text("Copy Prompt")
                        .dynamicTypeFont(base: 13, weight: .medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.Colors.aiPurple.opacity(0.3), in: Capsule())
            }
        }
    }

    private var aiTimeEstimates: some View {
        HStack(spacing: 12) {
            aiEstimatedTimeCard
            aiBestTimeCard
        }
    }

    private var aiEstimatedTimeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(Theme.Colors.aiAmber)
                Text("Estimated")
                    .dynamicTypeFont(base: 11)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            Text(viewModel.aiEstimatedTimeDisplay)
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    private var aiBestTimeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .dynamicTypeFont(base: 12)
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)
                Text("Best Time")
                    .dynamicTypeFont(base: 11)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
            Text(viewModel.aiBestTimeDisplay)
                .dynamicTypeFont(base: 14, weight: .semibold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    private var aiInsightsSectionBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Theme.CelestialColors.abyss.opacity(0.5))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore.opacity(0.25),
                                Theme.CelestialColors.nebulaEdge.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            aiInsightsHeader

            if viewModel.isLoadingAI {
                aiLoadingView
            } else {
                aiPromptSection
                aiTimeEstimates
            }
        }
        .padding(20)
        .background { aiInsightsSectionBackground }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Theme.CelestialColors.nebulaCore)

                Text("Notes")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)

                Spacer()
            }

            TextEditor(text: $viewModel.editableNotes)
                .dynamicTypeFont(base: 14)
                .foregroundStyle(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.editableNotes.isEmpty {
                        Text("Add notes to help focus...")
                            .dynamicTypeFont(base: 14)
                            .foregroundStyle(Theme.CelestialColors.starDim.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.abyss.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.CelestialColors.starDim.opacity(0.15), lineWidth: 1)
                }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Focus Mode Section

    private var focusModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Mode")
                .dynamicTypeFont(base: 16, weight: .semibold)
                .foregroundStyle(.white)

            // Focus mode options
            HStack(spacing: 10) {
                FocusModeOption(
                    icon: "brain.head.profile",
                    title: "Deep Work",
                    isSelected: viewModel.selectedFocusMode == .deepWork,
                    onTap: { viewModel.selectedFocusMode = .deepWork }
                )

                FocusModeOption(
                    icon: "timer",
                    title: "Pomodoro",
                    isSelected: viewModel.selectedFocusMode == .pomodoro,
                    onTap: { viewModel.selectedFocusMode = .pomodoro }
                )

                FocusModeOption(
                    icon: "bolt.fill",
                    title: "Flow",
                    isSelected: viewModel.selectedFocusMode == .flowState,
                    onTap: { viewModel.selectedFocusMode = .flowState }
                )
            }

            // App blocking toggle
            HStack {
                Image(systemName: "shield.fill")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(Theme.Colors.aiAmber)

                Text("Block Distracting Apps")
                    .dynamicTypeFont(base: 14)
                    .foregroundStyle(.white)

                Spacer()

                Toggle("", isOn: $viewModel.appBlockingEnabled)
                    .labelsHidden()
                    .tint(Theme.Colors.aiAmber)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.abyss.opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Theme.CelestialColors.starDim.opacity(0.15), lineWidth: 1)
                }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            // Complete button (primary)
            Button {
                HapticsService.shared.successFeedback()
                onComplete()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "checkmark")
                        .dynamicTypeFont(base: 16, weight: .bold)
                    Text(task.isCompleted ? "Completed" : "Complete")
                        .dynamicTypeFont(base: 15, weight: .semibold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.CelestialColors.auroraGreen, in: RoundedRectangle(cornerRadius: 16))
            }

            // Start Focus button
            Button {
                HapticsService.shared.impact()
                onStartTimer(task)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .dynamicTypeFont(base: 14)
                    Text("Focus")
                        .dynamicTypeFont(base: 15, weight: .semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            // More actions menu
            Menu {
                Button(action: { onDuplicate() }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(action: { showSnoozeOptions = true }) {
                    Label("Snooze", systemImage: "clock.arrow.circlepath")
                }
                Divider()
                Button(role: .destructive, action: { showDeleteConfirm = true }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .dynamicTypeFont(base: 16, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.CelestialColors.starDim.opacity(0.1))
                        .frame(height: 1)
                }
        }
        .glassEffect(.regular, in: Rectangle())
    }

    // MARK: - Toast Overlay

    private var toastOverlay: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.CelestialColors.auroraGreen)

                Text("Copied to clipboard!")
                    .dynamicTypeFont(base: 14, weight: .medium)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 16)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func snoozeFor(hours: Int) {
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date())!
        onSnooze(snoozeDate)
        HapticsService.shared.successFeedback()
        dismiss()
    }

    private func snoozeTomorrowMorning() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let snoozeDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
        onSnooze(snoozeDate)
        HapticsService.shared.successFeedback()
        dismiss()
    }
}

// MARK: - View Extensions

extension View {
    func sectionReveal(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .scaleEffect(appeared ? 1 : 0.96)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8).delay(delay),
                value: appeared
            )
    }
}

// MARK: - Focus Mode Option

struct FocusModeOption: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .dynamicTypeFont(base: 20)
                    .foregroundStyle(isSelected ? Theme.Colors.accent : .white.opacity(0.7))

                Text(title)
                    .dynamicTypeFont(base: 12, weight: .medium)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.accent.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Theme.Colors.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        Color.clear
            .slidableBottomSheet(isPresented: .constant(true)) {
                TaskDetailBottomSheet(
                    task: {
                        let task = TaskItem(title: "Review quarterly presentation")
                        task.starRating = 3
                        task.estimatedMinutes = 45
                        return task
                    }(),
                    onComplete: {},
                    onDuplicate: {},
                    onSnooze: { _ in },
                    onDelete: {},
                    onSchedule: { _ in },
                    onStartTimer: { _ in }
                )
            }
    }
}
