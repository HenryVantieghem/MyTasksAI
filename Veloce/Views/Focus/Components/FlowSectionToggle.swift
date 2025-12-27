//
//  FlowSectionToggle.swift
//  Veloce
//
//  Unified section toggle for Flow page
//  Timer | Blocking | Insights with Liquid Glass styling
//

import SwiftUI

struct FlowSectionToggle: View {
    @Binding var selected: FlowSection

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FlowSection.allCases, id: \.self) { section in
                sectionButton(for: section)
            }
        }
        .padding(4)
        .glassEffect(
            .regular.interactive(true),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }

    @ViewBuilder
    private func sectionButton(for section: FlowSection) -> some View {
        let isSelected = selected == section

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selected = section
            }
            HapticsService.shared.selectionFeedback()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                    .symbolRenderingMode(.hierarchical)

                Text(section.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.3)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(section.accentColor.opacity(0.25))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(section.accentColor.opacity(0.5), lineWidth: 1)
                        }
                        .shadow(color: section.accentColor.opacity(0.3), radius: 8, y: 2)
                        .matchedGeometryEffect(id: "selection", in: animation)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            FlowSectionToggle(selected: .constant(.timer))
            FlowSectionToggle(selected: .constant(.blocking))
            FlowSectionToggle(selected: .constant(.insights))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
