//
//  NotionTimelineGrid.swift
//  Veloce
//
//  Notion Calendar-Inspired Hour Grid
//  Clean, minimal timeline background with whisper-thin grid lines
//

import SwiftUI

// MARK: - Notion Timeline Grid

struct NotionTimelineGrid: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat

    init(
        startHour: Int = NotionCalendarTokens.Timeline.startHour,
        endHour: Int = NotionCalendarTokens.Timeline.endHour,
        hourHeight: CGFloat = NotionCalendarTokens.Timeline.hourHeight
    ) {
        self.startHour = startHour
        self.endHour = endHour
        self.hourHeight = hourHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                hourRow(for: hour)
            }
        }
    }

    private func hourRow(for hour: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour label
            Text(formatHour(hour))
                .font(NotionCalendarTokens.Typography.hourLabel)
                .foregroundStyle(NotionCalendarTokens.Colors.hourLabel)
                .frame(width: NotionCalendarTokens.Timeline.timeGutterWidth, alignment: .trailing)
                .padding(.trailing, 8)
                .offset(y: -6)

            // Grid line and content area
            VStack(spacing: 0) {
                Rectangle()
                    .fill(NotionCalendarTokens.Colors.gridLine)
                    .frame(height: NotionCalendarTokens.Timeline.gridLineWidth)

                Spacer()
            }
        }
        .frame(height: hourHeight)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour)"
    }
}

// MARK: - Compact Timeline Grid (for Week View)

struct NotionCompactTimelineGrid: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat

    init(
        startHour: Int = NotionCalendarTokens.Timeline.startHour,
        endHour: Int = NotionCalendarTokens.Timeline.endHour,
        hourHeight: CGFloat = NotionCalendarTokens.WeekView.hourHeight
    ) {
        self.startHour = startHour
        self.endHour = endHour
        self.hourHeight = hourHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                compactHourRow(for: hour)
            }
        }
    }

    private func compactHourRow(for hour: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Minimal hour label (only show every 2 hours)
            if hour % 2 == 0 {
                Text("\(hour % 12 == 0 ? 12 : hour % 12)")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(NotionCalendarTokens.Colors.hourLabel)
                    .frame(width: 20, alignment: .trailing)
                    .offset(y: -4)
            } else {
                Color.clear
                    .frame(width: 20)
            }

            // Grid line
            Rectangle()
                .fill(NotionCalendarTokens.Colors.gridLine)
                .frame(height: NotionCalendarTokens.Timeline.gridLineWidth)
                .padding(.leading, 4)
        }
        .frame(height: hourHeight)
    }
}

// MARK: - Preview

#Preview("Timeline Grid") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            NotionTimelineGrid()
                .padding(.top, 20)
        }
    }
}

#Preview("Compact Grid") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            NotionCompactTimelineGrid()
                .padding(.top, 20)
        }
    }
}
