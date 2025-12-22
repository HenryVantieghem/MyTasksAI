//
//  ConstellationPasswordStrength.swift
//  Veloce
//
//  Constellation Password Strength
//  A unique password strength indicator that displays 4 stars
//  that illuminate based on password strength, forming a constellation.
//

import SwiftUI

// MARK: - Constellation Password Strength

struct ConstellationPasswordStrength: View {
    let strength: PasswordStrength
    let password: String

    @State private var animatedStars: Int = 0
    @State private var connectionOpacity: Double = 0
    @State private var glowPulse: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Aurora.Layout.spacingSmall) {
            // Constellation visualization
            constellationView

            // Text label with requirements
            HStack(spacing: Aurora.Layout.spacingSmall) {
                // Strength label
                HStack(spacing: 4) {
                    Circle()
                        .fill(strength.color)
                        .frame(width: 6, height: 6)
                        .shadow(color: strength.color.opacity(0.5), radius: 3)

                    Text(strength.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(strength.color)
                }

                Spacer()

                // Requirements hints
                if !password.isEmpty {
                    requirementsHints
                }
            }
        }
        .onChange(of: strength) { _, newStrength in
            animateToStrength(newStrength)
        }
        .onAppear {
            animateToStrength(strength)
        }
    }

    // MARK: - Constellation View

    private var constellationView: some View {
        ZStack {
            // Connection lines (visible when strong)
            if strength == .strong {
                constellationLines
                    .opacity(connectionOpacity)
            }

            // Stars
            HStack(spacing: starSpacing) {
                ForEach(0..<4, id: \.self) { index in
                    starView(for: index)
                }
            }
        }
        .frame(height: 24)
    }

    // MARK: - Star View

    private func starView(for index: Int) -> some View {
        let isLit = index < animatedStars
        let starColor = colorForStar(at: index)

        return ZStack {
            // Outer glow when lit
            if isLit {
                Circle()
                    .fill(starColor.opacity(0.4 + glowPulse * 0.2))
                    .frame(width: 18, height: 18)
                    .blur(radius: 6)
            }

            // Star shape
            Image(systemName: isLit ? "star.fill" : "star")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isLit ? starColor : Aurora.Colors.textQuaternary)
                .scaleEffect(isLit ? 1.1 : 0.9)
                .shadow(
                    color: isLit ? starColor.opacity(0.6) : Color.clear,
                    radius: 4
                )
        }
        .animation(
            Aurora.Animation.spring.delay(Double(index) * 0.1),
            value: animatedStars
        )
    }

    private var starSpacing: CGFloat {
        24
    }

    private func colorForStar(at index: Int) -> Color {
        switch index {
        case 0: return Aurora.Colors.error      // Weak - red star
        case 1: return Aurora.Colors.warning    // Fair - orange star
        case 2: return Aurora.Colors.electric   // Good - blue star
        case 3: return Aurora.Colors.success    // Strong - green star
        default: return Aurora.Colors.textQuaternary
        }
    }

    // MARK: - Constellation Lines

    private var constellationLines: some View {
        GeometryReader { geometry in
            Path { path in
                let centerY = geometry.size.height / 2
                let totalWidth = CGFloat(3) * starSpacing
                let startX = (geometry.size.width - totalWidth) / 2

                // Draw lines connecting stars
                for i in 0..<3 {
                    let x1 = startX + CGFloat(i) * starSpacing
                    let x2 = startX + CGFloat(i + 1) * starSpacing

                    path.move(to: CGPoint(x: x1, y: centerY))
                    path.addLine(to: CGPoint(x: x2, y: centerY))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Aurora.Colors.error.opacity(0.6),
                        Aurora.Colors.warning.opacity(0.6),
                        Aurora.Colors.electric.opacity(0.6),
                        Aurora.Colors.success.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
            .shadow(color: Aurora.Colors.success.opacity(0.3), radius: 4)
        }
    }

    // MARK: - Requirements Hints

    private var requirementsHints: some View {
        HStack(spacing: Aurora.Layout.spacingSmall) {
            requirementDot(met: password.count >= 8, label: "8+")
            requirementDot(met: password.range(of: "[A-Z]", options: .regularExpression) != nil, label: "A-Z")
            requirementDot(met: password.range(of: "[0-9]", options: .regularExpression) != nil, label: "0-9")
            requirementDot(met: password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil, label: "#@")
        }
    }

    private func requirementDot(met: Bool, label: String) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(met ? Aurora.Colors.success : Aurora.Colors.textQuaternary)
                .frame(width: 5, height: 5)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(met ? Aurora.Colors.success : Aurora.Colors.textQuaternary)
        }
    }

    // MARK: - Animation

    private func animateToStrength(_ strength: PasswordStrength) {
        let starCount = strength.rawValue

        // Animate stars one by one
        withAnimation(Aurora.Animation.spring) {
            animatedStars = starCount
        }

        // Show constellation lines for strong passwords
        if strength == .strong {
            withAnimation(Aurora.Animation.slow.delay(0.3)) {
                connectionOpacity = 1.0
            }

            // Pulse glow
            withAnimation(Aurora.Animation.glowPulse) {
                glowPulse = 1.0
            }
        } else {
            withAnimation(Aurora.Animation.quick) {
                connectionOpacity = 0
                glowPulse = 0
            }
        }
    }
}

// MARK: - Preview

#Preview("Constellation Password Strength") {
    VStack(spacing: 32) {
        ForEach(PasswordStrength.allCases, id: \.rawValue) { strength in
            VStack(alignment: .leading, spacing: 8) {
                Text("Strength: \(strength.label)")
                    .font(.caption)
                    .foregroundStyle(Aurora.Colors.textSecondary)

                ConstellationPasswordStrength(
                    strength: strength,
                    password: samplePassword(for: strength)
                )
            }
            .padding()
            .crystallineCard()
        }
    }
    .padding()
    .background(AuroraBackground.auth)
}

private func samplePassword(for strength: PasswordStrength) -> String {
    switch strength {
    case .weak: return "abc"
    case .fair: return "abcdefgh"
    case .good: return "Abcdefgh1"
    case .strong: return "Abcdefgh1!"
    }
}
