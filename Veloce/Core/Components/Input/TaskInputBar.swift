//
//  TaskInputBar.swift
//  Veloce
//
//  Premium Task Input Bar - Claude Mobile Inspired
//  Luxury holographic glass with voice input, AI processing, and quick add
//

import SwiftUI
import Speech

// MARK: - Task Input Bar Metrics

private enum TaskInputBarMetrics {
    static let baseHeight: CGFloat = 52
    static let expandedHeight: CGFloat = 72
    static let horizontalPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 26
    static let buttonSize: CGFloat = 38
    static let sendButtonSize: CGFloat = 42
    static let iconSize: CGFloat = 16
    static let micIconSize: CGFloat = 18
}

// MARK: - Quick Add Template

struct QuickAddTemplate: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color

    static let defaults: [QuickAddTemplate] = [
        QuickAddTemplate(title: "Email", icon: "envelope.fill", color: Theme.Colors.aiBlue),
        QuickAddTemplate(title: "Call", icon: "phone.fill", color: Theme.Colors.aiGreen),
        QuickAddTemplate(title: "Meeting", icon: "person.2.fill", color: Theme.Colors.aiPurple),
        QuickAddTemplate(title: "Review", icon: "doc.text.fill", color: Theme.Colors.aiOrange),
        QuickAddTemplate(title: "Exercise", icon: "figure.run", color: Theme.Colors.aiCyan),
        QuickAddTemplate(title: "Shopping", icon: "cart.fill", color: Theme.Colors.aiPink)
    ]
}

// MARK: - Task Input Bar

struct TaskInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var onSubmit: (String) -> Void
    var onVoiceInput: (() -> Void)? = nil

    // Voice recording service
    private var voiceService: VoiceRecordingService { VoiceRecordingService.shared }

    // Recording state
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var recordingPulse: CGFloat = 1.0
    @State private var audioLevel: Float = 0
    @State private var currentRecordingURL: URL?
    @State private var voiceError: String?
    @State private var showVoiceError = false

    // AI processing state
    @State private var isAIProcessing = false
    @State private var aiDotPhase: Int = 0
    @State private var showCategoryBadge = false
    @State private var categoryText: String = ""

    // Quick add state
    @State private var showQuickAdd = false
    @State private var quickAddTemplates: [QuickAddTemplate] = QuickAddTemplate.defaults

    // AI enhancement state
    @State private var showAISheet = false
    @State private var isAIEnhancing = false
    @State private var aiEnhanceError: String?
    @State private var showAIError = false
    @State private var aiModeEnabled = false

    // Animation state
    @State private var sendPulse: CGFloat = 1.0
    @State private var glowPhase: CGFloat = 0
    @State private var borderRotation: Double = 0
    @State private var sparkleRotation: Double = 0

    // Audio level monitoring
    @State private var audioLevelTimer: Timer?

    // AI Service
    private var aiService: AIService { AIService.shared }

    // Services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Category badge (shows after AI processing)
            if showCategoryBadge {
                categoryBadgeView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                    .padding(.bottom, 8)
            }

            // Main input container
            mainInputContainer
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddSheet(
                templates: $quickAddTemplates,
                onSelect: { template in
                    text = template.title
                    showQuickAdd = false
                    HapticsService.shared.selectionFeedback()
                },
                onAddCustom: {
                    showQuickAdd = false
                    isFocused.wrappedValue = true
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showAISheet) {
            AIEnhanceSheet(
                text: $text,
                isProcessing: $isAIEnhancing,
                onEnhance: { action in
                    performAIAction(action)
                },
                onDismiss: {
                    showAISheet = false
                }
            )
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        .alert("AI Error", isPresented: $showAIError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(aiEnhanceError ?? "Failed to process with AI")
        }
        .animation(Theme.Animation.springBouncy, value: isFocused.wrappedValue)
        .animation(Theme.Animation.springBouncy, value: showCategoryBadge)
        .animation(Theme.Animation.spring, value: canSend)
        .animation(Theme.Animation.spring, value: isRecording)
        .animation(Theme.Animation.spring, value: isTranscribing)
        .animation(Theme.Animation.springBouncy, value: aiModeEnabled)
        .animation(Theme.Animation.spring, value: isAIEnhancing)
        .onAppear {
            startAmbientAnimations()
        }
        .onDisappear {
            // Clean up any ongoing recording
            if isRecording {
                cancelVoiceRecording()
            }
        }
    }

    // MARK: - Main Input Container

    private var mainInputContainer: some View {
        HStack(spacing: 12) {
            // Voice input button
            voiceInputButton

            // Text field
            expandingTextField

            // Right side controls
            HStack(spacing: 8) {
                // AI sparkles toggle (visible when keyboard shown)
                if isFocused.wrappedValue {
                    aiSparklesButton
                        .transition(.scale.combined(with: .opacity))
                }

                // Quick add / Send button
                if canSend {
                    sendButton
                        .transition(.scale.combined(with: .opacity))
                } else {
                    quickAddButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, TaskInputBarMetrics.horizontalPadding)
        .padding(.vertical, isFocused.wrappedValue ? 14 : 8)
        .frame(minHeight: isFocused.wrappedValue ? TaskInputBarMetrics.expandedHeight : TaskInputBarMetrics.baseHeight)
        .background { inputBackground }
        .overlay { inputBorder }
        .shadow(
            color: canSend
                ? Theme.Colors.aiPurple.opacity(0.35)
                : Color.black.opacity(0.15),
            radius: isFocused.wrappedValue ? 20 : 12,
            y: isFocused.wrappedValue ? 6 : 4
        )
        // AI Processing shimmer overlay
        .overlay {
            if isAIProcessing {
                aiProcessingOverlay
            }
        }
        .padding(.horizontal, TaskInputBarMetrics.horizontalPadding)
    }

    // MARK: - Input Background
    // iOS 26: Uses native Liquid Glass with adaptive fallback

    private var inputBackground: some View {
        ZStack {
            // iOS 26 native Liquid Glass (or fallback for older versions)
            Capsule()
                .fill(.clear)
                .adaptiveGlassCapsule()

            // Focused state: add subtle AI tint overlay
            if isFocused.wrappedValue {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(0.04),
                                Theme.Colors.aiBlue.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Input Border
    // iOS 26: Liquid Glass handles base border, only show special states

    @ViewBuilder
    private var inputBorder: some View {
        // Animated holographic border when recording
        if isRecording && !reduceMotion {
            Capsule()
                .stroke(
                    AngularGradient(
                        colors: [
                            .red.opacity(0.6),
                            Theme.Colors.aiPurple.opacity(0.4),
                            .red.opacity(0.3),
                            Theme.Colors.aiPink.opacity(0.5),
                            .red.opacity(0.6)
                        ],
                        center: .center,
                        angle: .degrees(borderRotation)
                    ),
                    lineWidth: 2
                )
                .blur(radius: 0.5)
        } else if isFocused.wrappedValue {
            // Subtle focus indicator with AI gradient
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.aiPurple.opacity(0.4),
                            Theme.Colors.aiBlue.opacity(0.2),
                            Theme.Colors.aiCyan.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Voice Input Button
    // iOS 26: Simplified design with glass effect

    private var voiceInputButton: some View {
        Button {
            HapticsService.shared.impact()
            toggleVoiceRecording()
        } label: {
            ZStack {
                // Recording pulse rings (kept for visual feedback)
                if isRecording && !reduceMotion {
                    ForEach(0..<3, id: \.self) { ring in
                        SwiftUI.Circle()
                            .stroke(Color.red.opacity(0.3 - Double(ring) * 0.1), lineWidth: 2)
                            .frame(
                                width: TaskInputBarMetrics.buttonSize + CGFloat(ring) * 12,
                                height: TaskInputBarMetrics.buttonSize + CGFloat(ring) * 12
                            )
                            .scaleEffect(recordingPulse)
                            .opacity(Double(3 - ring) / 3)
                    }
                }

                // Transcribing pulse (purple)
                if isTranscribing && !reduceMotion {
                    SwiftUI.Circle()
                        .stroke(Theme.Colors.aiPurple.opacity(0.3), lineWidth: 2)
                        .frame(width: TaskInputBarMetrics.buttonSize + 8, height: TaskInputBarMetrics.buttonSize + 8)
                        .scaleEffect(recordingPulse)
                }

                // Button with state-based styling
                Group {
                    if isRecording {
                        // Recording: solid red background
                        SwiftUI.Circle()
                            .fill(Color.red)
                            .frame(width: TaskInputBarMetrics.buttonSize, height: TaskInputBarMetrics.buttonSize)
                    } else if isTranscribing {
                        // Transcribing: purple tinted
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiPurple.opacity(0.2))
                            .frame(width: TaskInputBarMetrics.buttonSize, height: TaskInputBarMetrics.buttonSize)
                    } else {
                        // Default: subtle glass-like background
                        SwiftUI.Circle()
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: TaskInputBarMetrics.buttonSize, height: TaskInputBarMetrics.buttonSize)
                    }
                }

                // Audio level indicator (when recording)
                if isRecording {
                    SwiftUI.Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: TaskInputBarMetrics.buttonSize, height: TaskInputBarMetrics.buttonSize)
                        .scaleEffect(0.3 + CGFloat(audioLevel) * 0.7)
                }

                // Icon based on state
                if isTranscribing {
                    Image(systemName: "waveform")
                        .font(.system(size: TaskInputBarMetrics.micIconSize, weight: .medium))
                        .foregroundStyle(Theme.Colors.aiPurple)
                        .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
                } else {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: TaskInputBarMetrics.micIconSize, weight: .medium))
                        .foregroundStyle(isRecording ? .white : .secondary)
                        .scaleEffect(isRecording ? 0.85 : 1.0)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .disabled(isTranscribing)
        .accessibilityLabel(voiceButtonAccessibilityLabel)
        .alert("Voice Input Error", isPresented: $showVoiceError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(voiceError ?? "An unknown error occurred")
        }
    }

    private var voiceButtonAccessibilityLabel: String {
        if isTranscribing {
            return "Transcribing audio"
        } else if isRecording {
            return "Stop recording"
        } else {
            return "Voice input"
        }
    }

    // MARK: - Expanding Text Field

    private var expandingTextField: some View {
        TextField("", text: $text, prompt: placeholderText, axis: .vertical)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.primary)
            .lineLimit(isFocused.wrappedValue ? 1...6 : 1...2)
            .focused(isFocused)
            .submitLabel(.send)
            .onSubmit {
                if canSend {
                    submitTask()
                }
            }
            .tint(Theme.Colors.aiPurple)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(false)
            // iOS 26: Keyboard dismiss button
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button {
                        isFocused.wrappedValue = false
                        HapticsService.shared.lightImpact()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
    }

    private var placeholderText: Text {
        Text("What's on your mind?")
            .font(.system(size: 16, weight: .light))
            .italic()
            .foregroundStyle(.secondary.opacity(0.6))
    }

    // MARK: - AI Sparkles Button

    private var aiSparklesButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            if canSend {
                // Show AI enhancement options
                showAISheet = true
            } else {
                // Toggle AI mode for auto-enhancement on submit
                withAnimation(Theme.Animation.springBouncy) {
                    aiModeEnabled.toggle()
                }
                if aiModeEnabled {
                    HapticsService.shared.success()
                }
            }
        } label: {
            ZStack {
                // Animated glow when AI mode enabled
                if aiModeEnabled || isAIEnhancing {
                    SwiftUI.Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.aiPurple.opacity(0.4),
                                    Theme.Colors.aiCyan.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 52, height: 52)
                        .blur(radius: 6)
                        .scaleEffect(isAIEnhancing ? 1.2 : 1.0)
                }

                // Subtle glow background
                SwiftUI.Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.aiPurple.opacity(aiModeEnabled ? 0.35 : 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 44, height: 44)
                    .blur(radius: 3)

                // Button circle
                SwiftUI.Circle()
                    .fill(
                        aiModeEnabled
                            ? LinearGradient(
                                colors: [Theme.Colors.aiPurple.opacity(0.3), Theme.Colors.aiCyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Theme.Colors.aiPurple.opacity(0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(width: TaskInputBarMetrics.buttonSize - 4, height: TaskInputBarMetrics.buttonSize - 4)
                    .overlay {
                        if aiModeEnabled {
                            SwiftUI.Circle()
                                .stroke(
                                    AngularGradient(
                                        colors: [
                                            Theme.Colors.aiPurple,
                                            Theme.Colors.aiCyan,
                                            Theme.Colors.aiPink,
                                            Theme.Colors.aiPurple
                                        ],
                                        center: .center,
                                        angle: .degrees(sparkleRotation)
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    }

                // Sparkles icon
                if isAIEnhancing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.Colors.aiPurple)
                } else {
                    Image(systemName: aiModeEnabled ? "sparkles" : "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: aiModeEnabled
                                    ? [Theme.Colors.aiPurple, Theme.Colors.aiCyan, Theme.Colors.aiPink]
                                    : [Theme.Colors.aiPurple, Theme.Colors.aiCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: aiModeEnabled)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .disabled(isAIEnhancing)
        .accessibilityLabel(aiSparklesAccessibilityLabel)
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    sparkleRotation = 360
                }
            }
        }
    }

    private var aiSparklesAccessibilityLabel: String {
        if isAIEnhancing {
            return "AI is processing"
        } else if canSend {
            return "Enhance with AI"
        } else {
            return aiModeEnabled ? "AI mode enabled" : "Enable AI mode"
        }
    }

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button {
            HapticsService.shared.selectionFeedback()
            showQuickAdd = true
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: TaskInputBarMetrics.buttonSize, height: TaskInputBarMetrics.buttonSize)

                Image(systemName: "bolt.fill")
                    .font(.system(size: TaskInputBarMetrics.iconSize, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contentShape(SwiftUI.Circle())
        .accessibilityLabel("Quick add")
    }

    // MARK: - Send Button
    // iOS 26: Cleaner gradient orb design

    private var sendButton: some View {
        Button {
            submitTask()
        } label: {
            ZStack {
                // Subtle ambient glow (only when not reducing motion)
                if !reduceMotion {
                    SwiftUI.Circle()
                        .fill(Theme.AdaptiveColors.aiPrimary.opacity(0.4))
                        .frame(width: 48, height: 48)
                        .blur(radius: 8)
                        .scaleEffect(sendPulse)
                }

                // Main button with gradient
                SwiftUI.Circle()
                    .fill(Theme.AdaptiveColors.aiGradient)
                    .frame(width: 38, height: 38)
                    .overlay {
                        // Subtle inner highlight for depth
                        SwiftUI.Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 16
                                )
                            )
                    }

                // Arrow icon
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(OrbButtonStyle())
        .accessibilityLabel("Send task")
    }

    // MARK: - AI Processing Overlay

    private var aiProcessingOverlay: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.aiPurple.opacity(0.08),
                        Theme.Colors.aiCyan.opacity(0.05),
                        Theme.Colors.aiPurple.opacity(0.08)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                // Thinking dots
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        SwiftUI.Circle()
                            .fill(Theme.Colors.aiPurple)
                            .frame(width: 8, height: 8)
                            .opacity(aiDotPhase == index ? 1.0 : 0.3)
                            .scaleEffect(aiDotPhase == index ? 1.2 : 0.8)
                    }
                }
            }
            .allowsHitTesting(false)
    }

    // MARK: - Category Badge

    private var categoryBadgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))

            Text(categoryText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Theme.Colors.aiPurple)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.Colors.aiPurple.opacity(0.12))
                .overlay {
                    Capsule()
                        .stroke(Theme.Colors.aiPurple.opacity(0.25), lineWidth: 0.5)
                }
        }
    }

    // MARK: - Actions

    private func toggleVoiceRecording() {
        if isRecording {
            stopVoiceRecording()
        } else {
            startVoiceRecording()
        }
    }

    private func startVoiceRecording() {
        Task {
            do {
                // Start recording via service
                let url = try await voiceService.startRecording()
                currentRecordingURL = url

                await MainActor.run {
                    isRecording = true
                    onVoiceInput?()

                    // Start pulse animation
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                        ) {
                            recordingPulse = 1.15
                        }

                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            borderRotation = 360
                        }
                    }

                    // Start monitoring audio levels from service
                    startAudioLevelMonitoring()
                }
            } catch {
                await MainActor.run {
                    voiceError = error.localizedDescription
                    showVoiceError = true
                    HapticsService.shared.error()
                }
            }
        }
    }

    private func stopVoiceRecording() {
        Task {
            do {
                // Stop recording and get the recording object
                let recording = try await voiceService.stopRecording()

                await MainActor.run {
                    isRecording = false
                    stopAudioLevelMonitoring()
                    recordingPulse = 1.0
                    borderRotation = 0
                    audioLevel = 0

                    // Start transcription
                    isTranscribing = true

                    // Restart pulse for transcribing state
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                        ) {
                            recordingPulse = 1.1
                        }
                    }
                }

                // Transcribe the audio
                let audioURL = URL(fileURLWithPath: recording.localPath)
                let transcription = try await voiceService.transcribe(audioURL: audioURL)

                await MainActor.run {
                    isTranscribing = false
                    recordingPulse = 1.0

                    // Insert transcription into text field
                    if text.isEmpty {
                        text = transcription
                    } else {
                        text += " " + transcription
                    }

                    // Focus the text field
                    isFocused.wrappedValue = true

                    // Haptic feedback for success
                    HapticsService.shared.success()

                    // Clean up the recording file
                    voiceService.deleteRecording(at: recording.localPath)
                }
            } catch {
                await MainActor.run {
                    isRecording = false
                    isTranscribing = false
                    recordingPulse = 1.0
                    borderRotation = 0
                    audioLevel = 0
                    stopAudioLevelMonitoring()

                    voiceError = error.localizedDescription
                    showVoiceError = true
                    HapticsService.shared.error()
                }
            }
        }
    }

    private func cancelVoiceRecording() {
        voiceService.cancelRecording()
        isRecording = false
        isTranscribing = false
        recordingPulse = 1.0
        borderRotation = 0
        audioLevel = 0
        stopAudioLevelMonitoring()
    }

    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                self.audioLevel = self.voiceService.audioLevel
            }
        }
    }

    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }

    private func submitTask() {
        guard canSend else { return }

        let taskText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        HapticsService.shared.impact()

        // Show AI processing
        startAIProcessing()

        // Submit after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onSubmit(taskText)
            text = ""
            stopAIProcessing()

            // Show category badge briefly
            showCategoryResult()
        }
    }

    private func startAIProcessing() {
        isAIProcessing = true
        aiDotPhase = 0

        // Animate dots
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if !isAIProcessing {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                aiDotPhase = (aiDotPhase + 1) % 3
            }
        }

        HapticsService.shared.aiProcessingStart()
    }

    private func stopAIProcessing() {
        isAIProcessing = false
        HapticsService.shared.aiProcessingComplete()
    }

    private func showCategoryResult() {
        // Simulate AI categorization
        let categories = ["Work", "Personal", "Health", "Learning", "Creative"]
        categoryText = categories.randomElement() ?? "Task"

        withAnimation(Theme.Animation.springBouncy) {
            showCategoryBadge = true
        }

        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(Theme.Animation.spring) {
                showCategoryBadge = false
            }
        }
    }

    // MARK: - Ambient Animations

    private func startAmbientAnimations() {
        guard !reduceMotion else { return }

        // Send button pulse when text present
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            sendPulse = 1.06
        }
    }

    // MARK: - AI Actions

    private func performAIAction(_ action: AIEnhanceAction) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isAIEnhancing = true
        showAISheet = false

        Task {
            do {
                switch action {
                case .enhance:
                    let enhanced = try await enhanceTaskText(text)
                    await MainActor.run {
                        text = enhanced
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }

                case .estimateTime:
                    let minutes = try await aiService.estimateTime(for: text)
                    await MainActor.run {
                        // Append time estimate to task
                        text = "\(text) (~\(formatMinutes(minutes)))"
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }

                case .categorize:
                    let priority = try await aiService.assessPriority(for: text)
                    await MainActor.run {
                        categoryText = priority.label
                        isAIEnhancing = false
                        withAnimation(Theme.Animation.springBouncy) {
                            showCategoryBadge = true
                        }
                        HapticsService.shared.success()

                        // Hide badge after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(Theme.Animation.spring) {
                                showCategoryBadge = false
                            }
                        }
                    }

                case .breakDown:
                    let subTasks = try await generateSubTasks(for: text)
                    await MainActor.run {
                        // Replace text with formatted sub-tasks
                        if !subTasks.isEmpty {
                            text = subTasks.joined(separator: "\n• ")
                            text = "• " + text
                        }
                        isAIEnhancing = false
                        HapticsService.shared.success()
                    }
                }
            } catch {
                await MainActor.run {
                    isAIEnhancing = false
                    aiEnhanceError = error.localizedDescription
                    showAIError = true
                    HapticsService.shared.error()
                }
            }
        }
    }

    private func enhanceTaskText(_ original: String) async throws -> String {
        guard aiService.isConfigured else {
            throw AIServiceError.notConfigured
        }

        let prompt = """
        Rewrite this task to be clearer and more actionable. Keep it concise (1 sentence max).
        Original: \(original)

        Respond with ONLY the improved task text, nothing else.
        """

        let perplexity = PerplexityService.shared
        let (response, _) = try await perplexity.generateText(
            prompt: prompt,
            temperature: 0.5,
            maxTokens: 100
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateSubTasks(for taskTitle: String) async throws -> [String] {
        guard aiService.isConfigured else {
            throw AIServiceError.notConfigured
        }

        let prompt = """
        Break down this task into 3-5 simple sub-tasks.
        Task: \(taskTitle)

        Respond with ONLY a JSON array of strings, like: ["Step 1", "Step 2", "Step 3"]
        """

        let perplexity = PerplexityService.shared
        let jsonResponse = try await perplexity.generateJSON(prompt: prompt, temperature: 0.4)

        guard let data = jsonResponse.data(using: .utf8),
              let steps = try? JSONDecoder().decode([String].self, from: data) else {
            // Fallback: return original as single item
            return [taskTitle]
        }

        return steps
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
}

// MARK: - AI Enhance Action

enum AIEnhanceAction: String, CaseIterable, Identifiable {
    case enhance = "Enhance"
    case estimateTime = "Estimate Time"
    case categorize = "Categorize"
    case breakDown = "Break Down"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .enhance: return "wand.and.stars"
        case .estimateTime: return "clock"
        case .categorize: return "tag"
        case .breakDown: return "list.bullet.indent"
        }
    }

    var description: String {
        switch self {
        case .enhance: return "Rewrite to be clearer"
        case .estimateTime: return "Add time estimate"
        case .categorize: return "Assess priority"
        case .breakDown: return "Split into sub-tasks"
        }
    }

    var color: Color {
        switch self {
        case .enhance: return Theme.Colors.aiPurple
        case .estimateTime: return Theme.Colors.aiBlue
        case .categorize: return Theme.Colors.aiOrange
        case .breakDown: return Theme.Colors.aiCyan
        }
    }
}

// MARK: - AI Enhance Sheet

struct AIEnhanceSheet: View {
    @Binding var text: String
    @Binding var isProcessing: Bool
    let onEnhance: (AIEnhanceAction) -> Void
    let onDismiss: () -> Void

    @State private var selectedAction: AIEnhanceAction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview of current text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your task")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(text)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                }
                        }
                }
                .padding(.horizontal)

                // AI action buttons
                VStack(spacing: 12) {
                    ForEach(AIEnhanceAction.allCases) { action in
                        Button {
                            selectedAction = action
                            HapticsService.shared.selectionFeedback()
                            onEnhance(action)
                        } label: {
                            HStack(spacing: 14) {
                                // Icon
                                ZStack {
                                    SwiftUI.Circle()
                                        .fill(action.color.opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: action.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(action.color)
                                }

                                // Text
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Text(action.description)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // Arrow or spinner
                                if isProcessing && selectedAction == action {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(action.color)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                selectedAction == action
                                                    ? action.color.opacity(0.4)
                                                    : Color.white.opacity(0.08),
                                                lineWidth: selectedAction == action ? 1.5 : 0.5
                                            )
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isProcessing)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("AI Enhance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
        }
    }
}

// MARK: - Orb Button Style

private struct OrbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @Binding var templates: [QuickAddTemplate]
    let onSelect: (QuickAddTemplate) -> Void
    let onAddCustom: () -> Void

    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(templates) { template in
                        Button {
                            onSelect(template)
                        } label: {
                            HStack(spacing: 14) {
                                // Icon circle
                                ZStack {
                                    SwiftUI.Circle()
                                        .fill(template.color.opacity(0.15))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: template.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(template.color)
                                }

                                Text(template.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(template.color.opacity(0.6))
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        templates.remove(atOffsets: indexSet)
                        HapticsService.shared.lightImpact()
                    }
                } header: {
                    Text("Quick Tasks")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        onAddCustom()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                SwiftUI.Circle()
                                    .fill(Theme.Colors.aiPurple.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Theme.Colors.aiPurple)
                            }

                            Text("Add Custom Task")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.Colors.aiPurple)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .foregroundStyle(Theme.Colors.aiPurple)
                }
            }
            .environment(\.editMode, $editMode)
        }
    }
}

// MARK: - Preview

#Preview("Task Input Bar - Empty") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Spacer()

                    TaskInputBar(
                        text: $text,
                        isFocused: $isFocused,
                        onSubmit: { task in
                            print("Submitted: \(task)")
                        }
                    )
                    .padding(.bottom, 20)
                }
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Task Input Bar - With Text") {
    struct PreviewWrapper: View {
        @State private var text = "Review quarterly report"
        @FocusState private var isFocused: Bool

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Spacer()

                    TaskInputBar(
                        text: $text,
                        isFocused: $isFocused,
                        onSubmit: { _ in }
                    )
                    .padding(.bottom, 20)
                }
            }
            .onAppear { isFocused = true }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Quick Add Sheet") {
    QuickAddSheet(
        templates: .constant(QuickAddTemplate.defaults),
        onSelect: { _ in },
        onAddCustom: { }
    )
    .preferredColorScheme(.dark)
}

