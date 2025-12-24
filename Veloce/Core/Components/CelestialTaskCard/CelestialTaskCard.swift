//
//  CelestialTaskCard.swift
//  Veloce
//
//  Unified task card combining all features from GeniusTaskSheet,
//  TaskDetailSheet, and PremiumTaskDetailView into one celestial experience.
//

import SwiftUI
import SwiftData

// MARK: - Task Action Delegate

protocol TaskActionDelegate: AnyObject {
    func taskDidComplete(_ task: TaskItem)
    func taskDidDelete(_ task: TaskItem)
    func taskDidDuplicate(_ task: TaskItem)
    func taskDidSnooze(_ task: TaskItem)
}

// MARK: - Celestial Task Card

struct CelestialTaskCard: View {
    let task: TaskItem
    weak var delegate: TaskActionDelegate?
    @Binding var isPresented: Bool

    @State private var viewModel: CelestialTaskCardViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var showDeleteConfirmation = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization

    init(task: TaskItem, delegate: TaskActionDelegate? = nil, isPresented: Binding<Bool>) {
        self.task = task
        self.delegate = delegate
        self._isPresented = isPresented
        self._viewModel = State(initialValue: CelestialTaskCardViewModel(task: task))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { dismissCard() }

                // Main sheet - Full page expansion
                VStack(spacing: 0) {
                    sheetContent
                        .frame(maxHeight: geometry.size.height)
                        .offset(y: dragOffset)
                        .gesture(dragGesture)
                }
            }
        }
        .opacity(contentOpacity)
        .task {
            viewModel.setup(context: modelContext)
            await viewModel.loadAllData()
            animateIn()
        }
        .onDisappear {
            if viewModel.hasUnsavedChanges {
                viewModel.saveChanges()
            }
            viewModel.cleanup()
        }
        .confirmationDialog(
            "Delete Task",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteTask()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(task.title)'?")
        }
        .fullScreenCover(isPresented: $viewModel.showFocusMode) {
            FocusMode(task: task)
        }
        .sheet(isPresented: $viewModel.showCalendarScheduling) {
            CalendarSchedulingSheet(task: task)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showSchedulePicker) {
            CelestialSchedulePickerSheet(
                selectedDate: $viewModel.editedScheduledTime,
                task: task
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Sheet Content

    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Drag handle
            celestialDragHandle

            // Scrollable content - continuous layout (no collapsible sections)
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    // Header Section (Always visible)
                    CelestialHeaderSection(viewModel: viewModel)

                    // Task Details Section
                    CelestialSectionDivider.taskDetails()
                    CelestialTaskDetailsSection(viewModel: viewModel)

                    // AI Genius Section
                    CelestialSectionDivider.aiGenius()
                    CelestialAIGeniusSection(viewModel: viewModel)

                    // Recurring Section (NEW - dedicated section)
                    CelestialSectionDivider.recurring()
                    CelestialRecurringSectionWrapper(viewModel: viewModel)

                    // Schedule Section
                    CelestialSectionDivider.schedule()
                    CelestialScheduleSection(viewModel: viewModel)

                    // Focus Section
                    CelestialSectionDivider.focus()
                    CelestialFocusSection(viewModel: viewModel)

                    // App Blocking Section
                    AppBlockingModule(
                        task: task,
                        enableBlocking: $viewModel.enableAppBlocking
                    ) { _ in
                        viewModel.hasUnsavedChanges = true
                    }

                    // Quick Actions (Always visible)
                    CelestialQuickActions(
                        onComplete: completeTask,
                        onDuplicate: duplicateTask,
                        onSnooze: snoozeTask,
                        onDelete: { showDeleteConfirmation = true }
                    )

                    // Bottom padding for safe area
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.top, Theme.Spacing.md)
            }
            .scrollIndicators(.hidden)
        }
        .background(sheetBackground)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28,
                style: .continuous
            )
        )
    }

    // MARK: - Celestial Drag Handle

    private var celestialDragHandle: some View {
        ZStack {
            // Glow effect behind handle
            Capsule()
                .fill(viewModel.taskTypeColor.opacity(0.3))
                .frame(width: 60, height: 8)
                .blur(radius: 8)

            // Handle itself
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.4),
                            .white.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 5)
                .glassEffect(.regular, in: .capsule)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Sheet Background

    private var sheetBackground: some View {
        ZStack {
            // Base cosmic void
            Theme.CelestialColors.void

            // Nebula gradient from task type color
            LinearGradient(
                colors: [
                    viewModel.taskTypeColor.opacity(0.15),
                    Theme.CelestialColors.nebulaGlow.opacity(0.08),
                    Theme.CelestialColors.nebulaEdge.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Aurora effect
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 300
            )

            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.2)
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow dragging down
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                // Dismiss if dragged far enough or fast enough
                if value.translation.height > 150 || value.velocity.height > 1000 {
                    dismissCard()
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Animations

    private func animateIn() {
        guard !reduceMotion else {
            contentOpacity = 1
            return
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            contentOpacity = 1
        }
    }

    private func dismissCard() {
        // Save any unsaved changes
        if viewModel.hasUnsavedChanges {
            viewModel.saveChanges()
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            contentOpacity = 0
            dragOffset = 500
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    // MARK: - Task Actions

    private func completeTask() {
        HapticsService.shared.celebration()
        delegate?.taskDidComplete(task)
        dismissCard()
    }

    private func duplicateTask() {
        HapticsService.shared.softImpact()
        delegate?.taskDidDuplicate(task)
        dismissCard()
    }

    private func snoozeTask() {
        HapticsService.shared.softImpact()
        delegate?.taskDidSnooze(task)
        dismissCard()
    }

    private func deleteTask() {
        HapticsService.shared.warning()
        delegate?.taskDidDelete(task)
        dismissCard()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TaskItem.self, configurations: config)

    let sampleTask = TaskItem(title: "Complete project proposal")
    sampleTask.starRating = 3
    container.mainContext.insert(sampleTask)

    return CelestialTaskCard(
        task: sampleTask,
        isPresented: .constant(true)
    )
    .modelContainer(container)
}
