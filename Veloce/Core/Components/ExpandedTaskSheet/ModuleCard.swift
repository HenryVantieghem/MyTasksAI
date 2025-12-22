//
//  ModuleCard.swift
//  MyTasksAI
//
//  Unified module container with accent colors
//  Used by all genius sheet modules
//

import SwiftUI

// MARK: - Module Card

struct ModuleCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    var trailingText: String? = nil
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(accentColor)

                Spacer()

                if let trailing = trailingText {
                    Text(trailing)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Content
            content
        }
        .padding(Theme.Spacing.md)
        .background(moduleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(moduleBorder)
    }

    // MARK: - Background

    private var moduleBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.5)

            // Subtle accent gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.03),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Border

    private var moduleBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.2),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Module Header Only

struct ModuleHeader: View {
    let title: String
    let icon: String
    let accentColor: Color
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accentColor)

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(accentColor)

            Spacer()

            if let trailing = trailingText {
                Text(trailing)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            ModuleCard(
                title: "AI STRATEGY",
                icon: "brain",
                accentColor: Theme.TaskCardColors.strategy
            ) {
                Text("This is the module content area where the main functionality lives.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
            }

            ModuleCard(
                title: "START HERE",
                icon: "play.fill",
                accentColor: Theme.TaskCardColors.startHere,
                trailingText: "30 seconds"
            ) {
                Text("First step content goes here.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
    }
}
