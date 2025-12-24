//
//  TiimoCurrentTimeIndicator.swift
//  Veloce
//
//  Tiimo-Style Current Time Indicator
//  Pulsing "NOW" marker for vertical timeline
//

import SwiftUI
import Combine

// MARK: - Tiimo Current Time Indicator

/// Vertical timeline "NOW" indicator with pulsing animation
struct TiimoCurrentTimeIndicator: View {
    let hourHeight: CGFloat
    let startHour: Int
    let timeGutterWidth: CGFloat

    @State private var currentTime = Date()
    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    private var timeString: String {
        currentTime.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        HStack(spacing: 0) {
            // Time gutter area - show "NOW" label
            HStack(spacing: 4) {
                Text("NOW")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Colors.aiCyan)
            }
            .frame(width: timeGutterWidth, alignment: .trailing)
            .padding(.trailing, 4)

            // Pulsing dot
            ZStack {
                // Outer glow ring
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiCyan.opacity(0.2))
                    .frame(
                        width: TiimoDesignTokens.NowIndicator.glowSize + (reduceMotion ? 0 : pulsePhase * 6),
                        height: TiimoDesignTokens.NowIndicator.glowSize + (reduceMotion ? 0 : pulsePhase * 6)
                    )
                    .blur(radius: 4)

                // Inner dot
                SwiftUI.Circle()
                    .fill(Theme.Colors.aiCyan)
                    .frame(
                        width: TiimoDesignTokens.NowIndicator.dotSize,
                        height: TiimoDesignTokens.NowIndicator.dotSize
                    )
                    .shadow(color: Theme.Colors.aiCyan.opacity(0.6), radius: 4)
            }
            .offset(x: -TiimoDesignTokens.NowIndicator.dotSize / 2)

            // Horizontal line extending across timeline
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiCyan,
                            Theme.Colors.aiCyan.opacity(0.6),
                            Theme.Colors.aiCyan.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: TiimoDesignTokens.NowIndicator.lineHeight)
                .offset(x: -TiimoDesignTokens.NowIndicator.dotSize / 2)
        }
        .offset(y: yOffset)
        .onAppear {
            startPulseAnimation()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current time: \(timeString)")
    }

    private func startPulseAnimation() {
        guard !reduceMotion else { return }

        withAnimation(TiimoDesignTokens.Animation.breathingPulse) {
            pulsePhase = 1
        }
    }
}

// MARK: - Compact Now Indicator (for Week View)

/// Smaller current time indicator for week view
struct TiimoCompactNowIndicator: View {
    let hourHeight: CGFloat
    let startHour: Int
    let columnWidth: CGFloat
    let dayOffset: Int // 0 = first column, 6 = last column

    @State private var currentTime = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var yOffset: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)

        guard hour >= startHour else { return 0 }

        return CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }

    var body: some View {
        HStack(spacing: 0) {
            // Red dot
            SwiftUI.Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)

            // Red line spanning the day column
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: columnWidth - 6, height: 1.5)
        }
        .offset(
            x: CGFloat(dayOffset) * columnWidth,
            y: yOffset
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Preview

#Preview("Now Indicator") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            TiimoCurrentTimeIndicator(
                hourHeight: TiimoDesignTokens.Timeline.hourHeight,
                startHour: TiimoDesignTokens.Timeline.startHour,
                timeGutterWidth: TiimoDesignTokens.Timeline.timeGutterWidth
            )
            .frame(height: 100)

            Spacer()
        }
        .padding()
    }
}
