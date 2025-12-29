//
//  AuroraSounds.swift
//  Veloce
//
//  Aurora Sound Engine - Cosmic UI Sounds for Multisensory Experience
//  Subtle, ethereal audio feedback synchronized with visual effects
//

import SwiftUI
import AVFoundation
import AudioToolbox
import Combine

// MARK: - Aurora Sound Engine

/// Manages cosmic UI sounds for the Aurora Design System
/// Provides subtle, ethereal audio feedback for key interactions
@MainActor
public final class AuroraSoundEngine: ObservableObject {

    // MARK: - Singleton

    public static let shared = AuroraSoundEngine()

    // MARK: - Properties

    /// Whether sounds are enabled (respects user preference)
    @Published public var isEnabled: Bool = true

    /// Master volume (0.0 - 1.0)
    @Published public var volume: Float = 0.6

    /// Audio players cache
    private var audioPlayers: [AuroraSound: AVAudioPlayer] = [:]

    /// Audio session configured
    private var isConfigured = false

    // MARK: - Sound Types

    public enum AuroraSound: String, CaseIterable {
        // Task Interactions
        case taskComplete = "aurora_complete"
        case taskCreate = "aurora_create"
        case checkboxTap = "aurora_checkbox"

        // Navigation
        case tabSwitch = "aurora_tab"
        case sheetOpen = "aurora_sheet_open"
        case sheetClose = "aurora_sheet_close"

        // Celebrations
        case celebration = "aurora_celebration"
        case levelUp = "aurora_level_up"
        case streakMilestone = "aurora_streak"
        case achievement = "aurora_achievement"

        // AI Interactions
        case aiProcessing = "aurora_ai_processing"
        case aiComplete = "aurora_ai_complete"
        case aiSuggestion = "aurora_ai_suggestion"

        // Portal/Major Transitions
        case portalOpen = "aurora_portal_open"
        case portalClose = "aurora_portal_close"

        // Feedback
        case success = "aurora_success"
        case warning = "aurora_warning"
        case error = "aurora_error"

        // Voice
        case recordingStart = "aurora_record_start"
        case recordingStop = "aurora_record_stop"

        // Ambient
        case shimmer = "aurora_shimmer"
        case whisper = "aurora_whisper"

        // Additional aliases for compatibility
        case buttonTap = "aurora_button_tap"
        case dismiss = "aurora_dismiss"
        case aiThinking = "aurora_ai_thinking"
        case aiActivate = "aurora_ai_activate"

        /// System sound ID for fallback (using built-in system sounds)
        var systemSoundID: SystemSoundID {
            switch self {
            case .taskComplete: return 1057  // Soft chime
            case .taskCreate: return 1054    // Tock
            case .checkboxTap: return 1104   // Tick
            case .tabSwitch: return 1103     // Subtle tap
            case .sheetOpen: return 1100     // Swish up
            case .sheetClose: return 1101    // Swish down
            case .celebration: return 1025   // Celebration
            case .levelUp: return 1026       // Level up
            case .streakMilestone: return 1027 // Achievement
            case .achievement: return 1028   // Award
            case .aiProcessing: return 1052  // Processing
            case .aiComplete: return 1057    // Complete
            case .aiSuggestion: return 1054  // Suggestion
            case .portalOpen: return 1110    // Whoosh
            case .portalClose: return 1111   // Reverse whoosh
            case .success: return 1057       // Success
            case .warning: return 1053       // Warning
            case .error: return 1073         // Error
            case .recordingStart: return 1113 // Start
            case .recordingStop: return 1114  // Stop
            case .shimmer: return 1104       // Shimmer
            case .whisper: return 1105       // Whisper
            case .buttonTap: return 1104     // Tap
            case .dismiss: return 1101       // Dismiss
            case .aiThinking: return 1052    // AI Thinking
            case .aiActivate: return 1057    // AI Activate
            }
        }
    }

    // MARK: - Initialization

    private init() {
        configureAudioSession()
        loadUserPreferences()
    }

    // MARK: - Configuration

    private func configureAudioSession() {
        guard !isConfigured else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            isConfigured = true
        } catch {
            print("Aurora Sound: Failed to configure audio session - \(error)")
        }
    }

    private func loadUserPreferences() {
        // Load from UserDefaults
        isEnabled = UserDefaults.standard.bool(forKey: "aurora_sounds_enabled")
        volume = UserDefaults.standard.float(forKey: "aurora_sounds_volume")

        // Default to enabled if never set
        if !UserDefaults.standard.bool(forKey: "aurora_sounds_initialized") {
            isEnabled = true
            volume = 0.6
            UserDefaults.standard.set(true, forKey: "aurora_sounds_initialized")
            savePreferences()
        }
    }

    public func savePreferences() {
        UserDefaults.standard.set(isEnabled, forKey: "aurora_sounds_enabled")
        UserDefaults.standard.set(volume, forKey: "aurora_sounds_volume")
    }

    // MARK: - Play Sound

    /// Play a cosmic UI sound
    /// - Parameters:
    ///   - sound: The sound to play
    ///   - volumeMultiplier: Optional volume adjustment (0.0-1.0)
    public func play(_ sound: AuroraSound, volumeMultiplier: Float = 1.0) {
        guard isEnabled else { return }

        // Try to play custom sound first, fall back to system sound
        if let player = loadOrGetPlayer(for: sound) {
            player.volume = volume * volumeMultiplier
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system sound
            playSystemSound(sound.systemSoundID)
        }
    }

    /// Play system sound by ID
    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }

    /// Load or get cached audio player
    private func loadOrGetPlayer(for sound: AuroraSound) -> AVAudioPlayer? {
        // Return cached player
        if let player = audioPlayers[sound] {
            return player
        }

        // Try to load custom sound file
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav")
               ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a")
               ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[sound] = player
            return player
        } catch {
            print("Aurora Sound: Failed to load \(sound.rawValue) - \(error)")
            return nil
        }
    }

    // MARK: - Convenience Methods

    /// Task completed sound + haptic
    public func taskComplete() {
        play(.taskComplete)
        AuroraHaptics.dopamineBurst()
    }

    /// Tab switched sound + haptic
    public func tabSwitch() {
        play(.tabSwitch, volumeMultiplier: 0.5)
        AuroraHaptics.selection()
    }

    /// Sheet presented sound
    public func sheetOpen() {
        play(.sheetOpen, volumeMultiplier: 0.7)
        AuroraHaptics.soft()
    }

    /// Sheet dismissed sound
    public func sheetClose() {
        play(.sheetClose, volumeMultiplier: 0.6)
    }

    /// Celebration sequence (level up, milestone)
    public func celebration() {
        play(.celebration)
        AuroraHaptics.celebration()
    }

    /// AI processing started
    public func aiProcessing() {
        play(.aiProcessing, volumeMultiplier: 0.4)
        AuroraHaptics.aiTick()
    }

    /// AI processing complete
    public func aiComplete() {
        play(.aiComplete, volumeMultiplier: 0.7)
        AuroraHaptics.success()
    }

    /// Portal opening (major transition)
    public func portalOpen() {
        play(.portalOpen)
        AuroraHaptics.portalOpen()
    }

    /// Error feedback
    public func error() {
        play(.error, volumeMultiplier: 0.5)
        AuroraHaptics.error()
    }

    /// Success feedback
    public func success() {
        play(.success)
        AuroraHaptics.success()
    }

    /// Checkbox tap (quick)
    public func checkboxTap() {
        play(.checkboxTap, volumeMultiplier: 0.3)
        AuroraHaptics.tap()
    }

    /// Recording started
    public func recordingStart() {
        play(.recordingStart)
        AuroraHaptics.impact()
    }

    /// Recording stopped
    public func recordingStop() {
        play(.recordingStop)
        AuroraHaptics.soft()
    }
}

// MARK: - Sound Environment Key

private struct AuroraSoundEngineKey: EnvironmentKey {
    static let defaultValue = AuroraSoundEngine.shared
}

extension EnvironmentValues {
    public var auroraSounds: AuroraSoundEngine {
        get { self[AuroraSoundEngineKey.self] }
        set { self[AuroraSoundEngineKey.self] = newValue }
    }
}

// MARK: - View Modifier for Sound

extension View {

    /// Play sound on tap
    public func auroraSoundOnTap(_ sound: AuroraSoundEngine.AuroraSound) -> some View {
        self.onTapGesture {
            AuroraSoundEngine.shared.play(sound)
        }
    }

    /// Play sound on appear
    public func auroraSoundOnAppear(_ sound: AuroraSoundEngine.AuroraSound) -> some View {
        self.onAppear {
            AuroraSoundEngine.shared.play(sound)
        }
    }

    /// Play sound when value changes
    public func auroraSoundOnChange<V: Equatable>(
        of value: V,
        sound: AuroraSoundEngine.AuroraSound
    ) -> some View {
        self.onChange(of: value) { _, _ in
            AuroraSoundEngine.shared.play(sound)
        }
    }
}

// MARK: - Sound + Haptic Combined Actions

/// Convenience struct for common sound + haptic combinations
public struct AuroraFeedback {

    /// Task completion feedback
    public static func taskComplete() {
        AuroraSoundEngine.shared.taskComplete()
    }

    /// Tab change feedback
    public static func tabChange() {
        AuroraSoundEngine.shared.tabSwitch()
    }

    /// Button tap feedback
    public static func buttonTap() {
        AuroraSoundEngine.shared.play(.checkboxTap, volumeMultiplier: 0.4)
        AuroraHaptics.tap()
    }

    /// Primary action feedback
    public static func primaryAction() {
        AuroraSoundEngine.shared.play(.success, volumeMultiplier: 0.6)
        AuroraHaptics.impact()
    }

    /// Destructive action feedback
    public static func destructiveAction() {
        AuroraSoundEngine.shared.play(.warning, volumeMultiplier: 0.5)
        AuroraHaptics.warning()
    }

    /// Celebration feedback
    public static func celebrate() {
        AuroraSoundEngine.shared.celebration()
    }

    /// AI interaction feedback
    public static func aiInteraction() {
        AuroraSoundEngine.shared.aiProcessing()
    }

    /// AI complete feedback
    public static func aiComplete() {
        AuroraSoundEngine.shared.aiComplete()
    }

    /// Error feedback
    public static func error() {
        AuroraSoundEngine.shared.error()
    }

    /// Sheet open feedback
    public static func sheetOpen() {
        AuroraSoundEngine.shared.sheetOpen()
    }

    /// Sheet close feedback
    public static func sheetClose() {
        AuroraSoundEngine.shared.sheetClose()
    }

    /// Selection change feedback
    public static func selection() {
        AuroraSoundEngine.shared.play(.shimmer, volumeMultiplier: 0.3)
        AuroraHaptics.selection()
    }
}

// MARK: - Preview

#Preview("Aurora Sounds Test") {
    VStack(spacing: 20) {
        Text("Aurora Sound Engine")
            .font(Aurora.Typography.title2)
            .foregroundStyle(Aurora.Colors.textPrimary)

        ForEach(AuroraSoundEngine.AuroraSound.allCases.prefix(10), id: \.rawValue) { sound in
            Button(action: {
                AuroraSoundEngine.shared.play(sound)
            }) {
                Text(sound.rawValue.replacingOccurrences(of: "aurora_", with: "").capitalized)
                    .font(Aurora.Typography.bodyBold)
                    .foregroundStyle(Aurora.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .auroraGlass(.interactive, in: RoundedRectangle(cornerRadius: 12))
            }
        }

        Divider()
            .background(Aurora.Colors.textTertiary)

        Toggle("Sounds Enabled", isOn: Binding(
            get: { AuroraSoundEngine.shared.isEnabled },
            set: {
                AuroraSoundEngine.shared.isEnabled = $0
                AuroraSoundEngine.shared.savePreferences()
            }
        ))
        .font(Aurora.Typography.body)
        .foregroundStyle(Aurora.Colors.textPrimary)
        .tint(Aurora.Colors.electricCyan)
    }
    .padding()
    .background(Aurora.Colors.voidCosmos)
}
