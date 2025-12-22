//
//  DynamicPageHeader.swift
//  Veloce
//

import SwiftUI

enum PageType {
    case tasks
    case calendar
    case brainDump
    case settings
}

struct DynamicPageHeader: View {
    let pageType: PageType
    let scrollOffset: CGFloat
    var taskCount: Int = 0
    var completedCount: Int = 0

    private var isCollapsed: Bool { scrollOffset > 20 }
    private var headerHeight: CGFloat { isCollapsed ? 44 : 60 }

    var body: some View {
        HStack {
            switch pageType {
            case .tasks:
                TasksHeader(taskCount: taskCount, completedCount: completedCount, isCollapsed: isCollapsed)
            case .calendar:
                CalendarHeader(isCollapsed: isCollapsed)
            case .brainDump:
                BrainDumpHeader(isCollapsed: isCollapsed)
            case .settings:
                SettingsHeader(isCollapsed: isCollapsed)
            }
        }
        .frame(height: headerHeight)
        .animation(.spring(response: 0.3), value: isCollapsed)
    }
}

struct TasksHeader: View {
    let taskCount: Int
    let completedCount: Int
    let isCollapsed: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: isCollapsed ? 28 : 36, height: isCollapsed ? 28 : 36)
                Circle()
                    .trim(from: 0, to: taskCount > 0 ? CGFloat(completedCount) / CGFloat(taskCount) : 0)
                    .stroke(Theme.Colors.aiPurple, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: isCollapsed ? 28 : 36, height: isCollapsed ? 28 : 36)
                    .rotationEffect(.degrees(-90))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Tasks")
                    .font(isCollapsed ? .subheadline.bold() : .headline.bold())
                    .foregroundStyle(.white)
                if !isCollapsed {
                    Text("\(completedCount)/\(taskCount) completed")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            // AI readiness orb
            AIOrb(size: .tiny, animationStyle: .idle)
        }
        .padding(.horizontal)
    }
}

struct CalendarHeader: View {
    let isCollapsed: Bool
    @State private var weekProgress: CGFloat = 0.6

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(isCollapsed ? .subheadline.bold() : .headline.bold())
                    .foregroundStyle(.white)
                if !isCollapsed {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                            Capsule().fill(Theme.Colors.aiBlue).frame(width: geo.size.width * weekProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct BrainDumpHeader: View {
    let isCollapsed: Bool
    @State private var particlePhase: CGFloat = 0

    var body: some View {
        HStack {
            if !isCollapsed {
                NeuralParticles()
                    .frame(width: 40, height: 40)
            }
            Text("Clear your mind")
                .font(isCollapsed ? .subheadline : .headline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct NeuralParticles: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Theme.Colors.aiPurple.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .offset(x: cos(phase + CGFloat(i) * .pi / 3) * 15,
                            y: sin(phase + CGFloat(i) * .pi / 3) * 15)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { phase = .pi * 2 }
        }
    }
}

struct SettingsHeader: View {
    let isCollapsed: Bool

    var body: some View {
        HStack {
            Text("Settings")
                .font(isCollapsed ? .subheadline.bold() : .headline.bold())
                .foregroundStyle(.white)
            Spacer()
            // Pro badge
            Text("PRO")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(LinearGradient(colors: [Theme.Colors.aiGold, .orange], startPoint: .leading, endPoint: .trailing))
                .clipShape(Capsule())
        }
        .padding(.horizontal)
    }
}
