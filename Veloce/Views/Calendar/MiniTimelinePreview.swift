//
//  MiniTimelinePreview.swift
//  MyTasksAI
//
//  Mini timeline visualization for calendar scheduling
//  Shows existing events and new task slot
//

import SwiftUI
import EventKit

// MARK: - Mini Timeline Preview
struct MiniTimelinePreview: View {
    let scheduledDate: Date
    let duration: Int
    let existingEvents: [EKEvent]

    private let hourHeight: CGFloat = 35
    private let leftColumnWidth: CGFloat = 45

    // Show hours around the scheduled time
    private var visibleHourRange: ClosedRange<Int> {
        let scheduledHour = Calendar.current.component(.hour, from: scheduledDate)
        let startHour = max(0, scheduledHour - 2)
        let endHour = min(23, scheduledHour + 4)
        return startHour...endHour
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Hour lines
                    hourLines

                    // Existing events (dimmed)
                    ForEach(existingEvents, id: \.eventIdentifier) { event in
                        eventBlock(for: event)
                    }

                    // New scheduled task (highlighted)
                    newTaskBlock
                }
                .padding(.vertical, Theme.Spacing.sm)
            }
            .onAppear {
                // Scroll to scheduled hour
                let hour = Calendar.current.component(.hour, from: scheduledDate)
                proxy.scrollTo(max(0, hour - 1), anchor: .top)
            }
            .onChange(of: scheduledDate) { _, _ in
                let hour = Calendar.current.component(.hour, from: scheduledDate)
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(max(0, hour - 1), anchor: .top)
                }
            }
        }
    }

    // MARK: - Hour Lines
    private var hourLines: some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleHourRange), id: \.self) { hour in
                HStack(spacing: 0) {
                    // Hour label
                    Text(formatHour(hour))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: leftColumnWidth, alignment: .trailing)
                        .padding(.trailing, 8)

                    // Hour line
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                }
                .frame(height: hourHeight)
                .id(hour)
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    // MARK: - Event Block
    private func eventBlock(for event: EKEvent) -> some View {
        let startHour = Calendar.current.component(.hour, from: event.startDate)
        let startMinute = Calendar.current.component(.minute, from: event.startDate)
        let durationMinutes = Int(event.endDate.timeIntervalSince(event.startDate) / 60)

        let yOffset = CGFloat(startHour - visibleHourRange.lowerBound) * hourHeight +
                      CGFloat(startMinute) / 60 * hourHeight
        let height = max(CGFloat(durationMinutes) / 60 * hourHeight, 20)

        return RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text(event.title ?? "Event")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2),
                alignment: .topLeading
            )
            .frame(height: height)
            .padding(.leading, leftColumnWidth + 8)
            .padding(.trailing, 8)
            .offset(y: yOffset)
    }

    // MARK: - New Task Block
    private var newTaskBlock: some View {
        let hour = Calendar.current.component(.hour, from: scheduledDate)
        let minute = Calendar.current.component(.minute, from: scheduledDate)

        let yOffset = CGFloat(hour - visibleHourRange.lowerBound) * hourHeight +
                      CGFloat(minute) / 60 * hourHeight
        let height = max(CGFloat(duration) / 60 * hourHeight, 24)

        return RoundedRectangle(cornerRadius: 8)
            .fill(Theme.Colors.aiPurple.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.Colors.aiPurple, lineWidth: 2)
            )
            .overlay(
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 10))
                    Text("New Task")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Theme.Colors.aiPurple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4),
                alignment: .topLeading
            )
            .frame(height: height)
            .padding(.leading, leftColumnWidth + 8)
            .padding(.trailing, 8)
            .offset(y: yOffset)
            .shadow(color: Theme.Colors.aiPurple.opacity(0.3), radius: 8)
    }
}

// MARK: - Current Time Indicator
struct TimelineCurrentTimeIndicator: View {
    let hourHeight: CGFloat
    let leftColumnWidth: CGFloat

    @State private var currentTime = Date()

    var body: some View {
        let hour = Calendar.current.component(.hour, from: currentTime)
        let minute = Calendar.current.component(.minute, from: currentTime)
        let yOffset = CGFloat(hour) * hourHeight + CGFloat(minute) / 60 * hourHeight

        HStack(spacing: 0) {
            SwiftUI.Circle()
                .fill(Theme.Colors.destructive)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(Theme.Colors.destructive)
                .frame(height: 1)
        }
        .padding(.leading, leftColumnWidth)
        .offset(y: yOffset - 4)
        .onAppear {
            // Update every minute
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        MiniTimelinePreview(
            scheduledDate: Date().addingTimeInterval(3600), // 1 hour from now
            duration: 45,
            existingEvents: []
        )
        .frame(height: 200)
        .padding()
    }
}
