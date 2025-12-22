//
//  EditorialDesignSystem.swift
//  MyTasksAI
//
//  Premium Editorial-Minimal Design System
//  Clean typography, sophisticated colors, native Liquid Glass
//

import SwiftUI

// MARK: - App Colors

/// Editorial-minimal color palette with deep blacks and soft accents
enum AppColors {
    // MARK: Backgrounds
    static let backgroundPrimary = Color(hex: "0A0A0A")
    static let backgroundSurface = Color(hex: "141414")
    static let backgroundElevated = Color(hex: "1C1C1E")

    // MARK: Accents
    static let accentPrimary = Color(hex: "A78BFA")      // Soft violet
    static let accentSecondary = Color(hex: "F59E0B")    // Warm amber (streaks/stars)
    static let accentSuccess = Color(hex: "34D399")      // Completion green

    // MARK: Text
    static let textPrimary = Color(hex: "FAFAFA")
    static let textSecondary = Color(hex: "A1A1AA")
    static let textTertiary = Color(hex: "52525B")

    // MARK: Semantic
    static let error = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")
    static let success = Color(hex: "34D399")

    // MARK: Gradients
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentPrimary, accentPrimary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Glass
    static let glassBorder = Color.white.opacity(0.1)
    static let glassBackground = Color.white.opacity(0.05)
}

// MARK: - Typography

/// Editorial-minimal typography with thin display fonts
enum AppTypography {
    // MARK: Display (SF Pro Display, thin weights for elegance)
    static let largeTitle = Font.system(size: 34, weight: .thin, design: .default)
    static let title = Font.system(size: 28, weight: .thin, design: .default)
    static let title2 = Font.system(size: 22, weight: .light, design: .default)
    static let title3 = Font.system(size: 20, weight: .light, design: .default)

    // MARK: Body (SF Pro Text, regular weights for readability)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: Stats (SF Pro Rounded for gamification numbers)
    static let stats = Font.system(size: 16, weight: .medium, design: .rounded)
    static let statsLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let statsBadge = Font.system(size: 14, weight: .semibold, design: .rounded)
}

// MARK: - Editorial Layout

enum EditorialLayout {
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    static let cardRadius: CGFloat = 16
    static let pillRadius: CGFloat = 999
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Editorial Card Style

/// Minimal card style using backgroundSurface
struct EditorialCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EditorialLayout.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: EditorialLayout.cardRadius)
                    .fill(AppColors.backgroundSurface)
            }
    }
}

extension View {
    func editorialCard() -> some View {
        modifier(EditorialCardStyle())
    }
}

// MARK: - Editorial Task Card

/// Premium task card with priority indicator and clean typography
struct EditorialTaskCard: View {
    let title: String
    let priority: Int // 1-3 stars
    let isCompleted: Bool
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Checkbox
                Button(action: onToggle) {
                    Circle()
                        .strokeBorder(
                            isCompleted ? AppColors.accentSuccess : AppColors.textTertiary,
                            lineWidth: 1.5
                        )
                        .background(
                            Circle()
                                .fill(isCompleted ? AppColors.accentSuccess : Color.clear)
                        )
                        .overlay {
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundStyle(isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                        .strikethrough(isCompleted, color: AppColors.textTertiary)
                        .lineLimit(2)

                    // Priority stars
                    if priority > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<priority, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.accentSecondary)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(16)
            .background(AppColors.backgroundSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Editorial Stats Pill

/// Gamification stats pill with native Liquid Glass
struct EditorialStatsPill: View {
    let streakCount: Int
    let starsCount: Int
    let taskCount: Int

    var body: some View {
        HStack(spacing: 16) {
            // Streak
            Label {
                Text("\(streakCount)")
                    .font(AppTypography.stats)
                    .foregroundStyle(AppColors.textPrimary)
            } icon: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(AppColors.accentSecondary)
            }

            // Stars
            Label {
                Text("\(starsCount)")
                    .font(AppTypography.stats)
                    .foregroundStyle(AppColors.textPrimary)
            } icon: {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColors.accentSecondary)
            }

            // Task count badge
            Text("\(taskCount)")
                .font(AppTypography.statsBadge)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppColors.accentPrimary)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - Editorial Empty State

/// Clean empty state with thin typography
struct EditorialEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .padding(40)
    }
}

// MARK: - Editorial Background

/// Dark editorial background
struct EditorialBackground: View {
    var body: some View {
        AppColors.backgroundPrimary
            .ignoresSafeArea()
    }
}

// MARK: - View Extensions

extension View {
    /// Apply editorial dark background
    func editorialBackground() -> some View {
        self.background(EditorialBackground())
            .preferredColorScheme(.dark)
    }
}
