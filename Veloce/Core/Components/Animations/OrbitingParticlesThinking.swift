//
//  OrbitingParticlesThinking.swift
//  Veloce
//

import SwiftUI

struct OrbitingParticlesThinking: View {
    @State private var rotation: Double = 0
    let particleCount = 6

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                SwiftUI.Circle()
                    .fill(i < 3 ? Theme.Colors.aiPurple : Theme.Colors.aiCyan)
                    .frame(width: 6, height: 6)
                    .offset(x: i < 3 ? 25 : 40)
                    .rotationEffect(.degrees(rotation * (i < 3 ? 1 : 0.5) + Double(i * 60)))
                    .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 4)
            }
            AIOrb(size: .tiny, animationStyle: .pulse)
        }
        .frame(width: 100, height: 100)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) { rotation = 360 }
        }
    }
}
