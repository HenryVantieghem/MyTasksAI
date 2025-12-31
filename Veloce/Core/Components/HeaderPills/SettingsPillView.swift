//
//  SettingsPillView.swift
//  Veloce
//
//  Settings Pill View
//  User avatar or settings gear in header with reactive avatar sync
//

import SwiftUI

// MARK: - Settings Pill View

struct SettingsPillView: View {
    let avatarUrl: String?
    let userName: String?
    var transparent: Bool = false  // When true, skip glass effect (for unified header)
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppViewModel.self) private var appViewModel

    // Avatar service for loading and reactive updates
    @StateObject private var profileImageService = ProfileImageService.shared
    @State private var avatarImage: UIImage?

    var body: some View {
        Button(action: onTap) {
            pillContent
        }
        .buttonStyle(.plain)
        .onAppear {
            loadAvatar()
        }
        .onChange(of: profileImageService.lastAvatarUpdate) { _, _ in
            // Avatar was updated elsewhere, refresh
            loadAvatar()
        }
    }

    @ViewBuilder
    private var pillContent: some View {
        let content = ZStack {
            // Show loaded avatar image if available
            if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else if let url = avatarUrl, let imageUrl = URL(string: url) {
                // Fallback to AsyncImage if we have a URL but no loaded image
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
        } else if let name = appViewModel.currentUser?.fullName, let initial = name.first {
            Text(String(initial).uppercased())
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundStyle(Theme.Colors.accent)
        } else {
            Image(systemName: "gearshape.fill")
                .dynamicTypeFont(base: 16, weight: .medium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Avatar Loading

    private func loadAvatar() {
        Task {
            if let userId = appViewModel.currentUser?.id.uuidString {
                avatarImage = await profileImageService.fetchAvatar(for: userId)
            }
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
    .environment(AppViewModel())
}
