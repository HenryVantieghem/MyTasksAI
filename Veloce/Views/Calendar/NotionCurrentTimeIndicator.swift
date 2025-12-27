//
//  NotionCurrentTimeIndicator.swift
//  Veloce
//
//  Notion Calendar-Inspired Current Time Indicator
//  Clean cyan line with glowing dot marking the current time
//

import SwiftUI

// MARK: - Notion Current Time Indicator

struct NotionCurrentTimeIndicator: View {
    let hourHeight: CGFloat
    let startHour: Int
    let timeGutterWidth: CGFloat

    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    var body: some View {
        HStack(spacing: 0) {
            // NOW label
            Text("NOW")
                .font(NotionCalendarTokens.Typography.nowLabel)
                .foregroundStyle(Theme.Colors.aiCyan)
                .frame(width: timeGutterWidth - 8, alignment: .trailing)
                .padding(.trailing, 4)

            // Glowing dot
            ZStack {
                // Outer glow
                Circle()
                    .fill(Theme.Colors.aiCyan.opacity(0.3))
                    .frame(
                        width: NotionCalendarTokens.NowIndicator.dotSize + NotionCalendarTokens.NowIndicator.glowRadius,
                        height: NotionCalendarTokens.NowIndicator.dotSize + NotionCalendarTokens.NowIndicator.glowRadius
                    )
                    .blur(radius: 4)
                    .scaleEffect(pulseScale)

                // Core dot
                Circle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(
                        width: NotionCalendarTokens.NowIndicator.dotSize,
                        height: NotionCalendarTokens.NowIndicator.dotSize
                    )
            }

            // Line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiCyan,
                            Theme.Colors.aiCyan.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: NotionCalendarTokens.NowIndicator.lineHeight)
        }
        .offset(y: yOffset)
        .onAppear {
            startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        guard !reduceMotion else { return }

        withAnimation(NotionCalendarTokens.Animation.nowPulse) {
            pulseScale = 1.3
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            NotionCurrentTimeIndicator(
                hourHeight: NotionCalendarTokens.Timeline.hourHeight,
                startHour: NotionCalendarTokens.Timeline.startHour,
                timeGutterWidth: NotionCalendarTokens.Timeline.timeGutterWidth
            )

            Spacer()
        }
        .padding(.top, 200)
    }
}
