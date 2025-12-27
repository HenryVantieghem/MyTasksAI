//
//  SmartStackSection.swift
//  Veloce
//
//  Collapsible section component for task detail sheet
//  Smart Stack layout with smooth expand/collapse
//

import SwiftUI

// MARK: - Smart Stack Section (Collapsible)

struct SmartStackSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (tap to toggle)
            Button(action: toggleExpanded) {
                HStack(spacing: 10) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                        .frame(width: 20)

                    // Title
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.CelestialColors.starWhite)

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.CelestialColors.starDim)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.CelestialColors.nebulaDust.opacity(0.5))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("\(title), \(isExpanded ? "expanded" : "collapsed")")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
            .accessibilityAddTraits(.isButton)

            // Content (animated)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding(.top, 12)
                .padding(.horizontal, 4)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
    }

    private func toggleExpanded() {
        HapticsService.shared.selectionFeedback()

        if reduceMotion {
            isExpanded.toggle()
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Smart Section Fixed (Non-collapsible)

struct SmartSectionFixed<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.CelestialColors.starWhite)

                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.CelestialColors.nebulaDust.opacity(0.5))
            )

            // Content
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Danger Zone Section

struct DangerZoneSection: View {
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 12) {
            // Duplicate button
            Button(action: {
                HapticsService.shared.selectionFeedback()
                onDuplicate()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                    Text("Duplicate Task")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Theme.CelestialColors.starDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.CelestialColors.nebulaDust.opacity(0.3))
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                    Text("Delete Task")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Theme.CelestialColors.errorNebula)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.CelestialColors.errorNebula.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Theme.CelestialColors.errorNebula.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .confirmationDialog(
                "Delete Task",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    HapticsService.shared.notification(.warning)
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Compact Header Section

struct CompactHeaderSection: View {
    let title: String
    let taskType: TaskType
    let priority: Int
    let isEditing: Bool
    let onTitleChange: (String) -> Void
    let onPriorityChange: (Int) -> Void

    @State private var editedTitle: String = ""
    @FocusState private var isTitleFocused: Bool

    private var taskTypeColor: Color {
        switch taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Task type badge
            HStack(spacing: 6) {
                Circle()
                    .fill(taskTypeColor)
                    .frame(width: 8, height: 8)

                Text(taskType.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(taskTypeColor)
                    .tracking(1.2)
            }

            // Title (inline editable)
            if isEditing {
                TextField("Task title", text: $editedTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.CelestialColors.starWhite)
                    .focused($isTitleFocused)
                    .onAppear {
                        editedTitle = title
                    }
                    .onChange(of: editedTitle) { _, newValue in
                        onTitleChange(newValue)
                    }
                    .onSubmit {
                        isTitleFocused = false
                    }
            } else {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.CelestialColors.starWhite)
                    .lineLimit(3)
            }

            // Priority stars
            InlineStarRating(
                rating: priority,
                onChange: onPriorityChange
            )
        }
    }
}

// MARK: - Inline Star Rating

struct InlineStarRating: View {
    let rating: Int
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { star in
                Button(action: {
                    HapticsService.shared.selectionFeedback()
                    onChange(star)
                }) {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(star <= rating ? Theme.TaskCardColors.pointsGlow : Theme.CelestialColors.starGhost)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                SmartStackSection(
                    title: "Schedule",
                    icon: "calendar",
                    iconColor: Theme.CelestialColors.plasmaCore,
                    isExpanded: .constant(true)
                ) {
                    Text("Schedule content here")
                        .foregroundColor(.white)
                }

                SmartStackSection(
                    title: "Details",
                    icon: "doc.text",
                    iconColor: Theme.TaskCardColors.create,
                    isExpanded: .constant(false)
                ) {
                    Text("Details content here")
                        .foregroundColor(.white)
                }

                DangerZoneSection(
                    onDuplicate: { print("Duplicate") },
                    onDelete: { print("Delete") }
                )
            }
            .padding()
        }
    }
}
