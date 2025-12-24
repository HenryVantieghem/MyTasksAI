//
//  NeuralNetworkThinking.swift
//  Veloce
//

import SwiftUI

struct NeuralNetworkThinking: View {
    @State private var phase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    let nodeCount: Int = 12

    var body: some View {
        ZStack {
            // Connections
            ForEach(0..<nodeCount, id: \.self) { i in
                ForEach(0..<nodeCount, id: \.self) { j in
                    if i < j && (i + j) % 3 == 0 {
                        ConnectionLine(from: nodePosition(i), to: nodePosition(j), phase: phase)
                    }
                }
            }

            // Nodes
            ForEach(0..<nodeCount, id: \.self) { i in
                SwiftUI.Circle()
                    .fill(LinearGradient(colors: [Theme.Colors.aiPurple, Theme.Colors.aiBlue], startPoint: .top, endPoint: .bottom))
                    .frame(width: 8, height: 8)
                    .position(nodePosition(i))
                    .scaleEffect(pulseScale)
            }

            // Center orb
            AIOrb(size: .small, animationStyle: .thinking)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { phase = 1 }
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) { pulseScale = 1.15 }
        }
    }

    private func nodePosition(_ index: Int) -> CGPoint {
        let angle = (CGFloat(index) / CGFloat(nodeCount)) * .pi * 2
        let radius: CGFloat = 50
        return CGPoint(x: 60 + cos(angle) * radius, y: 60 + sin(angle) * radius)
    }
}

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let phase: CGFloat

    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .trim(from: 0, to: phase)
        .stroke(Theme.Colors.aiPurple.opacity(0.4), lineWidth: 1)
    }
}
