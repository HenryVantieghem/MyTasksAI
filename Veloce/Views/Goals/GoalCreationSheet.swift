//
//  GoalCreationSheet.swift
//  MyTasksAI
//
//  Goal Creation Sheet
//  Premium flow for setting new goals with AI refinement
//

import SwiftUI
import SwiftData

struct GoalCreationSheet: View {
    @Bindable var goalsVM: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Form State
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: GoalCategory = .personal
    @State private var selectedTimeframe: GoalTimeframe = .milestone
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    // MARK: - UI State
    @State private var isCreating = false
    @State private var showDatePicker = false
    @State private var animateIn = false

    @FocusState private var titleFocused: Bool

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var suggestedDate: Date {
        selectedTimeframe.suggestedTargetDate(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                VoidBackground.standard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header illustration
                        headerOrb
                            .padding(.top, 20)

                        // Title input
                        titleSection

                        // Category selector
                        categorySection

                        // Timeframe selector
                        timeframeSection

                        // Target date
                        dateSection

                        // Optional description
                        descriptionSection

                        // Create button
                        createButton
                            .padding(.top, 12)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateIn = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    titleFocused = true
                }
            }
            .onChange(of: selectedTimeframe) { _, newTimeframe in
                withAnimation(.easeInOut(duration: 0.3)) {
                    targetDate = newTimeframe.suggestedTargetDate(from: Date())
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    // MARK: - Header Orb

    private var headerOrb: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            selectedTimeframe.color.opacity(0.3),
                            selectedTimeframe.color.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)

            // Inner orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            selectedTimeframe.color.opacity(0.4),
                            Theme.CelestialColors.void
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    selectedTimeframe.color.opacity(0.6),
                                    selectedTimeframe.color.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            // Icon
            Image(systemName: selectedTimeframe.icon)
                .font(.system(size: 36))
                .foregroundStyle(selectedTimeframe.color)
        }
        .scaleEffect(animateIn ? 1 : 0.5)
        .opacity(animateIn ? 1 : 0)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("What's your goal?", systemImage: "target")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            CrystallineTextField(
                text: $title,
                placeholder: "e.g., Launch my side project",
                icon: "target"
            )
            .focused($titleFocused)
        }
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Category", systemImage: "folder")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GoalCategory.allCases, id: \.rawValue) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateIn)
    }

    // MARK: - Timeframe Section

    private var timeframeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Timeframe", systemImage: "calendar.badge.clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 10) {
                ForEach(GoalTimeframe.allCases, id: \.rawValue) { timeframe in
                    TimeframePillButton(
                        timeframe: timeframe,
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTimeframe = timeframe
                        }
                    }
                }
            }

            // Timeframe description
            Text(selectedTimeframe.detailedDescription)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: animateIn)
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Target Date", systemImage: "flag.checkered")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            Button {
                showDatePicker.toggle()
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundStyle(selectedTimeframe.color)

                    Text(targetDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()

                    if let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day {
                        Text("\(days) days")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if showDatePicker {
                DatePicker(
                    "Target Date",
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(selectedTimeframe.color)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.5))
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity
                ))
            }
        }
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateIn)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Description", systemImage: "text.alignleft")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Text("(Optional)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }

            TextEditor(text: $description)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.aiPurple)

                Text("AI will refine your goal into SMART format")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: animateIn)
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            Task {
                await createGoal()
            }
        } label: {
            HStack(spacing: 12) {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                }

                Text(isCreating ? "Creating..." : "Create & Generate Roadmap")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if canCreate {
                        LinearGradient(
                            colors: [selectedTimeframe.color, selectedTimeframe.color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.white.opacity(0.1)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: canCreate ? selectedTimeframe.color.opacity(0.4) : .clear,
                radius: 16,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(!canCreate || isCreating)
        .offset(y: animateIn ? 0 : 20)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateIn)
    }

    // MARK: - Actions

    private func createGoal() async {
        guard canCreate else { return }

        isCreating = true

        let goal = await goalsVM.createGoal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            category: selectedCategory,
            timeframe: selectedTimeframe,
            targetDate: targetDate,
            context: modelContext
        )

        // Generate AI roadmap
        await goalsVM.generateRoadmap(for: goal, context: modelContext)

        isCreating = false
        dismiss()
    }
}

// MARK: - Category Pill

private struct CategoryPill: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : category.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : category.color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(category.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeframe Pill Button

private struct TimeframePillButton: View {
    let timeframe: GoalTimeframe
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? timeframe.color : timeframe.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: timeframe.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : timeframe.color)
                }

                Text(timeframe.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                Text(timeframe.durationLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? timeframe.color.opacity(0.2) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? timeframe.color.opacity(0.5) : .white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeframe Extension

extension GoalTimeframe {
    var description: String {
        switch self {
        case .sprint:
            return "Perfect for quick wins and immediate focus areas"
        case .milestone:
            return "Ideal for meaningful projects that need sustained effort"
        case .horizon:
            return "Big-picture aspirations that shape your year"
        }
    }

    var durationLabel: String {
        switch self {
        case .sprint: return "1-2 weeks"
        case .milestone: return "1-3 months"
        case .horizon: return "3-12 months"
        }
    }

    func suggestedTargetDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .sprint:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .milestone:
            return calendar.date(byAdding: .month, value: 2, to: date) ?? date
        case .horizon:
            return calendar.date(byAdding: .month, value: 6, to: date) ?? date
        }
    }
}

// MARK: - Preview

#Preview {
    GoalCreationSheet(goalsVM: GoalsViewModel())
        .modelContainer(for: [Goal.self, TaskItem.self])
}
