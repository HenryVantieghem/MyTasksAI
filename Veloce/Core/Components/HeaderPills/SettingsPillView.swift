//
//  SettingsPillView.swift
//  Veloce
//
//  Settings Pill View
//  User avatar or settings gear in header
//

import SwiftUI

// MARK: - Settings Pill View

struct SettingsPillView: View {
    let avatarUrl: String?
    let userName: String?
    var transparent: Bool = false  // When true, skip glass effect (for unified header)
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle (only when not transparent)
                if !transparent {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                            .white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .frame(width: 36, height: 36)
                }

                // Content
                if let url = avatarUrl, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure, .empty:
                            fallbackContent
                        @unknown default:
                            fallbackContent
                        }
                    }
                } else {
                    fallbackContent
                }
            }
            .frame(width: 36, height: 36)  // Consistent size whether transparent or not
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fallback Content

    @ViewBuilder
    private var fallbackContent: some View {
        if let name = userName, let initial = name.first {
            Text(String(initial).uppercased())
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundStyle(Theme.Colors.accent)
        } else {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        SettingsPillView(avatarUrl: nil, userName: nil) { }
        SettingsPillView(avatarUrl: nil, userName: "John") { }
        SettingsPillView(avatarUrl: "https://example.com/avatar.jpg", userName: "Jane") { }
    }
    .padding()
    .background(Theme.Colors.background)
}
