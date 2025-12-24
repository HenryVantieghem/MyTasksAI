//
//  TemplateService.swift
//  Veloce
//
//  Template Service - Manages template marketplace operations
//  Part of Templates Marketplace feature
//

import Foundation
import Supabase

// MARK: - Template Service

@MainActor
@Observable
final class TemplateService {
    // MARK: Singleton
    static let shared = TemplateService()

    // MARK: State
    var templates: [Template] = []
    var myTemplates: [Template] = []
    var downloadedTemplates: [Template] = []
    var featuredTemplates: [Template] = []
    var isLoading = false
    var error: String?

    // MARK: Dependencies
    private let supabase = SupabaseService.shared

    // MARK: Initialization
    private init() {}

    // MARK: - Browse Templates

    func loadTemplates(category: TemplateCategory? = nil, searchQuery: String? = nil) async throws {
        guard supabase.isConfigured else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = try supabase.getClient()

            var query = client
                .from("templates")
                .select("*, creator:users!creator_id(id, display_name, username, avatar_url)")
                .eq("is_public", value: true)

            if let category = category {
                query = query.eq("category", value: category.rawValue)
            }

            if let searchQuery = searchQuery, !searchQuery.isEmpty {
                query = query.ilike("title", pattern: "%\(searchQuery)%")
            }

            let response: [Template] = try await query
                .order("download_count", ascending: false)
                .limit(50)
                .execute()
                .value

            templates = response
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func loadFeaturedTemplates() async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()

            let response: [Template] = try await client
                .from("templates")
                .select("*, creator:users!creator_id(id, display_name, username, avatar_url)")
                .eq("is_public", value: true)
                .gte("rating_avg", value: 4.0)
                .order("download_count", ascending: false)
                .limit(10)
                .execute()
                .value

            featuredTemplates = response
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - My Templates

    func loadMyTemplates() async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            let response: [Template] = try await client
                .from("templates")
                .select("*")
                .eq("creator_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            myTemplates = response
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func loadDownloadedTemplates() async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            // Get downloaded template IDs
            let downloads: [TemplateDownload] = try await client
                .from("template_downloads")
                .select("template_id")
                .eq("user_id", value: userId)
                .execute()
                .value

            let templateIds = downloads.map { $0.templateId }

            guard !templateIds.isEmpty else {
                downloadedTemplates = []
                return
            }

            // Fetch template details
            let response: [Template] = try await client
                .from("templates")
                .select("*, creator:users!creator_id(id, display_name, username, avatar_url)")
                .in("id", values: templateIds)
                .execute()
                .value

            downloadedTemplates = response
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Create Template

    func createTemplate(_ request: CreateTemplateRequest) async throws -> Template {
        guard supabase.isConfigured else {
            throw TemplateError.notConfigured
        }

        do {
            let client = try supabase.getClient()

            let response: Template = try await client
                .from("templates")
                .insert(request)
                .select("*")
                .single()
                .execute()
                .value

            myTemplates.insert(response, at: 0)
            return response
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Download Template

    func downloadTemplate(_ template: Template) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            // Check if already downloaded
            let existing: [TemplateDownload] = try await client
                .from("template_downloads")
                .select("id")
                .eq("user_id", value: userId)
                .eq("template_id", value: template.id)
                .execute()
                .value

            guard existing.isEmpty else { return }

            // Create download record
            let download = TemplateDownloadRequest(
                userId: userId,
                templateId: template.id,
                paidCents: template.priceCents
            )

            try await client
                .from("template_downloads")
                .insert(download)
                .execute()

            // Increment download count
            try await client
                .from("templates")
                .update(["download_count": template.downloadCount + 1])
                .eq("id", value: template.id)
                .execute()

            downloadedTemplates.append(template)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Apply Template to Tasks

    func applyTemplate(_ template: Template) async throws -> [TaskItem] {
        guard supabase.isConfigured else { return [] }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return [] }

            var createdTasks: [TaskItem] = []
            let today = Calendar.current.startOfDay(for: Date())

            for templateTask in template.templateData.tasks {
                let task = CreateTaskRequest(
                    userId: userId,
                    title: templateTask.title,
                    notes: templateTask.notes,
                    starRating: templateTask.starRating,
                    estimatedMinutes: templateTask.estimatedMinutes,
                    dueDate: today,
                    templateId: template.id
                )

                let createdTask: TaskItem = try await client
                    .from("tasks")
                    .insert(task)
                    .select("*")
                    .single()
                    .execute()
                    .value

                createdTasks.append(createdTask)
            }

            return createdTasks
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Rate Template

    func rateTemplate(_ templateId: UUID, rating: Int, review: String?) async throws {
        guard supabase.isConfigured else { return }
        guard rating >= 1 && rating <= 5 else { return }

        do {
            let client = try supabase.getClient()
            guard let userId = try await client.auth.session.user.id as UUID? else { return }

            // Check if already rated
            let existing: [TemplateRating] = try await client
                .from("template_ratings")
                .select("id")
                .eq("user_id", value: userId)
                .eq("template_id", value: templateId)
                .execute()
                .value

            if existing.isEmpty {
                // Create new rating
                let ratingRequest = CreateRatingRequest(
                    templateId: templateId,
                    userId: userId,
                    rating: rating,
                    review: review
                )

                try await client
                    .from("template_ratings")
                    .insert(ratingRequest)
                    .execute()
            } else {
                // Update existing rating
                try await client
                    .from("template_ratings")
                    .update(["rating": rating, "review": review as Any])
                    .eq("user_id", value: userId)
                    .eq("template_id", value: templateId)
                    .execute()
            }

            // Recalculate average
            try await updateTemplateRating(templateId)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    private func updateTemplateRating(_ templateId: UUID) async throws {
        let client = try supabase.getClient()

        let ratings: [TemplateRating] = try await client
            .from("template_ratings")
            .select("rating")
            .eq("template_id", value: templateId)
            .execute()
            .value

        guard !ratings.isEmpty else { return }

        let avg = Float(ratings.reduce(0) { $0 + $1.rating }) / Float(ratings.count)

        try await client
            .from("templates")
            .update([
                "rating_avg": avg,
                "rating_count": ratings.count
            ])
            .eq("id", value: templateId)
            .execute()
    }

    // MARK: - Delete Template

    func deleteTemplate(_ templateId: UUID) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()

            try await client
                .from("templates")
                .delete()
                .eq("id", value: templateId)
                .execute()

            myTemplates.removeAll { $0.id == templateId }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Update Template

    func updateTemplate(_ templateId: UUID, title: String?, description: String?, isPublic: Bool?, priceCents: Int?) async throws {
        guard supabase.isConfigured else { return }

        do {
            let client = try supabase.getClient()

            var updates: [String: Any] = ["updated_at": Date().ISO8601Format()]

            if let title = title {
                updates["title"] = title
            }
            if let description = description {
                updates["description"] = description
            }
            if let isPublic = isPublic {
                updates["is_public"] = isPublic
            }
            if let priceCents = priceCents {
                updates["price_cents"] = priceCents
                updates["is_premium"] = priceCents > 0
            }

            try await client
                .from("templates")
                .update(updates)
                .eq("id", value: templateId)
                .execute()

            try await loadMyTemplates()
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
}

// MARK: - Supporting Types

struct TemplateDownload: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let templateId: UUID
    let paidCents: Int
    let downloadedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case templateId = "template_id"
        case paidCents = "paid_cents"
        case downloadedAt = "downloaded_at"
    }
}

struct TemplateDownloadRequest: Codable, Sendable {
    let userId: UUID
    let templateId: UUID
    let paidCents: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case templateId = "template_id"
        case paidCents = "paid_cents"
    }
}

struct CreateRatingRequest: Codable, Sendable {
    let templateId: UUID
    let userId: UUID
    let rating: Int
    let review: String?

    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case userId = "user_id"
        case rating, review
    }
}

struct CreateTaskRequest: Codable, Sendable {
    let userId: UUID
    let title: String
    let notes: String?
    let starRating: Int
    let estimatedMinutes: Int
    let dueDate: Date
    let templateId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title, notes
        case starRating = "star_rating"
        case estimatedMinutes = "estimated_minutes"
        case dueDate = "due_date"
        case templateId = "template_id"
    }
}

enum TemplateError: Error, LocalizedError {
    case notConfigured
    case notAuthenticated
    case templateNotFound
    case alreadyDownloaded

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase not configured"
        case .notAuthenticated: return "User not authenticated"
        case .templateNotFound: return "Template not found"
        case .alreadyDownloaded: return "Template already downloaded"
        }
    }
}
