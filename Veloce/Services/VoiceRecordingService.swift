//
//  VoiceRecordingService.swift
//  Veloce
//
//  Voice Recording Service with Speech-to-Text Transcription
//  Uses AVFoundation for recording and Speech framework for transcription
//

import Foundation
import AVFoundation
import Speech

// MARK: - Voice Recording Service

@MainActor
@Observable
final class VoiceRecordingService: NSObject {
    static let shared = VoiceRecordingService()

    // MARK: State
    private(set) var isRecording = false
    private(set) var recordingTime: TimeInterval = 0
    private(set) var audioLevel: Float = 0
    private(set) var isTranscribing = false
    private(set) var transcriptionProgress: Double = 0

    var errorMessage: String?

    // MARK: Private
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var currentRecordingURL: URL?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    // MARK: Initialization

    private override init() {
        super.init()
    }

    // MARK: Permissions

    func requestPermissions() async -> Bool {
        // Request microphone permission
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard audioStatus else {
            errorMessage = "Microphone access is required for voice recording"
            return false
        }

        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        if !speechStatus {
            errorMessage = "Speech recognition access is required for transcription"
            // Still allow recording without transcription
        }

        return audioStatus
    }

    // MARK: Recording

    func startRecording() async throws -> URL {
        // Request permissions if needed
        let hasPermission = await requestPermissions()
        guard hasPermission else {
            throw VoiceRecordingError.permissionDenied
        }

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsFolder = documentsPath.appendingPathComponent("VoiceRecordings", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: recordingsFolder, withIntermediateDirectories: true)

        let fileName = "\(UUID().uuidString).m4a"
        let recordingURL = recordingsFolder.appendingPathComponent(fileName)

        // Recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Create recorder
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()

        guard audioRecorder?.record() == true else {
            throw VoiceRecordingError.recordingFailed
        }

        currentRecordingURL = recordingURL
        isRecording = true
        recordingTime = 0

        // Start timers
        startTimers()

        return recordingURL
    }

    func stopRecording() async throws -> VoiceRecording {
        guard isRecording, let recorder = audioRecorder, let url = currentRecordingURL else {
            throw VoiceRecordingError.noActiveRecording
        }

        // Stop recording
        recorder.stop()
        stopTimers()

        isRecording = false

        // Get duration
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration).seconds

        // Create recording object
        let recording = VoiceRecording(
            localPath: url.path,
            duration: duration,
            transcription: nil
        )

        // Reset state
        audioRecorder = nil
        currentRecordingURL = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)

        return recording
    }

    func cancelRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        stopTimers()

        // Delete the file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        isRecording = false
        audioRecorder = nil
        currentRecordingURL = nil

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: Transcription

    func transcribe(audioURL: URL) async throws -> String {
        guard speechRecognizer?.isAvailable == true else {
            throw VoiceRecordingError.transcriptionUnavailable
        }

        isTranscribing = true
        transcriptionProgress = 0

        defer {
            isTranscribing = false
            transcriptionProgress = 0
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        return try await withCheckedThrowingContinuation { continuation in
            speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = result else {
                    continuation.resume(throwing: VoiceRecordingError.transcriptionFailed)
                    return
                }

                if result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    continuation.resume(returning: transcription)
                }

                // Update progress
                Task { @MainActor in
                    self?.transcriptionProgress = Double(result.bestTranscription.segments.count) / 10.0
                }
            }
        }
    }

    // MARK: Playback

    func playRecording(at path: String) async throws {
        let url = URL(fileURLWithPath: path)

        // Configure audio session for playback
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        // Use AVAudioPlayer for simple playback
        // In production, you might want a more sophisticated player
    }

    // MARK: Private Methods

    private func startTimers() {
        // Recording time timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingTime += 0.1
            }
        }

        // Audio level timer
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevel()
            }
        }
    }

    private func stopTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0
            return
        }

        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        // Normalize from -160...0 to 0...1
        let normalizedLevel = max(0, (level + 50) / 50)
        audioLevel = normalizedLevel
    }

    // MARK: Helpers

    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func deleteRecording(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}

// MARK: - Voice Recording Error

enum VoiceRecordingError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case noActiveRecording
    case transcriptionUnavailable
    case transcriptionFailed
    case playbackFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required for voice recording"
        case .recordingFailed:
            return "Failed to start recording"
        case .noActiveRecording:
            return "No active recording to stop"
        case .transcriptionUnavailable:
            return "Speech recognition is not available"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .playbackFailed:
            return "Failed to play recording"
        }
    }
}
