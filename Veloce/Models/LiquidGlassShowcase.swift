//
//  LiquidGlassShowcase.swift
//  MyTasksAI
//
//  Simplified showcase of Liquid Glass components
//  Use this as a visual reference and component gallery
//

import SwiftUI

struct LiquidGlassShowcase: View {
    @State private var selectedTab = 0
    @State private var text = ""
    @State private var toggleState1 = true
    @State private var toggleState2 = false

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Tab 1: Buttons
                buttonsShowcase
                    .tag(0)

                // Tab 2: Cards
                cardsShowcase
                    .tag(1)

                // Tab 3: Typography
                typographyShowcase
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .background(cosmicBackground)
            .navigationTitle("Liquid Glass Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Tab \(selectedTab + 1)/3")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Buttons Showcase

    private var buttonsShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Buttons", icon: "button.programmable")

                VStack(spacing: 16) {
                    // Primary Button using SimpleLiquidGlassButton
                    SimpleLiquidGlassButton.primary("Primary Action", icon: "arrow.right") {}

                    // Success Button
                    SimpleLiquidGlassButton.success("Success State", icon: "checkmark.circle.fill") {}

                    // Destructive Button
                    SimpleLiquidGlassButton.destructive("Delete Item") {}

                    // Icon Buttons
                    HStack(spacing: 16) {
                        iconButton("heart.fill")
                        iconButton("bookmark.fill")
                        iconButton("star.fill")
                        iconButton("bell.fill")
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }

    private func iconButton(_ systemName: String) -> some View {
        Button(action: {}) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 44, height: 44)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }

    // MARK: - Cards Showcase

    private var cardsShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Cards & Containers", icon: "rectangle.stack")

                VStack(spacing: 20) {
                    // Standard Glass Card
                    LiquidGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Standard Card")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text("A beautiful glass card with native iOS 26 liquid glass effect.")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    // Prominent Card
                    LiquidGlassCard(style: .prominent) {
                        cardContent(
                            title: "Prominent Card",
                            description: "Higher emphasis glass effect"
                        )
                    }

                    // Floating Card
                    LiquidGlassCard(style: .floating) {
                        cardContent(
                            title: "Floating Card",
                            description: "Navigation-style glass effect"
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Typography Showcase

    private var typographyShowcase: some View {
        ScrollView {
            VStack(spacing: 32) {
                sectionHeader("Typography", icon: "textformat")

                VStack(alignment: .leading, spacing: 20) {
                    // CosmicWidget Typography
                    Group {
                        Text("Display Hero")
                            .font(CosmicWidget.Typography.displayHero)
                            .foregroundStyle(CosmicWidget.Text.primary)

                        Text("Display Stat")
                            .font(CosmicWidget.Typography.displayStat)
                            .foregroundStyle(CosmicWidget.Text.primary)

                        Text("Title 1")
                            .font(CosmicWidget.Typography.title1)
                            .foregroundStyle(CosmicWidget.Text.primary)

                        Text("Title 2")
                            .font(CosmicWidget.Typography.title2)
                            .foregroundStyle(CosmicWidget.Text.primary)

                        Text("Body Text")
                            .font(CosmicWidget.Typography.body)
                            .foregroundStyle(CosmicWidget.Text.secondary)

                        Text("Caption Text")
                            .font(CosmicWidget.Typography.caption)
                            .foregroundStyle(CosmicWidget.Text.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(LiquidGlassDesignSystem.VibrantAccents.electricCyan)

            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func cardContent(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var cosmicBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.02),
                    Color(red: 0.02, green: 0.02, blue: 0.035),
                    Color(red: 0.03, green: 0.02, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Nebula accents
            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.plasmaPurple.opacity(0.1),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )

            RadialGradient(
                colors: [
                    LiquidGlassDesignSystem.VibrantAccents.electricCyan.opacity(0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 350
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    LiquidGlassShowcase()
}
