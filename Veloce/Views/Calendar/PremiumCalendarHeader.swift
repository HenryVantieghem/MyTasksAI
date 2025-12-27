//
//  PremiumCalendarHeader.swift
//  Veloce
//
//  Premium Calendar Header with glass-effect view mode toggle
//  Clean navigation with arrow buttons and refined typography
//

import SwiftUI

// MARK: - Premium Calendar Header

struct PremiumCalendarHeader: View {
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDateTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Navigation arrows + Month/Year
            HStack(spacing: 12) {
                // Previous button
                navigationButton(icon: "chevron.left", action: onPrevious)

                // Month/Year Display
                Button(action: onDateTap) {
                    HStack(spacing: 6) {
                        Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .buttonStyle(.plain)

                // Next button
                navigationButton(icon: "chevron.right", action: onNext)
            }

            Spacer()

            // View Mode Toggle (Glass Effect)
            viewModeToggle
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
    }

    // MARK: - Navigation Button

    private func navigationButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsService.shared.lightImpact()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        }
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 2) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                viewModeButton(for: mode)
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    private func viewModeButton(for mode: CalendarViewMode) -> some View {
        let isSelected = viewMode == mode

        return Button {
            guard viewMode != mode else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                viewMode = mode
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            Text(mode.shortLabel)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.aiPurple.opacity(0.6),
                                        Theme.Colors.aiBlue.opacity(0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Theme.Colors.aiPurple.opacity(0.3), radius: 4, y: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CalendarViewMode Extension

extension CalendarViewMode {
    var shortLabel: String {
        switch self {
        case .day: return "Day"
        case .week: return "Wk"
        case .month: return "Mo"
        }
    }
}

// MARK: - Preview

#Preview("Calendar Header") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
                .frame(height: 60)

            PremiumCalendarHeader(
                selectedDate: .constant(Date()),
                viewMode: .constant(.week),
                onPrevious: {},
                onNext: {},
                onDateTap: {}
            )

            Spacer()
        }
    }
}
