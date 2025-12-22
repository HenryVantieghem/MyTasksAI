//
//  DimensionalRings.swift
//  MyTasksAI
//
//  3D rotating rings with perspective tilt, color-shifting gradients
//  Rings breathe (scale oscillation) and rotate at different speeds
//

import SwiftUI

// MARK: - Dimensional Rings

struct DimensionalRings: View {
    let size: CGFloat
    let isActive: Bool

    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var rotation3: Double = 0
    @State private var breathePhase: CGFloat = 0
    @State private var colorShift: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let gradientColors = Theme.TaskCardColors.iridescent

    var body: some View {
        ZStack {
            // Ring 1 - Outermost, slow rotation, tilted on X axis
            ringView(
                radius: size * 0.9,
                lineWidth: 2,
                rotation: rotation1,
                tiltX: 70,
                tiltY: 0,
                colorOffset: 0
            )

            // Ring 2 - Middle, medium rotation, tilted on Y axis
            ringView(
                radius: size * 0.75,
                lineWidth: 2.5,
                rotation: rotation2,
                tiltX: 0,
                tiltY: 70,
                colorOffset: 2
            )

            // Ring 3 - Innermost, fast rotation, tilted on both axes
            ringView(
                radius: size * 0.6,
                lineWidth: 3,
                rotation: rotation3,
                tiltX: 45,
                tiltY: 45,
                colorOffset: 4
            )
        }
        .frame(width: size * 2, height: size * 2)
        .onChange(of: isActive) { _, active in
            if active {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
    }

    // MARK: - Ring View

    private func ringView(
        radius: CGFloat,
        lineWidth: CGFloat,
        rotation: Double,
        tiltX: Double,
        tiltY: Double,
        colorOffset: Int
    ) -> some View {
        let breatheScale = 1 + sin(breathePhase * .pi * 2) * 0.05
        let shiftedColors = shiftColors(by: colorOffset)

        return Circle()
            .stroke(
                AngularGradient(
                    colors: shiftedColors,
                    center: .center,
                    startAngle: .degrees(Double(colorShift) * 360),
                    endAngle: .degrees(Double(colorShift) * 360 + 360)
                ),
                lineWidth: lineWidth
            )
            .frame(width: radius, height: radius)
            .scaleEffect(breatheScale)
            .rotation3DEffect(
                .degrees(tiltX),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(tiltY),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .rotationEffect(.degrees(rotation))
            .shadow(color: shiftedColors[0].opacity(0.3), radius: 4)
    }

    // MARK: - Color Shifting

    private func shiftColors(by offset: Int) -> [Color] {
        var colors = gradientColors
        for _ in 0..<offset {
            if let first = colors.first {
                colors.removeFirst()
                colors.append(first)
            }
        }
        colors.append(colors[0]) // Close the gradient loop
        return colors
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !reduceMotion else {
            rotation1 = 0
            rotation2 = 120
            rotation3 = 240
            return
        }

        // Ring 1 - Slow rotation (8 seconds per revolution)
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotation1 = 360
        }

        // Ring 2 - Medium rotation (5 seconds, opposite direction)
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            rotation2 = -360
        }

        // Ring 3 - Fast rotation (3 seconds)
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotation3 = 360
        }

        // Breathing effect
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breathePhase = 1
        }

        // Color shift
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            colorShift = 1
        }
    }

    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            breathePhase = 0
        }
        rotation1 = 0
        rotation2 = 0
        rotation3 = 0
        colorShift = 0
    }
}

// MARK: - Dimensional Ring Single

struct DimensionalRingSingle: View {
    let radius: CGFloat
    let lineWidth: CGFloat
    let rotation: Double
    let tiltAngle: Double
    let tiltAxis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let colors: [Color]

    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: colors + [colors[0]],
                    center: .center
                ),
                lineWidth: lineWidth
            )
            .frame(width: radius, height: radius)
            .rotation3DEffect(
                .degrees(tiltAngle),
                axis: tiltAxis,
                perspective: 0.5
            )
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Ring Shatter Effect (for completion)

struct RingShatterEffect: View {
    let size: CGFloat
    let colors: [Color]
    @State private var fragments: [RingFragment] = []
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            ForEach(fragments) { fragment in
                RingFragmentView(fragment: fragment)
            }
        }
        .opacity(opacity)
        .onAppear {
            createFragments()
            animateShatter()
        }
    }

    private func createFragments() {
        fragments = (0..<24).map { index in
            let angle = Double(index) * 15
            let color = colors[index % colors.count]
            return RingFragment(
                id: index,
                angle: angle,
                color: color,
                size: size / 20
            )
        }
    }

    private func animateShatter() {
        withAnimation(.easeOut(duration: 0.6)) {
            for i in fragments.indices {
                fragments[i].offset = CGFloat.random(in: 50...100)
                fragments[i].rotation = Double.random(in: -180...180)
                fragments[i].scale = CGFloat.random(in: 0.5...1.5)
            }
            opacity = 0
        }
    }
}

struct RingFragment: Identifiable {
    let id: Int
    let angle: Double
    let color: Color
    let size: CGFloat
    var offset: CGFloat = 0
    var rotation: Double = 0
    var scale: CGFloat = 1
}

struct RingFragmentView: View {
    let fragment: RingFragment

    var body: some View {
        Rectangle()
            .fill(fragment.color)
            .frame(width: fragment.size, height: fragment.size / 3)
            .rotationEffect(.degrees(fragment.rotation))
            .scaleEffect(fragment.scale)
            .offset(x: cos(fragment.angle * .pi / 180) * fragment.offset,
                   y: sin(fragment.angle * .pi / 180) * fragment.offset)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Dimensional Rings")
                .font(.headline)
                .foregroundStyle(.white)

            DimensionalRings(size: 80, isActive: true)
        }
    }
}
