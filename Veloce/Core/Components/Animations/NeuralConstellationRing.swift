//
//  NeuralConstellationRing.swift
//  MyTasksAI
//
//  Neural network visualization ring with 12 nodes
//  Nodes connect with animated lines that pulse with energy
//

import SwiftUI

// MARK: - Neural Constellation Ring

struct NeuralConstellationRing: View {
    let radius: CGFloat
    let isActive: Bool
    let phase: CGFloat // 0 to 1 for animation progress

    @State private var nodeActivations: [Bool] = Array(repeating: false, count: 12)
    @State private var connectionProgress: CGFloat = 0
    @State private var glowPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let nodeCount = 12
    private let gradientColors = Theme.TaskCardColors.iridescent

    var body: some View {
        ZStack {
            // Connection lines
            connectionLines

            // Nodes
            ForEach(0..<nodeCount, id: \.self) { index in
                nodeView(at: index)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
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

    // MARK: - Node Position

    private func nodePosition(at index: Int) -> CGPoint {
        let angle = (Double(index) / Double(nodeCount)) * 2 * .pi - .pi / 2
        return CGPoint(
            x: radius + CGFloat(cos(angle)) * radius,
            y: radius + CGFloat(sin(angle)) * radius
        )
    }

    // MARK: - Node View

    private func nodeView(at index: Int) -> some View {
        let position = nodePosition(at: index)
        let isActivated = nodeActivations[index]
        let nodeColor = gradientColors[index % gradientColors.count]

        return ZStack {
            // Glow when activated
            if isActivated {
                Circle()
                    .fill(nodeColor.opacity(0.5))
                    .frame(width: 12, height: 12)
                    .blur(radius: 4)
                    .scaleEffect(1 + glowPhase * 0.3)
            }

            // Node core
            Circle()
                .fill(
                    RadialGradient(
                        colors: isActivated
                            ? [.white, nodeColor]
                            : [nodeColor.opacity(0.6), nodeColor.opacity(0.3)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 8, height: 8)
                .scaleEffect(isActivated ? 1.2 : 0.8)
        }
        .position(position)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActivated)
    }

    // MARK: - Connection Lines

    private var connectionLines: some View {
        Canvas { context, size in
            // Draw connections between adjacent nodes and some cross-connections
            for i in 0..<nodeCount {
                let from = nodePosition(at: i)

                // Connect to next node
                let nextIndex = (i + 1) % nodeCount
                let to = nodePosition(at: nextIndex)
                drawConnection(context: context, from: from, to: to, index: i)

                // Cross-connections (every 3rd and 4th)
                if i % 3 == 0 {
                    let crossIndex = (i + 4) % nodeCount
                    let crossTo = nodePosition(at: crossIndex)
                    drawConnection(context: context, from: from, to: crossTo, index: i, isCross: true)
                }
            }
        }
        .frame(width: radius * 2, height: radius * 2)
    }

    private func drawConnection(
        context: GraphicsContext,
        from: CGPoint,
        to: CGPoint,
        index: Int,
        isCross: Bool = false
    ) {
        let progress = min(1, max(0, connectionProgress - CGFloat(index) * 0.05))
        guard progress > 0 else { return }

        var path = Path()
        path.move(to: from)

        // Interpolate to show progress
        let currentEnd = CGPoint(
            x: from.x + (to.x - from.x) * progress,
            y: from.y + (to.y - from.y) * progress
        )
        path.addLine(to: currentEnd)

        let color = gradientColors[index % gradientColors.count]
        let opacity = isCross ? 0.3 : 0.6
        let lineWidth: CGFloat = isCross ? 0.5 : 1

        context.stroke(
            path,
            with: .color(color.opacity(opacity * Double(progress))),
            lineWidth: lineWidth
        )

        // Energy pulse along the line
        if progress > 0.5 && !isCross {
            let pulsePosition = CGPoint(
                x: from.x + (to.x - from.x) * ((glowPhase + CGFloat(index) * 0.1).truncatingRemainder(dividingBy: 1)),
                y: from.y + (to.y - from.y) * ((glowPhase + CGFloat(index) * 0.1).truncatingRemainder(dividingBy: 1))
            )

            var pulsePath = Path()
            pulsePath.addEllipse(in: CGRect(x: pulsePosition.x - 2, y: pulsePosition.y - 2, width: 4, height: 4))
            context.fill(pulsePath, with: .color(.white.opacity(0.8)))
        }
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !reduceMotion else {
            connectionProgress = 1
            nodeActivations = Array(repeating: true, count: nodeCount)
            return
        }

        // Animate connection progress
        withAnimation(.easeOut(duration: 1.5)) {
            connectionProgress = 1
        }

        // Activate nodes sequentially
        for i in 0..<nodeCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    nodeActivations[i] = true
                }
            }
        }

        // Glow phase animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            glowPhase = 1
        }
    }

    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            connectionProgress = 0
            nodeActivations = Array(repeating: false, count: nodeCount)
        }
        glowPhase = 0
    }
}

// MARK: - Neural Pulse Effect

struct NeuralPulse: View {
    let color: Color
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 2
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Neural Constellation Ring")
                .font(.headline)
                .foregroundStyle(.white)

            NeuralConstellationRing(radius: 60, isActive: true, phase: 0.5)
        }
    }
}
