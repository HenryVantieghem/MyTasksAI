//
//  TiimoHourGrid.swift
//  Veloce
//
//  Tiimo-Style Vertical Hour Grid Background
//  Clean, minimal hour markers for the vertical timeline
//

import SwiftUI

// MARK: - Tiimo Hour Grid

/// Vertical hour grid background for the Tiimo-style day view
struct TiimoHourGrid: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                TiimoHourRow(
                    hour: hour,
                    height: hourHeight,
                    isPeakHour: isPeakHour(hour)
                )
            }
        }
    }

    /// Peak hours (9 AM - 5 PM) are highlighted
    private func isPeakHour(_ hour: Int) -> Bool {
        hour >= 9 && hour <= 17
    }
}

// MARK: - Hour Row

/// Single hour row with time label and divider line
struct TiimoHourRow: View {
    let hour: Int
    let height: CGFloat
    let isPeakHour: Bool

    private var hourText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        guard let date = Calendar.current.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: Date()
        ) else {
            return "\(hour)"
        }
        return formatter.string(from: date).lowercased()
    }

    var body: some View {
        HStack(spacing: 0) {
            // Time label
            Text(hourText)
                .font(.system(size: 11, weight: isPeakHour ? .medium : .regular, design: .monospaced))
                .foregroundStyle(isPeakHour ? .white.opacity(0.6) : .white.opacity(0.35))
                .frame(width: TiimoDesignTokens.Timeline.timeGutterWidth, alignment: .trailing)
                .padding(.trailing, 8)

            // Divider line
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(isPeakHour ? 0.12 : 0.06),
                                .white.opacity(0.02)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Spacer()
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(hourText)")
    }
}

// MARK: - Compact Hour Grid (for Week View)

/// Compact hour grid for week view with narrower labels
struct TiimoCompactHourGrid: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                TiimoCompactHourRow(
                    hour: hour,
                    height: hourHeight
                )
            }
        }
    }
}

/// Compact hour row for week view
struct TiimoCompactHourRow: View {
    let hour: Int
    let height: CGFloat

    private var hourText: String {
        let isPM = hour >= 12
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour)\(isPM ? "p" : "a")"
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(hourText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: TiimoDesignTokens.WeekView.timeGutterWidth, alignment: .trailing)
                .padding(.trailing, 4)

            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 1)
        }
        .frame(height: height, alignment: .top)
    }
}

// MARK: - Drop Zone Overlay

/// Invisible drop zones at 15-minute intervals for drag-and-drop
struct TiimoDropZoneOverlay: View {
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat
    let timeGutterWidth: CGFloat
    let onDrop: (Date) -> Void
    @Binding var dropTargetTime: Date?

    private var totalSlots: Int {
        (endHour - startHour) * 4 // 4 slots per hour (15-min intervals)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Drop zones
                ForEach(0..<totalSlots, id: \.self) { slot in
                    let hour = startHour + slot / 4
                    let minute = (slot % 4) * 15

                    Rectangle()
                        .fill(Color.clear)
                        .frame(
                            width: geometry.size.width - timeGutterWidth - 24,
                            height: hourHeight / 4
                        )
                        .offset(
                            x: timeGutterWidth + 12,
                            y: CGFloat(slot) * hourHeight / 4
                        )
                        .onTapGesture {
                            let targetDate = makeTargetDate(hour: hour, minute: minute)
                            onDrop(targetDate)
                        }
                }

                // Drop target indicator
                if let targetTime = dropTargetTime {
                    TiimoDropTargetIndicator(
                        time: targetTime,
                        hourHeight: hourHeight,
                        startHour: startHour,
                        timeGutterWidth: timeGutterWidth
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }

    private func makeTargetDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

// MARK: - Drop Target Indicator

/// Visual indicator showing where a task will be dropped
struct TiimoDropTargetIndicator: View {
    let time: Date
    let hourHeight: CGFloat
    let startHour: Int
    let timeGutterWidth: CGFloat

    @State private var isVisible = false

    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private var timeString: String {
        time.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time label
            Text(timeString)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.Colors.aiCyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Theme.Colors.aiCyan.opacity(0.2))
                )

            // Dashed line
            Rectangle()
                .fill(Theme.Colors.aiCyan)
                .frame(height: 2)
        }
        .offset(x: timeGutterWidth, y: yOffset - 12)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Hour Grid") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            TiimoHourGrid(
                startHour: TiimoDesignTokens.Timeline.startHour,
                endHour: TiimoDesignTokens.Timeline.endHour,
                hourHeight: TiimoDesignTokens.Timeline.hourHeight
            )
            .padding()
        }
    }
}
