//
//  CelestialBackground.swift
//  Veloce
//
//  Celestial Dark theme background with cosmic void and nebula gradients
//  Used by CelestialTaskCard for premium visual experience
//

import SwiftUI

// MARK: - Celestial Background

struct CelestialBackground: View {
    var taskTypeColor: Color = Theme.CelestialColors.nebulaCore

    var body: some View {
        ZStack {
            // Layer 1: Cosmic Void base
            Theme.CelestialColors.void
                .ignoresSafeArea()

            // Layer 2: Nebula gradient (top to bottom)
            LinearGradient(
                colors: [
                    taskTypeColor.opacity(0.15),
                    Theme.CelestialColors.nebulaGlow.opacity(0.08),
                    Theme.CelestialColors.nebulaEdge.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Layer 3: Aurora effect (subtle)
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaCore.opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Layer 4: Secondary glow
            RadialGradient(
                colors: [
                    Theme.CelestialColors.nebulaEdge.opacity(0.05),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Layer 5: Glass material overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.15)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Celestial Glass Card Modifier

extension View {
    /// Applies a celestial glass card style
    func celestialGlassCard(accent: Color? = nil) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(accent?.opacity(0.05) ?? Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CelestialBackground(taskTypeColor: Theme.TaskCardColors.create)

        VStack(spacing: 20) {
            Text("Celestial Background")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                Text("Sample Card Content")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("This is how content looks on the celestial background")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(20)
            .celestialGlassCard(accent: Theme.Colors.aiPurple)
        }
        .padding()
    }
}
