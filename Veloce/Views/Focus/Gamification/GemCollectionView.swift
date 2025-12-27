//
//  GemCollectionView.swift
//  Veloce
//
//  Displays earned and locked gems in a horizontal scrollable collection
//  Shows progress toward next gem milestone
//

import SwiftUI

// MARK: - Gem Progress

struct GemProgress: Identifiable {
    let id = UUID()
    let gemType: FocusGemType
    let isEarned: Bool
    let progress: Double // 0-1 progress toward earning
    let earnedDate: Date?

    static let sampleProgress: [GemProgress] = [
        GemProgress(gemType: .sapphire, isEarned: true, progress: 1.0, earnedDate: Date().addingTimeInterval(-86400 * 7)),
        GemProgress(gemType: .emerald, isEarned: true, progress: 1.0, earnedDate: Date().addingTimeInterval(-86400 * 3)),
        GemProgress(gemType: .ruby, isEarned: false, progress: 0.57, earnedDate: nil), // 4/7 days
        GemProgress(gemType: .diamond, isEarned: false, progress: 0.13, earnedDate: nil), // 4/30 days
        GemProgress(gemType: .amethyst, isEarned: false, progress: 0.23, earnedDate: nil) // 23/100 hours
    ]
}

// MARK: - Gem Collection View

struct GemCollectionView: View {
    let gems: [GemProgress]
    let onGemTapped: ((FocusGemType) -> Void)?

    @State private var selectedGem: FocusGemType?
    @State private var showGemDetail = false

    init(gems: [GemProgress] = GemProgress.sampleProgress, onGemTapped: ((FocusGemType) -> Void)? = nil) {
        self.gems = gems
        self.onGemTapped = onGemTapped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Focus Gems")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text("\(earnedCount)/\(gems.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)

            // Gems scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(gems) { gem in
                        GemCollectionItem(
                            gem: gem,
                            isSelected: selectedGem == gem.gemType
                        ) {
                            HapticsService.shared.selectionFeedback()
                            selectedGem = gem.gemType
                            onGemTapped?(gem.gemType)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiCyan.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private var earnedCount: Int {
        gems.filter { $0.isEarned }.count
    }
}

// MARK: - Gem Collection Item

struct GemCollectionItem: View {
    let gem: GemProgress
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Gem with progress ring
                ZStack {
                    // Progress ring background
                    if !gem.isEarned {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 70, height: 70)

                        // Progress ring
                        Circle()
                            .trim(from: 0, to: gem.progress)
                            .stroke(
                                gem.gemType.color.opacity(0.6),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                    }

                    // Gem
                    FocusGemView(
                        gemType: gem.gemType,
                        isEarned: gem.isEarned,
                        size: 56
                    )
                }

                // Label
                Text(gem.gemType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(gem.isEarned ? 0.8 : 0.5))
                    .lineLimit(1)

                // Progress or earned indicator
                if gem.isEarned {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Earned")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.success)
                } else {
                    Text("\(Int(gem.progress * 100))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(gem.gemType.color.opacity(0.8))
                }
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gem.gemType.color.opacity(0.15))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Gem Badge

struct CompactGemBadge: View {
    let gemType: FocusGemType
    let isEarned: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    isEarned
                        ? LinearGradient(colors: [gemType.color, gemType.secondaryColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 28, height: 28)

            Image(systemName: gemType.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isEarned ? .white : .white.opacity(0.4))

            if !isEarned {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.6))
                    .offset(x: 8, y: 8)
            }
        }
        .shadow(color: isEarned ? gemType.color.opacity(0.3) : .clear, radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 30) {
            GemCollectionView(gems: GemProgress.sampleProgress)
                .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach(FocusGemType.allCases) { gem in
                    CompactGemBadge(gemType: gem, isEarned: gem == .sapphire || gem == .emerald)
                }
            }
        }
    }
    .preferredColorScheme(.dark)
}
