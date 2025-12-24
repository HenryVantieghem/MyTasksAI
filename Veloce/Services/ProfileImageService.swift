//
//  ProfileImageService.swift
//  Veloce
//
//  Profile Image Service
//  Handles profile picture upload, download, and caching via Supabase Storage
//

import SwiftUI
import Supabase
import Combine

// MARK: - Profile Image Service

@MainActor
final class ProfileImageService: ObservableObject {
    static let shared = ProfileImageService()

    // MARK: - Properties

    private let bucketName = "avatars"
    private let maxImageSize: CGFloat = 500
    private let compressionQuality: CGFloat = 0.8

    private let imageCache = NSCache<NSString, UIImage>()

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var error: String?

    // MARK: - Initialization

    private init() {
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    // MARK: - Upload Avatar

    /// Upload a profile avatar image to Supabase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The user's ID for the storage path
    /// - Returns: The public URL of the uploaded image
    func uploadAvatar(_ image: UIImage, for userId: String) async throws -> URL {
        isUploading = true
        uploadProgress = 0
        error = nil

        defer {
            isUploading = false
            uploadProgress = 1.0
        }

        // Resize and compress image
        guard let processedImage = resizeImage(image, maxSize: maxImageSize),
              let imageData = processedImage.jpegData(compressionQuality: compressionQuality) else {
            throw ProfileImageError.compressionFailed
        }

        uploadProgress = 0.3

        // Create storage path
        let fileName = "profile.jpg"
        let filePath = "\(userId)/\(fileName)"

        // Upload to Supabase Storage
        do {
            // First, try to remove existing file (ignore errors if file doesn't exist)
            try? await SupabaseService.shared.supabase.storage
                .from(bucketName)
                .remove(paths: [filePath])

            uploadProgress = 0.5

            // Upload new file
            try await SupabaseService.shared.supabase.storage
                .from(bucketName)
                .upload(
                    filePath,
                    data: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )

            uploadProgress = 0.8

            // Get public URL
            let publicURL = try SupabaseService.shared.supabase.storage
                .from(bucketName)
                .getPublicURL(path: filePath)

            // Add cache-busting parameter
            let urlWithCacheBust = URL(string: "\(publicURL.absoluteString)?t=\(Date().timeIntervalSince1970)")!

            // Cache the image locally
            cacheImage(processedImage, for: userId)

            uploadProgress = 1.0

            // Update profile record
            try await updateProfileAvatarURL(urlWithCacheBust, for: userId)

            return urlWithCacheBust
        } catch {
            self.error = error.localizedDescription
            throw ProfileImageError.uploadFailed(error.localizedDescription)
        }
    }

    // MARK: - Fetch Avatar

    /// Fetch a user's avatar image
    /// - Parameter userId: The user's ID
    /// - Returns: The avatar UIImage if available
    func fetchAvatar(for userId: String) async -> UIImage? {
        // Check cache first
        if let cached = imageCache.object(forKey: userId as NSString) {
            return cached
        }

        // Fetch URL from profile (uses 'users' table)
        do {
            let response = try await SupabaseService.shared.supabase
                .from("users")
                .select("avatar_url")
                .eq("id", value: userId)
                .single()
                .execute()

            struct AvatarResponse: Decodable {
                let avatar_url: String?
            }

            let data = try JSONDecoder().decode(AvatarResponse.self, from: response.data)

            guard let urlString = data.avatar_url,
                  let url = URL(string: urlString) else {
                return nil
            }

            // Download image
            let (imageData, _) = try await URLSession.shared.data(from: url)

            guard let image = UIImage(data: imageData) else {
                return nil
            }

            // Cache the image
            cacheImage(image, for: userId)

            return image
        } catch {
            print("Failed to fetch avatar: \(error)")
            return nil
        }
    }

    // MARK: - Delete Avatar

    /// Delete a user's avatar from storage
    /// - Parameter userId: The user's ID
    func deleteAvatar(for userId: String) async throws {
        let filePath = "\(userId)/profile.jpg"

        do {
            try await SupabaseService.shared.supabase.storage
                .from(bucketName)
                .remove(paths: [filePath])

            // Clear from cache
            imageCache.removeObject(forKey: userId as NSString)

            // Update profile record
            try await clearProfileAvatarURL(for: userId)
        } catch {
            throw ProfileImageError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Cache Management

    /// Cache an image locally
    private func cacheImage(_ image: UIImage, for userId: String) {
        imageCache.setObject(image, forKey: userId as NSString)
    }

    /// Get cached image
    func getCachedAvatar(for userId: String) -> UIImage? {
        return imageCache.object(forKey: userId as NSString)
    }

    /// Clear cache for a user
    func clearCache(for userId: String) {
        imageCache.removeObject(forKey: userId as NSString)
    }

    /// Clear all cached images
    func clearAllCache() {
        imageCache.removeAllObjects()
    }

    // MARK: - Image Processing

    /// Resize image to fit within max dimensions while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size

        guard size.width > maxSize || size.height > maxSize else {
            return image
        }

        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    // MARK: - Profile Updates

    /// Update the avatar_url in the users table
    private func updateProfileAvatarURL(_ url: URL, for userId: String) async throws {
        try await SupabaseService.shared.supabase
            .from("users")
            .update(["avatar_url": url.absoluteString])
            .eq("id", value: userId)
            .execute()
    }

    /// Clear the avatar_url in the users table
    private func clearProfileAvatarURL(for userId: String) async throws {
        // Use empty string to clear (Supabase doesn't accept nil/NSNull directly)
        try await SupabaseService.shared.supabase
            .from("users")
            .update(["avatar_url": ""])
            .eq("id", value: userId)
            .execute()
    }
}

// MARK: - Profile Image Error

enum ProfileImageError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let message):
            return "Failed to upload image: \(message)"
        case .downloadFailed(let message):
            return "Failed to download image: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete image: \(message)"
        case .invalidURL:
            return "Invalid image URL"
        }
    }
}

// MARK: - Avatar URL Helper

extension URL {
    /// Create an avatar URL with cache-busting parameter
    func withCacheBust() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "t", value: String(Date().timeIntervalSince1970)))
        components.queryItems = queryItems

        return components.url ?? self
    }
}
