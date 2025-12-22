//
//  PomodoroTimerService.swift
//  Veloce
//
//  Pomodoro Timer Service
//  Background-capable timer with Live Activity and Dynamic Island support
//

import Foundation
import ActivityKit
import UserNotifications
import UIKit
import FamilyControls

// PomodoroState, PomodoroSession, and PomodoroActivityAttributes
// are defined in PomodoroModels.swift

// MARK: - Pomodoro Timer Service

@MainActor
@Observable
final class PomodoroTimerService {
    // MARK: Singleton
    static let shared = PomodoroTimerService()

    // MARK: State
    private(set) var currentSession: PomodoroSession?
    private(set) var isRunning = false

    /// Whether the current session is paused
    var isPaused: Bool {
        currentSession?.state == .paused
    }

    // MARK: App Blocking State
    /// Whether app blocking is enabled for current session
    private(set) var isAppBlockingEnabled = false
    /// Whether current session is Deep Focus (unbreakable)
    private(set) var isDeepFocusSession = false
    /// App selection for blocking
    private var blockingSelection: FamilyActivitySelection?

    // MARK: Settings
    var focusDuration: Int = 25 * 60  // 25 minutes
    var shortBreakDuration: Int = 5 * 60  // 5 minutes
    var longBreakDuration: Int = 15 * 60  // 15 minutes
    var sessionsUntilLongBreak: Int = 4

    // MARK: Private
    private var timer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var activity: Activity<PomodoroActivityAttributes>?

    // MARK: Keys
    private let sessionKey = "pomodoro_current_session"
    private let settingsKey = "pomodoro_settings"

    private init() {
        restoreSession()
        requestNotificationPermission()
    }

    // MARK: - Public Methods

    /// Start a new Pomodoro session
    /// - Parameters:
    ///   - taskId: Optional task ID to link the session to
    ///   - taskTitle: Title of the task/session
    ///   - duration: Duration in seconds (defaults to focusDuration)
    ///   - enableAppBlocking: Whether to enable app blocking for this session
    ///   - isDeepFocus: Whether this is a Deep Focus (unbreakable) session
    ///   - appSelection: Apps/categories to block (uses saved selection if nil)
    func startSession(
        taskId: UUID? = nil,
        taskTitle: String,
        duration: Int? = nil,
        enableAppBlocking: Bool = false,
        isDeepFocus: Bool = false,
        appSelection: FamilyActivitySelection? = nil
    ) {
        let totalSeconds = duration ?? focusDuration

        let session = PomodoroSession(
            id: UUID(),
            taskId: taskId,
            taskTitle: taskTitle,
            totalSeconds: totalSeconds,
            remainingSeconds: totalSeconds,
            state: .running,
            startedAt: Date(),
            pausedAt: nil,
            sessionsCompleted: currentSession?.sessionsCompleted ?? 0
        )

        currentSession = session
        isRunning = true

        // Store app blocking state
        isAppBlockingEnabled = enableAppBlocking
        isDeepFocusSession = isDeepFocus
        blockingSelection = appSelection

        // Start app blocking if enabled
        if enableAppBlocking {
            startAppBlocking(
                taskId: taskId,
                taskTitle: taskTitle,
                duration: totalSeconds,
                isDeepFocus: isDeepFocus,
                selection: appSelection
            )
        }

        saveSession()
        startTimer()
        startLiveActivity()
        scheduleCompletionNotification()

        HapticsService.shared.impact()
    }

    /// Start app blocking via FocusBlockingService
    private func startAppBlocking(
        taskId: UUID?,
        taskTitle: String,
        duration: Int,
        isDeepFocus: Bool,
        selection: FamilyActivitySelection?
    ) {
        let focusService = FocusBlockingService.shared

        // Use provided selection or saved selection
        let appsToBlock = selection ?? focusService.selectedAppsToBlock

        // Only start if we have apps to block and are authorized
        guard focusService.isAuthorized,
              !appsToBlock.applicationTokens.isEmpty || !appsToBlock.categoryTokens.isEmpty else {
            isAppBlockingEnabled = false
            return
        }

        Task {
            do {
                try await focusService.startSession(
                    title: "Pomodoro: \(taskTitle)",
                    duration: duration,
                    taskId: taskId,
                    taskTitle: taskTitle,
                    isDeepFocus: isDeepFocus,
                    selection: appsToBlock
                )
            } catch {
                print("Failed to start app blocking: \(error)")
                isAppBlockingEnabled = false
            }
        }
    }

    /// Whether the current session can be stopped (false if Deep Focus is active)
    var canStopSession: Bool {
        if isDeepFocusSession && isAppBlockingEnabled {
            return !FocusBlockingService.shared.isBlocking
        }
        return true
    }

    /// Pause the current session
    func pauseSession() {
        guard var session = currentSession, session.state == .running else { return }

        session.state = .paused
        session.pausedAt = Date()
        currentSession = session
        isRunning = false

        timer?.invalidate()
        timer = nil

        saveSession()
        updateLiveActivity()
        cancelScheduledNotifications()

        HapticsService.shared.selectionFeedback()
    }

    /// Resume a paused session
    func resumeSession() {
        guard var session = currentSession, session.state == .paused else { return }

        session.state = .running
        session.pausedAt = nil
        currentSession = session
        isRunning = true

        saveSession()
        startTimer()
        updateLiveActivity()
        scheduleCompletionNotification()

        HapticsService.shared.impact()
    }

    /// Stop and reset the current session
    func stopSession() {
        timer?.invalidate()
        timer = nil

        currentSession = nil
        isRunning = false

        clearSession()
        endLiveActivity()
        cancelScheduledNotifications()

        HapticsService.shared.selectionFeedback()
    }

    /// Start break time
    func startBreak() {
        guard let session = currentSession else { return }

        let isLongBreak = (session.sessionsCompleted + 1) % sessionsUntilLongBreak == 0
        let breakDuration = isLongBreak ? longBreakDuration : shortBreakDuration

        var newSession = session
        newSession.state = .breakTime
        newSession.remainingSeconds = breakDuration
        currentSession = newSession
        isRunning = true

        saveSession()
        startTimer()
        updateLiveActivity()

        HapticsService.shared.impact()
    }

    /// Skip the current break
    func skipBreak() {
        guard var session = currentSession, session.state == .breakTime else { return }

        session.sessionsCompleted += 1
        session.state = .idle
        currentSession = session
        isRunning = false

        timer?.invalidate()
        timer = nil

        saveSession()
        endLiveActivity()
    }

    // MARK: - Timer Logic

    private func startTimer() {
        timer?.invalidate()

        beginBackgroundTask()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }

        RunLoop.current.add(timer!, forMode: .common)
    }

    private func tick() {
        guard var session = currentSession else { return }

        if session.remainingSeconds > 0 {
            session.remainingSeconds -= 1
            currentSession = session

            // Update Live Activity every 5 seconds to save battery
            if session.remainingSeconds % 5 == 0 {
                updateLiveActivity()
            }

            saveSession()
        } else {
            completeSession()
        }
    }

    private func completeSession() {
        guard var session = currentSession else { return }

        timer?.invalidate()
        timer = nil
        isRunning = false

        if session.state == .running {
            // Focus session completed
            session.sessionsCompleted += 1
            session.state = .completed
            currentSession = session

            HapticsService.shared.celebration()
            sendCompletionNotification()
        } else if session.state == .breakTime {
            // Break completed
            session.state = .idle
            currentSession = session

            HapticsService.shared.taskComplete()
        }

        saveSession()
        updateLiveActivity()
        endBackgroundTask()
    }

    // MARK: - Background Task

    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    // MARK: - Persistence

    private func saveSession() {
        guard let session = currentSession,
              let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: sessionKey)
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    private func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              var session = try? JSONDecoder().decode(PomodoroSession.self, from: data) else { return }

        // Calculate elapsed time if was running
        if session.state == .running, let pausedAt = session.pausedAt {
            let elapsed = Int(Date().timeIntervalSince(pausedAt))
            session.remainingSeconds = max(0, session.remainingSeconds - elapsed)
        }

        currentSession = session

        if session.state == .running && session.remainingSeconds > 0 {
            isRunning = true
            startTimer()
            startLiveActivity()
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleCompletionNotification() {
        guard let session = currentSession else { return }

        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "Great work on \"\(session.taskTitle)\". Time for a break?"
        content.sound = .default
        content.categoryIdentifier = "POMODORO_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(session.remainingSeconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "pomodoro_complete_\(session.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func sendCompletionNotification() {
        guard let session = currentSession else { return }

        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "You completed a \(session.totalSeconds / 60) minute focus session on \"\(session.taskTitle)\""
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelScheduledNotifications() {
        guard let session = currentSession else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pomodoro_complete_\(session.id.uuidString)"]
        )
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              let session = currentSession else { return }

        let attributes = PomodoroActivityAttributes(
            taskTitle: session.taskTitle,
            totalSeconds: session.totalSeconds
        )

        let state = PomodoroActivityAttributes.ContentState(
            remainingSeconds: session.remainingSeconds,
            state: session.state,
            endTime: session.endTime
        )

        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(TimeInterval(session.remainingSeconds + 60))
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func updateLiveActivity() {
        guard let session = currentSession,
              let activity = activity else { return }

        let state = PomodoroActivityAttributes.ContentState(
            remainingSeconds: session.remainingSeconds,
            state: session.state,
            endTime: session.endTime
        )

        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(TimeInterval(session.remainingSeconds + 60))
        )

        Task {
            await activity.update(content)
        }
    }

    private func endLiveActivity() {
        guard let activity = activity else { return }

        let state = PomodoroActivityAttributes.ContentState(
            remainingSeconds: 0,
            state: .completed,
            endTime: Date()
        )

        let content = ActivityContent(
            state: state,
            staleDate: Date()
        )

        Task {
            await activity.end(content, dismissalPolicy: .default)
            self.activity = nil
        }
    }
}
