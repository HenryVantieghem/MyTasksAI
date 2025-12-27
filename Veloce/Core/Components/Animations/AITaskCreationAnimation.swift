//
//  AITaskCreationAnimation.swift
//  MyTasksAI
//
//  Full-screen "Cosmic Consciousness Awakening" animation
//  Composed of 7 layers: Aurora, Dimensional Rings, Orbiting Particles,
//  Neural Constellation, Singularity Core, Status Text, and Bloom Completion
//
//  Total Duration: 3.5 seconds
//

import SwiftUI

// MARK: - AI Task Creation Animation

struct AITaskCreationAnimation: View {
    let onComplete: () -> Void

    @State private var currentPhase: Phase = .awakening
    @State private var isLayerActive: [Bool] = Array(repeating: false, count: 7)
    @State private var overallOpacity: Double = 0
    @State private var showBloom: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.responsiveLayout) private var layout

    // Animation timing constants
    private let totalDuration: Double = 3.5
    private let phaseDuration: Double = 0.6

    // MARK: - Responsive Sizes

    private var auroraSize: CGFloat {
        layout.deviceType.isTablet ? 600 : 400
    }

    private var dimensionalRingSize: CGFloat {
        layout.deviceType.isTablet ? 180 : 120
    }

    private var orbitRadius: CGFloat {
        layout.deviceType.isTablet ? 105 : 70
    }

    private var constellationRadius: CGFloat {
        layout.deviceType.isTablet ? 75 : 50
    }

    private var coreSize: CGFloat {
        layout.deviceType.isTablet ? 90 : 60
    }

    private var bloomSize: CGFloat {
        layout.deviceType.isTablet ? 300 : 200
    }

    enum Phase: Int, CaseIterable {
        case awakening = 0      // Aurora + base glow
        case perceiving = 1     // Dimensional rings activate
        case mapping = 2        // Neural constellation lights up
        case crystallizing = 3  // Orbiting particles + singularity core
        case manifesting = 4    // Full intensity + status text changes
        case blooming = 5       // Completion explosion

        var statusMessage: String {
            switch self {
            case .awakening: return "Awakening..."
            case .perceiving: return "Perceiving your intent..."
            case .mapping: return "Mapping neural pathways..."
            case .crystallizing: return "Crystallizing insights..."
            case .manifesting: return "Manifesting genius..."
            case .blooming: return "Complete!"
            }
        }
    }

    var body: some View {
        ZStack {
            // Layer 0: Background (always visible when animation active)
            AuroraGradientBackground(isActive: overallOpacity > 0)
                .opacity(overallOpacity)

            // Layer 1: Aurora Waves (outer atmosphere)
            AuroraWaves(size: auroraSize, isActive: isLayerActive[0])
                .opacity(isLayerActive[0] ? 1 : 0)

            // Layer 2: Dimensional Rings (outer structure)
            DimensionalRings(size: dimensionalRingSize, isActive: isLayerActive[1])
                .opacity(isLayerActive[1] ? 1 : 0)

            // Layer 3: Orbiting Thought Particles (middle layer)
            OrbitingThoughtParticles(
                radius: orbitRadius,
                isActive: isLayerActive[2],
                phase: CGFloat(currentPhase.rawValue) / CGFloat(Phase.allCases.count)
            )
            .opacity(isLayerActive[2] ? 1 : 0)

            // Layer 4: Neural Constellation Ring (inner ring)
            NeuralConstellationRing(
                radius: constellationRadius,
                isActive: isLayerActive[3],
                phase: CGFloat(currentPhase.rawValue) / CGFloat(Phase.allCases.count)
            )
            .opacity(isLayerActive[3] ? 1 : 0)

            // Layer 5: Singularity Core (center orb)
            SingularityCore(size: coreSize, isActive: isLayerActive[4])
                .opacity(isLayerActive[4] ? 1 : 0)

            // Layer 6: Status Text (bottom)
            VStack {
                Spacer()

                TypewriterStatusText(
                    messages: Phase.allCases.dropLast().map(\.statusMessage),
                    isActive: isLayerActive[5]
                )
                .padding(.bottom, layout.deviceType.isTablet ? 150 : 100)
            }
            .opacity(isLayerActive[5] ? 1 : 0)

            // Bloom completion overlay
            if showBloom {
                BloomCompletion(size: bloomSize) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        overallOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete()
                    }
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation Orchestration

    private func startAnimation() {
        if reduceMotion {
            // Simplified animation for accessibility
            withAnimation(.easeIn(duration: 0.3)) {
                overallOpacity = 1
            }

            // Show checkmark after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showBloom = true
            }
            return
        }

        // Fade in
        withAnimation(.easeIn(duration: 0.3)) {
            overallOpacity = 1
        }

        // Trigger haptic
        triggerStartHaptic()

        // Phase 0: Awakening - Aurora activates
        activateLayer(0)
        currentPhase = .awakening

        // Phase 1: Perceiving - Dimensional rings
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * 0.8) {
            currentPhase = .perceiving
            activateLayer(1)
            triggerBuildingHaptic()
        }

        // Phase 2: Mapping - Neural constellation
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * 1.6) {
            currentPhase = .mapping
            activateLayer(3)
            triggerBuildingHaptic()
        }

        // Phase 3: Crystallizing - Orbiting particles + Singularity
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * 2.4) {
            currentPhase = .crystallizing
            activateLayer(2)
            activateLayer(4)
            activateLayer(5) // Status text
            triggerBuildingHaptic()
        }

        // Phase 4: Manifesting - Full intensity
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * 3.5) {
            currentPhase = .manifesting
            triggerCrescendoHaptic()
        }

        // Phase 5: Blooming - Completion
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - 0.6) {
            currentPhase = .blooming

            // Pause briefly for anticipation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Deactivate all layers
                for i in 0..<isLayerActive.count {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isLayerActive[i] = false
                    }
                }

                // Show bloom
                showBloom = true
            }
        }
    }

    private func activateLayer(_ index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isLayerActive[index] = true
        }
    }

    // MARK: - Haptic Feedback

    private func triggerStartHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    private func triggerBuildingHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func triggerCrescendoHaptic() {
        // Triple-tap crescendo
        let generator = UIImpactFeedbackGenerator(style: .heavy)

        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.impactOccurred()
        }
    }
}

// MARK: - AI Creation Animation Wrapper

/// Wraps content with AI creation animation overlay
struct AICreationAnimationModifier: ViewModifier {
    @Binding var isShowing: Bool
    let onComplete: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if isShowing {
                    AITaskCreationAnimation {
                        isShowing = false
                        onComplete()
                    }
                    .transition(.opacity)
                }
            }
    }
}

extension View {
    func aiCreationAnimation(
        isShowing: Binding<Bool>,
        onComplete: @escaping () -> Void = {}
    ) -> some View {
        modifier(AICreationAnimationModifier(isShowing: isShowing, onComplete: onComplete))
    }
}

// MARK: - Quick AI Processing Indicator

/// Compact indicator for quick AI operations (not full animation)
struct QuickAIIndicator: View {
    let isActive: Bool

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    @Environment(\.responsiveLayout) private var layout

    // Responsive sizes
    private var indicatorSize: CGFloat {
        layout.deviceType.isTablet ? 32 : 24
    }

    private var sparkleSize: CGFloat {
        layout.deviceType.isTablet ? 14 : 10
    }

    var body: some View {
        ZStack {
            // Outer ring
            SwiftUI.Circle()
                .stroke(
                    AngularGradient(
                        colors: Theme.TaskCardColors.iridescent,
                        center: .center
                    ),
                    lineWidth: layout.deviceType.isTablet ? 2.5 : 2
                )
                .frame(width: indicatorSize, height: indicatorSize)
                .rotationEffect(.degrees(rotation))

            // Center sparkle
            Image(systemName: "sparkle")
                .dynamicTypeFont(base: sparkleSize, weight: .medium)
                .foregroundStyle(.white)
                .scaleEffect(scale)
        }
        .onChange(of: isActive) { _, active in
            if active {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            scale = 1.2
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1
        }
        rotation = 0
    }
}

// MARK: - Preview

#Preview("Full Animation") {
    AITaskCreationAnimation {
        print("Animation complete!")
    }
}

#Preview("Quick Indicator") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
            Text("Quick AI Indicator")
                .foregroundStyle(.white)

            QuickAIIndicator(isActive: true)
        }
    }
}
