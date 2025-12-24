//
//  FocusModeCards.swift
//  Veloce
//
//  Enhanced mode selection cards for focus timer
//  Deep Work, Pomodoro, Flow State, Custom with proper styling
//

import SwiftUI

// MARK: - Focus Mode Card Grid

/// Horizontal scrolling grid of focus mode cards
struct FocusModeCardGrid: View {
    @Binding var selectedMode: FocusTimerMode
    let isSessionActive: Bool
    let onCustomTap: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FocusTimerMode.allCases, id: \.self) { mode in
                    FocusModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        isDisabled: isSessionActive
                    ) {
                        if mode == .custom {
                            onCustomTap()
                        } else {
                            HapticsService.shared.selectionFeedback()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedMode = mode
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Focus Mode Card

struct FocusModeCard: View {
    let mode: FocusTimerMode
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var accentColor: Color {
        switch mode {
        case .deepWork: return Color(red: 0.96, green: 0.55, blue: 0.22) // Orange
        case .pomodoro: return Color(red: 0.18, green: 0.82, blue: 0.92) // Cyan
        case .flowState: return Color(red: 0.58, green: 0.25, blue: 0.98) // Purple
        case .custom: return Color.white.opacity(0.6) // Gray
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon with glow
                ZStack {
                    // Glow behind icon when selected
                    if isSelected {
                        Circle()
                            .fill(accentColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)
                    }

                    Image(systemName: mode.icon)
                        .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? accentColor : .white.opacity(0.7))
                }
                .frame(height: 36)

                // Mode name
                Text(mode.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                // Duration
                Text(durationText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? accentColor : .white.opacity(0.4))
            }
            .frame(width: 88, height: 100)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? accentColor.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
            }
            .shadow(
                color: isSelected ? accentColor.opacity(0.3) : Color.clear,
                radius: 12,
                y: 4
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }

    private var durationText: String {
        switch mode {
        case .deepWork: return "90 min"
        case .pomodoro: return "25 min"
        case .flowState: return "∞"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Large Focus Mode Card (for sheets)

struct LargeFocusModeCard: View {
    let mode: FocusTimerMode
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        switch mode {
        case .deepWork: return Color(red: 0.96, green: 0.55, blue: 0.22)
        case .pomodoro: return Color(red: 0.18, green: 0.82, blue: 0.92)
        case .flowState: return Color(red: 0.58, green: 0.25, blue: 0.98)
        case .custom: return Color.white.opacity(0.6)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: mode.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(accentColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)

                        if mode.duration > 0 {
                            Text("• \(mode.duration) min")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(accentColor)
                        }
                    }

                    Text(mode.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor.opacity(0.1) : Color.white.opacity(0.03))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? accentColor.opacity(0.3) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Mode Cards Grid") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            FocusModeCardGrid(
                selectedMode: .constant(.pomodoro),
                isSessionActive: false,
                onCustomTap: {}
            )
        }
    }
}

#Preview("Large Mode Cards") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 12) {
            ForEach(FocusTimerMode.allCases, id: \.self) { mode in
                LargeFocusModeCard(
                    mode: mode,
                    isSelected: mode == .pomodoro,
                    action: {}
                )
            }
        }
        .padding()
    }
}
