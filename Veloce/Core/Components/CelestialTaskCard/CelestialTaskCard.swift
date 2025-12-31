//
//  CelestialTaskCard.swift
//  Veloce
//
//  Living Cosmos Expanded Task Card
//  Spatial computing portal with floating glass islands
//  Features: Cinematic transition, staggered reveals, floating sections, star field
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

// MARK: - Celestial Task Card (Living Cosmos Edition)

struct CelestialTaskCard: View {
    let task: TaskItem
    weak var delegate: TaskActionDelegate?
    @Binding var isPresented: Bool

    @State private var viewModel: CelestialTaskCardViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var showDeleteConfirmation = false

    // Living Cosmos animation states
    @State private var sectionsRevealed = false
    @State private var backgroundBlur: CGFloat = 0
    @State private var starShift: CGFloat = 0
    @State private var nebulaPhase: CGFloat = 0

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization

    init(task: TaskItem, delegate: TaskActionDelegate? = nil, isPresented: Binding<Bool>) {
        self.task = task
        self.delegate = delegate
        self._isPresented = isPresented
        // Use preloaded ViewModel if available, otherwise create new one
        let vm = TaskCardPreloadService.shared.getViewModel(for: task)
        self._viewModel = State(initialValue: vm)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cinematic portal background
                portalBackground(size: geometry.size)

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
            animatePortalOpen()
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
            NavigationStack {
                FocusTabView(
                    taskContext: FocusTaskContext(task: task),
                    onSessionComplete: { completed in
                        if completed {
                            delegate?.taskDidComplete(task)
                            viewModel.showFocusMode = false
                            dismissCard()
                        } else {
                            viewModel.showFocusMode = false
                        }
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            viewModel.showFocusMode = false
                        }
                    }
                }
            }
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

    // MARK: - Portal Background

    private func portalBackground(size: CGSize) -> some View {
        ZStack {
            // Deep void base
            Theme.CelestialColors.voidDeep
                .ignoresSafeArea()

            // Radial blur emanating from center (portal effect)
            RadialGradient(
                colors: [
                    Color.clear,
                    Theme.CelestialColors.void.opacity(0.6),
                    Theme.CelestialColors.void
                ],
                center: .center,
                startRadius: 80,
                endRadius: 500
            )
            .blur(radius: backgroundBlur)
            .ignoresSafeArea()

            // Shifting star field
            if !reduceMotion {
                StarFieldView(shift: starShift, density: .medium)
                    .opacity(0.5)
                    .ignoresSafeArea()
            }

            // Task type nebula glow
            RadialGradient(
                colors: [
                    viewModel.taskTypeColor.opacity(0.2),
                    viewModel.taskTypeColor.opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3, y: 0.1),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            // Secondary aurora glow
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaEdge.opacity(0.1 + (nebulaPhase * 0.05)),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.6),
                startRadius: 0,
                endRadius: 250
            )
            .ignoresSafeArea()

            // Tap to dismiss area
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismissCard() }
        }
    }

    // MARK: - Sheet Content

    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Plasma drag handle
            plasmaDragHandle

            // Scrollable content - floating glass islands
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg + 4) {
                    // Header Section (Always visible, first to appear)
                    CelestialHeaderSection(viewModel: viewModel)
                        .floatingIsland(depth: 0.9, floatPhase: 0)
                        .staggeredReveal(isVisible: sectionsRevealed, delay: 0, direction: .scale)

                    // Task Details Island
                    FloatingIslandSection(
                        title: "Details",
                        icon: "doc.text",
                        accentColor: viewModel.taskTypeColor
                    ) {
                        CelestialTaskDetailsSection(viewModel: viewModel)
                    }
                    .staggeredReveal(isVisible: sectionsRevealed, delay: Theme.Animation.staggerDelay * 1, direction: .fromBottom)

                    // AI Genius Island (Oracle Container)
                    FloatingIslandSection(
                        title: "AI Genius",
                        icon: "sparkles",
                        accentColor: Theme.CelestialColors.nebulaCore
                    ) {
                        CelestialAIGeniusSection(viewModel: viewModel)
                    }
                    .staggeredReveal(isVisible: sectionsRevealed, delay: Theme.Animation.staggerDelay * 2, direction: .fromBottom)

                    // Recurring Island
                    FloatingIslandSection(
                        title: "Recurring",
                        icon: "repeat",
                        accentColor: Theme.CelestialColors.nebulaGlow
                    ) {
                        CelestialRecurringSectionWrapper(viewModel: viewModel)
                    }
                    .staggeredReveal(isVisible: sectionsRevealed, delay: Theme.Animation.staggerDelay * 3, direction: .fromBottom)

                    // Schedule Island
                    FloatingIslandSection(
                        title: "Schedule",
                        icon: "calendar",
                        accentColor: Theme.CelestialColors.nebulaEdge
                    ) {
                        CelestialScheduleSection(viewModel: viewModel)
                    }
                    .staggeredReveal(isVisible: sectionsRevealed, delay: Theme.Animation.staggerDelay * 4, direction: .fromBottom)

                    // Focus Island
                    FloatingIslandSection(
                        title: "Focus Mode",
                        icon: "scope",
                        accentColor: Theme.CelestialColors.plasmaCore
                    ) {
                        CelestialFocusSection(viewModel: viewModel)
                    }
                    .staggeredReveal(isVisible: sectionsRevealed, delay: Theme.Animation.staggerDelay * 5, direction: .fromBottom)

                    // App Blocking Island
                    FloatingIslandSection(
                        title: "App Blocking",
                        icon: "shield.lefthalf.filled",
                        accentColor: Theme.CelestialColors.urgencyNear
                    ) {
                        AppBlockingModule(
                            task: task,
                            enableBlocking: $viewModel.enableAppBlocking
                        ) { _ in
                            viewModel.hasUnsavedChanges = true
                        }
                    }
                    .staggeredReveal(isVisible: sectionsRevealed, delay: Theme.Animation.staggerDelay * 6, direction: .fromBottom)

                    // Quick Actions Orbs
                    CosmicQuickActions(
                        onComplete: completeTask,
                        onDuplicate: duplicateTask,
                        onSnooze: snoozeTask,
                        onDelete: { showDeleteConfirmation = true }
                    )
                    .staggeredReveal(isVisible: sectionsRevealed, delay: Theme.Animation.staggerDelay * 7, direction: .fromBottom)

                    // Bottom padding
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.top, Theme.Spacing.md)
            }
            .scrollIndicators(.hidden)
        }
        .background(sheetBackground)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 32,
                style: .continuous
            )
        )
    }

    // MARK: - Plasma Drag Handle

    private var plasmaDragHandle: some View {
        ZStack {
            // Outer plasma glow
            Capsule()
                .fill(viewModel.taskTypeColor.opacity(0.4))
                .frame(width: 80, height: 12)
                .blur(radius: 12)

            // Inner glow ring
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.CelestialColors.plasmaCore.opacity(0.6),
                            viewModel.taskTypeColor.opacity(0.4),
                            Theme.CelestialColors.nebulaEdge.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 50, height: 6)
                .blur(radius: 4)

            // Handle core
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.6),
                            .white.opacity(0.3),
                            viewModel.taskTypeColor.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 44, height: 5)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 0.5)
                }
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
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

    private func animatePortalOpen() {
        guard !reduceMotion else {
            contentOpacity = 1
            sectionsRevealed = true
            return
        }

        // Phase 1: Fade in content
        withAnimation(Theme.Animation.portalOpen) {
            contentOpacity = 1
        }

        // Phase 2: Background blur effect
        withAnimation(.easeOut(duration: 0.6)) {
            backgroundBlur = 15
        }

        // Phase 3: Star field shift
        withAnimation(.easeOut(duration: 0.8)) {
            starShift = 25
        }

        // Phase 4: Trigger staggered section reveals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(Theme.Animation.stellarBounce) {
                sectionsRevealed = true
            }
        }

        // Phase 5: Ambient nebula animation
        withAnimation(
            .easeInOut(duration: 6)
            .repeatForever(autoreverses: true)
        ) {
            nebulaPhase = 1
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

// MARK: - Floating Island Section

/// Glass island container for expanded card sections
struct FloatingIslandSection<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    let content: Content

    @State private var floatOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: String,
        icon: String,
        accentColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack(spacing: Theme.Spacing.sm) {
                // Glowing icon
                ZStack {
                    SwiftUI.Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .blur(radius: 4)

                    Image(systemName: icon)
                        .dynamicTypeFont(base: 11, weight: .semibold)
                        .foregroundStyle(accentColor)
                }

                Text(title.uppercased())
                    .font(Theme.Typography.cosmosSectionHeader)
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .tracking(1.5)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.bottom, 4)

            // Content
            content
        }
        .padding(Theme.Spacing.md)
        .background {
            // Accent tint layer
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.08),
                            accentColor.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            accentColor.opacity(0.2),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        // Floating shadow
        .shadow(
            color: accentColor.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        // Ambient float
        .offset(y: floatOffset)
        .onAppear {
            if !reduceMotion {
                withAnimation(
                    Theme.Animation.orbitalFloat
                        .delay(Double.random(in: 0...0.5))
                ) {
                    floatOffset = 3
                }
            }
        }
    }
}

// MARK: - Cosmic Quick Actions

/// Floating action orbs for task operations
struct CosmicQuickActions: View {
    let onComplete: () -> Void
    let onDuplicate: () -> Void
    let onSnooze: () -> Void
    let onDelete: () -> Void

    @State private var hoveredAction: ActionType?

    enum ActionType: CaseIterable {
        case complete, duplicate, snooze, delete

        var icon: String {
            switch self {
            case .complete: return "checkmark"
            case .duplicate: return "plus.square.on.square"
            case .snooze: return "moon.zzz"
            case .delete: return "trash"
            }
        }

        var label: String {
            switch self {
            case .complete: return "Complete"
            case .duplicate: return "Duplicate"
            case .snooze: return "Snooze"
            case .delete: return "Delete"
            }
        }

        var color: Color {
            switch self {
            case .complete: return Theme.CelestialColors.auroraGreen
            case .duplicate: return Theme.CelestialColors.nebulaCore
            case .snooze: return Theme.CelestialColors.nebulaGlow
            case .delete: return Theme.CelestialColors.urgencyCritical
            }
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            actionOrb(.complete, action: onComplete)
            actionOrb(.duplicate, action: onDuplicate)
            actionOrb(.snooze, action: onSnooze)
            actionOrb(.delete, action: onDelete)
        }
        .padding(.vertical, Theme.Spacing.md)
    }

    private func actionOrb(_ type: ActionType, action: @escaping () -> Void) -> some View {
        Button {
            HapticsService.shared.selectionFeedback()
            action()
        } label: {
            VStack(spacing: 6) {
                // Orb
                ZStack {
                    // Glow
                    SwiftUI.Circle()
                        .fill(type.color.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)

                    // Glass orb with native Liquid Glass
                    ZStack {
                        // Color tint layer
                        SwiftUI.Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        type.color.opacity(0.2),
                                        type.color.opacity(0.08),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 30
                                )
                            )

                        // Icon
                        Image(systemName: type.icon)
                            .dynamicTypeFont(base: 18, weight: .medium)
                            .foregroundStyle(type.color)
                    }
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular, in: SwiftUI.Circle())
                }
                .shadow(color: type.color.opacity(0.3), radius: 8, x: 0, y: 4)

                // Label
                Text(type.label)
                    .font(Theme.Typography.cosmosMetaSmall)
                    .foregroundStyle(Theme.CelestialColors.starDim)
            }
        }
        .buttonStyle(OrbButtonStyle())
    }
}

// MARK: - Orb Button Style

private struct OrbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(Theme.Animation.stellarBounce, value: configuration.isPressed)
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
