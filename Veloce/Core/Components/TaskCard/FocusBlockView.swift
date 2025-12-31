//
//  FocusBlockView.swift
//  Veloce
//
//  Hero card for the most urgent/in-progress task
//  Large, prominent, with "Start Focus" action
//

import SwiftUI

// MARK: - Focus Block View

struct FocusBlockView: View {
    let task: TaskItem
    let onTap: () -> Void
    let onStartFocus: () -> Void
    let onComplete: () -> Void

    @State private var breathePhase: CGFloat = 0
    @State private var glowIntensity: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed Properties

    private var taskTypeColor: Color {
        switch task.taskType {
        case .create: return Theme.TaskCardColors.create
        case .communicate: return Theme.TaskCardColors.communicate
        case .consume: return Theme.TaskCardColors.consume
        case .coordinate: return Theme.TaskCardColors.coordinate
        }
    }

    private var urgencyText: String? {
        guard let scheduledTime = task.scheduledTime else { return nil }
        let hoursUntil = scheduledTime.timeIntervalSince(Date()) / 3600

        if hoursUntil < 0 {
            return "Overdue"
        } else if hoursUntil < 1 {
            let minutes = Int(hoursUntil * 60)
            return "Due in \(minutes)m"
        } else if hoursUntil < 4 {
            return "Due in \(Int(hoursUntil))h"
        }
        return nil
    }

    private var urgencyColor: Color {
        guard let scheduledTime = task.scheduledTime else {
            return Theme.CelestialColors.plasmaCore
        }

        let hoursUntil = scheduledTime.timeIntervalSince(Date()) / 3600
        if hoursUntil < 0 {
            return Theme.CelestialColors.urgencyCritical
        } else if hoursUntil < 1 {
            return Theme.CelestialColors.urgencyCritical
        } else if hoursUntil < 4 {
            return Theme.CelestialColors.urgencyNear
        }
        return Theme.CelestialColors.plasmaCore
    }

    /// Determines if task is "in progress" (high priority or scheduled soon)
    private var isInProgress: Bool {
        // High priority (3 stars) tasks are always "in progress"
        if task.starRating == 3 {
            return true
        }

        // Tasks scheduled within the next 2 hours are "in progress"
        if let scheduledTime = task.scheduledTime {
            let hoursUntil = scheduledTime.timeIntervalSince(Date()) / 3600
            if hoursUntil <= 2 && hoursUntil >= -1 {
                return true
            }
        }

        return false
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Top: Status badge + urgency
                HStack {
                    statusBadge

                    Spacer()

                    if let urgency = urgencyText {
                        urgencyBadge(urgency)
                    }
                }

                // Title
                Text(task.title)
                    .dynamicTypeFont(base: 22, weight: .semibold)
                    .foregroundColor(Theme.CelestialColors.starWhite)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // AI guidance
                if let advice = task.aiAdvice, !advice.isEmpty {
                    Text(advice)
                        .dynamicTypeFont(base: 14, weight: .regular)
                        .foregroundColor(Theme.CelestialColors.starDim)
                        .lineLimit(2)
                        .italic()
                }

                // Bottom: Action buttons
                HStack(spacing: 12) {
                    // Complete button
                    Button(action: onComplete) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .dynamicTypeFont(base: 14, weight: .semibold)
                            Text("Complete")
                                .dynamicTypeFont(base: 14, weight: .semibold)
                        }
                        .foregroundColor(Theme.CelestialColors.starWhite)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Theme.CelestialColors.auroraGreen.opacity(0.3))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Theme.CelestialColors.auroraGreen.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Focus button (primary)
                    Button(action: onStartFocus) {
                        HStack(spacing: 6) {
                            Image(systemName: "scope")
                                .dynamicTypeFont(base: 14, weight: .semibold)
                            Text("Start Focus")
                                .dynamicTypeFont(base: 14, weight: .bold)
                        }
                        .foregroundColor(Theme.CelestialColors.void)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [taskTypeColor, taskTypeColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: taskTypeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Points indicator
                    pointsIndicator
                }
            }
            .padding(20)
            .background(cardBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    breathePhase = 1
                    glowIntensity = 0.8
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), focus task")
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Components

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(taskTypeColor)
                .frame(width: 8, height: 8)
                .scaleEffect(1 + breathePhase * 0.2)

            Text(isInProgress ? "IN PROGRESS" : "UP NEXT")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(taskTypeColor)
                .tracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(taskTypeColor.opacity(0.15))
        )
    }

    private func urgencyBadge(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .dynamicTypeFont(base: 10)
            Text(text)
                .dynamicTypeFont(base: 11, weight: .semibold)
        }
        .foregroundColor(urgencyColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(urgencyColor.opacity(0.15))
        )
    }

    private var pointsIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .dynamicTypeFont(base: 12)
            Text("+\(task.pointsEarned > 0 ? task.pointsEarned : 25)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
        .foregroundColor(Theme.TaskCardColors.pointsGlow)
    }

    private var cardBackground: some View {
        ZStack {
            // Base
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.CelestialColors.abyss)

            // Gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            taskTypeColor.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            taskTypeColor.opacity(0.4 * glowIntensity),
                            taskTypeColor.opacity(0.2 * glowIntensity),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // Outer glow
            RoundedRectangle(cornerRadius: 20)
                .stroke(taskTypeColor.opacity(0.2 * glowIntensity), lineWidth: 4)
                .blur(radius: 8)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack {
            Text("FocusBlockView Preview")
                .foregroundColor(.white)
                .padding()

            // Preview would need a sample TaskItem
        }
    }
}
