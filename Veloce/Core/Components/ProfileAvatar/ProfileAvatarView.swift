//
//  ProfileAvatarView.swift
//  Veloce
//
//  Living Cosmos Profile Avatar Component
//  Circular avatar with gradient border, level badge, and edit functionality
//

import SwiftUI
import PhotosUI

// MARK: - Profile Avatar Size

enum ProfileAvatarSize {
    case small      // 40pt - for lists
    case medium     // 60pt - for cards
    case large      // 100pt - for settings
    case hero       // 140pt - for profile edit

    var dimension: CGFloat {
        switch self {
        case .small: return LivingCosmos.Avatar.sizeSmall
        case .medium: return LivingCosmos.Avatar.sizeMedium
        case .large: return LivingCosmos.Avatar.sizeLarge
        case .hero: return LivingCosmos.Avatar.sizeHero
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 2.5
        case .large, .hero: return LivingCosmos.Avatar.borderWidth
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 24
        case .large: return 40
        case .hero: return 56
        }
    }

    var badgeSize: CGFloat {
        switch self {
        case .small: return 18
        case .medium: return 22
        case .large: return 28
        case .hero: return 32
        }
    }

    var badgeOffset: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 22
        case .large: return 36
        case .hero: return 50
        }
    }
}

// MARK: - Profile Avatar View

struct ProfileAvatarView: View {
    let image: UIImage?
    let name: String
    let size: ProfileAvatarSize
    let level: Int?
    let showEditButton: Bool
    let borderGradient: [Color]
    let onEditTap: (() -> Void)?

    @State private var isPressed = false

    init(
        image: UIImage? = nil,
        name: String,
        size: ProfileAvatarSize = .medium,
        level: Int? = nil,
        showEditButton: Bool = false,
        borderGradient: [Color]? = nil,
        onEditTap: (() -> Void)? = nil
    ) {
        self.image = image
        self.name = name
        self.size = size
        self.level = level
        self.showEditButton = showEditButton
        self.borderGradient = borderGradient ?? [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore]
        self.onEditTap = onEditTap
    }

    var body: some View {
        ZStack {
            // Avatar circle
            avatarContent
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(SwiftUI.Circle())
                .overlay {
                    SwiftUI.Circle()
                        .stroke(
                            LinearGradient(
                                colors: borderGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: size.borderWidth
                        )
                }
                .shadow(color: borderGradient.first?.opacity(0.3) ?? Color.clear, radius: 8)

            // Level badge
            if let level {
                levelBadge(level)
                    .offset(x: size.badgeOffset, y: size.badgeOffset)
            }

            // Edit button
            if showEditButton {
                editButton
                    .offset(x: size.badgeOffset, y: -size.badgeOffset)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(LivingCosmos.Animations.quick, value: isPressed)
        .onTapGesture {
            if showEditButton {
                HapticsService.shared.lightImpact()
                onEditTap?()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if showEditButton { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Avatar Content

    @ViewBuilder
    private var avatarContent: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Initials fallback
            ZStack {
                LinearGradient(
                    colors: [Theme.Colors.aiPurple.opacity(0.8), Theme.CelestialColors.plasmaCore.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Text(initials)
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Initials

    private var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    // MARK: - Level Badge

    private func levelBadge(_ level: Int) -> some View {
        ZStack {
            SwiftUI.Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.aiPurple, Theme.CelestialColors.plasmaCore],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.badgeSize, height: size.badgeSize)
                .shadow(color: Theme.Colors.aiPurple.opacity(0.5), radius: 4)

            Text("\(level)")
                .font(.system(size: size.badgeSize * 0.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Edit Button

    private var editButton: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(Theme.CelestialColors.void)
                .frame(width: LivingCosmos.Avatar.editButtonSize, height: LivingCosmos.Avatar.editButtonSize)

            SwiftUI.Circle()
                .stroke(Theme.CelestialColors.starDim, lineWidth: 1)
                .frame(width: LivingCosmos.Avatar.editButtonSize, height: LivingCosmos.Avatar.editButtonSize)

            Image(systemName: "camera.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.CelestialColors.starWhite)
        }
    }
}

// MARK: - Profile Avatar Picker

struct ProfileAvatarPicker: View {
    @Binding var selectedImage: UIImage?
    let currentImage: UIImage?
    let name: String
    let level: Int?
    let onImageSelected: (UIImage) -> Void

    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Avatar
            ProfileAvatarView(
                image: selectedImage ?? currentImage,
                name: name,
                size: .hero,
                level: level,
                showEditButton: true
            ) {
                showingActionSheet = true
            }

            // Change photo button
            CosmicLinkButton("Change Photo") {
                showingActionSheet = true
            }
        }
        .confirmationDialog("Choose Photo", isPresented: $showingActionSheet) {
            Button("Take Photo") {
                sourceType = .camera
                showingImagePicker = true
            }

            Button("Choose from Library") {
                sourceType = .photoLibrary
                showingImagePicker = true
            }

            if selectedImage != nil || currentImage != nil {
                Button("Remove Photo", role: .destructive) {
                    selectedImage = nil
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: sourceType)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) { _, newImage in
            if let newImage {
                onImageSelected(newImage)
            }
        }
    }
}

// MARK: - Image Picker (UIKit Bridge)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Avatar Row (for lists)

struct ProfileAvatarRow: View {
    let image: UIImage?
    let name: String
    let subtitle: String?
    let level: Int?
    let action: (() -> Void)?

    @State private var isPressed = false

    init(
        image: UIImage? = nil,
        name: String,
        subtitle: String? = nil,
        level: Int? = nil,
        action: (() -> Void)? = nil
    ) {
        self.image = image
        self.name = name
        self.subtitle = subtitle
        self.level = level
        self.action = action
    }

    var body: some View {
        Button {
            HapticsService.shared.lightImpact()
            action?()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                ProfileAvatarView(
                    image: image,
                    name: name,
                    size: .small,
                    level: level
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starWhite)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.CelestialColors.starDim)
                    }
                }

                Spacer()

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.CelestialColors.starGhost)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(LivingCosmos.Animations.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if action != nil { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview("Profile Avatars") {
    ZStack {
        VoidBackground.settings

        VStack(spacing: Theme.Spacing.xl) {
            HStack(spacing: Theme.Spacing.lg) {
                ProfileAvatarView(name: "John Doe", size: .small, level: 5)
                ProfileAvatarView(name: "Jane", size: .medium, level: 12)
                ProfileAvatarView(name: "A", size: .large)
            }

            ProfileAvatarView(
                name: "Henry Van",
                size: .hero,
                level: 7,
                showEditButton: true
            ) {
                print("Edit tapped")
            }

            ProfileAvatarRow(
                name: "John Doe",
                subtitle: "john@example.com",
                level: 5
            ) {
                print("Row tapped")
            }
            .celestialGlass()
        }
        .padding()
    }
}
