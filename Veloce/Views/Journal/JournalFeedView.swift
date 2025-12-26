//
//  JournalFeedView.swift
//  Veloce
//
//  Beautiful Journal Feed - Apple Notes/Journal inspired rich experience
//  Date navigation, entry type filters, and stunning entry cards
//

import SwiftUI
import SwiftData

// MARK: - Journal Colors

enum JournalColors {
    // Entry Type Colors (Living Cosmos palette)
    static let brainDump = Theme.CelestialColors.starDim
    static let reminder = Theme.CelestialColors.solarFlare
    static let gratitude = Color(red: 0.98, green: 0.45, blue: 0.65)  // Warm rose
    static let reflection = Theme.CelestialColors.nebulaCore

    // Mood Colors
    static let excellent = Theme.CelestialColors.auroraGreen
    static let good = Theme.CelestialColors.plasmaCore
    static let neutral = Theme.CelestialColors.starDim
    static let low = Theme.CelestialColors.nebulaGlow
    static let stressed = Theme.CelestialColors.solarFlare

    static func colorFor(entryType: JournalEntryType) -> Color {
        switch entryType {
        case .brainDump: return brainDump
        case .reminder: return reminder
        case .gratitude: return gratitude
        case .reflection: return reflection
        }
    }

    static func colorFor(mood: JournalMood) -> Color {
        switch mood {
        case .excellent: return excellent
        case .good: return good
        case .neutral: return neutral
        case .low: return low
        case .stressed: return stressed
        }
    }
}

// MARK: - Journal Feed View

struct JournalFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = JournalFeedViewModel()
    @State private var showEditor = false
    @State private var selectedEntry: JournalEntry?
    @State private var newEntryType: JournalEntryType = .brainDump
    @State private var showSearch = false
    @State private var isLoaded = false

    var body: some View {
        ZStack {
            // Background - Living Cosmos journal variant
            VoidBackground.journal

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Date Navigation Header
                    dateNavigationHeader
                        .padding(.top, Theme.Spacing.universalHeaderHeight)

                    // Entry Type Filters
                    entryTypeFilters

                    // AI Daily Prompt Card
                    if let prompt = viewModel.dailyPrompt {
                        JournalAIPromptCard(prompt: prompt) {
                            newEntryType = .reflection
                            showEditor = true
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                    }

                    // Gratitude Streak (if applicable)
                    if viewModel.gratitudeStreak > 0 && viewModel.selectedFilter == .gratitude {
                        GratitudeStreakCard(streak: viewModel.gratitudeStreak)
                    }

                    // Journal Entries
                    if viewModel.filteredEntries.isEmpty {
                        emptyState
                    } else {
                        entriesGrid
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenPadding)
                .padding(.bottom, 140)
            }

            // Floating Create Button
            VStack {
                Spacer()
                createEntryButton
                    .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setup(context: modelContext)
            withAnimation(Theme.Animation.spring.delay(0.3)) {
                isLoaded = true
            }
        }
        .onChange(of: viewModel.selectedDate) { _, newDate in
            Task {
                await viewModel.loadEntries(for: newDate)
            }
        }
        .sheet(isPresented: $showEditor) {
            JournalEditorSheet(
                viewModel: viewModel,
                entry: selectedEntry,
                entryType: newEntryType
            )
        }
        .sheet(isPresented: $showSearch) {
            JournalSearchView(viewModel: viewModel)
        }
    }

    // MARK: - Date Navigation Header (Liquid Glass)

    private var dateNavigationHeader: some View {
        HStack(spacing: 12) {
            // Previous day
            Button {
                HapticsService.shared.selectionFeedback()
                viewModel.previousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: SwiftUI.Circle())

            // Date Pill with Liquid Glass
            Button {
                HapticsService.shared.selectionFeedback()
                viewModel.showDatePicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .medium))

                    Text(viewModel.formattedSelectedDate)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))

                    if viewModel.isToday {
                        Text("Today")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.CelestialColors.auroraGreen.opacity(0.3), in: Capsule())
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: Capsule())

            // Next day
            Button {
                HapticsService.shared.selectionFeedback()
                viewModel.nextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: SwiftUI.Circle())

            Spacer()

            // Search button
            Button {
                HapticsService.shared.selectionFeedback()
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: SwiftUI.Circle())
        }
        .sheet(isPresented: $viewModel.showDatePicker) {
            DatePickerSheet(selectedDate: $viewModel.selectedDate)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Entry Type Filters

    private var entryTypeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All filter
                JournalFilterPill(
                    label: "All",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedFilter == nil,
                    color: Theme.Colors.aiPurple
                ) {
                    HapticsService.shared.selectionFeedback()
                    withAnimation(Theme.Animation.spring) {
                        viewModel.selectedFilter = nil
                    }
                }

                // Entry type filters
                ForEach(JournalEntryType.allCases, id: \.self) { type in
                    JournalFilterPill(
                        label: type.displayName,
                        icon: type.icon,
                        isSelected: viewModel.selectedFilter == type,
                        color: JournalColors.colorFor(entryType: type)
                    ) {
                        HapticsService.shared.selectionFeedback()
                        withAnimation(Theme.Animation.spring) {
                            viewModel.selectedFilter = type
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Entries Grid

    private var entriesGrid: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            ForEach(Array(viewModel.filteredEntries.enumerated()), id: \.element.id) { index, entry in
                JournalFeedEntryCard(entry: entry, index: index, isLoaded: isLoaded)
                    .onTapGesture {
                        HapticsService.shared.impact()
                        selectedEntry = entry
                        newEntryType = entry.entryType
                        showEditor = true
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        JournalEmptyState(entryType: viewModel.selectedFilter) {
            if let filter = viewModel.selectedFilter {
                newEntryType = filter
            }
            showEditor = true
        }
    }

    // MARK: - Create Entry Button

    private var createEntryButton: some View {
        Menu {
            ForEach(JournalEntryType.allCases, id: \.self) { type in
                Button {
                    HapticsService.shared.impact()
                    newEntryType = type
                    selectedEntry = nil
                    showEditor = true
                } label: {
                    Label(type.displayName, systemImage: type.icon)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))

                Text("New Entry")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .shadow(color: Theme.Colors.aiPurple.opacity(0.4), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Pill (Liquid Glass)

struct JournalFilterPill: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))

                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    Capsule()
                        .fill(color.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Journal Entry Card

struct JournalFeedEntryCard: View {
    let entry: JournalEntry
    let index: Int
    let isLoaded: Bool

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var entryColor: Color {
        JournalColors.colorFor(entryType: entry.entryType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header: Type badge + Time + Mood
            HStack {
                // Entry type badge
                HStack(spacing: 6) {
                    Image(systemName: entry.entryType.icon)
                        .font(.system(size: 11, weight: .semibold))

                    Text(entry.entryType.displayName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(entryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(entryColor.opacity(0.2))
                }

                Spacer()

                // Time
                Text(entry.formattedTime)
                    .font(Theme.Typography.cosmosMeta)
                    .foregroundStyle(Theme.CelestialColors.starGhost)

                // Mood indicator
                if let mood = entry.mood {
                    Text(mood.emoji)
                        .font(.system(size: 16))
                }

                // Pinned/Favorite indicators
                if entry.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.CelestialColors.solarFlare)
                }

                if entry.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(JournalColors.gratitude)
                }
            }

            // Title (if exists)
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(Theme.Typography.cosmosTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            // Preview text
            if !entry.previewText.isEmpty {
                Text(entry.previewText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Theme.CelestialColors.starDim)
                    .lineLimit(3)
                    .lineSpacing(2)
            }

            // Media indicators
            if entry.hasMedia {
                HStack(spacing: 12) {
                    if entry.photoCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 11))
                            Text("\(entry.photoCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                    }

                    if entry.hasDrawing {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.tip")
                                .font(.system(size: 11))
                            Text("Drawing")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                    }

                    if entry.recordingCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 11))
                            Text("\(entry.recordingCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                    }

                    Spacer()

                    // Word count
                    if entry.wordCount > 0 {
                        Text("\(entry.wordCount) words")
                            .font(Theme.Typography.cosmosMeta)
                            .foregroundStyle(Theme.CelestialColors.starGhost)
                    }
                }
            }

            // AI Summary (if available)
            if let summary = entry.aiSummary, !summary.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))

                    Text(summary)
                        .font(Theme.Typography.cosmosWhisperSmall)
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.CelestialColors.nebulaCore.opacity(0.8))
                .padding(.top, 4)
            }
        }
        .padding(LivingCosmos.FloatingIsland.padding)
        .background {
            // Subtle entry color tint
            RoundedRectangle(cornerRadius: LivingCosmos.FloatingIsland.cornerRadius)
                .fill(entryColor.opacity(0.03))
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LivingCosmos.FloatingIsland.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LivingCosmos.FloatingIsland.cornerRadius)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(color: entryColor.opacity(0.12), radius: 8, y: 3)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            guard !reduceMotion else {
                isVisible = true
                return
            }

            withAnimation(
                Theme.Animation.spring
                    .delay(Double(index) * Theme.Animation.staggerDelay)
            ) {
                isVisible = isLoaded
            }
        }
        .onChange(of: isLoaded) { _, loaded in
            guard !reduceMotion else {
                isVisible = loaded
                return
            }

            withAnimation(
                Theme.Animation.spring
                    .delay(Double(index) * Theme.Animation.staggerDelay)
            ) {
                isVisible = loaded
            }
        }
    }
}

// MARK: - AI Prompt Card

struct JournalAIPromptCard: View {
    let prompt: String
    let onTap: () -> Void

    @State private var isGlowing = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)

                    Text("Today's Reflection")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.CelestialColors.nebulaCore)
                }

                Text(prompt)
                    .font(Theme.Typography.cosmosWhisper)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
                    .lineSpacing(4)
            }
            .padding(Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore.opacity(0.15),
                                Theme.CelestialColors.nebulaGlow.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.CelestialColors.nebulaCore.opacity(0.4),
                                Theme.CelestialColors.nebulaGlow.opacity(0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Theme.CelestialColors.nebulaCore.opacity(isGlowing ? 0.3 : 0.15), radius: isGlowing ? 20 : 12, y: 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(Theme.Animation.plasmaPulse) {
                isGlowing = true
            }
        }
    }
}

// MARK: - Gratitude Streak Card

struct GratitudeStreakCard: View {
    let streak: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Flame icon with glow
            ZStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.Colors.streakOrange)
                    .blur(radius: 6)

                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiOrange, Theme.Colors.fire],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) Day Streak!")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Keep the gratitude flowing")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Streak number
            Text("\(streak)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.aiOrange, Theme.Colors.fire],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .padding(Theme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.streakOrange.opacity(0.15),
                            Theme.Colors.fire.opacity(0.08),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.streakOrange.opacity(0.3), lineWidth: 0.5)
        }
    }
}

// MARK: - Journal Empty State

struct JournalEmptyState: View {
    let entryType: JournalEntryType?
    let onCreate: () -> Void

    private var title: String {
        if let type = entryType {
            return "No \(type.displayName) Entries"
        }
        return "No Entries Yet"
    }

    private var subtitle: String {
        if let type = entryType {
            return type.placeholder
        }
        return "Start capturing your thoughts, feelings, and reflections"
    }

    private var icon: String {
        entryType?.icon ?? "book.pages"
    }

    private var color: Color {
        if let type = entryType {
            return JournalColors.colorFor(entryType: type)
        }
        return Theme.Colors.aiPurple
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
                .frame(height: 40)

            // Animated icon
            ZStack {
                SwiftUI.Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 100, height: 100)

                SwiftUI.Circle()
                    .stroke(color.opacity(0.2), lineWidth: 1)
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(color.opacity(0.6))
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            // Benefits of journaling
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                benefitRow(icon: "brain.head.profile", text: "Clear your mind")
                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your growth")
                benefitRow(icon: "heart.text.square", text: "Process emotions")
            }
            .padding(.top, Theme.Spacing.lg)

            // Create button
            Button(action: onCreate) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Start Your First Entry")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background {
                    Capsule()
                        .fill(color)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, Theme.Spacing.lg)

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color.opacity(0.6))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Theme.Colors.aiPurple)
                .padding()

                Spacer()
            }
            .background(Theme.CelestialColors.void)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Today") {
                        selectedDate = Date()
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Journal Search View (Placeholder)

struct JournalSearchView: View {
    let viewModel: JournalFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: JournalEntryType?
    @State private var selectedMood: JournalMood?
    @State private var dateRange: ClosedRange<Date>?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.CelestialColors.void
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    // Search bar
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.5))

                        TextField("Search entries...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                    .padding(Theme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.08))
                    }
                    .padding(.horizontal)

                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(JournalEntryType.allCases, id: \.self) { type in
                                JournalFilterPill(
                                    label: type.displayName,
                                    icon: type.icon,
                                    isSelected: selectedFilter == type,
                                    color: JournalColors.colorFor(entryType: type)
                                ) {
                                    if selectedFilter == type {
                                        selectedFilter = nil
                                    } else {
                                        selectedFilter = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Results would go here
                    Spacer()

                    Text("Search results will appear here")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()
                }
                .padding(.top, Theme.Spacing.lg)
            }
            .navigationTitle("Search Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    JournalFeedView()
        .modelContainer(for: [JournalEntry.self], inMemory: true)
}
