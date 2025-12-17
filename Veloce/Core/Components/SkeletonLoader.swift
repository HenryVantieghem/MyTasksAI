//
//  SkeletonLoader.swift
//  Veloce
//
//  Skeleton Loading Components
//  Provides shimmer effect loading placeholders
//

import SwiftUI

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if !reduceMotion {
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                        .mask(content)
                    }
                }
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Shape

struct SkeletonShape: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Theme.Colors.textTertiary.opacity(0.3))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Task Row Skeleton

struct TaskRowSkeleton: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Checkbox skeleton
            Circle()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 24, height: 24)
                .shimmer()

            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                // Title
                SkeletonShape(width: .random(in: 120...200), height: 16)

                // Metadata row
                HStack(spacing: Theme.Spacing.sm) {
                    SkeletonShape(width: 40, height: 12, cornerRadius: 2)
                    SkeletonShape(width: 50, height: 12, cornerRadius: 2)
                }
            }

            Spacer()

            // Priority indicator skeleton
            Circle()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityLabel("Loading task")
        .accessibilityHidden(true)
    }
}

// MARK: - Task List Skeleton

struct TaskListSkeleton: View {
    let rowCount: Int

    init(rowCount: Int = 5) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<rowCount, id: \.self) { index in
                TaskRowSkeleton()
                    .opacity(1 - (Double(index) * 0.15))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Stats Bar Skeleton

struct StatsBarSkeleton: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 4) {
                    SkeletonShape(width: 50, height: 18, cornerRadius: 4)
                    SkeletonShape(width: 35, height: 12, cornerRadius: 2)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityHidden(true)
    }
}

// MARK: - Calendar Skeleton

struct CalendarSkeleton: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header skeleton
            HStack {
                SkeletonShape(width: 44, height: 44, cornerRadius: 22)
                Spacer()
                SkeletonShape(width: 120, height: 20, cornerRadius: 4)
                Spacer()
                SkeletonShape(width: 44, height: 44, cornerRadius: 22)
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Calendar grid skeleton
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Theme.Spacing.sm) {
                ForEach(0..<21, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonShape(width: 20, height: 10, cornerRadius: 2)
                        Circle()
                            .fill(Theme.Colors.textTertiary.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .shimmer()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Goal Row Skeleton

struct GoalRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                SkeletonShape(width: .random(in: 100...180), height: 18)
                Spacer()
            }

            SkeletonShape(width: .random(in: 150...250), height: 14)

            // Progress bar
            SkeletonShape(height: 4, cornerRadius: 2)

            SkeletonShape(width: 80, height: 12, cornerRadius: 2)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityHidden(true)
    }
}

// MARK: - Generic Content Skeleton

struct ContentSkeleton: View {
    let lines: Int

    init(lines: Int = 3) {
        self.lines = lines
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(0..<lines, id: \.self) { index in
                SkeletonShape(
                    width: index == lines - 1 ? 150 : nil,
                    height: 14
                )
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        IridescentBackground()

        ScrollView {
            VStack(spacing: 30) {
                Text("Skeleton Loaders")
                    .font(Theme.Typography.title2)

                Group {
                    Text("Stats Bar Skeleton")
                        .font(Theme.Typography.headline)
                    StatsBarSkeleton()
                }

                Group {
                    Text("Task List Skeleton")
                        .font(Theme.Typography.headline)
                    TaskListSkeleton(rowCount: 3)
                }

                Group {
                    Text("Goal Row Skeleton")
                        .font(Theme.Typography.headline)
                    GoalRowSkeleton()
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .padding()
        }
    }
}
