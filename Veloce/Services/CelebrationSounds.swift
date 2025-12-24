//
//  CelebrationSounds.swift
//  Veloce
//
//  Celebration Sound System
//  Manages audio feedback for task completion celebrations
//  Uses system sounds and synthesized tones for satisfying audio feedback
//

import AVFoundation
import AudioToolbox
import UIKit
import SwiftUI

// MARK: - Celebration Sound Type

enum CelebrationSoundType {
    case quickPop          // Light completion sound
    case completionDing    // Satisfying task complete
    case importantChord    // Triumphant completion
    case streakContinue    // Rising tone for streak
    case streakBreak       // Subtle reset notification
    case milestoneFanfare  // Full celebration
    case xpEarned          // Coin/point sound
    case levelUp           // Achievement sound
}

// MARK: - Celebration Sounds Service

@MainActor
final class CelebrationSounds {
    // MARK: Singleton
    static let shared = CelebrationSounds()

    // MARK: Properties
    private var audioEngine: AVAudioEngine?
    private var playerNodes: [CelebrationSoundType: AVAudioPlayerNode] = [:]
    private var audioBuffers: [CelebrationSoundType: AVAudioPCMBuffer] = [:]

    // Synthesizer for generated tones
    private var synthesizer: ToneSynthesizer?

    // MARK: Settings
    @AppStorage("celebrationSoundsEnabled") private var soundsEnabled = true
    @AppStorage("celebrationSoundVolume") private var volume: Double = 0.6

    // Silent mode detection
    private var isSilentMode: Bool {
        // Check if device is in silent mode
        // This uses a workaround since there's no direct API
        return false // Will respect system sound settings
    }

    // MARK: Initialization
    private init() {
        setupAudioSession()
        setupSynthesizer()
        preloadSounds()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("CelebrationSounds: Failed to setup audio session: \(error)")
        }
    }

    private func setupSynthesizer() {
        synthesizer = ToneSynthesizer()
    }

    private func preloadSounds() {
        // Preload synthesized sounds for instant playback
        // This runs async to not block app launch
        Task {
            await synthesizer?.preloadAllSounds()
        }
    }

    // MARK: - Public API

    /// Quick pop for fast task completion
    func playQuickPop() {
        guard shouldPlaySound() else { return }
        synthesizer?.playQuickPop(volume: Float(volume))
    }

    /// Satisfying ding for normal task completion
    func playCompletionDing() {
        guard shouldPlaySound() else { return }
        synthesizer?.playCompletionDing(volume: Float(volume))
    }

    /// Triumphant chord for important task completion
    func playImportantComplete() {
        guard shouldPlaySound() else { return }
        synthesizer?.playTriumphantChord(volume: Float(volume))
    }

    /// Rising tone for streak continuation
    /// - Parameter count: Current streak count (affects pitch)
    func playStreakContinue(count: Int) {
        guard shouldPlaySound() else { return }

        // Rising pitch based on streak count (musical progression)
        let semitones = min(count - 1, 12) // Cap at one octave
        synthesizer?.playRisingTone(semitones: semitones, volume: Float(volume))
    }

    /// Subtle notification for streak break
    func playStreakBreak() {
        guard shouldPlaySound() else { return }
        synthesizer?.playStreakBreak(volume: Float(volume) * 0.5)
    }

    /// Full celebration fanfare for milestones
    func playMilestoneFanfare() {
        guard shouldPlaySound() else { return }
        synthesizer?.playMilestoneFanfare(volume: Float(volume))
    }

    /// XP earned sound
    func playXPEarned() {
        guard shouldPlaySound() else { return }
        synthesizer?.playCoinSound(volume: Float(volume))
    }

    /// Level up sound
    func playLevelUp() {
        guard shouldPlaySound() else { return }
        synthesizer?.playLevelUp(volume: Float(volume))
    }

    // MARK: - Helpers

    private func shouldPlaySound() -> Bool {
        return soundsEnabled && !isSilentMode
    }
}

// MARK: - Tone Synthesizer

/// Generates celebration sounds programmatically using AudioToolbox
final class ToneSynthesizer {
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var mixerNode: AVAudioMixerNode

    init() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = audioEngine.mainMixerNode

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: mixerNode, format: nil)

        do {
            try audioEngine.start()
        } catch {
            print("ToneSynthesizer: Failed to start audio engine: \(error)")
        }
    }

    func preloadAllSounds() async {
        // Pre-generate common buffers
        // In production, these could be cached to disk
    }

    // MARK: - Sound Generation

    /// Quick pop - short high-pitched blip
    func playQuickPop(volume: Float) {
        playSystemSound(.pop)
    }

    /// Completion ding - satisfying bell tone
    func playCompletionDing(volume: Float) {
        let frequencies: [Double] = [880, 1100] // A5 + overtone
        let durations: [Double] = [0.15, 0.1]
        playChord(frequencies: frequencies, durations: durations, volume: volume)
    }

    /// Triumphant chord - major chord progression
    func playTriumphantChord(volume: Float) {
        // C major chord arpeggio
        Task {
            playTone(frequency: 523.25, duration: 0.12, volume: volume) // C5
            try? await Task.sleep(for: .milliseconds(80))
            playTone(frequency: 659.25, duration: 0.12, volume: volume) // E5
            try? await Task.sleep(for: .milliseconds(80))
            playTone(frequency: 783.99, duration: 0.2, volume: volume)  // G5
            try? await Task.sleep(for: .milliseconds(100))
            playTone(frequency: 1046.5, duration: 0.3, volume: volume * 0.8) // C6
        }
    }

    /// Rising tone based on semitones above base
    func playRisingTone(semitones: Int, volume: Float) {
        // Base note: C5 (523.25 Hz)
        let baseFreq = 523.25
        let frequency = baseFreq * pow(2.0, Double(semitones) / 12.0)
        playTone(frequency: frequency, duration: 0.15, volume: volume)
    }

    /// Subtle descending tone for streak break
    func playStreakBreak(volume: Float) {
        Task {
            playTone(frequency: 400, duration: 0.1, volume: volume)
            try? await Task.sleep(for: .milliseconds(100))
            playTone(frequency: 350, duration: 0.15, volume: volume * 0.7)
        }
    }

    /// Full milestone fanfare
    func playMilestoneFanfare(volume: Float) {
        Task {
            // Fanfare: D-G-B-D ascending
            let notes: [(freq: Double, dur: Double)] = [
                (587.33, 0.15),  // D5
                (783.99, 0.15),  // G5
                (987.77, 0.15),  // B5
                (1174.66, 0.25), // D6
            ]

            for (i, note) in notes.enumerated() {
                playTone(frequency: note.freq, duration: note.dur, volume: volume)
                try? await Task.sleep(for: .milliseconds(Int(note.dur * 1000 * 0.7)))

                // Add harmony on last note
                if i == notes.count - 1 {
                    playTone(frequency: 783.99, duration: 0.3, volume: volume * 0.5)  // G5
                    playTone(frequency: 987.77, duration: 0.3, volume: volume * 0.4)  // B5
                }
            }

            // Shimmer effect
            try? await Task.sleep(for: .milliseconds(100))
            for _ in 0..<3 {
                playTone(frequency: Double.random(in: 1800...2400), duration: 0.05, volume: volume * 0.2)
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    /// Coin/XP earned sound
    func playCoinSound(volume: Float) {
        // Classic coin sound: two quick rising tones
        Task {
            playTone(frequency: 988, duration: 0.08, volume: volume)  // B5
            try? await Task.sleep(for: .milliseconds(60))
            playTone(frequency: 1319, duration: 0.12, volume: volume) // E6
        }
    }

    /// Level up sound
    func playLevelUp(volume: Float) {
        Task {
            // Ascending arpeggio with sparkle
            let notes: [Double] = [523.25, 659.25, 783.99, 1046.5, 1318.5]
            for (i, freq) in notes.enumerated() {
                let delay = 60 - (i * 5) // Accelerating
                playTone(frequency: freq, duration: 0.12, volume: volume)
                try? await Task.sleep(for: .milliseconds(delay))
            }

            // Final chord
            try? await Task.sleep(for: .milliseconds(50))
            playTone(frequency: 1046.5, duration: 0.3, volume: volume)
            playTone(frequency: 1318.5, duration: 0.3, volume: volume * 0.7)
            playTone(frequency: 1568.0, duration: 0.3, volume: volume * 0.5)
        }
    }

    // MARK: - Low-Level Tone Generation

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))
        else { return }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        let data = buffer.floatChannelData![0]

        for i in 0..<frameCount {
            let time = Double(i) / sampleRate

            // Generate sine wave
            var sample = sin(2.0 * .pi * frequency * time)

            // Apply envelope (attack-decay)
            let attackTime = 0.01
            let decayStart = duration * 0.7

            if time < attackTime {
                sample *= time / attackTime
            } else if time > decayStart {
                let decayProgress = (time - decayStart) / (duration - decayStart)
                sample *= 1.0 - decayProgress
            }

            data[i] = Float(sample) * volume
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private func playChord(frequencies: [Double], durations: [Double], volume: Float) {
        for (freq, dur) in zip(frequencies, durations) {
            playTone(frequency: freq, duration: dur, volume: volume * 0.7)
        }
    }

    // MARK: - System Sounds

    enum SystemSoundEffect {
        case pop
        case ding
        case success
        case coin

        var soundID: SystemSoundID {
            switch self {
            case .pop: return 1104      // Pop
            case .ding: return 1057     // Tink
            case .success: return 1025  // Short success
            case .coin: return 1016     // Tweet
            }
        }
    }

    private func playSystemSound(_ effect: SystemSoundEffect) {
        AudioServicesPlaySystemSound(effect.soundID)
    }
}

// MARK: - Sound Settings View

struct CelebrationSoundSettings: View {
    @AppStorage("celebrationSoundsEnabled") private var soundsEnabled = true
    @AppStorage("celebrationSoundVolume") private var volume: Double = 0.6

    var body: some View {
        Section {
            Toggle("Celebration Sounds", isOn: $soundsEnabled)

            if soundsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volume")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(.secondary)

                        Slider(value: $volume, in: 0.1...1.0)
                            .tint(Theme.Celebration.plasmaCore)

                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    // Preview sound
                    CelebrationSounds.shared.playCompletionDing()
                } label: {
                    Label("Preview Sound", systemImage: "play.circle")
                }
            }
        } header: {
            Text("Sounds")
        }
    }
}

// MARK: - Preview

#Preview("Sound Settings") {
    NavigationStack {
        Form {
            CelebrationSoundSettings()
        }
        .navigationTitle("Settings")
    }
    .preferredColorScheme(.dark)
}
