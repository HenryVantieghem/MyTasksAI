//
//  SupabaseService.swift
//  Veloce
//
//  Supabase Service - Database Operations
//  Handles all Supabase interactions for data persistence and sync
//

import Foundation
import Supabase

// MARK: - Supabase Service

@MainActor
@Observable
final class SupabaseService {
    // MARK: Singleton
    static let shared = SupabaseService()

    // MARK: State
    private(set) var isConfigured: Bool = false
    private(set) var currentUserId: UUID?
    private(set) var lastError: String?

    // MARK: Client
    private var client: SupabaseClient?

    // MARK: Configuration
    private var supabaseURL: String {
        loadSecret(key: "SUPABASE_URL") ?? "YOUR_SUPABASE_URL_HERE"
    }
    
    private var supabaseKey: String {
        loadSecret(key: "SUPABASE_ANON_KEY") ?? "YOUR_SUPABASE_ANON_KEY_HERE"
    }

    // MARK: Initialization
    private init() {}
    
    // MARK: - Secret Loading
    
    private func loadSecret(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let value = plist[key] as? String,
              !value.isEmpty,
              !value.contains("YOUR_") else {
            return nil
        }
        return value
    }

    // MARK: - Configuration

    /// Configure the Supabase client
    func configure() {
        let urlString = supabaseURL
        guard urlString != "YOUR_SUPABASE_URL_HERE",
              let url = URL(string: urlString) else {
            lastError = "Invalid Supabase URL. Please configure Secrets.plist"
            return
        }
        
        let key = supabaseKey
        guard key != "YOUR_SUPABASE_ANON_KEY_HERE" else {
            lastError = "Invalid Supabase key. Please configure Secrets.plist"
            return
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        isConfigured = true
    }

    /// Configure with custom URL and key
    func configure(url: String, key: String) {
        guard let supabaseURL = URL(string: url) else {
            lastError = "Invalid Supabase URL"
            return
        }

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: key)
        isConfigured = true
    }

    /// Get the Supabase client (throws if not configured)
    func getClient() throws -> SupabaseClient {
        guard isConfigured, let client else {
            throw SupabaseError.notConfigured
        }
        return client
    }

    /// Get the Supabase client (for backwards compatibility - prefer getClient())
    var supabase: SupabaseClient {
        guard let client else {
            // Check if configuration failed with a specific error
            if let error = lastError {
                fatalError("SupabaseService not configured: \(error)")
            }
            fatalError("SupabaseService not configured. Call configure() first.")
        }
        return client
    }

    // MARK: - Authentication

    /// Get current authenticated user ID
    func getCurrentUserId() async -> UUID? {
        guard isConfigured else { return nil }
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id
            return session.user.id
        } catch {
            return nil
        }
    }

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        currentUserId != nil
    }

    // MARK: - Account Management

    /// Delete current user account and all associated data
    func deleteAccount() async throws {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        // Delete user data from all tables (order matters due to foreign keys)
        // Delete sub-tasks first
        try await supabase
            .from("sub_tasks")
            .delete()
            .eq("task_id", value: "")
            .or("task_id.in.(select id from tasks where user_id.eq.\(userId.uuidString))")
            .execute()

        // Delete task-related data
        try await supabase.from("task_youtube_resources").delete().eq("user_id", value: userId.uuidString).execute()
        try await supabase.from("task_reflections").delete().eq("user_id", value: userId.uuidString).execute()
        try await supabase.from("tasks").delete().eq("user_id", value: userId.uuidString).execute()

        // Delete goals and achievements
        try await supabase.from("goals").delete().eq("user_id", value: userId.uuidString).execute()
        try await supabase.from("achievements").delete().eq("user_id", value: userId.uuidString).execute()

        // Delete streaks and patterns
        try await supabase.from("streaks").delete().eq("user_id", value: userId.uuidString).execute()
        try await supabase.from("user_productivity_patterns").delete().eq("user_id", value: userId.uuidString).execute()

        // Delete user profile
        try await supabase.from("users").delete().eq("id", value: userId.uuidString).execute()

        // Sign out the user (this invalidates the session)
        try await supabase.auth.signOut()

        // Clear local state
        currentUserId = nil
    }

    // MARK: - User Operations

    /// Fetch user profile
    func fetchUser(id: UUID) async throws -> SupabaseUser {
        let response: SupabaseUser = try await supabase
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    /// Create or update user profile
    func upsertUser(_ user: SupabaseUser) async throws {
        try await supabase
            .from("users")
            .upsert(user)
            .execute()
    }

    /// Update user profile fields
    func updateUser(id: UUID, updates: [String: AnyEncodable]) async throws {
        try await supabase
            .from("users")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Task Operations

    /// Fetch all tasks for current user
    func fetchTasks() async throws -> [SupabaseTask] {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let tasks: [SupabaseTask] = try await supabase
            .from("tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("sort_order", ascending: true)
            .order("created_at", ascending: false)
            .execute()
            .value

        return tasks
    }

    /// Fetch incomplete tasks only
    func fetchIncompleteTasks() async throws -> [SupabaseTask] {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let tasks: [SupabaseTask] = try await supabase
            .from("tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_completed", value: false)
            .order("sort_order", ascending: true)
            .execute()
            .value

        return tasks
    }

    /// Fetch single task by ID
    func fetchTask(id: UUID) async throws -> SupabaseTask {
        let task: SupabaseTask = try await supabase
            .from("tasks")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return task
    }

    /// Create new task
    func createTask(_ task: SupabaseTask) async throws -> SupabaseTask {
        let created: SupabaseTask = try await supabase
            .from("tasks")
            .insert(task)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    /// Update existing task
    func updateTask(_ task: SupabaseTask) async throws {
        try await supabase
            .from("tasks")
            .update(task)
            .eq("id", value: task.id.uuidString)
            .execute()
    }

    /// Update task completion status
    func updateTaskCompletion(id: UUID, isCompleted: Bool, pointsEarned: Int? = nil) async throws {
        var updates: [String: AnyEncodable] = [
            "is_completed": AnyEncodable(isCompleted),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        if isCompleted {
            updates["completed_at"] = AnyEncodable(ISO8601DateFormatter().string(from: Date()))
            if let points = pointsEarned {
                updates["points_earned"] = AnyEncodable(points)
            }
        } else {
            updates["completed_at"] = AnyEncodable(nil as String?)
        }

        try await supabase
            .from("tasks")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete task
    func deleteTask(id: UUID) async throws {
        try await supabase
            .from("tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update task sort order
    func updateTaskOrder(id: UUID, sortOrder: Int) async throws {
        try await supabase
            .from("tasks")
            .update(["sort_order": sortOrder])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Sub-Task Operations

    /// Fetch sub-tasks for a task
    func fetchSubTasks(taskId: UUID) async throws -> [SubTask] {
        let subTasks: [SubTask] = try await supabase
            .from("sub_tasks")
            .select()
            .eq("task_id", value: taskId.uuidString)
            .order("order_index", ascending: true)
            .execute()
            .value

        return subTasks
    }

    /// Create sub-tasks for a task
    func createSubTasks(_ subTasks: [SubTask], taskId: UUID) async throws {
        let tasksWithId = subTasks.map { subTask -> SubTask in
            var updated = subTask
            updated.taskId = taskId
            return updated
        }

        try await supabase
            .from("sub_tasks")
            .insert(tasksWithId)
            .execute()
    }

    /// Update sub-task status
    func updateSubTaskStatus(id: UUID, status: SubTaskStatus) async throws {
        var updates: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue)
        ]

        if status == .completed {
            updates["completed_at"] = AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        }

        try await supabase
            .from("sub_tasks")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete sub-tasks for a task
    func deleteSubTasks(taskId: UUID) async throws {
        try await supabase
            .from("sub_tasks")
            .delete()
            .eq("task_id", value: taskId.uuidString)
            .execute()
    }

    // MARK: - Goal Operations

    /// Fetch all goals for current user
    func fetchGoals() async throws -> [SupabaseGoal] {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let goals: [SupabaseGoal] = try await supabase
            .from("goals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return goals
    }

    /// Create new goal
    func createGoal(_ goal: SupabaseGoal) async throws -> SupabaseGoal {
        let created: SupabaseGoal = try await supabase
            .from("goals")
            .insert(goal)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    /// Update goal
    func updateGoal(_ goal: SupabaseGoal) async throws {
        try await supabase
            .from("goals")
            .update(goal)
            .eq("id", value: goal.id.uuidString)
            .execute()
    }

    /// Delete goal
    func deleteGoal(id: UUID) async throws {
        try await supabase
            .from("goals")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Achievement Operations

    /// Fetch achievements for current user
    func fetchAchievements() async throws -> [SupabaseAchievement] {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let achievements: [SupabaseAchievement] = try await supabase
            .from("achievements")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("unlocked_at", ascending: false)
            .execute()
            .value

        return achievements
    }

    /// Create achievement
    func createAchievement(_ achievement: SupabaseAchievement) async throws {
        try await supabase
            .from("achievements")
            .insert(achievement)
            .execute()
    }

    /// Acknowledge achievement
    func acknowledgeAchievement(id: UUID) async throws {
        try await supabase
            .from("achievements")
            .update(["acknowledged": true])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Streak Operations

    /// Fetch streaks for current user
    func fetchStreaks(limit: Int = 30) async throws -> [StreakEntry] {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let streaks: [StreakEntry] = try await supabase
            .from("streaks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value

        return streaks
    }

    /// Update or create streak entry for today
    func updateTodayStreak(tasksCompleted: Int, goalMet: Bool) async throws {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)

        let entry = StreakEntry(
            userId: userId,
            date: String(today),
            tasksCompleted: tasksCompleted,
            goalMet: goalMet
        )

        try await supabase
            .from("streaks")
            .upsert(entry)
            .execute()
    }

    // MARK: - YouTube Resource Operations

    /// Fetch YouTube resources for a task
    func fetchYouTubeResources(taskId: UUID) async throws -> [YouTubeResource] {
        let resources: [YouTubeResource] = try await supabase
            .from("task_youtube_resources")
            .select()
            .eq("task_id", value: taskId.uuidString)
            .order("relevance_score", ascending: false)
            .execute()
            .value

        return resources
    }

    /// Save YouTube resources for a task
    func saveYouTubeResources(_ resources: [YouTubeResource], taskId: UUID) async throws {
        let resourcesWithId = resources.map { resource -> YouTubeResource in
            var updated = resource
            updated.taskId = taskId
            return updated
        }

        try await supabase
            .from("task_youtube_resources")
            .insert(resourcesWithId)
            .execute()
    }

    // MARK: - Reflection Operations

    /// Fetch reflection for a task
    func fetchReflection(taskId: UUID) async throws -> TaskReflection? {
        let reflections: [TaskReflection] = try await supabase
            .from("task_reflections")
            .select()
            .eq("task_id", value: taskId.uuidString)
            .limit(1)
            .execute()
            .value

        return reflections.first
    }

    /// Save task reflection
    func saveReflection(_ reflection: TaskReflection) async throws {
        try await supabase
            .from("task_reflections")
            .insert(reflection)
            .execute()
    }

    // MARK: - Productivity Patterns Operations

    /// Fetch user productivity patterns
    func fetchProductivityPatterns() async throws -> UserProductivityPatterns? {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let patterns: [UserProductivityPatterns] = try await supabase
            .from("user_productivity_patterns")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return patterns.first
    }

    /// Update productivity patterns
    func updateProductivityPatterns(_ patterns: UserProductivityPatterns) async throws {
        try await supabase
            .from("user_productivity_patterns")
            .upsert(patterns)
            .execute()
    }

    // MARK: - Batch Operations

    /// Sync multiple tasks
    func syncTasks(_ tasks: [SupabaseTask]) async throws {
        try await supabase
            .from("tasks")
            .upsert(tasks)
            .execute()
    }

    /// Delete multiple tasks
    func deleteTasks(ids: [UUID]) async throws {
        let idStrings = ids.map { $0.uuidString }
        try await supabase
            .from("tasks")
            .delete()
            .in("id", values: idStrings)
            .execute()
    }
}

// MARK: - Streak Entry Model

struct StreakEntry: Codable, Sendable {
    let userId: UUID
    let date: String
    var tasksCompleted: Int
    var goalMet: Bool
    let createdAt: Date?

    init(
        userId: UUID,
        date: String,
        tasksCompleted: Int = 0,
        goalMet: Bool = false,
        createdAt: Date? = nil
    ) {
        self.userId = userId
        self.date = date
        self.tasksCompleted = tasksCompleted
        self.goalMet = goalMet
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case tasksCompleted = "tasks_completed"
        case goalMet = "goal_met"
        case createdAt = "created_at"
    }
}

// MARK: - Any Encodable Wrapper

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - Supabase Error Types

enum SupabaseError: Error, LocalizedError {
    case notConfigured
    case notAuthenticated
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured"
        case .notAuthenticated:
            return "User is not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .notFound:
            return "Resource not found"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - Real-time Subscriptions

extension SupabaseService {
    /// Subscribe to task changes
    func subscribeToTasks(
        onChange: @escaping ([SupabaseTask]) -> Void
    ) async throws {
        guard let userId = currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let channel = supabase.channel("tasks-changes")

        // Subscribe to Postgres changes for the tasks table and filter by user_id at the server level.
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "tasks",
            filter: .eq("user_id", value: userId.uuidString)
        )

        try await channel.subscribeWithError()

        for await _ in changes {
            // Fetch updated tasks on any change
            if let tasks = try? await fetchTasks() {
                onChange(tasks)
            }
        }
    }

    /// Unsubscribe from all channels
    func unsubscribeAll() async {
        await supabase.removeAllChannels()
    }
}
