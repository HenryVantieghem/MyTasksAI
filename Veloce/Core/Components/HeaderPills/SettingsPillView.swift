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
            pillContent
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var pillContent: some View {
        let content = ZStack {
            // Content
            if let url = avatarUrl, let imageUrl = URL(string: url) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(SwiftUI.Circle())
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
        .frame(width: 40, height: 40)

        if transparent {
            content
        } else {
            content.glassEffect(.regular, in: Circle())  // Circular liquid glass pill
        }
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
