//
//  CelestialCollapsibleSection.swift
//  Veloce
//
//  Reusable collapsible section component for CelestialTaskCard
//

import SwiftUI

// MARK: - Celestial Collapsible Section

struct CelestialCollapsibleSection<Content: View>: View {
    let section: CelestialCardSection
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header with tap to expand/collapse
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                HStack(spacing: 12) {
                    // Section icon
                    Image(systemName: section.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(section.accentColor)
                        .frame(width: 24)

                    // Section title
                    Text(section.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    // Chevron indicator
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded ? 20 : 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(isExpanded ? 0.3 : 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isExpanded ? 20 : 16, style: .continuous)
                        .strokeBorder(
                            section.accentColor.opacity(isExpanded ? 0.3 : 0.1),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Simple Collapsible Section (without section enum)

struct SimpleCollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticsService.shared.selectionFeedback()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentColor)
                        .frame(width: 24)

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.CelestialColors.starDim)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.05))
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.CelestialColors.void.ignoresSafeArea()

        VStack(spacing: 16) {
            CelestialCollapsibleSection(
                section: .taskDetails,
                isExpanded: .constant(true)
            ) {
                VStack(spacing: 12) {
                    Text("Task details content goes here")
                        .foregroundStyle(.white)

                    Text("Sub-tasks, context, duration")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(16)
                .celestialGlassCard()
            }

            CelestialCollapsibleSection(
                section: .aiGenius,
                isExpanded: .constant(false)
            ) {
                Text("AI content")
            }
        }
        .padding()
    }
}
