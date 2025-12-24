//
//  PasswordStrengthIndicator.swift
//  Veloce
//
//  Password Strength Indicator
//  Visual 4-segment bar showing password strength
//

import SwiftUI

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let strength: PasswordStrength
    let password: String

    @State private var animatedStrength: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Strength bar
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(1...4, id: \.self) { segment in
                    RoundedRectangle(cornerRadius: Theme.Radius.xs)
                        .fill(segmentColor(for: segment))
                        .frame(height: 4)
                        .animation(Theme.Animation.spring.delay(Double(segment) * 0.05), value: animatedStrength)
                }
            }

            // Label and requirements
            HStack {
                Text(strength.label)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(strengthColor)

                Spacer()

                // Requirements hints
                if !password.isEmpty {
                    requirementsHints
                }
            }
        }
        .onChange(of: strength) { _, newValue in
            withAnimation(Theme.Animation.spring) {
                animatedStrength = newValue.rawValue
            }
        }
        .onAppear {
            animatedStrength = strength.rawValue
        }
    }

    // MARK: - Segment Color

    private func segmentColor(for segment: Int) -> Color {
        guard segment <= animatedStrength else {
            return Theme.Colors.glassBorder.opacity(0.3)
        }

        return strengthColor
    }

    private var strengthColor: Color {
        switch strength {
        case .weak: return Theme.Colors.error
        case .fair: return .orange
        case .good: return .yellow
        case .strong: return Theme.Colors.success
        }
    }

    // MARK: - Requirements Hints

    private var requirementsHints: some View {
        HStack(spacing: Theme.Spacing.xs) {
            RequirementDot(
                met: password.count >= 8,
                label: "8+"
            )

            RequirementDot(
                met: password.range(of: "[A-Z]", options: .regularExpression) != nil,
                label: "A-Z"
            )

            RequirementDot(
                met: password.range(of: "[0-9]", options: .regularExpression) != nil,
                label: "0-9"
            )

            RequirementDot(
                met: password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil,
                label: "#@"
            )
        }
    }
}

// MARK: - Requirement Dot

struct RequirementDot: View {
    let met: Bool
    let label: String

    var body: some View {
        HStack(spacing: 2) {
            SwiftUI.Circle()
                .fill(met ? Theme.Colors.success : Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 9, weight: .medium, design: .default))
                .foregroundStyle(met ? Theme.Colors.success : Theme.Colors.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        PasswordStrengthIndicator(strength: .weak, password: "abc")
        PasswordStrengthIndicator(strength: .fair, password: "abcdefgh")
        PasswordStrengthIndicator(strength: .good, password: "Abcdefgh1")
        PasswordStrengthIndicator(strength: .strong, password: "Abcdefgh1!")
    }
    .padding()
    .background(Theme.Colors.background)
}
