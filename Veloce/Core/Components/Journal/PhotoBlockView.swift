//
//  PhotoBlockView.swift
//  Veloce
//
//  Photo Block View - Display and manage photo attachments in journal
//  Supports thumbnail display, full-screen preview, and deletion
//

import SwiftUI
import PhotosUI

// MARK: - Photo Block View

struct PhotoBlockView: View {
    let attachment: PhotoAttachment
    let onDelete: () -> Void
    let onTap: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo image
            photoImage
                .onTapGesture {
                    onTap()
                }

            // Delete button
            Button {
                HapticsService.shared.warning()
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .buttonStyle(.plain)
            .padding(Theme.Spacing.xs)
        }
        .confirmationDialog(
            "Delete this photo?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var photoImage: some View {
        if let thumbnailData = attachment.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        } else if let uiImage = UIImage(contentsOfFile: attachment.localPath) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Colors.glassBackground)
                .frame(height: 200)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
        }
    }
}

// MARK: - Photo Grid View

struct PhotoGridView: View {
    let attachments: [PhotoAttachment]
    let onDelete: (PhotoAttachment) -> Void
    let onTap: (PhotoAttachment) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        if attachments.isEmpty {
            EmptyView()
        } else if attachments.count == 1 {
            // Single photo - full width
            PhotoBlockView(
                attachment: attachments[0],
                onDelete: { onDelete(attachments[0]) },
                onTap: { onTap(attachments[0]) }
            )
        } else {
            // Multiple photos - grid
            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(attachments) { attachment in
                    PhotoBlockView(
                        attachment: attachment,
                        onDelete: { onDelete(attachment) },
                        onTap: { onTap(attachment) }
                    )
                }
            }
        }
    }
}

// MARK: - Photo Picker Button

struct PhotoPickerButton: View {
    @Binding var selectedItems: [PhotosPickerItem]
    let onPhotosSelected: ([PhotosPickerItem]) -> Void

    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                Text("Add Photos")
                    .font(Theme.Typography.callout)
            }
            .foregroundStyle(Theme.Colors.accent)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.Colors.accent.opacity(0.5), lineWidth: 1)
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            if !newItems.isEmpty {
                onPhotosSelected(newItems)
                selectedItems = []
            }
        }
    }
}

// MARK: - Full Screen Photo Viewer

struct FullScreenPhotoViewer: View {
    let attachment: PhotoAttachment
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let uiImage = UIImage(contentsOfFile: attachment.localPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .gesture(dragGesture)
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3)) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                }

                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(Theme.Spacing.lg)
                    }
                    Spacer()
                }
            }
        }
        .statusBarHidden()
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1), 5)
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation(.spring(response: 0.3)) {
                        scale = 1
                        offset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
                if scale <= 1 {
                    withAnimation(.spring(response: 0.3)) {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview("Photo Block") {
    let attachment = PhotoAttachment(
        localPath: "",
        insertionIndex: 0,
        width: 300,
        height: 200
    )

    return PhotoBlockView(
        attachment: attachment,
        onDelete: {},
        onTap: {}
    )
    .padding()
    .background { VoidBackground.journal }
}

#Preview("Photo Grid") {
    let attachments = (0..<4).map { _ in
        PhotoAttachment(
            localPath: "",
            insertionIndex: 0,
            width: 300,
            height: 200
        )
    }

    return PhotoGridView(
        attachments: attachments,
        onDelete: { _ in },
        onTap: { _ in }
    )
    .padding()
    .background { VoidBackground.journal }
}
