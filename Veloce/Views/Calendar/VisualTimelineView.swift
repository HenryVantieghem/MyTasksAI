//
//  VisualTimelineView.swift
//  MyTasksAI
//
//  Visual Timeline - Tiimo-inspired horizontal day view
//  The signature "wow" feature users will screenshot and share
//

import SwiftUI
import SwiftData

// MARK: - Visual Timeline View

struct VisualTimelineView: View {
    let date: Date
    let tasks: [TaskItem]
    let onTaskTap: (TaskItem) -> Void
    var onTaskReschedule: ((TaskItem, Date) -> Void)? = nil

    @State private var scrollPosition: CGFloat = 0
    @State private var zoomScale: CGFloat = 1.0
    @State private var currentTime = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Timeline configuration
    private let startHour: Int = 6
    private let endHour: Int = 23
    private let baseHourWidth: CGFloat = 120
    private let blockHeight: CGFloat = 60
    private let timelineHeight: CGFloat = 180

    private var hourWidth: CGFloat {
        baseHourWidth * zoomScale
    }

    private var totalWidth: CGFloat {
        CGFloat(endHour - startHour) * hourWidth
    }

    private var currentTimeOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)

        guard hour >= startHour && hour < endHour else { return 0 }

        let hourProgress = CGFloat(hour - startHour)
        let minuteProgress = CGFloat(minute) / 60.0
        return (hourProgress + minuteProgress) * hourWidth
    }

    var body: some View {
        VStack(spacing: 0) {
            // Timeline header
            timelineHeader

            // Main timeline area
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Background with hour grid
                    hourGridBackground

                    // Task blocks layer
                    taskBlocksLayer

                    // Current time indicator (above everything)
                    if Calendar.current.isDateInToday(date) {
                        CurrentTimeIndicator(height: timelineHeight)
                            .offset(x: currentTimeOffset - 40)
                    }
                }
                .frame(width: totalWidth, height: timelineHeight)
                .background(timelineBackground)
            }
            .frame(height: timelineHeight)
            .scrollTargetLayout()
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newScale = zoomScale * value.magnification
                        zoomScale = min(max(newScale, 0.5), 2.0)
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.1),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            // Zoom indicator
            zoomIndicator
        }
        .onAppear {
            startTimeUpdates()
        }
    }

    // MARK: - Timeline Header

    private var timelineHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { hour in
                    HourMarker(hour: hour, width: hourWidth)
                }
            }
        }
        .frame(height: 32)
        .scrollDisabled(true)
    }

    // MARK: - Hour Grid Background

    private var hourGridBackground: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { hour in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: hourWidth, height: timelineHeight)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.08),
                                            .white.opacity(0.02)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 1)
                        }
                }
            }
        }
    }

    // MARK: - Task Blocks Layer

    private var taskBlocksLayer: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Invisible spacer for full width
                    Color.clear
                        .frame(width: totalWidth, height: timelineHeight)

                    // Task blocks
                    ForEach(scheduledTasks) { task in
                        TimeBlockView(
                            task: task,
                            hourWidth: hourWidth,
                            blockHeight: blockHeight,
                            onTap: { onTaskTap(task) },
                            onReschedule: { newTime in
                                onTaskReschedule?(task, newTime)
                            },
                            startHour: startHour
                        )
                        .offset(
                            x: taskXOffset(for: task),
                            y: taskYOffset(for: task)
                        )
                    }

                    // NOW anchor for scrolling
                    if Calendar.current.isDateInToday(date) {
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id("now")
                            .offset(x: currentTimeOffset)
                    }
                }
            }
            .onAppear {
                // Auto-scroll to current time
                if Calendar.current.isDateInToday(date) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            proxy.scrollTo("now", anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Timeline Background

    private var timelineBackground: some View {
        ZStack {
            // Deep void base
            Color(red: 0.02, green: 0.02, blue: 0.05)

            // Subtle nebula gradient
            LinearGradient(
                colors: [
                    Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.05),
                    Color(red: 0.024, green: 0.714, blue: 0.831).opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Starfield dots
            if !reduceMotion {
                StarfieldView()
                    .opacity(0.3)
            }
        }
    }

    // MARK: - Zoom Indicator

    private var zoomIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "minus.magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))

            // Zoom bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.545, green: 0.361, blue: 0.965),
                                    Color(red: 0.024, green: 0.714, blue: 0.831)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * ((zoomScale - 0.5) / 1.5))
                }
            }
            .frame(width: 80, height: 4)

            Image(systemName: "plus.magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))

            Spacer()

            Text("\(Int(zoomScale * 100))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var scheduledTasks: [TaskItem] {
        tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: scheduledTime)
            return hour >= startHour && hour < endHour
        }
    }

    private func taskXOffset(for task: TaskItem) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)

        let hourProgress = CGFloat(hour - startHour)
        let minuteProgress = CGFloat(minute) / 60.0
        return (hourProgress + minuteProgress) * hourWidth
    }

    private func taskYOffset(for task: TaskItem) -> CGFloat {
        // Stack overlapping tasks vertically
        let overlapping = scheduledTasks.filter { other in
            guard let otherTime = other.scheduledTime,
                  let taskTime = task.scheduledTime else { return false }
            return abs(otherTime.timeIntervalSince(taskTime)) < 1800 && other.id != task.id
        }

        let index = overlapping.firstIndex { $0.id == task.id } ?? 0
        return CGFloat(index) * (blockHeight + 8) + 20
    }

    private func startTimeUpdates() {
        guard !reduceMotion else { return }
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Hour Marker

struct HourMarker: View {
    let hour: Int
    let width: CGFloat

    private var hourText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }

    private var isPeakHour: Bool {
        hour >= 9 && hour <= 17
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(hourText)
                .font(.system(size: 11, weight: isPeakHour ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(isPeakHour ? .white.opacity(0.8) : .white.opacity(0.4))

            // Tick mark
            Rectangle()
                .fill(isPeakHour ? .white.opacity(0.3) : .white.opacity(0.15))
                .frame(width: 1, height: isPeakHour ? 8 : 4)
        }
        .frame(width: width)
    }
}

// MARK: - Starfield Background

struct StarfieldView: View {
    var body: some View {
        Canvas { context, size in
            // Generate deterministic star positions
            for i in 0..<50 {
                let seed = Double(i)
                let x = (sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1) * size.width
                let y = (sin(seed * 78.233) * 43758.5453).truncatingRemainder(dividingBy: 1) * size.height
                let starSize = 0.5 + (sin(seed * 3.14159) * 0.5)
                let opacity = 0.3 + (sin(seed * 2.71828) * 0.3)

                let rect = CGRect(
                    x: abs(x) ,
                    y: abs(y),
                    width: starSize,
                    height: starSize
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VisualTimelineView(
            date: Date(),
            tasks: [],
            onTaskTap: { _ in }
        )
        .padding()
    }
}
