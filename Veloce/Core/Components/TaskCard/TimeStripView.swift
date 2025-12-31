//
//  TimeStripView.swift
//  Veloce
//
//  Horizontal scrolling time navigation strip
//  Shows hours of the day with current hour highlighted
//

import SwiftUI

// MARK: - Time Strip View

struct TimeStripView: View {
    let onHourTap: (Int) -> Void

    @State private var currentHour: Int = Calendar.current.component(.hour, from: Date())
    @State private var pulsePhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let hours = Array(0..<24)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(hours, id: \.self) { hour in
                        HourPill(
                            hour: hour,
                            isCurrent: hour == currentHour,
                            pulsePhase: pulsePhase,
                            onTap: { onHourTap(hour) }
                        )
                        .id(hour)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                // Scroll to current hour
                withAnimation(.spring(response: 0.3)) {
                    proxy.scrollTo(currentHour, anchor: .center)
                }

                // Start pulse animation for current hour
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulsePhase = 1
                    }
                }

                // Update current hour periodically
                startHourTimer()
            }
        }
        .frame(height: 48)
    }

    private func startHourTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let newHour = Calendar.current.component(.hour, from: Date())
            if newHour != currentHour {
                withAnimation(.spring(response: 0.3)) {
                    currentHour = newHour
                }
            }
        }
    }
}

// MARK: - Hour Pill

struct HourPill: View {
    let hour: Int
    let isCurrent: Bool
    let pulsePhase: CGFloat
    let onTap: () -> Void

    private var hourText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date).lowercased()
    }

    private var periodLabel: String {
        if hour < 6 { return "night" }
        if hour < 12 { return "morning" }
        if hour < 17 { return "afternoon" }
        if hour < 21 { return "evening" }
        return "night"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(hourText)
                    .font(.system(size: 13, weight: isCurrent ? .bold : .medium, design: .rounded))
                    .foregroundColor(isCurrent ? Theme.CelestialColors.plasmaCore : Theme.CelestialColors.starDim)

                if isCurrent {
                    Circle()
                        .fill(Theme.CelestialColors.plasmaCore)
                        .frame(width: 4, height: 4)
                        .scaleEffect(1 + pulsePhase * 0.3)
                        .opacity(Double(1.0 - pulsePhase * 0.3))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isCurrent ? Theme.CelestialColors.plasmaCore.opacity(0.15) : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isCurrent ? Theme.CelestialColors.plasmaCore.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(hourText), \(periodLabel)\(isCurrent ? ", current hour" : "")")
    }
}

// MARK: - Time Period Divider

struct TimePeriodDivider: View {
    let period: TimePeriod

    enum TimePeriod: String {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"

        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            }
        }

        var color: Color {
            switch self {
            case .morning: return Color(red: 1.0, green: 0.8, blue: 0.4)
            case .afternoon: return Color(red: 1.0, green: 0.9, blue: 0.5)
            case .evening: return Color(red: 1.0, green: 0.6, blue: 0.4)
            case .night: return Color(red: 0.5, green: 0.6, blue: 0.9)
            }
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: period.icon)
                .dynamicTypeFont(base: 12)
                .foregroundColor(period.color)

            Text(period.rawValue)
                .dynamicTypeFont(base: 12, weight: .semibold)
                .foregroundColor(Theme.CelestialColors.starDim)

            Rectangle()
                .fill(Theme.CelestialColors.starGhost)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: 24) {
            TimeStripView { hour in
                print("Tapped hour: \(hour)")
            }

            TimePeriodDivider(period: .morning)
                .padding(.horizontal)

            TimePeriodDivider(period: .afternoon)
                .padding(.horizontal)

            TimePeriodDivider(period: .evening)
                .padding(.horizontal)
        }
    }
}
