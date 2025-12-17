//
//  TaskCheckbox.swift
//  MyTasksAI
//
//  Beautiful Animated Task Checkbox
//  Apple Notes-inspired with delightful animations
//

import SwiftUI

// MARK: - Task Checkbox
struct TaskCheckbox: View {
    @Binding var isChecked: Bool
    var size: CGFloat = Theme.Size.checkboxSize
    var onToggle: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false
    @State private var showParticles = false

    var body: some View {
        Button {
            toggleCheckbox()
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .strokeBorder(
                        isChecked ? Theme.Colors.success : Theme.Colors.textTertiary,
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)

                // Fill circle (animated)
                Circle()
                    .fill(Theme.Colors.success)
                    .frame(width: size, height: size)
                    .scaleEffect(isChecked ? 1 : 0)

                // Checkmark
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }

                // Particle burst on completion (skip for reduce motion)
                if showParticles && !reduceMotion {
                    ParticleBurst(
                        particleCount: 8,
                        colors: [Theme.Colors.success, Theme.Colors.iridescentMint],
                        duration: 0.6
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .scaleEffect(isAnimating && !reduceMotion ? 1.2 : 1.0)
        .animation(reduceMotion ? .none : Theme.Animation.bouncySpring, value: isChecked)
        .animation(reduceMotion ? .none : Theme.Animation.quickSpring, value: isAnimating)
        .accessibilityLabel(isChecked ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
    }

    private func toggleCheckbox() {
        if reduceMotion {
            isChecked.toggle()
        } else {
            withAnimation(Theme.Animation.bouncySpring) {
                isChecked.toggle()
            }
        }

        // Haptic feedback (always provide - not affected by reduce motion)
        if isChecked {
            HapticsService.shared.taskComplete()

            // Show celebration particles (skip for reduce motion)
            if !reduceMotion {
                showParticles = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showParticles = false
                }
            }
        } else {
            HapticsService.shared.selectionFeedback()
        }

        // Bounce animation (skip for reduce motion)
        if !reduceMotion {
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = false
            }
        }

        onToggle?()
    }
}

// MARK: - Particle Burst
struct ParticleBurst: View {
    let particleCount: Int
    let colors: [Color]
    let duration: Double

    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }

    private func createParticles() {
        particles = (0..<particleCount).map { i in
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi
            return Particle(
                id: i,
                color: colors[i % colors.count],
                size: CGFloat.random(in: 3...6),
                angle: angle,
                offset: .zero,
                opacity: 1
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeOut(duration: duration)) {
            particles = particles.map { particle in
                var p = particle
                let distance = CGFloat.random(in: 20...40)
                p.offset = CGSize(
                    width: cos(particle.angle) * distance,
                    height: sin(particle.angle) * distance
                )
                p.opacity = 0
                return p
            }
        }
    }
}

struct Particle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    let angle: Double
    var offset: CGSize
    var opacity: Double
}

// MARK: - Hand Drawn Checkbox Style
/// Alternative hand-drawn style checkbox
struct HandDrawnCheckbox: View {
    @Binding var isChecked: Bool
    var size: CGFloat = Theme.Size.checkboxSize
    var onToggle: (() -> Void)?

    @State private var pathProgress: CGFloat = 0

    var body: some View {
        Button {
            toggle()
        } label: {
            ZStack {
                // Rounded square outline
                RoundedRectangle(cornerRadius: size * 0.2)
                    .strokeBorder(
                        isChecked ? Theme.Colors.success : Theme.Colors.textTertiary,
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)

                // Animated checkmark path
                if isChecked {
                    CheckmarkPath()
                        .trim(from: 0, to: pathProgress)
                        .stroke(Theme.Colors.success, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: size * 0.6, height: size * 0.6)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onChange(of: isChecked) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.3)) {
                    pathProgress = 1
                }
            } else {
                pathProgress = 0
            }
        }
    }

    private func toggle() {
        HapticsService.shared.selectionFeedback()
        withAnimation(Theme.Animation.quickSpring) {
            isChecked.toggle()
        }
        if isChecked {
            HapticsService.shared.success()
        }
        onToggle?()
    }
}

struct CheckmarkPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let start = CGPoint(x: rect.minX, y: rect.midY)
        let middle = CGPoint(x: rect.width * 0.35, y: rect.maxY)
        let end = CGPoint(x: rect.maxX, y: rect.minY)

        path.move(to: start)
        path.addLine(to: middle)
        path.addLine(to: end)

        return path
    }
}

// MARK: - Circle Checkbox
/// Minimal circle checkbox style
struct CircleCheckbox: View {
    @Binding var isChecked: Bool
    var size: CGFloat = 20
    var activeColor: Color = Theme.Colors.accent

    var body: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            withAnimation(Theme.Animation.quickSpring) {
                isChecked.toggle()
            }
        } label: {
            Circle()
                .fill(isChecked ? activeColor : Color.clear)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isChecked ? activeColor : Theme.Colors.textTertiary,
                            lineWidth: 1.5
                        )
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .opacity(isChecked ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        Text("Task Checkboxes")
            .font(Theme.Typography.title2)

        HStack(spacing: 40) {
            VStack {
                TaskCheckbox(isChecked: .constant(false))
                Text("Unchecked")
                    .font(Theme.Typography.caption1)
            }

            VStack {
                TaskCheckbox(isChecked: .constant(true))
                Text("Checked")
                    .font(Theme.Typography.caption1)
            }
        }

        Divider()

        HStack(spacing: 40) {
            VStack {
                HandDrawnCheckbox(isChecked: .constant(false))
                Text("Hand Drawn")
                    .font(Theme.Typography.caption1)
            }

            VStack {
                HandDrawnCheckbox(isChecked: .constant(true))
                Text("Checked")
                    .font(Theme.Typography.caption1)
            }
        }

        Divider()

        HStack(spacing: 40) {
            VStack {
                CircleCheckbox(isChecked: .constant(false))
                Text("Circle")
                    .font(Theme.Typography.caption1)
            }

            VStack {
                CircleCheckbox(isChecked: .constant(true))
                Text("Checked")
                    .font(Theme.Typography.caption1)
            }
        }
    }
    .padding()
}
