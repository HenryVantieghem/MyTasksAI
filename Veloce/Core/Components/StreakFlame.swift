//
//  StreakFlame.swift
//  Veloce
//

import SwiftUI

struct StreakFlame: View {
    let streakDays: Int
    @State private var flamePhase: CGFloat = 0
    @State private var emberPhase: CGFloat = 0

    private var flameIntensity: BasicFlameIntensity {
        switch streakDays {
        case 0: return .none
        case 1...2: return .spark
        case 3...6: return .small
        case 7...13: return .medium
        case 14...29: return .large
        case 30...99: return .blazing
        default: return .inferno
        }
    }

    var body: some View {
        ZStack {
            // Glow
            SwiftUI.Circle()
                .fill(RadialGradient(colors: flameIntensity.colors.map { $0.opacity(0.3) }, center: .center, startRadius: 0, endRadius: 60))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .opacity(0.5 + flamePhase * 0.3)

            // Flame layers
            ForEach(0..<3, id: \.self) { layer in
                FlameLayer(phase: flamePhase, layer: layer, intensity: flameIntensity)
            }

            // Embers
            if flameIntensity.hasEmbers {
                EmberParticles(phase: emberPhase, count: flameIntensity.emberCount)
            }

            // Sparkles for high streaks
            if flameIntensity.hasSparkles {
                SparkleOverlay()
            }

            // Diamond for 100+ days
            if flameIntensity == .inferno {
                Image(systemName: "diamond.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .offset(y: -35)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) { flamePhase = 1 }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { emberPhase = 1 }
        }
    }
}

private enum BasicFlameIntensity {
    case none, spark, small, medium, large, blazing, inferno

    var colors: [Color] {
        switch self {
        case .none: return [.gray.opacity(0.2)]
        case .spark: return [.orange.opacity(0.5), .red.opacity(0.3)]
        case .small: return [.orange, .red]
        case .medium: return [.yellow, .orange, .red]
        case .large: return [.yellow, .orange, .red, .purple.opacity(0.3)]
        case .blazing: return [.white, .yellow, .orange, .red]
        case .inferno: return [.white, .cyan, .blue, .purple]
        }
    }

    var scale: CGFloat {
        switch self {
        case .none: return 0.3
        case .spark: return 0.4
        case .small: return 0.6
        case .medium: return 0.8
        case .large: return 1.0
        case .blazing: return 1.1
        case .inferno: return 1.2
        }
    }

    var hasEmbers: Bool { self != .none && self != .spark }
    var hasSparkles: Bool { self == .large || self == .blazing || self == .inferno }
    var emberCount: Int {
        switch self {
        case .small: return 3
        case .medium: return 5
        case .large: return 8
        case .blazing: return 12
        case .inferno: return 16
        default: return 0
        }
    }
}

private struct FlameLayer: View {
    let phase: CGFloat
    let layer: Int
    let intensity: BasicFlameIntensity

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 50 * intensity.scale - CGFloat(layer * 5)))
            .foregroundStyle(
                LinearGradient(colors: intensity.colors, startPoint: .bottom, endPoint: .top)
            )
            .scaleEffect(1 + phase * 0.1 - CGFloat(layer) * 0.02)
            .opacity(1 - Double(layer) * 0.2)
            .offset(y: CGFloat(layer * 2))
    }
}

private struct EmberParticles: View {
    let phase: CGFloat
    let count: Int

    var body: some View {
        ForEach(0..<count, id: \.self) { i in
            SwiftUI.Circle()
                .fill(Color.orange)
                .frame(width: 3, height: 3)
                .offset(
                    x: sin(phase * .pi * 2 + CGFloat(i)) * 20,
                    y: -40 - phase * 30 - CGFloat(i % 3) * 10
                )
                .opacity(1 - phase)
        }
    }
}

private struct SparkleOverlay: View {
    @State private var sparklePhase: CGFloat = 0

    var body: some View {
        ForEach(0..<5, id: \.self) { i in
            Image(systemName: "sparkle")
                .font(.caption2)
                .foregroundStyle(.yellow)
                .offset(
                    x: cos(CGFloat(i) * .pi * 2 / 5) * 30,
                    y: sin(CGFloat(i) * .pi * 2 / 5) * 30 - 20
                )
                .opacity(0.5 + sparklePhase * 0.5)
                .scaleEffect(0.8 + sparklePhase * 0.4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever()) { sparklePhase = 1 }
        }
    }
}
