//
//  TiimoEventBlock.swift
//  Veloce
//
//  Apple Calendar Event Display Block
//  Shows EventKit events in the Tiimo-style timeline
//

import SwiftUI
import EventKit

// MARK: - Tiimo Event Block

/// Display block for Apple Calendar events
struct TiimoEventBlock: View {
    let event: EKEvent
    let hourHeight: CGFloat
    let startHour: Int

    @State private var isPressed = false

    // MARK: - Computed Properties

    /// Block height based on event duration
    private var blockHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        let height = CGFloat(duration) / 60.0 * hourHeight
        return max(height, 24)
    }

    /// Y offset based on start time
    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    /// Event calendar color
    private var eventColor: Color {
        if let cgColor = event.calendar.cgColor {
            return Color(cgColor: cgColor)
        }
        return Theme.Colors.aiBlue
    }

    /// Whether this is a compact block
    private var isCompact: Bool {
        blockHeight < 40
    }

    /// Formatted time range
    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(eventColor)
                .frame(width: 4)

            // Event info
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Untitled Event")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(isCompact ? 1 : 2)

                if !isCompact {
                    Text(timeRange)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }

                if !isCompact, let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 8))
                        Text(location)
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                }
            }

            Spacer()

            // Calendar badge
            if blockHeight > 50 {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                    .foregroundStyle(eventColor.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(height: blockHeight)
        .frame(maxWidth: .infinity)
        .background(eventBackground)
        .overlay(eventBorder)
        .offset(y: yOffset)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(TiimoDesignTokens.Animation.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews

    private var eventBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(eventColor.opacity(0.12))
    }

    private var eventBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(eventColor.opacity(0.25), lineWidth: 1)
    }

    private var accessibilityLabel: String {
        var label = event.title ?? "Untitled Event"
        label += ", \(timeRange)"

        if let location = event.location, !location.isEmpty {
            label += ", at \(location)"
        }

        return label
    }
}

// MARK: - Compact Event Block (for Week View)

/// Smaller event block for week view
struct TiimoCompactEventBlock: View {
    let event: EKEvent
    let hourHeight: CGFloat
    let startHour: Int

    private var blockHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate) / 60
        let height = CGFloat(duration) / 60.0 * hourHeight
        return max(height, 20)
    }

    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private var eventColor: Color {
        if let cgColor = event.calendar.cgColor {
            return Color(cgColor: cgColor)
        }
        return Theme.Colors.aiBlue
    }

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1)
                .fill(eventColor)
                .frame(width: 2)

            Text(event.title ?? "Event")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(height: blockHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(eventColor.opacity(0.1))
        )
        .offset(y: yOffset)
    }
}

// MARK: - All Day Event Banner

/// Banner for all-day events at the top of the timeline
struct TiimoAllDayEventBanner: View {
    let events: [EKEvent]

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                    HStack(spacing: 8) {
                        SwiftUI.Circle()
                            .fill(eventColor(for: event))
                            .frame(width: 8, height: 8)

                        Text(event.title ?? "All Day")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)

                        Spacer()
                    }
                }

                if events.count > 3 {
                    Text("+\(events.count - 3) more")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, TiimoDesignTokens.Timeline.timeGutterWidth + 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 12)
        }
    }

    private func eventColor(for event: EKEvent) -> Color {
        if let cgColor = event.calendar.cgColor {
            return Color(cgColor: cgColor)
        }
        return Theme.Colors.aiBlue
    }
}

// MARK: - Preview

#Preview("Event Block") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 100) {
            // Mock event (can't preview real EKEvent without EventStore)
            Text("Event blocks require EventKit context")
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
    }
}
