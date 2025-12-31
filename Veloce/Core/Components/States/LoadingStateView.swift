//
//  LoadingStateView.swift
//  Veloce
//
//  Elegant loading indicators matching Living Cosmos aesthetic
//  Note: For skeleton loaders, use SkeletonLoader.swift
//

import SwiftUI

// MARK: - Loading State View

/// Full-screen loading state with optional message
struct LoadingStateView: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Animated loading indicator
            LoadingSpinner()

            // Optional message
            if let message = message {
                Text(message)
                    .dynamicTypeFont(base: 15, weight: .medium)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading Spinner

/// Gradient ring spinner with Veloce brand colors
struct LoadingSpinner: View {
    @State private var rotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        Theme.CelestialColors.nebulaCore,
                        Theme.CelestialColors.nebulaGlow,
                        Theme.CelestialColors.nebulaCore.opacity(0.3),
                        .clear
                    ],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 36, height: 36)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Preview

#Preview("Loading State") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        LoadingStateView(message: "Loading tasks...")
    }
}

#Preview("Loading Spinner") {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()
        LoadingSpinner()
    }
}
