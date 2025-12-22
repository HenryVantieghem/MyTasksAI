//
//  TimeBlockView.swift
//  MyTasksAI
//
//  Time Block View - Nebula-like task visualization
//  Color-coded blocks representing scheduled tasks
//

import SwiftUI

// MARK: - Time Block View

struct TimeBlockView: View {
    let task: TaskItem
    let hourWidth: CGFloat
    let blockHeight: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var glowPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Calculate block width based on duration
    private var blockWidth: CGFloat {
        let duration = task.estimatedMinutes ?? 30
        return CGFloat(duration) / 60.0 * hourWidth
    }

    // Get color based on TaskType
    private var taskColor: Color {
        switch task.taskType {
        case .create:
            return Color(red: 0.545, green: 0.361, blue: 0.965) // #8B5CF6 Purple
        case .communicate:
            return Color(red: 0.231, green: 0.510, blue: 0.965) // #3B82F6 Blue
        case .consume:
            return Color(red: 0.024, green: 0.714, blue: 0.831) // #06B6D4 Cyan
        case .coordinate:
            return Color(red: 0.961, green: 0.420, blue: 0.420) // #F56B6B Coral/Orange
        }
    }

    private var taskIcon: String {
        switch task.taskType {
        case .create: return "paintbrush.fill"
        case .communicate: return "bubble.left.fill"
        case .consume: return "book.fill"
        case .coordinate: return "person.2.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                // Glow background
                glowBackground

                // Main block
                mainBlock

                // Content
                blockContent
            }
            .frame(width: max(blockWidth, 60), height: blockHeight)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = 1
            }
        }
        .accessibilityLabel("\(task.title), \(task.taskType.rawValue) task")
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Glow Background

    private var glowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                RadialGradient(
                    colors: [
                        taskColor.opacity(0.4 + glowPhase * 0.2),
                        taskColor.opacity(0.1),
                        .clear
                    ],
                    center: .leading,
                    startRadius: 0,
                    endRadius: blockWidth * 0.8
                )
            )
            .blur(radius: 12)
            .offset(x: -10)
    }

    // MARK: - Main Block

    private var mainBlock: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        taskColor.opacity(0.9),
                        taskColor.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Glass shine
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                // Border
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                taskColor.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: taskColor.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    // MARK: - Block Content

    private var blockContent: some View {
        HStack(spacing: 8) {
            // Task type icon
            Image(systemName: taskIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            // Task title
            if blockWidth > 80 {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Duration badge
            if blockWidth > 100, let minutes = task.estimatedMinutes {
                Text("\(minutes)m")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.15))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Compact Time Block (for overlapping tasks)

struct CompactTimeBlock: View {
    let task: TaskItem
    let color: Color
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(task.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            // Create task
            TimeBlockView(
                task: {
                    let t = TaskItem(title: "Design new feature mockups")
                    t.estimatedMinutes = 90
                    t.taskTypeRaw = TaskType.create.rawValue
                    return t
                }(),
                hourWidth: 120,
                blockHeight: 60,
                onTap: {}
            )

            // Communicate task
            TimeBlockView(
                task: {
                    let t = TaskItem(title: "Team standup")
                    t.estimatedMinutes = 30
                    t.taskTypeRaw = TaskType.communicate.rawValue
                    return t
                }(),
                hourWidth: 120,
                blockHeight: 60,
                onTap: {}
            )

            // Consume task
            TimeBlockView(
                task: {
                    let t = TaskItem(title: "Read documentation")
                    t.estimatedMinutes = 45
                    t.taskTypeRaw = TaskType.consume.rawValue
                    return t
                }(),
                hourWidth: 120,
                blockHeight: 60,
                onTap: {}
            )

            // Coordinate task
            TimeBlockView(
                task: {
                    let t = TaskItem(title: "Project planning")
                    t.estimatedMinutes = 60
                    t.taskTypeRaw = TaskType.coordinate.rawValue
                    return t
                }(),
                hourWidth: 120,
                blockHeight: 60,
                onTap: {}
            )
        }
        .padding()
    }
}
