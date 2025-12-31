//
//  AIActionsTray.swift
//  Veloce
//
//  Expanded AI Actions Tray with beautiful grid layout
//  and advanced AI features for the Floating Island Task Input
//

import SwiftUI

// MARK: - AI Enhance Action (Expanded)

enum AIEnhanceAction: String, CaseIterable, Identifiable {
    // Original actions
    case enhance = "Enhance"
    case estimateTime = "Time"
    case categorize = "Priority"
    case breakDown = "Break Down"

    // New expanded actions
    case smartSchedule = "Smart Schedule"
    case findSimilar = "Find Similar"
    case autoTag = "Auto Tag"
    case summarize = "Summarize"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .enhance: return "wand.and.stars"
        case .estimateTime: return "clock.badge.checkmark"
        case .categorize: return "star.circle"
        case .breakDown: return "list.bullet.indent"
        case .smartSchedule: return "calendar.badge.clock"
        case .findSimilar: return "doc.on.doc"
        case .autoTag: return "tag.fill"
        case .summarize: return "text.alignleft"
        }
    }

    var description: String {
        switch self {
        case .enhance: return "Rewrite clearer"
        case .estimateTime: return "Estimate duration"
        case .categorize: return "Suggest priority"
        case .breakDown: return "Split into steps"
        case .smartSchedule: return "Find best time"
        case .findSimilar: return "Match existing"
        case .autoTag: return "Add categories"
        case .summarize: return "Make concise"
        }
    }

    var color: Color {
        switch self {
        case .enhance: return Theme.Colors.aiPurple
        case .estimateTime: return Theme.Colors.aiBlue
        case .categorize: return Theme.Colors.aiOrange
        case .breakDown: return Theme.Colors.aiCyan
        case .smartSchedule: return Theme.Colors.aiGreen
        case .findSimilar: return Theme.Colors.aiPink
        case .autoTag: return Theme.CelestialColors.nebulaCore
        case .summarize: return Color.white
        }
    }

    /// Primary actions shown in the main grid
    static var primaryActions: [AIEnhanceAction] {
        [.enhance, .estimateTime, .categorize, .breakDown]
    }

    /// Secondary actions shown in the expanded section
    static var secondaryActions: [AIEnhanceAction] {
        [.smartSchedule, .findSimilar, .autoTag, .summarize]
    }
}

// MARK: - AI Enhance Sheet (Redesigned)

struct AIEnhanceSheet: View {
    @Binding var text: String
    @Binding var isProcessing: Bool
    let onEnhance: (AIEnhanceAction) -> Void
    let onDismiss: () -> Void

    @State private var selectedAction: AIEnhanceAction?
    @State private var showExpandedActions = false
    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Task Preview Card
                    taskPreviewCard

                    // Primary AI Actions Grid
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(title: "AI Enhancements", icon: "sparkles")

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AIEnhanceAction.primaryActions) { action in
                                AIActionButton(
                                    action: action,
                                    isSelected: selectedAction == action,
                                    isProcessing: isProcessing && selectedAction == action
                                ) {
                                    selectedAction = action
                                    HapticsService.shared.selectionFeedback()
                                    onEnhance(action)
                                }
                            }
                        }
                    }

                    // Expandable Secondary Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(Theme.Animation.springBouncy) {
                                showExpandedActions.toggle()
                            }
                            HapticsService.shared.lightImpact()
                        } label: {
                            HStack(spacing: 8) {
                                sectionHeader(title: "More Actions", icon: "ellipsis.circle")

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .dynamicTypeFont(base: 12, weight: .semibold)
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(showExpandedActions ? 180 : 0))
                            }
                        }
                        .buttonStyle(.plain)

                        if showExpandedActions {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(AIEnhanceAction.secondaryActions) { action in
                                    AIActionButton(
                                        action: action,
                                        isSelected: selectedAction == action,
                                        isProcessing: isProcessing && selectedAction == action
                                    ) {
                                        selectedAction = action
                                        HapticsService.shared.selectionFeedback()
                                        onEnhance(action)
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Color.clear)
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Task Preview Card

    private var taskPreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .dynamicTypeFont(base: 11, weight: .semibold)

                Text("Your Task")
                    .dynamicTypeFont(base: 12, weight: .semibold)
            }
            .foregroundStyle(.secondary)

            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .dynamicTypeFont(base: 12, weight: .semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(title)
                .dynamicTypeFont(base: 13, weight: .semibold)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - AI Action Button

struct AIActionButton: View {
    let action: AIEnhanceAction
    let isSelected: Bool
    let isProcessing: Bool
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 10) {
                // Icon with glow
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(action.color.opacity(isSelected ? 0.4 : 0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                        .scaleEffect(isSelected ? 1.1 : 1.0)

                    // Icon circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    action.color.opacity(isSelected ? 0.35 : 0.18),
                                    action.color.opacity(isSelected ? 0.2 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(action.color.opacity(isSelected ? 0.5 : 0.2), lineWidth: 1)
                        }

                    // Icon or processing indicator
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(action.color)
                    } else {
                        Image(systemName: action.icon)
                            .dynamicTypeFont(base: 16, weight: .semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [action.color, action.color.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .symbolEffect(.bounce, value: isSelected)
                    }
                }

                // Labels
                VStack(spacing: 2) {
                    Text(action.rawValue)
                        .dynamicTypeFont(base: 12, weight: .semibold)
                        .foregroundStyle(.primary)

                    Text(action.description)
                        .dynamicTypeFont(base: 10, weight: .regular)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                isSelected ? action.color.opacity(0.15) : Color.white.opacity(0.06),
                                isSelected ? action.color.opacity(0.08) : Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        // Shimmer effect when processing
                        if isProcessing && !reduceMotion {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: action.color.opacity(0.3), location: 0.5),
                                            .init(color: .clear, location: 1)
                                        ],
                                        startPoint: UnitPoint(x: shimmerOffset / 200, y: 0),
                                        endPoint: UnitPoint(x: shimmerOffset / 200 + 0.5, y: 1)
                                    )
                                )
                                .mask(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                    ? action.color.opacity(0.4)
                                    : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .accessibilityLabel("\(action.rawValue): \(action.description)")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            if isProcessing && !reduceMotion {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
        }
        .onChange(of: isProcessing) { _, newValue in
            if newValue && !reduceMotion {
                shimmerOffset = -200
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
        }
    }
}

// MARK: - Compact AI Actions Row (for inline use)

struct CompactAIActionsRow: View {
    let onAction: (AIEnhanceAction) -> Void
    @State private var selectedAction: AIEnhanceAction?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AIEnhanceAction.primaryActions) { action in
                    CompactAIActionChip(
                        action: action,
                        isSelected: selectedAction == action
                    ) {
                        selectedAction = action
                        HapticsService.shared.selectionFeedback()
                        onAction(action)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct CompactAIActionChip: View {
    let action: AIEnhanceAction
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: action.icon)
                    .dynamicTypeFont(base: 12, weight: .semibold)

                Text(action.rawValue)
                    .dynamicTypeFont(base: 12, weight: .medium)
            }
            .foregroundStyle(
                isSelected
                    ? action.color
                    : .secondary
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(
                        isSelected
                            ? action.color.opacity(0.15)
                            : Color.white.opacity(0.06)
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                isSelected
                                    ? action.color.opacity(0.4)
                                    : Color.white.opacity(0.1),
                                lineWidth: 0.5
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("AI Enhance Sheet") {
    AIEnhanceSheet(
        text: .constant("Call mom tomorrow at 5pm about the birthday party"),
        isProcessing: .constant(false),
        onEnhance: { _ in },
        onDismiss: { }
    )
    .preferredColorScheme(.dark)
}

#Preview("Compact AI Actions") {
    CompactAIActionsRow(onAction: { _ in })
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
