//
//  AmbientSoundService.swift
//  Veloce
//

import Foundation
import AVFoundation
import SwiftUI

enum AmbientSound: String, CaseIterable, Identifiable {
    case none = "None"
    case lofi = "Lo-fi Beats"
    case whiteNoise = "White Noise"
    case rain = "Rain"
    case forest = "Forest"
    case ocean = "Ocean Waves"
    case cafe = "Coffee Shop"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .lofi: return "headphones"
        case .whiteNoise: return "waveform"
        case .rain: return "cloud.rain"
        case .forest: return "leaf"
        case .ocean: return "water.waves"
        case .cafe: return "cup.and.saucer"
        }
    }
}

@MainActor
@Observable
final class AmbientSoundService {
    static let shared = AmbientSoundService()

    private(set) var currentSound: AmbientSound = .none
    private(set) var isPlaying = false
    private(set) var volume: Float = 0.5

    private var audioPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func play(_ sound: AmbientSound) {
        guard sound != .none else { stop(); return }
        currentSound = sound
        // In production, load actual audio files
        isPlaying = true
        HapticsService.shared.selectionFeedback()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentSound = .none
        isPlaying = false
    }

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
    }

    func fadeForBreak() {
        // Reduce volume during Pomodoro breaks
        let originalVolume = volume
        setVolume(volume * 0.3)
        Task {
            try? await Task.sleep(for: .seconds(300)) // 5 min break
            await MainActor.run { setVolume(originalVolume) }
        }
    }
}

struct AmbientSoundPicker: View {
    @State private var service = AmbientSoundService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.circle.fill").foregroundStyle(Theme.Colors.aiPurple)
                Text("Ambient Sounds").font(.headline).foregroundStyle(.white)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AmbientSound.allCases) { sound in
                        Button { service.play(sound) } label: {
                            VStack(spacing: 8) {
                                Image(systemName: sound.icon)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(service.currentSound == sound ? Theme.Colors.aiPurple : .white.opacity(0.1))
                                    .clipShape(SwiftUI.Circle())
                                Text(sound.rawValue)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(service.currentSound == sound ? .white : .white.opacity(0.6))
                        }
                    }
                }
            }

            if service.isPlaying {
                HStack {
                    Image(systemName: "speaker.wave.1")
                    Slider(value: Binding(get: { Double(service.volume) }, set: { service.setVolume(Float($0)) }), in: 0...1)
                        .tint(Theme.Colors.aiPurple)
                    Image(systemName: "speaker.wave.3")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .voidCard()
    }
}
